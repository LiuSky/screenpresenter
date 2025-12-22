# DemoConsole

macOS 设备演示投屏控制台 - 为产品经理和测试人员打造的 iOS/Android 投屏工具。

## 功能特性

### Android 投屏
- ✅ USB 一键投屏（使用 adb + scrcpy）
- ✅ 自动检测设备连接状态
- ✅ 自动处理 USB 调试授权
- ✅ 支持 Wi-Fi 投屏（向导模式）

### iPhone 投屏
- ✅ AirPlay 无线投屏引导
- ✅ QuickTime 有线投屏引导
- ✅ 一键启动 QuickTime 录制

### 系统功能
- ✅ 首次启动权限检查清单
- ✅ **adb 已内嵌**（无需手动安装）
- ✅ **scrcpy 一键安装**（通过 Homebrew）
- ✅ 友好的用户界面

---

## 快速开始

### 系统要求
- macOS 12.0 或更高版本
- Xcode 14.0+（用于编译）
- Homebrew（用于安装 scrcpy）

### 编译运行

```bash
# 1. 打开 Xcode 项目
open /Users/sun/Projects/Webull/Innovation/DemoConsole/DemoConsole.xcodeproj

# 2. 在 Xcode 中按 ⌘R 运行
```

### 首次启动

1. 应用会显示「设备演示检查清单」
2. 授予「屏幕录制」权限
3. 点击「安装」按钮一键安装 scrcpy
4. 全部就绪后点击「开始使用」

### 工具链说明

| 工具 | 来源 | 安装方式 |
|------|------|----------|
| **adb** | 内嵌 | 自动（无需操作） |
| **scrcpy** | Homebrew | 点击「安装」按钮 |

---

## 使用指南

### Android 设备投屏

#### USB 投屏（推荐）

1. **开启开发者选项**
   - 设置 → 关于手机 → 连续点击「版本号」7 次

2. **启用 USB 调试**
   - 设置 → 开发者选项 → USB 调试 → 开启

3. **连接设备**
   - 用 USB 数据线连接 Android 手机到 Mac
   - 如果弹出「允许 USB 调试」，点击「允许」

4. **开始投屏**
   - 在 DemoConsole 中看到设备后，点击「投屏」按钮

**预期效果：** 插线后 5 秒内出画面

#### Wi-Fi 投屏

1. 先用 USB 连接设备
2. 在 DemoConsole 中启用 Wi-Fi 连接
3. 断开 USB，保持 Wi-Fi 投屏

> ⚠️ 无线连接不稳定时，建议使用 USB 连接

---

### iPhone 设备投屏

#### 方式一：AirPlay 无线投屏（推荐）

**前提条件：**
- Mac 和 iPhone 连接到同一 Wi-Fi
- Mac 已开启 AirPlay Receiver

**操作步骤：**
1. 在 iPhone 上下拉控制中心
2. 点击「屏幕镜像」
3. 选择你的 Mac 名称

**预期效果：** 选择后立即出画面

#### 方式二：QuickTime 有线投屏

**操作步骤：**
1. 用 Lightning/USB-C 数据线连接 iPhone 到 Mac
2. 在 DemoConsole 中点击「启动 QuickTime」
3. 在 QuickTime 中，点击录制按钮旁边的下拉箭头
4. 选择你的 iPhone

**预期效果：** 选择后 20 秒内出画面

---

## 故障排查

### Android 问题

| 问题 | 解决方案 |
|------|----------|
| 设备显示「等待授权」| 在手机上点击「允许 USB 调试」|
| 设备不显示 | 检查 USB 调试是否开启；尝试换数据线 |
| scrcpy 闪退 | 检查 scrcpy 版本；重新插拔设备 |
| 画面卡顿 | 使用 USB 而非 Wi-Fi 连接 |

### iPhone 问题

| 问题 | 解决方案 |
|------|----------|
| AirPlay 找不到 Mac | 确保在同一 Wi-Fi；检查 Mac 的 AirPlay Receiver 是否开启 |
| QuickTime 看不到 iPhone | 解锁 iPhone；点击「信任这台电脑」|
| 画面黑屏 | 关闭 iPhone 低电量模式；检查有无 App 阻止录屏 |

### 工具链问题

| 问题 | 解决方案 |
|------|----------|
| scrcpy 未找到 | 点击侧边栏「安装」按钮，或手动运行 `brew install scrcpy` |
| Homebrew 未安装 | 访问 https://brew.sh 安装 Homebrew |
| 权限不足 | 重新启动 DemoConsole，授予屏幕录制权限 |

---

## 项目结构

```
DemoConsole/
├── DemoConsoleApp.swift          # App 入口和全局状态
├── Views/
│   ├── ContentView.swift         # 主界面
│   ├── AndroidDeviceListView.swift   # Android 设备列表
│   ├── IOSGuideView.swift        # iPhone 投屏引导
│   └── PermissionChecklistView.swift # 权限检查清单
├── Core/
│   ├── DeviceDiscovery/
│   │   ├── AndroidDevice.swift       # Android 设备模型
│   │   └── AndroidDeviceProvider.swift   # 设备发现
│   ├── Connection/
│   │   ├── AndroidConnector.swift    # Android 连接器
│   │   ├── IOSAirPlayGuide.swift     # AirPlay 引导
│   │   └── IOSQuickTimeGuide.swift   # QuickTime 引导
│   ├── Process/
│   │   ├── ProcessRunner.swift       # 进程执行器
│   │   └── ToolchainManager.swift    # 工具链管理
│   └── Permissions/
│       └── PermissionChecker.swift   # 权限检查
└── Resources/
    └── tools/                    # 内嵌工具（可选）
```

---

## 技术说明

### Android 投屏原理

使用 `scrcpy`（Screen Copy）工具，通过 ADB 协议将 Android 设备屏幕实时传输到 Mac。

- 不需要 root
- 不需要在手机上安装任何 App
- 延迟极低（通常 < 100ms）

### iPhone 投屏原理

- **AirPlay**：利用 macOS 内置的 AirPlay Receiver 功能
- **QuickTime**：使用 QuickTime Player 的影片录制功能捕获屏幕

两种方式都不需要在 iPhone 上安装 App。

---

## 许可证

内部工具，仅供公司内部使用。

---

## 常见问题

**Q: 为什么不用 iPhone Mirroring？**

A: iPhone Mirroring 需要 iPhone 和 Mac 使用同一 Apple ID，不适合演示他人设备。

**Q: 支持多设备同时投屏吗？**

A: 支持多个 Android 设备同时投屏（每个设备一个 scrcpy 窗口）。iPhone 投屏一次只能显示一个设备。

**Q: 支持录屏吗？**

A: Android 可以通过 scrcpy 的 `--record` 参数录制。iPhone 使用 QuickTime 时可以直接录制。
