//
//  FramePipeline.swift
//  DemoConsole
//
//  Created by Sun on 2025/12/22.
//
//  帧处理管线
//  处理从窗口捕获到渲染输出的完整流程
//

import Foundation
import CoreMedia
import CoreImage
import Combine
import QuartzCore

// MARK: - 帧数据

struct CapturedFrame: Identifiable {
    let id: UUID
    let sourceID: UUID
    let timestamp: CMTime
    let size: CGSize
    
    /// 视频帧的像素缓冲区（内部使用）
    private let _pixelBuffer: CVPixelBuffer?
    
    /// 可选的原始采样缓冲区（内部使用）
    private let _sampleBuffer: CMSampleBuffer?
    
    /// 获取像素缓冲区（公开只读）
    var pixelBuffer: CVPixelBuffer? { _pixelBuffer }
    
    /// 获取采样缓冲区（公开只读）
    var sampleBuffer: CMSampleBuffer? { _sampleBuffer }
    
    /// 从 CMSampleBuffer 初始化
    init(sourceID: UUID, sampleBuffer: CMSampleBuffer) {
        self.id = UUID()
        self.sourceID = sourceID
        self._sampleBuffer = sampleBuffer
        self._pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        self.timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            self.size = CGSize(width: Int(dimensions.width), height: Int(dimensions.height))
        } else {
            self.size = .zero
        }
    }
    
    /// 从 CVPixelBuffer 初始化
    init(pixelBuffer: CVPixelBuffer, presentationTime: CMTime, size: CGSize) {
        self.id = UUID()
        self.sourceID = UUID()  // 默认 sourceID
        self._pixelBuffer = pixelBuffer
        self._sampleBuffer = nil
        self.timestamp = presentationTime
        self.size = size
    }
    
    /// 转换为 CIImage
    func toCIImage() -> CIImage? {
        if let pixelBuffer = _pixelBuffer {
            return CIImage(cvImageBuffer: pixelBuffer)
        }
        if let imageBuffer = _sampleBuffer.flatMap({ CMSampleBufferGetImageBuffer($0) }) {
            return CIImage(cvImageBuffer: imageBuffer)
        }
        return nil
    }
    
    /// 转换为 CGImage
    func toCGImage() -> CGImage? {
        guard let ciImage = toCIImage() else { return nil }
        
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

// MARK: - 管线配置

struct PipelineConfiguration {
    /// 输出帧率
    var outputFrameRate: Int = 30
    
    /// 输出分辨率
    var outputSize: CGSize = CGSize(width: 1920, height: 1080)
    
    /// 是否启用帧插值
    var enableFrameInterpolation: Bool = false
    
    /// 缓冲区大小
    var bufferSize: Int = 3
}

// MARK: - 帧处理管线

@MainActor
final class FramePipeline: ObservableObject {
    
    // MARK: - 发布属性
    
    /// 最新输出帧
    @Published private(set) var outputFrame: CIImage?
    
    /// 当前帧率
    @Published private(set) var currentFPS: Double = 0
    
    /// 处理延迟（毫秒）
    @Published private(set) var processingLatency: Double = 0
    
    // MARK: - 配置
    
    var configuration = PipelineConfiguration()
    
    // MARK: - 私有属性
    
    /// 帧缓冲区
    private var frameBuffers: [UUID: [CapturedFrame]] = [:]
    
    /// 帧时间戳（用于计算 FPS）
    private var frameTimestamps: [CFTimeInterval] = []
    
    /// CIContext 用于图像处理
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: false
    ])
    
    /// 处理队列
    private let processingQueue = DispatchQueue(label: "com.democonsole.framepipeline", qos: .userInteractive)
    
    // MARK: - 公开方法
    
    /// 接收新帧
    func receiveFrame(_ frame: CapturedFrame) {
        // 添加到缓冲区
        if frameBuffers[frame.sourceID] == nil {
            frameBuffers[frame.sourceID] = []
        }
        
        frameBuffers[frame.sourceID]?.append(frame)
        
        // 保持缓冲区大小
        while (frameBuffers[frame.sourceID]?.count ?? 0) > configuration.bufferSize {
            frameBuffers[frame.sourceID]?.removeFirst()
        }
        
        // 记录时间戳用于 FPS 计算
        let now = CACurrentMediaTime()
        frameTimestamps.append(now)
        
        // 只保留最近 1 秒的时间戳
        frameTimestamps = frameTimestamps.filter { now - $0 < 1.0 }
        currentFPS = Double(frameTimestamps.count)
    }
    
    /// 获取指定源的最新帧
    func latestFrame(for sourceID: UUID) -> CapturedFrame? {
        return frameBuffers[sourceID]?.last
    }
    
    /// 获取所有源的最新帧
    func allLatestFrames() -> [UUID: CapturedFrame] {
        var result: [UUID: CapturedFrame] = [:]
        for (sourceID, frames) in frameBuffers {
            if let latest = frames.last {
                result[sourceID] = latest
            }
        }
        return result
    }
    
    /// 处理并合成帧
    func processFrames(_ frames: [CapturedFrame], layout: LayoutType) -> CIImage? {
        let startTime = CACurrentMediaTime()
        
        defer {
            let endTime = CACurrentMediaTime()
            processingLatency = (endTime - startTime) * 1000
        }
        
        guard !frames.isEmpty else { return nil }
        
        // 单个源直接返回
        if frames.count == 1, let image = frames.first?.toCIImage() {
            return scaleToOutput(image)
        }
        
        // 多个源需要合成
        return compositeFrames(frames, layout: layout)
    }
    
    /// 清除缓冲区
    func clearBuffers() {
        frameBuffers.removeAll()
        frameTimestamps.removeAll()
        currentFPS = 0
    }
    
    // MARK: - 私有方法
    
    /// 缩放到输出尺寸
    private func scaleToOutput(_ image: CIImage) -> CIImage {
        let scaleX = configuration.outputSize.width / image.extent.width
        let scaleY = configuration.outputSize.height / image.extent.height
        let scale = min(scaleX, scaleY)
        
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    /// 合成多个帧
    private func compositeFrames(_ frames: [CapturedFrame], layout: LayoutType) -> CIImage? {
        let outputSize = configuration.outputSize
        var compositeImage: CIImage = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: outputSize))
        
        let rects = layout.calculateRects(count: frames.count, in: outputSize)
        
        for (index, frame) in frames.enumerated() {
            guard index < rects.count, let image = frame.toCIImage() else { continue }
            
            let targetRect = rects[index]
            
            // 计算缩放
            let scaleX = targetRect.width / image.extent.width
            let scaleY = targetRect.height / image.extent.height
            let scale = min(scaleX, scaleY)
            
            // 缩放并平移
            let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            let translatedImage = scaledImage.transformed(by: CGAffineTransform(
                translationX: targetRect.origin.x,
                y: targetRect.origin.y
            ))
            
            // 合成
            compositeImage = translatedImage.composited(over: compositeImage)
        }
        
        return compositeImage
    }
}

