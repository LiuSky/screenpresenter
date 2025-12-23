//
//  SingleDeviceRenderView.swift
//  ScreenPresenter
//
//  Created by Sun on 2025/12/23.
//
//  单设备 Metal 渲染视图
//  嵌入到 DeviceBezelView 的 screenContentView 中，画面跟随设备边框动画
//

import AppKit
import CoreVideo
import Metal
import QuartzCore

// MARK: - 单设备渲染视图

final class SingleDeviceRenderView: NSView {
    // MARK: - Metal 组件

    private var metalLayer: CAMetalLayer!
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var textureCache: CVMetalTextureCache?
    private var samplerState: MTLSamplerState?

    // MARK: - 纹理

    private var currentTexture: MTLTexture?
    private let textureLock = NSLock()

    // MARK: - 渲染状态

    private var displayLink: CVDisplayLink?
    private(set) var isRendering = false
    private let renderQueue = DispatchQueue(label: "com.screenPresenter.singleRender", qos: .userInteractive)

    // MARK: - 配置

    /// 屏幕圆角半径
    var cornerRadius: CGFloat = 0 {
        didSet {
            metalLayer?.cornerRadius = cornerRadius
        }
    }

    // MARK: - 统计

    private var frameTimestamps: [CFAbsoluteTime] = []
    private(set) var fps: Double = 0

