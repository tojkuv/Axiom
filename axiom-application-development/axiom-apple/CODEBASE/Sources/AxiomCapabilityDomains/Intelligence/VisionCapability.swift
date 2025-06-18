import Foundation
import Vision
import CoreImage
import AxiomCore
import AxiomCapabilities

// MARK: - Vision Capability Configuration

/// Configuration for Vision capability
public struct VisionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableVision: Bool
    public let enableImageAnalysis: Bool
    public let enableTextRecognition: Bool
    public let enableFaceDetection: Bool
    public let enableObjectDetection: Bool
    public let enableBarcodeDetection: Bool
    public let enableImageClassification: Bool
    public let maxConcurrentRequests: Int
    public let requestTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let revision: VisionRevision
    
    public enum VisionRevision: Int, Codable, CaseIterable {
        case automatic = 0
        case v1 = 1
        case v2 = 2
        case v3 = 3
        case latest = 99
    }
    
    public init(
        enableVision: Bool = true,
        enableImageAnalysis: Bool = true,
        enableTextRecognition: Bool = true,
        enableFaceDetection: Bool = true,
        enableObjectDetection: Bool = true,
        enableBarcodeDetection: Bool = true,
        enableImageClassification: Bool = true,
        maxConcurrentRequests: Int = 10,
        requestTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 100,
        enablePerformanceOptimization: Bool = true,
        revision: VisionRevision = .automatic
    ) {
        self.enableVision = enableVision
        self.enableImageAnalysis = enableImageAnalysis
        self.enableTextRecognition = enableTextRecognition
        self.enableFaceDetection = enableFaceDetection
        self.enableObjectDetection = enableObjectDetection
        self.enableBarcodeDetection = enableBarcodeDetection
        self.enableImageClassification = enableImageClassification
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestTimeout = requestTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.revision = revision
    }
    
    public var isValid: Bool {
        maxConcurrentRequests > 0 &&
        requestTimeout > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: VisionCapabilityConfiguration) -> VisionCapabilityConfiguration {
        VisionCapabilityConfiguration(
            enableVision: other.enableVision,
            enableImageAnalysis: other.enableImageAnalysis,
            enableTextRecognition: other.enableTextRecognition,
            enableFaceDetection: other.enableFaceDetection,
            enableObjectDetection: other.enableObjectDetection,
            enableBarcodeDetection: other.enableBarcodeDetection,
            enableImageClassification: other.enableImageClassification,
            maxConcurrentRequests: other.maxConcurrentRequests,
            requestTimeout: other.requestTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            revision: other.revision
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> VisionCapabilityConfiguration {
        var adjustedTimeout = requestTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRequests = maxConcurrentRequests
        var adjustedCacheSize = cacheSize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(requestTimeout, 15.0)
            adjustedConcurrentRequests = min(maxConcurrentRequests, 3)
            adjustedCacheSize = min(cacheSize, 20)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return VisionCapabilityConfiguration(
            enableVision: enableVision,
            enableImageAnalysis: enableImageAnalysis,
            enableTextRecognition: enableTextRecognition,
            enableFaceDetection: enableFaceDetection,
            enableObjectDetection: enableObjectDetection,
            enableBarcodeDetection: enableBarcodeDetection,
            enableImageClassification: enableImageClassification,
            maxConcurrentRequests: adjustedConcurrentRequests,
            requestTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            revision: revision
        )
    }
}

// MARK: - Vision Types

/// Vision analysis request
public struct VisionAnalysisRequest: Sendable, Identifiable {
    public let id: UUID
    public let image: CIImage
    public let requestTypes: Set<VisionRequestType>
    public let options: VisionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public enum VisionRequestType: String, Sendable, CaseIterable {
        case textRecognition = "text-recognition"
        case faceDetection = "face-detection"
        case objectDetection = "object-detection"
        case barcodeDetection = "barcode-detection"
        case imageClassification = "image-classification"
        case rectangleDetection = "rectangle-detection"
        case horizonDetection = "horizon-detection"
        case animalDetection = "animal-detection"
        case humanDetection = "human-detection"
    }
    
    public struct VisionOptions: Sendable {
        public let usesCPUOnly: Bool
        public let revision: VisionCapabilityConfiguration.VisionRevision
        public let minimumConfidence: Float
        public let maximumCandidates: Int
        public let recognitionLevel: TextRecognitionLevel
        public let usesLanguageCorrection: Bool
        public let customWords: [String]
        
        public enum TextRecognitionLevel: String, Sendable, CaseIterable {
            case fast = "fast"
            case accurate = "accurate"
        }
        
        public init(
            usesCPUOnly: Bool = false,
            revision: VisionCapabilityConfiguration.VisionRevision = .automatic,
            minimumConfidence: Float = 0.5,
            maximumCandidates: Int = 10,
            recognitionLevel: TextRecognitionLevel = .accurate,
            usesLanguageCorrection: Bool = true,
            customWords: [String] = []
        ) {
            self.usesCPUOnly = usesCPUOnly
            self.revision = revision
            self.minimumConfidence = minimumConfidence
            self.maximumCandidates = maximumCandidates
            self.recognitionLevel = recognitionLevel
            self.usesLanguageCorrection = usesLanguageCorrection
            self.customWords = customWords
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
        requestTypes: Set<VisionRequestType>,
        options: VisionOptions = VisionOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.image = image
        self.requestTypes = requestTypes
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Vision analysis result
public struct VisionAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let results: [VisionRequestType: VisionRequestResult]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: VisionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public enum VisionRequestResult: Sendable {
        case textRecognition([TextObservation])
        case faceDetection([FaceObservation])
        case objectDetection([ObjectObservation])
        case barcodeDetection([BarcodeObservation])
        case imageClassification([ClassificationObservation])
        case rectangleDetection([RectangleObservation])
        case horizonDetection([HorizonObservation])
        case animalDetection([AnimalObservation])
        case humanDetection([HumanObservation])
    }
    
    public struct TextObservation: Sendable {
        public let text: String
        public let confidence: Float
        public let boundingBox: CGRect
        public let characterBoxes: [CGRect]
        public let language: String?
        
        public init(text: String, confidence: Float, boundingBox: CGRect, characterBoxes: [CGRect] = [], language: String? = nil) {
            self.text = text
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.characterBoxes = characterBoxes
            self.language = language
        }
    }
    
    public struct FaceObservation: Sendable {
        public let boundingBox: CGRect
        public let confidence: Float
        public let landmarks: FaceLandmarks?
        public let faceId: Int?
        public let roll: Float?
        public let yaw: Float?
        public let pitch: Float?
        
        public struct FaceLandmarks: Sendable {
            public let leftEye: CGPoint?
            public let rightEye: CGPoint?
            public let nose: CGPoint?
            public let leftMouth: CGPoint?
            public let rightMouth: CGPoint?
            public let leftEyebrow: CGPoint?
            public let rightEyebrow: CGPoint?
            
            public init(leftEye: CGPoint? = nil, rightEye: CGPoint? = nil, nose: CGPoint? = nil, leftMouth: CGPoint? = nil, rightMouth: CGPoint? = nil, leftEyebrow: CGPoint? = nil, rightEyebrow: CGPoint? = nil) {
                self.leftEye = leftEye
                self.rightEye = rightEye
                self.nose = nose
                self.leftMouth = leftMouth
                self.rightMouth = rightMouth
                self.leftEyebrow = leftEyebrow
                self.rightEyebrow = rightEyebrow
            }
        }
        
        public init(boundingBox: CGRect, confidence: Float, landmarks: FaceLandmarks? = nil, faceId: Int? = nil, roll: Float? = nil, yaw: Float? = nil, pitch: Float? = nil) {
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.landmarks = landmarks
            self.faceId = faceId
            self.roll = roll
            self.yaw = yaw
            self.pitch = pitch
        }
    }
    
    public struct ObjectObservation: Sendable {
        public let identifier: String
        public let confidence: Float
        public let boundingBox: CGRect
        public let label: String?
        
        public init(identifier: String, confidence: Float, boundingBox: CGRect, label: String? = nil) {
            self.identifier = identifier
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.label = label
        }
    }
    
    public struct BarcodeObservation: Sendable {
        public let symbology: String
        public let payloadStringValue: String?
        public let boundingBox: CGRect
        public let confidence: Float
        
        public init(symbology: String, payloadStringValue: String?, boundingBox: CGRect, confidence: Float) {
            self.symbology = symbology
            self.payloadStringValue = payloadStringValue
            self.boundingBox = boundingBox
            self.confidence = confidence
        }
    }
    
    public struct ClassificationObservation: Sendable {
        public let identifier: String
        public let confidence: Float
        public let label: String?
        
        public init(identifier: String, confidence: Float, label: String? = nil) {
            self.identifier = identifier
            self.confidence = confidence
            self.label = label
        }
    }
    
    public struct RectangleObservation: Sendable {
        public let boundingBox: CGRect
        public let confidence: Float
        public let topLeft: CGPoint
        public let topRight: CGPoint
        public let bottomLeft: CGPoint
        public let bottomRight: CGPoint
        
        public init(boundingBox: CGRect, confidence: Float, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
        }
    }
    
    public struct HorizonObservation: Sendable {
        public let angle: Float
        public let confidence: Float
        
        public init(angle: Float, confidence: Float) {
            self.angle = angle
            self.confidence = confidence
        }
    }
    
    public struct AnimalObservation: Sendable {
        public let boundingBox: CGRect
        public let confidence: Float
        public let labels: [String]
        
        public init(boundingBox: CGRect, confidence: Float, labels: [String]) {
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.labels = labels
        }
    }
    
    public struct HumanObservation: Sendable {
        public let boundingBox: CGRect
        public let confidence: Float
        public let upperBodyOnly: Bool
        
        public init(boundingBox: CGRect, confidence: Float, upperBodyOnly: Bool = false) {
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.upperBodyOnly = upperBodyOnly
        }
    }
    
    public init(
        requestId: UUID,
        results: [VisionRequestType: VisionRequestResult],
        processingTime: TimeInterval,
        success: Bool,
        error: VisionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.results = results
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Vision metrics
public struct VisionMetrics: Sendable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageProcessingTime: TimeInterval
    public let requestsByType: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    
    public init(
        totalRequests: Int = 0,
        successfulRequests: Int = 0,
        failedRequests: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        requestsByType: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0
    ) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageProcessingTime = averageProcessingTime
        self.requestsByType = requestsByType
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRequests) / averageProcessingTime : 0
    }
    
    public var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
    }
}

// MARK: - Vision Resource

/// Vision resource management
@available(iOS 13.0, macOS 10.15, *)
public actor VisionCapabilityResource: AxiomCapabilityResource {
    private let configuration: VisionCapabilityConfiguration
    private var activeRequests: [UUID: VisionAnalysisRequest] = [:]
    private var requestQueue: [VisionAnalysisRequest] = []
    private var requestHistory: [VisionAnalysisResult] = []
    private var resultCache: [String: VisionAnalysisResult] = [:]
    private var metrics: VisionMetrics = VisionMetrics()
    private var resultStreamContinuation: AsyncStream<VisionAnalysisResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: VisionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for vision processing
            cpu: 5.0, // High CPU usage for vision analysis
            bandwidth: 0,
            storage: 50_000_000 // 50MB for caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let requestMemory = activeRequests.count * 20_000_000 // ~20MB per active request
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let historyMemory = requestHistory.count * 10_000
            
            return ResourceUsage(
                memory: requestMemory + cacheMemory + historyMemory + 20_000_000,
                cpu: activeRequests.isEmpty ? 0.3 : 4.0,
                bandwidth: 0,
                storage: resultCache.count * 50_000 // ~50KB per cached result
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Vision is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableVision
        }
        return false
    }
    
    public func release() async {
        activeRequests.removeAll()
        requestQueue.removeAll()
        requestHistory.removeAll()
        resultCache.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = VisionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Vision processing
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[Vision] 🚀 Vision capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: VisionCapabilityConfiguration) async throws {
        // Configuration updates for Vision
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<VisionAnalysisResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Vision Analysis
    
    public func analyzeImage(_ request: VisionAnalysisRequest) async throws -> VisionAnalysisResult {
        guard configuration.enableVision else {
            throw VisionError.visionDisabled
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
        if activeRequests.count >= configuration.maxConcurrentRequests {
            requestQueue.append(request)
            throw VisionError.requestQueued(request.id)
        }
        
        let startTime = Date()
        activeRequests[request.id] = request
        
        do {
            var results: [VisionAnalysisRequest.VisionRequestType: VisionAnalysisResult.VisionRequestResult] = [:]
            
            // Process each request type
            for requestType in request.requestTypes {
                let result = try await processVisionRequest(type: requestType, image: request.image, options: request.options)
                results[requestType] = result
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let analysisResult = VisionAnalysisResult(
                requestId: request.id,
                results: results,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeRequests.removeValue(forKey: request.id)
            requestHistory.append(analysisResult)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = analysisResult
            }
            
            resultStreamContinuation?.yield(analysisResult)
            
            await updateSuccessMetrics(analysisResult)
            
            if configuration.enableLogging {
                await logAnalysis(analysisResult)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processRequestQueue()
            }
            
            return analysisResult
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let analysisResult = VisionAnalysisResult(
                requestId: request.id,
                results: [:],
                processingTime: processingTime,
                success: false,
                error: error as? VisionError ?? VisionError.analysisError(error.localizedDescription)
            )
            
            activeRequests.removeValue(forKey: request.id)
            requestHistory.append(analysisResult)
            
            resultStreamContinuation?.yield(analysisResult)
            
            await updateFailureMetrics(analysisResult)
            
            if configuration.enableLogging {
                await logAnalysis(analysisResult)
            }
            
            throw error
        }
    }
    
    public func cancelRequest(_ requestId: UUID) async {
        activeRequests.removeValue(forKey: requestId)
        requestQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[Vision] 🚫 Cancelled request: \(requestId)")
        }
    }
    
    public func getActiveRequests() async -> [VisionAnalysisRequest] {
        return Array(activeRequests.values)
    }
    
    public func getRequestHistory(since: Date? = nil) async -> [VisionAnalysisResult] {
        if let since = since {
            return requestHistory.filter { $0.timestamp >= since }
        }
        return requestHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> VisionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = VisionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        // Performance optimization for Vision
        if configuration.enableLogging {
            print("[Vision] ⚡ Performance optimization enabled")
        }
    }
    
    private func processVisionRequest(type: VisionAnalysisRequest.VisionRequestType, image: CIImage, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        
        let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
        
        switch type {
        case .textRecognition:
            return try await performTextRecognition(requestHandler: requestHandler, options: options)
        case .faceDetection:
            return try await performFaceDetection(requestHandler: requestHandler, options: options)
        case .objectDetection:
            return try await performObjectDetection(requestHandler: requestHandler, options: options)
        case .barcodeDetection:
            return try await performBarcodeDetection(requestHandler: requestHandler, options: options)
        case .imageClassification:
            return try await performImageClassification(requestHandler: requestHandler, options: options)
        case .rectangleDetection:
            return try await performRectangleDetection(requestHandler: requestHandler, options: options)
        case .horizonDetection:
            return try await performHorizonDetection(requestHandler: requestHandler, options: options)
        case .animalDetection:
            return try await performAnimalDetection(requestHandler: requestHandler, options: options)
        case .humanDetection:
            return try await performHumanDetection(requestHandler: requestHandler, options: options)
        }
    }
    
    private func performTextRecognition(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let textObservations = observations.compactMap { observation -> VisionAnalysisResult.TextObservation? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    return VisionAnalysisResult.TextObservation(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: .textRecognition(textObservations))
            }
            
            request.recognitionLevel = options.recognitionLevel == .fast ? .fast : .accurate
            request.usesLanguageCorrection = options.usesLanguageCorrection
            if !options.customWords.isEmpty {
                request.customWords = options.customWords
            }
            request.minimumTextHeight = 0.05
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performFaceDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let faceObservations = observations.map { observation in
                    VisionAnalysisResult.FaceObservation(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        roll: observation.roll?.floatValue,
                        yaw: observation.yaw?.floatValue,
                        pitch: observation.pitch?.floatValue
                    )
                }
                
                continuation.resume(returning: .faceDetection(faceObservations))
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performObjectDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let objectObservations = observations.map { observation in
                    VisionAnalysisResult.ObjectObservation(
                        identifier: "rectangle",
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: .objectDetection(objectObservations))
            }
            
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.1
            request.minimumConfidence = options.minimumConfidence
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performBarcodeDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let barcodeObservations = observations.map { observation in
                    VisionAnalysisResult.BarcodeObservation(
                        symbology: observation.symbology.rawValue,
                        payloadStringValue: observation.payloadStringValue,
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: .barcodeDetection(barcodeObservations))
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performImageClassification(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let classificationObservations = observations.prefix(options.maximumCandidates).map { observation in
                    VisionAnalysisResult.ClassificationObservation(
                        identifier: observation.identifier,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: .imageClassification(Array(classificationObservations)))
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performRectangleDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let rectangleObservations = observations.map { observation in
                    VisionAnalysisResult.RectangleObservation(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        topLeft: observation.topLeft,
                        topRight: observation.topRight,
                        bottomLeft: observation.bottomLeft,
                        bottomRight: observation.bottomRight
                    )
                }
                
                continuation.resume(returning: .rectangleDetection(rectangleObservations))
            }
            
            request.minimumConfidence = options.minimumConfidence
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performHorizonDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHorizonRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNHorizonObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let horizonObservations = observations.map { observation in
                    VisionAnalysisResult.HorizonObservation(
                        angle: observation.angle,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: .horizonDetection(horizonObservations))
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performAnimalDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeAnimalsRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let animalObservations = observations.map { observation in
                    VisionAnalysisResult.AnimalObservation(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        labels: observation.labels.map { $0.identifier }
                    )
                }
                
                continuation.resume(returning: .animalDetection(animalObservations))
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performHumanDetection(requestHandler: VNImageRequestHandler, options: VisionAnalysisRequest.VisionOptions) async throws -> VisionAnalysisResult.VisionRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNHumanObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                let humanObservations = observations.map { observation in
                    VisionAnalysisResult.HumanObservation(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        upperBodyOnly: observation.upperBodyOnly
                    )
                }
                
                continuation.resume(returning: .humanDetection(humanObservations))
            }
            
            request.upperBodyOnly = false
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processRequestQueue() async {
        guard !isProcessingQueue && !requestQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        requestQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !requestQueue.isEmpty && activeRequests.count < configuration.maxConcurrentRequests {
            let request = requestQueue.removeFirst()
            
            do {
                _ = try await analyzeImage(request)
            } catch {
                if configuration.enableLogging {
                    print("[Vision] ⚠️ Queued request failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: VisionAnalysisRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: VisionAnalysisRequest) -> String {
        // Generate a cache key based on image hash and request parameters
        let imageData = request.image.pixelBuffer.map { Data(bytes: CVPixelBufferGetBaseAddress($0)!, count: CVPixelBufferGetDataSize($0)) } ?? Data()
        let imageHash = imageData.hashValue
        let requestTypes = request.requestTypes.sorted { $0.rawValue < $1.rawValue }.map { $0.rawValue }.joined(separator: ",")
        return "\(imageHash)_\(requestTypes)_\(request.options.minimumConfidence)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRequests)) + 1
        let totalRequests = metrics.totalRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = VisionMetrics(
            totalRequests: totalRequests,
            successfulRequests: metrics.successfulRequests + 1,
            failedRequests: metrics.failedRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            requestsByType: metrics.requestsByType,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateSuccessMetrics(_ result: VisionAnalysisResult) async {
        let totalRequests = metrics.totalRequests + 1
        let successfulRequests = metrics.successfulRequests + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRequests)) + result.processingTime) / Double(totalRequests)
        
        var requestsByType = metrics.requestsByType
        for requestType in result.results.keys {
            requestsByType[requestType.rawValue, default: 0] += 1
        }
        
        // Calculate average confidence
        var totalConfidence = metrics.averageConfidence * Double(metrics.successfulRequests)
        var confidenceCount = metrics.successfulRequests
        
        for (_, requestResult) in result.results {
            switch requestResult {
            case .textRecognition(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .faceDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .objectDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .barcodeDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .imageClassification(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .rectangleDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .horizonDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .animalDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            case .humanDetection(let observations):
                totalConfidence += observations.reduce(0) { $0 + Double($1.confidence) }
                confidenceCount += observations.count
            }
        }
        
        let newAverageConfidence = confidenceCount > 0 ? totalConfidence / Double(confidenceCount) : 0
        
        metrics = VisionMetrics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: metrics.failedRequests,
            averageProcessingTime: newAverageProcessingTime,
            requestsByType: requestsByType,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateFailureMetrics(_ result: VisionAnalysisResult) async {
        let totalRequests = metrics.totalRequests + 1
        let failedRequests = metrics.failedRequests + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = VisionMetrics(
            totalRequests: totalRequests,
            successfulRequests: metrics.successfulRequests,
            failedRequests: failedRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            requestsByType: metrics.requestsByType,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func logAnalysis(_ result: VisionAnalysisResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let resultCount = result.results.values.reduce(0) { total, requestResult in
            switch requestResult {
            case .textRecognition(let obs): return total + obs.count
            case .faceDetection(let obs): return total + obs.count
            case .objectDetection(let obs): return total + obs.count
            case .barcodeDetection(let obs): return total + obs.count
            case .imageClassification(let obs): return total + obs.count
            case .rectangleDetection(let obs): return total + obs.count
            case .horizonDetection(let obs): return total + obs.count
            case .animalDetection(let obs): return total + obs.count
            case .humanDetection(let obs): return total + obs.count
            }
        }
        
        print("[Vision] \(statusIcon) Analysis: \(result.results.count) types, \(resultCount) results (\(timeStr)s)")
        
        if let error = result.error {
            print("[Vision] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Vision Capability Implementation

/// Vision capability providing comprehensive computer vision analysis
@available(iOS 13.0, macOS 10.15, *)
public actor VisionCapability: DomainCapability {
    public typealias ConfigurationType = VisionCapabilityConfiguration
    public typealias ResourceType = VisionCapabilityResource
    
    private var _configuration: VisionCapabilityConfiguration
    private var _resources: VisionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "vision-capability" }
    
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
    
    public var configuration: VisionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: VisionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: VisionCapabilityConfiguration = VisionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = VisionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: VisionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Vision configuration")
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
        // Vision is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Vision doesn't require special permissions beyond camera if using live camera
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Vision Operations
    
    /// Analyze image with Vision
    public func analyzeImage(_ request: VisionAnalysisRequest) async throws -> VisionAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        return try await _resources.analyzeImage(request)
    }
    
    /// Cancel vision request
    public func cancelRequest(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        await _resources.cancelRequest(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<VisionAnalysisResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active requests
    public func getActiveRequests() async throws -> [VisionAnalysisRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        return await _resources.getActiveRequests()
    }
    
    /// Get request history
    public func getRequestHistory(since: Date? = nil) async throws -> [VisionAnalysisResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        return await _resources.getRequestHistory(since: since)
    }
    
    /// Get Vision metrics
    public func getMetrics() async throws -> VisionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Vision capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Detect text in image
    public func detectText(in image: CIImage, options: VisionAnalysisRequest.VisionOptions = VisionAnalysisRequest.VisionOptions()) async throws -> [VisionAnalysisResult.TextObservation] {
        let request = VisionAnalysisRequest(
            image: image,
            requestTypes: [.textRecognition],
            options: options
        )
        
        let result = try await analyzeImage(request)
        
        if case .textRecognition(let observations) = result.results[.textRecognition] {
            return observations
        }
        
        return []
    }
    
    /// Detect faces in image
    public func detectFaces(in image: CIImage, options: VisionAnalysisRequest.VisionOptions = VisionAnalysisRequest.VisionOptions()) async throws -> [VisionAnalysisResult.FaceObservation] {
        let request = VisionAnalysisRequest(
            image: image,
            requestTypes: [.faceDetection],
            options: options
        )
        
        let result = try await analyzeImage(request)
        
        if case .faceDetection(let observations) = result.results[.faceDetection] {
            return observations
        }
        
        return []
    }
    
    /// Classify image
    public func classifyImage(_ image: CIImage, options: VisionAnalysisRequest.VisionOptions = VisionAnalysisRequest.VisionOptions()) async throws -> [VisionAnalysisResult.ClassificationObservation] {
        let request = VisionAnalysisRequest(
            image: image,
            requestTypes: [.imageClassification],
            options: options
        )
        
        let result = try await analyzeImage(request)
        
        if case .imageClassification(let observations) = result.results[.imageClassification] {
            return observations
        }
        
        return []
    }
    
    /// Check if vision is processing
    public func hasActiveRequests() async throws -> Bool {
        let activeRequests = try await getActiveRequests()
        return !activeRequests.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Vision specific errors
public enum VisionError: Error, LocalizedError {
    case visionDisabled
    case analysisError(String)
    case invalidImage
    case noResults
    case requestQueued(UUID)
    case requestTimeout(UUID)
    case unsupportedRequestType(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .visionDisabled:
            return "Vision is disabled"
        case .analysisError(let reason):
            return "Vision analysis failed: \(reason)"
        case .invalidImage:
            return "Invalid image provided"
        case .noResults:
            return "No results found in vision analysis"
        case .requestQueued(let id):
            return "Vision request queued: \(id)"
        case .requestTimeout(let id):
            return "Vision request timeout: \(id)"
        case .unsupportedRequestType(let type):
            return "Unsupported request type: \(type)"
        case .configurationError(let reason):
            return "Vision configuration error: \(reason)"
        }
    }
}