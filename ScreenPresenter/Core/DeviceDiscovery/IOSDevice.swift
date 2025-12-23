//
//  IOSDevice.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/24.
//
//  iOS 设备模型
//  表示通过 USB 连接的 iPhone/iPad 设备
//

import AVFoundation
import Foundation

// MARK: - iOS 设备

/// iOS 设备信息
struct IOSDevice: Identifiable, Hashable {
    /// 设备唯一 ID
    let id: String

    /// 设备名称（如 "iPhone 15 Pro"）
    let name: String

    /// 设备型号标识
    let modelID: String?

    /// 连接类型
    let connectionType: ConnectionType

    /// 设备位置 ID（用于 USB 识别）
    let locationID: UInt32?

    /// 关联的 AVCaptureDevice
    weak var captureDevice: AVCaptureDevice?

    // MARK: - MobileDevice 增强信息（可选，不影响主流程）

    /// 增强的设备信息（来自 MobileDevice.framework）
    var insight: IOSDeviceInsight?

    /// 用户提示信息（信任状态、占用状态等）
    var userPrompt: String?

    /// 显示名称（优先使用 insight 中的用户设备名）
    var displayName: String {
        // 优先使用 MobileDevice 提供的用户设置的设备名
        if let insight, insight.deviceName != "iOS 设备" {
            return insight.deviceName
        }
        return name
    }

    /// 详细型号名称（优先使用 insight 中的型号名）
    var displayModelName: String? {
        // 优先使用 MobileDevice 提供的型号名
        if let insight, insight.modelName != L10n.deviceInfo.unknownModel {
            return insight.modelName
        }
        // 尝试从 modelID 映射
        if let modelID {
            let mapped = DeviceInsightService.modelName(for: modelID)
            if mapped != modelID {
                return mapped
            }
        }
        return modelID
    }

    /// iOS 版本
    var systemVersion: String? {
        insight?.systemVersion
    }

    /// 连接类型枚举
    enum ConnectionType: String {
        case usb = "USB"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .usb: "cable.connector"
            case .unknown: "questionmark.circle"
            }
        }
    }

    // MARK: - 初始化

    init(
        id: String,
        name: String,
        modelID: String? = nil,
        connectionType: ConnectionType = .usb,
        locationID: UInt32? = nil,
        captureDevice: AVCaptureDevice? = nil,
        insight: IOSDeviceInsight? = nil,
        userPrompt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.modelID = modelID
        self.connectionType = connectionType
        self.locationID = locationID
        self.captureDevice = captureDevice
        self.insight = insight
        self.userPrompt = userPrompt
    }

    // MARK: - 从 AVCaptureDevice 创建

    static func from(captureDevice: AVCaptureDevice) -> IOSDevice? {
        let deviceType = captureDevice.deviceType
        let rawName = captureDevice.localizedName
        let modelID = captureDevice.modelID

        // 必须是外部设备类型
        guard deviceType == .external else {
            return nil
        }

        // 检查设备是否真正连接（不是缓存的设备）
        guard !captureDevice.isSuspended else {
            return nil
        }

        // 检查是否是 iOS 设备（通过模型ID判断）
        let isIOSDevice = modelID.hasPrefix("iPhone") ||
            modelID.hasPrefix("iPad") ||
            modelID.hasPrefix("iPod")

        guard isIOSDevice else {
            return nil
        }

        // 额外验证：尝试获取设备确保它真正可用
        guard AVCaptureDevice(uniqueID: captureDevice.uniqueID) != nil else {
            return nil
        }

        // 清理设备名称，去掉系统添加的后缀
        let displayName = cleanDeviceName(rawName)

        // 获取 MobileDevice 增强信息（不影响主流程）
        let insightService = DeviceInsightService.shared
        let insight = insightService.getDeviceInsight(for: captureDevice.uniqueID)
        let userPrompt = insightService.getUserPrompt(for: insight)

        // 记录增强信息
        if insightService.isMobileDeviceAvailable {
            AppLogger.device.info(
                "发现 iOS 设备: \(insight.deviceName), 模型: \(insight.modelName), iOS: \(insight.systemVersion)"
            )
        } else {
            AppLogger.device.info("发现 iOS 设备: \(displayName), 模型: \(modelID)")
        }

        // 记录用户提示
        if let prompt = userPrompt {
            AppLogger.device.warning("设备状态提示: \(prompt)")
        }

        return IOSDevice(
            id: captureDevice.uniqueID,
            name: displayName,
            modelID: modelID,
            connectionType: .usb,
            locationID: nil,
            captureDevice: captureDevice,
            insight: insight,
            userPrompt: userPrompt
        )
    }

    /// 清理设备名称，去掉系统添加的后缀
    /// 例如: "Nokia"的相机 → Nokia
    ///       "iPhone"的桌上视角相机 → iPhone
    private static func cleanDeviceName(_ name: String) -> String {
        var cleanName = name

        // 去掉常见后缀
        let suffixes = [
            "的相机",
            "的桌上视角相机",
            "的摄像头",
            "'s Camera",
            "'s Desk View Camera",
            " Camera",
        ]

        for suffix in suffixes {
            if cleanName.hasSuffix(suffix) {
                cleanName = String(cleanName.dropLast(suffix.count))
                break
            }
        }

        // 去掉首尾引号（英文和中文引号）
        let quotePatterns: [(String, String)] = [
            ("\"", "\""),
            ("\u{201C}", "\u{201D}"), // 中文引号 " "
        ]

        for (openQuote, closeQuote) in quotePatterns {
            if cleanName.hasPrefix(openQuote), cleanName.hasSuffix(closeQuote) {
                cleanName = String(cleanName.dropFirst().dropLast())
                break
            }
        }

        return cleanName.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: IOSDevice, rhs: IOSDevice) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DeviceInfo 协议扩展

extension IOSDevice: DeviceInfo {
    var model: String? { modelID }
    var platform: DevicePlatform { .ios }
}
