import Foundation
import Metal
import MetalKit
import CoreGraphics
import QuartzCore
import AxiomCore
import AxiomCapabilities

// MARK: - Metal Rendering Capability Configuration

/// Configuration for Metal Rendering capability
public struct MetalRenderingCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableMetalRendering: Bool
    public let enablePerformanceOptimization: Bool
    public let enableDebugMode: Bool
    public let enableGPUValidation: Bool
    public let enableShaderDebugging: Bool
    public let enableAsyncRendering: Bool
    public let maxConcurrentRenderPasses: Int
    public let renderTimeout: TimeInterval
    public let maxTextureSize: Int
    public let maxBufferSize: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let preferredGPU: PreferredGPU
    public let renderQuality: RenderQuality
    public let pixelFormat: PixelFormat
    public let colorSpace: ColorSpace
    
    public enum PreferredGPU: String, Codable, CaseIterable {
        case integrated = "integrated"
        case discrete = "discrete"
        case external = "external"
        case automatic = "automatic"
    }
    
    public enum RenderQuality: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case ultra = "ultra"
    }
    
    public enum PixelFormat: String, Codable, CaseIterable {
        case rgba8Unorm = "rgba8Unorm"
        case rgba16Float = "rgba16Float"
        case rgba32Float = "rgba32Float"
        case bgra8Unorm = "bgra8Unorm"
        case rgb10a2Unorm = "rgb10a2Unorm"
    }
    
    public enum ColorSpace: String, Codable, CaseIterable {
        case sRGB = "sRGB"
        case displayP3 = "displayP3"
        case rec2020 = "rec2020"
        case extendedSRGB = "extendedSRGB"
    }
    
    public init(
        enableMetalRendering: Bool = true,
        enablePerformanceOptimization: Bool = true,
        enableDebugMode: Bool = false,
        enableGPUValidation: Bool = false,
        enableShaderDebugging: Bool = false,
        enableAsyncRendering: Bool = true,
        maxConcurrentRenderPasses: Int = 4,
        renderTimeout: TimeInterval = 5.0,
        maxTextureSize: Int = 16384,
        maxBufferSize: Int = 256_000_000, // 256MB
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 100,
        preferredGPU: PreferredGPU = .automatic,
        renderQuality: RenderQuality = .high,
        pixelFormat: PixelFormat = .rgba8Unorm,
        colorSpace: ColorSpace = .sRGB
    ) {
        self.enableMetalRendering = enableMetalRendering
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.enableDebugMode = enableDebugMode
        self.enableGPUValidation = enableGPUValidation
        self.enableShaderDebugging = enableShaderDebugging
        self.enableAsyncRendering = enableAsyncRendering
        self.maxConcurrentRenderPasses = maxConcurrentRenderPasses
        self.renderTimeout = renderTimeout
        self.maxTextureSize = maxTextureSize
        self.maxBufferSize = maxBufferSize
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.preferredGPU = preferredGPU
        self.renderQuality = renderQuality
        self.pixelFormat = pixelFormat
        self.colorSpace = colorSpace
    }
    
    public var isValid: Bool {
        maxConcurrentRenderPasses > 0 &&
        renderTimeout > 0 &&
        maxTextureSize > 0 &&
        maxBufferSize > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: MetalRenderingCapabilityConfiguration) -> MetalRenderingCapabilityConfiguration {
        MetalRenderingCapabilityConfiguration(
            enableMetalRendering: other.enableMetalRendering,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            enableDebugMode: other.enableDebugMode,
            enableGPUValidation: other.enableGPUValidation,
            enableShaderDebugging: other.enableShaderDebugging,
            enableAsyncRendering: other.enableAsyncRendering,
            maxConcurrentRenderPasses: other.maxConcurrentRenderPasses,
            renderTimeout: other.renderTimeout,
            maxTextureSize: other.maxTextureSize,
            maxBufferSize: other.maxBufferSize,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            preferredGPU: other.preferredGPU,
            renderQuality: other.renderQuality,
            pixelFormat: other.pixelFormat,
            colorSpace: other.colorSpace
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> MetalRenderingCapabilityConfiguration {
        var adjustedTimeout = renderTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentPasses = maxConcurrentRenderPasses
        var adjustedCacheSize = cacheSize
        var adjustedRenderQuality = renderQuality
        var adjustedDebugMode = enableDebugMode
        var adjustedGPUValidation = enableGPUValidation
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(renderTimeout, 2.0)
            adjustedConcurrentPasses = min(maxConcurrentRenderPasses, 2)
            adjustedCacheSize = min(cacheSize, 25)
            adjustedRenderQuality = .low
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedDebugMode = true
            adjustedGPUValidation = true
        }
        
        return MetalRenderingCapabilityConfiguration(
            enableMetalRendering: enableMetalRendering,
            enablePerformanceOptimization: enablePerformanceOptimization,
            enableDebugMode: adjustedDebugMode,
            enableGPUValidation: adjustedGPUValidation,
            enableShaderDebugging: enableShaderDebugging,
            enableAsyncRendering: enableAsyncRendering,
            maxConcurrentRenderPasses: adjustedConcurrentPasses,
            renderTimeout: adjustedTimeout,
            maxTextureSize: maxTextureSize,
            maxBufferSize: maxBufferSize,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            preferredGPU: preferredGPU,
            renderQuality: adjustedRenderQuality,
            pixelFormat: pixelFormat,
            colorSpace: colorSpace
        )
    }
}

// MARK: - Metal Rendering Types

