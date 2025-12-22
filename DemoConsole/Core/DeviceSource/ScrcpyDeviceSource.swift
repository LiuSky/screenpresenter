//
//  ScrcpyDeviceSource.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  Scrcpy 设备源
//  实现 Android 设备通过 scrcpy 进行投屏捕获
//

import Foundation
import CoreMedia
import ScreenCaptureKit
import AppKit
import Combine

// MARK: - Scrcpy 配置

/// Scrcpy 启动配置
struct ScrcpyConfiguration {
    /// 设备序列号
    var serial: String
    
    /// 最大尺寸限制（0 表示不限制）
    var maxSize: Int = 0
    
    /// 比特率 (bps)
    var bitrate: Int = 8_000_000
    
    /// 最大帧率
    var maxFps: Int = 60
    
    /// 是否显示触摸点
    var showTouches: Bool = true
    
    /// 是否关闭设备屏幕
    var turnScreenOff: Bool = false
    
    /// 是否保持唤醒
    var stayAwake: Bool = true
    
    /// 是否全屏启动
    var fullscreen: Bool = false
    
    /// 是否无边框窗口
    var borderless: Bool = false
    
    /// 是否始终在最前
    var alwaysOnTop: Bool = false
    
    /// 窗口标题（nil 使用默认）
    var windowTitle: String?
    
    /// 编码器名称（nil 使用默认）
    var encoderName: String?
    
    /// 视频编解码器
    var videoCodec: VideoCodec = .h264
    
    /// 视频编解码器枚举
    enum VideoCodec: String {
        case h264 = "h264"
        case h265 = "h265"
        case av1 = "av1"
    }
    
    /// 构建命令行参数
    func buildArguments() -> [String] {
        var args: [String] = []
        
        args.append("-s")
        args.append(serial)
        
        if maxSize > 0 {
            args.append("--max-size=\(maxSize)")
        }
        
        args.append("--bit-rate=\(bitrate)")
        args.append("--max-fps=\(maxFps)")
        args.append("--video-codec=\(videoCodec.rawValue)")
        
        if showTouches {
            args.append("--show-touches")
        }
        
        if turnScreenOff {
            args.append("--turn-screen-off")
        }
        
        if stayAwake {
            args.append("--stay-awake")
        }
        
        if fullscreen {
            args.append("--fullscreen")
        }
        
        if borderless {
            args.append("--window-borderless")
        }
        
        if alwaysOnTop {
            args.append("--always-on-top")
        }
        
        if let title = windowTitle {
            args.append("--window-title=\(title)")
        }
        
        if let encoder = encoderName {
            args.append("--encoder=\(encoder)")
        }
        
        return args
    }
}

// MARK: - Scrcpy 设备源

/// Scrcpy 设备源实现
final class ScrcpyDeviceSource: BaseDeviceSource {
    
    // MARK: - Properties
    
    private let configuration: ScrcpyConfiguration
    private var process: Process?
    private var captureSession: SCStream?
    private var windowID: CGWindowID?
    private var monitorTask: Task<Void, Never>?
    
    private let scrcpyPath: String
    
    // MARK: - Initialization
    
    init(device: AndroidDevice, configuration: ScrcpyConfiguration? = nil) {
        var config = configuration ?? ScrcpyConfiguration(serial: device.serial)
        config.serial = device.serial
        config.windowTitle = "DemoConsole - \(device.displayName)"
        
        self.configuration = config
        
        // 查找 scrcpy 路径
        if let path = ProcessRunner.findExecutable("scrcpy") {
            self.scrcpyPath = path
        } else {
            self.scrcpyPath = "/opt/homebrew/bin/scrcpy"
        }
        
        super.init(
            displayName: device.displayName,
            sourceType: .scrcpy
        )
        
        // 设置设备信息
        self.deviceInfo = GenericDeviceInfo(
            id: device.serial,
            name: device.displayName,
            model: device.model,
            platform: .android
        )
        
        AppLogger.device.info("创建 Scrcpy 设备源: \(device.displayName)")
    }
    
    deinit {
        monitorTask?.cancel()
    }
    
    // MARK: - Connect
    
    override func connect() async throws {
        guard state == .idle || state == .disconnected else {
            AppLogger.connection.warning("设备已连接或正在连接中")
            return
        }
        
        updateState(.connecting)
        AppLogger.connection.info("开始连接 Android 设备: \(configuration.serial)")
        
        do {
            // 启动 scrcpy 进程
            try await startScrcpyProcess()
            
            // 等待窗口出现
            windowID = try await waitForWindow(timeout: 10.0)
            
            updateState(.connected)
            AppLogger.connection.info("设备连接成功: \(displayName)")
            
            // 启动进程监控
            startProcessMonitoring()
            
        } catch {
            let deviceError = DeviceSourceError.connectionFailed(error.localizedDescription)
            updateState(.error(deviceError))
            AppLogger.connection.error("设备连接失败: \(error.localizedDescription)")
            throw deviceError
        }
    }
    
