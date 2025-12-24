//
//  DeviceModel.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/23.
//
//  设备型号定义
//  包含各代 iPhone/Android 设备的外观参数
//
//  规格数据参考:
//  - https://www.screensizes.app/
//  - Apple Human Interface Guidelines
//  - 各代 iPhone 实测数据
//

import AppKit

// MARK: - 设备型号定义

/// 设备型号，包含具体设备的外观参数
/// 不同代 iPhone 的参数按照真实设备规格实现
///
/// 数据来源: https://www.screensizes.app/
enum DeviceModel: Equatable {
    // MARK: - iPhone 动态岛系列

    /// iPhone 17 Pro / 17 Pro Max (2025)
    /// - 17 Pro: 6.3" 2622×1206 @460ppi, 边框预计 ~1.0mm
    /// - 17 Pro Max: 6.9" 2868×1320 @460ppi, 边框预计 ~1.0mm
    case iPhone17Pro

    /// iPhone 17 / 17 Air (2025)
    /// - 17: 6.3" 2622×1206 @460ppi
    /// - 17 Air: 6.6" 2740×1280 @460ppi (超薄设计)
    case iPhone17

    /// iPhone 16 Pro / 16 Pro Max (2024)
    /// - 16 Pro: 6.3" 2622×1206 @460ppi, 设备宽 71.5mm, 边框 1.15mm
    /// - 16 Pro Max: 6.9" 2868×1320 @460ppi, 设备宽 77.6mm, 边框 1.15mm
    case iPhone16Pro

    /// iPhone 16 / 16 Plus (2024)
    /// - 16: 6.1" 2556×1179 @460ppi, 设备宽 71.6mm, 边框 1.85mm
    /// - 16 Plus: 6.7" 2796×1290 @460ppi, 设备宽 77.8mm, 边框 1.85mm
    case iPhone16

    /// iPhone 15 Pro / 15 Pro Max (2023)
    /// - 15 Pro: 6.1" 2556×1179 @460ppi, 设备宽 70.6mm, 边框 1.55mm
    /// - 15 Pro Max: 6.7" 2796×1290 @460ppi, 设备宽 76.7mm, 边框 1.55mm
    case iPhone15Pro

    /// iPhone 15 / 15 Plus (2023)
    /// - 15: 6.1" 2556×1179 @460ppi, 设备宽 71.6mm, 边框 1.80mm
    /// - 15 Plus: 6.7" 2796×1290 @460ppi, 设备宽 77.8mm, 边框 1.80mm
    case iPhone15

    /// iPhone 14 Pro / 14 Pro Max (2022) - 首款动态岛
    /// - 14 Pro: 6.1" 2556×1179 @460ppi, 设备宽 71.5mm, 边框 1.95mm
    /// - 14 Pro Max: 6.7" 2796×1290 @460ppi, 设备宽 77.6mm, 边框 1.95mm
    case iPhone14Pro

    // MARK: - iPhone 刘海屏系列

    /// iPhone 14 / 14 Plus (2022) - 小刘海
    /// - 14: 6.1" 2532×1170 @460ppi, 设备宽 71.5mm, 边框 2.39mm
    /// - 14 Plus: 6.7" 2778×1284 @458ppi, 设备宽 78.1mm, 边框 2.39mm
    case iPhone14

    /// iPhone 13 / 13 mini (2021) - 刘海比 12 系列小 20%
    /// - 13: 6.1" 2532×1170 @460ppi, 设备宽 71.5mm, 边框 2.40mm
    /// - 13 mini: 5.4" 2340×1080 @476ppi, 设备宽 64.2mm, 边框 2.20mm
    case iPhone13

    /// iPhone 13 Pro / 13 Pro Max (2021)
    /// - 13 Pro: 6.1" 2532×1170 @460ppi, 设备宽 71.5mm, 边框 2.40mm
    /// - 13 Pro Max: 6.7" 2778×1284 @458ppi, 设备宽 78.1mm, 边框 2.40mm
    case iPhone13Pro

    /// iPhone 12 系列 (2020) - 直角边框设计
    /// - 12: 6.1" 2532×1170 @460ppi, 设备宽 71.5mm, 边框 2.65mm
    /// - 12 Pro Max: 6.7" 2778×1284 @458ppi, 设备宽 78.1mm, 边框 2.65mm
    case iPhone12

    /// iPhone 11 系列 (2019) - 圆角边框
    /// - 11: 6.1" 1792×828 @326ppi, 设备宽 75.7mm, 边框 3.50mm
    /// - 11 Pro Max: 6.5" 2688×1242 @458ppi, 设备宽 77.8mm, 边框 3.50mm
    case iPhone11

    /// iPhone X / XS / XR (2017-2018) - 首款刘海屏
    /// - X: 5.8" 2436×1125 @458ppi, 设备宽 70.9mm, 边框 4.00mm
    /// - XS Max: 6.5" 2688×1242 @458ppi, 设备宽 77.4mm, 边框 4.00mm
    /// - XR: 6.1" 1792×828 @326ppi, 设备宽 75.7mm, 边框 4.50mm
    case iPhoneX

    // MARK: - iPhone Home 键系列

