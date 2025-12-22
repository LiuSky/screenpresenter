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

    /// 摄像头权限（用于 iOS 设备检测）
    @Published private(set) var cameraStatus: PermissionStatus = .unknown

    /// 辅助功能权限
    @Published private(set) var accessibilityStatus: PermissionStatus = .unknown

    /// 是否所有必需权限都已授予
    var allPermissionsGranted: Bool {
        screenRecordingStatus == .granted && cameraStatus == .granted
    }

    /// 权限列表
    var permissions: [PermissionItem] {
        [
            PermissionItem(
                id: "camera",
                name: "摄像头",
                description: "需要此权限来检测 USB 连接的 iOS 设备",
                status: cameraStatus,
                isRequired: true,
                settingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
            ),
            PermissionItem(
                id: "screenRecording",
                name: "屏幕录制",
                description: "需要此权限来捕获设备画面",
                status: screenRecordingStatus,
                isRequired: true,
                settingsURL: URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
                )
            ),
            PermissionItem(
                id: "accessibility",
                name: "辅助功能",
                description: "用于自动化操作 QuickTime（可选）",
                status: accessibilityStatus,
                isRequired: false,
                settingsURL: URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                )
            ),
        ]
    }

    // MARK: - 公开方法

    /// 检查所有权限
    func checkAll() async {
        await checkCameraPermission()
        await checkScreenRecordingPermission()
        await checkAccessibilityPermission()
    }

    /// 检查摄像头权限（用于 iOS 设备检测）
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
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await checkCameraPermission()
        return granted
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

    /// 检查辅助功能权限
    func checkAccessibilityPermission() async {
        accessibilityStatus = .checking

        // 使用不带提示的选项检查辅助功能权限
        // 注意：AXIsProcessTrustedWithOptions 的结果可能被缓存
        // 需要确保每次调用都获取最新状态
        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false,
        ]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // 也可以不带参数直接检查
        let trustedSimple = AXIsProcessTrusted()

        // 任一方法返回 true 则认为已授权
        let isGranted = trusted || trustedSimple

        accessibilityStatus = isGranted ? .granted : .denied
    }

    /// 请求辅助功能权限（会弹出系统对话框）
    func requestAccessibilityPermission() {
        // 带提示选项会触发系统授权对话框
        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
        ]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
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
