//
//  ConnectionManager.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  连接管理器
//  管理设备连接、错误处理和自动重连机制
//

import Foundation
import Combine
import SwiftUI

// MARK: - 连接事件

/// 连接事件类型
enum ConnectionEvent {
    case connected(any DeviceSource)
    case disconnected(any DeviceSource, reason: DisconnectReason)
    case error(any DeviceSource, DeviceSourceError)
    case reconnecting(any DeviceSource, attempt: Int)
    case reconnectFailed(any DeviceSource)
}

/// 断开原因
enum DisconnectReason {
    case userRequested
    case deviceRemoved
    case connectionLost
    case processTerminated
    case error(Error)
}

// MARK: - 连接管理器

/// 连接管理器 - 处理设备连接生命周期和自动重连
@MainActor
final class ConnectionManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ConnectionManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var isReconnecting = false
    @Published private(set) var reconnectAttempts: [UUID: Int] = [:]
    
    // MARK: - Properties
    
    private let sourceManager = DeviceSourceManager.shared
    private let preferences = UserPreferences.shared
    
    private var stateObservers: [UUID: AnyCancellable] = [:]
    private var reconnectTasks: [UUID: Task<Void, Never>] = [:]
    
    /// 连接事件发布者
    let eventPublisher = PassthroughSubject<ConnectionEvent, Never>()
    
    // MARK: - Initialization
    
    private init() {
        AppLogger.connection.info("连接管理器已初始化")
    }
    
    // MARK: - Connection Methods
    
    /// 连接 Android 设备
    func connectAndroidDevice(_ device: AndroidDevice) async throws -> ScrcpyDeviceSource {
        AppLogger.connection.info("连接 Android 设备: \(device.displayName)")
        
        let config = preferences.buildScrcpyConfiguration(serial: device.serial)
        let source = ScrcpyDeviceSource(device: device, configuration: config)
        
        // 添加到管理器
        sourceManager.addSource(source)
        
        // 设置状态观察
        observeSourceState(source)
        
        // 执行连接
        try await source.connect()
        
        // 发送连接事件
        eventPublisher.send(.connected(source))
        
        return source
    }
    
    /// 断开设备
    func disconnect(_ source: any DeviceSource, reason: DisconnectReason = .userRequested) async {
        AppLogger.connection.info("断开设备: \(source.displayName), 原因: \(reason)")
        
        // 取消重连任务
        cancelReconnect(source.id)
        
        // 移除状态观察
        stateObservers[source.id]?.cancel()
        stateObservers[source.id] = nil
        
        // 断开连接
        await source.disconnect()
        
        // 从管理器移除
        sourceManager.removeSource(source)
        
        // 发送断开事件
        eventPublisher.send(.disconnected(source, reason: reason))
    }
    
    /// 断开所有设备
    func disconnectAll() async {
        AppLogger.connection.info("断开所有设备")
        
        for source in sourceManager.activeSources {
            await disconnect(source, reason: .userRequested)
        }
    }
    
    // MARK: - Reconnection
    
    /// 启动自动重连
    func startReconnect(_ source: any DeviceSource) {
        guard preferences.autoReconnect else {
            AppLogger.connection.info("自动重连已禁用")
            return
        }
        
        guard reconnectTasks[source.id] == nil else {
            AppLogger.connection.warning("重连任务已存在: \(source.displayName)")
            return
        }
        
        reconnectAttempts[source.id] = 0
        isReconnecting = true
        
        reconnectTasks[source.id] = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                let attempt = (self.reconnectAttempts[source.id] ?? 0) + 1
                
                guard attempt <= self.preferences.maxReconnectAttempts else {
                    await MainActor.run {
                        self.eventPublisher.send(.reconnectFailed(source))
                        self.cleanupReconnect(source.id)
                    }
                    break
                }
                
                await MainActor.run {
                    self.reconnectAttempts[source.id] = attempt
                    self.eventPublisher.send(.reconnecting(source, attempt: attempt))
                }
                
                AppLogger.connection.info("重连尝试 #\(attempt): \(source.displayName)")
                
                // 等待重连延迟
                try? await Task.sleep(nanoseconds: UInt64(self.preferences.reconnectDelay * 1_000_000_000))
                
                guard !Task.isCancelled else { break }
                
                // 尝试重连
                do {
                    try await source.reconnect()
                    
                    await MainActor.run {
                        AppLogger.connection.info("重连成功: \(source.displayName)")
                        self.eventPublisher.send(.connected(source))
                        self.cleanupReconnect(source.id)
                    }
                    break
                } catch {
                    AppLogger.connection.warning("重连失败 #\(attempt): \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 取消重连
    func cancelReconnect(_ sourceID: UUID) {
        reconnectTasks[sourceID]?.cancel()
        cleanupReconnect(sourceID)
    }
    
    private func cleanupReconnect(_ sourceID: UUID) {
        reconnectTasks[sourceID] = nil
        reconnectAttempts[sourceID] = nil
        
        if reconnectTasks.isEmpty {
            isReconnecting = false
        }
    }
    
    // MARK: - State Observation
    
    private func observeSourceState(_ source: BaseDeviceSource) {
        stateObservers[source.id] = source.$state
            .dropFirst()
            .sink { [weak self, weak source] newState in
                guard let self = self, let source = source else { return }
                self.handleStateChange(source: source, state: newState)
            }
    }
    
    private func handleStateChange(source: any DeviceSource, state: DeviceSourceState) {
        switch state {
        case .error(let error):
            AppLogger.connection.error("设备错误: \(source.displayName) - \(error.localizedDescription)")
            eventPublisher.send(.error(source, error))
            
            // 根据错误类型决定是否重连
            if shouldReconnect(for: error) {
                startReconnect(source)
            }
            
        case .disconnected:
            AppLogger.connection.info("设备已断开: \(source.displayName)")
            
            // 如果不是用户主动断开，尝试重连
            if reconnectTasks[source.id] == nil && preferences.autoReconnect {
                startReconnect(source)
            }
            
        default:
            break
        }
    }
    
    private func shouldReconnect(for error: DeviceSourceError) -> Bool {
        switch error {
        case .connectionFailed, .processTerminated, .timeout:
            return true
        case .permissionDenied, .windowNotFound:
            return false
        case .captureStartFailed, .unknown:
            return true
        }
    }
}

// MARK: - 重连状态视图

/// 重连状态指示器视图
struct ReconnectingIndicator: View {
    
    let sourceID: UUID
    let sourceName: String
    @ObservedObject var connectionManager: ConnectionManager
    
    var body: some View {
        if let attempt = connectionManager.reconnectAttempts[sourceID] {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("正在重连: \(sourceName)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("尝试 \(attempt)/\(UserPreferences.shared.maxReconnectAttempts)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    connectionManager.cancelReconnect(sourceID)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

// MARK: - 错误恢复视图

/// 错误恢复视图
struct ErrorRecoveryView: View {
    
    let error: DeviceSourceError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("连接错误")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button("关闭", action: onDismiss)
                    .buttonStyle(.bordered)
                
                if canRetry {
                    Button("重试", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    private var errorIcon: String {
        switch error {
        case .permissionDenied:
            return "lock.shield"
        case .windowNotFound:
            return "rectangle.slash"
        case .connectionFailed:
            return "wifi.exclamationmark"
        case .processTerminated:
            return "exclamationmark.triangle"
        case .timeout:
            return "clock.badge.exclamationmark"
        default:
            return "exclamationmark.circle"
        }
    }
    
    private var canRetry: Bool {
        switch error {
        case .permissionDenied:
            return false
        default:
            return true
        }
    }
    
    private var recoverySuggestion: String? {
        switch error {
        case .permissionDenied:
            return "请在系统偏好设置 > 隐私与安全性 > 屏幕录制中授予权限"
        case .windowNotFound:
            return "请确保投屏窗口已打开并可见"
        case .connectionFailed:
            return "请检查设备连接和网络状态"
        case .processTerminated:
            return "scrcpy 进程已终止，请检查设备连接"
        case .timeout:
            return "连接超时，请检查设备是否响应"
        default:
            return nil
        }
    }
}
