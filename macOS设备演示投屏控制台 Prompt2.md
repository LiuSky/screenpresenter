# Prompt ②

## M1 → M2 演进路线（增量升级，不允许重写）

> **重要指令**
>  M1 是一个 **稳定基线**。
>  **禁止** 重写设备发现、连接逻辑、投屏链路。
>  M2 只允许在 **渲染与演示层** 做增强。

------

## 一、M2 的本质目标

从：

> “可靠地把手机画面投到 Mac”

升级为：

> “专业的多设备演示舞台”

------

## 二、核心认知（必须体现在设计里）

> **M2 并不替换投屏来源，而是“吃进它们的窗口”**

------

## 三、新增渲染层（只能新增）

```
Rendering
 ├─ CaptureSessionManager
 ├─ WindowCaptureSource
 ├─ FramePipeline
 ├─ Compositor (Metal)
 ├─ AnnotationLayer
 ├─ RecordingController
```

------

## 四、演进阶段拆分

### Phase 2.1：窗口收编

- 使用 ScreenCaptureKit 捕获：
  - scrcpy 窗口
  - QuickTime 窗口
  - AirPlay 窗口
- 外部窗口允许隐藏/最小化

------

### Phase 2.2：布局系统

- 1×2、2×2 网格
- 画中画（PiP）
- 场景预设（Demo A / Demo B）

------

### Phase 2.3：演示工具

- 激光笔
- 自由标注
- 焦点高亮

------

### Phase 2.4：录制

- 录制合成后的画面
- 默认 30fps
- 支持单场景录制

------

## 五、性能约束（必须实现）

- 默认 30fps
- 同时最多 2 路 1080p
- 温度 / 压力过高时自动降级

------

## 六、严格禁止事项

- 不允许自研视频协议
- 不使用 ReplayKit / MediaProjection
- 不修改手机端行为

------

## 七、最终输出要求

- 明确哪些是新增模块
- M1 代码零破坏
- 清晰解释为什么 M2 不会影响投屏延迟来源