    /// iPhone SE (所有代) - 4.7" 1334×750 @326ppi
    /// 设备宽 67.3mm, 边框 4.00mm (左右), 顶部/底部更宽
    case iPhoneSE

    /// iPhone 8 / 8 Plus 及更早
    /// - 8: 4.7" 1334×750 @326ppi, 设备宽 67.3mm
    /// - 8 Plus: 5.5" 1920×1080 @401ppi, 设备宽 78.1mm
    case iPhoneLegacy

    // MARK: - iPhone 通用

    /// iPhone 通用（未识别具体型号时使用动态岛样式）
    case iPhoneGeneric

    // MARK: - Android 系列

    /// 三星 Galaxy S 系列 (打孔屏，居中)
    case samsungGalaxyS
    /// 三星 Galaxy Z Fold (折叠屏展开)
    case samsungGalaxyFold
    /// Google Pixel 系列 (打孔屏，左上角)
    case googlePixel
    /// 小米系列 (打孔屏，居中或左上角)
    case xiaomi
    /// 一加系列
    case oneplus
    /// OPPO / Vivo 系列
    case oppoVivo
    /// Android 通用
    case androidGeneric

    // MARK: - 通用

    /// 完全未知设备
    case unknown
}

// MARK: - 屏幕参数

extension DeviceModel {
    /// 屏幕圆角半径比例（相对于屏幕宽度）
    /// 数据来源: Apple Human Interface Guidelines, screensizes.app
    ///
    /// | 设备 | 屏幕圆角 (pt) | 屏幕宽度 (pt) | 比例 |
    /// |-----|-------------|--------------|------|
    /// | iPhone 16/15/14 Pro | 55 | 393 | 0.140 |
    /// | iPhone 16/15 | 55 | 393 | 0.140 |
    /// | iPhone 14/13/12 | 47.33 | 390 | 0.121 |
    /// | iPhone 11 Pro | 39 | 375 | 0.104 |
    /// | iPhone 11/XR | 41.5 | 414 | 0.100 |
    /// | iPhone X/XS | 39 | 375 | 0.104 |
    /// | iPhone SE | 0 | 375 | 0 |
    var screenCornerRadiusRatio: CGFloat {
        switch self {
        // iPhone 17 Pro - 预计与 16 Pro 相同
        case .iPhone17Pro:
            0.140
        // iPhone 17 - 预计与 16 Pro 相同
        case .iPhone17:
            0.140
        // iPhone 16 Pro - 屏幕圆角 55pt / 393pt
        case .iPhone16Pro:
            0.140
        // iPhone 16 - 屏幕圆角 55pt / 393pt
        case .iPhone16:
            0.140
        // iPhone 15 Pro - 屏幕圆角 55pt / 393pt
        case .iPhone15Pro:
            0.140
        // iPhone 15 - 屏幕圆角 55pt / 393pt
        case .iPhone15:
            0.140
        // iPhone 14 Pro - 屏幕圆角 55pt / 393pt
        case .iPhone14Pro:
            0.140
        // iPhone 14 - 屏幕圆角 47.33pt / 390pt
        case .iPhone14:
            0.121
        // iPhone 13 系列 - 屏幕圆角 47.33pt / 390pt
        case .iPhone13, .iPhone13Pro:
            0.121
        // iPhone 12 系列 - 屏幕圆角 47.33pt / 390pt
        case .iPhone12:
            0.121
        // iPhone 11 系列 - 屏幕圆角 39-41.5pt
        case .iPhone11:
            0.100
        // iPhone X/XS/XR - 屏幕圆角 39pt / 375pt
        case .iPhoneX:
            0.104
        // iPhone SE / Legacy - 无屏幕圆角
        case .iPhoneSE, .iPhoneLegacy:
            0.0
        // iPhone 通用 - 使用 Pro 系列参数
        case .iPhoneGeneric:
            0.140
        // Android 系列
        case .samsungGalaxyS, .googlePixel, .xiaomi, .oneplus, .oppoVivo:
            0.08
        case .samsungGalaxyFold:
            0.05
        case .androidGeneric:
            0.07
        case .unknown:
            0.08
        }
    }

    /// 默认屏幕内容区域的宽高比 (宽度 / 高度)
    /// 这是用于 DeviceBezelView 的主要参数，确保屏幕区域与视频宽高比一致
    /// 数据来源: screensizes.app
    var defaultScreenAspectRatio: CGFloat {
        defaultAspectRatio
    }

