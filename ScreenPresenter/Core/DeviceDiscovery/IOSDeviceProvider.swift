//
//  IOSDeviceProvider.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/24.
//
//  iOS 设备提供者
//  使用 AVFoundation 发现和管理 USB 连接的 iOS 设备
//
//  设备事件监听策略：
//  - 主要：AVFoundation 通知（连接/断开）— 稳定的公开 API
//  - 增强：定期刷新 DeviceInsight（状态变化检测）— 轻量级补充
//  - 不使用 MobileDevice 原生事件，避免私有 API 不稳定性
//

import AVFoundation
import Combine
import Foundation

// MARK: - iOS 设备提供者

@MainActor
final class IOSDeviceProvider: NSObject, ObservableObject {
    // MARK: - 状态

    /// 已发现的 iOS 设备列表
    @Published private(set) var devices: [IOSDevice] = []

    /// 是否正在监控
    @Published private(set) var isMonitoring = false

    /// 最后一次错误
    @Published private(set) var lastError: String?

    // MARK: - 配置

    /// 状态刷新间隔（秒）— 用于检测信任/占用状态变化
    private let insightRefreshInterval: TimeInterval = 5.0

    // MARK: - 私有属性

    private var discoverySession: AVCaptureDevice.DiscoverySession?
    private var deviceObservation: NSKeyValueObservation?
    private var insightRefreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化

    override init() {
        super.init()
        setupNotifications()
    }

    deinit {
        deviceObservation?.invalidate()
        insightRefreshTask?.cancel()
    }

    // MARK: - 公开方法

    /// 开始监控设备
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        lastError = nil
        setupDiscoverySession()
        startInsightRefresh()
    }

    /// 设置设备发现会话
    private func setupDiscoverySession() {
        // 创建发现会话，只监听外部视频设备（iOS 设备）
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        )

        // 监听设备列表变化
        deviceObservation = discoverySession?.observe(\.devices, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor in
                self?.refreshDevices()
            }
        }

        // 立即刷新一次
        refreshDevices()

        AppLogger.device.info("iOS 设备监控已启动")
    }

    /// 停止监控
    func stopMonitoring() {
        isMonitoring = false
        deviceObservation?.invalidate()
        deviceObservation = nil
        discoverySession = nil
        insightRefreshTask?.cancel()
        insightRefreshTask = nil

        AppLogger.device.info("iOS 设备监控已停止")
    }

    /// 手动刷新设备列表
    func refreshDevices() {
        guard let session = discoverySession else {
            // 如果没有会话，创建临时查询
            let tempSession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.external],
                mediaType: .video,
                position: .unspecified
            )
            updateDeviceList(from: tempSession.devices)
            return
        }

        updateDeviceList(from: session.devices)
    }

    /// 获取特定设备
    func device(for id: String) -> IOSDevice? {
        devices.first { $0.id == id }
    }

    /// 获取 AVCaptureDevice
    func captureDevice(for deviceID: String) -> AVCaptureDevice? {
        AVCaptureDevice(uniqueID: deviceID)
    }

    // MARK: - 私有方法

    private func updateDeviceList(from captureDevices: [AVCaptureDevice]) {
        let iosDevices = captureDevices.compactMap { device -> IOSDevice? in
            IOSDevice.from(captureDevice: device)
        }

        // 只在设备列表真正变化时更新
        if iosDevices.map(\.id) != devices.map(\.id) {
            devices = iosDevices

            if iosDevices.isEmpty {
                AppLogger.device.info("未发现 iOS 设备")
            } else {
                for device in iosDevices {
                    // 使用增强的设备信息显示
                    let displayInfo = buildDeviceDisplayInfo(device)
                    AppLogger.device.info("iOS 设备已更新: \(displayInfo)")
                }
            }
        }
    }

    /// 构建设备显示信息（用于日志和诊断）
    private func buildDeviceDisplayInfo(_ device: IOSDevice) -> String {
        var info = device.displayName

        if let modelName = device.displayModelName {
            info += " (\(modelName))"
        }

        if let version = device.systemVersion, version != L10n.deviceInfo.unknown {
            info += " iOS \(version)"
        }

        if let prompt = device.userPrompt {
            info += " ⚠️ \(prompt)"
        }

        return info
    }

    /// 获取设备的用户提示信息（用于 UI 显示）
    func getUserPrompt(for deviceID: String) -> String? {
        devices.first { $0.id == deviceID }?.userPrompt
    }

    // MARK: - Insight 状态刷新（轻量级增强）

    /// 启动定期状态刷新
    /// 用于检测设备状态变化（信任、占用等），补充 AVFoundation 的连接/断开事件
    private func startInsightRefresh() {
        insightRefreshTask?.cancel()
        insightRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.insightRefreshInterval ?? 5.0) * 1_000_000_000)

                guard !Task.isCancelled, let self else { break }

                // 只在有设备时刷新 insight
                if !devices.isEmpty {
                    await refreshDeviceInsights()
                }
            }
        }

        AppLogger.device.debug("设备状态刷新已启动，间隔: \(insightRefreshInterval)s")
    }

    /// 刷新所有设备的 insight 信息
    /// 检测状态变化（信任、占用等）并更新 UI
    private func refreshDeviceInsights() async {
        guard let session = discoverySession else { return }

        var hasChanges = false

        for captureDevice in session.devices {
            guard let existingDevice = devices.first(where: { $0.id == captureDevice.uniqueID }) else {
                continue
            }

            // 重新获取 insight
            let insightService = DeviceInsightService.shared
            let newInsight = insightService.getDeviceInsight(for: captureDevice.uniqueID)
            let newPrompt = insightService.getUserPrompt(for: newInsight)

            // 检测状态变化
            let oldPrompt = existingDevice.userPrompt
            if newPrompt != oldPrompt {
                hasChanges = true

                if let prompt = newPrompt {
                    AppLogger.device.warning("设备状态变化: \(existingDevice.displayName) - \(prompt)")
                } else if oldPrompt != nil {
                    AppLogger.device.info("设备状态恢复正常: \(existingDevice.displayName)")
                }
            }
        }

        // 如果有变化，完整刷新设备列表（会触发 UI 更新）
        if hasChanges {
            refreshDevices()
        }
    }

    private func setupNotifications() {
        // 监听设备连接/断开通知
        NotificationCenter.default.publisher(for: .AVCaptureDeviceWasConnected)
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let device = notification.object as? AVCaptureDevice {
                        AppLogger.device.info("设备已连接: \(device.localizedName)")
                    }
                    self?.refreshDevices()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVCaptureDeviceWasDisconnected)
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let device = notification.object as? AVCaptureDevice {
                        AppLogger.device.info("设备已断开: \(device.localizedName)")
                    }
                    self?.refreshDevices()
                }
            }
            .store(in: &cancellables)
    }
}