    // MARK: - 初始化

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMetal()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
    }

    deinit {
        stopRendering()
    }

    // MARK: - 视图生命周期

    override func makeBackingLayer() -> CALayer {
        let layer = CAMetalLayer()
        layer.device = MTLCreateSystemDefaultDevice()
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = true
        layer.isOpaque = false
        layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        return layer
    }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        metalLayer?.contentsScale = window?.backingScaleFactor ?? 2.0
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            metalLayer?.contentsScale = window?.backingScaleFactor ?? 2.0
            updateDrawableSize()
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateDrawableSize()
    }

    override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        updateDrawableSize()
    }

    // MARK: - 设置

    private func setupMetal() {
        // 强制使用 layer-backed 视图
        wantsLayer = true

        // 创建并设置 CAMetalLayer
        let metal = CAMetalLayer()
        layer = metal
        metalLayer = metal

        guard let device = MTLCreateSystemDefaultDevice() else {
            AppLogger.rendering.error("无法创建 Metal 设备")
            return
        }
        self.device = device

        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = false
        metalLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        metalLayer.masksToBounds = true

        // 创建命令队列
        guard let commandQueue = device.makeCommandQueue() else {
            AppLogger.rendering.error("无法创建命令队列")
            return
        }
        self.commandQueue = commandQueue

        // 创建纹理缓存
        var cache: CVMetalTextureCache?
        let status = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device,
            nil,
            &cache
        )
        guard status == kCVReturnSuccess else {
            AppLogger.rendering.error("无法创建纹理缓存: \(status)")
            return
        }
        textureCache = cache

        // 创建渲染管线
        guard let pipelineState = createPipelineState(device: device) else {
            AppLogger.rendering.error("无法创建渲染管线")
            return
        }
        self.pipelineState = pipelineState

        // 创建采样器
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor) else {
            AppLogger.rendering.error("无法创建采样器")
            return
        }
        samplerState = sampler

        AppLogger.rendering.info("SingleDeviceRenderView Metal 初始化成功")
    }

    private func updateDrawableSize() {
        guard let metalLayer else { return }

        let scale = window?.backingScaleFactor ?? 2.0
        let size = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )

        if size.width > 0, size.height > 0 {
            metalLayer.drawableSize = size
        }
    }

    // MARK: - 渲染控制

    func startRendering() {
        guard !isRendering else { return }
        isRendering = true
        setupDisplayLink()
    }

    func stopRendering() {
        guard isRendering else { return }
        isRendering = false
        stopDisplayLink()
    }

    // MARK: - Display Link

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else {
            AppLogger.rendering.error("无法创建 CVDisplayLink")
            return
        }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo else { return kCVReturnSuccess }
            let view = Unmanaged<SingleDeviceRenderView>.fromOpaque(userInfo).takeUnretainedValue()
            view.displayLinkCallback()
            return kCVReturnSuccess
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)

        if let screen = window?.screen {
            let displayID = screen
                .deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
            CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)
        }

        CVDisplayLinkStart(displayLink)
        self.displayLink = displayLink
    }

    private func stopDisplayLink() {
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
    }

    private func displayLinkCallback() {
        guard isRendering else { return }

        // 渲染当前纹理
        renderQueue.async { [weak self] in
            self?.renderFrame()
        }
    }

    // MARK: - 纹理更新

    /// 用于追踪上次刷新纹理缓存的时间
    private var lastCacheFlushTime: CFAbsoluteTime = 0

    func updateTexture(from pixelBuffer: CVPixelBuffer) {
        guard let cache = textureCache else { return }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var cvTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )

        guard status == kCVReturnSuccess, let texture = cvTexture else { return }

        textureLock.lock()
        currentTexture = CVMetalTextureGetTexture(texture)
        textureLock.unlock()

        // 定期刷新纹理缓存，防止内存泄漏（每秒刷新一次）
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastCacheFlushTime > 1.0 {
            CVMetalTextureCacheFlush(cache, 0)
            lastCacheFlushTime = now
        }

        // 更新 FPS 统计
        frameTimestamps.append(now)
        frameTimestamps = frameTimestamps.filter { now - $0 < 1.0 }
        fps = Double(frameTimestamps.count)
    }

    func clearTexture() {
        textureLock.lock()
        currentTexture = nil
        textureLock.unlock()
        fps = 0
        frameTimestamps.removeAll()

        // 清除画面
        renderQueue.async { [weak self] in
            self?.renderFrame()
        }
    }

    // MARK: - 渲染

    private func renderFrame() {
        guard let metalLayer, let commandQueue, let pipelineState, let samplerState else { return }

        let drawableSize = metalLayer.drawableSize
        guard drawableSize.width > 0, drawableSize.height > 0 else { return }

        guard let drawable = metalLayer.nextDrawable() else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        textureLock.lock()
        let texture = currentTexture
        textureLock.unlock()

        if let texture {
            encoder.setRenderPipelineState(pipelineState)
            encoder.setFragmentSamplerState(samplerState, index: 0)

            // 计算保持纵横比的顶点
            let textureAspect = CGFloat(texture.width) / CGFloat(texture.height)
            let viewAspect = drawableSize.width / drawableSize.height

            var scaleX: Float = 1.0
            var scaleY: Float = 1.0

            if textureAspect > viewAspect {
                scaleY = Float(viewAspect / textureAspect)
            } else {
                scaleX = Float(textureAspect / viewAspect)
            }

            let vertices: [Float] = [
                -scaleX, -scaleY, 0.0, 1.0,
                scaleX, -scaleY, 1.0, 1.0,
                -scaleX, scaleY, 0.0, 0.0,
                scaleX, scaleY, 1.0, 0.0,
            ]

            encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - 着色器

    private func createPipelineState(device: MTLDevice) -> MTLRenderPipelineState? {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                                       constant float4 *vertices [[buffer(0)]]) {
            VertexOut out;
            float4 v = vertices[vertexID];
            out.position = float4(v.xy, 0.0, 1.0);
            out.texCoord = v.zw;
            return out;
        }

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                        texture2d<float> texture [[texture(0)]],
                                        sampler textureSampler [[sampler(0)]]) {
            return texture.sample(textureSampler, in.texCoord);
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let vertexFunction = library.makeFunction(name: "vertexShader")
            let fragmentFunction = library.makeFunction(name: "fragmentShader")

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            AppLogger.rendering.error("编译着色器失败: \(error.localizedDescription)")
            return nil
        }
    }
}