    /// 默认宽高比 (宽度 / 高度)
    /// 数据来源: screensizes.app
    var defaultAspectRatio: CGFloat {
        switch self {
        // iPhone 17 Pro Max - 6.9" (2868×1320)
        case .iPhone17Pro:
            1320.0 / 2868.0
        // iPhone 17 Air - 6.6" (2740×1280)
        case .iPhone17:
            1280.0 / 2740.0
        // iPhone 16 Pro Max - 6.9" (2868×1320)
        case .iPhone16Pro:
            1320.0 / 2868.0
        // iPhone 16 Plus - 6.7" (2796×1290)
        case .iPhone16:
            1290.0 / 2796.0
        // iPhone 15 Pro Max
        case .iPhone15Pro:
            1290.0 / 2796.0
        // iPhone 15 Plus
        case .iPhone15:
            1290.0 / 2796.0
        // iPhone 14 Pro Max
        case .iPhone14Pro:
            1290.0 / 2796.0
        // iPhone 14 Plus
        case .iPhone14:
            1284.0 / 2778.0
        // iPhone 13 Pro Max
        case .iPhone13Pro:
            1284.0 / 2778.0
        // iPhone 13
        case .iPhone13:
            1170.0 / 2532.0
        // iPhone 12 Pro Max
        case .iPhone12:
            1284.0 / 2778.0
        // iPhone 11 Pro Max
        case .iPhone11:
            1242.0 / 2688.0
        // iPhone XS Max
        case .iPhoneX:
            1242.0 / 2688.0
        // iPhone SE
        case .iPhoneSE:
            750.0 / 1334.0
        // iPhone 8 Plus
        case .iPhoneLegacy:
            1080.0 / 1920.0
        // iPhone 通用
        case .iPhoneGeneric:
            1290.0 / 2796.0
        // Android 系列
        case .samsungGalaxyS:
            1080.0 / 2340.0
        case .samsungGalaxyFold:
            1812.0 / 2176.0
        case .googlePixel:
            1080.0 / 2400.0
        case .xiaomi, .oneplus, .oppoVivo:
            1080.0 / 2400.0
        case .androidGeneric:
            1080.0 / 2400.0
        case .unknown:
            9.0 / 19.0
        }
    }
}

// MARK: - 边框参数

extension DeviceModel {
    /// 金属外壳边框宽度比例（相对于设备宽度）
    /// 金属边框是设备最外层的金属/钛金属框架的可视厚度
    ///
    /// 真实 iPhone 金属边框可视部分很薄，约 0.3-0.5mm
    /// 设备宽约 72mm，比例 ≈ 0.4 / 72 ≈ 0.006
    var metalFrameWidthRatio: CGFloat {
        switch self {
        // iPhone 17 Pro - 钛金属边框
        case .iPhone17Pro:
            0.006
        // iPhone 17 - 铝金属边框
        case .iPhone17:
            0.007
        // iPhone 16 Pro - 钛金属边框
        case .iPhone16Pro:
            0.006
        // iPhone 16 - 铝金属边框
        case .iPhone16:
            0.007
        // iPhone 15 Pro - 钛金属边框
        case .iPhone15Pro:
            0.006
        // iPhone 15 - 铝金属边框
        case .iPhone15:
            0.007
        // iPhone 14 Pro - 不锈钢边框
        case .iPhone14Pro:
            0.007
        // iPhone 14 - 铝金属边框
        case .iPhone14:
            0.008
        // iPhone 13 系列
        case .iPhone13, .iPhone13Pro:
            0.008
        // iPhone 12 系列 - 直角边框设计
        case .iPhone12:
            0.008
        // iPhone 11 系列 - 圆润边框
        case .iPhone11:
            0.010
        // iPhone X/XS/XR
        case .iPhoneX:
            0.012
        // iPhone SE - 较厚边框
        case .iPhoneSE:
            0.015
        // iPhone Legacy
        case .iPhoneLegacy:
            0.015
        // iPhone 通用
        case .iPhoneGeneric:
            0.007
        // Android 系列
        case .samsungGalaxyS, .googlePixel, .xiaomi, .oneplus, .oppoVivo:
            0.006
        case .samsungGalaxyFold:
            0.005
        case .androidGeneric:
            0.007
        case .unknown:
            0.007
        }
    }

    /// 屏幕黑边框宽度比例（相对于设备宽度）
    /// 屏幕黑边框是金属边框内侧、屏幕显示区域外侧的黑色边框
    /// 数据来源: 实测数据, screensizes.app
    ///
    /// | 设备 | 黑边框 (mm) | 设备宽 (mm) | 比例 |
    /// |-----|------------|-----------|------|
    /// | iPhone 16 Pro | 1.15 | 71.5 | 0.0161 |
    /// | iPhone 16 | 1.85 | 71.6 | 0.0258 |
    /// | iPhone 15 Pro | 1.55 | 70.6 | 0.0220 |
    /// | iPhone 15 | 1.80 | 71.6 | 0.0251 |
    /// | iPhone 14 Pro | 1.95 | 71.5 | 0.0273 |
    /// | iPhone 14 | 2.39 | 71.5 | 0.0334 |
    /// | iPhone 13 | 2.40 | 71.5 | 0.0336 |
    /// | iPhone 12 | 2.65 | 71.5 | 0.0371 |
    /// | iPhone 11 | 3.50 | 75.7 | 0.0462 |
    /// | iPhone X | 4.00 | 70.9 | 0.0564 |
    /// | iPhone SE | 4.00 | 67.3 | 0.0594 |
    var screenBezelWidthRatio: CGFloat {
        switch self {
        // iPhone 17 Pro - 预计 ~1.0mm (更窄边框)
        case .iPhone17Pro:
            0.014
        // iPhone 17 - 预计与 16 Pro 相近
        case .iPhone17:
            0.016
        // iPhone 16 Pro - 1.15mm / 71.5mm (业界最窄边框)
        case .iPhone16Pro:
            0.016
        // iPhone 16 - 1.85mm / 71.6mm
        case .iPhone16:
            0.026
        // iPhone 15 Pro - 1.55mm / 70.6mm
        case .iPhone15Pro:
            0.022
        // iPhone 15 - 1.80mm / 71.6mm
        case .iPhone15:
            0.025
        // iPhone 14 Pro - 1.95mm / 71.5mm
        case .iPhone14Pro:
            0.027
        // iPhone 14 - 2.39mm / 71.5mm
        case .iPhone14:
            0.033
        // iPhone 13 系列 - 2.40mm / 71.5mm
        case .iPhone13, .iPhone13Pro:
            0.034
        // iPhone 12 系列 - 2.65mm / 71.5mm
        case .iPhone12:
            0.037
        // iPhone 11 系列 - 3.50mm / 75.7mm
        case .iPhone11:
            0.046
        // iPhone X/XS/XR - 4.00mm / 70.9mm
        case .iPhoneX:
            0.056
        // iPhone SE - 4.00mm / 67.3mm (左右), 顶部底部更宽
        case .iPhoneSE:
            0.059
        // iPhone Legacy
        case .iPhoneLegacy:
            0.059
        // iPhone 通用 - 使用 15 系列参数
        case .iPhoneGeneric:
            0.025
        // Android 系列
        case .samsungGalaxyS, .googlePixel, .xiaomi, .oneplus, .oppoVivo:
            0.020
        case .samsungGalaxyFold:
            0.015
        case .androidGeneric:
            0.025
        case .unknown:
            0.025
        }
    }

