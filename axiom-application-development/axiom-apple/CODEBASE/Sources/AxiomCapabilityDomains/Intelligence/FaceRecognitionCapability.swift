import Foundation
import Vision
import CoreImage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Face Recognition Capability Configuration

/// Configuration for Face Recognition capability
public struct FaceRecognitionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableFaceRecognition: Bool
    public let enableFaceDetection: Bool
    public let enableFaceLandmarks: Bool
    public let enableFaceQuality: Bool
    public let enableFaceTracking: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentRecognitions: Int
    public let recognitionTimeout: TimeInterval
    public let minimumFaceSize: Float
    public let maximumFaces: Int
    public let qualityThreshold: Float
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let preferredComputeUnits: ComputeUnits
    
    public enum ComputeUnits: String, Codable, CaseIterable {
        case cpuOnly = "cpu-only"
        case cpuAndGPU = "cpu-and-gpu"
        case cpuAndNeuralEngine = "cpu-and-neural-engine"
        case all = "all"
    }
    
    public init(
        enableFaceRecognition: Bool = true,
        enableFaceDetection: Bool = true,
        enableFaceLandmarks: Bool = true,
        enableFaceQuality: Bool = true,
        enableFaceTracking: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentRecognitions: Int = 5,
        recognitionTimeout: TimeInterval = 30.0,
        minimumFaceSize: Float = 0.05,
        maximumFaces: Int = 20,
        qualityThreshold: Float = 0.3,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 100,
        enablePerformanceOptimization: Bool = true,
        preferredComputeUnits: ComputeUnits = .all
    ) {
        self.enableFaceRecognition = enableFaceRecognition
        self.enableFaceDetection = enableFaceDetection
        self.enableFaceLandmarks = enableFaceLandmarks
        self.enableFaceQuality = enableFaceQuality
        self.enableFaceTracking = enableFaceTracking
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentRecognitions = maxConcurrentRecognitions
        self.recognitionTimeout = recognitionTimeout
        self.minimumFaceSize = minimumFaceSize
        self.maximumFaces = maximumFaces
        self.qualityThreshold = qualityThreshold
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.preferredComputeUnits = preferredComputeUnits
    }
    
    public var isValid: Bool {
        maxConcurrentRecognitions > 0 &&
        recognitionTimeout > 0 &&
        minimumFaceSize > 0.0 && minimumFaceSize <= 1.0 &&
        maximumFaces > 0 &&
        qualityThreshold >= 0.0 && qualityThreshold <= 1.0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: FaceRecognitionCapabilityConfiguration) -> FaceRecognitionCapabilityConfiguration {
        FaceRecognitionCapabilityConfiguration(
            enableFaceRecognition: other.enableFaceRecognition,
            enableFaceDetection: other.enableFaceDetection,
            enableFaceLandmarks: other.enableFaceLandmarks,
            enableFaceQuality: other.enableFaceQuality,
            enableFaceTracking: other.enableFaceTracking,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentRecognitions: other.maxConcurrentRecognitions,
            recognitionTimeout: other.recognitionTimeout,
            minimumFaceSize: other.minimumFaceSize,
            maximumFaces: other.maximumFaces,
            qualityThreshold: other.qualityThreshold,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            preferredComputeUnits: other.preferredComputeUnits
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> FaceRecognitionCapabilityConfiguration {
        var adjustedTimeout = recognitionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRecognitions = maxConcurrentRecognitions
        var adjustedCacheSize = cacheSize
        var adjustedComputeUnits = preferredComputeUnits
        var adjustedMaxFaces = maximumFaces
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(recognitionTimeout, 15.0)
            adjustedConcurrentRecognitions = min(maxConcurrentRecognitions, 2)
            adjustedCacheSize = min(cacheSize, 20)
            adjustedComputeUnits = .cpuOnly
            adjustedMaxFaces = min(maximumFaces, 5)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return FaceRecognitionCapabilityConfiguration(
            enableFaceRecognition: enableFaceRecognition,
            enableFaceDetection: enableFaceDetection,
            enableFaceLandmarks: enableFaceLandmarks,
            enableFaceQuality: enableFaceQuality,
            enableFaceTracking: enableFaceTracking,
            enableCustomModels: enableCustomModels,
            maxConcurrentRecognitions: adjustedConcurrentRecognitions,
            recognitionTimeout: adjustedTimeout,
            minimumFaceSize: minimumFaceSize,
            maximumFaces: adjustedMaxFaces,
            qualityThreshold: qualityThreshold,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            preferredComputeUnits: adjustedComputeUnits
        )
    }
}

// MARK: - Face Recognition Types

/// Face recognition request
public struct FaceRecognitionRequest: Sendable, Identifiable {
    public let id: UUID
    public let image: CIImage
    public let options: RecognitionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct RecognitionOptions: Sendable {
        public let enableDetection: Bool
        public let enableLandmarks: Bool
        public let enableQualityAssessment: Bool
        public let enableTracking: Bool
        public let minimumFaceSize: Float
        public let maximumFaces: Int
        public let qualityThreshold: Float
        public let trackingId: UUID?
        public let customModelId: String?
        public let regionOfInterest: CGRect?
        
        public init(
            enableDetection: Bool = true,
            enableLandmarks: Bool = true,
            enableQualityAssessment: Bool = true,
            enableTracking: Bool = false,
            minimumFaceSize: Float = 0.05,
            maximumFaces: Int = 20,
            qualityThreshold: Float = 0.3,
            trackingId: UUID? = nil,
            customModelId: String? = nil,
            regionOfInterest: CGRect? = nil
        ) {
            self.enableDetection = enableDetection
            self.enableLandmarks = enableLandmarks
            self.enableQualityAssessment = enableQualityAssessment
            self.enableTracking = enableTracking
            self.minimumFaceSize = minimumFaceSize
            self.maximumFaces = maximumFaces
            self.qualityThreshold = qualityThreshold
            self.trackingId = trackingId
            self.customModelId = customModelId
            self.regionOfInterest = regionOfInterest
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
        options: RecognitionOptions = RecognitionOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.image = image
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Face recognition result
public struct FaceRecognitionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let faces: [Face]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: FaceRecognitionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct Face: Sendable, Identifiable {
        public let id: UUID
        public let boundingBox: CGRect
        public let confidence: Float
        public let landmarks: FaceLandmarks?
        public let quality: FaceQuality?
        public let pose: FacePose?
        public let expressions: FaceExpressions?
        public let age: AgeEstimate?
        public let gender: GenderEstimate?
        public let trackingId: UUID?
        public let identity: FaceIdentity?
        public let features: FaceFeatures?
        
        public struct FaceLandmarks: Sendable {
            public let leftEye: CGPoint?
            public let rightEye: CGPoint?
            public let nose: CGPoint?
            public let mouth: CGPoint?
            public let leftEyebrow: CGPoint?
            public let rightEyebrow: CGPoint?
            public let leftCheek: CGPoint?
            public let rightCheek: CGPoint?
            public let chin: CGPoint?
            public let forehead: CGPoint?
            public let allPoints: [CGPoint]
            
            public init(leftEye: CGPoint? = nil, rightEye: CGPoint? = nil, nose: CGPoint? = nil, mouth: CGPoint? = nil, leftEyebrow: CGPoint? = nil, rightEyebrow: CGPoint? = nil, leftCheek: CGPoint? = nil, rightCheek: CGPoint? = nil, chin: CGPoint? = nil, forehead: CGPoint? = nil, allPoints: [CGPoint] = []) {
                self.leftEye = leftEye
                self.rightEye = rightEye
                self.nose = nose
                self.mouth = mouth
                self.leftEyebrow = leftEyebrow
                self.rightEyebrow = rightEyebrow
                self.leftCheek = leftCheek
                self.rightCheek = rightCheek
                self.chin = chin
                self.forehead = forehead
                self.allPoints = allPoints
            }
        }
        
        public struct FaceQuality: Sendable {
            public let overall: Float
            public let sharpness: Float
            public let brightness: Float
            public let contrast: Float
            public let symmetry: Float
            public let headPose: Float
            public let eyeOpenness: Float
            public let isUsableForRecognition: Bool
            
            public init(overall: Float, sharpness: Float, brightness: Float, contrast: Float, symmetry: Float, headPose: Float, eyeOpenness: Float, isUsableForRecognition: Bool) {
                self.overall = overall
                self.sharpness = sharpness
                self.brightness = brightness
                self.contrast = contrast
                self.symmetry = symmetry
                self.headPose = headPose
                self.eyeOpenness = eyeOpenness
                self.isUsableForRecognition = isUsableForRecognition
            }
        }
        
        public struct FacePose: Sendable {
            public let roll: Float
            public let yaw: Float
            public let pitch: Float
            
            public init(roll: Float, yaw: Float, pitch: Float) {
                self.roll = roll
                self.yaw = yaw
                self.pitch = pitch
            }
        }
        
        public struct FaceExpressions: Sendable {
            public let neutral: Float
            public let happiness: Float
            public let sadness: Float
            public let anger: Float
            public let fear: Float
            public let surprise: Float
            public let disgust: Float
            public let contempt: Float
            
            public init(neutral: Float = 0, happiness: Float = 0, sadness: Float = 0, anger: Float = 0, fear: Float = 0, surprise: Float = 0, disgust: Float = 0, contempt: Float = 0) {
                self.neutral = neutral
                self.happiness = happiness
                self.sadness = sadness
                self.anger = anger
                self.fear = fear
                self.surprise = surprise
                self.disgust = disgust
                self.contempt = contempt
            }
        }
        
        public struct AgeEstimate: Sendable {
            public let estimatedAge: Int
            public let confidence: Float
            public let ageRange: ClosedRange<Int>
            
            public init(estimatedAge: Int, confidence: Float, ageRange: ClosedRange<Int>) {
                self.estimatedAge = estimatedAge
                self.confidence = confidence
                self.ageRange = ageRange
            }
        }
        
        public struct GenderEstimate: Sendable {
            public let gender: Gender
            public let confidence: Float
            
            public enum Gender: String, Sendable, CaseIterable {
                case male = "male"
                case female = "female"
                case unknown = "unknown"
            }
            
            public init(gender: Gender, confidence: Float) {
                self.gender = gender
                self.confidence = confidence
            }
        }
        
        public struct FaceIdentity: Sendable {
            public let identityId: UUID?
            public let identityName: String?
            public let confidence: Float
            public let similarity: Float
            public let isNewPerson: Bool
            
            public init(identityId: UUID? = nil, identityName: String? = nil, confidence: Float, similarity: Float, isNewPerson: Bool) {
                self.identityId = identityId
                self.identityName = identityName
                self.confidence = confidence
                self.similarity = similarity
                self.isNewPerson = isNewPerson
            }
        }
        
        public struct FaceFeatures: Sendable {
            public let faceEncoding: [Float]
            public let descriptorVersion: String
            public let extractionMethod: String
            
            public init(faceEncoding: [Float], descriptorVersion: String, extractionMethod: String) {
                self.faceEncoding = faceEncoding
                self.descriptorVersion = descriptorVersion
                self.extractionMethod = extractionMethod
            }
        }
        
        public init(
            boundingBox: CGRect,
            confidence: Float,
            landmarks: FaceLandmarks? = nil,
            quality: FaceQuality? = nil,
            pose: FacePose? = nil,
            expressions: FaceExpressions? = nil,
            age: AgeEstimate? = nil,
            gender: GenderEstimate? = nil,
            trackingId: UUID? = nil,
            identity: FaceIdentity? = nil,
            features: FaceFeatures? = nil
        ) {
            self.id = UUID()
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.landmarks = landmarks
            self.quality = quality
            self.pose = pose
            self.expressions = expressions
            self.age = age
            self.gender = gender
            self.trackingId = trackingId
            self.identity = identity
            self.features = features
        }
    }
    
    public init(
        requestId: UUID,
        faces: [Face],
        processingTime: TimeInterval,
        success: Bool,
        error: FaceRecognitionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.faces = faces
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var faceCount: Int {
        faces.count
    }
    
    public var averageConfidence: Float {
        guard !faces.isEmpty else { return 0.0 }
        return faces.reduce(0) { $0 + $1.confidence } / Float(faces.count)
    }
    
    public var highestConfidenceFace: Face? {
        faces.max(by: { $0.confidence < $1.confidence })
    }
    
    public func faces(withMinimumConfidence confidence: Float) -> [Face] {
        faces.filter { $0.confidence >= confidence }
    }
}

/// Face recognition metrics
public struct FaceRecognitionMetrics: Sendable {
    public let totalRecognitions: Int
    public let successfulRecognitions: Int
    public let failedRecognitions: Int
    public let averageProcessingTime: TimeInterval
    public let averageFacesPerImage: Double
    public let averageConfidence: Double
    public let recognitionsByQuality: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let throughputPerSecond: Double
    public let trackingStats: TrackingStats
    
    public struct TrackingStats: Sendable {
        public let totalTrackedFaces: Int
        public let activeTrackings: Int
        public let lostTrackings: Int
        public let averageTrackingDuration: TimeInterval
        
        public init(totalTrackedFaces: Int = 0, activeTrackings: Int = 0, lostTrackings: Int = 0, averageTrackingDuration: TimeInterval = 0) {
            self.totalTrackedFaces = totalTrackedFaces
            self.activeTrackings = activeTrackings
            self.lostTrackings = lostTrackings
            self.averageTrackingDuration = averageTrackingDuration
        }
    }
    
    public init(
        totalRecognitions: Int = 0,
        successfulRecognitions: Int = 0,
        failedRecognitions: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        averageFacesPerImage: Double = 0,
        averageConfidence: Double = 0,
        recognitionsByQuality: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        throughputPerSecond: Double = 0,
        trackingStats: TrackingStats = TrackingStats()
    ) {
        self.totalRecognitions = totalRecognitions
        self.successfulRecognitions = successfulRecognitions
        self.failedRecognitions = failedRecognitions
        self.averageProcessingTime = averageProcessingTime
        self.averageFacesPerImage = averageFacesPerImage
        self.averageConfidence = averageConfidence
        self.recognitionsByQuality = recognitionsByQuality
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRecognitions) / averageProcessingTime : 0
        self.trackingStats = trackingStats
    }
    
    public var successRate: Double {
        totalRecognitions > 0 ? Double(successfulRecognitions) / Double(totalRecognitions) : 0
    }
}

// MARK: - Face Recognition Resource

/// Face recognition resource management
@available(iOS 13.0, macOS 10.15, *)
public actor FaceRecognitionCapabilityResource: AxiomCapabilityResource {
    private let configuration: FaceRecognitionCapabilityConfiguration
    private var activeRecognitions: [UUID: FaceRecognitionRequest] = [:]
    private var recognitionQueue: [FaceRecognitionRequest] = [:]
    private var recognitionHistory: [FaceRecognitionResult] = [:]
    private var resultCache: [String: FaceRecognitionResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var trackedFaces: [UUID: TrackedFace] = [:]
    private var metrics: FaceRecognitionMetrics = FaceRecognitionMetrics()
    private var resultStreamContinuation: AsyncStream<FaceRecognitionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    private struct TrackedFace {
        let trackingId: UUID
        var lastSeen: Date
        var positions: [CGPoint]
        var confidences: [Float]
        var identity: FaceRecognitionResult.Face.FaceIdentity?
        
        init(trackingId: UUID, position: CGPoint, confidence: Float) {
            self.trackingId = trackingId
            self.lastSeen = Date()
            self.positions = [position]
            self.confidences = [confidence]
            self.identity = nil
        }
    }
    
    public init(configuration: FaceRecognitionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 250_000_000, // 250MB for face recognition
            cpu: 4.5, // High CPU usage for face processing
            bandwidth: 0,
            storage: 100_000_000 // 100MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let recognitionMemory = activeRecognitions.count * 30_000_000 // ~30MB per active recognition
            let cacheMemory = resultCache.count * 150_000 // ~150KB per cached result
            let modelMemory = customModels.count * 80_000_000 // ~80MB per loaded model
            let trackingMemory = trackedFaces.count * 15_000 // ~15KB per tracked face
            let historyMemory = recognitionHistory.count * 20_000
            
            return ResourceUsage(
                memory: recognitionMemory + cacheMemory + modelMemory + trackingMemory + historyMemory + 25_000_000,
                cpu: activeRecognitions.isEmpty ? 0.3 : 4.0,
                bandwidth: 0,
                storage: resultCache.count * 75_000 + customModels.count * 150_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Face recognition is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableFaceRecognition
        }
        return false
    }
    
    public func release() async {
        activeRecognitions.removeAll()
        recognitionQueue.removeAll()
        recognitionHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        trackedFaces.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = FaceRecognitionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[FaceRecognition] 🚀 Face Recognition capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: FaceRecognitionCapabilityConfiguration) async throws {
        if configuration.enableFaceTracking {
            await updateTracking()
        }
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<FaceRecognitionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw FaceRecognitionError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[FaceRecognition] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw FaceRecognitionError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[FaceRecognition] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Face Recognition
    
    public func recognizeFaces(_ request: FaceRecognitionRequest) async throws -> FaceRecognitionResult {
        guard configuration.enableFaceRecognition else {
            throw FaceRecognitionError.faceRecognitionDisabled
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
        if activeRecognitions.count >= configuration.maxConcurrentRecognitions {
            recognitionQueue.append(request)
            throw FaceRecognitionError.recognitionQueued(request.id)
        }
        
        let startTime = Date()
        activeRecognitions[request.id] = request
        
        do {
            // Perform face recognition
            let faces = try await performFaceRecognition(image: request.image, options: request.options)
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = FaceRecognitionResult(
                requestId: request.id,
                faces: faces,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeRecognitions.removeValue(forKey: request.id)
            recognitionHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logRecognition(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processRecognitionQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = FaceRecognitionResult(
                requestId: request.id,
                faces: [],
                processingTime: processingTime,
                success: false,
                error: error as? FaceRecognitionError ?? FaceRecognitionError.recognitionError(error.localizedDescription)
            )
            
            activeRecognitions.removeValue(forKey: request.id)
            recognitionHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logRecognition(result)
            }
            
            throw error
        }
    }
    
    public func cancelRecognition(_ requestId: UUID) async {
        activeRecognitions.removeValue(forKey: requestId)
        recognitionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[FaceRecognition] 🚫 Cancelled recognition: \(requestId)")
        }
    }
    
    public func getActiveRecognitions() async -> [FaceRecognitionRequest] {
        return Array(activeRecognitions.values)
    }
    
    public func getRecognitionHistory(since: Date? = nil) async -> [FaceRecognitionResult] {
        if let since = since {
            return recognitionHistory.filter { $0.timestamp >= since }
        }
        return recognitionHistory
    }
    
    // MARK: - Face Tracking
    
    public func getTrackedFaces() async -> [UUID: String] {
        return trackedFaces.mapValues { tracked in
            tracked.identity?.identityName ?? "Unknown"
        }
    }
    
    public func clearTracking() async {
        trackedFaces.removeAll()
        
        if configuration.enableLogging {
            print("[FaceRecognition] 🧹 Cleared all face tracking data")
        }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> FaceRecognitionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = FaceRecognitionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[FaceRecognition] ⚡ Performance optimization enabled")
        }
    }
    
    private func updateTracking() async {
        // Clean up old tracking data
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        let staleTrackings = trackedFaces.filter { $0.value.lastSeen < cutoffTime }
        
        for (trackingId, _) in staleTrackings {
            trackedFaces.removeValue(forKey: trackingId)
        }
        
        if configuration.enableLogging && !staleTrackings.isEmpty {
            print("[FaceRecognition] 🧹 Cleaned up \(staleTrackings.count) stale face trackings")
        }
    }
    
    private func performFaceRecognition(image: CIImage, options: FaceRecognitionRequest.RecognitionOptions) async throws -> [FaceRecognitionResult.Face] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            var allRequests: [VNRequest] = []
            
            // Face detection request
            let faceDetectionRequest = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let faces = observations.compactMap { observation -> FaceRecognitionResult.Face? in
                    guard observation.confidence >= options.qualityThreshold else { return nil }
                    
                    // Create basic face with bounding box and confidence
                    var face = FaceRecognitionResult.Face(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence
                    )
                    
                    // Add pose information if available
                    if let roll = observation.roll, let yaw = observation.yaw, let pitch = observation.pitch {
                        let pose = FaceRecognitionResult.Face.FacePose(
                            roll: roll.floatValue,
                            yaw: yaw.floatValue,
                            pitch: pitch.floatValue
                        )
                        face = FaceRecognitionResult.Face(
                            boundingBox: face.boundingBox,
                            confidence: face.confidence,
                            pose: pose
                        )
                    }
                    
                    // Add landmarks if requested and available
                    if options.enableLandmarks {
                        do {
                            let landmarksRequest = VNDetectFaceLandmarksRequest()
                            landmarksRequest.inputFaceObservations = [observation]
                            try requestHandler.perform([landmarksRequest])
                            
                            if let landmarkResults = landmarksRequest.results?.first as? VNFaceObservation,
                               let landmarks = landmarkResults.landmarks {
                                
                                let faceLandmarks = FaceRecognitionResult.Face.FaceLandmarks(
                                    leftEye: landmarks.leftEye?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
                                    rightEye: landmarks.rightEye?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
                                    nose: landmarks.nose?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
                                    mouth: landmarks.outerLips?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
                                    allPoints: landmarks.allPoints?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? []
                                )
                                
                                face = FaceRecognitionResult.Face(
                                    boundingBox: face.boundingBox,
                                    confidence: face.confidence,
                                    landmarks: faceLandmarks,
                                    pose: face.pose
                                )
                            }
                        } catch {
                            // Continue without landmarks if extraction fails
                        }
                    }
                    
                    // Add quality assessment if requested
                    if options.enableQualityAssessment {
                        let quality = self.assessFaceQuality(observation: observation, image: image)
                        face = FaceRecognitionResult.Face(
                            boundingBox: face.boundingBox,
                            confidence: face.confidence,
                            landmarks: face.landmarks,
                            quality: quality,
                            pose: face.pose
                        )
                    }
                    
                    // Add tracking if enabled
                    if options.enableTracking {
                        let trackedFace = self.applyTracking(to: face, trackingId: options.trackingId)
                        face = trackedFace
                    }
                    
                    return face
                }
                
                continuation.resume(returning: faces)
            }
            
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            
            allRequests.append(faceDetectionRequest)
            
            do {
                try requestHandler.perform(allRequests)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func assessFaceQuality(observation: VNFaceObservation, image: CIImage) -> FaceRecognitionResult.Face.FaceQuality {
        // Basic quality assessment
        let boundingBox = observation.boundingBox
        let faceSize = min(boundingBox.width, boundingBox.height)
        
        // Calculate basic quality metrics
        let sharpness: Float = faceSize > 0.1 ? 0.8 : 0.4 // Based on face size
        let brightness: Float = 0.7 // Simplified - would need actual luminance analysis
        let contrast: Float = 0.6 // Simplified - would need actual contrast analysis
        let symmetry: Float = 0.75 // Simplified - would need landmark analysis
        let headPose: Float = abs(observation.yaw?.floatValue ?? 0) < 0.3 ? 0.9 : 0.5
        let eyeOpenness: Float = 0.8 // Simplified - would need eye analysis
        
        let overall = (sharpness + brightness + contrast + symmetry + headPose + eyeOpenness) / 6.0
        let isUsable = overall > configuration.qualityThreshold
        
        return FaceRecognitionResult.Face.FaceQuality(
            overall: overall,
            sharpness: sharpness,
            brightness: brightness,
            contrast: contrast,
            symmetry: symmetry,
            headPose: headPose,
            eyeOpenness: eyeOpenness,
            isUsableForRecognition: isUsable
        )
    }
    
    private func applyTracking(to face: FaceRecognitionResult.Face, trackingId: UUID?) -> FaceRecognitionResult.Face {
        let center = CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY)
        
        // Try to match with existing tracked faces
        var bestMatch: (UUID, Float)? = nil
        
        for (id, trackedState) in trackedFaces {
            let lastPosition = trackedState.positions.last ?? CGPoint.zero
            let distance = sqrt(pow(center.x - lastPosition.x, 2) + pow(center.y - lastPosition.y, 2))
            let maxDistance: CGFloat = 0.1 // Maximum tracking distance in normalized coordinates
            
            if distance < maxDistance {
                let similarity = 1.0 - Float(distance / maxDistance)
                if bestMatch == nil || similarity > bestMatch!.1 {
                    bestMatch = (id, similarity)
                }
            }
        }
        
        if let (existingTrackingId, _) = bestMatch {
            // Update existing tracking
            var updatedState = trackedFaces[existingTrackingId]!
            updatedState.lastSeen = Date()
            updatedState.positions.append(center)
            updatedState.confidences.append(face.confidence)
            
            // Keep only recent positions
            if updatedState.positions.count > 10 {
                updatedState.positions = Array(updatedState.positions.suffix(10))
                updatedState.confidences = Array(updatedState.confidences.suffix(10))
            }
            
            trackedFaces[existingTrackingId] = updatedState
            
            return FaceRecognitionResult.Face(
                boundingBox: face.boundingBox,
                confidence: face.confidence,
                landmarks: face.landmarks,
                quality: face.quality,
                pose: face.pose,
                expressions: face.expressions,
                age: face.age,
                gender: face.gender,
                trackingId: existingTrackingId,
                identity: face.identity,
                features: face.features
            )
        } else {
            // Create new tracking
            let newTrackingId = trackingId ?? UUID()
            let newTrackedState = TrackedFace(
                trackingId: newTrackingId,
                position: center,
                confidence: face.confidence
            )
            
            trackedFaces[newTrackingId] = newTrackedState
            
            return FaceRecognitionResult.Face(
                boundingBox: face.boundingBox,
                confidence: face.confidence,
                landmarks: face.landmarks,
                quality: face.quality,
                pose: face.pose,
                expressions: face.expressions,
                age: face.age,
                gender: face.gender,
                trackingId: newTrackingId,
                identity: face.identity,
                features: face.features
            )
        }
    }
    
    private func processRecognitionQueue() async {
        guard !isProcessingQueue && !recognitionQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        recognitionQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !recognitionQueue.isEmpty && activeRecognitions.count < configuration.maxConcurrentRecognitions {
            let request = recognitionQueue.removeFirst()
            
            do {
                _ = try await recognizeFaces(request)
            } catch {
                if configuration.enableLogging {
                    print("[FaceRecognition] ⚠️ Queued recognition failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: FaceRecognitionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: FaceRecognitionRequest) -> String {
        // Generate a cache key based on image hash and request parameters
        let imageHash = request.image.extent.hashValue
        let enableDetection = request.options.enableDetection
        let enableLandmarks = request.options.enableLandmarks
        let enableQuality = request.options.enableQualityAssessment
        let minimumFaceSize = Int(request.options.minimumFaceSize * 1000)
        let roi = request.options.regionOfInterest?.debugDescription ?? "full"
        return "\(imageHash)_\(enableDetection)_\(enableLandmarks)_\(enableQuality)_\(minimumFaceSize)_\(roi)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRecognitions)) + 1
        let totalRecognitions = metrics.totalRecognitions + 1
        let newCacheHitRate = cacheHits / Double(totalRecognitions)
        
        metrics = FaceRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions + 1,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            averageFacesPerImage: metrics.averageFacesPerImage,
            averageConfidence: metrics.averageConfidence,
            recognitionsByQuality: metrics.recognitionsByQuality,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: metrics.trackingStats
        )
    }
    
    private func updateSuccessMetrics(_ result: FaceRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let successfulRecognitions = metrics.successfulRecognitions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRecognitions)) + result.processingTime) / Double(totalRecognitions)
        
        let newAverageFacesPerImage = ((metrics.averageFacesPerImage * Double(metrics.successfulRecognitions)) + Double(result.faceCount)) / Double(successfulRecognitions)
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulRecognitions)) + Double(result.averageConfidence)) / Double(successfulRecognitions)
        
        var recognitionsByQuality = metrics.recognitionsByQuality
        for face in result.faces {
            let qualityLevel = getQualityLevel(face.quality?.overall ?? 0.0)
            recognitionsByQuality[qualityLevel, default: 0] += 1
        }
        
        // Update tracking stats
        var trackingStats = metrics.trackingStats
        let trackedCount = result.faces.filter { $0.trackingId != nil }.count
        if trackedCount > 0 {
            trackingStats = FaceRecognitionMetrics.TrackingStats(
                totalTrackedFaces: trackingStats.totalTrackedFaces + trackedCount,
                activeTrackings: self.trackedFaces.count,
                lostTrackings: trackingStats.lostTrackings,
                averageTrackingDuration: trackingStats.averageTrackingDuration
            )
        }
        
        metrics = FaceRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: successfulRecognitions,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: newAverageProcessingTime,
            averageFacesPerImage: newAverageFacesPerImage,
            averageConfidence: newAverageConfidence,
            recognitionsByQuality: recognitionsByQuality,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: trackingStats
        )
    }
    
    private func updateFailureMetrics(_ result: FaceRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let failedRecognitions = metrics.failedRecognitions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = FaceRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions,
            failedRecognitions: failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            averageFacesPerImage: metrics.averageFacesPerImage,
            averageConfidence: metrics.averageConfidence,
            recognitionsByQuality: metrics.recognitionsByQuality,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond,
            trackingStats: metrics.trackingStats
        )
    }
    
    private func getQualityLevel(_ quality: Float) -> String {
        switch quality {
        case 0.8...: return "high"
        case 0.5..<0.8: return "medium"
        default: return "low"
        }
    }
    
    private func logRecognition(_ result: FaceRecognitionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let faceCount = result.faceCount
        let avgConfidence = result.averageConfidence
        
        print("[FaceRecognition] \(statusIcon) Recognition: \(faceCount) faces, avg confidence: \(String(format: "%.3f", avgConfidence)) (\(timeStr)s)")
        
        if let error = result.error {
            print("[FaceRecognition] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Face Recognition Capability Implementation

/// Face Recognition capability providing comprehensive face detection and recognition
@available(iOS 13.0, macOS 10.15, *)
public actor FaceRecognitionCapability: DomainCapability {
    public typealias ConfigurationType = FaceRecognitionCapabilityConfiguration
    public typealias ResourceType = FaceRecognitionCapabilityResource
    
    private var _configuration: FaceRecognitionCapabilityConfiguration
    private var _resources: FaceRecognitionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "face-recognition-capability" }
    
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
    
    public var configuration: FaceRecognitionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: FaceRecognitionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: FaceRecognitionCapabilityConfiguration = FaceRecognitionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = FaceRecognitionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: FaceRecognitionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Face Recognition configuration")
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
        // Face recognition is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Face recognition doesn't require special permissions beyond camera if using live camera
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Face Recognition Operations
    
    /// Recognize faces in image
    public func recognizeFaces(_ request: FaceRecognitionRequest) async throws -> FaceRecognitionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return try await _resources.recognizeFaces(request)
    }
    
    /// Cancel face recognition
    public func cancelRecognition(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        await _resources.cancelRecognition(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<FaceRecognitionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active recognitions
    public func getActiveRecognitions() async throws -> [FaceRecognitionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.getActiveRecognitions()
    }
    
    /// Get recognition history
    public func getRecognitionHistory(since: Date? = nil) async throws -> [FaceRecognitionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.getRecognitionHistory(since: since)
    }
    
    /// Get tracked faces
    public func getTrackedFaces() async throws -> [UUID: String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.getTrackedFaces()
    }
    
    /// Clear tracking
    public func clearTracking() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        await _resources.clearTracking()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> FaceRecognitionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Face Recognition capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick detect faces with default options
    public func quickDetectFaces(_ image: CIImage, minimumSize: Float = 0.05, qualityThreshold: Float = 0.3) async throws -> [FaceRecognitionResult.Face] {
        let options = FaceRecognitionRequest.RecognitionOptions(
            enableDetection: true,
            enableLandmarks: false,
            enableQualityAssessment: true,
            minimumFaceSize: minimumSize,
            qualityThreshold: qualityThreshold
        )
        
        let request = FaceRecognitionRequest(image: image, options: options)
        let result = try await recognizeFaces(request)
        
        return result.faces
    }
    
    /// Detect faces with landmarks
    public func detectFacesWithLandmarks(_ image: CIImage, qualityThreshold: Float = 0.3) async throws -> [FaceRecognitionResult.Face] {
        let options = FaceRecognitionRequest.RecognitionOptions(
            enableDetection: true,
            enableLandmarks: true,
            enableQualityAssessment: true,
            qualityThreshold: qualityThreshold
        )
        
        let request = FaceRecognitionRequest(image: image, options: options)
        let result = try await recognizeFaces(request)
        
        return result.faces
    }
    
    /// Check if face recognition is active
    public func hasActiveRecognitions() async throws -> Bool {
        let activeRecognitions = try await getActiveRecognitions()
        return !activeRecognitions.isEmpty
    }
    
    /// Get model count
    public func getModelCount() async throws -> Int {
        let models = try await getLoadedModels()
        return models.count
    }
    
    /// Get tracking count
    public func getTrackingCount() async throws -> Int {
        let trackedFaces = try await getTrackedFaces()
        return trackedFaces.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Face Recognition specific errors
public enum FaceRecognitionError: Error, LocalizedError {
    case faceRecognitionDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case recognitionError(String)
    case invalidImage
    case noFacesDetected
    case recognitionQueued(UUID)
    case recognitionTimeout(UUID)
    case trackingError(String)
    case qualityTooLow
    case unsupportedImageFormat
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .faceRecognitionDisabled:
            return "Face recognition is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .recognitionError(let reason):
            return "Face recognition failed: \(reason)"
        case .invalidImage:
            return "Invalid image provided"
        case .noFacesDetected:
            return "No faces detected in image"
        case .recognitionQueued(let id):
            return "Face recognition queued: \(id)"
        case .recognitionTimeout(let id):
            return "Face recognition timeout: \(id)"
        case .trackingError(let reason):
            return "Face tracking error: \(reason)"
        case .qualityTooLow:
            return "Face quality too low for recognition"
        case .unsupportedImageFormat:
            return "Unsupported image format"
        case .configurationError(let reason):
            return "Face recognition configuration error: \(reason)"
        }
    }
}