//
//  ContentView.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  主内容视图（简化版）
//  单窗口布局：顶部工具栏、中间预览区、底部状态栏
//

import SwiftUI

// MARK: - 蓝色主题色

extension Color {
    /// 主题蓝色 - 与 AppIcon 一致
    static let themeBlue = Color(hex: "007AFF")
    static let themeBlueDark = Color(hex: "005FB8")

    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xf) * 17, (int & 0xf) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xff, int & 0xff)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xff, int >> 8 & 0xff, int & 0xff)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 布局模式

/// 分屏布局模式
enum SplitLayout: String, CaseIterable, Identifiable {
    case sideBySide // 左右平分
    case topBottom // 上下平分

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sideBySide: "左右平分"
        case .topBottom: "上下平分"
        }
    }

    var icon: String {
        switch self {
        case .sideBySide: "rectangle.split.2x1"
        case .topBottom: "rectangle.split.1x2"
        }
    }
}

// MARK: - 主内容视图

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    // 窗口设置
    @State private var backgroundColor: Color = .black
    @State private var splitLayout: SplitLayout = .sideBySide

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            topToolbar

            Divider()

            // 中间预览区域
            previewArea

            Divider()

            // 底部状态栏
            bottomStatusBar
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay {
            // 首次启动权限检查
            if appState.showPermissionChecklist {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                PermissionChecklistView()
                    .environmentObject(appState)
            }

            // 初始化加载
            if appState.isInitializing {
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在初始化...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
        }
    }

    // MARK: - 顶部工具栏

    private var topToolbar: some View {
        HStack(spacing: 16) {
            // 设备窗口设置
            HStack(spacing: 12) {
                // 背景色选择
                HStack(spacing: 8) {
                    Text("背景")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ColorPicker("", selection: $backgroundColor)
                        .labelsHidden()
                        .frame(width: 24, height: 24)
                }

                Divider().frame(height: 20)

                // 分屏布局选择
                HStack(spacing: 8) {
                    Text("布局")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $splitLayout) {
                        ForEach(SplitLayout.allCases) { layout in
                            Label(layout.displayName, systemImage: layout.icon)
                                .tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }

            Spacer()

            // 标题
            Text("DemoConsole")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            // 刷新按钮
            Button {
                appState.refreshDevices()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("刷新设备列表")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - 预览区域

    private var previewArea: some View {
        GeometryReader { _ in
            ZStack {
                // 背景色
                backgroundColor

                // 根据布局显示设备
                switch splitLayout {
                case .sideBySide:
                    HStack(spacing: 2) {
                        // 左侧：Android 设备
                        devicePreviewPanel(
                            title: "Android",
                            icon: "apps.iphone",
                            isConnected: appState.androidConnected,
                            deviceName: appState.androidDeviceName,
                            connectionGuide: "使用 USB 数据线连接 Android 设备"
                        )

                        // 右侧：iOS 设备
                        devicePreviewPanel(
                            title: "iPhone",
                            icon: "iphone",
                            isConnected: appState.iosConnected,
                            deviceName: appState.iosDeviceName,
                            connectionGuide: "使用 USB 数据线连接 iPhone 并信任此电脑"
                        )
                    }

                case .topBottom:
                    VStack(spacing: 2) {
                        // 上方：Android 设备
                        devicePreviewPanel(
                            title: "Android",
                            icon: "apps.iphone",
                            isConnected: appState.androidConnected,
                            deviceName: appState.androidDeviceName,
                            connectionGuide: "使用 USB 数据线连接 Android 设备"
                        )

                        // 下方：iOS 设备
                        devicePreviewPanel(
                            title: "iPhone",
                            icon: "iphone",
                            isConnected: appState.iosConnected,
                            deviceName: appState.iosDeviceName,
                            connectionGuide: "使用 USB 数据线连接 iPhone 并信任此电脑"
                        )
                    }
                }
            }
        }
    }

    // MARK: - 设备预览面板

    private func devicePreviewPanel(
        title: String,
        icon: String,
        isConnected: Bool,
        deviceName: String?,
        connectionGuide: String
    ) -> some View {
        VStack(spacing: 0) {
            // 设备标题栏
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
                Spacer()
                if isConnected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    if let name = deviceName {
                        Text(name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .foregroundStyle(.white)

            // 设备内容区
            ZStack {
                if isConnected {
                    // 已连接：显示设备画面占位符
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Text("设备画面")
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    // 未连接：显示连接指引
                    VStack(spacing: 16) {
                        Image(systemName: "cable.connector")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("未连接")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.6))

                        Text(connectionGuide)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.1))
    }

    // MARK: - 底部状态栏

    private var bottomStatusBar: some View {
        HStack(spacing: 16) {
            // 工具链状态
            HStack(spacing: 12) {
                // adb 状态
                HStack(spacing: 6) {
                    StatusDot(isReady: appState.toolchainManager.adbStatus.isReady)
                    Text("adb")
                        .font(.caption)
                    if appState.toolchainManager.adbStatus.isReady {
                        Text(appState.toolchainManager.adbVersionDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider().frame(height: 12)

                // scrcpy 状态
                HStack(spacing: 6) {
                    StatusDot(isReady: appState.toolchainManager.scrcpyStatus.isReady)
                    Text("scrcpy")
                        .font(.caption)
                    if appState.toolchainManager.scrcpyStatus.isReady {
                        Text(appState.toolchainManager.scrcpyVersionDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Button("安装") {
                            // TODO: 安装 scrcpy
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
            }

            Spacer()

            // 设备连接状态
            HStack(spacing: 8) {
                if appState.androidConnected {
                    Label("Android 已连接", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if appState.iosConnected {
                    Label("iPhone 已连接", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if !appState.androidConnected, !appState.iosConnected {
                    Text("等待设备连接...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - 状态指示点

struct StatusDot: View {
    let isReady: Bool

    var body: some View {
        Circle()
            .fill(isReady ? Color.green : Color.orange)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 900, height: 600)
}