    /// 总边框宽度比例（金属边框 + 屏幕黑边框）
    var totalBezelWidthRatio: CGFloat {
        metalFrameWidthRatio + screenBezelWidthRatio
    }

    /// 边框圆角半径比例（相对于设备宽度）
    /// 设备整体圆角略大于屏幕圆角
    var bezelCornerRadiusRatio: CGFloat {
        switch self {
        // iPhone 17 Pro - 预计与 16 Pro 相近
        case .iPhone17Pro:
            0.153
        // iPhone 17 - 预计与 16 Pro 相近
        case .iPhone17:
            0.153
        // iPhone 16 Pro - 设备圆角约 60pt / 393pt
        case .iPhone16Pro:
            0.153
        // iPhone 16 - 设备圆角约 58pt / 393pt
        case .iPhone16:
            0.148
        // iPhone 15 Pro
        case .iPhone15Pro:
            0.153
        // iPhone 15
        case .iPhone15:
            0.148
        // iPhone 14 Pro
        case .iPhone14Pro:
            0.153
        // iPhone 14
        case .iPhone14:
            0.138
        // iPhone 13 系列
        case .iPhone13, .iPhone13Pro:
            0.138
        // iPhone 12 系列 - 直角边框设计，设备整体有圆角
        case .iPhone12:
            0.138
        // iPhone 11 系列 - 圆润边框
        case .iPhone11:
            0.116
        // iPhone X/XS/XR
        case .iPhoneX:
            0.123
        // iPhone SE - 较小圆角
        case .iPhoneSE:
            0.030
        // iPhone Legacy
        case .iPhoneLegacy:
            0.025
        // iPhone 通用
        case .iPhoneGeneric:
            0.148
        // Android 系列
        case .samsungGalaxyS, .googlePixel, .xiaomi, .oneplus, .oppoVivo:
            0.10
        case .samsungGalaxyFold:
            0.06
        case .androidGeneric:
            0.08
        case .unknown:
            0.08
        }
    }

    /// 边框基础颜色
    var bezelBaseColor: NSColor {
        switch self {
        // iPhone 17/16/15 Pro - 钛金属
        case .iPhone17Pro, .iPhone16Pro, .iPhone15Pro:
            NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        // iPhone 14 Pro - 不锈钢
        case .iPhone14Pro:
            NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        // iPhone 标准版 - 铝金属
        case .iPhone17, .iPhone16, .iPhone15, .iPhone14, .iPhone13, .iPhone13Pro, .iPhone12, .iPhone11, .iPhoneX:
            NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        // iPhone SE / Legacy
        case .iPhoneSE, .iPhoneLegacy:
            NSColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0)
        // iPhone 通用
        case .iPhoneGeneric:
            NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        // Android 系列
        case .samsungGalaxyS, .samsungGalaxyFold:
            NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        case .googlePixel:
            NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        case .xiaomi, .oneplus, .oppoVivo:
            NSColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0)
        case .androidGeneric:
            NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        case .unknown:
            NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
        }
    }

    /// 边框高光颜色
    var bezelHighlightColor: NSColor {
        switch self {
        case .iPhone17Pro, .iPhone16Pro, .iPhone15Pro:
            NSColor(white: 0.32, alpha: 1.0) // 钛金属高光
        case .iPhone14Pro:
            NSColor(white: 0.35, alpha: 1.0) // 不锈钢高光
        default:
            NSColor(white: 0.28, alpha: 1.0)
        }
    }
}

// MARK: - 顶部特征

