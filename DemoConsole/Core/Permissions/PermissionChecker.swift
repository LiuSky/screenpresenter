//
//  PermissionChecker.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  权限检查器
//  检测和请求屏幕录制等系统权限
//

import AppKit
import AVFoundation
import Foundation
import ScreenCaptureKit

// MARK: - 权限状态

enum PermissionStatus: Equatable {
    case unknown
    case checking
    case granted
    case denied
    case notDetermined

    var displayName: String {
        switch self {
        case .unknown:
            "未知"
        case .checking:
            "检查中..."
        case .granted:
            "已授权"
        case .denied:
            "已拒绝"
        case .notDetermined:
            "未设置"
        }
    }

    var icon: String {
        switch self {
        case .granted:
            "checkmark.circle.fill"
        case .denied:
            "xmark.circle.fill"
        case .notDetermined:
            "questionmark.circle"
        default:
            "circle"
        }
    }

    var iconColor: String {
        switch self {
        case .granted:
            "green"
        case .denied:
            "red"
        case .notDetermined:
            "orange"
        default:
            "gray"
        }
    }
}

// MARK: - 权限项

struct PermissionItem: Identifiable {
    let id: String
    let name: String
    let description: String
    var status: PermissionStatus
    let isRequired: Bool
    let settingsURL: URL?
}

// MARK: - 权限检查器

@MainActor
final class PermissionChecker: ObservableObject {
    // MARK: - 状态

    /// 屏幕录制权限
    @Published private(set) var screenRecordingStatus: PermissionStatus = .unknown

    /// 摄像头权限（用于 iOS 设备捕获）
    @Published private(set) var cameraStatus: PermissionStatus = .unknown

    /// 是否所有必需权限都已授予
    /// 所有权限都改为可选，返回 true 允许用户直接使用
    var allPermissionsGranted: Bool {
        true
    }

    /// 权限列表
    var permissions: [PermissionItem] {
        [
            PermissionItem(
                id: "camera",
                name: "摄像头",
                description: "用于捕获 USB 连接的 iOS 设备画面（连接设备时自动请求）",
                status: cameraStatus,
                isRequired: false,
                settingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
            ),
            PermissionItem(
                id: "screenRecording",
                name: "屏幕录制",
                description: "用于捕获 Android 设备画面（scrcpy 窗口）",
                status: screenRecordingStatus,
                isRequired: false,
                settingsURL: URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
                )
            ),
        ]
    }

    // MARK: - 公开方法

    /// 检查所有权限
    func checkAll() async {
        await checkCameraPermission()
        await checkScreenRecordingPermission()
    }

    /// 检查摄像头权限
    func checkCameraPermission() async {
        cameraStatus = .checking

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraStatus = .granted
        case .denied, .restricted:
            cameraStatus = .denied
        case .notDetermined:
            cameraStatus = .notDetermined
        @unknown default:
            cameraStatus = .unknown
        }
    }

    /// 请求摄像头权限
    func requestCameraPermission() async -> Bool {
        // 方法1：标准 API 请求
        var granted = await AVCaptureDevice.requestAccess(for: .video)

        // 方法2：如果标准方法不触发弹窗，尝试实际访问摄像头硬件
        if !granted {
            granted = await forceTriggerCameraPermission()
        }

        await checkCameraPermission()
        return cameraStatus == .granted
    }

    /// 通过实际访问摄像头硬件来强制触发权限弹窗
    private func forceTriggerCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 尝试获取内置摄像头（这会触发权限弹窗）
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .front
                )

                guard let camera = discoverySession.devices.first else {
                    // 没有内置摄像头，尝试任何视频设备
                    let anyDeviceSession = AVCaptureDevice.DiscoverySession(
                        deviceTypes: [.builtInWideAngleCamera, .external],
                        mediaType: .video,
                        position: .unspecified
                    )

                    guard let anyCamera = anyDeviceSession.devices.first else {
                        AppLogger.permission.warning("未找到任何摄像头设备")
                        continuation.resume(returning: false)
                        return
                    }

                    self.tryCreateCaptureInput(device: anyCamera, continuation: continuation)
                    return
                }

                self.tryCreateCaptureInput(device: camera, continuation: continuation)
            }
        }
    }

    /// 尝试创建捕获输入（这会触发权限弹窗）
    private func tryCreateCaptureInput(device: AVCaptureDevice, continuation: CheckedContinuation<Bool, Never>) {
        do {
            // 创建输入 - 这一步会触发权限弹窗
            let input = try AVCaptureDeviceInput(device: device)

            // 创建一个临时会话来验证
            let session = AVCaptureSession()
            if session.canAddInput(input) {
                session.addInput(input)
                // 立即移除
                session.removeInput(input)
            }

            AppLogger.permission.info("摄像头权限已获取")
            continuation.resume(returning: true)
        } catch {
            AppLogger.permission.error("触发摄像头权限失败: \(error.localizedDescription)")
            continuation.resume(returning: false)
        }
    }

    /// 检查屏幕录制权限
    func checkScreenRecordingPermission() async {
        screenRecordingStatus = .checking

        // 使用 CGPreflightScreenCaptureAccess 检查当前权限状态
        // 这个 API 只是检查，不会触发授权对话框
        let hasAccess = CGPreflightScreenCaptureAccess()

        if hasAccess {
            screenRecordingStatus = .granted
        } else {
            screenRecordingStatus = .denied
        }
    }

    /// 请求屏幕录制权限
    /// 注意：需要应用有正确签名才能在系统设置中显示
    func requestScreenRecordingPermission() async -> Bool {
        // CGRequestScreenCaptureAccess 会尝试触发系统授权
        // 对于开发中的应用，可能需要手动添加到系统设置
        let result = CGRequestScreenCaptureAccess()

        // 重新检查状态
        await checkScreenRecordingPermission()

        return result
    }

    /// 打开系统偏好设置
    func openSystemPreferences(for permissionID: String) {
        if
            let permission = permissions.first(where: { $0.id == permissionID }),
            let url = permission.settingsURL {
            NSWorkspace.shared.open(url)
        }
    }

    /// 打开隐私设置
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 工具检查扩展

extension PermissionChecker {
    /// 检查工具链状态
    func checkToolchain(manager: ToolchainManager) -> [ToolchainCheckItem] {
        [
            ToolchainCheckItem(
                name: "adb",
                description: "Android 调试工具",
                status: manager.adbStatus,
                isRequired: true
            ),
            ToolchainCheckItem(
                name: "scrcpy",
                description: "Android 投屏工具",
                status: manager.scrcpyStatus,
                isRequired: true
            ),
        ]
    }
}

// MARK: - 工具链检查项

struct ToolchainCheckItem: Identifiable {
    let name: String
    let description: String
    let status: ToolchainStatus
    let isRequired: Bool

    var id: String { name }

    var statusIcon: String {
        switch status {
        case .installed:
            "checkmark.circle.fill"
        case .installing:
            "arrow.down.circle"
        case .notInstalled:
            "xmark.circle"
        case .error:
            "exclamationmark.circle.fill"
        }
    }

    var statusColor: String {
        switch status {
        case .installed:
            "green"
        case .installing:
            "blue"
        case .notInstalled:
            "orange"
        case .error:
            "red"
        }
    }
}