// MARK: - 布局类型

enum LayoutType: String, CaseIterable, Identifiable {
    case single = "single"
    case sideBySide = "1x2"
    case grid2x2 = "2x2"
    case pip = "pip"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .single: return "单窗口"
        case .sideBySide: return "左右并排"
        case .grid2x2: return "2×2 网格"
        case .pip: return "画中画"
        }
    }
    
    var icon: String {
        switch self {
        case .single: return "rectangle"
        case .sideBySide: return "rectangle.split.2x1"
        case .grid2x2: return "rectangle.split.2x2"
        case .pip: return "pip"
        }
    }
    
    /// 计算布局矩形
    func calculateRects(count: Int, in size: CGSize) -> [CGRect] {
        let padding: CGFloat = 8
        
        switch self {
        case .single:
            return [CGRect(origin: .zero, size: size)]
            
        case .sideBySide:
            let width = (size.width - padding) / 2
            return [
                CGRect(x: 0, y: 0, width: width, height: size.height),
                CGRect(x: width + padding, y: 0, width: width, height: size.height)
            ]
            
        case .grid2x2:
            let width = (size.width - padding) / 2
            let height = (size.height - padding) / 2
            return [
                CGRect(x: 0, y: height + padding, width: width, height: height),
                CGRect(x: width + padding, y: height + padding, width: width, height: height),
                CGRect(x: 0, y: 0, width: width, height: height),
                CGRect(x: width + padding, y: 0, width: width, height: height)
            ]
            
        case .pip:
            let mainRect = CGRect(origin: .zero, size: size)
            let pipWidth = size.width * 0.3
            let pipHeight = size.height * 0.3
            let pipRect = CGRect(
                x: size.width - pipWidth - padding,
                y: padding,
                width: pipWidth,
                height: pipHeight
            )
            return [mainRect, pipRect]
        }
    }
}
