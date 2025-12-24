//
//  IOSScreenMirrorActivator.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/22.
//
//  iOS 屏幕镜像激活器
//  使用 CoreMediaIO 启用屏幕捕获设备
//
//  【核心职责】
//  启用 CoreMediaIO DAL 设备（kCMIOHardwarePropertyAllowScreenCaptureDevices）
//  这是 QuickTime 同款路径的关键步骤
//

import CoreMediaIO
import Foundation

// MARK: - iOS 屏幕镜像激活器

/// iOS 屏幕镜像激活器
/// 负责启用 CoreMediaIO DAL 设备以允许访问 iOS 屏幕捕获
final class IOSScreenMirrorActivator {
    // MARK: - 单例

    static let shared = IOSScreenMirrorActivator()

    // MARK: - 状态

    /// 是否已启用 DAL 设备
    private(set) var isDALEnabled = false

    // MARK: - 初始化

    private init() {}

    // MARK: - 公开方法

    /// 启用 CoreMediaIO DAL 设备（允许访问屏幕捕获设备）
    /// 这是使用 AVFoundation 捕获 iOS 屏幕的必要步骤
    @discardableResult
    func enableDALDevices() -> Bool {
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var allow: UInt32 = 1
        let result = CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &prop,
            0, nil,
            UInt32(MemoryLayout<UInt32>.size),
            &allow
        )

        if result == kCMIOHardwareNoError {
            isDALEnabled = true
            AppLogger.device.info("已启用 CoreMediaIO 屏幕捕获设备 (DAL)")
            return true
        } else {
            isDALEnabled = false
            AppLogger.device.warning("启用 CoreMediaIO 屏幕捕获设备失败: \(result)")
            return false
        }
    }
}
