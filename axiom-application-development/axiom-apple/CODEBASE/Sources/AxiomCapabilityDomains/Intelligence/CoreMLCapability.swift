import Foundation
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Core ML Capability Configuration

/// Configuration for Core ML capability
public struct CoreMLCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCoreML: Bool
    public let enableModelCaching: Bool
    public let enableBatchPredictions: Bool
    public let enableAsyncPredictions: Bool
    public let maxConcurrentPredictions: Int
    public let modelCacheSize: Int
    public let predictionTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enablePerformanceOptimization: Bool
    public let computeUnits: ComputeUnits
    public let modelFormat: ModelFormat
    public let enableModelCompilation: Bool
    
    public enum ComputeUnits: String, Codable, CaseIterable {
        case cpuOnly = "cpu-only"
        case cpuAndGPU = "cpu-and-gpu"
        case cpuAndNeuralEngine = "cpu-and-neural-engine"
        case all = "all"
    }
    
    public enum ModelFormat: String, Codable, CaseIterable {
        case coreML = "core-ml"
        case onnx = "onnx"
        case tensorFlow = "tensorflow"
        case pytorch = "pytorch"
    }
    
    public init(
        enableCoreML: Bool = true,
        enableModelCaching: Bool = true,
        enableBatchPredictions: Bool = true,
        enableAsyncPredictions: Bool = true,
        maxConcurrentPredictions: Int = 5,
        modelCacheSize: Int = 10,
        predictionTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enablePerformanceOptimization: Bool = true,
        computeUnits: ComputeUnits = .all,
        modelFormat: ModelFormat = .coreML,
        enableModelCompilation: Bool = true
    ) {
        self.enableCoreML = enableCoreML
        self.enableModelCaching = enableModelCaching
        self.enableBatchPredictions = enableBatchPredictions
        self.enableAsyncPredictions = enableAsyncPredictions
        self.maxConcurrentPredictions = maxConcurrentPredictions
        self.modelCacheSize = modelCacheSize
        self.predictionTimeout = predictionTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.computeUnits = computeUnits
        self.modelFormat = modelFormat
        self.enableModelCompilation = enableModelCompilation
    }
    
    public var isValid: Bool {
        maxConcurrentPredictions > 0 &&
        modelCacheSize > 0 &&
        predictionTimeout > 0
    }
    
    public func merged(with other: CoreMLCapabilityConfiguration) -> CoreMLCapabilityConfiguration {
        CoreMLCapabilityConfiguration(
            enableCoreML: other.enableCoreML,
            enableModelCaching: other.enableModelCaching,
            enableBatchPredictions: other.enableBatchPredictions,
            enableAsyncPredictions: other.enableAsyncPredictions,
            maxConcurrentPredictions: other.maxConcurrentPredictions,
            modelCacheSize: other.modelCacheSize,
            predictionTimeout: other.predictionTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            computeUnits: other.computeUnits,
            modelFormat: other.modelFormat,
            enableModelCompilation: other.enableModelCompilation
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CoreMLCapabilityConfiguration {
        var adjustedTimeout = predictionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentPredictions = maxConcurrentPredictions
        var adjustedComputeUnits = computeUnits
        var adjustedCacheSize = modelCacheSize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(predictionTimeout, 15.0)
            adjustedConcurrentPredictions = min(maxConcurrentPredictions, 2)
            adjustedComputeUnits = .cpuOnly
            adjustedCacheSize = min(modelCacheSize, 3)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return CoreMLCapabilityConfiguration(
            enableCoreML: enableCoreML,
            enableModelCaching: enableModelCaching,
            enableBatchPredictions: enableBatchPredictions,
            enableAsyncPredictions: enableAsyncPredictions,
            maxConcurrentPredictions: adjustedConcurrentPredictions,
            modelCacheSize: adjustedCacheSize,
            predictionTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enablePerformanceOptimization: enablePerformanceOptimization,
            computeUnits: adjustedComputeUnits,
            modelFormat: modelFormat,
            enableModelCompilation: enableModelCompilation
        )
    }
}

// MARK: - Core ML Types

/// ML Model information
public struct MLModelInfo: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let version: String?
    public let description: String?
    public let author: String?
    public let license: String?
    public let size: Int64
    public let modelType: ModelType
    public let inputDescription: MLFeatureDescription
    public let outputDescription: MLFeatureDescription
    public let creationDate: Date
    public let lastUsed: Date?
    public let usageCount: Int
    public let isLoaded: Bool
    public let compilationState: CompilationState
    
    public enum ModelType: String, Sendable, Codable, CaseIterable {
        case classifier = "classifier"
        case regressor = "regressor"
        case neuralNetwork = "neural-network"
        case pipeline = "pipeline"
        case transformer = "transformer"
        case unknown = "unknown"
    }
    
    public enum CompilationState: String, Sendable, Codable, CaseIterable {
        case notCompiled = "not-compiled"
        case compiling = "compiling"
        case compiled = "compiled"
        case failed = "failed"
    }
    
    public struct MLFeatureDescription: Sendable, Codable {
        public let features: [MLFeature]
        
        public struct MLFeature: Sendable, Codable {
            public let name: String
            public let type: FeatureType
            public let isOptional: Bool
            public let constraint: FeatureConstraint?
            
            public enum FeatureType: String, Sendable, Codable, CaseIterable {
                case invalid = "invalid"
                case int64 = "int64"
                case double = "double"
                case string = "string"
                case image = "image"
                case multiArray = "multi-array"
                case dictionary = "dictionary"
                case sequence = "sequence"
            }
            
            public struct FeatureConstraint: Sendable, Codable {
                public let allowedValues: [String]?
                public let allowedSet: Set<String>?
                public let enumeratedInts: [Int]?
                public let sizeConstraint: SizeConstraint?
                
                public struct SizeConstraint: Sendable, Codable {
                    public let enumeratedShapes: [[Int]]?
                    public let shapeFlexibility: [ShapeFlexibility]?
                    
                    public enum ShapeFlexibility: String, Sendable, Codable, CaseIterable {
                        case enumerated = "enumerated"
                        case range = "range"
                        case variable = "variable"
                    }
                    
                    public init(enumeratedShapes: [[Int]]? = nil, shapeFlexibility: [ShapeFlexibility]? = nil) {
                        self.enumeratedShapes = enumeratedShapes
                        self.shapeFlexibility = shapeFlexibility
                    }
                }
                
                public init(allowedValues: [String]? = nil, allowedSet: Set<String>? = nil, enumeratedInts: [Int]? = nil, sizeConstraint: SizeConstraint? = nil) {
                    self.allowedValues = allowedValues
                    self.allowedSet = allowedSet
                    self.enumeratedInts = enumeratedInts
                    self.sizeConstraint = sizeConstraint
                }
            }
            
            public init(name: String, type: FeatureType, isOptional: Bool = false, constraint: FeatureConstraint? = nil) {
                self.name = name
                self.type = type
                self.isOptional = isOptional
                self.constraint = constraint
            }
        }
        
        public init(features: [MLFeature]) {
            self.features = features
        }
    }
    
    public init(
        name: String,
        version: String? = nil,
        description: String? = nil,
        author: String? = nil,
        license: String? = nil,
        size: Int64,
        modelType: ModelType,
        inputDescription: MLFeatureDescription,
        outputDescription: MLFeatureDescription,
        lastUsed: Date? = nil,
        usageCount: Int = 0,
        isLoaded: Bool = false,
        compilationState: CompilationState = .notCompiled
    ) {
        self.id = UUID()
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.license = license
        self.size = size
        self.modelType = modelType
        self.inputDescription = inputDescription
        self.outputDescription = outputDescription
        self.creationDate = Date()
        self.lastUsed = lastUsed
        self.usageCount = usageCount
        self.isLoaded = isLoaded
        self.compilationState = compilationState
    }
}

