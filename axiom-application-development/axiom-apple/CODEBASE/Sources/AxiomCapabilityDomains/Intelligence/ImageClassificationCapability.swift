import Foundation
import Vision
import CoreImage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Image Classification Capability Configuration

/// Configuration for Image Classification capability
public struct ImageClassificationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableImageClassification: Bool
    public let enableCustomModels: Bool
    public let enableConfidenceFiltering: Bool
    public let enableBatchClassification: Bool
    public let enableRealTimeClassification: Bool
    public let maxConcurrentClassifications: Int
    public let classificationTimeout: TimeInterval
    public let minimumConfidence: Float
    public let maximumResults: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let preferredComputeUnits: ComputeUnits
    public let modelUpdateInterval: TimeInterval
    
    public enum ComputeUnits: String, Codable, CaseIterable {
        case cpuOnly = "cpu-only"
        case cpuAndGPU = "cpu-and-gpu"
        case cpuAndNeuralEngine = "cpu-and-neural-engine"
        case all = "all"
    }
    
    public init(
        enableImageClassification: Bool = true,
        enableCustomModels: Bool = true,
        enableConfidenceFiltering: Bool = true,
        enableBatchClassification: Bool = true,
        enableRealTimeClassification: Bool = true,
        maxConcurrentClassifications: Int = 8,
        classificationTimeout: TimeInterval = 30.0,
        minimumConfidence: Float = 0.01,
        maximumResults: Int = 10,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        enablePerformanceOptimization: Bool = true,
        preferredComputeUnits: ComputeUnits = .all,
        modelUpdateInterval: TimeInterval = 86400.0 // 24 hours
    ) {
        self.enableImageClassification = enableImageClassification
        self.enableCustomModels = enableCustomModels
        self.enableConfidenceFiltering = enableConfidenceFiltering
        self.enableBatchClassification = enableBatchClassification
        self.enableRealTimeClassification = enableRealTimeClassification
        self.maxConcurrentClassifications = maxConcurrentClassifications
        self.classificationTimeout = classificationTimeout
        self.minimumConfidence = minimumConfidence
        self.maximumResults = maximumResults
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.preferredComputeUnits = preferredComputeUnits
        self.modelUpdateInterval = modelUpdateInterval
    }
    
    public var isValid: Bool {
        maxConcurrentClassifications > 0 &&
        classificationTimeout > 0 &&
        minimumConfidence >= 0.0 && minimumConfidence <= 1.0 &&
        maximumResults > 0 &&
        cacheSize >= 0 &&
        modelUpdateInterval > 0
    }
    
    public func merged(with other: ImageClassificationCapabilityConfiguration) -> ImageClassificationCapabilityConfiguration {
        ImageClassificationCapabilityConfiguration(
            enableImageClassification: other.enableImageClassification,
            enableCustomModels: other.enableCustomModels,
            enableConfidenceFiltering: other.enableConfidenceFiltering,
            enableBatchClassification: other.enableBatchClassification,
            enableRealTimeClassification: other.enableRealTimeClassification,
            maxConcurrentClassifications: other.maxConcurrentClassifications,
            classificationTimeout: other.classificationTimeout,
            minimumConfidence: other.minimumConfidence,
            maximumResults: other.maximumResults,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            preferredComputeUnits: other.preferredComputeUnits,
            modelUpdateInterval: other.modelUpdateInterval
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ImageClassificationCapabilityConfiguration {
        var adjustedTimeout = classificationTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentClassifications = maxConcurrentClassifications
        var adjustedCacheSize = cacheSize
        var adjustedComputeUnits = preferredComputeUnits
        var adjustedMaxResults = maximumResults
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(classificationTimeout, 15.0)
            adjustedConcurrentClassifications = min(maxConcurrentClassifications, 3)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedComputeUnits = .cpuOnly
            adjustedMaxResults = min(maximumResults, 5)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ImageClassificationCapabilityConfiguration(
            enableImageClassification: enableImageClassification,
            enableCustomModels: enableCustomModels,
            enableConfidenceFiltering: enableConfidenceFiltering,
            enableBatchClassification: enableBatchClassification,
            enableRealTimeClassification: enableRealTimeClassification,
            maxConcurrentClassifications: adjustedConcurrentClassifications,
            classificationTimeout: adjustedTimeout,
            minimumConfidence: minimumConfidence,
            maximumResults: adjustedMaxResults,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            preferredComputeUnits: adjustedComputeUnits,
            modelUpdateInterval: modelUpdateInterval
        )
    }
}

// MARK: - Image Classification Types

/// Image classification request
public struct ImageClassificationRequest: Sendable, Identifiable {
    public let id: UUID
    public let image: CIImage
    public let modelIdentifier: String?
    public let options: ClassificationOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct ClassificationOptions: Sendable {
        public let minimumConfidence: Float
        public let maximumResults: Int
        public let usesCPUOnly: Bool
        public let computeUnits: ImageClassificationCapabilityConfiguration.ComputeUnits?
        public let cropAndScale: CropAndScale?
        public let preprocessingOptions: PreprocessingOptions
        
        public struct CropAndScale: Sendable {
            public let cropRect: CGRect?
            public let scaleToSize: CGSize?
            public let maintainAspectRatio: Bool
            
            public init(cropRect: CGRect? = nil, scaleToSize: CGSize? = nil, maintainAspectRatio: Bool = true) {
                self.cropRect = cropRect
                self.scaleToSize = scaleToSize
                self.maintainAspectRatio = maintainAspectRatio
            }
        }
        
        public struct PreprocessingOptions: Sendable {
            public let normalizeValues: Bool
            public let applyCenterCrop: Bool
            public let applyColorCorrection: Bool
            public let enhanceContrast: Bool
            
            public init(normalizeValues: Bool = true, applyCenterCrop: Bool = false, applyColorCorrection: Bool = false, enhanceContrast: Bool = false) {
                self.normalizeValues = normalizeValues
                self.applyCenterCrop = applyCenterCrop
                self.applyColorCorrection = applyColorCorrection
                self.enhanceContrast = enhanceContrast
            }
        }
        
        public init(
            minimumConfidence: Float = 0.01,
            maximumResults: Int = 10,
            usesCPUOnly: Bool = false,
            computeUnits: ImageClassificationCapabilityConfiguration.ComputeUnits? = nil,
            cropAndScale: CropAndScale? = nil,
            preprocessingOptions: PreprocessingOptions = PreprocessingOptions()
        ) {
            self.minimumConfidence = minimumConfidence
            self.maximumResults = maximumResults
            self.usesCPUOnly = usesCPUOnly
            self.computeUnits = computeUnits
            self.cropAndScale = cropAndScale
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
        options: ClassificationOptions = ClassificationOptions(),
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

/// Image classification result
public struct ImageClassificationResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let classifications: [Classification]
    public let modelInfo: ModelInfo
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ImageClassificationError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct Classification: Sendable {
        public let identifier: String
        public let label: String?
        public let confidence: Float
        public let category: String?
        public let hierarchy: [String]
        public let boundingBox: CGRect?
        public let additionalInfo: [String: String]
        
        public init(
            identifier: String,
            label: String? = nil,
            confidence: Float,
            category: String? = nil,
            hierarchy: [String] = [],
            boundingBox: CGRect? = nil,
            additionalInfo: [String: String] = [:]
        ) {
            self.identifier = identifier
            self.label = label
            self.confidence = confidence
            self.category = category
            self.hierarchy = hierarchy
            self.boundingBox = boundingBox
            self.additionalInfo = additionalInfo
        }
    }
    
    public struct ModelInfo: Sendable {
        public let identifier: String
        public let name: String
        public let version: String?
        public let description: String?
        public let inputSize: CGSize?
        public let outputClasses: Int?
        public let computeUnits: String?
        
        public init(
            identifier: String,
            name: String,
            version: String? = nil,
            description: String? = nil,
            inputSize: CGSize? = nil,
            outputClasses: Int? = nil,
            computeUnits: String? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.version = version
            self.description = description
            self.inputSize = inputSize
            self.outputClasses = outputClasses
            self.computeUnits = computeUnits
        }
    }
    
    public init(
        requestId: UUID,
        classifications: [Classification],
        modelInfo: ModelInfo,
        processingTime: TimeInterval,
        success: Bool,
        error: ImageClassificationError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.classifications = classifications
        self.modelInfo = modelInfo
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var topClassification: Classification? {
        classifications.max(by: { $0.confidence < $1.confidence })
    }
    
    public var averageConfidence: Float {
        guard !classifications.isEmpty else { return 0.0 }
        return classifications.reduce(0) { $0 + $1.confidence } / Float(classifications.count)
    }
}

/// Image classification metrics
public struct ImageClassificationMetrics: Sendable {
    public let totalClassifications: Int
    public let successfulClassifications: Int
    public let failedClassifications: Int
    public let averageProcessingTime: TimeInterval
    public let classificationsByModel: [String: Int]
    public let classificationsByCategory: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    public let modelUsageStats: [String: ModelUsageStats]
    
    public struct ModelUsageStats: Sendable {
        public let usageCount: Int
        public let averageProcessingTime: TimeInterval
        public let successRate: Double
        public let averageConfidence: Double
        
        public init(usageCount: Int, averageProcessingTime: TimeInterval, successRate: Double, averageConfidence: Double) {
            self.usageCount = usageCount
            self.averageProcessingTime = averageProcessingTime
            self.successRate = successRate
            self.averageConfidence = averageConfidence
        }
    }
    
    public init(
        totalClassifications: Int = 0,
        successfulClassifications: Int = 0,
        failedClassifications: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        classificationsByModel: [String: Int] = [:],
        classificationsByCategory: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0,
        modelUsageStats: [String: ModelUsageStats] = [:]
    ) {
        self.totalClassifications = totalClassifications
        self.successfulClassifications = successfulClassifications
        self.failedClassifications = failedClassifications
        self.averageProcessingTime = averageProcessingTime
        self.classificationsByModel = classificationsByModel
        self.classificationsByCategory = classificationsByCategory
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalClassifications) / averageProcessingTime : 0
        self.modelUsageStats = modelUsageStats
    }
    
    public var successRate: Double {
        totalClassifications > 0 ? Double(successfulClassifications) / Double(totalClassifications) : 0
    }
}

// MARK: - Image Classification Resource

/// Image classification resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ImageClassificationCapabilityResource: AxiomCapabilityResource {
    private let configuration: ImageClassificationCapabilityConfiguration
    private var activeClassifications: [UUID: ImageClassificationRequest] = [:]
    private var classificationQueue: [ImageClassificationRequest] = []
    private var classificationHistory: [ImageClassificationResult] = []
    private var resultCache: [String: ImageClassificationResult] = [:]
    private var loadedModels: [String: MLModel] = [:]
    private var modelInfos: [String: ImageClassificationResult.ModelInfo] = [:]
    private var metrics: ImageClassificationMetrics = ImageClassificationMetrics()
    private var resultStreamContinuation: AsyncStream<ImageClassificationResult>.Continuation?
    private var isProcessingQueue: Bool = false
    private var lastModelUpdate: Date = Date()
    
    public init(configuration: ImageClassificationCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 200_000_000, // 200MB for image classification
            cpu: 4.0, // High CPU usage for image processing
            bandwidth: 0,
            storage: 100_000_000 // 100MB for model caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let classificationMemory = activeClassifications.count * 25_000_000 // ~25MB per active classification
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let modelMemory = loadedModels.count * 50_000_000 // ~50MB per loaded model
            let historyMemory = classificationHistory.count * 10_000
            
            return ResourceUsage(
                memory: classificationMemory + cacheMemory + modelMemory + historyMemory + 20_000_000,
                cpu: activeClassifications.isEmpty ? 0.3 : 3.5,
                bandwidth: 0,
                storage: resultCache.count * 50_000 + loadedModels.count * 100_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Image classification is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableImageClassification
        }
        return false
    }
    
    public func release() async {
        activeClassifications.removeAll()
        classificationQueue.removeAll()
        classificationHistory.removeAll()
        resultCache.removeAll()
        loadedModels.removeAll()
        modelInfos.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = ImageClassificationMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize default classification models
        if configuration.enableCustomModels {
            await loadDefaultModels()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[ImageClassification] 🚀 Image Classification capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: ImageClassificationCapabilityConfiguration) async throws {
        // Check if models need updating
        if Date().timeIntervalSince(lastModelUpdate) >= configuration.modelUpdateInterval {
            await updateModels()
        }
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<ImageClassificationResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadModel(from url: URL, identifier: String) async throws -> ImageClassificationResult.ModelInfo {
        guard configuration.enableCustomModels else {
            throw ImageClassificationError.customModelsDisabled
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
            throw ImageClassificationError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadModel(_ identifier: String) async {
        loadedModels.removeValue(forKey: identifier)
        modelInfos.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[ImageClassification] 🗑️ Unloaded model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [ImageClassificationResult.ModelInfo] {
        return Array(modelInfos.values)
    }
    
    public func getModelInfo(identifier: String) async -> ImageClassificationResult.ModelInfo? {
        return modelInfos[identifier]
    }
    
    // MARK: - Image Classification
    
    public func classifyImage(_ request: ImageClassificationRequest) async throws -> ImageClassificationResult {
        guard configuration.enableImageClassification else {
            throw ImageClassificationError.imageClassificationDisabled
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
        if activeClassifications.count >= configuration.maxConcurrentClassifications {
            classificationQueue.append(request)
            throw ImageClassificationError.classificationQueued(request.id)
        }
        
        let startTime = Date()
        activeClassifications[request.id] = request
        
        do {
            // Get the model to use
            let model = try await getModelForClassification(request)
            let modelInfo = modelInfos[request.modelIdentifier ?? "default"] ?? createDefaultModelInfo()
            
            // Preprocess image if needed
            let processedImage = await preprocessImage(request.image, options: request.options)
            
            // Perform classification
            let classifications = try await performClassification(
                image: processedImage,
                model: model,
                options: request.options
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ImageClassificationResult(
                requestId: request.id,
                classifications: classifications,
                modelInfo: modelInfo,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeClassifications.removeValue(forKey: request.id)
            classificationHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logClassification(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processClassificationQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ImageClassificationResult(
                requestId: request.id,
                classifications: [],
                modelInfo: createDefaultModelInfo(),
                processingTime: processingTime,
                success: false,
                error: error as? ImageClassificationError ?? ImageClassificationError.classificationError(error.localizedDescription)
            )
            
            activeClassifications.removeValue(forKey: request.id)
            classificationHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logClassification(result)
            }
            
            throw error
        }
    }
    
    public func classifyImages(_ requests: [ImageClassificationRequest]) async throws -> [ImageClassificationResult] {
        guard configuration.enableBatchClassification else {
            throw ImageClassificationError.batchClassificationDisabled
        }
        
        var results: [ImageClassificationResult] = []
        
        // Process in batches to manage memory
        let batchSize = min(configuration.maxConcurrentClassifications, requests.count)
        
        for batch in requests.chunked(into: batchSize) {
            let batchResults = try await withThrowingTaskGroup(of: ImageClassificationResult.self) { group in
                for request in batch {
                    group.addTask {
                        try await self.classifyImage(request)
                    }
                }
                
                var batchResults: [ImageClassificationResult] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    public func cancelClassification(_ requestId: UUID) async {
        activeClassifications.removeValue(forKey: requestId)
        classificationQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[ImageClassification] 🚫 Cancelled classification: \(requestId)")
        }
    }
    
    public func getActiveClassifications() async -> [ImageClassificationRequest] {
        return Array(activeClassifications.values)
    }
    
    public func getClassificationHistory(since: Date? = nil) async -> [ImageClassificationResult] {
        if let since = since {
            return classificationHistory.filter { $0.timestamp >= since }
        }
        return classificationHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ImageClassificationMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ImageClassificationMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultModels() async {
        // Load built-in Vision classification models
        if #available(iOS 13.0, macOS 10.15, *) {
            // Create default model info for Vision framework
            let defaultModelInfo = ImageClassificationResult.ModelInfo(
                identifier: "default",
                name: "Vision Image Classification",
                version: "1.0",
                description: "Built-in Vision framework image classification",
                computeUnits: configuration.preferredComputeUnits.rawValue
            )
            
            modelInfos["default"] = defaultModelInfo
            
            if configuration.enableLogging {
                print("[ImageClassification] 📦 Loaded default Vision classification model")
            }
        }
    }
    
    private func updateModels() async {
        lastModelUpdate = Date()
        
        if configuration.enableLogging {
            print("[ImageClassification] 🔄 Updated models")
        }
    }
    
    private func optimizePerformance() async {
        // Performance optimization for image classification
        if configuration.enableLogging {
            print("[ImageClassification] ⚡ Performance optimization enabled")
        }
    }
    
    private func getModelForClassification(_ request: ImageClassificationRequest) async throws -> MLModel? {
        if let modelId = request.modelIdentifier {
            guard let model = loadedModels[modelId] else {
                throw ImageClassificationError.modelNotLoaded(modelId)
            }
            return model
        }
        
        // Use Vision framework for default classification
        return nil
    }
    
    private func preprocessImage(_ image: CIImage, options: ImageClassificationRequest.ClassificationOptions) async -> CIImage {
        var processedImage = image
        
        // Apply cropping if specified
        if let cropAndScale = options.cropAndScale {
            if let cropRect = cropAndScale.cropRect {
                processedImage = processedImage.cropped(to: cropRect)
            }
            
            if let scaleSize = cropAndScale.scaleToSize {
                let scaleX = scaleSize.width / processedImage.extent.width
                let scaleY = scaleSize.height / processedImage.extent.height
                
                let scale = cropAndScale.maintainAspectRatio ? min(scaleX, scaleY) : max(scaleX, scaleY)
                processedImage = processedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
        }
        
        // Apply preprocessing options
        let preprocessing = options.preprocessingOptions
        
        if preprocessing.applyColorCorrection {
            processedImage = processedImage.applyingFilter("CIColorControls")
        }
        
        if preprocessing.enhanceContrast {
            processedImage = processedImage.applyingFilter("CIColorControls", parameters: ["inputContrast": 1.2])
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
    
    private func performClassification(image: CIImage, model: MLModel?, options: ImageClassificationRequest.ClassificationOptions) async throws -> [ImageClassificationResult.Classification] {
        
        if let model = model {
            // Use custom Core ML model
            return try await classifyWithCoreML(image: image, model: model, options: options)
        } else {
            // Use Vision framework
            return try await classifyWithVision(image: image, options: options)
        }
    }
    
    private func classifyWithVision(image: CIImage, options: ImageClassificationRequest.ClassificationOptions) async throws -> [ImageClassificationResult.Classification] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ImageClassificationError.noResults)
                    return
                }
                
                let classifications = observations
                    .filter { $0.confidence >= options.minimumConfidence }
                    .prefix(options.maximumResults)
                    .map { observation in
                        ImageClassificationResult.Classification(
                            identifier: observation.identifier,
                            confidence: observation.confidence,
                            hierarchy: observation.identifier.components(separatedBy: "/")
                        )
                    }
                
                continuation.resume(returning: Array(classifications))
            }
            
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func classifyWithCoreML(image: CIImage, model: MLModel, options: ImageClassificationRequest.ClassificationOptions) async throws -> [ImageClassificationResult.Classification] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: model)) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ImageClassificationError.noResults)
                    return
                }
                
                let classifications = observations
                    .filter { $0.confidence >= options.minimumConfidence }
                    .prefix(options.maximumResults)
                    .map { observation in
                        ImageClassificationResult.Classification(
                            identifier: observation.identifier,
                            confidence: observation.confidence,
                            hierarchy: observation.identifier.components(separatedBy: "/")
                        )
                    }
                
                continuation.resume(returning: Array(classifications))
            }
            
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processClassificationQueue() async {
        guard !isProcessingQueue && !classificationQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        classificationQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !classificationQueue.isEmpty && activeClassifications.count < configuration.maxConcurrentClassifications {
            let request = classificationQueue.removeFirst()
            
            do {
                _ = try await classifyImage(request)
            } catch {
                if configuration.enableLogging {
                    print("[ImageClassification] ⚠️ Queued classification failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: ImageClassificationRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: ImageClassificationRequest) -> String {
        // Generate a cache key based on image hash and request parameters
        let imageHash = request.image.extent.hashValue
        let modelId = request.modelIdentifier ?? "default"
        let confidence = Int(request.options.minimumConfidence * 1000)
        return "\(imageHash)_\(modelId)_\(confidence)_\(request.options.maximumResults)"
    }
    
    private func createModelInfo(from model: MLModel, identifier: String, url: URL) -> ImageClassificationResult.ModelInfo {
        let modelDescription = model.modelDescription
        
        // Get file size
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        
        // Try to determine input size from model description
        var inputSize: CGSize?
        if let inputDescription = modelDescription.inputDescriptionsByName.values.first,
           let imageConstraint = inputDescription.imageConstraint {
            inputSize = CGSize(width: imageConstraint.pixelsWide, height: imageConstraint.pixelsHigh)
        }
        
        // Try to determine output classes count
        var outputClasses: Int?
        if let outputDescription = modelDescription.outputDescriptionsByName.values.first,
           let multiArrayConstraint = outputDescription.multiArrayConstraint {
            outputClasses = multiArrayConstraint.shape.first?.intValue
        }
        
        return ImageClassificationResult.ModelInfo(
            identifier: identifier,
            name: modelDescription.metadata[.name] as? String ?? identifier,
            version: modelDescription.metadata[.versionString] as? String,
            description: modelDescription.metadata[.description] as? String,
            inputSize: inputSize,
            outputClasses: outputClasses,
            computeUnits: configuration.preferredComputeUnits.rawValue
        )
    }
    
    private func createDefaultModelInfo() -> ImageClassificationResult.ModelInfo {
        return ImageClassificationResult.ModelInfo(
            identifier: "default",
            name: "Vision Image Classification",
            version: "1.0",
            description: "Built-in Vision framework image classification",
            computeUnits: configuration.preferredComputeUnits.rawValue
        )
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalClassifications)) + 1
        let totalClassifications = metrics.totalClassifications + 1
        let newCacheHitRate = cacheHits / Double(totalClassifications)
        
        metrics = ImageClassificationMetrics(
            totalClassifications: totalClassifications,
            successfulClassifications: metrics.successfulClassifications + 1,
            failedClassifications: metrics.failedClassifications,
            averageProcessingTime: metrics.averageProcessingTime,
            classificationsByModel: metrics.classificationsByModel,
            classificationsByCategory: metrics.classificationsByCategory,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelUsageStats: metrics.modelUsageStats
        )
    }
    
    private func updateSuccessMetrics(_ result: ImageClassificationResult) async {
        let totalClassifications = metrics.totalClassifications + 1
        let successfulClassifications = metrics.successfulClassifications + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalClassifications)) + result.processingTime) / Double(totalClassifications)
        
        var classificationsByModel = metrics.classificationsByModel
        classificationsByModel[result.modelInfo.identifier, default: 0] += 1
        
        var classificationsByCategory = metrics.classificationsByCategory
        for classification in result.classifications {
            if let category = classification.category {
                classificationsByCategory[category, default: 0] += 1
            }
        }
        
        let newAverageConfidence = result.classifications.isEmpty ? metrics.averageConfidence :
            ((metrics.averageConfidence * Double(metrics.successfulClassifications)) + Double(result.averageConfidence)) / Double(successfulClassifications)
        
        // Update model usage stats
        var modelUsageStats = metrics.modelUsageStats
        let modelId = result.modelInfo.identifier
        if let existingStats = modelUsageStats[modelId] {
            let newUsageCount = existingStats.usageCount + 1
            let newAvgTime = ((existingStats.averageProcessingTime * Double(existingStats.usageCount)) + result.processingTime) / Double(newUsageCount)
            let newSuccessRate = ((existingStats.successRate * Double(existingStats.usageCount)) + 1.0) / Double(newUsageCount)
            let newAvgConfidence = ((existingStats.averageConfidence * Double(existingStats.usageCount)) + Double(result.averageConfidence)) / Double(newUsageCount)
            
            modelUsageStats[modelId] = ImageClassificationMetrics.ModelUsageStats(
                usageCount: newUsageCount,
                averageProcessingTime: newAvgTime,
                successRate: newSuccessRate,
                averageConfidence: newAvgConfidence
            )
        } else {
            modelUsageStats[modelId] = ImageClassificationMetrics.ModelUsageStats(
                usageCount: 1,
                averageProcessingTime: result.processingTime,
                successRate: 1.0,
                averageConfidence: Double(result.averageConfidence)
            )
        }
        
        metrics = ImageClassificationMetrics(
            totalClassifications: totalClassifications,
            successfulClassifications: successfulClassifications,
            failedClassifications: metrics.failedClassifications,
            averageProcessingTime: newAverageProcessingTime,
            classificationsByModel: classificationsByModel,
            classificationsByCategory: classificationsByCategory,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelUsageStats: modelUsageStats
        )
    }
    
    private func updateFailureMetrics(_ result: ImageClassificationResult) async {
        let totalClassifications = metrics.totalClassifications + 1
        let failedClassifications = metrics.failedClassifications + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        // Update model usage stats for failures
        var modelUsageStats = metrics.modelUsageStats
        let modelId = result.modelInfo.identifier
        if let existingStats = modelUsageStats[modelId] {
            let newUsageCount = existingStats.usageCount + 1
            let newAvgTime = ((existingStats.averageProcessingTime * Double(existingStats.usageCount)) + result.processingTime) / Double(newUsageCount)
            let newSuccessRate = (existingStats.successRate * Double(existingStats.usageCount)) / Double(newUsageCount)
            
            modelUsageStats[modelId] = ImageClassificationMetrics.ModelUsageStats(
                usageCount: newUsageCount,
                averageProcessingTime: newAvgTime,
                successRate: newSuccessRate,
                averageConfidence: existingStats.averageConfidence
            )
        } else {
            modelUsageStats[modelId] = ImageClassificationMetrics.ModelUsageStats(
                usageCount: 1,
                averageProcessingTime: result.processingTime,
                successRate: 0.0,
                averageConfidence: 0.0
            )
        }
        
        metrics = ImageClassificationMetrics(
            totalClassifications: totalClassifications,
            successfulClassifications: metrics.successfulClassifications,
            failedClassifications: failedClassifications,
            averageProcessingTime: metrics.averageProcessingTime,
            classificationsByModel: metrics.classificationsByModel,
            classificationsByCategory: metrics.classificationsByCategory,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelUsageStats: modelUsageStats
        )
    }
    
    private func logModel(_ model: ImageClassificationResult.ModelInfo, action: String) async {
        print("[ImageClassification] 📦 \(action): \(model.name) (\(model.identifier))")
    }
    
    private func logClassification(_ result: ImageClassificationResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let classificationCount = result.classifications.count
        let topConfidence = result.topClassification?.confidence ?? 0.0
        
        print("[ImageClassification] \(statusIcon) Classification: \(classificationCount) results, top confidence: \(String(format: "%.3f", topConfidence)) (\(timeStr)s)")
        
        if let error = result.error {
            print("[ImageClassification] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Image Classification Capability Implementation

/// Image Classification capability providing comprehensive image classification
@available(iOS 13.0, macOS 10.15, *)
public actor ImageClassificationCapability: DomainCapability {
    public typealias ConfigurationType = ImageClassificationCapabilityConfiguration
    public typealias ResourceType = ImageClassificationCapabilityResource
    
    private var _configuration: ImageClassificationCapabilityConfiguration
    private var _resources: ImageClassificationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "image-classification-capability" }
    
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
    
    public var configuration: ImageClassificationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ImageClassificationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ImageClassificationCapabilityConfiguration = ImageClassificationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ImageClassificationCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ImageClassificationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Image Classification configuration")
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
        // Image classification is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Image classification doesn't require special permissions beyond camera if using live camera
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Image Classification Operations
    
    /// Classify image
    public func classifyImage(_ request: ImageClassificationRequest) async throws -> ImageClassificationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return try await _resources.classifyImage(request)
    }
    
    /// Classify multiple images
    public func classifyImages(_ requests: [ImageClassificationRequest]) async throws -> [ImageClassificationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return try await _resources.classifyImages(requests)
    }
    
    /// Cancel classification
    public func cancelClassification(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        await _resources.cancelClassification(requestId)
    }
    
    /// Load custom model
    public func loadModel(from url: URL, identifier: String) async throws -> ImageClassificationResult.ModelInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return try await _resources.loadModel(from: url, identifier: identifier)
    }
    
    /// Unload model
    public func unloadModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        await _resources.unloadModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<ImageClassificationResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [ImageClassificationResult.ModelInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active classifications
    public func getActiveClassifications() async throws -> [ImageClassificationRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return await _resources.getActiveClassifications()
    }
    
    /// Get classification history
    public func getClassificationHistory(since: Date? = nil) async throws -> [ImageClassificationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return await _resources.getClassificationHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ImageClassificationMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Image Classification capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick classify image with default options
    public func quickClassify(_ image: CIImage, confidence: Float = 0.1, maxResults: Int = 5) async throws -> [ImageClassificationResult.Classification] {
        let options = ImageClassificationRequest.ClassificationOptions(
            minimumConfidence: confidence,
            maximumResults: maxResults
        )
        
        let request = ImageClassificationRequest(image: image, options: options)
        let result = try await classifyImage(request)
        
        return result.classifications
    }
    
    /// Check if classification is active
    public func hasActiveClassifications() async throws -> Bool {
        let activeClassifications = try await getActiveClassifications()
        return !activeClassifications.isEmpty
    }
    
    /// Get model count
    public func getModelCount() async throws -> Int {
        let models = try await getLoadedModels()
        return models.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Image Classification specific errors
public enum ImageClassificationError: Error, LocalizedError {
    case imageClassificationDisabled
    case customModelsDisabled
    case batchClassificationDisabled
    case modelLoadFailed(String, String)
    case modelNotLoaded(String)
    case classificationError(String)
    case invalidImage
    case noResults
    case classificationQueued(UUID)
    case classificationTimeout(UUID)
    case unsupportedImageFormat
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .imageClassificationDisabled:
            return "Image classification is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .batchClassificationDisabled:
            return "Batch classification is disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .modelNotLoaded(let identifier):
            return "Model not loaded: \(identifier)"
        case .classificationError(let reason):
            return "Classification failed: \(reason)"
        case .invalidImage:
            return "Invalid image provided"
        case .noResults:
            return "No classification results found"
        case .classificationQueued(let id):
            return "Classification queued: \(id)"
        case .classificationTimeout(let id):
            return "Classification timeout: \(id)"
        case .unsupportedImageFormat:
            return "Unsupported image format"
        case .configurationError(let reason):
            return "Image classification configuration error: \(reason)"
        }
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