    override func disconnect() async {
        AppLogger.connection.info("断开连接: \(displayName)")
        
        monitorTask?.cancel()
        monitorTask = nil
        
        await stopCapture()
        
        // 终止 scrcpy 进程
        if let process = process, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        process = nil
        windowID = nil
        
        updateState(.disconnected)
    }
    
    // MARK: - Capture
    
    override func startCapture() async throws {
        guard state == .connected || state == .paused else {
            throw DeviceSourceError.captureStartFailed("设备未连接")
        }
        
        guard let windowID = windowID else {
            throw DeviceSourceError.windowNotFound
        }
        
        AppLogger.capture.info("开始捕获窗口: \(windowID)")
        
        do {
            // 获取窗口信息
            guard let window = try await findSCWindow(windowID: windowID) else {
                throw DeviceSourceError.windowNotFound
            }
            
            // 创建捕获配置
            let filter = SCContentFilter(desktopIndependentWindow: window)
            
            let streamConfig = SCStreamConfiguration()
            streamConfig.width = Int(window.frame.width) * 2  // Retina
            streamConfig.height = Int(window.frame.height) * 2
            streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(configuration.maxFps))
            streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
            streamConfig.showsCursor = false
            streamConfig.capturesAudio = false
            
            // 创建并启动捕获流
            let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
            
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
            try await stream.startCapture()
            
            self.captureSession = stream
            
            // 更新捕获尺寸
            let width = CGFloat(streamConfig.width)
            let height = CGFloat(streamConfig.height)
            updateCaptureSize(CGSize(width: width, height: height))
            
            updateState(.capturing)
            AppLogger.capture.info("捕获已启动: \(displayName)")
            
        } catch {
            let captureError = DeviceSourceError.captureStartFailed(error.localizedDescription)
            updateState(.error(captureError))
            throw captureError
        }
    }
    
    override func stopCapture() async {
        guard let stream = captureSession else { return }
        
        do {
            try await stream.stopCapture()
        } catch {
            AppLogger.capture.error("停止捕获失败: \(error.localizedDescription)")
        }
        
        captureSession = nil
        
        if state == .capturing {
            updateState(.connected)
        }
        
        AppLogger.capture.info("捕获已停止: \(displayName)")
    }
    
    // MARK: - Private Methods
    
    private func startScrcpyProcess() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: scrcpyPath)
        process.arguments = configuration.buildArguments()
        
        // 设置环境变量
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        process.environment = environment
        
        // 配置输出管道
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        AppLogger.process.info("启动 scrcpy: \(scrcpyPath) \(configuration.buildArguments().joined(separator: " "))")
        
        try process.run()
        self.process = process
        
        // 异步读取输出（用于调试）
        Task {
            for try await line in outputPipe.fileHandleForReading.bytes.lines {
                AppLogger.process.debug("[scrcpy stdout] \(line)")
            }
        }
        
        Task {
            for try await line in errorPipe.fileHandleForReading.bytes.lines {
                AppLogger.process.debug("[scrcpy stderr] \(line)")
            }
        }
    }
    
    private func waitForWindow(timeout: TimeInterval) async throws -> CGWindowID {
        let startTime = CFAbsoluteTimeGetCurrent()
        let windowTitle = configuration.windowTitle ?? "scrcpy"
        
        AppLogger.capture.info("等待窗口出现: \(windowTitle)")
        
        while CFAbsoluteTimeGetCurrent() - startTime < timeout {
            // 获取所有窗口
            guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                continue
            }
            
            // 查找匹配的窗口
            for windowInfo in windowList {
                guard let name = windowInfo[kCGWindowName as String] as? String,
                      let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID else {
                    continue
                }
                
                // 匹配窗口标题
                if name.contains(windowTitle) || name.lowercased().contains("scrcpy") {
                    AppLogger.capture.info("找到窗口: \(name) (ID: \(windowID))")
                    return windowID
                }
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
        
        throw DeviceSourceError.timeout
    }
    
    private func findSCWindow(windowID: CGWindowID) async throws -> SCWindow? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content.windows.first { $0.windowID == windowID }
    }
    
    private func startProcessMonitoring() {
        monitorTask = Task { [weak self] in
            guard let self = self, let process = self.process else { return }
            
            // 等待进程退出
            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
            
            let exitCode = process.terminationStatus
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if exitCode != 0 && self.state != .disconnected {
                    AppLogger.connection.error("scrcpy 进程异常退出，退出码: \(exitCode)")
                    self.updateState(.error(.processTerminated(exitCode)))
                } else {
                    AppLogger.connection.info("scrcpy 进程正常退出")
                    self.updateState(.disconnected)
                }
            }
        }
    }
}

// MARK: - SCStreamOutput

extension ScrcpyDeviceSource: SCStreamOutput {
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard state == .capturing else { return }
        
        // 创建 CapturedFrame
        let frame = CapturedFrame(sourceID: id, sampleBuffer: sampleBuffer)
        emitFrame(frame)
    }
}