extension DeviceModel {
    /// 顶部特征类型
    enum TopFeature {
        case none
        /// 动态岛 - widthRatio 相对于屏幕宽度，heightRatio 相对于屏幕宽度
        case dynamicIsland(widthRatio: CGFloat, heightRatio: CGFloat)
        /// 刘海 - widthRatio 相对于屏幕宽度，heightRatio 相对于屏幕宽度
        case notch(widthRatio: CGFloat, heightRatio: CGFloat)
        /// 打孔摄像头
        case punchHole(position: PunchHolePosition, sizeRatio: CGFloat)
        /// Home 键
        case homeButton
    }

    enum PunchHolePosition {
        case center
        case topLeft
        case topRight
    }

    /// 顶部特征配置
    /// 动态岛和刘海的尺寸按真实设备比例
    ///
    /// **动态岛尺寸** (iPhone 14 Pro+):
    /// - 宽度: 126pt / 393pt = 0.321
    /// - 高度: 36pt (药丸形状)
    ///
    /// **刘海尺寸**:
    /// | 设备 | 宽度 (pt) | 屏幕宽 (pt) | 比例 | 高度 (pt) |
    /// |-----|----------|-----------|------|----------|
    /// | iPhone 14/13 | 162 | 390 | 0.415 | 34 |
    /// | iPhone 12 | 209 | 390 | 0.536 | 32 |
    /// | iPhone 11/X | 209 | 375-414 | 0.50-0.56 | 30 |
    var topFeature: TopFeature {
        switch self {
        // iPhone 17 Pro - 动态岛
        case .iPhone17Pro:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 17 - 动态岛
        case .iPhone17:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 16 Pro - 动态岛 126pt×36pt / 393pt
        case .iPhone16Pro:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 16 - 动态岛
        case .iPhone16:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 15 Pro - 动态岛
        case .iPhone15Pro:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 15 - 动态岛
        case .iPhone15:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 14 Pro - 首款动态岛
        case .iPhone14Pro:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // iPhone 14 - 小刘海 162pt×34pt / 390pt
        case .iPhone14:
            .notch(widthRatio: 0.415, heightRatio: 0.087)
        // iPhone 13 系列 - 小刘海 (比 12 系列小 20%)
        case .iPhone13, .iPhone13Pro:
            .notch(widthRatio: 0.415, heightRatio: 0.087)
        // iPhone 12 系列 - 中刘海 209pt×32pt / 390pt
        case .iPhone12:
            .notch(widthRatio: 0.536, heightRatio: 0.082)
        // iPhone 11 系列 - 大刘海 209pt×30pt / 414pt
        case .iPhone11:
            .notch(widthRatio: 0.505, heightRatio: 0.072)
        // iPhone X/XS/XR - 大刘海 209pt×30pt / 375pt
        case .iPhoneX:
            .notch(widthRatio: 0.557, heightRatio: 0.080)
        // iPhone SE / Legacy - Home 键
        case .iPhoneSE, .iPhoneLegacy:
            .homeButton
        // iPhone 通用 - 使用动态岛
        case .iPhoneGeneric:
            .dynamicIsland(widthRatio: 0.321, heightRatio: 0.092)
        // Android 系列
        case .samsungGalaxyS, .xiaomi, .oppoVivo:
            .punchHole(position: .center, sizeRatio: 0.028)
        case .googlePixel:
            .punchHole(position: .topLeft, sizeRatio: 0.028)
        case .oneplus:
            .punchHole(position: .topLeft, sizeRatio: 0.025)
        case .samsungGalaxyFold:
            .punchHole(position: .topRight, sizeRatio: 0.022)
        case .androidGeneric:
            .punchHole(position: .center, sizeRatio: 0.025)
        case .unknown:
            .none
        }
    }
}

// MARK: - 侧边按钮

extension DeviceModel {
    /// 侧边按钮布局
    struct SideButtons {
        let left: [ButtonSpec]
        let right: [ButtonSpec]

        struct ButtonSpec {
            let type: ButtonType
            let topRatio: CGFloat
            let heightRatio: CGFloat
            let width: CGFloat

            enum ButtonType {
                case silentSwitch
                case actionButton // iPhone 15 Pro+ 的操作按钮
                case cameraControl // iPhone 16 Pro 的相机控制按钮
                case volumeUp
                case volumeDown
                case power
            }
        }
    }

