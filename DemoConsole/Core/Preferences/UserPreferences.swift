//
//  UserPreferences.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  用户偏好设置
//  持久化存储用户的各项配置选项（简化版）
//

import Foundation
import SwiftUI

// MARK: - 布局样式

/// 多设备布局样式
enum LayoutStyle: String, CaseIterable, Identifiable, Codable {
    case single = "single" // 单设备
    case sideBySide = "sideBySide" // 并排
    case grid = "grid" // 网格
    case pip = "pip" // 画中画
    case stack = "stack" // 堆叠

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: return "单设备"
        case .sideBySide: return "并排"
        case .grid: return "网格"
        case .pip: return "画中画"
        case .stack: return "堆叠"
        }
    }

    var icon: String {
        switch self {
        case .single: return "rectangle"
        case .sideBySide: return "rectangle.split.2x1"
        case .grid: return "rectangle.split.2x2"
        case .pip: return "pip"
        case .stack: return "rectangle.stack"
        }
    }
}

// MARK: - 主题模式

/// 主题模式
enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - 用户偏好设置模型

/// 用户偏好设置
final class UserPreferences: ObservableObject {

    // MARK: - Singleton

    static let shared = UserPreferences()

    // MARK: - Keys

    private enum Keys {
        static let defaultLayout = "defaultLayout"
        static let autoReconnect = "autoReconnect"
        static let reconnectDelay = "reconnectDelay"
        static let maxReconnectAttempts = "maxReconnectAttempts"
        static let themeMode = "themeMode"
        static let captureFrameRate = "captureFrameRate"
        static let scrcpyBitrate = "scrcpyBitrate"
        static let scrcpyMaxSize = "scrcpyMaxSize"
        static let scrcpyShowTouches = "scrcpyShowTouches"
    }

    // MARK: - Layout Settings

    /// 默认布局样式
    @AppStorage(Keys.defaultLayout)
    var defaultLayout: LayoutStyle = .single

    // MARK: - Connection Settings

    /// 是否自动重连
    @AppStorage(Keys.autoReconnect)
    var autoReconnect: Bool = true

    /// 重连延迟（秒）
    @AppStorage(Keys.reconnectDelay)
    var reconnectDelay: Double = 3.0

    /// 最大重连次数
    @AppStorage(Keys.maxReconnectAttempts)
    var maxReconnectAttempts: Int = 5

    // MARK: - Display Settings

    /// 主题模式
    @AppStorage(Keys.themeMode)
    var themeMode: ThemeMode = .system

    // MARK: - Capture Settings

    /// 捕获帧率
    @AppStorage(Keys.captureFrameRate)
    var captureFrameRate: Int = 60

    // MARK: - scrcpy Settings

    /// 码率（Mbps）
    @AppStorage(Keys.scrcpyBitrate)
    var scrcpyBitrate: Int = 8

    /// 最大分辨率
    @AppStorage(Keys.scrcpyMaxSize)
    var scrcpyMaxSize: Int = 1920

    /// 显示触摸点
    @AppStorage(Keys.scrcpyShowTouches)
    var scrcpyShowTouches: Bool = true

    // MARK: - Private Init

    private init() {}

    // MARK: - scrcpy 配置生成

    /// 生成 scrcpy 配置
    func generateScrcpyConfig() -> ScrcpyConfig {
        var config = ScrcpyConfig()
        config.bitrate = "\(scrcpyBitrate)M"
        config.maxSize = scrcpyMaxSize
        config.maxFps = captureFrameRate
        config.stayAwake = true
        return config
    }

    /// 为特定设备构建 scrcpy 配置
    func buildScrcpyConfiguration(serial: String) -> ScrcpyConfiguration {
        ScrcpyConfiguration(
            serial: serial,
            maxSize: scrcpyMaxSize,
            bitrate: scrcpyBitrate * 1_000_000,
            maxFps: captureFrameRate,
            showTouches: scrcpyShowTouches,
            stayAwake: true
        )
    }
}

// MARK: - AppStorage Extensions for Custom Types

extension LayoutStyle: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "single": self = .single
        case "sideBySide": self = .sideBySide
        case "grid": self = .grid
        case "pip": self = .pip
        case "stack": self = .stack
        default: return nil
        }
    }
}

extension ThemeMode: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "system": self = .system
        case "light": self = .light
        case "dark": self = .dark
        default: return nil
        }
    }
}
