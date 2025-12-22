# Prompt ①

## M1：macOS「设备演示投屏控制台」完整项目级实现

> **角色指令**
>  你是 Claude Code Opus，扮演一名 **资深 macOS 平台工程师 / 工具链工程师**，精通 **Swift、SwiftUI、Process 管理、ScreenCaptureKit、系统权限、开发者工具**。
>  你的目标是 **直接实现一个可交付、可维护、可扩展的 macOS 内部工具**，不是示例工程、不是伪代码。

这是一个 **内部使用的产品演示工具**，**不考虑 App Store 上架限制**。

------

## 一、项目背景

实现一个 macOS 桌面应用，名称：

> **DemoConsole**

用途：

- 给 **产品经理 / 测试人员** 演示 iOS & Android App
- 在 Mac 上快速、稳定地投屏 **真实手机画面**
- 支持演示时的录屏与多设备展示

核心理念（必须贯彻）：

> **不要自研投屏协议，按平台使用最稳定、行业事实标准的方案**

------

## 二、硬性约束（不可违反）

### 1. iPhone 相关

- **禁止** 使用 iPhone Mirroring / Continuity
- **禁止** 依赖同一个 Apple ID
- **禁止** 在 iPhone 上安装任何 App

iPhone 仅允许两条路径：

1. **无线**：AirPlay 镜像到 Mac（用户在 iPhone 上点一次）
2. **有线兜底**：QuickTime 屏幕采集

------

### 2. Android 相关

- 不 root
- 不安装 App
- 必须使用 **adb + scrcpy**

------

## 三、验收标准（这是“能不能交付”的判断线）

- Android（USB）：
  - 插线 → **5 秒内出画面**
- iPhone（USB）：
  - 插线 → **20 秒内出画面**
- 非工程师可独立完成操作
- 任一失败场景都有**明确下一步提示**

------

## 四、整体架构（必须按层拆）

```
DemoConsole.app
 ├─ AppUI (SwiftUI)
 │   ├─ DeviceListView
 │   ├─ DeviceRowView
 │   ├─ ConnectionGuideView
 │   ├─ PermissionChecklistView
 │
 ├─ Core
 │   ├─ DeviceDiscovery
 │   │   ├─ AndroidDeviceProvider
 │   │   ├─ IOSUSBDeviceProvider
 │   │
 │   ├─ Connection
 │   │   ├─ AndroidConnector
 │   │   ├─ IOSAirPlayGuide
 │   │   ├─ IOSQuickTimeGuide
 │   │
 │   ├─ Process
 │   │   ├─ ProcessRunner
 │   │   ├─ ToolchainManager
 │   │
 │   ├─ Permissions
 │   │   ├─ ScreenRecordingPermission
 │   │   ├─ AccessibilityPermission
 │
 ├─ Resources
 │   ├─ tools/
 │   │   ├─ adb
 │   │   ├─ scrcpy
```

**强制规则：**

- UI 层 **不能** 直接调用 shell
- 所有外部进程必须通过 `ProcessRunner`
- 所有设备状态必须是可观察的（Combine 或 async stream）

------

## 五、Android 实现规范（M1 核心）

### 5.1 工具链管理

- 内嵌 `adb`、`scrcpy`

- 首次启动时解压到：

  ```
  ~/Library/Application Support/DemoConsole/tools/
  ```

- 校验可执行权限与版本

------

### 5.2 USB 一键投屏（必须做到“真一键”）

流程：

1. `adb start-server`

2. `adb devices -l`

3. 若状态为 `unauthorized`

   - UI 提示：**“请在手机上点击「允许 USB 调试」”**
   - 每 2 秒自动轮询

4. 状态为 `device`

   - 启动：

     ```
     scrcpy -s <serial> --no-audio --stay-awake
     ```

5. 监听进程生命周期：

   - 设备拔出
   - scrcpy 异常退出
   - adb 断连

------

### 5.3 Wi-Fi 投屏（仅向导，不做一键）

- 明确分步骤 UI

- 任何失败都必须提示：

  > “无线不稳定，插线更快更稳（推荐）”

------

## 六、iPhone 实现规范（以“引导”为核心）

### 6.1 无线：AirPlay

Mac 侧职责：

- 判断当前 Mac 是否支持 AirPlay Receiver
- 未开启时自动跳转到系统设置对应页面

UI 必须明确展示：

> iPhone：下拉控制中心 → 屏幕镜像 → 选择当前 Mac

------

### 6.2 有线兜底：QuickTime

Mac 侧职责：

- 自动打开 QuickTime
- 自动创建「新建影片录制」窗口

UI 提示最短路径：

1. 点击录制按钮旁边的下拉
2. 选择 iPhone
3. 若未出现：
   - 解锁 iPhone
   - 点击“信任这台电脑”

**可选增强**：

- 使用辅助功能做 UI 自动点选
- 自动失败即回退为人工提示（不能卡死）

------

## 七、权限与首次启动体验（非常重要）

首次启动必须展示「演示设备检查清单」：

- 屏幕录制权限
- 辅助功能权限（如使用）
- 工具链完整性
- AirPlay Receiver 支持性

禁止静默失败。

------

## 八、UI/UX 原则

- 面向产品经理，而不是工程师
- 不展示 adb、scrcpy 等术语
- 每个状态都告诉用户：**下一步怎么做**
- 假设用户在会议室、紧张、没有耐心

------

## 九、你需要交付的内容

- 完整 Xcode 工程
- 可运行 Swift 源码（非伪代码）
- README：说明常见演示流程与失败排查