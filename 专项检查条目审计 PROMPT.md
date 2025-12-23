# MobileDevice.framework 专项检查条目审计清单（用于自审/Review）

## A. 接入边界与“主线不绑架”审计

-  MobileDevice 相关代码是否完全隔离在 `DeviceInsightLayer`（或同等独立模块）？
-  iOS 投屏主线（CMIO + AVFoundation）是否可以在 **MobileDevice 完全不可用** 时仍然启动？
-  是否存在任何逻辑：MobileDevice 失败 → 阻止 AVCaptureSession start？（有则不合格）
-  是否写明“MobileDevice 仅增强，不可作为前置条件”的代码注释与架构说明？

## B. 能力范围审计（是否越界）

-  MobileDevice 是否仅用于：设备信息、信任/配对状态解释、占用/不可用原因提示？
-  是否误用 MobileDevice 作为视频采集链路的一部分？（有则不合格）
-  是否存在把“是否可投屏”的最终判定交给 MobileDevice？（有则高风险）

## C. 降级策略审计（必须可用）

-  MobileDevice 初始化失败时是否进入 `InsightUnavailable`，并继续走 CMIO+AVF？
-  MobileDevice 调用失败是否**不会**导致 UI 卡死、状态机卡住？
-  降级后 UI 是否仍给出合理提示（如“设备信息不可用，但投屏仍可用”）？

## D. 稳定性与资源审计

-  插拔 iOS 设备时 MobileDevice 回调是否可靠触发？触发后是否只更新状态，不做重活？
-  是否有明显的泄漏风险：设备拔出后相关对象/observer 能否释放？
-  是否有“频繁轮询”导致 CPU 异常（例如每 100ms query 一次设备属性）？（有则不合格）
-  是否对多线程回调做了线程安全处理（回调队列明确、状态机串行）？

## E. 产品体验审计（MobileDevice 的价值是否真正兑现）

-  UI 是否优先展示 MobileDevice 提供的用户设备名（而不是泛化的“iPhone”）？
-  是否能区分并提示：
  - 未信任此电脑（Trust）
  - 被占用（例如 QuickTime/Xcode）
  - 服务不可用/设备锁屏导致的不可用
-  错误提示是否是“人话”，并包含下一步操作指引？

## F. 日志与可诊断性审计

-  是否记录 MobileDevice 初始化与关键调用的成功/失败原因（含错误码/失败阶段）？
-  是否记录：设备标识（尽量不泄露敏感信息时可 hash）+ iOS 版本/型号（若可取）
-  导出的诊断包中是否包含 MobileDevice 层的事件序列（插拔/信任/状态变化）？