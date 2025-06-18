import Foundation
import ARKit
import SceneKit
import RealityKit
import Metal
import MetalKit
import AxiomCore
import AxiomCapabilities

// MARK: - AR Rendering Capability Configuration

/// Configuration for AR Rendering capability
public struct ARRenderingCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableARRendering: Bool
    public let enableWorldTracking: Bool
    public let enablePlaneDetection: Bool
    public let enableImageTracking: Bool
    public let enableObjectDetection: Bool
    public let enableBodyTracking: Bool
    public let enableFaceTracking: Bool
    public let enableOcclusion: Bool
    public let enableLightEstimation: Bool
    public let enableCollaborativeSession: Bool
    public let enablePeopleOcclusion: Bool
    public let maxConcurrentSessions: Int
    public let sessionTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let trackingQuality: TrackingQuality
    public let renderingFramework: RenderingFramework
    public let worldAlignment: WorldAlignment
    public let planeDetection: PlaneDetection
    public let environmentTexturing: EnvironmentTexturing
    public let maxAnchors: Int
    public let frameSemantics: [FrameSemantics]
    
    public enum TrackingQuality: String, Codable, CaseIterable {
        case normal = "normal"
        case limited = "limited"
        case notAvailable = "notAvailable"
        case automatic = "automatic"
    }
    
    public enum RenderingFramework: String, Codable, CaseIterable {
        case sceneKit = "sceneKit"
        case realityKit = "realityKit"
        case metal = "metal"
        case custom = "custom"
    }
    
    public enum WorldAlignment: String, Codable, CaseIterable {
        case gravity = "gravity"
        case gravityAndHeading = "gravityAndHeading"
        case camera = "camera"
    }
    
    public enum PlaneDetection: String, Codable, CaseIterable {
        case none = "none"
        case horizontal = "horizontal"
        case vertical = "vertical"
        case both = "both"
    }
    
    public enum EnvironmentTexturing: String, Codable, CaseIterable {
        case none = "none"
        case manual = "manual"
        case automatic = "automatic"
    }
    
    public enum FrameSemantics: String, Codable, CaseIterable {
        case personSegmentation = "personSegmentation"
        case personSegmentationWithDepth = "personSegmentationWithDepth"
        case bodyDetection = "bodyDetection"
        case sceneDepth = "sceneDepth"
        case smoothedSceneDepth = "smoothedSceneDepth"
    }
    
    public init(
        enableARRendering: Bool = true,
        enableWorldTracking: Bool = true,
        enablePlaneDetection: Bool = true,
        enableImageTracking: Bool = true,
        enableObjectDetection: Bool = true,
        enableBodyTracking: Bool = false,
        enableFaceTracking: Bool = false,
        enableOcclusion: Bool = true,
        enableLightEstimation: Bool = true,
        enableCollaborativeSession: Bool = false,
        enablePeopleOcclusion: Bool = false,
        maxConcurrentSessions: Int = 1,
        sessionTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 50,
        trackingQuality: TrackingQuality = .automatic,
        renderingFramework: RenderingFramework = .realityKit,
        worldAlignment: WorldAlignment = .gravity,
        planeDetection: PlaneDetection = .both,
        environmentTexturing: EnvironmentTexturing = .automatic,
        maxAnchors: Int = 100,
        frameSemantics: [FrameSemantics] = [.personSegmentation, .sceneDepth]
    ) {
        self.enableARRendering = enableARRendering
        self.enableWorldTracking = enableWorldTracking
        self.enablePlaneDetection = enablePlaneDetection
        self.enableImageTracking = enableImageTracking
        self.enableObjectDetection = enableObjectDetection
        self.enableBodyTracking = enableBodyTracking
        self.enableFaceTracking = enableFaceTracking
        self.enableOcclusion = enableOcclusion
        self.enableLightEstimation = enableLightEstimation
        self.enableCollaborativeSession = enableCollaborativeSession
        self.enablePeopleOcclusion = enablePeopleOcclusion
        self.maxConcurrentSessions = maxConcurrentSessions
        self.sessionTimeout = sessionTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.trackingQuality = trackingQuality
        self.renderingFramework = renderingFramework
        self.worldAlignment = worldAlignment
        self.planeDetection = planeDetection
        self.environmentTexturing = environmentTexturing
        self.maxAnchors = maxAnchors
        self.frameSemantics = frameSemantics
    }
    
    public var isValid: Bool {
        maxConcurrentSessions > 0 &&
        sessionTimeout > 0 &&
        maxAnchors > 0 &&
        cacheSize >= 0 &&
        !frameSemantics.isEmpty
    }
    
    public func merged(with other: ARRenderingCapabilityConfiguration) -> ARRenderingCapabilityConfiguration {
        ARRenderingCapabilityConfiguration(
            enableARRendering: other.enableARRendering,
            enableWorldTracking: other.enableWorldTracking,
            enablePlaneDetection: other.enablePlaneDetection,
            enableImageTracking: other.enableImageTracking,
            enableObjectDetection: other.enableObjectDetection,
            enableBodyTracking: other.enableBodyTracking,
            enableFaceTracking: other.enableFaceTracking,
            enableOcclusion: other.enableOcclusion,
            enableLightEstimation: other.enableLightEstimation,
            enableCollaborativeSession: other.enableCollaborativeSession,
            enablePeopleOcclusion: other.enablePeopleOcclusion,
            maxConcurrentSessions: other.maxConcurrentSessions,
            sessionTimeout: other.sessionTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            trackingQuality: other.trackingQuality,
            renderingFramework: other.renderingFramework,
            worldAlignment: other.worldAlignment,
            planeDetection: other.planeDetection,
            environmentTexturing: other.environmentTexturing,
            maxAnchors: other.maxAnchors,
            frameSemantics: other.frameSemantics
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ARRenderingCapabilityConfiguration {
        var adjustedTimeout = sessionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentSessions = maxConcurrentSessions
        var adjustedCacheSize = cacheSize
        var adjustedFrameSemantics = frameSemantics
        var adjustedMaxAnchors = maxAnchors
        var adjustedRenderingFramework = renderingFramework
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(sessionTimeout, 15.0)
            adjustedConcurrentSessions = 1
            adjustedCacheSize = min(cacheSize, 20)
            adjustedFrameSemantics = [.personSegmentation]
            adjustedMaxAnchors = min(maxAnchors, 25)
            adjustedRenderingFramework = .sceneKit
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ARRenderingCapabilityConfiguration(
            enableARRendering: enableARRendering,
            enableWorldTracking: enableWorldTracking,
            enablePlaneDetection: enablePlaneDetection,
            enableImageTracking: enableImageTracking,
            enableObjectDetection: enableObjectDetection,
            enableBodyTracking: enableBodyTracking,
            enableFaceTracking: enableFaceTracking,
            enableOcclusion: enableOcclusion,
            enableLightEstimation: enableLightEstimation,
            enableCollaborativeSession: enableCollaborativeSession,
            enablePeopleOcclusion: enablePeopleOcclusion,
            maxConcurrentSessions: adjustedConcurrentSessions,
            sessionTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            trackingQuality: trackingQuality,
            renderingFramework: adjustedRenderingFramework,
            worldAlignment: worldAlignment,
            planeDetection: planeDetection,
            environmentTexturing: environmentTexturing,
            maxAnchors: adjustedMaxAnchors,
            frameSemantics: adjustedFrameSemantics
        )
    }
}

// MARK: - AR Rendering Types

/// AR rendering session request
public struct ARRenderingRequest: Sendable, Identifiable {
    public let id: UUID
    public let sessionConfig: SessionConfiguration
    public let renderingOptions: RenderingOptions
    public let trackingOptions: TrackingOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct SessionConfiguration: Sendable {
        public let configType: ConfigurationType
        public let worldAlignment: ARRenderingCapabilityConfiguration.WorldAlignment
        public let planeDetection: ARRenderingCapabilityConfiguration.PlaneDetection
        public let environmentTexturing: ARRenderingCapabilityConfiguration.EnvironmentTexturing
        public let frameSemantics: [ARRenderingCapabilityConfiguration.FrameSemantics]
        public let isLightEstimationEnabled: Bool
        public let providesAudioData: Bool
        public let isAutoFocusEnabled: Bool
        public let videoFormat: VideoFormat?
        
        public enum ConfigurationType: String, Sendable, CaseIterable {
            case worldTracking = "worldTracking"
            case orientationTracking = "orientationTracking"
            case faceTracking = "faceTracking"
            case imageTracking = "imageTracking"
            case objectDetection = "objectDetection"
            case bodyTracking = "bodyTracking"
            case collaborative = "collaborative"
        }
        
        public struct VideoFormat: Sendable {
            public let imageResolution: CGSize
            public let framesPerSecond: Int
            public let captureDevicePosition: CaptureDevicePosition
            
            public enum CaptureDevicePosition: String, Sendable, CaseIterable {
                case front = "front"
                case back = "back"
                case unspecified = "unspecified"
            }
            
            public init(imageResolution: CGSize, framesPerSecond: Int, captureDevicePosition: CaptureDevicePosition = .back) {
                self.imageResolution = imageResolution
                self.framesPerSecond = framesPerSecond
                self.captureDevicePosition = captureDevicePosition
            }
        }
        
        public init(configType: ConfigurationType, worldAlignment: ARRenderingCapabilityConfiguration.WorldAlignment = .gravity, planeDetection: ARRenderingCapabilityConfiguration.PlaneDetection = .both, environmentTexturing: ARRenderingCapabilityConfiguration.EnvironmentTexturing = .automatic, frameSemantics: [ARRenderingCapabilityConfiguration.FrameSemantics] = [], isLightEstimationEnabled: Bool = true, providesAudioData: Bool = false, isAutoFocusEnabled: Bool = true, videoFormat: VideoFormat? = nil) {
            self.configType = configType
            self.worldAlignment = worldAlignment
            self.planeDetection = planeDetection
            self.environmentTexturing = environmentTexturing
            self.frameSemantics = frameSemantics
            self.isLightEstimationEnabled = isLightEstimationEnabled
            self.providesAudioData = providesAudioData
            self.isAutoFocusEnabled = isAutoFocusEnabled
            self.videoFormat = videoFormat
        }
    }
    
    public struct RenderingOptions: Sendable {
        public let framework: ARRenderingCapabilityConfiguration.RenderingFramework
        public let enableStatistics: Bool
        public let enableDebugging: Bool
        public let enablePhysics: Bool
        public let enableAntialiasing: Bool
        public let enableHDR: Bool
        public let renderingAPI: RenderingAPI
        public let shadowQuality: ShadowQuality
        public let textureQuality: TextureQuality
        
        public enum RenderingAPI: String, Sendable, CaseIterable {
            case metal = "metal"
            case openGL = "openGL"
            case vulkan = "vulkan"
        }
        
        public enum ShadowQuality: String, Sendable, CaseIterable {
            case disabled = "disabled"
            case low = "low"
            case medium = "medium"
            case high = "high"
            case ultra = "ultra"
        }
        
        public enum TextureQuality: String, Sendable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case ultra = "ultra"
        }
        
        public init(framework: ARRenderingCapabilityConfiguration.RenderingFramework = .realityKit, enableStatistics: Bool = false, enableDebugging: Bool = false, enablePhysics: Bool = true, enableAntialiasing: Bool = true, enableHDR: Bool = false, renderingAPI: RenderingAPI = .metal, shadowQuality: ShadowQuality = .medium, textureQuality: TextureQuality = .high) {
            self.framework = framework
            self.enableStatistics = enableStatistics
            self.enableDebugging = enableDebugging
            self.enablePhysics = enablePhysics
            self.enableAntialiasing = enableAntialiasing
            self.enableHDR = enableHDR
            self.renderingAPI = renderingAPI
            self.shadowQuality = shadowQuality
            self.textureQuality = textureQuality
        }
    }
    
    public struct TrackingOptions: Sendable {
        public let resetTracking: Bool
        public let removeExistingAnchors: Bool
        public let relocalizationEnabled: Bool
        public let userFaceTrackingEnabled: Bool
        public let environmentProbeAnchorEnabled: Bool
        public let automaticImageScaleEstimationEnabled: Bool
        public let wantsHDREnvironmentTextures: Bool
        public let maximumNumberOfTrackedImages: Int
        
        public init(resetTracking: Bool = false, removeExistingAnchors: Bool = false, relocalizationEnabled: Bool = true, userFaceTrackingEnabled: Bool = false, environmentProbeAnchorEnabled: Bool = false, automaticImageScaleEstimationEnabled: Bool = false, wantsHDREnvironmentTextures: Bool = false, maximumNumberOfTrackedImages: Int = 1) {
            self.resetTracking = resetTracking
            self.removeExistingAnchors = removeExistingAnchors
            self.relocalizationEnabled = relocalizationEnabled
            self.userFaceTrackingEnabled = userFaceTrackingEnabled
            self.environmentProbeAnchorEnabled = environmentProbeAnchorEnabled
            self.automaticImageScaleEstimationEnabled = automaticImageScaleEstimationEnabled
            self.wantsHDREnvironmentTextures = wantsHDREnvironmentTextures
            self.maximumNumberOfTrackedImages = maximumNumberOfTrackedImages
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(sessionConfig: SessionConfiguration, renderingOptions: RenderingOptions = RenderingOptions(), trackingOptions: TrackingOptions = TrackingOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.sessionConfig = sessionConfig
        self.renderingOptions = renderingOptions
        self.trackingOptions = trackingOptions
        self.priority = priority
        self.metadata = metadata
    }
}

/// AR rendering session result
public struct ARRenderingResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let sessionState: SessionState
    public let trackingState: TrackingState
    public let detectedElements: [DetectedElement]
    public let anchors: [ARAnchorInfo]
    public let renderingMetrics: RenderingMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ARRenderingError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct SessionState: Sendable {
        public let isRunning: Bool
        public let isPaused: Bool
        public let trackingState: TrackingState
        public let currentFrame: FrameInfo?
        public let lightEstimate: LightEstimate?
        public let worldMappingStatus: WorldMappingStatus
        
        public enum WorldMappingStatus: String, Sendable, CaseIterable {
            case notAvailable = "notAvailable"
            case limited = "limited"
            case extending = "extending"
            case mapped = "mapped"
        }
        
        public struct FrameInfo: Sendable {
            public let timestamp: TimeInterval
            public let cameraTransform: Transform
            public let cameraIntrinsics: CameraIntrinsics
            public let imageResolution: CGSize
            public let displayTransform: Transform
            
            public struct Transform: Sendable {
                public let translation: SIMD3<Float>
                public let rotation: simd_quatf
                public let scale: SIMD3<Float>
                
                public init(translation: SIMD3<Float>, rotation: simd_quatf, scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
                    self.translation = translation
                    self.rotation = rotation
                    self.scale = scale
                }
            }
            
            public struct CameraIntrinsics: Sendable {
                public let focalLength: SIMD2<Float>
                public let principalPoint: SIMD2<Float>
                public let imageResolution: CGSize
                
                public init(focalLength: SIMD2<Float>, principalPoint: SIMD2<Float>, imageResolution: CGSize) {
                    self.focalLength = focalLength
                    self.principalPoint = principalPoint
                    self.imageResolution = imageResolution
                }
            }
            
            public init(timestamp: TimeInterval, cameraTransform: Transform, cameraIntrinsics: CameraIntrinsics, imageResolution: CGSize, displayTransform: Transform) {
                self.timestamp = timestamp
                self.cameraTransform = cameraTransform
                self.cameraIntrinsics = cameraIntrinsics
                self.imageResolution = imageResolution
                self.displayTransform = displayTransform
            }
        }
        
        public struct LightEstimate: Sendable {
            public let ambientIntensity: Double
            public let ambientColorTemperature: Double
            public let primaryLightDirection: SIMD3<Float>?
            public let primaryLightIntensity: Double?
            public let sphericalHarmonicsCoefficients: [Float]?
            
            public init(ambientIntensity: Double, ambientColorTemperature: Double, primaryLightDirection: SIMD3<Float>? = nil, primaryLightIntensity: Double? = nil, sphericalHarmonicsCoefficients: [Float]? = nil) {
                self.ambientIntensity = ambientIntensity
                self.ambientColorTemperature = ambientColorTemperature
                self.primaryLightDirection = primaryLightDirection
                self.primaryLightIntensity = primaryLightIntensity
                self.sphericalHarmonicsCoefficients = sphericalHarmonicsCoefficients
            }
        }
        
        public init(isRunning: Bool, isPaused: Bool, trackingState: TrackingState, currentFrame: FrameInfo? = nil, lightEstimate: LightEstimate? = nil, worldMappingStatus: WorldMappingStatus) {
            self.isRunning = isRunning
            self.isPaused = isPaused
            self.trackingState = trackingState
            self.currentFrame = currentFrame
            self.lightEstimate = lightEstimate
            self.worldMappingStatus = worldMappingStatus
        }
    }
    
    public enum TrackingState: String, Sendable, CaseIterable {
        case normal = "normal"
        case limited = "limited"
        case notAvailable = "notAvailable"
    }
    
    public struct DetectedElement: Sendable {
        public let elementId: String
        public let elementType: ElementType
        public let confidence: Float
        public let boundingBox: BoundingBox
        public let worldPosition: SIMD3<Float>
        public let classification: String?
        
        public enum ElementType: String, Sendable, CaseIterable {
            case plane = "plane"
            case image = "image"
            case object = "object"
            case face = "face"
            case body = "body"
            case text = "text"
            case unknown = "unknown"
        }
        
        public struct BoundingBox: Sendable {
            public let center: SIMD2<Float>
            public let size: SIMD2<Float>
            
            public init(center: SIMD2<Float>, size: SIMD2<Float>) {
                self.center = center
                self.size = size
            }
        }
        
        public init(elementId: String, elementType: ElementType, confidence: Float, boundingBox: BoundingBox, worldPosition: SIMD3<Float>, classification: String? = nil) {
            self.elementId = elementId
            self.elementType = elementType
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.worldPosition = worldPosition
            self.classification = classification
        }
    }
    
    public struct ARAnchorInfo: Sendable {
        public let anchorId: String
        public let anchorType: AnchorType
        public let transform: ARRenderingResult.SessionState.FrameInfo.Transform
        public let isTracked: Bool
        public let sessionIdentifier: UUID
        
        public enum AnchorType: String, Sendable, CaseIterable {
            case world = "world"
            case plane = "plane"
            case image = "image"
            case object = "object"
            case face = "face"
            case body = "body"
            case environment = "environment"
        }
        
        public init(anchorId: String, anchorType: AnchorType, transform: ARRenderingResult.SessionState.FrameInfo.Transform, isTracked: Bool, sessionIdentifier: UUID) {
            self.anchorId = anchorId
            self.anchorType = anchorType
            self.transform = transform
            self.isTracked = isTracked
            self.sessionIdentifier = sessionIdentifier
        }
    }
    
    public struct RenderingMetrics: Sendable {
        public let frameRate: Double
        public let frameTime: TimeInterval
        public let gpuUtilization: Float
        public let memoryUsage: Int
        public let thermalState: ThermalState
        public let powerConsumption: Float
        public let trackingQuality: TrackingQuality
        public let anchorsTracked: Int
        public let planesDetected: Int
        public let objectsDetected: Int
        
        public enum ThermalState: String, Sendable, CaseIterable {
            case nominal = "nominal"
            case fair = "fair"
            case serious = "serious"
            case critical = "critical"
        }
        
        public enum TrackingQuality: String, Sendable, CaseIterable {
            case poor = "poor"
            case acceptable = "acceptable"
            case good = "good"
            case excellent = "excellent"
        }
        
        public init(frameRate: Double, frameTime: TimeInterval, gpuUtilization: Float, memoryUsage: Int, thermalState: ThermalState, powerConsumption: Float, trackingQuality: TrackingQuality, anchorsTracked: Int, planesDetected: Int, objectsDetected: Int) {
            self.frameRate = frameRate
            self.frameTime = frameTime
            self.gpuUtilization = gpuUtilization
            self.memoryUsage = memoryUsage
            self.thermalState = thermalState
            self.powerConsumption = powerConsumption
            self.trackingQuality = trackingQuality
            self.anchorsTracked = anchorsTracked
            self.planesDetected = planesDetected
            self.objectsDetected = objectsDetected
        }
    }
    
    public init(requestId: UUID, sessionState: SessionState, trackingState: TrackingState, detectedElements: [DetectedElement], anchors: [ARAnchorInfo], renderingMetrics: RenderingMetrics, processingTime: TimeInterval, success: Bool, error: ARRenderingError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.sessionState = sessionState
        self.trackingState = trackingState
        self.detectedElements = detectedElements
        self.anchors = anchors
        self.renderingMetrics = renderingMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var trackingQuality: Double {
        switch trackingState {
        case .normal: return 1.0
        case .limited: return 0.6
        case .notAvailable: return 0.0
        }
    }
    
    public var detectionEffectiveness: Double {
        let totalDetections = detectedElements.count
        let highConfidenceDetections = detectedElements.filter { $0.confidence > 0.8 }.count
        return totalDetections > 0 ? Double(highConfidenceDetections) / Double(totalDetections) : 0.0
    }
}

/// AR rendering capability metrics
public struct ARRenderingCapabilityMetrics: Sendable {
    public let totalSessions: Int
    public let successfulSessions: Int
    public let failedSessions: Int
    public let averageProcessingTime: TimeInterval
    public let sessionsByType: [String: Int]
    public let averageFrameRate: Double
    public let averageTrackingQuality: Double
    public let errorsByType: [String: Int]
    public let throughputPerMinute: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestFrameRate: Double
        public let worstFrameRate: Double
        public let averageAnchorsPerSession: Double
        public let averageDetectionsPerSession: Double
        public let totalPlanesDetected: Int
        public let totalObjectsDetected: Int
        public let averageSessionDuration: TimeInterval
        
        public init(bestFrameRate: Double = 0, worstFrameRate: Double = 0, averageAnchorsPerSession: Double = 0, averageDetectionsPerSession: Double = 0, totalPlanesDetected: Int = 0, totalObjectsDetected: Int = 0, averageSessionDuration: TimeInterval = 0) {
            self.bestFrameRate = bestFrameRate
            self.worstFrameRate = worstFrameRate
            self.averageAnchorsPerSession = averageAnchorsPerSession
            self.averageDetectionsPerSession = averageDetectionsPerSession
            self.totalPlanesDetected = totalPlanesDetected
            self.totalObjectsDetected = totalObjectsDetected
            self.averageSessionDuration = averageSessionDuration
        }
    }
    
    public init(totalSessions: Int = 0, successfulSessions: Int = 0, failedSessions: Int = 0, averageProcessingTime: TimeInterval = 0, sessionsByType: [String: Int] = [:], averageFrameRate: Double = 0, averageTrackingQuality: Double = 0, errorsByType: [String: Int] = [:], throughputPerMinute: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalSessions = totalSessions
        self.successfulSessions = successfulSessions
        self.failedSessions = failedSessions
        self.averageProcessingTime = averageProcessingTime
        self.sessionsByType = sessionsByType
        self.averageFrameRate = averageFrameRate
        self.averageTrackingQuality = averageTrackingQuality
        self.errorsByType = errorsByType
        self.throughputPerMinute = averageProcessingTime > 0 ? 60.0 / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalSessions > 0 ? Double(successfulSessions) / Double(totalSessions) : 0
    }
}

// MARK: - AR Rendering Resource

/// AR rendering resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ARRenderingCapabilityResource: AxiomCapabilityResource {
    private let configuration: ARRenderingCapabilityConfiguration
    private var activeSessions: [UUID: ARRenderingRequest] = [:]
    private var sessionHistory: [ARRenderingResult] = []
    private var resultCache: [String: ARRenderingResult] = [:]
    private var arSessionManager: ARSessionManager = ARSessionManager()
    private var trackingEngine: TrackingEngine = TrackingEngine()
    private var detectionEngine: DetectionEngine = DetectionEngine()
    private var renderingEngine: RenderingEngine = RenderingEngine()
    private var metrics: ARRenderingCapabilityMetrics = ARRenderingCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<ARRenderingResult>.Continuation?
    
    // Helper classes for AR rendering processing
    private class ARSessionManager {
        private var currentSession: ARSession?
        private var sessionDelegate: ARSessionDelegate?
        
        func createSession(with request: ARRenderingRequest) -> ARSession {
            let session = ARSession()
            let configuration = createARConfiguration(from: request.sessionConfig)
            
            session.run(configuration, options: createRunOptions(from: request.trackingOptions))
            currentSession = session
            
            return session
        }
        
        private func createARConfiguration(from config: ARRenderingRequest.SessionConfiguration) -> ARConfiguration {
            switch config.configType {
            case .worldTracking:
                let worldConfig = ARWorldTrackingConfiguration()
                worldConfig.worldAlignment = convertWorldAlignment(config.worldAlignment)
                worldConfig.planeDetection = convertPlaneDetection(config.planeDetection)
                worldConfig.environmentTexturing = convertEnvironmentTexturing(config.environmentTexturing)
                worldConfig.isLightEstimationEnabled = config.isLightEstimationEnabled
                worldConfig.isAutoFocusEnabled = config.isAutoFocusEnabled
                worldConfig.providesAudioData = config.providesAudioData
                
                if #available(iOS 13.0, *) {
                    worldConfig.frameSemantics = convertFrameSemantics(config.frameSemantics)
                }
                
                return worldConfig
                
            case .orientationTracking:
                return AROrientationTrackingConfiguration()
                
            case .faceTracking:
                if ARFaceTrackingConfiguration.isSupported {
                    let faceConfig = ARFaceTrackingConfiguration()
                    faceConfig.worldAlignment = convertWorldAlignment(config.worldAlignment)
                    faceConfig.isLightEstimationEnabled = config.isLightEstimationEnabled
                    return faceConfig
                } else {
                    return AROrientationTrackingConfiguration()
                }
                
            case .imageTracking:
                let imageConfig = ARImageTrackingConfiguration()
                imageConfig.isAutoFocusEnabled = config.isAutoFocusEnabled
                return imageConfig
                
            case .objectDetection:
                if #available(iOS 12.0, *), ARObjectScanningConfiguration.isSupported {
                    return ARObjectScanningConfiguration()
                } else {
                    return ARWorldTrackingConfiguration()
                }
                
            case .bodyTracking:
                if #available(iOS 13.0, *), ARBodyTrackingConfiguration.isSupported {
                    let bodyConfig = ARBodyTrackingConfiguration()
                    bodyConfig.worldAlignment = convertWorldAlignment(config.worldAlignment)
                    bodyConfig.isAutoFocusEnabled = config.isAutoFocusEnabled
                    return bodyConfig
                } else {
                    return ARWorldTrackingConfiguration()
                }
                
            case .collaborative:
                let worldConfig = ARWorldTrackingConfiguration()
                worldConfig.isCollaborationEnabled = true
                return worldConfig
            }
        }
        
        private func createRunOptions(from tracking: ARRenderingRequest.TrackingOptions) -> ARSession.RunOptions {
            var options: ARSession.RunOptions = []
            
            if tracking.resetTracking {
                options.insert(.resetTracking)
            }
            
            if tracking.removeExistingAnchors {
                options.insert(.removeExistingAnchors)
            }
            
            return options
        }
        
        private func convertWorldAlignment(_ alignment: ARRenderingCapabilityConfiguration.WorldAlignment) -> ARConfiguration.WorldAlignment {
            switch alignment {
            case .gravity: return .gravity
            case .gravityAndHeading: return .gravityAndHeading
            case .camera: return .camera
            }
        }
        
        private func convertPlaneDetection(_ detection: ARRenderingCapabilityConfiguration.PlaneDetection) -> ARWorldTrackingConfiguration.PlaneDetection {
            switch detection {
            case .none: return []
            case .horizontal: return .horizontal
            case .vertical: return .vertical
            case .both: return [.horizontal, .vertical]
            }
        }
        
        private func convertEnvironmentTexturing(_ texturing: ARRenderingCapabilityConfiguration.EnvironmentTexturing) -> ARWorldTrackingConfiguration.EnvironmentTexturing {
            switch texturing {
            case .none: return .none
            case .manual: return .manual
            case .automatic: return .automatic
            }
        }
        
        @available(iOS 13.0, *)
        private func convertFrameSemantics(_ semantics: [ARRenderingCapabilityConfiguration.FrameSemantics]) -> ARConfiguration.FrameSemantics {
            var result: ARConfiguration.FrameSemantics = []
            
            for semantic in semantics {
                switch semantic {
                case .personSegmentation:
                    if #available(iOS 13.0, *) {
                        result.insert(.personSegmentation)
                    }
                case .personSegmentationWithDepth:
                    if #available(iOS 14.0, *) {
                        result.insert(.personSegmentationWithDepth)
                    }
                case .bodyDetection:
                    if #available(iOS 13.0, *) {
                        result.insert(.bodyDetection)
                    }
                case .sceneDepth:
                    if #available(iOS 14.0, *) {
                        result.insert(.sceneDepth)
                    }
                case .smoothedSceneDepth:
                    if #available(iOS 14.0, *) {
                        result.insert(.smoothedSceneDepth)
                    }
                }
            }
            
            return result
        }
        
        func pauseSession() {
            currentSession?.pause()
        }
        
        func stopSession() {
            currentSession?.pause()
            currentSession = nil
        }
        
        func getCurrentFrame() -> ARFrame? {
            return currentSession?.currentFrame
        }
    }
    
    private class TrackingEngine {
        func analyzeTrackingState(_ frame: ARFrame?) -> ARRenderingResult.TrackingState {
            guard let frame = frame else { return .notAvailable }
            
            switch frame.camera.trackingState {
            case .normal:
                return .normal
            case .limited:
                return .limited
            case .notAvailable:
                return .notAvailable
            }
        }
        
        func calculateTrackingQuality(_ trackingState: ARRenderingResult.TrackingState, anchors: [ARAnchor]) -> ARRenderingResult.RenderingMetrics.TrackingQuality {
            let anchorCount = anchors.count
            
            switch trackingState {
            case .normal:
                if anchorCount >= 5 { return .excellent }
                else if anchorCount >= 3 { return .good }
                else { return .acceptable }
            case .limited:
                return .acceptable
            case .notAvailable:
                return .poor
            }
        }
    }
    
    private class DetectionEngine {
        func detectElements(in frame: ARFrame) -> [ARRenderingResult.DetectedElement] {
            var detectedElements: [ARRenderingResult.DetectedElement] = []
            
            // Simulate plane detection
            let planeDetection = ARRenderingResult.DetectedElement(
                elementId: UUID().uuidString,
                elementType: .plane,
                confidence: 0.9,
                boundingBox: ARRenderingResult.DetectedElement.BoundingBox(
                    center: SIMD2<Float>(0.5, 0.5),
                    size: SIMD2<Float>(0.3, 0.3)
                ),
                worldPosition: SIMD3<Float>(0, -1, -2),
                classification: "floor"
            )
            detectedElements.append(planeDetection)
            
            return detectedElements
        }
        
        func processAnchors(_ anchors: [ARAnchor]) -> [ARRenderingResult.ARAnchorInfo] {
            return anchors.map { anchor in
                let anchorType: ARRenderingResult.ARAnchorInfo.AnchorType
                
                if anchor is ARPlaneAnchor {
                    anchorType = .plane
                } else if anchor is ARImageAnchor {
                    anchorType = .image
                } else if #available(iOS 12.0, *), anchor is ARObjectAnchor {
                    anchorType = .object
                } else if anchor is ARFaceAnchor {
                    anchorType = .face
                } else if #available(iOS 13.0, *), anchor is ARBodyAnchor {
                    anchorType = .body
                } else if #available(iOS 12.0, *), anchor is AREnvironmentProbeAnchor {
                    anchorType = .environment
                } else {
                    anchorType = .world
                }
                
                let transform = ARRenderingResult.SessionState.FrameInfo.Transform(
                    translation: SIMD3<Float>(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z),
                    rotation: simd_quatf(anchor.transform)
                )
                
                return ARRenderingResult.ARAnchorInfo(
                    anchorId: anchor.identifier.uuidString,
                    anchorType: anchorType,
                    transform: transform,
                    isTracked: true,
                    sessionIdentifier: UUID()
                )
            }
        }
    }
    
    private class RenderingEngine {
        func calculateRenderingMetrics(_ frame: ARFrame?) -> ARRenderingResult.RenderingMetrics {
            return ARRenderingResult.RenderingMetrics(
                frameRate: 60.0, // Simulated
                frameTime: 0.016, // 60 FPS
                gpuUtilization: 0.7, // Simulated
                memoryUsage: 150_000_000, // 150MB simulated
                thermalState: .nominal,
                powerConsumption: 8.0, // 8W simulated
                trackingQuality: .good,
                anchorsTracked: 3,
                planesDetected: 1,
                objectsDetected: 0
            )
        }
    }
    
    public init(configuration: ARRenderingCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 500_000_000, // 500MB for AR rendering
            cpu: 3.5, // High CPU usage for AR processing
            bandwidth: 0,
            storage: 100_000_000 // 100MB for AR session data caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let sessionMemory = activeSessions.count * 200_000_000 // ~200MB per active session
            let cacheMemory = resultCache.count * 500_000 // ~500KB per cached result
            let historyMemory = sessionHistory.count * 100_000
            let arMemory = 100_000_000 // AR engine overhead
            
            return ResourceUsage(
                memory: sessionMemory + cacheMemory + historyMemory + arMemory,
                cpu: activeSessions.isEmpty ? 0.2 : 3.0,
                bandwidth: 0,
                storage: resultCache.count * 250_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // AR rendering is available on iOS 13+ with ARKit support
        if #available(iOS 13.0, *) {
            return configuration.enableARRendering && ARWorldTrackingConfiguration.isSupported
        }
        return false
    }
    
    public func release() async {
        activeSessions.removeAll()
        sessionHistory.removeAll()
        resultCache.removeAll()
        
        arSessionManager.stopSession()
        arSessionManager = ARSessionManager()
        trackingEngine = TrackingEngine()
        detectionEngine = DetectionEngine()
        renderingEngine = RenderingEngine()
        
        resultStreamContinuation?.finish()
        
        metrics = ARRenderingCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        arSessionManager = ARSessionManager()
        trackingEngine = TrackingEngine()
        detectionEngine = DetectionEngine()
        renderingEngine = RenderingEngine()
        
        if configuration.enableLogging {
            print("[ARRendering] 🚀 AR Rendering capability initialized")
            print("[ARRendering] 📱 Framework: \(configuration.renderingFramework.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: ARRenderingCapabilityConfiguration) async throws {
        // Update AR rendering configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<ARRenderingResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - AR Rendering Processing
    
    public func startSession(_ request: ARRenderingRequest) async throws -> ARRenderingResult {
        guard configuration.enableARRendering else {
            throw ARRenderingError.arRenderingDisabled
        }
        
        guard activeSessions.count < configuration.maxConcurrentSessions else {
            throw ARRenderingError.sessionLimitExceeded
        }
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(for: request)
            if let cachedResult = resultCache[cacheKey] {
                await updateCacheHitMetrics()
                return cachedResult
            }
        }
        
        let startTime = Date()
        activeSessions[request.id] = request
        
        do {
            // Create AR session
            let arSession = arSessionManager.createSession(with: request)
            
            // Process current frame
            let currentFrame = arSession.currentFrame
            let trackingState = trackingEngine.analyzeTrackingState(currentFrame)
            
            // Detect elements
            let detectedElements = currentFrame != nil ? detectionEngine.detectElements(in: currentFrame!) : []
            
            // Process anchors
            let anchors = currentFrame?.anchors ?? []
            let anchorInfos = detectionEngine.processAnchors(anchors)
            
            // Calculate metrics
            let renderingMetrics = renderingEngine.calculateRenderingMetrics(currentFrame)
            
            // Create session state
            let sessionState = ARRenderingResult.SessionState(
                isRunning: true,
                isPaused: false,
                trackingState: trackingState,
                currentFrame: createFrameInfo(from: currentFrame),
                lightEstimate: createLightEstimate(from: currentFrame),
                worldMappingStatus: .extending
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ARRenderingResult(
                requestId: request.id,
                sessionState: sessionState,
                trackingState: trackingState,
                detectedElements: detectedElements,
                anchors: anchorInfos,
                renderingMetrics: renderingMetrics,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeSessions.removeValue(forKey: request.id)
            sessionHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logSession(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ARRenderingResult(
                requestId: request.id,
                sessionState: ARRenderingResult.SessionState(
                    isRunning: false,
                    isPaused: false,
                    trackingState: .notAvailable,
                    worldMappingStatus: .notAvailable
                ),
                trackingState: .notAvailable,
                detectedElements: [],
                anchors: [],
                renderingMetrics: ARRenderingResult.RenderingMetrics(
                    frameRate: 0,
                    frameTime: 0,
                    gpuUtilization: 0,
                    memoryUsage: 0,
                    thermalState: .nominal,
                    powerConsumption: 0,
                    trackingQuality: .poor,
                    anchorsTracked: 0,
                    planesDetected: 0,
                    objectsDetected: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? ARRenderingError ?? ARRenderingError.sessionFailed(error.localizedDescription)
            )
            
            activeSessions.removeValue(forKey: request.id)
            sessionHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logSession(result)
            }
            
            throw error
        }
    }
    
    public func pauseSession(_ sessionId: UUID) async {
        arSessionManager.pauseSession()
        
        if configuration.enableLogging {
            print("[ARRendering] ⏸️ Session paused: \(sessionId)")
        }
    }
    
    public func stopSession(_ sessionId: UUID) async {
        arSessionManager.stopSession()
        activeSessions.removeValue(forKey: sessionId)
        
        if configuration.enableLogging {
            print("[ARRendering] 🛑 Session stopped: \(sessionId)")
        }
    }
    
    public func getActiveSessions() async -> [ARRenderingRequest] {
        return Array(activeSessions.values)
    }
    
    public func getSessionHistory(since: Date? = nil) async -> [ARRenderingResult] {
        if let since = since {
            return sessionHistory.filter { $0.timestamp >= since }
        }
        return sessionHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ARRenderingCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ARRenderingCapabilityMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func createFrameInfo(from frame: ARFrame?) -> ARRenderingResult.SessionState.FrameInfo? {
        guard let frame = frame else { return nil }
        
        let cameraTransform = ARRenderingResult.SessionState.FrameInfo.Transform(
            translation: SIMD3<Float>(frame.camera.transform.columns.3.x, frame.camera.transform.columns.3.y, frame.camera.transform.columns.3.z),
            rotation: simd_quatf(frame.camera.transform)
        )
        
        let cameraIntrinsics = ARRenderingResult.SessionState.FrameInfo.CameraIntrinsics(
            focalLength: SIMD2<Float>(frame.camera.intrinsics.columns.0.x, frame.camera.intrinsics.columns.1.y),
            principalPoint: SIMD2<Float>(frame.camera.intrinsics.columns.2.x, frame.camera.intrinsics.columns.2.y),
            imageResolution: frame.camera.imageResolution
        )
        
        let displayTransform = ARRenderingResult.SessionState.FrameInfo.Transform(
            translation: SIMD3<Float>(0, 0, 0),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
        )
        
        return ARRenderingResult.SessionState.FrameInfo(
            timestamp: frame.timestamp,
            cameraTransform: cameraTransform,
            cameraIntrinsics: cameraIntrinsics,
            imageResolution: frame.camera.imageResolution,
            displayTransform: displayTransform
        )
    }
    
    private func createLightEstimate(from frame: ARFrame?) -> ARRenderingResult.SessionState.LightEstimate? {
        guard let frame = frame, let lightEstimate = frame.lightEstimate else { return nil }
        
        return ARRenderingResult.SessionState.LightEstimate(
            ambientIntensity: lightEstimate.ambientIntensity,
            ambientColorTemperature: lightEstimate.ambientColorTemperature
        )
    }
    
    private func generateCacheKey(for request: ARRenderingRequest) -> String {
        let configHash = request.sessionConfig.configType.rawValue.hashValue
        let frameworkHash = request.renderingOptions.framework.rawValue.hashValue
        let trackingHash = request.trackingOptions.resetTracking.hashValue
        
        return "\(configHash)_\(frameworkHash)_\(trackingHash)"
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit metrics
    }
    
    private func updateSuccessMetrics(_ result: ARRenderingResult) async {
        let totalSessions = metrics.totalSessions + 1
        let successfulSessions = metrics.successfulSessions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalSessions)) + result.processingTime) / Double(totalSessions)
        let newAverageFrameRate = ((metrics.averageFrameRate * Double(metrics.successfulSessions)) + result.renderingMetrics.frameRate) / Double(successfulSessions)
        let newAverageTrackingQuality = ((metrics.averageTrackingQuality * Double(metrics.successfulSessions)) + result.trackingQuality) / Double(successfulSessions)
        
        var sessionsByType = metrics.sessionsByType
        sessionsByType["ar_session", default: 0] += 1
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestFrameRate = metrics.successfulSessions == 0 ? result.renderingMetrics.frameRate : max(performanceStats.bestFrameRate, result.renderingMetrics.frameRate)
        let worstFrameRate = metrics.successfulSessions == 0 ? result.renderingMetrics.frameRate : min(performanceStats.worstFrameRate, result.renderingMetrics.frameRate)
        let newAverageAnchorsPerSession = ((performanceStats.averageAnchorsPerSession * Double(metrics.successfulSessions)) + Double(result.anchors.count)) / Double(successfulSessions)
        let newAverageDetectionsPerSession = ((performanceStats.averageDetectionsPerSession * Double(metrics.successfulSessions)) + Double(result.detectedElements.count)) / Double(successfulSessions)
        let totalPlanesDetected = performanceStats.totalPlanesDetected + result.renderingMetrics.planesDetected
        let totalObjectsDetected = performanceStats.totalObjectsDetected + result.renderingMetrics.objectsDetected
        let newAverageSessionDuration = ((performanceStats.averageSessionDuration * Double(metrics.successfulSessions)) + result.processingTime) / Double(successfulSessions)
        
        performanceStats = ARRenderingCapabilityMetrics.PerformanceStats(
            bestFrameRate: bestFrameRate,
            worstFrameRate: worstFrameRate,
            averageAnchorsPerSession: newAverageAnchorsPerSession,
            averageDetectionsPerSession: newAverageDetectionsPerSession,
            totalPlanesDetected: totalPlanesDetected,
            totalObjectsDetected: totalObjectsDetected,
            averageSessionDuration: newAverageSessionDuration
        )
        
        metrics = ARRenderingCapabilityMetrics(
            totalSessions: totalSessions,
            successfulSessions: successfulSessions,
            failedSessions: metrics.failedSessions,
            averageProcessingTime: newAverageProcessingTime,
            sessionsByType: sessionsByType,
            averageFrameRate: newAverageFrameRate,
            averageTrackingQuality: newAverageTrackingQuality,
            errorsByType: metrics.errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: ARRenderingResult) async {
        let totalSessions = metrics.totalSessions + 1
        let failedSessions = metrics.failedSessions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = ARRenderingCapabilityMetrics(
            totalSessions: totalSessions,
            successfulSessions: metrics.successfulSessions,
            failedSessions: failedSessions,
            averageProcessingTime: metrics.averageProcessingTime,
            sessionsByType: metrics.sessionsByType,
            averageFrameRate: metrics.averageFrameRate,
            averageTrackingQuality: metrics.averageTrackingQuality,
            errorsByType: errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logSession(_ result: ARRenderingResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let frameRateStr = String(format: "%.1f", result.renderingMetrics.frameRate)
        let anchorCount = result.anchors.count
        let detectionCount = result.detectedElements.count
        let trackingState = result.trackingState.rawValue
        
        print("[ARRendering] \(statusIcon) Session: \(frameRateStr) FPS, \(anchorCount) anchors, \(detectionCount) detections, \(trackingState) tracking (\(timeStr)s)")
        
        if let error = result.error {
            print("[ARRendering] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - AR Rendering Capability Implementation

/// AR Rendering capability providing augmented reality rendering
@available(iOS 13.0, macOS 10.15, *)
public actor ARRenderingCapability: DomainCapability {
    public typealias ConfigurationType = ARRenderingCapabilityConfiguration
    public typealias ResourceType = ARRenderingCapabilityResource
    
    private var _configuration: ARRenderingCapabilityConfiguration
    private var _resources: ARRenderingCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "ar-rendering-capability" }
    
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
    
    public var configuration: ARRenderingCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ARRenderingCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ARRenderingCapabilityConfiguration = ARRenderingCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ARRenderingCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ARRenderingCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid AR Rendering configuration")
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
        // AR rendering is supported on iOS 13+ with ARKit
        if #available(iOS 13.0, *) {
            return ARWorldTrackingConfiguration.isSupported
        }
        return false
    }
    
    public func requestPermission() async throws {
        // AR rendering requires camera permissions - handled by ARKit
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - AR Rendering Operations
    
    /// Start AR rendering session
    public func startSession(_ request: ARRenderingRequest) async throws -> ARRenderingResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        return try await _resources.startSession(request)
    }
    
    /// Pause AR session
    public func pauseSession(_ sessionId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        await _resources.pauseSession(sessionId)
    }
    
    /// Stop AR session
    public func stopSession(_ sessionId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        await _resources.stopSession(sessionId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<ARRenderingResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active sessions
    public func getActiveSessions() async throws -> [ARRenderingRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        return await _resources.getActiveSessions()
    }
    
    /// Get session history
    public func getSessionHistory(since: Date? = nil) async throws -> [ARRenderingResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        return await _resources.getSessionHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ARRenderingCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AR Rendering capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create world tracking session request
    public func createWorldTrackingRequest(
        enablePlaneDetection: Bool = true,
        enableImageTracking: Bool = false,
        enableOcclusion: Bool = true
    ) -> ARRenderingRequest {
        let sessionConfig = ARRenderingRequest.SessionConfiguration(
            configType: .worldTracking,
            planeDetection: enablePlaneDetection ? .both : .none,
            frameSemantics: enableOcclusion ? [.personSegmentation, .sceneDepth] : []
        )
        
        return ARRenderingRequest(sessionConfig: sessionConfig)
    }
    
    /// Create face tracking session request
    public func createFaceTrackingRequest() -> ARRenderingRequest {
        let sessionConfig = ARRenderingRequest.SessionConfiguration(
            configType: .faceTracking,
            frameSemantics: [.personSegmentation]
        )
        
        return ARRenderingRequest(sessionConfig: sessionConfig)
    }
    
    /// Create image tracking session request
    public func createImageTrackingRequest(maxTrackedImages: Int = 1) -> ARRenderingRequest {
        let sessionConfig = ARRenderingRequest.SessionConfiguration(
            configType: .imageTracking
        )
        
        let trackingOptions = ARRenderingRequest.TrackingOptions(
            maximumNumberOfTrackedImages: maxTrackedImages
        )
        
        return ARRenderingRequest(sessionConfig: sessionConfig, trackingOptions: trackingOptions)
    }
    
    /// Check if AR features are supported
    public func checkARSupport() async throws -> (worldTracking: Bool, faceTracking: Bool, bodyTracking: Bool, imageTracking: Bool) {
        let worldTracking = ARWorldTrackingConfiguration.isSupported
        let faceTracking = ARFaceTrackingConfiguration.isSupported
        let bodyTracking: Bool
        let imageTracking = ARImageTrackingConfiguration.isSupported
        
        if #available(iOS 13.0, *) {
            bodyTracking = ARBodyTrackingConfiguration.isSupported
        } else {
            bodyTracking = false
        }
        
        return (worldTracking, faceTracking, bodyTracking, imageTracking)
    }
    
    /// Get device AR capabilities
    public func getARCapabilities() async throws -> [String] {
        var capabilities: [String] = []
        
        if ARWorldTrackingConfiguration.isSupported {
            capabilities.append("worldTracking")
        }
        
        if ARFaceTrackingConfiguration.isSupported {
            capabilities.append("faceTracking")
        }
        
        if ARImageTrackingConfiguration.isSupported {
            capabilities.append("imageTracking")
        }
        
        if #available(iOS 13.0, *), ARBodyTrackingConfiguration.isSupported {
            capabilities.append("bodyTracking")
        }
        
        if #available(iOS 12.0, *), ARObjectScanningConfiguration.isSupported {
            capabilities.append("objectScanning")
        }
        
        return capabilities
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// AR Rendering specific errors
public enum ARRenderingError: Error, LocalizedError {
    case arRenderingDisabled
    case sessionFailed(String)
    case trackingFailed
    case configurationNotSupported
    case cameraPermissionDenied
    case sessionLimitExceeded
    case arKitNotAvailable
    case invalidConfiguration(String)
    case hardwareNotSupported
    
    public var errorDescription: String? {
        switch self {
        case .arRenderingDisabled:
            return "AR rendering is disabled"
        case .sessionFailed(let reason):
            return "AR session failed: \(reason)"
        case .trackingFailed:
            return "AR tracking failed"
        case .configurationNotSupported:
            return "AR configuration not supported on this device"
        case .cameraPermissionDenied:
            return "Camera permission required for AR"
        case .sessionLimitExceeded:
            return "Maximum AR sessions exceeded"
        case .arKitNotAvailable:
            return "ARKit not available on this device"
        case .invalidConfiguration(let reason):
            return "Invalid AR configuration: \(reason)"
        case .hardwareNotSupported:
            return "AR hardware not supported"
        }
    }
}