    /// 按钮颜色
    var buttonColor: NSColor {
        switch self {
        case .iPhone17Pro, .iPhone16Pro, .iPhone15Pro:
            NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)
        default:
            NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        }
    }

    /// 按钮高光颜色
    var buttonHighlightColor: NSColor {
        NSColor(white: 0.32, alpha: 1.0)
    }

    /// 侧边按钮布局
    /// 位置参数基于真实设备测量数据，参考 iPhone 17 Pro SVG 矢量图
    /// - topRatio: 按钮顶部距离设备顶部的比例
    /// - heightRatio: 按钮高度占设备高度的比例
    ///
    /// iPhone 17 Pro 参考数据 (设备高度 150mm):
    /// - Action Button: y=30.69mm, h=6.97mm → top=0.205, height=0.046
    /// - Volume Up: y=42.77mm, h=11.24mm → top=0.285, height=0.075
    /// - Volume Down: y=57.00mm, h=11.24mm → top=0.380, height=0.075
    /// - Power: y=46.58mm, h=17.66mm → top=0.311, height=0.118
    ///
    /// 注意: Camera Control 按钮在正面视觉上不可见，不绘制
    var sideButtons: SideButtons {
        switch self {
        // iPhone 17 Pro - 操作按钮 + 音量按钮（基于 SVG 精确测量）
        case .iPhone17Pro:
            SideButtons(
                left: [
                    .init(type: .actionButton, topRatio: 0.205, heightRatio: 0.046, width: 3),
                    .init(type: .volumeUp, topRatio: 0.285, heightRatio: 0.075, width: 3),
                    .init(type: .volumeDown, topRatio: 0.380, heightRatio: 0.075, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.311, heightRatio: 0.118, width: 3),
                ]
            )
        // iPhone 17 - 操作按钮 + 音量按钮（与 17 Pro 相同布局）
        case .iPhone17:
            SideButtons(
                left: [
                    .init(type: .actionButton, topRatio: 0.205, heightRatio: 0.046, width: 3),
                    .init(type: .volumeUp, topRatio: 0.285, heightRatio: 0.075, width: 3),
                    .init(type: .volumeDown, topRatio: 0.380, heightRatio: 0.075, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.311, heightRatio: 0.118, width: 3),
                ]
            )
        // iPhone 16 Pro - 操作按钮 + 音量按钮（与 17 Pro 相似布局）
        case .iPhone16Pro:
            SideButtons(
                left: [
                    .init(type: .actionButton, topRatio: 0.205, heightRatio: 0.046, width: 3),
                    .init(type: .volumeUp, topRatio: 0.285, heightRatio: 0.075, width: 3),
                    .init(type: .volumeDown, topRatio: 0.380, heightRatio: 0.075, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.311, heightRatio: 0.118, width: 3),
                ]
            )
        // iPhone 16 标准版 - 操作按钮 + 音量按钮
        case .iPhone16:
            SideButtons(
                left: [
                    .init(type: .actionButton, topRatio: 0.205, heightRatio: 0.046, width: 3),
                    .init(type: .volumeUp, topRatio: 0.285, heightRatio: 0.075, width: 3),
                    .init(type: .volumeDown, topRatio: 0.380, heightRatio: 0.075, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.311, heightRatio: 0.118, width: 3),
                ]
            )
        // iPhone 15 Pro - 操作按钮替代静音开关
        case .iPhone15Pro:
            SideButtons(
                left: [
                    .init(type: .actionButton, topRatio: 0.205, heightRatio: 0.046, width: 3),
                    .init(type: .volumeUp, topRatio: 0.285, heightRatio: 0.075, width: 3),
                    .init(type: .volumeDown, topRatio: 0.380, heightRatio: 0.075, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.311, heightRatio: 0.118, width: 3),
                ]
            )
        // iPhone 15/14 Pro/14/13/12 - 静音开关 + 音量按钮
        case .iPhone15, .iPhone14Pro, .iPhone14, .iPhone13, .iPhone13Pro, .iPhone12:
            SideButtons(
                left: [
                    .init(type: .silentSwitch, topRatio: 0.195, heightRatio: 0.030, width: 3),
                    .init(type: .volumeUp, topRatio: 0.270, heightRatio: 0.070, width: 3),
                    .init(type: .volumeDown, topRatio: 0.360, heightRatio: 0.070, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.300, heightRatio: 0.110, width: 3),
                ]
            )
        // iPhone 11/X 系列 - 按钮位置稍有不同
        case .iPhone11, .iPhoneX:
            SideButtons(
                left: [
                    .init(type: .silentSwitch, topRatio: 0.175, heightRatio: 0.028, width: 3),
                    .init(type: .volumeUp, topRatio: 0.245, heightRatio: 0.065, width: 3),
                    .init(type: .volumeDown, topRatio: 0.330, heightRatio: 0.065, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.280, heightRatio: 0.100, width: 3),
                ]
            )
        // iPhone SE / Legacy - 按钮位置更靠上
        case .iPhoneSE, .iPhoneLegacy:
            SideButtons(
                left: [
                    .init(type: .silentSwitch, topRatio: 0.135, heightRatio: 0.025, width: 3),
                    .init(type: .volumeUp, topRatio: 0.195, heightRatio: 0.055, width: 3),
                    .init(type: .volumeDown, topRatio: 0.270, heightRatio: 0.055, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.135, heightRatio: 0.055, width: 3),
                ]
            )
        // iPhone 通用
        case .iPhoneGeneric:
            SideButtons(
                left: [
                    .init(type: .silentSwitch, topRatio: 0.195, heightRatio: 0.030, width: 3),
                    .init(type: .volumeUp, topRatio: 0.270, heightRatio: 0.070, width: 3),
                    .init(type: .volumeDown, topRatio: 0.360, heightRatio: 0.070, width: 3),
                ],
                right: [
                    .init(type: .power, topRatio: 0.300, heightRatio: 0.110, width: 3),
                ]
            )
        // Android 系列 - 按钮在右侧
        case .samsungGalaxyS, .samsungGalaxyFold, .googlePixel, .xiaomi, .oneplus, .oppoVivo:
            SideButtons(
                left: [],
                right: [
                    .init(type: .volumeUp, topRatio: 0.250, heightRatio: 0.075, width: 2.5),
                    .init(type: .volumeDown, topRatio: 0.345, heightRatio: 0.075, width: 2.5),
                    .init(type: .power, topRatio: 0.460, heightRatio: 0.050, width: 2.5),
                ]
            )
        case .androidGeneric:
            SideButtons(
                left: [],
                right: [
                    .init(type: .volumeUp, topRatio: 0.260, heightRatio: 0.070, width: 2.5),
                    .init(type: .volumeDown, topRatio: 0.350, heightRatio: 0.070, width: 2.5),
                    .init(type: .power, topRatio: 0.460, heightRatio: 0.050, width: 2.5),
                ]
            )
        case .unknown:
            SideButtons(left: [], right: [])
        }
    }
}

