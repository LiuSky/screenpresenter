//
//  ScrcpyServerLauncher.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/24.
//
//  Scrcpy Server 启动器
//  负责推送 scrcpy-server 到设备并启动
//

import Foundation

// MARK: - Scrcpy 连接模式

/// scrcpy 连接模式
enum ScrcpyConnectionMode {
    /// reverse 模式：macOS 监听端口，Android 设备连接过来
    case reverse
    /// forward 模式：Android 设备监听，macOS 连接过去
    case forward
}

// MARK: - Scrcpy Server 启动器

/// Scrcpy Server 启动器
/// 负责：
/// 1. 推送 scrcpy-server.jar 到设备
/// 2. 建立 adb reverse（失败则 fallback 到 forward）
/// 3. 启动 scrcpy-server
final class ScrcpyServerLauncher {
    // MARK: - 常量

    /// scrcpy-server 在设备上的路径
    static let serverDevicePath = "/data/local/tmp/scrcpy-server.jar"

    // MARK: - 属性

    /// ADB 服务
    private let adbService: AndroidADBService

    /// scrcpy-server 本地路径
    private let serverLocalPath: String

    /// 连接端口
    private let port: Int

    /// 生成的 scid
    private(set) var scid: UInt32 = 0

    /// 当前连接模式
    private(set) var connectionMode: ScrcpyConnectionMode = .reverse

    /// 服务器进程
    private var serverProcess: Process?

    /// scrcpy 版本（用于与服务端通信）
    private let scrcpyVersion: String

    // MARK: - 初始化

    /// 初始化启动器
    /// - Parameters:
    ///   - adbService: ADB 服务
    ///   - serverLocalPath: scrcpy-server 本地路径
    ///   - port: 连接端口
    ///   - scrcpyVersion: scrcpy 版本号
    init(
        adbService: AndroidADBService,
        serverLocalPath: String,
        port: Int,
        scrcpyVersion: String = "3.0"
    ) {
        self.adbService = adbService
        self.serverLocalPath = serverLocalPath
        self.port = port
        self.scrcpyVersion = scrcpyVersion

        // 生成随机 scid（限制在 Java Integer 安全范围内）
        scid = UInt32.random(in: 10_000_000..<100_000_000)

        AppLogger.process.info("[ScrcpyLauncher] 初始化，scid: \(scid), port: \(port)")
    }

    // MARK: - 公开方法

    /// 启动 scrcpy-server
    /// - Parameter configuration: scrcpy 配置
    /// - Returns: 启动的服务器进程
    @MainActor
    func launch(configuration: ScrcpyConfiguration) async throws -> Process {
        AppLogger.process.info("[ScrcpyLauncher] 开始启动流程...")

        // 1. 推送 scrcpy-server 到设备
        try await pushServer()

        // 2. 检查协议版本兼容性
        await checkProtocolVersion()

        // 3. 设置端口转发（优先使用 reverse，失败则 fallback 到 forward）
        try await setupPortForwarding()

        // 4. 启动 scrcpy-server
        let process = try await startServer(configuration: configuration)
        serverProcess = process

        AppLogger.process.info("[ScrcpyLauncher] 启动完成，模式: \(connectionMode)")
        return process
    }

    /// 检查协议版本兼容性
    @MainActor
    private func checkProtocolVersion() async {
        AppLogger.process.info("[ScrcpyLauncher] 检查协议版本兼容性...")

        // 尝试获取已推送的 server 版本（通过 MD5 或其他方式）
        // scrcpy-server 不直接暴露版本，这里记录客户端版本供参考
        let clientVersion = scrcpyVersion

        // 解析主版本号
        let majorVersion = clientVersion.components(separatedBy: ".").first ?? "0"

        AppLogger.process.info("[ScrcpyLauncher] 客户端协议版本: \(clientVersion) (主版本: \(majorVersion))")

        // 版本兼容性检查
        if let major = Int(majorVersion) {
            if major < 2 {
                AppLogger.process.warning("[ScrcpyLauncher] ⚠️ 协议版本可能不兼容 - 客户端版本: \(clientVersion)，建议使用 2.0 或更高版本")
            } else if major >= 3 {
                AppLogger.process.info("[ScrcpyLauncher] ✅ 协议版本兼容 (scrcpy 3.x)")
            } else {
                AppLogger.process.info("[ScrcpyLauncher] ✅ 协议版本兼容 (scrcpy 2.x)")
            }
        }
    }

    /// 停止服务器
    @MainActor
    func stop() async {
        AppLogger.process.info("[ScrcpyLauncher] 停止服务器...")

        // 终止进程
        if let process = serverProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        serverProcess = nil

        // 移除端口转发
        await removePortForwarding()

        AppLogger.process.info("[ScrcpyLauncher] 服务器已停止")
    }

    /// 获取 Unix 域套接字名称
    var socketName: String {
        "scrcpy_\(scid)"
    }

