import Foundation
import CoreML
import CreateML
import AxiomCore
import AxiomCapabilities

// MARK: - Predictive Analytics Capability Configuration

/// Configuration for Predictive Analytics capability
public struct PredictiveAnalyticsCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enablePredictiveAnalytics: Bool
    public let enableTimeSeriesForecasting: Bool
    public let enableAnomalyDetection: Bool
    public let enableClassification: Bool
    public let enableRegression: Bool
    public let enableClustering: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentAnalyses: Int
    public let analysisTimeout: TimeInterval
    public let maxDataPoints: Int
    public let minDataPoints: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let defaultModelType: ModelType
    public let confidenceThreshold: Float
    public let enableAutoModelSelection: Bool
    
    public enum ModelType: String, Codable, CaseIterable {
        case linearRegression = "linear-regression"
        case polynomialRegression = "polynomial-regression"
        case randomForest = "random-forest"
        case neuralNetwork = "neural-network"
        case svm = "svm"
        case kMeans = "k-means"
        case arima = "arima"
        case lstm = "lstm"
    }
    
    public init(
        enablePredictiveAnalytics: Bool = true,
        enableTimeSeriesForecasting: Bool = true,
        enableAnomalyDetection: Bool = true,
        enableClassification: Bool = true,
        enableRegression: Bool = true,
        enableClustering: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentAnalyses: Int = 5,
        analysisTimeout: TimeInterval = 120.0,
        maxDataPoints: Int = 100000,
        minDataPoints: Int = 10,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 50,
        enablePerformanceOptimization: Bool = true,
        defaultModelType: ModelType = .randomForest,
        confidenceThreshold: Float = 0.7,
        enableAutoModelSelection: Bool = true
    ) {
        self.enablePredictiveAnalytics = enablePredictiveAnalytics
        self.enableTimeSeriesForecasting = enableTimeSeriesForecasting
        self.enableAnomalyDetection = enableAnomalyDetection
        self.enableClassification = enableClassification
        self.enableRegression = enableRegression
        self.enableClustering = enableClustering
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentAnalyses = maxConcurrentAnalyses
        self.analysisTimeout = analysisTimeout
        self.maxDataPoints = maxDataPoints
        self.minDataPoints = minDataPoints
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.defaultModelType = defaultModelType
        self.confidenceThreshold = confidenceThreshold
        self.enableAutoModelSelection = enableAutoModelSelection
    }
    
    public var isValid: Bool {
        maxConcurrentAnalyses > 0 &&
        analysisTimeout > 0 &&
        maxDataPoints > minDataPoints &&
        minDataPoints > 0 &&
        confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: PredictiveAnalyticsCapabilityConfiguration) -> PredictiveAnalyticsCapabilityConfiguration {
        PredictiveAnalyticsCapabilityConfiguration(
            enablePredictiveAnalytics: other.enablePredictiveAnalytics,
            enableTimeSeriesForecasting: other.enableTimeSeriesForecasting,
            enableAnomalyDetection: other.enableAnomalyDetection,
            enableClassification: other.enableClassification,
            enableRegression: other.enableRegression,
            enableClustering: other.enableClustering,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentAnalyses: other.maxConcurrentAnalyses,
            analysisTimeout: other.analysisTimeout,
            maxDataPoints: other.maxDataPoints,
            minDataPoints: other.minDataPoints,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            defaultModelType: other.defaultModelType,
            confidenceThreshold: other.confidenceThreshold,
            enableAutoModelSelection: other.enableAutoModelSelection
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> PredictiveAnalyticsCapabilityConfiguration {
        var adjustedTimeout = analysisTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAnalyses = maxConcurrentAnalyses
        var adjustedCacheSize = cacheSize
        var adjustedMaxDataPoints = maxDataPoints
        var adjustedModelType = defaultModelType
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(analysisTimeout, 60.0)
            adjustedConcurrentAnalyses = min(maxConcurrentAnalyses, 2)
            adjustedCacheSize = min(cacheSize, 10)
            adjustedMaxDataPoints = min(maxDataPoints, 10000)
            adjustedModelType = .linearRegression // Use simpler model in low power mode
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return PredictiveAnalyticsCapabilityConfiguration(
            enablePredictiveAnalytics: enablePredictiveAnalytics,
            enableTimeSeriesForecasting: enableTimeSeriesForecasting,
            enableAnomalyDetection: enableAnomalyDetection,
            enableClassification: enableClassification,
            enableRegression: enableRegression,
            enableClustering: enableClustering,
            enableCustomModels: enableCustomModels,
            maxConcurrentAnalyses: adjustedConcurrentAnalyses,
            analysisTimeout: adjustedTimeout,
            maxDataPoints: adjustedMaxDataPoints,
            minDataPoints: minDataPoints,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            defaultModelType: adjustedModelType,
            confidenceThreshold: confidenceThreshold,
            enableAutoModelSelection: enableAutoModelSelection
        )
    }
}

// MARK: - Predictive Analytics Types

/// Predictive analytics request
public struct PredictiveAnalyticsRequest: Sendable, Identifiable {
    public let id: UUID
    public let data: AnalyticsData
    public let analysisType: AnalysisType
    public let options: AnalysisOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public enum AnalysisType: String, Sendable, CaseIterable {
        case forecast = "forecast"
        case classification = "classification"
        case regression = "regression"
        case clustering = "clustering"
        case anomalyDetection = "anomaly-detection"
        case patternRecognition = "pattern-recognition"
        case trendAnalysis = "trend-analysis"
    }
    
    public struct AnalyticsData: Sendable {
        public let features: [[Double]]
        public let targets: [Double]?
        public let timestamps: [Date]?
        public let featureNames: [String]
        public let dataType: DataType
        
        public enum DataType: String, Sendable, CaseIterable {
            case timeSeries = "time-series"
            case categorical = "categorical"
            case numerical = "numerical"
            case mixed = "mixed"
        }
        
        public init(
            features: [[Double]],
            targets: [Double]? = nil,
            timestamps: [Date]? = nil,
            featureNames: [String],
            dataType: DataType = .numerical
        ) {
            self.features = features
            self.targets = targets
            self.timestamps = timestamps
            self.featureNames = featureNames
            self.dataType = dataType
        }
    }
    
    public struct AnalysisOptions: Sendable {
        public let modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType?
        public let forecastHorizon: Int
        public let confidenceLevel: Float
        public let enableFeatureImportance: Bool
        public let enableCrossValidation: Bool
        public let customModelId: String?
        public let hyperParameters: [String: Double]
        public let validationSplit: Float
        public let enableEnsembleMethods: Bool
        
        public init(
            modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType? = nil,
            forecastHorizon: Int = 10,
            confidenceLevel: Float = 0.95,
            enableFeatureImportance: Bool = true,
            enableCrossValidation: Bool = true,
            customModelId: String? = nil,
            hyperParameters: [String: Double] = [:],
            validationSplit: Float = 0.2,
            enableEnsembleMethods: Bool = false
        ) {
            self.modelType = modelType
            self.forecastHorizon = forecastHorizon
            self.confidenceLevel = confidenceLevel
            self.enableFeatureImportance = enableFeatureImportance
            self.enableCrossValidation = enableCrossValidation
            self.customModelId = customModelId
            self.hyperParameters = hyperParameters
            self.validationSplit = validationSplit
            self.enableEnsembleMethods = enableEnsembleMethods
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        data: AnalyticsData,
        analysisType: AnalysisType,
        options: AnalysisOptions = AnalysisOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.data = data
        self.analysisType = analysisType
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Predictive analytics result
public struct PredictiveAnalyticsResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let analysisType: PredictiveAnalyticsRequest.AnalysisType
    public let predictions: [Prediction]
    public let modelMetrics: ModelMetrics
    public let featureImportance: [FeatureImportance]
    public let anomalies: [Anomaly]
    public let insights: [Insight]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: PredictiveAnalyticsError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct Prediction: Sendable {
        public let value: Double
        public let confidence: Float
        public let confidenceInterval: ConfidenceInterval?
        public let timestamp: Date?
        public let category: String?
        public let probability: Float?
        
        public struct ConfidenceInterval: Sendable {
            public let lower: Double
            public let upper: Double
            public let level: Float
            
            public init(lower: Double, upper: Double, level: Float) {
                self.lower = lower
                self.upper = upper
                self.level = level
            }
        }
        
        public init(
            value: Double,
            confidence: Float,
            confidenceInterval: ConfidenceInterval? = nil,
            timestamp: Date? = nil,
            category: String? = nil,
            probability: Float? = nil
        ) {
            self.value = value
            self.confidence = confidence
            self.confidenceInterval = confidenceInterval
            self.timestamp = timestamp
            self.category = category
            self.probability = probability
        }
    }
    
    public struct ModelMetrics: Sendable {
        public let modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType
        public let accuracy: Float?
        public let precision: Float?
        public let recall: Float?
        public let f1Score: Float?
        public let rmse: Float?
        public let mae: Float?
        public let r2Score: Float?
        public let crossValidationScore: Float?
        public let trainingTime: TimeInterval
        public let modelSize: Int
        
        public init(
            modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType,
            accuracy: Float? = nil,
            precision: Float? = nil,
            recall: Float? = nil,
            f1Score: Float? = nil,
            rmse: Float? = nil,
            mae: Float? = nil,
            r2Score: Float? = nil,
            crossValidationScore: Float? = nil,
            trainingTime: TimeInterval,
            modelSize: Int
        ) {
            self.modelType = modelType
            self.accuracy = accuracy
            self.precision = precision
            self.recall = recall
            self.f1Score = f1Score
            self.rmse = rmse
            self.mae = mae
            self.r2Score = r2Score
            self.crossValidationScore = crossValidationScore
            self.trainingTime = trainingTime
            self.modelSize = modelSize
        }
    }
    
    public struct FeatureImportance: Sendable {
        public let featureName: String
        public let importance: Float
        public let rank: Int
        public let description: String?
        
        public init(featureName: String, importance: Float, rank: Int, description: String? = nil) {
            self.featureName = featureName
            self.importance = importance
            self.rank = rank
            self.description = description
        }
    }
    
    public struct Anomaly: Sendable {
        public let index: Int
        public let value: Double
        public let severity: Severity
        public let confidence: Float
        public let timestamp: Date?
        public let explanation: String?
        
        public enum Severity: String, Sendable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
        }
        
        public init(index: Int, value: Double, severity: Severity, confidence: Float, timestamp: Date? = nil, explanation: String? = nil) {
            self.index = index
            self.value = value
            self.severity = severity
            self.confidence = confidence
            self.timestamp = timestamp
            self.explanation = explanation
        }
    }
    
    public struct Insight: Sendable {
        public let type: InsightType
        public let description: String
        public let confidence: Float
        public let supportingData: [String: Double]
        public let recommendations: [String]
        
        public enum InsightType: String, Sendable, CaseIterable {
            case trend = "trend"
            case seasonality = "seasonality"
            case correlation = "correlation"
            case outlier = "outlier"
            case pattern = "pattern"
            case prediction = "prediction"
        }
        
        public init(type: InsightType, description: String, confidence: Float, supportingData: [String: Double] = [:], recommendations: [String] = []) {
            self.type = type
            self.description = description
            self.confidence = confidence
            self.supportingData = supportingData
            self.recommendations = recommendations
        }
    }
    
    public init(
        requestId: UUID,
        analysisType: PredictiveAnalyticsRequest.AnalysisType,
        predictions: [Prediction],
        modelMetrics: ModelMetrics,
        featureImportance: [FeatureImportance] = [],
        anomalies: [Anomaly] = [],
        insights: [Insight] = [],
        processingTime: TimeInterval,
        success: Bool,
        error: PredictiveAnalyticsError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.analysisType = analysisType
        self.predictions = predictions
        self.modelMetrics = modelMetrics
        self.featureImportance = featureImportance
        self.anomalies = anomalies
        self.insights = insights
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var averageConfidence: Float {
        guard !predictions.isEmpty else { return 0.0 }
        return predictions.reduce(0) { $0 + $1.confidence } / Float(predictions.count)
    }
    
    public var highConfidencePredictions: [Prediction] {
        predictions.filter { $0.confidence >= 0.8 }
    }
    
    public var criticalAnomalies: [Anomaly] {
        anomalies.filter { $0.severity == .critical || $0.severity == .high }
    }
}

/// Predictive analytics metrics
public struct PredictiveAnalyticsMetrics: Sendable {
    public let totalAnalyses: Int
    public let successfulAnalyses: Int
    public let failedAnalyses: Int
    public let averageProcessingTime: TimeInterval
    public let analysesByType: [String: Int]
    public let analysesByModel: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageAccuracy: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    public let modelPerformanceStats: ModelPerformanceStats
    
    public struct ModelPerformanceStats: Sendable {
        public let totalModelsTrained: Int
        public let averageTrainingTime: TimeInterval
        public let bestPerformingModel: String?
        public let averageModelSize: Double
        public let anomaliesDetected: Int
        
        public init(totalModelsTrained: Int = 0, averageTrainingTime: TimeInterval = 0, bestPerformingModel: String? = nil, averageModelSize: Double = 0, anomaliesDetected: Int = 0) {
            self.totalModelsTrained = totalModelsTrained
            self.averageTrainingTime = averageTrainingTime
            self.bestPerformingModel = bestPerformingModel
            self.averageModelSize = averageModelSize
            self.anomaliesDetected = anomaliesDetected
        }
    }
    
    public init(
        totalAnalyses: Int = 0,
        successfulAnalyses: Int = 0,
        failedAnalyses: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        analysesByType: [String: Int] = [:],
        analysesByModel: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageAccuracy: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0,
        modelPerformanceStats: ModelPerformanceStats = ModelPerformanceStats()
    ) {
        self.totalAnalyses = totalAnalyses
        self.successfulAnalyses = successfulAnalyses
        self.failedAnalyses = failedAnalyses
        self.averageProcessingTime = averageProcessingTime
        self.analysesByType = analysesByType
        self.analysesByModel = analysesByModel
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageAccuracy = averageAccuracy
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalAnalyses) / averageProcessingTime : 0
        self.modelPerformanceStats = modelPerformanceStats
    }
    
    public var successRate: Double {
        totalAnalyses > 0 ? Double(successfulAnalyses) / Double(totalAnalyses) : 0
    }
}

// MARK: - Predictive Analytics Resource

/// Predictive analytics resource management
@available(iOS 13.0, macOS 10.15, *)
public actor PredictiveAnalyticsCapabilityResource: AxiomCapabilityResource {
    private let configuration: PredictiveAnalyticsCapabilityConfiguration
    private var activeAnalyses: [UUID: PredictiveAnalyticsRequest] = [:]
    private var analysisQueue: [PredictiveAnalyticsRequest] = []
    private var analysisHistory: [PredictiveAnalyticsResult] = []
    private var resultCache: [String: PredictiveAnalyticsResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var trainedModels: [String: MLModel] = [:]
    private var metrics: PredictiveAnalyticsMetrics = PredictiveAnalyticsMetrics()
    private var resultStreamContinuation: AsyncStream<PredictiveAnalyticsResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: PredictiveAnalyticsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 500_000_000, // 500MB for predictive analytics
            cpu: 5.0, // Very high CPU usage for ML training
            bandwidth: 0,
            storage: 200_000_000 // 200MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let analysisMemory = activeAnalyses.count * 50_000_000 // ~50MB per active analysis
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let modelMemory = (customModels.count + trainedModels.count) * 100_000_000 // ~100MB per loaded model
            let historyMemory = analysisHistory.count * 20_000
            
            return ResourceUsage(
                memory: analysisMemory + cacheMemory + modelMemory + historyMemory + 50_000_000,
                cpu: activeAnalyses.isEmpty ? 0.3 : 4.5,
                bandwidth: 0,
                storage: resultCache.count * 50_000 + (customModels.count + trainedModels.count) * 250_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Predictive analytics is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enablePredictiveAnalytics
        }
        return false
    }
    
    public func release() async {
        activeAnalyses.removeAll()
        analysisQueue.removeAll()
        analysisHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        trainedModels.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = PredictiveAnalyticsMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[PredictiveAnalytics] 🚀 Predictive Analytics capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: PredictiveAnalyticsCapabilityConfiguration) async throws {
        // Update predictive analytics configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<PredictiveAnalyticsResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw PredictiveAnalyticsError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[PredictiveAnalytics] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw PredictiveAnalyticsError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[PredictiveAnalytics] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys) + Array(trainedModels.keys)
    }
    
    // MARK: - Predictive Analytics
    
    public func performAnalysis(_ request: PredictiveAnalyticsRequest) async throws -> PredictiveAnalyticsResult {
        guard configuration.enablePredictiveAnalytics else {
            throw PredictiveAnalyticsError.predictiveAnalyticsDisabled
        }
        
        // Validate data
        guard request.data.features.count >= configuration.minDataPoints else {
            throw PredictiveAnalyticsError.insufficientData
        }
        guard request.data.features.count <= configuration.maxDataPoints else {
            throw PredictiveAnalyticsError.tooMuchData
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
        if activeAnalyses.count >= configuration.maxConcurrentAnalyses {
            analysisQueue.append(request)
            throw PredictiveAnalyticsError.analysisQueued(request.id)
        }
        
        let startTime = Date()
        activeAnalyses[request.id] = request
        
        do {
            // Perform analysis
            let result = try await performPredictiveAnalysis(
                request: request,
                startTime: startTime
            )
            
            activeAnalyses.removeValue(forKey: request.id)
            analysisHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logAnalysis(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processAnalysisQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = PredictiveAnalyticsResult(
                requestId: request.id,
                analysisType: request.analysisType,
                predictions: [],
                modelMetrics: PredictiveAnalyticsResult.ModelMetrics(
                    modelType: configuration.defaultModelType,
                    trainingTime: 0,
                    modelSize: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? PredictiveAnalyticsError ?? PredictiveAnalyticsError.analysisError(error.localizedDescription)
            )
            
            activeAnalyses.removeValue(forKey: request.id)
            analysisHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logAnalysis(result)
            }
            
            throw error
        }
    }
    
    public func cancelAnalysis(_ requestId: UUID) async {
        activeAnalyses.removeValue(forKey: requestId)
        analysisQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[PredictiveAnalytics] 🚫 Cancelled analysis: \(requestId)")
        }
    }
    
    public func getActiveAnalyses() async -> [PredictiveAnalyticsRequest] {
        return Array(activeAnalyses.values)
    }
    
    public func getAnalysisHistory(since: Date? = nil) async -> [PredictiveAnalyticsResult] {
        if let since = since {
            return analysisHistory.filter { $0.timestamp >= since }
        }
        return analysisHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> PredictiveAnalyticsMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = PredictiveAnalyticsMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[PredictiveAnalytics] ⚡ Performance optimization enabled")
        }
    }
    
    private func performPredictiveAnalysis(
        request: PredictiveAnalyticsRequest,
        startTime: Date
    ) async throws -> PredictiveAnalyticsResult {
        
        // Select model type
        let modelType = selectModelType(for: request)
        
        // Train or use existing model
        let model = try await getOrTrainModel(for: request, modelType: modelType)
        
        // Perform analysis based on type
        let analysisResult = try await executeAnalysis(
            request: request,
            model: model,
            modelType: modelType
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return PredictiveAnalyticsResult(
            requestId: request.id,
            analysisType: request.analysisType,
            predictions: analysisResult.predictions,
            modelMetrics: analysisResult.modelMetrics,
            featureImportance: analysisResult.featureImportance,
            anomalies: analysisResult.anomalies,
            insights: analysisResult.insights,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func selectModelType(for request: PredictiveAnalyticsRequest) -> PredictiveAnalyticsCapabilityConfiguration.ModelType {
        if let specifiedType = request.options.modelType {
            return specifiedType
        }
        
        if configuration.enableAutoModelSelection {
            // Auto-select based on analysis type and data characteristics
            return switch request.analysisType {
            case .forecast:
                request.data.dataType == .timeSeries ? .lstm : .arima
            case .classification:
                .randomForest
            case .regression:
                .linearRegression
            case .clustering:
                .kMeans
            case .anomalyDetection:
                .randomForest
            case .patternRecognition, .trendAnalysis:
                .neuralNetwork
            }
        }
        
        return configuration.defaultModelType
    }
    
    private func getOrTrainModel(
        for request: PredictiveAnalyticsRequest,
        modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType
    ) async throws -> MLModel {
        
        // Check if custom model is specified
        if let customModelId = request.options.customModelId,
           let customModel = customModels[customModelId] {
            return customModel
        }
        
        // Check if we have a trained model for this configuration
        let modelKey = generateModelKey(for: request, modelType: modelType)
        if let existingModel = trainedModels[modelKey] {
            return existingModel
        }
        
        // Train a new model
        return try await trainModel(for: request, modelType: modelType, modelKey: modelKey)
    }
    
    private func trainModel(
        for request: PredictiveAnalyticsRequest,
        modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType,
        modelKey: String
    ) async throws -> MLModel {
        
        // Simplified model training simulation
        // In a real implementation, this would use CreateML or other ML frameworks
        
        if configuration.enableLogging {
            print("[PredictiveAnalytics] 🎯 Training \(modelType.rawValue) model")
        }
        
        // Simulate training time
        let trainingDelay = switch modelType {
        case .linearRegression: 0.5
        case .polynomialRegression: 1.0
        case .randomForest: 2.0
        case .neuralNetwork: 5.0
        case .svm: 3.0
        case .kMeans: 1.5
        case .arima: 2.5
        case .lstm: 8.0
        }
        
        try await Task.sleep(nanoseconds: UInt64(trainingDelay * 1_000_000_000))
        
        // Create a dummy ML model (in real implementation, use CreateML)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mlmodel")
        
        // For simulation, we'll create a simple model structure
        // In reality, this would be a proper trained ML model
        let dummyModel = try await createDummyModel(for: modelType)
        
        trainedModels[modelKey] = dummyModel
        
        if configuration.enableLogging {
            print("[PredictiveAnalytics] ✅ Model training completed: \(modelType.rawValue)")
        }
        
        return dummyModel
    }
    
    private func createDummyModel(for modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType) async throws -> MLModel {
        // This is a simplified dummy model creation
        // In a real implementation, you would use CreateML to train actual models
        
        // For now, we'll throw an error indicating this is a simulation
        throw PredictiveAnalyticsError.modelTrainingNotImplemented("Model training simulation - \(modelType.rawValue)")
    }
    
    private func executeAnalysis(
        request: PredictiveAnalyticsRequest,
        model: MLModel,
        modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType
    ) async throws -> (
        predictions: [PredictiveAnalyticsResult.Prediction],
        modelMetrics: PredictiveAnalyticsResult.ModelMetrics,
        featureImportance: [PredictiveAnalyticsResult.FeatureImportance],
        anomalies: [PredictiveAnalyticsResult.Anomaly],
        insights: [PredictiveAnalyticsResult.Insight]
    ) {
        
        // Simulate analysis execution
        let predictions = generatePredictions(for: request, modelType: modelType)
        let modelMetrics = generateModelMetrics(modelType: modelType)
        let featureImportance = request.options.enableFeatureImportance ? generateFeatureImportance(for: request) : []
        let anomalies = request.analysisType == .anomalyDetection ? generateAnomalies(for: request) : []
        let insights = generateInsights(for: request, predictions: predictions)
        
        return (predictions, modelMetrics, featureImportance, anomalies, insights)
    }
    
    private func generatePredictions(
        for request: PredictiveAnalyticsRequest,
        modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType
    ) -> [PredictiveAnalyticsResult.Prediction] {
        
        let forecastHorizon = request.options.forecastHorizon
        var predictions: [PredictiveAnalyticsResult.Prediction] = []
        
        for i in 0..<forecastHorizon {
            let baseValue = request.data.features.last?.first ?? 0.0
            let noise = Double.random(in: -0.1...0.1)
            let trend = Double(i) * 0.02
            let predictedValue = baseValue + trend + noise
            
            let confidence = Float.random(in: 0.7...0.95)
            let confidenceInterval = PredictiveAnalyticsResult.Prediction.ConfidenceInterval(
                lower: predictedValue - 0.1,
                upper: predictedValue + 0.1,
                level: 0.95
            )
            
            let timestamp = request.data.timestamps?.last?.addingTimeInterval(TimeInterval(i + 1) * 86400) // Add days
            
            predictions.append(PredictiveAnalyticsResult.Prediction(
                value: predictedValue,
                confidence: confidence,
                confidenceInterval: confidenceInterval,
                timestamp: timestamp
            ))
        }
        
        return predictions
    }
    
    private func generateModelMetrics(modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType) -> PredictiveAnalyticsResult.ModelMetrics {
        // Simulate model metrics based on model type
        let accuracy = Float.random(in: 0.75...0.95)
        let precision = Float.random(in: 0.70...0.90)
        let recall = Float.random(in: 0.70...0.90)
        let f1Score = 2 * (precision * recall) / (precision + recall)
        let rmse = Float.random(in: 0.05...0.20)
        let mae = Float.random(in: 0.03...0.15)
        let r2Score = Float.random(in: 0.80...0.95)
        
        return PredictiveAnalyticsResult.ModelMetrics(
            modelType: modelType,
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            rmse: rmse,
            mae: mae,
            r2Score: r2Score,
            crossValidationScore: Float.random(in: 0.75...0.90),
            trainingTime: Double.random(in: 1.0...10.0),
            modelSize: Int.random(in: 100_000...5_000_000)
        )
    }
    
    private func generateFeatureImportance(for request: PredictiveAnalyticsRequest) -> [PredictiveAnalyticsResult.FeatureImportance] {
        return request.data.featureNames.enumerated().map { index, featureName in
            let importance = Float.random(in: 0.1...1.0)
            return PredictiveAnalyticsResult.FeatureImportance(
                featureName: featureName,
                importance: importance,
                rank: index + 1,
                description: "Feature importance for \(featureName)"
            )
        }.sorted { $0.importance > $1.importance }
    }
    
    private func generateAnomalies(for request: PredictiveAnalyticsRequest) -> [PredictiveAnalyticsResult.Anomaly] {
        var anomalies: [PredictiveAnalyticsResult.Anomaly] = []
        
        for (index, features) in request.data.features.enumerated() {
            if Double.random(in: 0...1) < 0.05 { // 5% chance of anomaly
                let severity: PredictiveAnalyticsResult.Anomaly.Severity = .random()
                let confidence = Float.random(in: 0.6...0.95)
                let timestamp = request.data.timestamps?[safe: index]
                
                anomalies.append(PredictiveAnalyticsResult.Anomaly(
                    index: index,
                    value: features.first ?? 0.0,
                    severity: severity,
                    confidence: confidence,
                    timestamp: timestamp,
                    explanation: "Detected anomaly at data point \(index)"
                ))
            }
        }
        
        return anomalies
    }
    
    private func generateInsights(
        for request: PredictiveAnalyticsRequest,
        predictions: [PredictiveAnalyticsResult.Prediction]
    ) -> [PredictiveAnalyticsResult.Insight] {
        
        var insights: [PredictiveAnalyticsResult.Insight] = []
        
        // Trend insight
        if predictions.count > 1 {
            let isIncreasing = predictions.last!.value > predictions.first!.value
            insights.append(PredictiveAnalyticsResult.Insight(
                type: .trend,
                description: "Data shows \(isIncreasing ? "increasing" : "decreasing") trend",
                confidence: 0.85,
                supportingData: ["trend_direction": isIncreasing ? 1.0 : -1.0],
                recommendations: [isIncreasing ? "Monitor growth patterns" : "Investigate decline factors"]
            ))
        }
        
        // Prediction insight
        if let lastPrediction = predictions.last {
            insights.append(PredictiveAnalyticsResult.Insight(
                type: .prediction,
                description: "Next period predicted value: \(String(format: "%.2f", lastPrediction.value))",
                confidence: lastPrediction.confidence,
                supportingData: ["predicted_value": lastPrediction.value],
                recommendations: ["Prepare for predicted value range"]
            ))
        }
        
        return insights
    }
    
    private func generateModelKey(
        for request: PredictiveAnalyticsRequest,
        modelType: PredictiveAnalyticsCapabilityConfiguration.ModelType
    ) -> String {
        let dataHash = request.data.features.description.hashValue
        let analysisType = request.analysisType.rawValue
        let modelTypeString = modelType.rawValue
        return "\(analysisType)_\(modelTypeString)_\(dataHash)"
    }
    
    private func processAnalysisQueue() async {
        guard !isProcessingQueue && !analysisQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        analysisQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !analysisQueue.isEmpty && activeAnalyses.count < configuration.maxConcurrentAnalyses {
            let request = analysisQueue.removeFirst()
            
            do {
                _ = try await performAnalysis(request)
            } catch {
                if configuration.enableLogging {
                    print("[PredictiveAnalytics] ⚠️ Queued analysis failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: PredictiveAnalyticsRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: PredictiveAnalyticsRequest) -> String {
        let dataHash = request.data.features.description.hashValue
        let analysisType = request.analysisType.rawValue
        let optionsHash = String(describing: request.options).hashValue
        return "\(analysisType)_\(dataHash)_\(optionsHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalAnalyses)) + 1
        let totalAnalyses = metrics.totalAnalyses + 1
        let newCacheHitRate = cacheHits / Double(totalAnalyses)
        
        metrics = PredictiveAnalyticsMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses + 1,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            analysesByModel: metrics.analysesByModel,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageAccuracy: metrics.averageAccuracy,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelPerformanceStats: metrics.modelPerformanceStats
        )
    }
    
    private func updateSuccessMetrics(_ result: PredictiveAnalyticsResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let successfulAnalyses = metrics.successfulAnalyses + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAnalyses)) + result.processingTime) / Double(totalAnalyses)
        
        var analysesByType = metrics.analysesByType
        analysesByType[result.analysisType.rawValue, default: 0] += 1
        
        var analysesByModel = metrics.analysesByModel
        analysesByModel[result.modelMetrics.modelType.rawValue, default: 0] += 1
        
        let newAverageAccuracy = if let accuracy = result.modelMetrics.accuracy {
            ((metrics.averageAccuracy * Double(metrics.successfulAnalyses)) + Double(accuracy)) / Double(successfulAnalyses)
        } else {
            metrics.averageAccuracy
        }
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulAnalyses)) + Double(result.averageConfidence)) / Double(successfulAnalyses)
        
        // Update model performance stats
        var modelPerfStats = metrics.modelPerformanceStats
        let totalModelsTrained = modelPerfStats.totalModelsTrained + 1
        let newAverageTrainingTime = ((modelPerfStats.averageTrainingTime * Double(modelPerfStats.totalModelsTrained)) + result.modelMetrics.trainingTime) / Double(totalModelsTrained)
        let newAverageModelSize = ((modelPerfStats.averageModelSize * Double(modelPerfStats.totalModelsTrained)) + Double(result.modelMetrics.modelSize)) / Double(totalModelsTrained)
        let anomaliesDetected = modelPerfStats.anomaliesDetected + result.anomalies.count
        
        modelPerfStats = PredictiveAnalyticsMetrics.ModelPerformanceStats(
            totalModelsTrained: totalModelsTrained,
            averageTrainingTime: newAverageTrainingTime,
            bestPerformingModel: analysesByModel.max(by: { $0.value < $1.value })?.key,
            averageModelSize: newAverageModelSize,
            anomaliesDetected: anomaliesDetected
        )
        
        metrics = PredictiveAnalyticsMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: successfulAnalyses,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: newAverageProcessingTime,
            analysesByType: analysesByType,
            analysesByModel: analysesByModel,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageAccuracy: newAverageAccuracy,
            averageConfidence: newAverageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelPerformanceStats: modelPerfStats
        )
    }
    
    private func updateFailureMetrics(_ result: PredictiveAnalyticsResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let failedAnalyses = metrics.failedAnalyses + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = PredictiveAnalyticsMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses,
            failedAnalyses: failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            analysesByModel: metrics.analysesByModel,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageAccuracy: metrics.averageAccuracy,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            modelPerformanceStats: metrics.modelPerformanceStats
        )
    }
    
    private func logAnalysis(_ result: PredictiveAnalyticsResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let predictionCount = result.predictions.count
        let confidence = String(format: "%.3f", result.averageConfidence)
        let analysisType = result.analysisType.rawValue
        let modelType = result.modelMetrics.modelType.rawValue
        let anomalyCount = result.anomalies.count
        
        print("[PredictiveAnalytics] \(statusIcon) Analysis: \(analysisType) using \(modelType), \(predictionCount) predictions, confidence: \(confidence), \(anomalyCount) anomalies (\(timeStr)s)")
        
        if let error = result.error {
            print("[PredictiveAnalytics] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Predictive Analytics Capability Implementation

/// Predictive Analytics capability providing comprehensive machine learning and forecasting
@available(iOS 13.0, macOS 10.15, *)
public actor PredictiveAnalyticsCapability: DomainCapability {
    public typealias ConfigurationType = PredictiveAnalyticsCapabilityConfiguration
    public typealias ResourceType = PredictiveAnalyticsCapabilityResource
    
    private var _configuration: PredictiveAnalyticsCapabilityConfiguration
    private var _resources: PredictiveAnalyticsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(20)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "predictive-analytics-capability" }
    
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
    
    public var configuration: PredictiveAnalyticsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: PredictiveAnalyticsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: PredictiveAnalyticsCapabilityConfiguration = PredictiveAnalyticsCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = PredictiveAnalyticsCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: PredictiveAnalyticsCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Predictive Analytics configuration")
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
        // Predictive analytics is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Predictive analytics doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Predictive Analytics Operations
    
    /// Perform predictive analytics on data
    public func performAnalysis(_ request: PredictiveAnalyticsRequest) async throws -> PredictiveAnalyticsResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return try await _resources.performAnalysis(request)
    }
    
    /// Cancel analysis
    public func cancelAnalysis(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        await _resources.cancelAnalysis(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<PredictiveAnalyticsResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active analyses
    public func getActiveAnalyses() async throws -> [PredictiveAnalyticsRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return await _resources.getActiveAnalyses()
    }
    
    /// Get analysis history
    public func getAnalysisHistory(since: Date? = nil) async throws -> [PredictiveAnalyticsResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return await _resources.getAnalysisHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> PredictiveAnalyticsMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Predictive Analytics capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Simple time series forecast
    public func forecastTimeSeries(_ data: [Double], periods: Int = 10) async throws -> [Double] {
        let analyticsData = PredictiveAnalyticsRequest.AnalyticsData(
            features: data.map { [$0] },
            featureNames: ["value"],
            dataType: .timeSeries
        )
        
        let options = PredictiveAnalyticsRequest.AnalysisOptions(forecastHorizon: periods)
        let request = PredictiveAnalyticsRequest(
            data: analyticsData,
            analysisType: .forecast,
            options: options
        )
        
        let result = try await performAnalysis(request)
        return result.predictions.map { $0.value }
    }
    
    /// Detect anomalies in data
    public func detectAnomalies(_ data: [[Double]], featureNames: [String]) async throws -> [PredictiveAnalyticsResult.Anomaly] {
        let analyticsData = PredictiveAnalyticsRequest.AnalyticsData(
            features: data,
            featureNames: featureNames
        )
        
        let request = PredictiveAnalyticsRequest(
            data: analyticsData,
            analysisType: .anomalyDetection
        )
        
        let result = try await performAnalysis(request)
        return result.anomalies
    }
    
    /// Check if analysis is active
    public func hasActiveAnalyses() async throws -> Bool {
        let activeAnalyses = try await getActiveAnalyses()
        return !activeAnalyses.isEmpty
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

/// Predictive Analytics specific errors
public enum PredictiveAnalyticsError: Error, LocalizedError {
    case predictiveAnalyticsDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case modelTrainingNotImplemented(String)
    case analysisError(String)
    case insufficientData
    case tooMuchData
    case analysisQueued(UUID)
    case analysisTimeout(UUID)
    case unsupportedAnalysisType(String)
    case invalidDataFormat
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .predictiveAnalyticsDisabled:
            return "Predictive analytics is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .modelTrainingNotImplemented(let details):
            return "Model training not implemented: \(details)"
        case .analysisError(let reason):
            return "Predictive analysis failed: \(reason)"
        case .insufficientData:
            return "Insufficient data for analysis"
        case .tooMuchData:
            return "Too much data for analysis"
        case .analysisQueued(let id):
            return "Predictive analysis queued: \(id)"
        case .analysisTimeout(let id):
            return "Predictive analysis timeout: \(id)"
        case .unsupportedAnalysisType(let type):
            return "Unsupported analysis type: \(type)"
        case .invalidDataFormat:
            return "Invalid data format provided"
        case .configurationError(let reason):
            return "Predictive analytics configuration error: \(reason)"
        }
    }
}

// MARK: - Extensions

private extension PredictiveAnalyticsResult.Anomaly.Severity {
    static func random() -> PredictiveAnalyticsResult.Anomaly.Severity {
        let cases = PredictiveAnalyticsResult.Anomaly.Severity.allCases
        return cases[Int.random(in: 0..<cases.count)]
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}