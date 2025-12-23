//
//  MainViewController.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/22.
//
//  主视图控制器
//  包含工具栏和预览区域
//

import AppKit
import Combine
import SnapKit

// MARK: - 主视图控制器

final class MainViewController: NSViewController {
    // MARK: - UI 组件

    private var toolbarView: ToolbarView!
    private var previewContainerView: NSView!

    // MARK: - 设备面板

    /// iOS 面板（默认在左侧）
    private var iosPanelView: DevicePanelView!
    /// Android 面板（默认在右侧）
    private var androidPanelView: DevicePanelView!
    private var dividerView: NSBox!

    // MARK: - 状态

    private var cancellables = Set<AnyCancellable>()
    private var isSwapped: Bool = false

    // MARK: - 生命周期

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 从偏好设置读取默认设备位置
        isSwapped = !UserPreferences.shared.iosOnLeft

        setupUI()
        setupBindings()
        startRendering()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopRendering()
    }

    // MARK: - UI 设置

    private func setupUI() {
        setupToolbar()
        setupPreviewContainer()
        setupDevicePanels()
        updatePanelLayout()
    }

    private func setupToolbar() {
        toolbarView = ToolbarView()
        toolbarView.delegate = self
        toolbarView.setSwapState(isSwapped)
        view.addSubview(toolbarView)
        toolbarView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
    }

    private func setupPreviewContainer() {
        previewContainerView = NSView()
        previewContainerView.wantsLayer = true
        previewContainerView.layer?.backgroundColor = UserPreferences.shared.backgroundColor.cgColor
        view.addSubview(previewContainerView)
        previewContainerView.snp.makeConstraints { make in
            make.top.equalTo(toolbarView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupDevicePanels() {
        androidPanelView = DevicePanelView()
        previewContainerView.addSubview(androidPanelView)

        iosPanelView = DevicePanelView()
        previewContainerView.addSubview(iosPanelView)

        dividerView = NSBox()
        dividerView.boxType = .custom
        dividerView.fillColor = NSColor.separatorColor
        dividerView.borderWidth = 0
        dividerView.contentViewMargins = .zero
        previewContainerView.addSubview(dividerView)
    }

    private func updatePanelLayout() {
        // 更新面板内容
        updateAndroidPanel(androidPanelView)
        updateIOSPanel(iosPanelView)

        // 重置约束
        androidPanelView.snp.removeConstraints()
        iosPanelView.snp.removeConstraints()
        dividerView.snp.removeConstraints()

        // 根据 isSwapped 决定哪个面板在左侧
        // 默认 (isSwapped=false): iOS 在左侧，Android 在右侧
        // 交换后 (isSwapped=true): Android 在左侧，iOS 在右侧
        let leftPanel = isSwapped ? androidPanelView! : iosPanelView!
        let rightPanel = isSwapped ? iosPanelView! : androidPanelView!

        let dividerWidth: CGFloat = 1

        // 左右并排布局
        leftPanel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5).offset(-dividerWidth / 2)
        }

        dividerView.snp.makeConstraints { make in
            make.leading.equalTo(leftPanel.snp.trailing)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(dividerWidth)
        }

        rightPanel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(dividerView.snp.trailing)
            make.trailing.equalToSuperview()
        }

        // 动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            previewContainerView.layoutSubtreeIfNeeded()
        }
    }

    // MARK: - 绑定

    private func setupBindings() {
        AppState.shared.stateChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateUI()
            }
            .store(in: &cancellables)

        // 注意：纹理更新由数据源的帧回调驱动，而不是渲染请求
        // 这在 updateIOSPanel/updateAndroidPanel 中设置

        // 监听背景色变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundColorChange),
            name: .backgroundColorDidChange,
            object: nil
        )
    }

    @objc private func handleBackgroundColorChange() {
        previewContainerView.layer?.backgroundColor = UserPreferences.shared.backgroundColor.cgColor
    }

    // MARK: - 渲染

    private func startRendering() {
        iosPanelView.renderView.startRendering()
        androidPanelView.renderView.startRendering()
    }

    private func stopRendering() {
        iosPanelView.renderView.stopRendering()
        androidPanelView.renderView.stopRendering()
    }

    // MARK: - UI 更新

    /// 记录上次的 aspectRatio，用于检测变化
    private var lastIOSAspectRatio: CGFloat = 0
    private var lastAndroidAspectRatio: CGFloat = 0

    private func updateUI() {
        // 先记录旧的 aspectRatio
        let oldIOSRatio = iosPanelView.deviceAspectRatio
        let oldAndroidRatio = androidPanelView.deviceAspectRatio

        // 更新面板内容
        updateAndroidPanel(androidPanelView)
        updateIOSPanel(iosPanelView)

        // 检查 aspectRatio 是否变化，如果变化则重新布局
        let newIOSRatio = iosPanelView.deviceAspectRatio
        let newAndroidRatio = androidPanelView.deviceAspectRatio

        if abs(newIOSRatio - oldIOSRatio) > 0.01 || abs(newAndroidRatio - oldAndroidRatio) > 0.01 {
            updatePanelLayout()
        }
    }

    private func updateAndroidPanel(_ panel: DevicePanelView) {
        let appState = AppState.shared
        let scrcpyReady = appState.toolchainManager.scrcpyStatus.isReady

        if !scrcpyReady {
            panel.showToolchainMissing(toolName: "scrcpy") { [weak self] in
                self?.installScrcpy()
            }
            panel.renderView.clearTexture()
        } else if appState.androidCapturing {
            panel.showCapturing(
                deviceName: appState.androidDeviceName ?? "Android",
                platform: .android,
                fps: panel.renderView.fps,
                resolution: appState.androidDeviceSource?.captureSize ?? .zero,
                onStop: { [weak self] in
                    self?.stopAndroidCapture()
                }
            )
        } else if appState.androidConnected {
            panel.showConnected(
                deviceName: appState.androidDeviceName ?? "Android",
                platform: .android,
                onStart: { [weak self] in
                    self?.startAndroidCapture()
                }
            )
            panel.renderView.clearTexture()
        } else {
            panel.showDisconnected(platform: .android, connectionGuide: L10n.overlayUI.connectAndroid)
            panel.renderView.clearTexture()
        }
    }

    private func updateIOSPanel(_ panel: DevicePanelView) {
        let appState = AppState.shared

        if appState.iosCapturing {
            // 设置帧回调，每个新帧到来时更新纹理
            appState.iosDeviceSource?.onFrame = { [weak panel] pixelBuffer in
                panel?.renderView.updateTexture(from: pixelBuffer)
            }

            panel.showCapturing(
                deviceName: appState.iosDeviceName ?? "iPhone",
                platform: .ios,
                fps: panel.renderView.fps,
                resolution: appState.iosDeviceSource?.captureSize ?? .zero,
                onStop: { [weak self] in
                    self?.stopIOSCapture()
                }
            )
        } else if appState.iosConnected {
            // 清除帧回调
            appState.iosDeviceSource?.onFrame = nil

            panel.showConnected(
                deviceName: appState.iosDeviceName ?? "iPhone",
                platform: .ios,
                userPrompt: appState.iosDeviceUserPrompt,
                onStart: { [weak self] in
                    self?.startIOSCapture()
                }
            )
            panel.renderView.clearTexture()
        } else {
            panel.showDisconnected(platform: .ios, connectionGuide: L10n.overlayUI.connectIOS)
            panel.renderView.clearTexture()
        }
    }

    // MARK: - 操作

    private func startIOSCapture() {
        Task {
            do {
                try await AppState.shared.startIOSCapture()
            } catch {
                showError(L10n.error.startCaptureFailed(L10n.platform.ios, error.localizedDescription))
            }
        }
    }

    private func stopIOSCapture() {
        Task {
            await AppState.shared.stopIOSCapture()
        }
    }

    private func startAndroidCapture() {
        Task {
            do {
                try await AppState.shared.startAndroidCapture()
            } catch {
                showError(L10n.error.startCaptureFailed(L10n.platform.android, error.localizedDescription))
            }
        }
    }

    private func stopAndroidCapture() {
        Task {
            await AppState.shared.stopAndroidCapture()
        }
    }

    private func installScrcpy() {
        Task {
            await AppState.shared.toolchainManager.installScrcpy()
            updateUI()
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.common.error
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.common.ok)
        alert.runModal()
    }

    // MARK: - 窗口事件

    func handleWindowResize() {
        iosPanelView.needsLayout = true
        androidPanelView.needsLayout = true
    }
}

// MARK: - 工具栏代理

extension MainViewController: ToolbarViewDelegate {
    func toolbarDidRequestRefresh() {
        Task {
            await AppState.shared.refreshDevices()
            toolbarView.setRefreshing(false)
        }
    }

    func toolbarDidToggleSwap(_ swapped: Bool) {
        isSwapped = swapped
        updatePanelLayout()
    }

    func toolbarDidRequestPreferences() {
        PreferencesWindowController.shared.showWindow(nil)
    }
}
