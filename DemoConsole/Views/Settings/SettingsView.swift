//
//  SettingsView.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  设置视图（简化版）
//  提供用户偏好设置的配置界面
//

import SwiftUI

// MARK: - 设置视图

struct SettingsView: View {

    // MARK: - Properties

    @ObservedObject var preferences: UserPreferences = .shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TabView {
                generalSettingsTab
                    .tabItem {
                        Label("通用", systemImage: "gear")
                    }

                captureSettingsTab
                    .tabItem {
                        Label("捕获", systemImage: "video")
                    }

                scrcpySettingsTab
                    .tabItem {
                        Label("Scrcpy", systemImage: "antenna.radiowaves.left.and.right")
                    }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - General Settings Tab

    private var generalSettingsTab: some View {
        Form {
            Section("外观") {
                Picker("主题模式", selection: $preferences.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            Section("布局") {
                Picker("默认布局", selection: $preferences.defaultLayout) {
                    ForEach(LayoutStyle.allCases) { style in
                        HStack {
                            Image(systemName: style.icon)
                            Text(style.displayName)
                        }
                        .tag(style)
                    }
                }
            }

            Section("连接") {
                Toggle("自动重连", isOn: $preferences.autoReconnect)

                if preferences.autoReconnect {
                    Stepper("重连延迟: \(Int(preferences.reconnectDelay))秒",
                            value: $preferences.reconnectDelay,
                            in: 1 ... 30,
                            step: 1)

                    Stepper("最大重连次数: \(preferences.maxReconnectAttempts)次",
                            value: $preferences.maxReconnectAttempts,
                            in: 1 ... 20)
                }
            }
        }
        .padding()
    }

    // MARK: - Capture Settings Tab

    private var captureSettingsTab: some View {
        Form {
            Section("帧率") {
                Picker("捕获帧率", selection: $preferences.captureFrameRate) {
                    Text("30 FPS").tag(30)
                    Text("60 FPS").tag(60)
                    Text("120 FPS").tag(120)
                }
                .pickerStyle(.segmented)

                Text("更高的帧率会增加 CPU 和 GPU 负载")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Scrcpy Settings Tab

    private var scrcpySettingsTab: some View {
        Form {
            Section("视频") {
                Picker("比特率", selection: $preferences.scrcpyBitrate) {
                    Text("4 Mbps (流畅)").tag(4)
                    Text("8 Mbps (标准)").tag(8)
                    Text("16 Mbps (高清)").tag(16)
                    Text("32 Mbps (超清)").tag(32)
                }

                Picker("最大尺寸", selection: $preferences.scrcpyMaxSize) {
                    Text("不限制").tag(0)
                    Text("1280 像素").tag(1280)
                    Text("1920 像素").tag(1920)
                    Text("2560 像素").tag(2560)
                }

                Text("限制尺寸可以降低 CPU 负载")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("显示") {
                Toggle("显示触摸点", isOn: $preferences.scrcpyShowTouches)
            }

            Section("高级") {
                Text("更多 scrcpy 配置请参考官方文档")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("scrcpy GitHub",
                     destination: URL(string: "https://github.com/Genymobile/scrcpy")!)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
