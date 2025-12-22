//
//  IOSDevice.swift
//  DemoConsole
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

    /// 连接类型枚举
    enum ConnectionType: String {
        case usb = "USB"
        case unknown = "未知"

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
        captureDevice: AVCaptureDevice? = nil
    ) {
        self.id = id
        self.name = name
        self.modelID = modelID
        self.connectionType = connectionType
        self.locationID = locationID
        self.captureDevice = captureDevice
    }

    // MARK: - 从 AVCaptureDevice 创建

    static func from(captureDevice: AVCaptureDevice) -> IOSDevice? {
        let deviceType = captureDevice.deviceType
        let name = captureDevice.localizedName
        let modelID = captureDevice.modelID

        // 调试日志
        AppLogger.device.debug(
            "检查设备: \(name), 类型: \(deviceType.rawValue), 模型: \(modelID), " +
                "是否暂停: \(captureDevice.isSuspended), 是否在用: \(captureDevice.isInUseByAnotherApplication)"
        )

        // 必须是外部设备类型
        let isExternalDevice = deviceType == .external || deviceType == .externalUnknown
        guard isExternalDevice else {
            AppLogger.device.debug("设备 \(name) 不是外部设备，跳过")
            return nil
        }

        // 检查设备是否真正连接（不是缓存的设备）
        // 已暂停的设备说明物理上已断开
        guard !captureDevice.isSuspended else {
            AppLogger.device.debug("设备 \(name) 已暂停（未连接），跳过")
            return nil
        }

        // 检查是否是 iOS 设备
        // 通过设备名称判断（名称通常包含 "iPhone"、"iPad" 等，或用户自定义名称 + "的相机"）
        let isIOSDeviceByName = name.contains("iPhone") ||
            name.contains("iPad") ||
            name.contains("iPod") ||
            name.hasSuffix("的相机") // 用户自定义名称的 iOS 设备

        // 通过模型ID判断（iOS 设备的模型ID格式如 "iPhone18,1"）
        let isIOSDeviceByModel = modelID.hasPrefix("iPhone") ||
            modelID.hasPrefix("iPad") ||
            modelID.hasPrefix("iPod")

        // 必须同时满足：外部设备 + (名称匹配 或 模型ID匹配)
        let isIOSDevice = isIOSDeviceByName || isIOSDeviceByModel

        guard isIOSDevice else {
            AppLogger.device.debug("设备 \(name) 不是 iOS 设备，跳过")
            return nil
        }

        // 额外验证：尝试获取设备确保它真正可用
        // 如果设备已断开，AVCaptureDevice(uniqueID:) 可能返回 nil 或设备不可用
        guard AVCaptureDevice(uniqueID: captureDevice.uniqueID) != nil else {
            AppLogger.device.debug("设备 \(name) 无法通过 ID 获取，跳过")
            return nil
        }

        AppLogger.device.info("发现 iOS 设备: \(name), 模型: \(modelID)")

        return IOSDevice(
            id: captureDevice.uniqueID,
            name: name,
            modelID: modelID,
            connectionType: .usb,
            locationID: nil,
            captureDevice: captureDevice
        )
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