    // MARK: - 私有方法

    /// 推送 scrcpy-server 到设备
    @MainActor
    private func pushServer() async throws {
        AppLogger.process.info("[ScrcpyLauncher] 推送 scrcpy-server 到设备...")

        guard FileManager.default.fileExists(atPath: serverLocalPath) else {
            throw ScrcpyLauncherError.serverNotFound(path: serverLocalPath)
        }

        try await adbService.push(local: serverLocalPath, remote: Self.serverDevicePath)

        AppLogger.process.info("[ScrcpyLauncher] scrcpy-server 已推送到设备")
    }

    /// 设置端口转发
    @MainActor
    private func setupPortForwarding() async throws {
        AppLogger.process.info("[ScrcpyLauncher] 设置端口转发，优先使用 reverse 模式...")

        // 首先尝试 reverse 模式
        do {
            try await adbService.reverse(localAbstract: socketName, tcpPort: port)
            connectionMode = .reverse
            AppLogger.process.info("[ScrcpyLauncher] ✅ reverse 模式设置成功")
            return
        } catch {
            AppLogger.process.warning("[ScrcpyLauncher] reverse 模式失败: \(error.localizedDescription)，回退到 forward 模式")
        }

        // Fallback 到 forward 模式
        do {
            try await adbService.forward(tcpPort: port, localAbstract: socketName)
            connectionMode = .forward
            AppLogger.process.info("[ScrcpyLauncher] ✅ forward 模式设置成功")
        } catch {
            throw ScrcpyLauncherError.portForwardingFailed(reason: error.localizedDescription)
        }
    }

    /// 移除端口转发
    @MainActor
    private func removePortForwarding() async {
        switch connectionMode {
        case .reverse:
            await adbService.removeReverse(localAbstract: socketName)
        case .forward:
            await adbService.removeForward(tcpPort: port)
        }
    }

    /// 启动 scrcpy-server
    @MainActor
    private func startServer(configuration: ScrcpyConfiguration) async throws -> Process {
        AppLogger.process.info("[ScrcpyLauncher] 启动 scrcpy-server...")

        // 构建服务端参数
        let serverArgs = buildServerArguments(configuration: configuration)

        do {
            let process = try adbService.startServer(
                serverPath: Self.serverDevicePath,
                arguments: serverArgs
            )

            // 等待一小段时间让服务端启动
            try await Task.sleep(nanoseconds: 800_000_000) // 800ms

            // 检查进程是否还在运行
            guard process.isRunning else {
                let exitCode = process.terminationStatus
                throw ScrcpyLauncherError.serverStartFailedWithExitCode(exitCode)
            }

            AppLogger.process.info("[ScrcpyLauncher] scrcpy-server 已启动")
            return process
        } catch let error as ScrcpyLauncherError {
            throw error
        } catch {
            throw ScrcpyLauncherError.serverStartFailed(reason: error.localizedDescription)
        }
    }

    /// 构建服务端参数
    private func buildServerArguments(configuration: ScrcpyConfiguration) -> [String] {
        var args: [String] = [
            scrcpyVersion,
            "scid=\(scid)",
            "log_level=info",
            "audio=false",
            "control=false",
            // 标准协议：发送 meta 和 frame header
            "send_device_meta=true",
            "send_frame_meta=true",
            "send_dummy_byte=true",
            "send_codec_meta=true",
            "raw_stream=false",
        ]

        // 根据连接模式设置 tunnel 参数
        switch connectionMode {
        case .reverse:
            args.append("tunnel_forward=false")
        case .forward:
            args.append("tunnel_forward=true")
        }

        // 视频参数
        if configuration.maxSize > 0 {
            args.append("max_size=\(configuration.maxSize)")
        }
        if configuration.maxFps > 0 {
            args.append("max_fps=\(configuration.maxFps)")
        }
        if configuration.bitrate > 0 {
            args.append("video_bit_rate=\(configuration.bitrate)")
        }
        args.append("video_codec=\(configuration.videoCodec.rawValue)")

        AppLogger.process.info("[ScrcpyLauncher] 服务端参数: \(args.joined(separator: " "))")
        return args
    }
}

// MARK: - Scrcpy Launcher 错误

/// Scrcpy 启动器错误
enum ScrcpyLauncherError: LocalizedError {
    case serverNotFound(path: String)
    case portForwardingFailed(reason: String)
    case serverStartFailedWithExitCode(Int32)
    case serverStartFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case let .serverNotFound(path):
            "scrcpy-server 未找到: \(path)"
        case let .portForwardingFailed(reason):
            "端口转发设置失败: \(reason)"
        case let .serverStartFailedWithExitCode(exitCode):
            "scrcpy-server 启动失败，退出码: \(exitCode)"
        case let .serverStartFailed(reason):
            "scrcpy-server 启动失败: \(reason)"
        }
    }
}
