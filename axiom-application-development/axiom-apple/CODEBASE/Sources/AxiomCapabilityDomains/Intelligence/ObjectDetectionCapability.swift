import Foundation
import Vision
import CoreImage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Object Detection Capability Configuration

/// Configuration for Object Detection capability
public struct ObjectDetectionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableObjectDetection: Bool
    public let enableCustomModels: Bool
    public let enableRealTimeDetection: Bool
    public let enableBatchDetection: Bool
    public let enableTrackingOptimization: Bool
    public let maxConcurrentDetections: Int
    public let detectionTimeout: TimeInterval
    public let minimumConfidence: Float
    public let maximumObjects: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let preferredComputeUnits: ComputeUnits
    public let nonMaxSuppressionThreshold: Float
    public let overlapThreshold: Float
    
    public enum ComputeUnits: String, Codable, CaseIterable {
        case cpuOnly = "cpu-only"
        case cpuAndGPU = "cpu-and-gpu"
        case cpuAndNeuralEngine = "cpu-and-neural-engine"
        case all = "all"
    }
    
    public init(
        enableObjectDetection: Bool = true,
        enableCustomModels: Bool = true,
        enableRealTimeDetection: Bool = true,
        enableBatchDetection: Bool = true,
        enableTrackingOptimization: Bool = true,
        maxConcurrentDetections: Int = 6,
        detectionTimeout: TimeInterval = 30.0,
        minimumConfidence: Float = 0.3,
        maximumObjects: Int = 50,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 150,
        enablePerformanceOptimization: Bool = true,
        preferredComputeUnits: ComputeUnits = .all,
        nonMaxSuppressionThreshold: Float = 0.5,
        overlapThreshold: Float = 0.3
    ) {
        self.enableObjectDetection = enableObjectDetection
        self.enableCustomModels = enableCustomModels
        self.enableRealTimeDetection = enableRealTimeDetection
        self.enableBatchDetection = enableBatchDetection
        self.enableTrackingOptimization = enableTrackingOptimization
        self.maxConcurrentDetections = maxConcurrentDetections
        self.detectionTimeout = detectionTimeout
        self.minimumConfidence = minimumConfidence
        self.maximumObjects = maximumObjects
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.preferredComputeUnits = preferredComputeUnits
        self.nonMaxSuppressionThreshold = nonMaxSuppressionThreshold
        self.overlapThreshold = overlapThreshold
    }
    
    public var isValid: Bool {
        maxConcurrentDetections > 0 &&
        detectionTimeout > 0 &&
        minimumConfidence >= 0.0 && minimumConfidence <= 1.0 &&
        maximumObjects > 0 &&
        cacheSize >= 0 &&
        nonMaxSuppressionThreshold >= 0.0 && nonMaxSuppressionThreshold <= 1.0 &&
        overlapThreshold >= 0.0 && overlapThreshold <= 1.0
    }
    
    public func merged(with other: ObjectDetectionCapabilityConfiguration) -> ObjectDetectionCapabilityConfiguration {
        ObjectDetectionCapabilityConfiguration(
            enableObjectDetection: other.enableObjectDetection,
            enableCustomModels: other.enableCustomModels,
            enableRealTimeDetection: other.enableRealTimeDetection,
            enableBatchDetection: other.enableBatchDetection,
            enableTrackingOptimization: other.enableTrackingOptimization,
            maxConcurrentDetections: other.maxConcurrentDetections,
            detectionTimeout: other.detectionTimeout,
            minimumConfidence: other.minimumConfidence,
            maximumObjects: other.maximumObjects,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            preferredComputeUnits: other.preferredComputeUnits,
            nonMaxSuppressionThreshold: other.nonMaxSuppressionThreshold,
            overlapThreshold: other.overlapThreshold
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ObjectDetectionCapabilityConfiguration {
        var adjustedTimeout = detectionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentDetections = maxConcurrentDetections
        var adjustedCacheSize = cacheSize
        var adjustedComputeUnits = preferredComputeUnits
        var adjustedMaxObjects = maximumObjects
        var adjustedConfidence = minimumConfidence
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(detectionTimeout, 15.0)
            adjustedConcurrentDetections = min(maxConcurrentDetections, 2)
            adjustedCacheSize = min(cacheSize, 30)
            adjustedComputeUnits = .cpuOnly
            adjustedMaxObjects = min(maximumObjects, 20)
            adjustedConfidence = max(minimumConfidence, 0.5) // Higher confidence for faster processing
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ObjectDetectionCapabilityConfiguration(
            enableObjectDetection: enableObjectDetection,
            enableCustomModels: enableCustomModels,
            enableRealTimeDetection: enableRealTimeDetection,
            enableBatchDetection: enableBatchDetection,
            enableTrackingOptimization: enableTrackingOptimization,
            maxConcurrentDetections: adjustedConcurrentDetections,
            detectionTimeout: adjustedTimeout,
            minimumConfidence: adjustedConfidence,
            maximumObjects: adjustedMaxObjects,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            preferredComputeUnits: adjustedComputeUnits,
            nonMaxSuppressionThreshold: nonMaxSuppressionThreshold,
            overlapThreshold: overlapThreshold
        )
    }
}

// MARK: - Object Detection Types

/// Object detection request
public struct ObjectDetectionRequest: Sendable, Identifiable {
    public let id: UUID
    public let image: CIImage
    public let modelIdentifier: String?
    public let options: DetectionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct DetectionOptions: Sendable {
        public let minimumConfidence: Float
        public let maximumObjects: Int
        public let usesCPUOnly: Bool
        public let computeUnits: ObjectDetectionCapabilityConfiguration.ComputeUnits?
        public let regionOfInterest: CGRect?
        public let objectTypes: Set<String>
        public let enableTracking: Bool
        public let trackingId: UUID?
        public let preprocessingOptions: PreprocessingOptions
        
        public struct PreprocessingOptions: Sendable {
            public let normalizeValues: Bool
            public let resizeToModelInput: Bool
            public let applyCenterCrop: Bool
            public let enhanceContrast: Bool
            public let reduceLighting: Bool
            
            public init(normalizeValues: Bool = true, resizeToModelInput: Bool = true, applyCenterCrop: Bool = false, enhanceContrast: Bool = false, reduceLighting: Bool = false) {
                self.normalizeValues = normalizeValues
                self.resizeToModelInput = resizeToModelInput
                self.applyCenterCrop = applyCenterCrop
                self.enhanceContrast = enhanceContrast
                self.reduceLighting = reduceLighting
            }
        }
        
        public init(
            minimumConfidence: Float = 0.3,
            maximumObjects: Int = 50,
            usesCPUOnly: Bool = false,
            computeUnits: ObjectDetectionCapabilityConfiguration.ComputeUnits? = nil,
            regionOfInterest: CGRect? = nil,
            objectTypes: Set<String> = [],
            enableTracking: Bool = false,
            trackingId: UUID? = nil,
            preprocessingOptions: PreprocessingOptions = PreprocessingOptions()
        ) {
            self.minimumConfidence = minimumConfidence
            self.maximumObjects = maximumObjects
            self.usesCPUOnly = usesCPUOnly
            self.computeUnits = computeUnits
            self.regionOfInterest = regionOfInterest
            self.objectTypes = objectTypes
            self.enableTracking = enableTracking
            self.trackingId = trackingId
            self.preprocessingOptions = preprocessingOptions
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        image: CIImage,
        modelIdentifier: String? = nil,
        options: DetectionOptions = DetectionOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.image = image
        self.modelIdentifier = modelIdentifier
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Object detection result
public struct ObjectDetectionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let detectedObjects: [DetectedObject]
    public let modelInfo: ModelInfo
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ObjectDetectionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct DetectedObject: Sendable, Identifiable {
        public let id: UUID
        public let label: String
        public let confidence: Float
        public let boundingBox: CGRect
        public let center: CGPoint
        public let area: Float
        public let classId: Int?
        public let trackingId: UUID?
        public let trackingState: TrackingState
        public let features: ObjectFeatures?
        public let hierarchy: [String]
        public let additionalInfo: [String: String]
        
        public enum TrackingState: String, Sendable, CaseIterable {
            case new = "new"
            case tracked = "tracked"
            case lost = "lost"
            case merged = "merged"
        }
        
        public struct ObjectFeatures: Sendable {
            public let size: CGSize
            public let aspectRatio: Float
            public let color: ColorInfo?
            public let motion: MotionInfo?
            public let texture: TextureInfo?
            
            public struct ColorInfo: Sendable {
                public let dominantColor: String
                public let colorHistogram: [Float]
                public let brightness: Float
                
                public init(dominantColor: String, colorHistogram: [Float], brightness: Float) {
                    self.dominantColor = dominantColor
                    self.colorHistogram = colorHistogram
                    self.brightness = brightness
                }
            }
            
            public struct MotionInfo: Sendable {
                public let velocity: CGVector
                public let acceleration: CGVector
                public let direction: Float
                
                public init(velocity: CGVector, acceleration: CGVector, direction: Float) {
                    self.velocity = velocity
                    self.acceleration = acceleration
                    self.direction = direction
                }
            }
            
            public struct TextureInfo: Sendable {
                public let smoothness: Float
                public let edgeDensity: Float
                public let pattern: String?
                
                public init(smoothness: Float, edgeDensity: Float, pattern: String? = nil) {
                    self.smoothness = smoothness
                    self.edgeDensity = edgeDensity
                    self.pattern = pattern
                }
            }
            
            public init(size: CGSize, aspectRatio: Float, color: ColorInfo? = nil, motion: MotionInfo? = nil, texture: TextureInfo? = nil) {
                self.size = size
                self.aspectRatio = aspectRatio
                self.color = color
                self.motion = motion
                self.texture = texture
            }
        }
        
        public init(
            label: String,
            confidence: Float,
            boundingBox: CGRect,
            classId: Int? = nil,
            trackingId: UUID? = nil,
            trackingState: TrackingState = .new,
            features: ObjectFeatures? = nil,
            hierarchy: [String] = [],
            additionalInfo: [String: String] = [:]
        ) {
            self.id = UUID()
            self.label = label
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
            self.area = Float(boundingBox.width * boundingBox.height)
            self.classId = classId
            self.trackingId = trackingId
            self.trackingState = trackingState
            self.features = features
            self.hierarchy = hierarchy
            self.additionalInfo = additionalInfo
        }
    }
    
    public struct ModelInfo: Sendable {
        public let identifier: String
        public let name: String
        public let version: String?
        public let description: String?
        public let inputSize: CGSize?
        public let outputClasses: [String]
        public let computeUnits: String?
        public let modelType: ModelType
        
        public enum ModelType: String, Sendable, CaseIterable {
            case yolo = "yolo"
            case ssd = "ssd"
            case rcnn = "rcnn"
            case vision = "vision"
            case custom = "custom"
        }
        
        public init(
            identifier: String,
            name: String,
            version: String? = nil,
            description: String? = nil,
            inputSize: CGSize? = nil,
            outputClasses: [String] = [],
            computeUnits: String? = nil,
            modelType: ModelType = .vision
        ) {
            self.identifier = identifier
            self.name = name
            self.version = version
            self.description = description
            self.inputSize = inputSize
            self.outputClasses = outputClasses
            self.computeUnits = computeUnits
            self.modelType = modelType
        }
    }
    
    public init(
        requestId: UUID,
        detectedObjects: [DetectedObject],
        modelInfo: ModelInfo,
        processingTime: TimeInterval,
        success: Bool,
        error: ObjectDetectionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.detectedObjects = detectedObjects
        self.modelInfo = modelInfo
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var objectCount: Int {
        detectedObjects.count
    }
    
    public var averageConfidence: Float {
        guard !detectedObjects.isEmpty else { return 0.0 }
        return detectedObjects.reduce(0) { $0 + $1.confidence } / Float(detectedObjects.count)
    }
    
    public var highestConfidenceObject: DetectedObject? {
        detectedObjects.max(by: { $0.confidence < $1.confidence })
    }
    
    public func objects(withLabel label: String) -> [DetectedObject] {
        detectedObjects.filter { $0.label == label }
    }
    
    public func objects(withMinimumConfidence confidence: Float) -> [DetectedObject] {
        detectedObjects.filter { $0.confidence >= confidence }
    }
}

/// Object detection metrics
public struct ObjectDetectionMetrics: Sendable {
    public let totalDetections: Int
    public let successfulDetections: Int
    public let failedDetections: Int
    public let averageProcessingTime: TimeInterval
    public let detectionsByModel: [String: Int]
    public let detectionsByObjectType: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let averageObjectsPerImage: Double
    public let throughputPerSecond: Double
    public let trackingStats: TrackingStats
    public let modelPerformanceStats: [String: ModelPerformanceStats]
    
    public struct TrackingStats: Sendable {
        public let totalTrackedObjects: Int
        public let activeTrackings: Int
        public let lostTrackings: Int
        public let mergedTrackings: Int
        public let averageTrackingDuration: TimeInterval
        
        public init(totalTrackedObjects: Int = 0, activeTrackings: Int = 0, lostTrackings: Int = 0, mergedTrackings: Int = 0, averageTrackingDuration: TimeInterval = 0) {
            self.totalTrackedObjects = totalTrackedObjects
            self.activeTrackings = activeTrackings
            self.lostTrackings = lostTrackings
            self.mergedTrackings = mergedTrackings
            self.averageTrackingDuration = averageTrackingDuration
        }
    }
    
    public struct ModelPerformanceStats: Sendable {
        public let usageCount: Int
        public let averageProcessingTime: TimeInterval
        public let successRate: Double
        public let averageObjectCount: Double
        public let averageConfidence: Double
        
        public init(usageCount: Int, averageProcessingTime: TimeInterval, successRate: Double, averageObjectCount: Double, averageConfidence: Double) {
            self.usageCount = usageCount
            self.averageProcessingTime = averageProcessingTime
            self.successRate = successRate
            self.averageObjectCount = averageObjectCount
            self.averageConfidence = averageConfidence
        }
    }
    
    public init(
        totalDetections: Int = 0,
        successfulDetections: Int = 0,
        failedDetections: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        detectionsByModel: [String: Int] = [:],
        detectionsByObjectType: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        averageObjectsPerImage: Double = 0,
        throughputPerSecond: Double = 0,
        trackingStats: TrackingStats = TrackingStats(),
        modelPerformanceStats: [String: ModelPerformanceStats] = [:]
    ) {
        self.totalDetections = totalDetections
        self.successfulDetections = successfulDetections
        self.failedDetections = failedDetections
        self.averageProcessingTime = averageProcessingTime
        self.detectionsByModel = detectionsByModel
        self.detectionsByObjectType = detectionsByObjectType
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.averageObjectsPerImage = averageObjectsPerImage
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalDetections) / averageProcessingTime : 0
        self.trackingStats = trackingStats
        self.modelPerformanceStats = modelPerformanceStats
    }
    
    public var successRate: Double {
        totalDetections > 0 ? Double(successfulDetections) / Double(totalDetections) : 0
    }
}

// MARK: - Object Detection Resource

/// Object detection resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ObjectDetectionCapabilityResource: AxiomCapabilityResource {
    private let configuration: ObjectDetectionCapabilityConfiguration
    private var activeDetections: [UUID: ObjectDetectionRequest] = [:]
    private var detectionQueue: [ObjectDetectionRequest] = []
    private var detectionHistory: [ObjectDetectionResult] = []
    private var resultCache: [String: ObjectDetectionResult] = [:]
    private var loadedModels: [String: MLModel] = [:]
    private var modelInfos: [String: ObjectDetectionResult.ModelInfo] = [:]
    private var trackedObjects: [UUID: TrackedObjectState] = [:]
    private var metrics: ObjectDetectionMetrics = ObjectDetectionMetrics()
    private var resultStreamContinuation: AsyncStream<ObjectDetectionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    private struct TrackedObjectState {
        let trackingId: UUID
        let label: String
        var lastSeen: Date
        var positions: [CGPoint]
        var confidences: [Float]
        var state: ObjectDetectionResult.DetectedObject.TrackingState
        
        init(trackingId: UUID, label: String, position: CGPoint, confidence: Float) {
            self.trackingId = trackingId
            self.label = label
            self.lastSeen = Date()
            self.positions = [position]
            self.confidences = [confidence]
            self.state = .new
        }
    }
    
    public init(configuration: ObjectDetectionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 300_000_000, // 300MB for object detection
            cpu: 5.0, // Very high CPU usage for object detection
            bandwidth: 0,
            storage: 150_000_000 // 150MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let detectionMemory = activeDetections.count * 30_000_000 // ~30MB per active detection
            let cacheMemory = resultCache.count * 200_000 // ~200KB per cached result
            let modelMemory = loadedModels.count * 100_000_000 // ~100MB per loaded model
            let trackingMemory = trackedObjects.count * 10_000 // ~10KB per tracked object
            let historyMemory = detectionHistory.count * 50_000
            
            return ResourceUsage(
                memory: detectionMemory + cacheMemory + modelMemory + trackingMemory + historyMemory + 30_000_000,
                cpu: activeDetections.isEmpty ? 0.4 : 4.5,
                bandwidth: 0,
                storage: resultCache.count * 100_000 + loadedModels.count * 200_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Object detection is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableObjectDetection
        }
        return false
    }
    
    public func release() async {
        activeDetections.removeAll()
        detectionQueue.removeAll()
        detectionHistory.removeAll()
        resultCache.removeAll()
        loadedModels.removeAll()
        modelInfos.removeAll()
        trackedObjects.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = ObjectDetectionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize default detection models
        if configuration.enableCustomModels {
            await loadDefaultModels()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[ObjectDetection] 🚀 Object Detection capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: ObjectDetectionCapabilityConfiguration) async throws {
        // Update tracking optimization if needed
        if configuration.enableTrackingOptimization {
            await updateTracking()
        }
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<ObjectDetectionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadModel(from url: URL, identifier: String) async throws -> ObjectDetectionResult.ModelInfo {
        guard configuration.enableCustomModels else {
            throw ObjectDetectionError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            let modelInfo = createModelInfo(from: mlModel, identifier: identifier, url: url)
            
            loadedModels[identifier] = mlModel
            modelInfos[identifier] = modelInfo
            
            if configuration.enableLogging {
                await logModel(modelInfo, action: "Loaded")
            }
            
            return modelInfo
            
        } catch {
            throw ObjectDetectionError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadModel(_ identifier: String) async {
        loadedModels.removeValue(forKey: identifier)
        modelInfos.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[ObjectDetection] 🗑️ Unloaded model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [ObjectDetectionResult.ModelInfo] {
        return Array(modelInfos.values)
    }
    
    public func getModelInfo(identifier: String) async -> ObjectDetectionResult.ModelInfo? {
        return modelInfos[identifier]
    }
    
    // MARK: - Object Detection
    
    public func detectObjects(_ request: ObjectDetectionRequest) async throws -> ObjectDetectionResult {
        guard configuration.enableObjectDetection else {
            throw ObjectDetectionError.objectDetectionDisabled
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
        if activeDetections.count >= configuration.maxConcurrentDetections {
            detectionQueue.append(request)
            throw ObjectDetectionError.detectionQueued(request.id)
        }
        
        let startTime = Date()
        activeDetections[request.id] = request
        
        do {
            // Get the model to use
            let model = try await getModelForDetection(request)
            let modelInfo = modelInfos[request.modelIdentifier ?? "default"] ?? createDefaultModelInfo()
            
            // Preprocess image if needed
            let processedImage = await preprocessImage(request.image, options: request.options)
            
            // Perform detection
            var detectedObjects = try await performDetection(
                image: processedImage,
                model: model,
                options: request.options
            )
            
            // Apply non-maximum suppression
            detectedObjects = await applyNonMaxSuppression(to: detectedObjects)
            
            // Apply tracking if enabled
            if request.options.enableTracking {
                detectedObjects = await applyTracking(to: detectedObjects, trackingId: request.options.trackingId)
            }
            
            // Filter by object types if specified
            if !request.options.objectTypes.isEmpty {
                detectedObjects = detectedObjects.filter { request.options.objectTypes.contains($0.label) }
            }
            
            // Limit to maximum objects
            if detectedObjects.count > request.options.maximumObjects {
                detectedObjects = Array(detectedObjects.sorted { $0.confidence > $1.confidence }.prefix(request.options.maximumObjects))
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ObjectDetectionResult(
                requestId: request.id,
                detectedObjects: detectedObjects,
                modelInfo: modelInfo,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeDetections.removeValue(forKey: request.id)
            detectionHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logDetection(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processDetectionQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ObjectDetectionResult(
                requestId: request.id,
                detectedObjects: [],
                modelInfo: createDefaultModelInfo(),
                processingTime: processingTime,
                success: false,
                error: error as? ObjectDetectionError ?? ObjectDetectionError.detectionError(error.localizedDescription)
            )
            
            activeDetections.removeValue(forKey: request.id)
            detectionHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logDetection(result)
            }
            
            throw error
        }
    }
    
    public func detectObjectsInBatch(_ requests: [ObjectDetectionRequest]) async throws -> [ObjectDetectionResult] {
        guard configuration.enableBatchDetection else {
            throw ObjectDetectionError.batchDetectionDisabled
        }
        
        var results: [ObjectDetectionResult] = []
        
        // Process in batches to manage memory
        let batchSize = min(configuration.maxConcurrentDetections, requests.count)
        
        for batch in requests.chunked(into: batchSize) {
            let batchResults = try await withThrowingTaskGroup(of: ObjectDetectionResult.self) { group in
                for request in batch {
                    group.addTask {
                        try await self.detectObjects(request)
                    }
                }
                
                var batchResults: [ObjectDetectionResult] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    public func cancelDetection(_ requestId: UUID) async {
        activeDetections.removeValue(forKey: requestId)
        detectionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[ObjectDetection] 🚫 Cancelled detection: \(requestId)")
        }
    }
    
    public func getActiveDetections() async -> [ObjectDetectionRequest] {
        return Array(activeDetections.values)
    }
    
    public func getDetectionHistory(since: Date? = nil) async -> [ObjectDetectionResult] {
        if let since = since {
            return detectionHistory.filter { $0.timestamp >= since }
        }
        return detectionHistory
    }
    
    // MARK: - Tracking
    
    public func getTrackedObjects() async -> [UUID: String] {
        return trackedObjects.mapValues { $0.label }
    }
    
    public func clearTracking() async {
        trackedObjects.removeAll()
        
        if configuration.enableLogging {
            print("[ObjectDetection] 🧹 Cleared all tracking data")
        }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ObjectDetectionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ObjectDetectionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultModels() async {
        // Create default model info for Vision framework
        let defaultModelInfo = ObjectDetectionResult.ModelInfo(
            identifier: "default",
            name: "Vision Object Detection",
            version: "1.0",
            description: "Built-in Vision framework object detection",
            outputClasses: ["rectangle", "object"],
            computeUnits: configuration.preferredComputeUnits.rawValue,
            modelType: .vision
        )
        
        modelInfos["default"] = defaultModelInfo
        
        if configuration.enableLogging {
            print("[ObjectDetection] 📦 Loaded default Vision detection model")
        }
    }
    
    private func updateTracking() async {
        // Clean up old tracking data
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        let staleTrackings = trackedObjects.filter { $0.value.lastSeen < cutoffTime }
        
        for (trackingId, _) in staleTrackings {
            trackedObjects.removeValue(forKey: trackingId)
        }
        
        if configuration.enableLogging && !staleTrackings.isEmpty {
            print("[ObjectDetection] 🧹 Cleaned up \(staleTrackings.count) stale trackings")
        }
    }
    
    private func optimizePerformance() async {
        // Performance optimization for object detection
        if configuration.enableLogging {
            print("[ObjectDetection] ⚡ Performance optimization enabled")
        }
    }
    
    private func getModelForDetection(_ request: ObjectDetectionRequest) async throws -> MLModel? {
        if let modelId = request.modelIdentifier {
            guard let model = loadedModels[modelId] else {
                throw ObjectDetectionError.modelNotLoaded(modelId)
            }
            return model
        }
        
        // Use Vision framework for default detection
        return nil
    }
    
    private func preprocessImage(_ image: CIImage, options: ObjectDetectionRequest.DetectionOptions) async -> CIImage {
        var processedImage = image
        
        // Apply region of interest if specified
        if let roi = options.regionOfInterest {
            let scaledROI = CGRect(
                x: roi.minX * image.extent.width,
                y: roi.minY * image.extent.height,
                width: roi.width * image.extent.width,
                height: roi.height * image.extent.height
            )
            processedImage = processedImage.cropped(to: scaledROI)
        }
        
        // Apply preprocessing options
        let preprocessing = options.preprocessingOptions
        
        if preprocessing.enhanceContrast {
            processedImage = processedImage.applyingFilter("CIColorControls", parameters: ["inputContrast": 1.3])
        }
        
        if preprocessing.reduceLighting {
            processedImage = processedImage.applyingFilter("CIExposureAdjust", parameters: ["inputEV": -0.5])
        }
        
        if preprocessing.applyCenterCrop {
            let cropSize = min(processedImage.extent.width, processedImage.extent.height)
            let cropRect = CGRect(
                x: (processedImage.extent.width - cropSize) / 2,
                y: (processedImage.extent.height - cropSize) / 2,
                width: cropSize,
                height: cropSize
            )
            processedImage = processedImage.cropped(to: cropRect)
        }
        
        return processedImage
    }
    
    private func performDetection(image: CIImage, model: MLModel?, options: ObjectDetectionRequest.DetectionOptions) async throws -> [ObjectDetectionResult.DetectedObject] {
        
        if let model = model {
            // Use custom Core ML model
            return try await detectWithCoreML(image: image, model: model, options: options)
        } else {
            // Use Vision framework
            return try await detectWithVision(image: image, options: options)
        }
    }
    
    private func detectWithVision(image: CIImage, options: ObjectDetectionRequest.DetectionOptions) async throws -> [ObjectDetectionResult.DetectedObject] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(throwing: ObjectDetectionError.noResults)
                    return
                }
                
                let detectedObjects = observations
                    .filter { $0.confidence >= options.minimumConfidence }
                    .enumerated()
                    .map { index, observation in
                        let features = ObjectDetectionResult.DetectedObject.ObjectFeatures(
                            size: observation.boundingBox.size,
                            aspectRatio: Float(observation.boundingBox.width / observation.boundingBox.height)
                        )
                        
                        return ObjectDetectionResult.DetectedObject(
                            label: "rectangle",
                            confidence: observation.confidence,
                            boundingBox: observation.boundingBox,
                            classId: index,
                            features: features
                        )
                    }
                
                continuation.resume(returning: detectedObjects)
            }
            
            request.minimumAspectRatio = 0.2
            request.maximumAspectRatio = 3.0
            request.minimumSize = 0.05
            request.minimumConfidence = options.minimumConfidence
            
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectWithCoreML(image: CIImage, model: MLModel, options: ObjectDetectionRequest.DetectionOptions) async throws -> [ObjectDetectionResult.DetectedObject] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: model)) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(throwing: ObjectDetectionError.noResults)
                    return
                }
                
                let detectedObjects = observations
                    .filter { $0.confidence >= options.minimumConfidence }
                    .map { observation in
                        let topLabel = observation.labels.first
                        let label = topLabel?.identifier ?? "unknown"
                        let confidence = topLabel?.confidence ?? observation.confidence
                        
                        let features = ObjectDetectionResult.DetectedObject.ObjectFeatures(
                            size: observation.boundingBox.size,
                            aspectRatio: Float(observation.boundingBox.width / observation.boundingBox.height)
                        )
                        
                        return ObjectDetectionResult.DetectedObject(
                            label: label,
                            confidence: confidence,
                            boundingBox: observation.boundingBox,
                            features: features,
                            hierarchy: label.components(separatedBy: "/")
                        )
                    }
                
                continuation.resume(returning: detectedObjects)
            }
            
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func applyNonMaxSuppression(to objects: [ObjectDetectionResult.DetectedObject]) async -> [ObjectDetectionResult.DetectedObject] {
        guard objects.count > 1 else { return objects }
        
        var finalObjects: [ObjectDetectionResult.DetectedObject] = []
        var remainingObjects = objects.sorted { $0.confidence > $1.confidence }
        
        while !remainingObjects.isEmpty {
            let bestObject = remainingObjects.removeFirst()
            finalObjects.append(bestObject)
            
            // Remove overlapping objects
            remainingObjects.removeAll { object in
                let intersection = bestObject.boundingBox.intersection(object.boundingBox)
                let union = bestObject.boundingBox.union(object.boundingBox)
                let iou = intersection.area / union.area
                return iou > CGFloat(configuration.overlapThreshold)
            }
        }
        
        return finalObjects
    }
    
    private func applyTracking(to objects: [ObjectDetectionResult.DetectedObject], trackingId: UUID?) async -> [ObjectDetectionResult.DetectedObject] {
        var trackedObjects = objects
        
        for (index, object) in trackedObjects.enumerated() {
            // Try to match with existing tracked objects
            var bestMatch: (UUID, Float)? = nil
            
            for (id, trackedState) in self.trackedObjects {
                // Calculate distance and similarity
                let lastPosition = trackedState.positions.last ?? CGPoint.zero
                let distance = sqrt(pow(object.center.x - lastPosition.x, 2) + pow(object.center.y - lastPosition.y, 2))
                let maxDistance: CGFloat = 100.0 // Maximum tracking distance
                
                if distance < maxDistance && trackedState.label == object.label {
                    let similarity = 1.0 - Float(distance / maxDistance)
                    if bestMatch == nil || similarity > bestMatch!.1 {
                        bestMatch = (id, similarity)
                    }
                }
            }
            
            if let (trackingId, _) = bestMatch {
                // Update existing tracking
                var updatedObject = object
                var updatedState = self.trackedObjects[trackingId]!
                updatedState.lastSeen = Date()
                updatedState.positions.append(object.center)
                updatedState.confidences.append(object.confidence)
                updatedState.state = .tracked
                
                // Keep only recent positions
                if updatedState.positions.count > 10 {
                    updatedState.positions = Array(updatedState.positions.suffix(10))
                    updatedState.confidences = Array(updatedState.confidences.suffix(10))
                }
                
                self.trackedObjects[trackingId] = updatedState
                
                // Calculate motion if we have enough data
                if updatedState.positions.count >= 2 {
                    let currentPos = updatedState.positions.last!
                    let previousPos = updatedState.positions[updatedState.positions.count - 2]
                    let velocity = CGVector(dx: currentPos.x - previousPos.x, dy: currentPos.y - previousPos.y)
                    let direction = atan2(velocity.dy, velocity.dx)
                    
                    let motionInfo = ObjectDetectionResult.DetectedObject.ObjectFeatures.MotionInfo(
                        velocity: velocity,
                        acceleration: CGVector.zero, // Would need more frames to calculate
                        direction: Float(direction)
                    )
                    
                    var features = updatedObject.features ?? ObjectDetectionResult.DetectedObject.ObjectFeatures(
                        size: object.boundingBox.size,
                        aspectRatio: Float(object.boundingBox.width / object.boundingBox.height)
                    )
                    features = ObjectDetectionResult.DetectedObject.ObjectFeatures(
                        size: features.size,
                        aspectRatio: features.aspectRatio,
                        color: features.color,
                        motion: motionInfo,
                        texture: features.texture
                    )
                    
                    updatedObject = ObjectDetectionResult.DetectedObject(
                        label: object.label,
                        confidence: object.confidence,
                        boundingBox: object.boundingBox,
                        classId: object.classId,
                        trackingId: trackingId,
                        trackingState: .tracked,
                        features: features,
                        hierarchy: object.hierarchy,
                        additionalInfo: object.additionalInfo
                    )
                } else {
                    updatedObject = ObjectDetectionResult.DetectedObject(
                        label: object.label,
                        confidence: object.confidence,
                        boundingBox: object.boundingBox,
                        classId: object.classId,
                        trackingId: trackingId,
                        trackingState: .tracked,
                        features: object.features,
                        hierarchy: object.hierarchy,
                        additionalInfo: object.additionalInfo
                    )
                }
                
                trackedObjects[index] = updatedObject
            } else {
                // Create new tracking
                let newTrackingId = UUID()
                let newTrackedState = TrackedObjectState(
                    trackingId: newTrackingId,
                    label: object.label,
                    position: object.center,
                    confidence: object.confidence
                )
                
                self.trackedObjects[newTrackingId] = newTrackedState
                
                let updatedObject = ObjectDetectionResult.DetectedObject(
                    label: object.label,
                    confidence: object.confidence,
                    boundingBox: object.boundingBox,
                    classId: object.classId,
                    trackingId: newTrackingId,
                    trackingState: .new,
                    features: object.features,
                    hierarchy: object.hierarchy,
                    additionalInfo: object.additionalInfo
                )
                
                trackedObjects[index] = updatedObject
            }
        }
        
        return trackedObjects
    }
    
    private func processDetectionQueue() async {
        guard !isProcessingQueue && !detectionQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        detectionQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !detectionQueue.isEmpty && activeDetections.count < configuration.maxConcurrentDetections {
            let request = detectionQueue.removeFirst()
            
            do {
                _ = try await detectObjects(request)
            } catch {
                if configuration.enableLogging {
                    print("[ObjectDetection] ⚠️ Queued detection failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: ObjectDetectionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: ObjectDetectionRequest) -> String {
        // Generate a cache key based on image hash and request parameters
        let imageHash = request.image.extent.hashValue
        let modelId = request.modelIdentifier ?? "default"
        let confidence = Int(request.options.minimumConfidence * 1000)
        let roi = request.options.regionOfInterest?.debugDescription ?? "full"
        return "\(imageHash)_\(modelId)_\(confidence)_\(request.options.maximumObjects)_\(roi)"
    }
    
    private func createModelInfo(from model: MLModel, identifier: String, url: URL) -> ObjectDetectionResult.ModelInfo {
        let modelDescription = model.modelDescription
        
        // Try to determine input size from model description
        var inputSize: CGSize?
        if let inputDescription = modelDescription.inputDescriptionsByName.values.first,
           let imageConstraint = inputDescription.imageConstraint {
            inputSize = CGSize(width: imageConstraint.pixelsWide, height: imageConstraint.pixelsHigh)
        }
        
        // Try to extract class labels
        var outputClasses: [String] = []
        if let classLabels = modelDescription.classLabels as? [String] {
            outputClasses = classLabels
        }
        
        return ObjectDetectionResult.ModelInfo(
            identifier: identifier,
            name: modelDescription.metadata[.name] as? String ?? identifier,
            version: modelDescription.metadata[.versionString] as? String,
            description: modelDescription.metadata[.description] as? String,
            inputSize: inputSize,
            outputClasses: outputClasses,
            computeUnits: configuration.preferredComputeUnits.rawValue,
            modelType: .custom
        )
    }
    
    private func createDefaultModelInfo() -> ObjectDetectionResult.ModelInfo {
        return ObjectDetectionResult.ModelInfo(
            identifier: "default",
            name: "Vision Object Detection",
            version: "1.0",
            description: "Built-in Vision framework object detection",
            outputClasses: ["rectangle", "object"],
            computeUnits: configuration.preferredComputeUnits.rawValue,
            modelType: .vision
        )
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalDetections)) + 1
        let totalDetections = metrics.totalDetections + 1
        let newCacheHitRate = cacheHits / Double(totalDetections)
        
        metrics = ObjectDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: metrics.successfulDetections + 1,
            failedDetections: metrics.failedDetections,
            averageProcessingTime: metrics.averageProcessingTime,
            detectionsByModel: metrics.detectionsByModel,
            detectionsByObjectType: metrics.detectionsByObjectType,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageObjectsPerImage: metrics.averageObjectsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: metrics.trackingStats,
            modelPerformanceStats: metrics.modelPerformanceStats
        )
    }
    
    private func updateSuccessMetrics(_ result: ObjectDetectionResult) async {
        let totalDetections = metrics.totalDetections + 1
        let successfulDetections = metrics.successfulDetections + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalDetections)) + result.processingTime) / Double(totalDetections)
        
        var detectionsByModel = metrics.detectionsByModel
        detectionsByModel[result.modelInfo.identifier, default: 0] += 1
        
        var detectionsByObjectType = metrics.detectionsByObjectType
        for object in result.detectedObjects {
            detectionsByObjectType[object.label, default: 0] += 1
        }
        
        let newAverageConfidence = result.detectedObjects.isEmpty ? metrics.averageConfidence :
            ((metrics.averageConfidence * Double(metrics.successfulDetections)) + Double(result.averageConfidence)) / Double(successfulDetections)
        
        let newAverageObjectsPerImage = ((metrics.averageObjectsPerImage * Double(metrics.successfulDetections)) + Double(result.objectCount)) / Double(successfulDetections)
        
        // Update tracking stats
        var trackingStats = metrics.trackingStats
        let trackedCount = result.detectedObjects.filter { $0.trackingState == .tracked }.count
        if trackedCount > 0 {
            trackingStats = ObjectDetectionMetrics.TrackingStats(
                totalTrackedObjects: trackingStats.totalTrackedObjects + trackedCount,
                activeTrackings: self.trackedObjects.count,
                lostTrackings: trackingStats.lostTrackings,
                mergedTrackings: trackingStats.mergedTrackings,
                averageTrackingDuration: trackingStats.averageTrackingDuration
            )
        }
        
        // Update model performance stats
        var modelPerformanceStats = metrics.modelPerformanceStats
        let modelId = result.modelInfo.identifier
        if let existingStats = modelPerformanceStats[modelId] {
            let newUsageCount = existingStats.usageCount + 1
            let newAvgTime = ((existingStats.averageProcessingTime * Double(existingStats.usageCount)) + result.processingTime) / Double(newUsageCount)
            let newSuccessRate = ((existingStats.successRate * Double(existingStats.usageCount)) + 1.0) / Double(newUsageCount)
            let newAvgObjectCount = ((existingStats.averageObjectCount * Double(existingStats.usageCount)) + Double(result.objectCount)) / Double(newUsageCount)
            let newAvgConfidence = ((existingStats.averageConfidence * Double(existingStats.usageCount)) + Double(result.averageConfidence)) / Double(newUsageCount)
            
            modelPerformanceStats[modelId] = ObjectDetectionMetrics.ModelPerformanceStats(
                usageCount: newUsageCount,
                averageProcessingTime: newAvgTime,
                successRate: newSuccessRate,
                averageObjectCount: newAvgObjectCount,
                averageConfidence: newAvgConfidence
            )
        } else {
            modelPerformanceStats[modelId] = ObjectDetectionMetrics.ModelPerformanceStats(
                usageCount: 1,
                averageProcessingTime: result.processingTime,
                successRate: 1.0,
                averageObjectCount: Double(result.objectCount),
                averageConfidence: Double(result.averageConfidence)
            )
        }
        
        metrics = ObjectDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: successfulDetections,
            failedDetections: metrics.failedDetections,
            averageProcessingTime: newAverageProcessingTime,
            detectionsByModel: detectionsByModel,
            detectionsByObjectType: detectionsByObjectType,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            averageObjectsPerImage: newAverageObjectsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: trackingStats,
            modelPerformanceStats: modelPerformanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: ObjectDetectionResult) async {
        let totalDetections = metrics.totalDetections + 1
        let failedDetections = metrics.failedDetections + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        // Update model performance stats for failures
        var modelPerformanceStats = metrics.modelPerformanceStats
        let modelId = result.modelInfo.identifier
        if let existingStats = modelPerformanceStats[modelId] {
            let newUsageCount = existingStats.usageCount + 1
            let newAvgTime = ((existingStats.averageProcessingTime * Double(existingStats.usageCount)) + result.processingTime) / Double(newUsageCount)
            let newSuccessRate = (existingStats.successRate * Double(existingStats.usageCount)) / Double(newUsageCount)
            
            modelPerformanceStats[modelId] = ObjectDetectionMetrics.ModelPerformanceStats(
                usageCount: newUsageCount,
                averageProcessingTime: newAvgTime,
                successRate: newSuccessRate,
                averageObjectCount: existingStats.averageObjectCount,
                averageConfidence: existingStats.averageConfidence
            )
        } else {
            modelPerformanceStats[modelId] = ObjectDetectionMetrics.ModelPerformanceStats(
                usageCount: 1,
                averageProcessingTime: result.processingTime,
                successRate: 0.0,
                averageObjectCount: 0.0,
                averageConfidence: 0.0
            )
        }
        
        metrics = ObjectDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: metrics.successfulDetections,
            failedDetections: failedDetections,
            averageProcessingTime: metrics.averageProcessingTime,
            detectionsByModel: metrics.detectionsByModel,
            detectionsByObjectType: metrics.detectionsByObjectType,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageObjectsPerImage: metrics.averageObjectsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: metrics.trackingStats,
            modelPerformanceStats: modelPerformanceStats
        )
    }
    
    private func logModel(_ model: ObjectDetectionResult.ModelInfo, action: String) async {
        let typeIcon = switch model.modelType {
        case .yolo: "🎯"
        case .ssd: "🔍"
        case .rcnn: "📊"
        case .vision: "👁️"
        case .custom: "🛠️"
        }
        
        print("[ObjectDetection] \(typeIcon) \(action): \(model.name) (\(model.identifier))")
    }
    
    private func logDetection(_ result: ObjectDetectionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let objectCount = result.objectCount
        let avgConfidence = result.averageConfidence
        
        print("[ObjectDetection] \(statusIcon) Detection: \(objectCount) objects, avg confidence: \(String(format: "%.3f", avgConfidence)) (\(timeStr)s)")
        
        if let error = result.error {
            print("[ObjectDetection] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Object Detection Capability Implementation

/// Object Detection capability providing comprehensive object detection and tracking
@available(iOS 13.0, macOS 10.15, *)
public actor ObjectDetectionCapability: DomainCapability {
    public typealias ConfigurationType = ObjectDetectionCapabilityConfiguration
    public typealias ResourceType = ObjectDetectionCapabilityResource
    
    private var _configuration: ObjectDetectionCapabilityConfiguration
    private var _resources: ObjectDetectionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "object-detection-capability" }
    
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
    
    public var configuration: ObjectDetectionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ObjectDetectionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ObjectDetectionCapabilityConfiguration = ObjectDetectionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ObjectDetectionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ObjectDetectionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Object Detection configuration")
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
        // Object detection is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Object detection doesn't require special permissions beyond camera if using live camera
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Object Detection Operations
    
    /// Detect objects in image
    public func detectObjects(_ request: ObjectDetectionRequest) async throws -> ObjectDetectionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return try await _resources.detectObjects(request)
    }
    
    /// Detect objects in multiple images
    public func detectObjectsInBatch(_ requests: [ObjectDetectionRequest]) async throws -> [ObjectDetectionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return try await _resources.detectObjectsInBatch(requests)
    }
    
    /// Cancel detection
    public func cancelDetection(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        await _resources.cancelDetection(requestId)
    }
    
    /// Load custom model
    public func loadModel(from url: URL, identifier: String) async throws -> ObjectDetectionResult.ModelInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return try await _resources.loadModel(from: url, identifier: identifier)
    }
    
    /// Unload model
    public func unloadModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        await _resources.unloadModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<ObjectDetectionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [ObjectDetectionResult.ModelInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active detections
    public func getActiveDetections() async throws -> [ObjectDetectionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.getActiveDetections()
    }
    
    /// Get detection history
    public func getDetectionHistory(since: Date? = nil) async throws -> [ObjectDetectionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.getDetectionHistory(since: since)
    }
    
    /// Get tracked objects
    public func getTrackedObjects() async throws -> [UUID: String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.getTrackedObjects()
    }
    
    /// Clear tracking
    public func clearTracking() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        await _resources.clearTracking()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ObjectDetectionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Object Detection capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick detect objects with default options
    public func quickDetect(_ image: CIImage, confidence: Float = 0.3, maxObjects: Int = 20) async throws -> [ObjectDetectionResult.DetectedObject] {
        let options = ObjectDetectionRequest.DetectionOptions(
            minimumConfidence: confidence,
            maximumObjects: maxObjects
        )
        
        let request = ObjectDetectionRequest(image: image, options: options)
        let result = try await detectObjects(request)
        
        return result.detectedObjects
    }
    
    /// Detect objects with tracking
    public func detectWithTracking(_ image: CIImage, trackingId: UUID? = nil, confidence: Float = 0.3) async throws -> [ObjectDetectionResult.DetectedObject] {
        let options = ObjectDetectionRequest.DetectionOptions(
            minimumConfidence: confidence,
            enableTracking: true,
            trackingId: trackingId
        )
        
        let request = ObjectDetectionRequest(image: image, options: options)
        let result = try await detectObjects(request)
        
        return result.detectedObjects
    }
    
    /// Check if detection is active
    public func hasActiveDetections() async throws -> Bool {
        let activeDetections = try await getActiveDetections()
        return !activeDetections.isEmpty
    }
    
    /// Get model count
    public func getModelCount() async throws -> Int {
        let models = try await getLoadedModels()
        return models.count
    }
    
    /// Get tracking count
    public func getTrackingCount() async throws -> Int {
        let trackedObjects = try await getTrackedObjects()
        return trackedObjects.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Object Detection specific errors
public enum ObjectDetectionError: Error, LocalizedError {
    case objectDetectionDisabled
    case customModelsDisabled
    case batchDetectionDisabled
    case modelLoadFailed(String, String)
    case modelNotLoaded(String)
    case detectionError(String)
    case invalidImage
    case noResults
    case detectionQueued(UUID)
    case detectionTimeout(UUID)
    case trackingError(String)
    case unsupportedImageFormat
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .objectDetectionDisabled:
            return "Object detection is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .batchDetectionDisabled:
            return "Batch detection is disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .modelNotLoaded(let identifier):
            return "Model not loaded: \(identifier)"
        case .detectionError(let reason):
            return "Detection failed: \(reason)"
        case .invalidImage:
            return "Invalid image provided"
        case .noResults:
            return "No detection results found"
        case .detectionQueued(let id):
            return "Detection queued: \(id)"
        case .detectionTimeout(let id):
            return "Detection timeout: \(id)"
        case .trackingError(let reason):
            return "Tracking error: \(reason)"
        case .unsupportedImageFormat:
            return "Unsupported image format"
        case .configurationError(let reason):
            return "Object detection configuration error: \(reason)"
        }
    }
}

// MARK: - CGRect Extension

extension CGRect {
    var area: CGFloat {
        width * height
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}