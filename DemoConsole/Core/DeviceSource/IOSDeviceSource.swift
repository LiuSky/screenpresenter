//
//  IOSDeviceSource.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/24.
//
//  iOS 设备源
//  使用 AVFoundation 直接捕获 USB 连接的 iPhone/iPad 屏幕
//

import AVFoundation
import Combine
import CoreMedia
import Foundation

// MARK: - iOS 设备源

@MainActor
final class IOSDeviceSource: BaseDeviceSource {
    // MARK: - 属性

    /// 关联的 iOS 设备
    let iosDevice: IOSDevice

    /// 是否支持音频
    override var supportsAudio: Bool { true }

    // MARK: - 私有属性

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private let captureQueue = DispatchQueue(label: "com.democonsole.ios.capture", qos: .userInteractive)
    private let audioQueue = DispatchQueue(label: "com.democonsole.ios.audio", qos: .userInteractive)

    /// 视频输出代理
    private var videoDelegate: VideoCaptureDelegate?

    /// 是否正在捕获（线程安全标志）
    private var isCapturingFlag: Bool = false

    // MARK: - 初始化

    init(device: IOSDevice) {
        iosDevice = device

        let deviceInfo = GenericDeviceInfo(
            id: device.id,
            name: device.name,
            model: device.modelID,
            platform: .ios
        )

        super.init(
            displayName: device.name,
            sourceType: .quicktime
        )

        self.deviceInfo = deviceInfo
    }

    // MARK: - DeviceSource 实现

    override func connect() async throws {
        guard state == .idle || state == .disconnected else {
            AppLogger.connection.warning("iOS 设备已连接或正在连接中")
            return
        }

        updateState(.connecting)
        AppLogger.connection.info("开始连接 iOS 设备: \(iosDevice.name)")

        do {
            // 创建捕获会话
            try await setupCaptureSession()
            updateState(.connected)
            AppLogger.connection.info("iOS 设备已连接: \(iosDevice.name)")
        } catch {
            let deviceError = DeviceSourceError.connectionFailed(error.localizedDescription)
            updateState(.error(deviceError))
            throw deviceError
        }
    }

    override func disconnect() async {
        AppLogger.connection.info("断开 iOS 设备: \(iosDevice.name)")

        await stopCapture()

        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        audioOutput = nil
        videoDelegate = nil

        updateState(.disconnected)
    }

    override func startCapture() async throws {
        guard state == .connected || state == .paused else {
            throw DeviceSourceError.captureStartFailed("设备未连接")
        }

        guard let session = captureSession else {
            throw DeviceSourceError.captureStartFailed("捕获会话未初始化")
        }

        AppLogger.capture.info("开始捕获 iOS 设备: \(iosDevice.name)")

        // 在后台线程启动会话
        await withCheckedContinuation { continuation in
            captureQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                if !session.isRunning {
                    session.startRunning()
                }

                Task { @MainActor in
                    self.isCapturingFlag = true
                    self.updateState(.capturing)
                    continuation.resume()
                }
            }
        }

        AppLogger.capture.info("iOS 捕获已启动: \(iosDevice.name)")
    }

    override func stopCapture() async {
        guard isCapturingFlag else { return }

        isCapturingFlag = false

        await withCheckedContinuation { continuation in
            captureQueue.async { [weak self] in
                self?.captureSession?.stopRunning()

                Task { @MainActor in
                    if self?.state == .capturing {
                        self?.updateState(.connected)
                    }
                    continuation.resume()
                }
            }
        }

        AppLogger.capture.info("iOS 捕获已停止: \(iosDevice.name)")
    }

    // MARK: - 私有方法

    private func setupCaptureSession() async throws {
        // 获取 AVCaptureDevice
        guard let captureDevice = AVCaptureDevice(uniqueID: iosDevice.id) else {
            throw DeviceSourceError.connectionFailed("无法获取捕获设备")
        }

        let session = AVCaptureSession()
        session.sessionPreset = .high

        // 添加视频输入
        let videoInput = try AVCaptureDeviceInput(device: captureDevice)
        guard session.canAddInput(videoInput) else {
            throw DeviceSourceError.connectionFailed("无法添加视频输入")
        }
        session.addInput(videoInput)

        // 添加视频输出
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // 创建视频代理
        let delegate = VideoCaptureDelegate { [weak self] sampleBuffer in
            self?.handleVideoSampleBuffer(sampleBuffer)
        }
        videoOutput.setSampleBufferDelegate(delegate, queue: captureQueue)

        guard session.canAddOutput(videoOutput) else {
            throw DeviceSourceError.connectionFailed("无法添加视频输出")
        }
        session.addOutput(videoOutput)

        // 尝试添加音频输入（如果设备支持）
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            if let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)

                    let audioOutput = AVCaptureAudioDataOutput()
                    if session.canAddOutput(audioOutput) {
                        session.addOutput(audioOutput)
                        self.audioOutput = audioOutput
                    }
                }
            }
        }

        // 获取视频尺寸
        let formatDescription = captureDevice.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        updateCaptureSize(CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height)))

        captureSession = session
        self.videoOutput = videoOutput
        videoDelegate = delegate

        AppLogger.capture.info("iOS 捕获会话已配置: \(iosDevice.name)")
    }

    private func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isCapturingFlag else { return }

        // 创建 CapturedFrame 并发送
        let frame = CapturedFrame(sourceID: id, sampleBuffer: sampleBuffer)

        Task { @MainActor [weak self] in
            self?.emitFrame(frame)
        }
    }
}

// MARK: - 视频捕获代理

private final class VideoCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let handler: (CMSampleBuffer) -> Void

    init(handler: @escaping (CMSampleBuffer) -> Void) {
        self.handler = handler
        super.init()
    }

    func captureOutput(
        _: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {
        handler(sampleBuffer)
    }
}