// MARK: - 设备信息

extension DeviceModel {
    /// 是否为 iOS 设备
    var isIOS: Bool {
        switch self {
        case .iPhone17Pro, .iPhone17, .iPhone16Pro, .iPhone16, .iPhone15Pro, .iPhone15, .iPhone14Pro, .iPhone14,
             .iPhone13, .iPhone13Pro, .iPhone12, .iPhone11, .iPhoneX,
             .iPhoneSE, .iPhoneLegacy, .iPhoneGeneric:
            true
        default:
            false
        }
    }

    /// 设备显示名称（用于 UI 文案）
    var displayName: String {
        switch self {
        case .iPhone17Pro:
            "iPhone 17 Pro"
        case .iPhone17:
            "iPhone 17"
        case .iPhone16Pro:
            "iPhone 16 Pro"
        case .iPhone16:
            "iPhone 16"
        case .iPhone15Pro:
            "iPhone 15 Pro"
        case .iPhone15:
            "iPhone 15"
        case .iPhone14Pro:
            "iPhone 14 Pro"
        case .iPhone14:
            "iPhone 14"
        case .iPhone13Pro:
            "iPhone 13 Pro"
        case .iPhone13:
            "iPhone 13"
        case .iPhone12:
            "iPhone 12"
        case .iPhone11:
            "iPhone 11"
        case .iPhoneX:
            "iPhone X"
        case .iPhoneSE:
            "iPhone SE"
        case .iPhoneLegacy:
            "iPhone"
        case .iPhoneGeneric:
            "iPhone"
        case .samsungGalaxyS:
            "Samsung Galaxy"
        case .samsungGalaxyFold:
            "Samsung Fold"
        case .googlePixel:
            "Google Pixel"
        case .xiaomi:
            "Xiaomi"
        case .oneplus:
            "OnePlus"
        case .oppoVivo:
            "OPPO/Vivo"
        case .androidGeneric:
            "Android"
        case .unknown:
            "Device"
        }
    }
}

// MARK: - 设备识别

extension DeviceModel {
    /// 根据 iOS 设备的 productType（型号标识符）识别设备型号
    /// 这是最精确的识别方式，基于设备硬件标识
    ///
    /// - Parameter productType: iOS 设备型号标识符，如 "iPhone17,1"
    /// - Returns: 对应的 DeviceModel
    ///
    /// 型号标识符参考：
    /// - iPhone 18.x = iPhone 17 系列 (2025)
    /// - iPhone 17.x = iPhone 16 系列 (2024)
    /// - iPhone 16.x = iPhone 15 系列 (2023)
    /// - iPhone 15.x = iPhone 14 系列 (2022)
    /// - iPhone 14.x = iPhone 13 系列 (2021)
    /// - iPhone 13.x = iPhone 12 系列 (2020)
    /// - iPhone 12.x = iPhone 11 系列 (2019)
    /// - iPhone 11.x = iPhone XS/XR 系列 (2018)
    /// - iPhone 10.x = iPhone X/8 系列 (2017)
    static func from(productType: String?) -> DeviceModel {
        guard let type = productType, !type.isEmpty else {
            return .iPhoneGeneric
        }

        // 提取主版本号（如 "iPhone17,1" -> 17）
        let components = type.replacingOccurrences(of: "iPhone", with: "").split(separator: ",")
        guard let majorStr = components.first, let major = Int(majorStr) else {
            // 尝试名称匹配作为 fallback
            return identifyiPhone(from: type.lowercased())
        }

        let minor = components.count > 1 ? Int(components[1]) ?? 0 : 0

        switch major {
        // iPhone 18.x = iPhone 17 系列 (2025)
        case 18:
            switch minor {
            case 1, 2: // iPhone 17 Pro / Pro Max
                return .iPhone17Pro
            default: // iPhone 17 / Plus / Air
                return .iPhone17
            }

        // iPhone 17.x = iPhone 16 系列 (2024)
        case 17:
            switch minor {
            case 1, 2: // iPhone 16 Pro / Pro Max
                return .iPhone16Pro
            default: // iPhone 16 / Plus
                return .iPhone16
            }

        // iPhone 16.x = iPhone 15 系列 (2023)
        case 16:
            switch minor {
            case 1, 2: // iPhone 15 Pro / Pro Max
                return .iPhone15Pro
            default: // iPhone 15 / Plus
                return .iPhone15
            }

        // iPhone 15.x = iPhone 14 系列 (2022)
        case 15:
            switch minor {
            case 2, 3: // iPhone 14 Pro / Pro Max
                return .iPhone14Pro
            case 4, 5: // iPhone 14 / Plus
                return .iPhone14
            default:
                return .iPhone14
            }

        // iPhone 14.x = iPhone 13 系列 (2021) + iPhone SE 3 + iPhone 14 标准版
        case 14:
            switch minor {
            case 2, 3: // iPhone 13 Pro / Pro Max
                return .iPhone13Pro
            case 4, 5: // iPhone 13 mini / iPhone 13
                return .iPhone13
            case 6: // iPhone SE (3rd gen)
                return .iPhoneSE
            case 7, 8: // iPhone 14 / Plus (特殊：使用 iPhone14,x 标识)
                return .iPhone14
            default:
                return .iPhone13
            }

        // iPhone 13.x = iPhone 12 系列 (2020)
        case 13:
            switch minor {
            case 3, 4: // iPhone 12 Pro / Pro Max
                return .iPhone12
            default: // iPhone 12 mini / iPhone 12
                return .iPhone12
            }

        // iPhone 12.x = iPhone 11 系列 (2019) + iPhone SE 2
        case 12:
            switch minor {
            case 8: // iPhone SE (2nd gen)
                return .iPhoneSE
            default: // iPhone 11 / Pro / Pro Max
                return .iPhone11
            }

        // iPhone 11.x = iPhone XS/XR 系列 (2018)
        case 11:
            return .iPhoneX

        // iPhone 10.x = iPhone X/8 系列 (2017)
        case 10:
            switch minor {
            case 3, 6: // iPhone X
                return .iPhoneX
            default: // iPhone 8 / 8 Plus
                return .iPhoneLegacy
            }

        // 更早的设备
        default:
            if major >= 9 {
                return .iPhoneLegacy
            }
            return .iPhoneGeneric
        }
    }

