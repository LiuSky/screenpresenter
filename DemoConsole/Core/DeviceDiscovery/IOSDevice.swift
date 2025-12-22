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
        AppLogger.device.debug("检查设备: \(name), 类型: \(deviceType.rawValue), 模型: \(modelID)")

        // 检查是否是 iOS 设备
        // 方法1：通过设备名称判断
        let isIOSDeviceByName = name.contains("iPhone") ||
            name.contains("iPad") ||
            name.contains("iPod")

        // 方法2：通过模型ID判断（iOS 设备的模型ID通常包含特定前缀）
        let isIOSDeviceByModel = modelID.hasPrefix("iOS Device") ||
            modelID.contains("Apple") ||
            modelID.contains("iPhone") ||
            modelID.contains("iPad")

        // 方法3：外部设备类型且不是普通摄像头
        let isExternalDevice = deviceType == .external || deviceType == .externalUnknown

        // 综合判断：是外部设备，且名称或模型匹配 iOS 设备
        let isIOSDevice = isExternalDevice && (isIOSDeviceByName || isIOSDeviceByModel)

        // 额外检查：即使不是 .external 类型，如果名称明确包含 iPhone/iPad 也接受
        let shouldAccept = isIOSDevice || isIOSDeviceByName

        guard shouldAccept else {
            AppLogger.device.debug("设备 \(name) 不是 iOS 设备，跳过")
            return nil
        }

        AppLogger.device.info("发现 iOS 设备: \(name)")

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