/// Metal render request
public struct MetalRenderRequest: Sendable, Identifiable {
    public let id: UUID
    public let renderPass: RenderPassDescriptor
    public let options: RenderOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct RenderPassDescriptor: Sendable {
        public let name: String
        public let renderTargets: [RenderTarget]
        public let clearColor: SIMD4<Float>
        public let viewport: MTLViewport
        public let cullMode: CullMode
        public let windingOrder: WindingOrder
        public let depthStencilState: DepthStencilDescriptor?
        
        public struct RenderTarget: Sendable {
            public let texture: TextureDescriptor
            public let loadAction: LoadAction
            public let storeAction: StoreAction
            public let level: Int
            public let slice: Int
            
            public enum LoadAction: String, Sendable, CaseIterable {
                case dontCare = "dontCare"
                case load = "load"
                case clear = "clear"
            }
            
            public enum StoreAction: String, Sendable, CaseIterable {
                case dontCare = "dontCare"
                case store = "store"
                case multisampleResolve = "multisampleResolve"
            }
            
            public init(texture: TextureDescriptor, loadAction: LoadAction = .clear, storeAction: StoreAction = .store, level: Int = 0, slice: Int = 0) {
                self.texture = texture
                self.loadAction = loadAction
                self.storeAction = storeAction
                self.level = level
                self.slice = slice
            }
        }
        
        public struct DepthStencilDescriptor: Sendable {
            public let depthCompareFunction: CompareFunction
            public let isDepthWriteEnabled: Bool
            public let stencilDescriptor: StencilDescriptor?
            
            public enum CompareFunction: String, Sendable, CaseIterable {
                case never = "never"
                case less = "less"
                case equal = "equal"
                case lessEqual = "lessEqual"
                case greater = "greater"
                case notEqual = "notEqual"
                case greaterEqual = "greaterEqual"
                case always = "always"
            }
            
            public struct StencilDescriptor: Sendable {
                public let stencilCompareFunction: CompareFunction
                public let stencilFailureOperation: StencilOperation
                public let depthFailureOperation: StencilOperation
                public let depthStencilPassOperation: StencilOperation
                public let readMask: UInt32
                public let writeMask: UInt32
                
                public enum StencilOperation: String, Sendable, CaseIterable {
                    case keep = "keep"
                    case zero = "zero"
                    case replace = "replace"
                    case incrementClamp = "incrementClamp"
                    case decrementClamp = "decrementClamp"
                    case invert = "invert"
                    case incrementWrap = "incrementWrap"
                    case decrementWrap = "decrementWrap"
                }
                
                public init(stencilCompareFunction: CompareFunction = .always, stencilFailureOperation: StencilOperation = .keep, depthFailureOperation: StencilOperation = .keep, depthStencilPassOperation: StencilOperation = .keep, readMask: UInt32 = 0xFF, writeMask: UInt32 = 0xFF) {
                    self.stencilCompareFunction = stencilCompareFunction
                    self.stencilFailureOperation = stencilFailureOperation
                    self.depthFailureOperation = depthFailureOperation
                    self.depthStencilPassOperation = depthStencilPassOperation
                    self.readMask = readMask
                    self.writeMask = writeMask
                }
            }
            
            public init(depthCompareFunction: CompareFunction = .less, isDepthWriteEnabled: Bool = true, stencilDescriptor: StencilDescriptor? = nil) {
                self.depthCompareFunction = depthCompareFunction
                self.isDepthWriteEnabled = isDepthWriteEnabled
                self.stencilDescriptor = stencilDescriptor
            }
        }
        
        public enum CullMode: String, Sendable, CaseIterable {
            case none = "none"
            case front = "front"
            case back = "back"
        }
        
        public enum WindingOrder: String, Sendable, CaseIterable {
            case clockwise = "clockwise"
            case counterClockwise = "counterClockwise"
        }
        
        public init(name: String, renderTargets: [RenderTarget], clearColor: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 1.0), viewport: MTLViewport, cullMode: CullMode = .back, windingOrder: WindingOrder = .counterClockwise, depthStencilState: DepthStencilDescriptor? = nil) {
            self.name = name
            self.renderTargets = renderTargets
            self.clearColor = clearColor
            self.viewport = viewport
            self.cullMode = cullMode
            self.windingOrder = windingOrder
            self.depthStencilState = depthStencilState
        }
    }
    
    public struct TextureDescriptor: Sendable {
        public let width: Int
        public let height: Int
        public let depth: Int
        public let pixelFormat: MetalRenderingCapabilityConfiguration.PixelFormat
        public let textureType: TextureType
        public let usage: TextureUsage
        public let storageMode: StorageMode
        public let mipmapLevelCount: Int
        public let sampleCount: Int
        public let arrayLength: Int
        
        public enum TextureType: String, Sendable, CaseIterable {
            case type1D = "type1D"
            case type1DArray = "type1DArray"
            case type2D = "type2D"
            case type2DArray = "type2DArray"
            case type2DMultisample = "type2DMultisample"
            case typeCube = "typeCube"
            case typeCubeArray = "typeCubeArray"
            case type3D = "type3D"
        }
        
        public struct TextureUsage: OptionSet, Sendable {
            public let rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            public static let unknown = TextureUsage(rawValue: 0)
            public static let shaderRead = TextureUsage(rawValue: 1 << 0)
            public static let shaderWrite = TextureUsage(rawValue: 1 << 1)
            public static let renderTarget = TextureUsage(rawValue: 1 << 2)
            public static let pixelFormatView = TextureUsage(rawValue: 1 << 3)
        }
        
        public enum StorageMode: String, Sendable, CaseIterable {
            case shared = "shared"
            case managed = "managed"
            case `private` = "private"
            case memoryless = "memoryless"
        }
        
        public init(width: Int, height: Int, depth: Int = 1, pixelFormat: MetalRenderingCapabilityConfiguration.PixelFormat = .rgba8Unorm, textureType: TextureType = .type2D, usage: TextureUsage = [.shaderRead, .renderTarget], storageMode: StorageMode = .private, mipmapLevelCount: Int = 1, sampleCount: Int = 1, arrayLength: Int = 1) {
            self.width = width
            self.height = height
            self.depth = depth
            self.pixelFormat = pixelFormat
            self.textureType = textureType
            self.usage = usage
            self.storageMode = storageMode
            self.mipmapLevelCount = mipmapLevelCount
            self.sampleCount = sampleCount
            self.arrayLength = arrayLength
        }
    }
    
    public struct RenderOptions: Sendable {
        public let enableWireframe: Bool
        public let enableMSAA: Bool
        public let sampleCount: Int
        public let enableDepthTesting: Bool
        public let enableBlending: Bool
        public let blendOperation: BlendOperation
        public let enableInstancing: Bool
        public let instanceCount: Int
        public let enableTessellation: Bool
        public let tessellationFactorScale: Float
        public let enableComputeShaders: Bool
        public let threadsPerThreadgroup: MTLSize
        public let threadgroupsPerGrid: MTLSize
        
        public enum BlendOperation: String, Sendable, CaseIterable {
            case add = "add"
            case subtract = "subtract"
            case reverseSubtract = "reverseSubtract"
            case min = "min"
            case max = "max"
        }
        
        public init(enableWireframe: Bool = false, enableMSAA: Bool = true, sampleCount: Int = 4, enableDepthTesting: Bool = true, enableBlending: Bool = true, blendOperation: BlendOperation = .add, enableInstancing: Bool = false, instanceCount: Int = 1, enableTessellation: Bool = false, tessellationFactorScale: Float = 1.0, enableComputeShaders: Bool = false, threadsPerThreadgroup: MTLSize = MTLSize(width: 1, height: 1, depth: 1), threadgroupsPerGrid: MTLSize = MTLSize(width: 1, height: 1, depth: 1)) {
            self.enableWireframe = enableWireframe
            self.enableMSAA = enableMSAA
            self.sampleCount = sampleCount
            self.enableDepthTesting = enableDepthTesting
            self.enableBlending = enableBlending
            self.blendOperation = blendOperation
            self.enableInstancing = enableInstancing
            self.instanceCount = instanceCount
            self.enableTessellation = enableTessellation
            self.tessellationFactorScale = tessellationFactorScale
            self.enableComputeShaders = enableComputeShaders
            self.threadsPerThreadgroup = threadsPerThreadgroup
            self.threadgroupsPerGrid = threadgroupsPerGrid
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(renderPass: RenderPassDescriptor, options: RenderOptions = RenderOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.renderPass = renderPass
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Metal render result
public struct MetalRenderResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let renderPassResults: [RenderPassResult]
    public let performanceMetrics: PerformanceMetrics
    public let gpuMetrics: GPUMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: MetalRenderingError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct RenderPassResult: Sendable {
        public let passName: String
        public let drawCalls: Int
        public let verticesRendered: Int
        public let primitivesRendered: Int
        public let texturesUsed: [String]
        public let shadersUsed: [String]
        public let renderTime: TimeInterval
        public let gpuTime: TimeInterval
        
        public init(passName: String, drawCalls: Int, verticesRendered: Int, primitivesRendered: Int, texturesUsed: [String], shadersUsed: [String], renderTime: TimeInterval, gpuTime: TimeInterval) {
            self.passName = passName
            self.drawCalls = drawCalls
            self.verticesRendered = verticesRendered
            self.primitivesRendered = primitivesRendered
            self.texturesUsed = texturesUsed
            self.shadersUsed = shadersUsed
            self.renderTime = renderTime
            self.gpuTime = gpuTime
        }
    }
    
    public struct PerformanceMetrics: Sendable {
        public let frameRate: Double
        public let frameTime: TimeInterval
        public let gpuUtilization: Float
        public let memoryUsage: Int
        public let bandwidthUsage: Int
        public let thermalState: ThermalState
        public let powerConsumption: Float
        
        public enum ThermalState: String, Sendable, CaseIterable {
            case nominal = "nominal"
            case fair = "fair"
            case serious = "serious"
            case critical = "critical"
        }
        
        public init(frameRate: Double, frameTime: TimeInterval, gpuUtilization: Float, memoryUsage: Int, bandwidthUsage: Int, thermalState: ThermalState, powerConsumption: Float) {
            self.frameRate = frameRate
            self.frameTime = frameTime
            self.gpuUtilization = gpuUtilization
            self.memoryUsage = memoryUsage
            self.bandwidthUsage = bandwidthUsage
            self.thermalState = thermalState
            self.powerConsumption = powerConsumption
        }
    }
    
    public struct GPUMetrics: Sendable {
        public let deviceName: String
        public let driverVersion: String
        public let totalMemory: Int
        public let availableMemory: Int
        public let maxTextureSize: Int
        public let maxRenderTargets: Int
        public let supportsRayTracing: Bool
        public let supportsVariableRateShading: Bool
        public let supportsMeshShaders: Bool
        
        public init(deviceName: String, driverVersion: String, totalMemory: Int, availableMemory: Int, maxTextureSize: Int, maxRenderTargets: Int, supportsRayTracing: Bool, supportsVariableRateShading: Bool, supportsMeshShaders: Bool) {
            self.deviceName = deviceName
            self.driverVersion = driverVersion
            self.totalMemory = totalMemory
            self.availableMemory = availableMemory
            self.maxTextureSize = maxTextureSize
            self.maxRenderTargets = maxRenderTargets
            self.supportsRayTracing = supportsRayTracing
            self.supportsVariableRateShading = supportsVariableRateShading
            self.supportsMeshShaders = supportsMeshShaders
        }
    }
    
    public init(requestId: UUID, renderPassResults: [RenderPassResult], performanceMetrics: PerformanceMetrics, gpuMetrics: GPUMetrics, processingTime: TimeInterval, success: Bool, error: MetalRenderingError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.renderPassResults = renderPassResults
        self.performanceMetrics = performanceMetrics
        self.gpuMetrics = gpuMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var totalDrawCalls: Int {
        renderPassResults.reduce(0) { $0 + $1.drawCalls }
    }
    
    public var totalVerticesRendered: Int {
        renderPassResults.reduce(0) { $0 + $1.verticesRendered }
    }
    
    public var averageFrameRate: Double {
        performanceMetrics.frameRate
    }
    
    public var isPerformant: Bool {
        performanceMetrics.frameRate >= 30.0 && performanceMetrics.gpuUtilization < 0.9
    }
}

/// Metal rendering metrics
public struct MetalRenderingMetrics: Sendable {
    public let totalRenderRequests: Int
    public let successfulRenders: Int
    public let failedRenders: Int
    public let averageProcessingTime: TimeInterval
    public let rendersByQuality: [String: Int]
    public let rendersByDevice: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageFrameRate: Double
    public let averageGPUUtilization: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let peakFrameRate: Double
        public let minFrameRate: Double
        public let averageDrawCalls: Double
        public let peakMemoryUsage: Int
        public let averageMemoryUsage: Int
        public let thermalThrottlingEvents: Int
        
        public init(peakFrameRate: Double = 0, minFrameRate: Double = 0, averageDrawCalls: Double = 0, peakMemoryUsage: Int = 0, averageMemoryUsage: Int = 0, thermalThrottlingEvents: Int = 0) {
            self.peakFrameRate = peakFrameRate
            self.minFrameRate = minFrameRate
            self.averageDrawCalls = averageDrawCalls
            self.peakMemoryUsage = peakMemoryUsage
            self.averageMemoryUsage = averageMemoryUsage
            self.thermalThrottlingEvents = thermalThrottlingEvents
        }
    }
    
    public init(totalRenderRequests: Int = 0, successfulRenders: Int = 0, failedRenders: Int = 0, averageProcessingTime: TimeInterval = 0, rendersByQuality: [String: Int] = [:], rendersByDevice: [String: Int] = [:], errorsByType: [String: Int] = [:], cacheHitRate: Double = 0, averageFrameRate: Double = 0, averageGPUUtilization: Double = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalRenderRequests = totalRenderRequests
        self.successfulRenders = successfulRenders
        self.failedRenders = failedRenders
        self.averageProcessingTime = averageProcessingTime
        self.rendersByQuality = rendersByQuality
        self.rendersByDevice = rendersByDevice
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageFrameRate = averageFrameRate
        self.averageGPUUtilization = averageGPUUtilization
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRenderRequests) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalRenderRequests > 0 ? Double(successfulRenders) / Double(totalRenderRequests) : 0
    }
}

// MARK: - Metal Rendering Resource

/// Metal rendering resource management
@available(iOS 13.0, macOS 10.15, *)
public actor MetalRenderingCapabilityResource: AxiomCapabilityResource {
    private let configuration: MetalRenderingCapabilityConfiguration
    private var activeRenders: [UUID: MetalRenderRequest] = [:]
    private var renderQueue: [MetalRenderRequest] = []
    private var renderHistory: [MetalRenderResult] = []
    private var resultCache: [String: MetalRenderResult] = [:]
    private var metalDevice: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var renderPipelineStates: [String: MTLRenderPipelineState] = [:]
    private var computePipelineStates: [String: MTLComputePipelineState] = [:]
    private var depthStencilStates: [String: MTLDepthStencilState] = [:]
    private var textureCache: [String: MTLTexture] = [:]
    private var bufferPool: [MTLBuffer] = []
    private var metrics: MetalRenderingMetrics = MetalRenderingMetrics()
    private var resultStreamContinuation: AsyncStream<MetalRenderResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: MetalRenderingCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 1_000_000_000, // 1GB for Metal rendering
            cpu: 4.0, // High CPU usage for rendering
            bandwidth: 0,
            storage: 200_000_000 // 200MB for shader and texture caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let renderMemory = activeRenders.count * 100_000_000 // ~100MB per active render
            let cacheMemory = resultCache.count * 200_000 // ~200KB per cached result
            let textureMemory = textureCache.count * 20_000_000 // ~20MB per cached texture
            let bufferMemory = bufferPool.count * 10_000_000 // ~10MB per buffer
            let historyMemory = renderHistory.count * 50_000
            let metalMemory = metalDevice != nil ? 100_000_000 : 0
            
            return ResourceUsage(
                memory: renderMemory + cacheMemory + textureMemory + bufferMemory + historyMemory + metalMemory,
                cpu: activeRenders.isEmpty ? 0.5 : 3.5,
                bandwidth: 0,
                storage: resultCache.count * 100_000 + textureCache.count * 50_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Metal rendering is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableMetalRendering && MTLCreateSystemDefaultDevice() != nil
        }
        return false
    }
    
    public func release() async {
        activeRenders.removeAll()
        renderQueue.removeAll()
        renderHistory.removeAll()
        resultCache.removeAll()
        renderPipelineStates.removeAll()
        computePipelineStates.removeAll()
        depthStencilStates.removeAll()
        textureCache.removeAll()
        bufferPool.removeAll()
        
        commandQueue = nil
        metalDevice = nil
        
        resultStreamContinuation?.finish()
        
        metrics = MetalRenderingMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MetalRenderingError.deviceNotFound
        }
        
        metalDevice = device
        
        // Create command queue
        guard let queue = device.makeCommandQueue() else {
            throw MetalRenderingError.commandQueueCreationFailed
        }
        
        commandQueue = queue
        
        // Setup debug and validation if enabled
        if configuration.enableDebugMode {
            // Enable Metal debug features
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[MetalRendering] 🚀 Metal Rendering capability initialized")
            print("[MetalRendering] 📱 Device: \(device.name)")
        }
    }
    
    internal func updateConfiguration(_ configuration: MetalRenderingCapabilityConfiguration) async throws {
        // Update Metal rendering configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<MetalRenderResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Device Information
    
    public func getDeviceInfo() async -> MetalRenderResult.GPUMetrics? {
        guard let device = metalDevice else { return nil }
        
        return MetalRenderResult.GPUMetrics(
            deviceName: device.name,
            driverVersion: "Unknown",
            totalMemory: Int(device.recommendedMaxWorkingSetSize),
            availableMemory: Int(device.currentAllocatedSize),
            maxTextureSize: configuration.maxTextureSize,
            maxRenderTargets: 8, // Typical Metal limit
            supportsRayTracing: device.supportsRaytracing,
            supportsVariableRateShading: false, // Feature detection would go here
            supportsMeshShaders: false // Feature detection would go here
        )
    }
    
    public func getSupportedPixelFormats() async -> [String] {
        guard let device = metalDevice else { return [] }
        
        // Check which pixel formats are supported
        let formats: [MTLPixelFormat] = [
            .rgba8Unorm,
            .rgba16Float,
            .rgba32Float,
            .bgra8Unorm,
            .rgb10a2Unorm
        ]
        
        return formats.compactMap { format in
            device.supportsTextureSampleCount(1, pixelFormat: format) ? String(describing: format) : nil
        }
    }
    
    // MARK: - Metal Rendering
    
    public func render(_ request: MetalRenderRequest) async throws -> MetalRenderResult {
        guard configuration.enableMetalRendering else {
            throw MetalRenderingError.renderingDisabled
        }
        
        guard let device = metalDevice, let commandQueue = commandQueue else {
            throw MetalRenderingError.deviceNotAvailable
        }
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(for: request)
            if let cachedResult = resultCache[cacheKey] {
                await updateCacheHitMetrics()
                return cachedResult
            }
        }
        
        // Check if we're at capacity
        if activeRenders.count >= configuration.maxConcurrentRenderPasses {
            renderQueue.append(request)
            throw MetalRenderingError.renderQueued(request.id)
        }
        
        let startTime = Date()
        activeRenders[request.id] = request
        
        do {
            // Perform Metal rendering
            let result = try await performMetalRendering(
                request: request,
                device: device,
                commandQueue: commandQueue,
                startTime: startTime
            )
            
            activeRenders.removeValue(forKey: request.id)
            renderHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logRender(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processRenderQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MetalRenderResult(
                requestId: request.id,
                renderPassResults: [],
                performanceMetrics: MetalRenderResult.PerformanceMetrics(
                    frameRate: 0,
                    frameTime: processingTime,
                    gpuUtilization: 0,
                    memoryUsage: 0,
                    bandwidthUsage: 0,
                    thermalState: .nominal,
                    powerConsumption: 0
                ),
                gpuMetrics: await getDeviceInfo() ?? MetalRenderResult.GPUMetrics(
                    deviceName: "Unknown",
                    driverVersion: "Unknown",
                    totalMemory: 0,
                    availableMemory: 0,
                    maxTextureSize: 0,
                    maxRenderTargets: 0,
                    supportsRayTracing: false,
                    supportsVariableRateShading: false,
                    supportsMeshShaders: false
                ),
                processingTime: processingTime,
                success: false,
                error: error as? MetalRenderingError ?? MetalRenderingError.renderingError(error.localizedDescription)
            )
            
            activeRenders.removeValue(forKey: request.id)
            renderHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logRender(result)
            }
            
            throw error
        }
    }
    
    public func cancelRender(_ requestId: UUID) async {
        activeRenders.removeValue(forKey: requestId)
        renderQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[MetalRendering] 🚫 Cancelled render: \(requestId)")
        }
    }
    
    public func getActiveRenders() async -> [MetalRenderRequest] {
        return Array(activeRenders.values)
    }
    
    public func getRenderHistory(since: Date? = nil) async -> [MetalRenderResult] {
        if let since = since {
            return renderHistory.filter { $0.timestamp >= since }
        }
        return renderHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> MetalRenderingMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = MetalRenderingMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
        textureCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[MetalRendering] ⚡ Performance optimization enabled")
        }
    }
    
    private func performMetalRendering(
        request: MetalRenderRequest,
        device: MTLDevice,
        commandQueue: MTLCommandQueue,
        startTime: Date
    ) async throws -> MetalRenderResult {
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw MetalRenderingError.commandBufferCreationFailed
        }
        
        var renderPassResults: [MetalRenderResult.RenderPassResult] = []
        
        // Process render pass
        let renderPassResult = try await processRenderPass(
            renderPass: request.renderPass,
            options: request.options,
            device: device,
            commandBuffer: commandBuffer
        )
        
        renderPassResults.append(renderPassResult)
        
        // Commit and wait for completion
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Calculate performance metrics
        let performanceMetrics = calculatePerformanceMetrics(
            processingTime: processingTime,
            renderPassResults: renderPassResults
        )
        
        let gpuMetrics = await getDeviceInfo() ?? MetalRenderResult.GPUMetrics(
            deviceName: device.name,
            driverVersion: "Unknown",
            totalMemory: Int(device.recommendedMaxWorkingSetSize),
            availableMemory: Int(device.currentAllocatedSize),
            maxTextureSize: configuration.maxTextureSize,
            maxRenderTargets: 8,
            supportsRayTracing: device.supportsRaytracing,
            supportsVariableRateShading: false,
            supportsMeshShaders: false
        )
        
        return MetalRenderResult(
            requestId: request.id,
            renderPassResults: renderPassResults,
            performanceMetrics: performanceMetrics,
            gpuMetrics: gpuMetrics,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func processRenderPass(
        renderPass: MetalRenderRequest.RenderPassDescriptor,
        options: MetalRenderRequest.RenderOptions,
        device: MTLDevice,
        commandBuffer: MTLCommandBuffer
    ) async throws -> MetalRenderResult.RenderPassResult {
        
        // Create render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        // Configure render targets
        for (index, target) in renderPass.renderTargets.enumerated() {
            guard index < 8 else { break } // Metal limit
            
            let attachment = renderPassDescriptor.colorAttachments[index]
            
            // Create texture for render target
            let texture = try createTexture(from: target.texture, device: device)
            attachment?.texture = texture
            
            // Configure load and store actions
            switch target.loadAction {
            case .dontCare:
                attachment?.loadAction = .dontCare
            case .load:
                attachment?.loadAction = .load
            case .clear:
                attachment?.loadAction = .clear
                attachment?.clearColor = MTLClearColor(
                    red: Double(renderPass.clearColor.x),
                    green: Double(renderPass.clearColor.y),
                    blue: Double(renderPass.clearColor.z),
                    alpha: Double(renderPass.clearColor.w)
                )
            }
            
            switch target.storeAction {
            case .dontCare:
                attachment?.storeAction = .dontCare
            case .store:
                attachment?.storeAction = .store
            case .multisampleResolve:
                attachment?.storeAction = .multisampleResolve
            }
        }
        
        // Create render command encoder
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw MetalRenderingError.encoderCreationFailed
        }
        
        // Configure viewport
        encoder.setViewport(renderPass.viewport)
        
        // Configure culling and winding
        switch renderPass.cullMode {
        case .none:
            encoder.setCullMode(.none)
        case .front:
            encoder.setCullMode(.front)
        case .back:
            encoder.setCullMode(.back)
        }
        
        switch renderPass.windingOrder {
        case .clockwise:
            encoder.setFrontFacing(.clockwise)
        case .counterClockwise:
            encoder.setFrontFacing(.counterClockwise)
        }
        
        // Simulate rendering work
        let drawCalls = 1
        let verticesRendered = 3 // Triangle
        let primitivesRendered = 1
        
        encoder.endEncoding()
        
        return MetalRenderResult.RenderPassResult(
            passName: renderPass.name,
            drawCalls: drawCalls,
            verticesRendered: verticesRendered,
            primitivesRendered: primitivesRendered,
            texturesUsed: renderPass.renderTargets.map { _ in "texture" },
            shadersUsed: ["vertex_shader", "fragment_shader"],
            renderTime: 0.001, // 1ms simulation
            gpuTime: 0.0005 // 0.5ms simulation
        )
    }
    
    private func createTexture(from descriptor: MetalRenderRequest.TextureDescriptor, device: MTLDevice) throws -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = descriptor.width
        textureDescriptor.height = descriptor.height
        textureDescriptor.depth = descriptor.depth
        
        // Convert pixel format
        switch descriptor.pixelFormat {
        case .rgba8Unorm:
            textureDescriptor.pixelFormat = .rgba8Unorm
        case .rgba16Float:
            textureDescriptor.pixelFormat = .rgba16Float
        case .rgba32Float:
            textureDescriptor.pixelFormat = .rgba32Float
        case .bgra8Unorm:
            textureDescriptor.pixelFormat = .bgra8Unorm
        case .rgb10a2Unorm:
            textureDescriptor.pixelFormat = .rgb10a2Unorm
        }
        
        // Convert texture type
        switch descriptor.textureType {
        case .type1D:
            textureDescriptor.textureType = .type1D
        case .type1DArray:
            textureDescriptor.textureType = .type1DArray
        case .type2D:
            textureDescriptor.textureType = .type2D
        case .type2DArray:
            textureDescriptor.textureType = .type2DArray
        case .type2DMultisample:
            textureDescriptor.textureType = .type2DMultisample
        case .typeCube:
            textureDescriptor.textureType = .typeCube
        case .typeCubeArray:
            textureDescriptor.textureType = .typeCubeArray
        case .type3D:
            textureDescriptor.textureType = .type3D
        }
        
        // Convert usage
        var usage: MTLTextureUsage = []
        if descriptor.usage.contains(.shaderRead) {
            usage.insert(.shaderRead)
        }
        if descriptor.usage.contains(.shaderWrite) {
            usage.insert(.shaderWrite)
        }
        if descriptor.usage.contains(.renderTarget) {
            usage.insert(.renderTarget)
        }
        if descriptor.usage.contains(.pixelFormatView) {
            usage.insert(.pixelFormatView)
        }
        textureDescriptor.usage = usage
        
        // Convert storage mode
        switch descriptor.storageMode {
        case .shared:
            textureDescriptor.storageMode = .shared
        case .managed:
            textureDescriptor.storageMode = .managed
        case .private:
            textureDescriptor.storageMode = .private
        case .memoryless:
            textureDescriptor.storageMode = .memoryless
        }
        
        textureDescriptor.mipmapLevelCount = descriptor.mipmapLevelCount
        textureDescriptor.sampleCount = descriptor.sampleCount
        textureDescriptor.arrayLength = descriptor.arrayLength
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw MetalRenderingError.textureCreationFailed
        }
        
        return texture
    }
    
    private func calculatePerformanceMetrics(
        processingTime: TimeInterval,
        renderPassResults: [MetalRenderResult.RenderPassResult]
    ) -> MetalRenderResult.PerformanceMetrics {
        
        let frameRate = processingTime > 0 ? 1.0 / processingTime : 0
        let gpuUtilization: Float = 0.5 // Simulated
        let memoryUsage = 50_000_000 // 50MB simulated
        let bandwidthUsage = 100_000_000 // 100MB/s simulated
        
        return MetalRenderResult.PerformanceMetrics(
            frameRate: frameRate,
            frameTime: processingTime,
            gpuUtilization: gpuUtilization,
            memoryUsage: memoryUsage,
            bandwidthUsage: bandwidthUsage,
            thermalState: .nominal,
            powerConsumption: 5.0 // 5W simulated
        )
    }
    
    private func processRenderQueue() async {
        guard !isProcessingQueue && !renderQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        renderQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !renderQueue.isEmpty && activeRenders.count < configuration.maxConcurrentRenderPasses {
            let request = renderQueue.removeFirst()
            
            do {
                _ = try await render(request)
            } catch {
                if configuration.enableLogging {
                    print("[MetalRendering] ⚠️ Queued render failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: MetalRenderRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: MetalRenderRequest) -> String {
        let passHash = request.renderPass.name.hashValue
        let qualityHash = configuration.renderQuality.rawValue.hashValue
        let optionsHash = String(describing: request.options).hashValue
        
        return "\(passHash)_\(qualityHash)_\(optionsHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRenderRequests)) + 1
        let totalRequests = metrics.totalRenderRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = MetalRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: metrics.successfulRenders + 1,
            failedRenders: metrics.failedRenders,
            averageProcessingTime: metrics.averageProcessingTime,
            rendersByQuality: metrics.rendersByQuality,
            rendersByDevice: metrics.rendersByDevice,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageFrameRate: metrics.averageFrameRate,
            averageGPUUtilization: metrics.averageGPUUtilization,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func updateSuccessMetrics(_ result: MetalRenderResult) async {
        let totalRequests = metrics.totalRenderRequests + 1
        let successfulRenders = metrics.successfulRenders + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRenderRequests)) + result.processingTime) / Double(totalRequests)
        
        var rendersByQuality = metrics.rendersByQuality
        rendersByQuality[configuration.renderQuality.rawValue, default: 0] += 1
        
        var rendersByDevice = metrics.rendersByDevice
        rendersByDevice[result.gpuMetrics.deviceName, default: 0] += 1
        
        let newAverageFrameRate = ((metrics.averageFrameRate * Double(metrics.successfulRenders)) + result.performanceMetrics.frameRate) / Double(successfulRenders)
        
        let newAverageGPUUtilization = ((metrics.averageGPUUtilization * Double(metrics.successfulRenders)) + Double(result.performanceMetrics.gpuUtilization)) / Double(successfulRenders)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let peakFrameRate = max(performanceStats.peakFrameRate, result.performanceMetrics.frameRate)
        let minFrameRate = min(performanceStats.minFrameRate == 0 ? result.performanceMetrics.frameRate : performanceStats.minFrameRate, result.performanceMetrics.frameRate)
        let newAverageDrawCalls = ((performanceStats.averageDrawCalls * Double(metrics.successfulRenders)) + Double(result.totalDrawCalls)) / Double(successfulRenders)
        let peakMemoryUsage = max(performanceStats.peakMemoryUsage, result.performanceMetrics.memoryUsage)
        let newAverageMemoryUsage = Int(((Double(performanceStats.averageMemoryUsage) * Double(metrics.successfulRenders)) + Double(result.performanceMetrics.memoryUsage)) / Double(successfulRenders))
        
        performanceStats = MetalRenderingMetrics.PerformanceStats(
            peakFrameRate: peakFrameRate,
            minFrameRate: minFrameRate,
            averageDrawCalls: newAverageDrawCalls,
            peakMemoryUsage: peakMemoryUsage,
            averageMemoryUsage: newAverageMemoryUsage,
            thermalThrottlingEvents: performanceStats.thermalThrottlingEvents
        )
        
        metrics = MetalRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: successfulRenders,
            failedRenders: metrics.failedRenders,
            averageProcessingTime: newAverageProcessingTime,
            rendersByQuality: rendersByQuality,
            rendersByDevice: rendersByDevice,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageFrameRate: newAverageFrameRate,
            averageGPUUtilization: newAverageGPUUtilization,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: MetalRenderResult) async {
        let totalRequests = metrics.totalRenderRequests + 1
        let failedRenders = metrics.failedRenders + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = MetalRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: metrics.successfulRenders,
            failedRenders: failedRenders,
            averageProcessingTime: metrics.averageProcessingTime,
            rendersByQuality: metrics.rendersByQuality,
            rendersByDevice: metrics.rendersByDevice,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageFrameRate: metrics.averageFrameRate,
            averageGPUUtilization: metrics.averageGPUUtilization,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logRender(_ result: MetalRenderResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let frameRate = String(format: "%.1f", result.performanceMetrics.frameRate)
        let drawCalls = result.totalDrawCalls
        let deviceName = result.gpuMetrics.deviceName
        
        print("[MetalRendering] \(statusIcon) Render: \(drawCalls) draw calls, \(frameRate) FPS, \(deviceName) (\(timeStr)s)")
        
        if let error = result.error {
            print("[MetalRendering] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Metal Rendering Capability Implementation

/// Metal Rendering capability providing high-performance graphics rendering
@available(iOS 13.0, macOS 10.15, *)
public actor MetalRenderingCapability: DomainCapability {
    public typealias ConfigurationType = MetalRenderingCapabilityConfiguration
    public typealias ResourceType = MetalRenderingCapabilityResource
    
    private var _configuration: MetalRenderingCapabilityConfiguration
    private var _resources: MetalRenderingCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "metal-rendering-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: MetalRenderingCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: MetalRenderingCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: MetalRenderingCapabilityConfiguration = MetalRenderingCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = MetalRenderingCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: MetalRenderingCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Metal Rendering configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Metal rendering is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return MTLCreateSystemDefaultDevice() != nil
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Metal rendering doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Metal Rendering Operations
    
    /// Render graphics using Metal
    public func render(_ request: MetalRenderRequest) async throws -> MetalRenderResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return try await _resources.render(request)
    }
    
    /// Cancel rendering
    public func cancelRender(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        await _resources.cancelRender(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<MetalRenderResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get device information
    public func getDeviceInfo() async throws -> MetalRenderResult.GPUMetrics? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.getDeviceInfo()
    }
    
    /// Get supported pixel formats
    public func getSupportedPixelFormats() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.getSupportedPixelFormats()
    }
    
    /// Get active renders
    public func getActiveRenders() async throws -> [MetalRenderRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.getActiveRenders()
    }
    
    /// Get render history
    public func getRenderHistory(since: Date? = nil) async throws -> [MetalRenderResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.getRenderHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> MetalRenderingMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Metal Rendering capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple render request
    public func createSimpleRenderRequest(width: Int, height: Int, clearColor: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)) -> MetalRenderRequest {
        let textureDescriptor = MetalRenderRequest.TextureDescriptor(width: width, height: height)
        let renderTarget = MetalRenderRequest.RenderPassDescriptor.RenderTarget(texture: textureDescriptor)
        let viewport = MTLViewport(originX: 0, originY: 0, width: Double(width), height: Double(height), znear: 0.0, zfar: 1.0)
        
        let renderPass = MetalRenderRequest.RenderPassDescriptor(
            name: "SimpleRender",
            renderTargets: [renderTarget],
            clearColor: clearColor,
            viewport: viewport
        )
        
        return MetalRenderRequest(renderPass: renderPass)
    }
    
    /// Check if rendering is active
    public func hasActiveRenders() async throws -> Bool {
        let activeRenders = try await getActiveRenders()
        return !activeRenders.isEmpty
    }
    
    /// Get current frame rate
    public func getCurrentFrameRate() async throws -> Double {
        let metrics = try await getMetrics()
        return metrics.averageFrameRate
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Metal Rendering specific errors
public enum MetalRenderingError: Error, LocalizedError {
    case renderingDisabled
    case deviceNotFound
    case deviceNotAvailable
    case commandQueueCreationFailed
    case commandBufferCreationFailed
    case encoderCreationFailed
    case textureCreationFailed
    case renderingError(String)
    case renderQueued(UUID)
    case renderTimeout(UUID)
    case invalidRenderPass
    case invalidTexture
    case shaderCompilationFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .renderingDisabled:
            return "Metal rendering is disabled"
        case .deviceNotFound:
            return "Metal device not found"
        case .deviceNotAvailable:
            return "Metal device not available"
        case .commandQueueCreationFailed:
            return "Failed to create command queue"
        case .commandBufferCreationFailed:
            return "Failed to create command buffer"
        case .encoderCreationFailed:
            return "Failed to create render encoder"
        case .textureCreationFailed:
            return "Failed to create texture"
        case .renderingError(let reason):
            return "Metal rendering failed: \(reason)"
        case .renderQueued(let id):
            return "Render queued: \(id)"
        case .renderTimeout(let id):
            return "Render timeout: \(id)"
        case .invalidRenderPass:
            return "Invalid render pass configuration"
        case .invalidTexture:
            return "Invalid texture configuration"
        case .shaderCompilationFailed(let reason):
            return "Shader compilation failed: \(reason)"
        case .configurationError(let reason):
            return "Metal rendering configuration error: \(reason)"
        }
    }
}