    /// 根据设备名称识别设备型号（fallback 方式）
    /// - Parameters:
    ///   - deviceName: 设备名称
    ///   - platform: 设备平台
    /// - Returns: 对应的 DeviceModel
    static func identify(from deviceName: String?, platform: DevicePlatform) -> DeviceModel {
        guard let name = deviceName?.lowercased() else {
            return platform == .ios ? .iPhoneGeneric : .androidGeneric
        }

        if platform == .ios {
            return identifyiPhone(from: name)
        } else {
            return identifyAndroid(from: name)
        }
    }

    private static func identifyiPhone(from name: String) -> DeviceModel {
        // iPhone 17 系列
        if name.contains("iphone 17") || name.contains("iphone17") {
            if name.contains("pro") {
                return .iPhone17Pro
            }
            return .iPhone17
        }

        // iPhone 16 系列
        if name.contains("iphone 16") || name.contains("iphone16") {
            if name.contains("pro") {
                return .iPhone16Pro
            }
            return .iPhone16
        }

        // iPhone 15 系列
        if name.contains("iphone 15") || name.contains("iphone15") {
            if name.contains("pro") {
                return .iPhone15Pro
            }
            return .iPhone15
        }

        // iPhone 14 系列
        if name.contains("iphone 14") || name.contains("iphone14") {
            if name.contains("pro") {
                return .iPhone14Pro
            }
            return .iPhone14
        }

        // iPhone 13 系列
        if name.contains("iphone 13") || name.contains("iphone13") {
            if name.contains("pro") {
                return .iPhone13Pro
            }
            return .iPhone13
        }

        // iPhone 12 系列
        if name.contains("iphone 12") || name.contains("iphone12") {
            return .iPhone12
        }

        // iPhone 11 系列
        if name.contains("iphone 11") || name.contains("iphone11") {
            return .iPhone11
        }

        // iPhone X 系列
        if name.contains("iphone x") || name.contains("iphone xs") || name.contains("iphone xr") {
            return .iPhoneX
        }

        // iPhone SE
        if name.contains("iphone se") {
            return .iPhoneSE
        }

        // iPhone 8 及更早
        if
            name.contains("iphone 8") || name.contains("iphone 7") || name.contains("iphone 6") ||
            name.contains("iphone8") || name.contains("iphone7") || name.contains("iphone6") {
            return .iPhoneLegacy
        }

        return .iPhoneGeneric
    }

    private static func identifyAndroid(from name: String) -> DeviceModel {
        if name.contains("samsung") || name.contains("galaxy") || name.contains("sm-") {
            if name.contains("fold") || name.contains("z fold") {
                return .samsungGalaxyFold
            }
            return .samsungGalaxyS
        }

        if name.contains("pixel") || name.contains("google") {
            return .googlePixel
        }

        if name.contains("xiaomi") || name.contains("redmi") || name.contains("poco") || name.contains("mi ") {
            return .xiaomi
        }

        if name.contains("oneplus") || name.contains("one plus") {
            return .oneplus
        }

        if name.contains("oppo") || name.contains("vivo") || name.contains("realme") || name.contains("iqoo") {
            return .oppoVivo
        }

        return .androidGeneric
    }
}