/// ML Prediction request
public struct MLPredictionRequest: Sendable, Identifiable {
    public let id: UUID
    public let modelName: String
    public let input: MLFeatureProvider
    public let options: PredictionOptions
    public let priority: Priority
    public let timeout: TimeInterval?
    public let metadata: [String: String]
    
    public struct PredictionOptions: Sendable {
        public let usesCPUOnly: Bool
        public let automaticOutputBackingMode: Bool
        public let batchSize: Int?
        public let computeUnits: CoreMLCapabilityConfiguration.ComputeUnits?
        
        public init(usesCPUOnly: Bool = false, automaticOutputBackingMode: Bool = true, batchSize: Int? = nil, computeUnits: CoreMLCapabilityConfiguration.ComputeUnits? = nil) {
            self.usesCPUOnly = usesCPUOnly
            self.automaticOutputBackingMode = automaticOutputBackingMode
            self.batchSize = batchSize
            self.computeUnits = computeUnits
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        modelName: String,
        input: MLFeatureProvider,
        options: PredictionOptions = PredictionOptions(),
        priority: Priority = .normal,
        timeout: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.modelName = modelName
        self.input = input
        self.options = options
        self.priority = priority
        self.timeout = timeout
        self.metadata = metadata
    }
}

/// ML Prediction result
public struct MLPredictionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let modelName: String
    public let output: MLFeatureProvider?
    public let confidence: Double?
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: CoreMLError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(
        requestId: UUID,
        modelName: String,
        output: MLFeatureProvider? = nil,
        confidence: Double? = nil,
        processingTime: TimeInterval,
        success: Bool,
        error: CoreMLError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.modelName = modelName
        self.output = output
        self.confidence = confidence
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Core ML metrics
public struct CoreMLMetrics: Sendable {
    public let totalPredictions: Int
    public let successfulPredictions: Int
    public let failedPredictions: Int
    public let averageProcessingTime: TimeInterval
    public let totalProcessingTime: TimeInterval
    public let predictionsByModel: [String: Int]
    public let errorsByType: [String: Int]
    public let modelsLoaded: Int
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    
    public init(
        totalPredictions: Int = 0,
        successfulPredictions: Int = 0,
        failedPredictions: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        totalProcessingTime: TimeInterval = 0,
        predictionsByModel: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        modelsLoaded: Int = 0,
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0
    ) {
        self.totalPredictions = totalPredictions
        self.successfulPredictions = successfulPredictions
        self.failedPredictions = failedPredictions
        self.averageProcessingTime = averageProcessingTime
        self.totalProcessingTime = totalProcessingTime
        self.predictionsByModel = predictionsByModel
        self.errorsByType = errorsByType
        self.modelsLoaded = modelsLoaded
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = totalProcessingTime > 0 ? Double(totalPredictions) / totalProcessingTime : 0
    }
    
    public var successRate: Double {
        totalPredictions > 0 ? Double(successfulPredictions) / Double(totalPredictions) : 0
    }
}

// MARK: - Core ML Resource

/// Core ML resource management
@available(iOS 11.0, macOS 10.13, watchOS 4.0, tvOS 11.0, *)
public actor CoreMLCapabilityResource: AxiomCapabilityResource {
    private let configuration: CoreMLCapabilityConfiguration
    private var loadedModels: [String: MLModel] = [:]
    private var modelInfos: [String: MLModelInfo] = [:]
    private var predictionQueue: [MLPredictionRequest] = []
    private var activePredictions: [UUID: MLPredictionRequest] = [:]
    private var predictionHistory: [MLPredictionResult] = []
    private var metrics: CoreMLMetrics = CoreMLMetrics()
    private var predictionStreamContinuation: AsyncStream<MLPredictionResult>.Continuation?
    private var modelStreamContinuation: AsyncStream<MLModelInfo>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: CoreMLCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 100_000_000, // 100MB for model storage and inference
            cpu: 4.0, // High CPU usage for ML inference
            bandwidth: 0,
            storage: 500_000_000 // 500MB for cached models
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let modelMemory = loadedModels.count * 20_000_000 // ~20MB per model
            let queueMemory = predictionQueue.count * 10_000
            let historyMemory = predictionHistory.count * 5_000
            
            return ResourceUsage(
                memory: modelMemory + queueMemory + historyMemory + 10_000_000,
                cpu: activePredictions.isEmpty ? 0.2 : 3.0,
                bandwidth: 0,
                storage: loadedModels.count * 50_000_000 // ~50MB per cached model
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Core ML is available on iOS 11+, macOS 10.13+, watchOS 4+, tvOS 11+
        if #available(iOS 11.0, macOS 10.13, watchOS 4.0, tvOS 11.0, *) {
            return configuration.enableCoreML
        }
        return false
    }
    
    public func release() async {
        loadedModels.removeAll()
        modelInfos.removeAll()
        predictionQueue.removeAll()
        activePredictions.removeAll()
        predictionHistory.removeAll()
        
        predictionStreamContinuation?.finish()
        modelStreamContinuation?.finish()
        
        metrics = CoreMLMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Core ML subsystem
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
    }
    
    internal func updateConfiguration(_ configuration: CoreMLCapabilityConfiguration) async throws {
        // Configuration updates for Core ML
    }
    
    // MARK: - Prediction Streams
    
    public var predictionStream: AsyncStream<MLPredictionResult> {
        AsyncStream { continuation in
            self.predictionStreamContinuation = continuation
        }
    }
    
    public var modelStream: AsyncStream<MLModelInfo> {
        AsyncStream { continuation in
            self.modelStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadModel(from url: URL, name: String) async throws -> MLModelInfo {
        guard configuration.enableCoreML else {
            throw CoreMLError.coreMLDisabled
        }
        
        // Check if model is already loaded
        if let existingInfo = modelInfos[name] {
            return existingInfo
        }
        
        let startTime = Date()
        
        do {
            let compiledURL: URL
            
            if configuration.enableModelCompilation {
                compiledURL = try MLModel.compileModel(at: url)
            } else {
                compiledURL = url
            }
            
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            let modelInfo = createModelInfo(from: mlModel, name: name, url: url)
            
            // Store in cache if enabled
            if configuration.enableModelCaching && loadedModels.count < configuration.modelCacheSize {
                loadedModels[name] = mlModel
                var updatedInfo = modelInfo
                updatedInfo = MLModelInfo(
                    name: modelInfo.name,
                    version: modelInfo.version,
                    description: modelInfo.description,
                    author: modelInfo.author,
                    license: modelInfo.license,
                    size: modelInfo.size,
                    modelType: modelInfo.modelType,
                    inputDescription: modelInfo.inputDescription,
                    outputDescription: modelInfo.outputDescription,
                    lastUsed: modelInfo.lastUsed,
                    usageCount: modelInfo.usageCount,
                    isLoaded: true,
                    compilationState: .compiled
                )
                modelInfos[name] = updatedInfo
                modelStreamContinuation?.yield(updatedInfo)
            } else {
                modelInfos[name] = modelInfo
                modelStreamContinuation?.yield(modelInfo)
            }
            
            await updateModelMetrics()
            
            if configuration.enableLogging {
                let loadTime = Date().timeIntervalSince(startTime)
                await logModel(modelInfo, action: "Loaded", duration: loadTime)
            }
            
            return modelInfos[name]!
            
        } catch {
            throw CoreMLError.modelLoadFailed(name, error.localizedDescription)
        }
    }
    
    public func unloadModel(_ name: String) async {
        loadedModels.removeValue(forKey: name)
        
        if var modelInfo = modelInfos[name] {
            modelInfo = MLModelInfo(
                name: modelInfo.name,
                version: modelInfo.version,
                description: modelInfo.description,
                author: modelInfo.author,
                license: modelInfo.license,
                size: modelInfo.size,
                modelType: modelInfo.modelType,
                inputDescription: modelInfo.inputDescription,
                outputDescription: modelInfo.outputDescription,
                lastUsed: modelInfo.lastUsed,
                usageCount: modelInfo.usageCount,
                isLoaded: false,
                compilationState: modelInfo.compilationState
            )
            modelInfos[name] = modelInfo
            modelStreamContinuation?.yield(modelInfo)
        }
        
        if configuration.enableLogging {
            print("[CoreML] 🗑️ Unloaded model: \(name)")
        }
    }
    
    public func getLoadedModels() async -> [MLModelInfo] {
        return modelInfos.values.filter { $0.isLoaded }.map { $0 }
    }
    
    public func getAllModels() async -> [MLModelInfo] {
        return Array(modelInfos.values)
    }
    
    public func getModel(name: String) async -> MLModelInfo? {
        return modelInfos[name]
    }
    
    // MARK: - Prediction
    
    public func predict(_ request: MLPredictionRequest) async throws -> MLPredictionResult {
        guard configuration.enableCoreML else {
            throw CoreMLError.coreMLDisabled
        }
        
        // Check if we're at capacity
        if activePredictions.count >= configuration.maxConcurrentPredictions {
            if configuration.enableAsyncPredictions {
                predictionQueue.append(request)
                throw CoreMLError.predictionQueued(request.id)
            } else {
                throw CoreMLError.tooManyActivePredictions(configuration.maxConcurrentPredictions)
            }
        }
        
        let startTime = Date()
        activePredictions[request.id] = request
        
        do {
            // Get or load the model
            let model = try await getOrLoadModel(request.modelName)
            
            // Configure prediction options
            let options = MLPredictionOptions()
            options.usesCPUOnly = request.options.usesCPUOnly
            
            // Perform prediction
            let output = try model.prediction(from: request.input, options: options)
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MLPredictionResult(
                requestId: request.id,
                modelName: request.modelName,
                output: output,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activePredictions.removeValue(forKey: request.id)
            predictionHistory.append(result)
            
            predictionStreamContinuation?.yield(result)
            
            await updatePredictionMetrics(result)
            await updateModelUsage(request.modelName)
            
            if configuration.enableLogging {
                await logPrediction(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processPredictionQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MLPredictionResult(
                requestId: request.id,
                modelName: request.modelName,
                processingTime: processingTime,
                success: false,
                error: error as? CoreMLError ?? CoreMLError.predictionFailed(request.modelName, error.localizedDescription)
            )
            
            activePredictions.removeValue(forKey: request.id)
            predictionHistory.append(result)
            
            predictionStreamContinuation?.yield(result)
            
            await updatePredictionMetrics(result)
            
            if configuration.enableLogging {
                await logPrediction(result)
            }
            
            throw error
        }
    }
    
    public func batchPredict(_ requests: [MLPredictionRequest]) async throws -> [MLPredictionResult] {
        guard configuration.enableBatchPredictions else {
            throw CoreMLError.batchPredictionsDisabled
        }
        
        var results: [MLPredictionResult] = []
        
        for request in requests {
            do {
                let result = try await predict(request)
                results.append(result)
            } catch {
                let result = MLPredictionResult(
                    requestId: request.id,
                    modelName: request.modelName,
                    processingTime: 0,
                    success: false,
                    error: error as? CoreMLError ?? CoreMLError.predictionFailed(request.modelName, error.localizedDescription)
                )
                results.append(result)
            }
        }
        
        return results
    }
    
    public func cancelPrediction(_ requestId: UUID) async {
        activePredictions.removeValue(forKey: requestId)
        predictionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[CoreML] 🚫 Cancelled prediction: \(requestId)")
        }
    }
    
    public func getActivePredictions() async -> [MLPredictionRequest] {
        return Array(activePredictions.values)
    }
    
    public func getPredictionHistory(since: Date? = nil) async -> [MLPredictionResult] {
        if let since = since {
            return predictionHistory.filter { $0.timestamp >= since }
        }
        return predictionHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> CoreMLMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = CoreMLMetrics()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        // Performance optimization for Core ML
        if configuration.enableLogging {
            print("[CoreML] ⚡ Performance optimization enabled")
        }
    }
    
    private func getOrLoadModel(_ name: String) async throws -> MLModel {
        // Check if model is already loaded
        if let model = loadedModels[name] {
            return model
        }
        
        // Model not loaded, throw error
        throw CoreMLError.modelNotLoaded(name)
    }
    
    private func createModelInfo(from model: MLModel, name: String, url: URL) -> MLModelInfo {
        let modelDescription = model.modelDescription
        
        // Get file size
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        
        // Convert input description
        let inputFeatures = modelDescription.inputDescriptionsByName.map { (key, description) in
            MLModelInfo.MLFeatureDescription.MLFeature(
                name: key,
                type: convertMLFeatureType(description.type),
                isOptional: description.isOptional
            )
        }
        
        let inputDescription = MLModelInfo.MLFeatureDescription(features: Array(inputFeatures))
        
        // Convert output description
        let outputFeatures = modelDescription.outputDescriptionsByName.map { (key, description) in
            MLModelInfo.MLFeatureDescription.MLFeature(
                name: key,
                type: convertMLFeatureType(description.type),
                isOptional: description.isOptional
            )
        }
        
        let outputDescription = MLModelInfo.MLFeatureDescription(features: Array(outputFeatures))
        
        // Determine model type
        let modelType = determineModelType(from: modelDescription)
        
        return MLModelInfo(
            name: name,
            version: modelDescription.metadata[.versionString] as? String,
            description: modelDescription.metadata[.description] as? String,
            author: modelDescription.metadata[.author] as? String,
            license: modelDescription.metadata[.license] as? String,
            size: Int64(fileSize),
            modelType: modelType,
            inputDescription: inputDescription,
            outputDescription: outputDescription,
            compilationState: .compiled
        )
    }
    
    private func convertMLFeatureType(_ type: MLFeatureType) -> MLModelInfo.MLFeatureDescription.MLFeature.FeatureType {
        switch type {
        case .invalid:
            return .invalid
        case .int64:
            return .int64
        case .double:
            return .double
        case .string:
            return .string
        case .image:
            return .image
        case .multiArray:
            return .multiArray
        case .dictionary:
            return .dictionary
        case .sequence:
            return .sequence
        @unknown default:
            return .invalid
        }
    }
    
    private func determineModelType(from description: MLModelDescription) -> MLModelInfo.ModelType {
        // Simple heuristic to determine model type
        let outputFeatures = description.outputDescriptionsByName
        
        if outputFeatures.count == 1 {
            let feature = outputFeatures.values.first!
            if feature.type == .dictionary {
                return .classifier
            } else if feature.type == .double || feature.type == .multiArray {
                return .regressor
            }
        }
        
        return .neuralNetwork
    }
    
    private func processPredictionQueue() async {
        guard !isProcessingQueue && !predictionQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        predictionQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !predictionQueue.isEmpty && activePredictions.count < configuration.maxConcurrentPredictions {
            let request = predictionQueue.removeFirst()
            
            do {
                _ = try await predict(request)
            } catch {
                if configuration.enableLogging {
                    print("[CoreML] ⚠️ Queued prediction failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: MLPredictionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func updateModelMetrics() async {
        let modelsLoaded = loadedModels.count
        
        metrics = CoreMLMetrics(
            totalPredictions: metrics.totalPredictions,
            successfulPredictions: metrics.successfulPredictions,
            failedPredictions: metrics.failedPredictions,
            averageProcessingTime: metrics.averageProcessingTime,
            totalProcessingTime: metrics.totalProcessingTime,
            predictionsByModel: metrics.predictionsByModel,
            errorsByType: metrics.errorsByType,
            modelsLoaded: modelsLoaded,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updatePredictionMetrics(_ result: MLPredictionResult) async {
        let totalPredictions = metrics.totalPredictions + 1
        let successfulPredictions = metrics.successfulPredictions + (result.success ? 1 : 0)
        let failedPredictions = metrics.failedPredictions + (result.success ? 0 : 1)
        let totalProcessingTime = metrics.totalProcessingTime + result.processingTime
        
        let newAverageProcessingTime = totalProcessingTime / Double(totalPredictions)
        
        var predictionsByModel = metrics.predictionsByModel
        predictionsByModel[result.modelName, default: 0] += 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = CoreMLMetrics(
            totalPredictions: totalPredictions,
            successfulPredictions: successfulPredictions,
            failedPredictions: failedPredictions,
            averageProcessingTime: newAverageProcessingTime,
            totalProcessingTime: totalProcessingTime,
            predictionsByModel: predictionsByModel,
            errorsByType: errorsByType,
            modelsLoaded: metrics.modelsLoaded,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateModelUsage(_ modelName: String) async {
        if var modelInfo = modelInfos[modelName] {
            modelInfo = MLModelInfo(
                name: modelInfo.name,
                version: modelInfo.version,
                description: modelInfo.description,
                author: modelInfo.author,
                license: modelInfo.license,
                size: modelInfo.size,
                modelType: modelInfo.modelType,
                inputDescription: modelInfo.inputDescription,
                outputDescription: modelInfo.outputDescription,
                lastUsed: Date(),
                usageCount: modelInfo.usageCount + 1,
                isLoaded: modelInfo.isLoaded,
                compilationState: modelInfo.compilationState
            )
            modelInfos[modelName] = modelInfo
            modelStreamContinuation?.yield(modelInfo)
        }
    }
    
    private func logModel(_ model: MLModelInfo, action: String, duration: TimeInterval? = nil) async {
        let typeIcon = switch model.modelType {
        case .classifier: "🏷️"
        case .regressor: "📊"
        case .neuralNetwork: "🧠"
        case .pipeline: "🔗"
        case .transformer: "🔄"
        case .unknown: "❓"
        }
        
        let sizeStr = ByteCountFormatter.string(fromByteCount: model.size, countStyle: .file)
        let durationStr = duration.map { String(format: " (%.3fs)", $0) } ?? ""
        
        print("[CoreML] \(typeIcon) \(action): \(model.name) - \(sizeStr)\(durationStr)")
    }
    
    private func logPrediction(_ result: MLPredictionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        
        print("[CoreML] \(statusIcon) Prediction: \(result.modelName) (\(timeStr)s)")
        
        if let error = result.error {
            print("[CoreML] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Core ML Capability Implementation

/// Core ML capability providing comprehensive machine learning model execution
@available(iOS 11.0, macOS 10.13, watchOS 4.0, tvOS 11.0, *)
public actor CoreMLCapability: LocalCapability {
    public typealias ConfigurationType = CoreMLCapabilityConfiguration
    public typealias ResourceType = CoreMLCapabilityResource
    
    private var _configuration: CoreMLCapabilityConfiguration
    private var _resources: CoreMLCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "core-ml-capability" }
    
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
    
    public var configuration: CoreMLCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CoreMLCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CoreMLCapabilityConfiguration = CoreMLCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CoreMLCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: CoreMLCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Core ML configuration")
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
        // Core ML is supported on iOS 11+, macOS 10.13+, watchOS 4+, tvOS 11+
        if #available(iOS 11.0, macOS 10.13, watchOS 4.0, tvOS 11.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Core ML doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Core ML Operations
    
    /// Load ML model
    public func loadModel(from url: URL, name: String) async throws -> MLModelInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return try await _resources.loadModel(from: url, name: name)
    }
    
    /// Unload ML model
    public func unloadModel(_ name: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        await _resources.unloadModel(name)
    }
    
    /// Get prediction stream
    public func getPredictionStream() async throws -> AsyncStream<MLPredictionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.predictionStream
    }
    
    /// Get model stream
    public func getModelStream() async throws -> AsyncStream<MLModelInfo> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.modelStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [MLModelInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get all models
    public func getAllModels() async throws -> [MLModelInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getAllModels()
    }
    
    /// Get specific model
    public func getModel(name: String) async throws -> MLModelInfo? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getModel(name: name)
    }
    
    /// Perform prediction
    public func predict(_ request: MLPredictionRequest) async throws -> MLPredictionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return try await _resources.predict(request)
    }
    
    /// Perform batch predictions
    public func batchPredict(_ requests: [MLPredictionRequest]) async throws -> [MLPredictionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return try await _resources.batchPredict(requests)
    }
    
    /// Cancel prediction
    public func cancelPrediction(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        await _resources.cancelPrediction(requestId)
    }
    
    /// Get active predictions
    public func getActivePredictions() async throws -> [MLPredictionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getActivePredictions()
    }
    
    /// Get prediction history
    public func getPredictionHistory(since: Date? = nil) async throws -> [MLPredictionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getPredictionHistory(since: since)
    }
    
    /// Get Core ML metrics
    public func getMetrics() async throws -> CoreMLMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core ML capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if model is loaded
    public func isModelLoaded(_ name: String) async throws -> Bool {
        let models = try await getLoadedModels()
        return models.contains { $0.name == name }
    }
    
    /// Get model count
    public func getModelCount() async throws -> Int {
        let models = try await getAllModels()
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

/// Core ML specific errors
public enum CoreMLError: Error, LocalizedError {
    case coreMLDisabled
    case modelLoadFailed(String, String)
    case modelNotLoaded(String)
    case predictionFailed(String, String)
    case invalidInput(String)
    case invalidOutput(String)
    case tooManyActivePredictions(Int)
    case predictionTimeout(String)
    case predictionQueued(UUID)
    case batchPredictionsDisabled
    case unsupportedModelFormat(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .coreMLDisabled:
            return "Core ML is disabled"
        case .modelLoadFailed(let name, let reason):
            return "Failed to load model '\(name)': \(reason)"
        case .modelNotLoaded(let name):
            return "Model not loaded: \(name)"
        case .predictionFailed(let model, let reason):
            return "Prediction failed for model '\(model)': \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .invalidOutput(let reason):
            return "Invalid output: \(reason)"
        case .tooManyActivePredictions(let maxPredictions):
            return "Too many active predictions (max: \(maxPredictions))"
        case .predictionTimeout(let model):
            return "Prediction timeout for model: \(model)"
        case .predictionQueued(let id):
            return "Prediction queued: \(id)"
        case .batchPredictionsDisabled:
            return "Batch predictions are disabled"
        case .unsupportedModelFormat(let format):
            return "Unsupported model format: \(format)"
        case .configurationError(let reason):
            return "Core ML configuration error: \(reason)"
        }
    }
}