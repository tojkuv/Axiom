import Foundation
import NaturalLanguage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Translation Capability Configuration

/// Configuration for Translation capability
public struct TranslationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableTranslation: Bool
    public let enableOfflineTranslation: Bool
    public let enableAutoLanguageDetection: Bool
    public let enableBatchTranslation: Bool
    public let enableRealTimeTranslation: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentTranslations: Int
    public let translationTimeout: TimeInterval
    public let minimumTextLength: Int
    public let maximumTextLength: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let supportedLanguagePairs: [(String, String)]
    public let defaultSourceLanguage: String
    public let defaultTargetLanguage: String
    public let translationQuality: TranslationQuality
    
    public enum TranslationQuality: String, Codable, CaseIterable {
        case fast = "fast"
        case balanced = "balanced"
        case accurate = "accurate"
    }
    
    public init(
        enableTranslation: Bool = true,
        enableOfflineTranslation: Bool = true,
        enableAutoLanguageDetection: Bool = true,
        enableBatchTranslation: Bool = true,
        enableRealTimeTranslation: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentTranslations: Int = 8,
        translationTimeout: TimeInterval = 30.0,
        minimumTextLength: Int = 1,
        maximumTextLength: Int = 5000,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 500,
        enablePerformanceOptimization: Bool = true,
        supportedLanguagePairs: [(String, String)] = [
            ("en", "es"), ("en", "fr"), ("en", "de"), ("en", "it"), ("en", "pt"),
            ("en", "ru"), ("en", "ja"), ("en", "ko"), ("en", "zh"), ("en", "ar")
        ],
        defaultSourceLanguage: String = "en",
        defaultTargetLanguage: String = "es",
        translationQuality: TranslationQuality = .balanced
    ) {
        self.enableTranslation = enableTranslation
        self.enableOfflineTranslation = enableOfflineTranslation
        self.enableAutoLanguageDetection = enableAutoLanguageDetection
        self.enableBatchTranslation = enableBatchTranslation
        self.enableRealTimeTranslation = enableRealTimeTranslation
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentTranslations = maxConcurrentTranslations
        self.translationTimeout = translationTimeout
        self.minimumTextLength = minimumTextLength
        self.maximumTextLength = maximumTextLength
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.supportedLanguagePairs = supportedLanguagePairs
        self.defaultSourceLanguage = defaultSourceLanguage
        self.defaultTargetLanguage = defaultTargetLanguage
        self.translationQuality = translationQuality
    }
    
    public var isValid: Bool {
        maxConcurrentTranslations > 0 &&
        translationTimeout > 0 &&
        minimumTextLength >= 0 &&
        maximumTextLength > minimumTextLength &&
        cacheSize >= 0 &&
        !defaultSourceLanguage.isEmpty &&
        !defaultTargetLanguage.isEmpty &&
        !supportedLanguagePairs.isEmpty
    }
    
    public func merged(with other: TranslationCapabilityConfiguration) -> TranslationCapabilityConfiguration {
        TranslationCapabilityConfiguration(
            enableTranslation: other.enableTranslation,
            enableOfflineTranslation: other.enableOfflineTranslation,
            enableAutoLanguageDetection: other.enableAutoLanguageDetection,
            enableBatchTranslation: other.enableBatchTranslation,
            enableRealTimeTranslation: other.enableRealTimeTranslation,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentTranslations: other.maxConcurrentTranslations,
            translationTimeout: other.translationTimeout,
            minimumTextLength: other.minimumTextLength,
            maximumTextLength: other.maximumTextLength,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            supportedLanguagePairs: other.supportedLanguagePairs,
            defaultSourceLanguage: other.defaultSourceLanguage,
            defaultTargetLanguage: other.defaultTargetLanguage,
            translationQuality: other.translationQuality
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> TranslationCapabilityConfiguration {
        var adjustedTimeout = translationTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentTranslations = maxConcurrentTranslations
        var adjustedCacheSize = cacheSize
        var adjustedMaxTextLength = maximumTextLength
        var adjustedQuality = translationQuality
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(translationTimeout, 15.0)
            adjustedConcurrentTranslations = min(maxConcurrentTranslations, 3)
            adjustedCacheSize = min(cacheSize, 100)
            adjustedMaxTextLength = min(maximumTextLength, 2000)
            adjustedQuality = .fast
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return TranslationCapabilityConfiguration(
            enableTranslation: enableTranslation,
            enableOfflineTranslation: enableOfflineTranslation,
            enableAutoLanguageDetection: enableAutoLanguageDetection,
            enableBatchTranslation: enableBatchTranslation,
            enableRealTimeTranslation: enableRealTimeTranslation,
            enableCustomModels: enableCustomModels,
            maxConcurrentTranslations: adjustedConcurrentTranslations,
            translationTimeout: adjustedTimeout,
            minimumTextLength: minimumTextLength,
            maximumTextLength: adjustedMaxTextLength,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            supportedLanguagePairs: supportedLanguagePairs,
            defaultSourceLanguage: defaultSourceLanguage,
            defaultTargetLanguage: defaultTargetLanguage,
            translationQuality: adjustedQuality
        )
    }
}

// MARK: - Translation Types

/// Translation request
public struct TranslationRequest: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let options: TranslationOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct TranslationOptions: Sendable {
        public let sourceLanguage: String?
        public let targetLanguage: String
        public let enableAutoDetection: Bool
        public let translationQuality: TranslationCapabilityConfiguration.TranslationQuality
        public let customModelId: String?
        public let includeAlternatives: Bool
        public let preserveFormatting: Bool
        public let translationContext: TranslationContext
        public let domainSpecialization: DomainSpecialization?
        
        public enum TranslationContext: String, Sendable, CaseIterable {
            case general = "general"
            case formal = "formal"
            case informal = "informal"
            case technical = "technical"
            case medical = "medical"
            case legal = "legal"
            case business = "business"
            case literary = "literary"
        }
        
        public enum DomainSpecialization: String, Sendable, CaseIterable {
            case technology = "technology"
            case medicine = "medicine"
            case finance = "finance"
            case education = "education"
            case travel = "travel"
            case food = "food"
            case sports = "sports"
            case entertainment = "entertainment"
        }
        
        public init(
            sourceLanguage: String? = nil,
            targetLanguage: String,
            enableAutoDetection: Bool = true,
            translationQuality: TranslationCapabilityConfiguration.TranslationQuality = .balanced,
            customModelId: String? = nil,
            includeAlternatives: Bool = false,
            preserveFormatting: Bool = true,
            translationContext: TranslationContext = .general,
            domainSpecialization: DomainSpecialization? = nil
        ) {
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.enableAutoDetection = enableAutoDetection
            self.translationQuality = translationQuality
            self.customModelId = customModelId
            self.includeAlternatives = includeAlternatives
            self.preserveFormatting = preserveFormatting
            self.translationContext = translationContext
            self.domainSpecialization = domainSpecialization
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        text: String,
        options: TranslationOptions,
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.text = text
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Translation result
public struct TranslationResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let sourceText: String
    public let translatedText: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let confidence: Float
    public let alternativeTranslations: [AlternativeTranslation]
    public let translationMetadata: TranslationMetadata
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: TranslationError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AlternativeTranslation: Sendable {
        public let text: String
        public let confidence: Float
        public let context: String?
        public let explanation: String?
        
        public init(text: String, confidence: Float, context: String? = nil, explanation: String? = nil) {
            self.text = text
            self.confidence = confidence
            self.context = context
            self.explanation = explanation
        }
    }
    
    public struct TranslationMetadata: Sendable {
        public let wordCount: Int
        public let characterCount: Int
        public let sentenceCount: Int
        public let translationMethod: TranslationMethod
        public let modelVersion: String?
        public let languageConfidence: Float
        public let translationComplexity: Float
        public let processingSteps: [ProcessingStep]
        
        public enum TranslationMethod: String, Sendable, CaseIterable {
            case neuralMachine = "neural-machine"
            case statistical = "statistical"
            case rulesBased = "rules-based"
            case hybrid = "hybrid"
            case custom = "custom"
        }
        
        public struct ProcessingStep: Sendable {
            public let step: String
            public let duration: TimeInterval
            public let details: [String: String]
            
            public init(step: String, duration: TimeInterval, details: [String: String] = [:]) {
                self.step = step
                self.duration = duration
                self.details = details
            }
        }
        
        public init(
            wordCount: Int,
            characterCount: Int,
            sentenceCount: Int,
            translationMethod: TranslationMethod,
            modelVersion: String? = nil,
            languageConfidence: Float,
            translationComplexity: Float,
            processingSteps: [ProcessingStep] = []
        ) {
            self.wordCount = wordCount
            self.characterCount = characterCount
            self.sentenceCount = sentenceCount
            self.translationMethod = translationMethod
            self.modelVersion = modelVersion
            self.languageConfidence = languageConfidence
            self.translationComplexity = translationComplexity
            self.processingSteps = processingSteps
        }
    }
    
    public init(
        requestId: UUID,
        sourceText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        confidence: Float,
        alternativeTranslations: [AlternativeTranslation] = [],
        translationMetadata: TranslationMetadata,
        processingTime: TimeInterval,
        success: Bool,
        error: TranslationError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.confidence = confidence
        self.alternativeTranslations = alternativeTranslations
        self.translationMetadata = translationMetadata
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var isHighQuality: Bool {
        confidence >= 0.8
    }
    
    public var bestAlternative: AlternativeTranslation? {
        alternativeTranslations.max(by: { $0.confidence < $1.confidence })
    }
    
    public var translationRatio: Float {
        guard !sourceText.isEmpty else { return 0.0 }
        return Float(translatedText.count) / Float(sourceText.count)
    }
}

/// Translation metrics
public struct TranslationMetrics: Sendable {
    public let totalTranslations: Int
    public let successfulTranslations: Int
    public let failedTranslations: Int
    public let averageProcessingTime: TimeInterval
    public let translationsByLanguagePair: [String: Int]
    public let translationsByQuality: [String: Int]
    public let translationsByContext: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let averageWordsPerTranslation: Double
    public let throughputPerSecond: Double
    public let qualityStats: QualityStats
    
    public struct QualityStats: Sendable {
        public let highQualityTranslations: Int
        public let averageTranslationRatio: Double
        public let mostReliableLanguagePair: String?
        public let averageAlternatives: Double
        
        public init(highQualityTranslations: Int = 0, averageTranslationRatio: Double = 0, mostReliableLanguagePair: String? = nil, averageAlternatives: Double = 0) {
            self.highQualityTranslations = highQualityTranslations
            self.averageTranslationRatio = averageTranslationRatio
            self.mostReliableLanguagePair = mostReliableLanguagePair
            self.averageAlternatives = averageAlternatives
        }
    }
    
    public init(
        totalTranslations: Int = 0,
        successfulTranslations: Int = 0,
        failedTranslations: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        translationsByLanguagePair: [String: Int] = [:],
        translationsByQuality: [String: Int] = [:],
        translationsByContext: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        averageWordsPerTranslation: Double = 0,
        throughputPerSecond: Double = 0,
        qualityStats: QualityStats = QualityStats()
    ) {
        self.totalTranslations = totalTranslations
        self.successfulTranslations = successfulTranslations
        self.failedTranslations = failedTranslations
        self.averageProcessingTime = averageProcessingTime
        self.translationsByLanguagePair = translationsByLanguagePair
        self.translationsByQuality = translationsByQuality
        self.translationsByContext = translationsByContext
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.averageWordsPerTranslation = averageWordsPerTranslation
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalTranslations) / averageProcessingTime : 0
        self.qualityStats = qualityStats
    }
    
    public var successRate: Double {
        totalTranslations > 0 ? Double(successfulTranslations) / Double(totalTranslations) : 0
    }
}

// MARK: - Translation Resource

/// Translation resource management
@available(iOS 14.0, macOS 11.0, *)
public actor TranslationCapabilityResource: AxiomCapabilityResource {
    private let configuration: TranslationCapabilityConfiguration
    private var activeTranslations: [UUID: TranslationRequest] = [:]
    private var translationQueue: [TranslationRequest] = []
    private var translationHistory: [TranslationResult] = []
    private var resultCache: [String: TranslationResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var languageRecognizer: NLLanguageRecognizer?
    private var metrics: TranslationMetrics = TranslationMetrics()
    private var resultStreamContinuation: AsyncStream<TranslationResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: TranslationCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 250_000_000, // 250MB for translation models
            cpu: 3.0, // High CPU usage for translation processing
            bandwidth: 0,
            storage: 100_000_000 // 100MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let translationMemory = activeTranslations.count * 20_000_000 // ~20MB per active translation
            let cacheMemory = resultCache.count * 30_000 // ~30KB per cached result
            let modelMemory = customModels.count * 80_000_000 // ~80MB per loaded model
            let historyMemory = translationHistory.count * 5_000
            let nlModelMemory = languageRecognizer != nil ? 15_000_000 : 0
            
            return ResourceUsage(
                memory: translationMemory + cacheMemory + modelMemory + historyMemory + nlModelMemory + 20_000_000,
                cpu: activeTranslations.isEmpty ? 0.2 : 2.5,
                bandwidth: 0,
                storage: resultCache.count * 15_000 + customModels.count * 150_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Translation is available on iOS 14+, macOS 11+
        if #available(iOS 14.0, macOS 11.0, *) {
            return configuration.enableTranslation
        }
        return false
    }
    
    public func release() async {
        activeTranslations.removeAll()
        translationQueue.removeAll()
        translationHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        languageRecognizer = nil
        
        resultStreamContinuation?.finish()
        
        metrics = TranslationMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize language recognizer for auto-detection
        if configuration.enableAutoLanguageDetection {
            languageRecognizer = NLLanguageRecognizer()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[Translation] 🚀 Translation capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: TranslationCapabilityConfiguration) async throws {
        // Update translation configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<TranslationResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw TranslationError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[Translation] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw TranslationError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[Translation] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Translation
    
    public func translateText(_ request: TranslationRequest) async throws -> TranslationResult {
        guard configuration.enableTranslation else {
            throw TranslationError.translationDisabled
        }
        
        // Validate text length
        guard request.text.count >= configuration.minimumTextLength else {
            throw TranslationError.textTooShort
        }
        guard request.text.count <= configuration.maximumTextLength else {
            throw TranslationError.textTooLong
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
        if activeTranslations.count >= configuration.maxConcurrentTranslations {
            translationQueue.append(request)
            throw TranslationError.translationQueued(request.id)
        }
        
        let startTime = Date()
        activeTranslations[request.id] = request
        
        do {
            // Detect source language if needed
            let sourceLanguage = try await detectSourceLanguage(for: request)
            
            // Perform translation
            let result = try await performTranslation(
                request: request,
                sourceLanguage: sourceLanguage,
                startTime: startTime
            )
            
            activeTranslations.removeValue(forKey: request.id)
            translationHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logTranslation(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processTranslationQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = TranslationResult(
                requestId: request.id,
                sourceText: request.text,
                translatedText: "",
                sourceLanguage: request.options.sourceLanguage ?? configuration.defaultSourceLanguage,
                targetLanguage: request.options.targetLanguage,
                confidence: 0.0,
                translationMetadata: TranslationResult.TranslationMetadata(
                    wordCount: request.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
                    characterCount: request.text.count,
                    sentenceCount: 1,
                    translationMethod: .neuralMachine,
                    languageConfidence: 0.0,
                    translationComplexity: 0.0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? TranslationError ?? TranslationError.translationError(error.localizedDescription)
            )
            
            activeTranslations.removeValue(forKey: request.id)
            translationHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logTranslation(result)
            }
            
            throw error
        }
    }
    
    public func cancelTranslation(_ requestId: UUID) async {
        activeTranslations.removeValue(forKey: requestId)
        translationQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[Translation] 🚫 Cancelled translation: \(requestId)")
        }
    }
    
    public func getActiveTranslations() async -> [TranslationRequest] {
        return Array(activeTranslations.values)
    }
    
    public func getTranslationHistory(since: Date? = nil) async -> [TranslationResult] {
        if let since = since {
            return translationHistory.filter { $0.timestamp >= since }
        }
        return translationHistory
    }
    
    // MARK: - Language Support
    
    public func getSupportedLanguagePairs() async -> [(String, String)] {
        return configuration.supportedLanguagePairs
    }
    
    public func isLanguagePairSupported(source: String, target: String) async -> Bool {
        return configuration.supportedLanguagePairs.contains { $0.0 == source && $0.1 == target }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> TranslationMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = TranslationMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[Translation] ⚡ Performance optimization enabled")
        }
    }
    
    private func detectSourceLanguage(for request: TranslationRequest) async throws -> String {
        if let sourceLanguage = request.options.sourceLanguage {
            return sourceLanguage
        }
        
        guard request.options.enableAutoDetection && configuration.enableAutoLanguageDetection else {
            return configuration.defaultSourceLanguage
        }
        
        guard let recognizer = languageRecognizer else {
            return configuration.defaultSourceLanguage
        }
        
        recognizer.reset()
        recognizer.processString(request.text)
        
        if let detectedLanguage = recognizer.dominantLanguage {
            return detectedLanguage.rawValue
        }
        
        return configuration.defaultSourceLanguage
    }
    
    private func performTranslation(
        request: TranslationRequest,
        sourceLanguage: String,
        startTime: Date
    ) async throws -> TranslationResult {
        
        // Check if language pair is supported
        guard await isLanguagePairSupported(source: sourceLanguage, target: request.options.targetLanguage) else {
            throw TranslationError.languagePairNotSupported(sourceLanguage, request.options.targetLanguage)
        }
        
        // Simulate translation process
        let translatedText = await simulateTranslation(
            text: request.text,
            from: sourceLanguage,
            to: request.options.targetLanguage,
            quality: request.options.translationQuality
        )
        
        let confidence = calculateTranslationConfidence(
            sourceText: request.text,
            translatedText: translatedText,
            quality: request.options.translationQuality
        )
        
        // Generate alternatives if requested
        var alternatives: [TranslationResult.AlternativeTranslation] = []
        if request.options.includeAlternatives {
            alternatives = await generateAlternativeTranslations(
                sourceText: request.text,
                primaryTranslation: translatedText
            )
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let metadata = TranslationResult.TranslationMetadata(
            wordCount: request.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
            characterCount: request.text.count,
            sentenceCount: request.text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            translationMethod: .neuralMachine,
            modelVersion: "1.0",
            languageConfidence: 0.95,
            translationComplexity: calculateTextComplexity(request.text),
            processingSteps: [
                TranslationResult.TranslationMetadata.ProcessingStep(step: "language_detection", duration: 0.1),
                TranslationResult.TranslationMetadata.ProcessingStep(step: "translation", duration: processingTime - 0.1)
            ]
        )
        
        return TranslationResult(
            requestId: request.id,
            sourceText: request.text,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: request.options.targetLanguage,
            confidence: confidence,
            alternativeTranslations: alternatives,
            translationMetadata: metadata,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func simulateTranslation(text: String, from sourceLanguage: String, to targetLanguage: String, quality: TranslationCapabilityConfiguration.TranslationQuality) async -> String {
        // Simplified translation simulation
        // In a real implementation, this would use ML models or translation services
        
        // Simulate processing delay based on quality
        let delay = switch quality {
        case .fast: 0.1
        case .balanced: 0.3
        case .accurate: 0.5
        }
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Simple simulation - return modified text
        return "[\(targetLanguage.uppercased())] \(text)"
    }
    
    private func calculateTranslationConfidence(sourceText: String, translatedText: String, quality: TranslationCapabilityConfiguration.TranslationQuality) -> Float {
        // Simplified confidence calculation
        let baseConfidence: Float = switch quality {
        case .fast: 0.75
        case .balanced: 0.85
        case .accurate: 0.95
        }
        
        // Adjust based on text length (longer texts might have lower confidence)
        let lengthFactor = min(1.0, Float(sourceText.count) / 1000.0)
        return max(0.1, baseConfidence - (lengthFactor * 0.1))
    }
    
    private func generateAlternativeTranslations(sourceText: String, primaryTranslation: String) async -> [TranslationResult.AlternativeTranslation] {
        // Simplified alternative generation
        return [
            TranslationResult.AlternativeTranslation(
                text: "[ALT1] \(primaryTranslation)",
                confidence: 0.7,
                context: "informal",
                explanation: "More casual translation"
            ),
            TranslationResult.AlternativeTranslation(
                text: "[ALT2] \(primaryTranslation)",
                confidence: 0.6,
                context: "formal",
                explanation: "More formal translation"
            )
        ]
    }
    
    private func calculateTextComplexity(_ text: String) -> Float {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let avgWordsPerSentence = sentences.isEmpty ? 0 : Float(words.count) / Float(sentences.count)
        let avgWordLength = words.isEmpty ? 0 : Float(words.reduce(0) { $0 + $1.count }) / Float(words.count)
        
        return min(1.0, (avgWordsPerSentence + avgWordLength) / 20.0)
    }
    
    private func processTranslationQueue() async {
        guard !isProcessingQueue && !translationQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        translationQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !translationQueue.isEmpty && activeTranslations.count < configuration.maxConcurrentTranslations {
            let request = translationQueue.removeFirst()
            
            do {
                _ = try await translateText(request)
            } catch {
                if configuration.enableLogging {
                    print("[Translation] ⚠️ Queued translation failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: TranslationRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: TranslationRequest) -> String {
        let textHash = request.text.hashValue
        let sourceLanguage = request.options.sourceLanguage ?? "auto"
        let targetLanguage = request.options.targetLanguage
        let quality = request.options.translationQuality.rawValue
        let context = request.options.translationContext.rawValue
        let alternatives = request.options.includeAlternatives
        
        return "\(textHash)_\(sourceLanguage)_\(targetLanguage)_\(quality)_\(context)_\(alternatives)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalTranslations)) + 1
        let totalTranslations = metrics.totalTranslations + 1
        let newCacheHitRate = cacheHits / Double(totalTranslations)
        
        metrics = TranslationMetrics(
            totalTranslations: totalTranslations,
            successfulTranslations: metrics.successfulTranslations + 1,
            failedTranslations: metrics.failedTranslations,
            averageProcessingTime: metrics.averageProcessingTime,
            translationsByLanguagePair: metrics.translationsByLanguagePair,
            translationsByQuality: metrics.translationsByQuality,
            translationsByContext: metrics.translationsByContext,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageWordsPerTranslation: metrics.averageWordsPerTranslation,
            throughputPerSecond: metrics.throughputPerSecond,
            qualityStats: metrics.qualityStats
        )
    }
    
    private func updateSuccessMetrics(_ result: TranslationResult) async {
        let totalTranslations = metrics.totalTranslations + 1
        let successfulTranslations = metrics.successfulTranslations + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalTranslations)) + result.processingTime) / Double(totalTranslations)
        
        var translationsByLanguagePair = metrics.translationsByLanguagePair
        let languagePair = "\(result.sourceLanguage)-\(result.targetLanguage)"
        translationsByLanguagePair[languagePair, default: 0] += 1
        
        var translationsByQuality = metrics.translationsByQuality
        let qualityKey = result.confidence >= 0.8 ? "high" : result.confidence >= 0.6 ? "medium" : "low"
        translationsByQuality[qualityKey, default: 0] += 1
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulTranslations)) + Double(result.confidence)) / Double(successfulTranslations)
        
        let newAverageWordsPerTranslation = ((metrics.averageWordsPerTranslation * Double(metrics.successfulTranslations)) + Double(result.translationMetadata.wordCount)) / Double(successfulTranslations)
        
        // Update quality stats
        var qualityStats = metrics.qualityStats
        let highQualityTranslations = qualityStats.highQualityTranslations + (result.isHighQuality ? 1 : 0)
        let newAverageTranslationRatio = ((qualityStats.averageTranslationRatio * Double(metrics.successfulTranslations)) + Double(result.translationRatio)) / Double(successfulTranslations)
        let newAverageAlternatives = ((qualityStats.averageAlternatives * Double(metrics.successfulTranslations)) + Double(result.alternativeTranslations.count)) / Double(successfulTranslations)
        
        qualityStats = TranslationMetrics.QualityStats(
            highQualityTranslations: highQualityTranslations,
            averageTranslationRatio: newAverageTranslationRatio,
            mostReliableLanguagePair: translationsByLanguagePair.max(by: { $0.value < $1.value })?.key,
            averageAlternatives: newAverageAlternatives
        )
        
        metrics = TranslationMetrics(
            totalTranslations: totalTranslations,
            successfulTranslations: successfulTranslations,
            failedTranslations: metrics.failedTranslations,
            averageProcessingTime: newAverageProcessingTime,
            translationsByLanguagePair: translationsByLanguagePair,
            translationsByQuality: translationsByQuality,
            translationsByContext: metrics.translationsByContext,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            averageWordsPerTranslation: newAverageWordsPerTranslation,
            throughputPerSecond: metrics.throughputPerSecond,
            qualityStats: qualityStats
        )
    }
    
    private func updateFailureMetrics(_ result: TranslationResult) async {
        let totalTranslations = metrics.totalTranslations + 1
        let failedTranslations = metrics.failedTranslations + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = TranslationMetrics(
            totalTranslations: totalTranslations,
            successfulTranslations: metrics.successfulTranslations,
            failedTranslations: failedTranslations,
            averageProcessingTime: metrics.averageProcessingTime,
            translationsByLanguagePair: metrics.translationsByLanguagePair,
            translationsByQuality: metrics.translationsByQuality,
            translationsByContext: metrics.translationsByContext,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageWordsPerTranslation: metrics.averageWordsPerTranslation,
            throughputPerSecond: metrics.throughputPerSecond,
            qualityStats: metrics.qualityStats
        )
    }
    
    private func logTranslation(_ result: TranslationResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let wordCount = result.translationMetadata.wordCount
        let confidence = String(format: "%.3f", result.confidence)
        let languagePair = "\(result.sourceLanguage)-\(result.targetLanguage)"
        let alternativeCount = result.alternativeTranslations.count
        
        print("[Translation] \(statusIcon) Translation: \(wordCount) words, \(languagePair), confidence: \(confidence), \(alternativeCount) alternatives (\(timeStr)s)")
        
        if let error = result.error {
            print("[Translation] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Translation Capability Implementation

/// Translation capability providing comprehensive text translation services
@available(iOS 14.0, macOS 11.0, *)
public actor TranslationCapability: DomainCapability {
    public typealias ConfigurationType = TranslationCapabilityConfiguration
    public typealias ResourceType = TranslationCapabilityResource
    
    private var _configuration: TranslationCapabilityConfiguration
    private var _resources: TranslationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "translation-capability" }
    
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
    
    public var configuration: TranslationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: TranslationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: TranslationCapabilityConfiguration = TranslationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = TranslationCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: TranslationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Translation configuration")
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
        // Translation is supported on iOS 14+, macOS 11+
        if #available(iOS 14.0, macOS 11.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Translation doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Translation Operations
    
    /// Translate text from one language to another
    public func translateText(_ request: TranslationRequest) async throws -> TranslationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return try await _resources.translateText(request)
    }
    
    /// Cancel translation
    public func cancelTranslation(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        await _resources.cancelTranslation(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<TranslationResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get supported language pairs
    public func getSupportedLanguagePairs() async throws -> [(String, String)] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.getSupportedLanguagePairs()
    }
    
    /// Check if language pair is supported
    public func isLanguagePairSupported(source: String, target: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.isLanguagePairSupported(source: source, target: target)
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active translations
    public func getActiveTranslations() async throws -> [TranslationRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.getActiveTranslations()
    }
    
    /// Get translation history
    public func getTranslationHistory(since: Date? = nil) async throws -> [TranslationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.getTranslationHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> TranslationMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Translation capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick translation with default options
    public func quickTranslate(_ text: String, to targetLanguage: String, from sourceLanguage: String? = nil) async throws -> String {
        let options = TranslationRequest.TranslationOptions(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        let request = TranslationRequest(text: text, options: options)
        let result = try await translateText(request)
        return result.translatedText
    }
    
    /// Batch translate multiple texts
    public func batchTranslate(_ texts: [String], to targetLanguage: String, from sourceLanguage: String? = nil) async throws -> [String] {
        var results: [String] = []
        
        for text in texts {
            let translatedText = try await quickTranslate(text, to: targetLanguage, from: sourceLanguage)
            results.append(translatedText)
        }
        
        return results
    }
    
    /// Check if translation is active
    public func hasActiveTranslations() async throws -> Bool {
        let activeTranslations = try await getActiveTranslations()
        return !activeTranslations.isEmpty
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

/// Translation specific errors
public enum TranslationError: Error, LocalizedError {
    case translationDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case translationError(String)
    case textTooShort
    case textTooLong
    case translationQueued(UUID)
    case translationTimeout(UUID)
    case languagePairNotSupported(String, String)
    case sourceLanguageDetectionFailed
    case invalidText
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .translationDisabled:
            return "Translation is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .translationError(let reason):
            return "Translation failed: \(reason)"
        case .textTooShort:
            return "Text is too short for translation"
        case .textTooLong:
            return "Text is too long for translation"
        case .translationQueued(let id):
            return "Translation queued: \(id)"
        case .translationTimeout(let id):
            return "Translation timeout: \(id)"
        case .languagePairNotSupported(let source, let target):
            return "Language pair not supported: \(source) to \(target)"
        case .sourceLanguageDetectionFailed:
            return "Failed to detect source language"
        case .invalidText:
            return "Invalid text provided for translation"
        case .configurationError(let reason):
            return "Translation configuration error: \(reason)"
        }
    }
}