import Foundation
import NaturalLanguage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Language Detection Capability Configuration

/// Configuration for Language Detection capability
public struct LanguageDetectionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableLanguageDetection: Bool
    public let enableMixedLanguageDetection: Bool
    public let enableConfidenceScoring: Bool
    public let enableSegmentAnalysis: Bool
    public let enableRealTimeDetection: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentDetections: Int
    public let detectionTimeout: TimeInterval
    public let minimumTextLength: Int
    public let maximumTextLength: Int
    public let confidenceThreshold: Float
    public let maxHypotheses: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let supportedLanguages: [String]
    public let detectionGranularity: DetectionGranularity
    public let domainHints: [DomainHint]
    
    public enum DetectionGranularity: String, Codable, CaseIterable {
        case character = "character"
        case word = "word"
        case sentence = "sentence"
        case paragraph = "paragraph"
        case document = "document"
    }
    
    public enum DomainHint: String, Codable, CaseIterable {
        case news = "news"
        case social = "social"
        case academic = "academic"
        case business = "business"
        case casual = "casual"
        case technical = "technical"
    }
    
    public init(
        enableLanguageDetection: Bool = true,
        enableMixedLanguageDetection: Bool = true,
        enableConfidenceScoring: Bool = true,
        enableSegmentAnalysis: Bool = true,
        enableRealTimeDetection: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentDetections: Int = 15,
        detectionTimeout: TimeInterval = 15.0,
        minimumTextLength: Int = 1,
        maximumTextLength: Int = 50000,
        confidenceThreshold: Float = 0.1,
        maxHypotheses: Int = 5,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 300,
        enablePerformanceOptimization: Bool = true,
        supportedLanguages: [String] = [],
        detectionGranularity: DetectionGranularity = .document,
        domainHints: [DomainHint] = []
    ) {
        self.enableLanguageDetection = enableLanguageDetection
        self.enableMixedLanguageDetection = enableMixedLanguageDetection
        self.enableConfidenceScoring = enableConfidenceScoring
        self.enableSegmentAnalysis = enableSegmentAnalysis
        self.enableRealTimeDetection = enableRealTimeDetection
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentDetections = maxConcurrentDetections
        self.detectionTimeout = detectionTimeout
        self.minimumTextLength = minimumTextLength
        self.maximumTextLength = maximumTextLength
        self.confidenceThreshold = confidenceThreshold
        self.maxHypotheses = maxHypotheses
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.supportedLanguages = supportedLanguages
        self.detectionGranularity = detectionGranularity
        self.domainHints = domainHints
    }
    
    public var isValid: Bool {
        maxConcurrentDetections > 0 &&
        detectionTimeout > 0 &&
        minimumTextLength >= 0 &&
        maximumTextLength > minimumTextLength &&
        confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0 &&
        maxHypotheses > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: LanguageDetectionCapabilityConfiguration) -> LanguageDetectionCapabilityConfiguration {
        LanguageDetectionCapabilityConfiguration(
            enableLanguageDetection: other.enableLanguageDetection,
            enableMixedLanguageDetection: other.enableMixedLanguageDetection,
            enableConfidenceScoring: other.enableConfidenceScoring,
            enableSegmentAnalysis: other.enableSegmentAnalysis,
            enableRealTimeDetection: other.enableRealTimeDetection,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentDetections: other.maxConcurrentDetections,
            detectionTimeout: other.detectionTimeout,
            minimumTextLength: other.minimumTextLength,
            maximumTextLength: other.maximumTextLength,
            confidenceThreshold: other.confidenceThreshold,
            maxHypotheses: other.maxHypotheses,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            supportedLanguages: other.supportedLanguages,
            detectionGranularity: other.detectionGranularity,
            domainHints: other.domainHints
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> LanguageDetectionCapabilityConfiguration {
        var adjustedTimeout = detectionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentDetections = maxConcurrentDetections
        var adjustedCacheSize = cacheSize
        var adjustedMaxTextLength = maximumTextLength
        var adjustedMaxHypotheses = maxHypotheses
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(detectionTimeout, 10.0)
            adjustedConcurrentDetections = min(maxConcurrentDetections, 5)
            adjustedCacheSize = min(cacheSize, 100)
            adjustedMaxTextLength = min(maximumTextLength, 20000)
            adjustedMaxHypotheses = min(maxHypotheses, 3)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return LanguageDetectionCapabilityConfiguration(
            enableLanguageDetection: enableLanguageDetection,
            enableMixedLanguageDetection: enableMixedLanguageDetection,
            enableConfidenceScoring: enableConfidenceScoring,
            enableSegmentAnalysis: enableSegmentAnalysis,
            enableRealTimeDetection: enableRealTimeDetection,
            enableCustomModels: enableCustomModels,
            maxConcurrentDetections: adjustedConcurrentDetections,
            detectionTimeout: adjustedTimeout,
            minimumTextLength: minimumTextLength,
            maximumTextLength: adjustedMaxTextLength,
            confidenceThreshold: confidenceThreshold,
            maxHypotheses: adjustedMaxHypotheses,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            supportedLanguages: supportedLanguages,
            detectionGranularity: detectionGranularity,
            domainHints: domainHints
        )
    }
}

// MARK: - Language Detection Types

/// Language detection request
public struct LanguageDetectionRequest: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let options: DetectionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct DetectionOptions: Sendable {
        public let granularity: LanguageDetectionCapabilityConfiguration.DetectionGranularity
        public let maxHypotheses: Int
        public let confidenceThreshold: Float
        public let enableMixedLanguageDetection: Bool
        public let enableSegmentAnalysis: Bool
        public let customModelId: String?
        public let domainHints: [LanguageDetectionCapabilityConfiguration.DomainHint]
        public let preferredLanguages: [String]
        public let excludeLanguages: [String]
        
        public init(
            granularity: LanguageDetectionCapabilityConfiguration.DetectionGranularity = .document,
            maxHypotheses: Int = 5,
            confidenceThreshold: Float = 0.1,
            enableMixedLanguageDetection: Bool = true,
            enableSegmentAnalysis: Bool = false,
            customModelId: String? = nil,
            domainHints: [LanguageDetectionCapabilityConfiguration.DomainHint] = [],
            preferredLanguages: [String] = [],
            excludeLanguages: [String] = []
        ) {
            self.granularity = granularity
            self.maxHypotheses = maxHypotheses
            self.confidenceThreshold = confidenceThreshold
            self.enableMixedLanguageDetection = enableMixedLanguageDetection
            self.enableSegmentAnalysis = enableSegmentAnalysis
            self.customModelId = customModelId
            self.domainHints = domainHints
            self.preferredLanguages = preferredLanguages
            self.excludeLanguages = excludeLanguages
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
        options: DetectionOptions = DetectionOptions(),
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

/// Language detection result
public struct LanguageDetectionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let dominantLanguage: LanguageHypothesis?
    public let languageHypotheses: [LanguageHypothesis]
    public let segmentAnalysis: [LanguageSegment]
    public let mixedLanguageAnalysis: MixedLanguageAnalysis?
    public let textStatistics: TextStatistics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: LanguageDetectionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct LanguageHypothesis: Sendable {
        public let languageCode: String
        public let languageName: String
        public let confidence: Double
        public let script: String?
        public let region: String?
        public let variants: [String]
        public let certaintyLevel: CertaintyLevel
        
        public enum CertaintyLevel: String, Sendable, CaseIterable {
            case veryLow = "very-low"
            case low = "low"
            case medium = "medium"
            case high = "high"
            case veryHigh = "very-high"
        }
        
        public init(languageCode: String, languageName: String, confidence: Double, script: String? = nil, region: String? = nil, variants: [String] = []) {
            self.languageCode = languageCode
            self.languageName = languageName
            self.confidence = confidence
            self.script = script
            self.region = region
            self.variants = variants
            
            // Determine certainty level based on confidence
            switch confidence {
            case 0.9...1.0:
                self.certaintyLevel = .veryHigh
            case 0.7..<0.9:
                self.certaintyLevel = .high
            case 0.5..<0.7:
                self.certaintyLevel = .medium
            case 0.3..<0.5:
                self.certaintyLevel = .low
            default:
                self.certaintyLevel = .veryLow
            }
        }
    }
    
    public struct LanguageSegment: Sendable {
        public let text: String
        public let range: Range<String.Index>
        public let dominantLanguage: LanguageHypothesis
        public let alternativeLanguages: [LanguageHypothesis]
        public let confidence: Double
        public let segmentType: SegmentType
        
        public enum SegmentType: String, Sendable, CaseIterable {
            case word = "word"
            case phrase = "phrase"
            case sentence = "sentence"
            case paragraph = "paragraph"
            case section = "section"
        }
        
        public init(text: String, range: Range<String.Index>, dominantLanguage: LanguageHypothesis, alternativeLanguages: [LanguageHypothesis], confidence: Double, segmentType: SegmentType) {
            self.text = text
            self.range = range
            self.dominantLanguage = dominantLanguage
            self.alternativeLanguages = alternativeLanguages
            self.confidence = confidence
            self.segmentType = segmentType
        }
    }
    
    public struct MixedLanguageAnalysis: Sendable {
        public let isMixedLanguage: Bool
        public let languageDistribution: [String: Double]
        public let primaryLanguage: String
        public let secondaryLanguages: [String]
        public let codeSwitch: [CodeSwitchPoint]
        public let mixingPattern: MixingPattern
        
        public struct CodeSwitchPoint: Sendable {
            public let position: String.Index
            public let fromLanguage: String
            public let toLanguage: String
            public let confidence: Double
            public let context: String
            
            public init(position: String.Index, fromLanguage: String, toLanguage: String, confidence: Double, context: String) {
                self.position = position
                self.fromLanguage = fromLanguage
                self.toLanguage = toLanguage
                self.confidence = confidence
                self.context = context
            }
        }
        
        public enum MixingPattern: String, Sendable, CaseIterable {
            case intrasentential = "intrasentential" // Within sentences
            case intersentential = "intersentential" // Between sentences
            case sequential = "sequential" // Sequential blocks
            case random = "random" // Random distribution
            case structured = "structured" // Structured pattern
        }
        
        public init(isMixedLanguage: Bool, languageDistribution: [String: Double], primaryLanguage: String, secondaryLanguages: [String], codeSwitch: [CodeSwitchPoint], mixingPattern: MixingPattern) {
            self.isMixedLanguage = isMixedLanguage
            self.languageDistribution = languageDistribution
            self.primaryLanguage = primaryLanguage
            self.secondaryLanguages = secondaryLanguages
            self.codeSwitch = codeSwitch
            self.mixingPattern = mixingPattern
        }
    }
    
    public struct TextStatistics: Sendable {
        public let characterCount: Int
        public let wordCount: Int
        public let sentenceCount: Int
        public let paragraphCount: Int
        public let uniqueCharacterRatio: Double
        public let scriptTypes: [ScriptType]
        public let averageWordLength: Double
        public let textComplexity: Double
        
        public enum ScriptType: String, Sendable, CaseIterable {
            case latin = "latin"
            case cyrillic = "cyrillic"
            case arabic = "arabic"
            case chinese = "chinese"
            case japanese = "japanese"
            case korean = "korean"
            case thai = "thai"
            case hebrew = "hebrew"
            case greek = "greek"
            case devanagari = "devanagari"
            case unknown = "unknown"
        }
        
        public init(characterCount: Int, wordCount: Int, sentenceCount: Int, paragraphCount: Int, uniqueCharacterRatio: Double, scriptTypes: [ScriptType], averageWordLength: Double, textComplexity: Double) {
            self.characterCount = characterCount
            self.wordCount = wordCount
            self.sentenceCount = sentenceCount
            self.paragraphCount = paragraphCount
            self.uniqueCharacterRatio = uniqueCharacterRatio
            self.scriptTypes = scriptTypes
            self.averageWordLength = averageWordLength
            self.textComplexity = textComplexity
        }
    }
    
    public init(
        requestId: UUID,
        dominantLanguage: LanguageHypothesis? = nil,
        languageHypotheses: [LanguageHypothesis] = [],
        segmentAnalysis: [LanguageSegment] = [],
        mixedLanguageAnalysis: MixedLanguageAnalysis? = nil,
        textStatistics: TextStatistics,
        processingTime: TimeInterval,
        success: Bool,
        error: LanguageDetectionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.dominantLanguage = dominantLanguage
        self.languageHypotheses = languageHypotheses
        self.segmentAnalysis = segmentAnalysis
        self.mixedLanguageAnalysis = mixedLanguageAnalysis
        self.textStatistics = textStatistics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var detectedLanguageCode: String? {
        dominantLanguage?.languageCode
    }
    
    public var confidenceScore: Double {
        dominantLanguage?.confidence ?? 0.0
    }
    
    public var isHighConfidence: Bool {
        confidenceScore >= 0.8
    }
    
    public var uniqueLanguages: [String] {
        Array(Set(languageHypotheses.map { $0.languageCode }))
    }
}

/// Language detection metrics
public struct LanguageDetectionMetrics: Sendable {
    public let totalDetections: Int
    public let successfulDetections: Int
    public let failedDetections: Int
    public let averageProcessingTime: TimeInterval
    public let detectionsByLanguage: [String: Int]
    public let detectionsByConfidence: [String: Int]
    public let detectionsByGranularity: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageTextLength: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    public let mixedLanguageStats: MixedLanguageStats
    
    public struct MixedLanguageStats: Sendable {
        public let totalMixedLanguageTexts: Int
        public let averageLanguagesPerText: Double
        public let mostCommonLanguagePairs: [(String, String, Int)]
        public let codeSwitchFrequency: Double
        
        public init(totalMixedLanguageTexts: Int = 0, averageLanguagesPerText: Double = 0, mostCommonLanguagePairs: [(String, String, Int)] = [], codeSwitchFrequency: Double = 0) {
            self.totalMixedLanguageTexts = totalMixedLanguageTexts
            self.averageLanguagesPerText = averageLanguagesPerText
            self.mostCommonLanguagePairs = mostCommonLanguagePairs
            self.codeSwitchFrequency = codeSwitchFrequency
        }
    }
    
    public init(
        totalDetections: Int = 0,
        successfulDetections: Int = 0,
        failedDetections: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        detectionsByLanguage: [String: Int] = [:],
        detectionsByConfidence: [String: Int] = [:],
        detectionsByGranularity: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageTextLength: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0,
        mixedLanguageStats: MixedLanguageStats = MixedLanguageStats()
    ) {
        self.totalDetections = totalDetections
        self.successfulDetections = successfulDetections
        self.failedDetections = failedDetections
        self.averageProcessingTime = averageProcessingTime
        self.detectionsByLanguage = detectionsByLanguage
        self.detectionsByConfidence = detectionsByConfidence
        self.detectionsByGranularity = detectionsByGranularity
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageTextLength = averageTextLength
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalDetections) / averageProcessingTime : 0
        self.mixedLanguageStats = mixedLanguageStats
    }
    
    public var successRate: Double {
        totalDetections > 0 ? Double(successfulDetections) / Double(totalDetections) : 0
    }
}

// MARK: - Language Detection Resource

/// Language detection resource management
@available(iOS 13.0, macOS 10.15, *)
public actor LanguageDetectionCapabilityResource: AxiomCapabilityResource {
    private let configuration: LanguageDetectionCapabilityConfiguration
    private var activeDetections: [UUID: LanguageDetectionRequest] = [:]
    private var detectionQueue: [LanguageDetectionRequest] = []
    private var detectionHistory: [LanguageDetectionResult] = []
    private var resultCache: [String: LanguageDetectionResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var languageRecognizer: NLLanguageRecognizer?
    private var tokenizer: NLTokenizer?
    private var metrics: LanguageDetectionMetrics = LanguageDetectionMetrics()
    private var resultStreamContinuation: AsyncStream<LanguageDetectionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: LanguageDetectionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 120_000_000, // 120MB for language detection
            cpu: 1.5, // Light CPU usage for text processing
            bandwidth: 0,
            storage: 40_000_000 // 40MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let detectionMemory = activeDetections.count * 8_000_000 // ~8MB per active detection
            let cacheMemory = resultCache.count * 50_000 // ~50KB per cached result
            let modelMemory = customModels.count * 30_000_000 // ~30MB per loaded model
            let historyMemory = detectionHistory.count * 8_000
            let nlModelMemory = languageRecognizer != nil ? 20_000_000 : 0
            
            return ResourceUsage(
                memory: detectionMemory + cacheMemory + modelMemory + historyMemory + nlModelMemory + 15_000_000,
                cpu: activeDetections.isEmpty ? 0.1 : 1.2,
                bandwidth: 0,
                storage: resultCache.count * 25_000 + customModels.count * 60_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Language detection is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableLanguageDetection
        }
        return false
    }
    
    public func release() async {
        activeDetections.removeAll()
        detectionQueue.removeAll()
        detectionHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        languageRecognizer = nil
        tokenizer = nil
        
        resultStreamContinuation?.finish()
        
        metrics = LanguageDetectionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize language recognizer
        languageRecognizer = NLLanguageRecognizer()
        
        // Initialize tokenizer for segmentation
        tokenizer = NLTokenizer(unit: .sentence)
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[LanguageDetection] 🚀 Language Detection capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: LanguageDetectionCapabilityConfiguration) async throws {
        // Update language detection configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<LanguageDetectionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw LanguageDetectionError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[LanguageDetection] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw LanguageDetectionError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[LanguageDetection] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Language Detection
    
    public func detectLanguage(_ request: LanguageDetectionRequest) async throws -> LanguageDetectionResult {
        guard configuration.enableLanguageDetection else {
            throw LanguageDetectionError.languageDetectionDisabled
        }
        
        // Validate text length
        guard request.text.count >= configuration.minimumTextLength else {
            throw LanguageDetectionError.textTooShort
        }
        guard request.text.count <= configuration.maximumTextLength else {
            throw LanguageDetectionError.textTooLong
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
            throw LanguageDetectionError.detectionQueued(request.id)
        }
        
        let startTime = Date()
        activeDetections[request.id] = request
        
        do {
            // Perform language detection
            let result = try await performLanguageDetection(
                text: request.text,
                request: request,
                startTime: startTime
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
            let result = LanguageDetectionResult(
                requestId: request.id,
                textStatistics: createTextStatistics(text: request.text),
                processingTime: processingTime,
                success: false,
                error: error as? LanguageDetectionError ?? LanguageDetectionError.detectionError(error.localizedDescription)
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
    
    public func cancelDetection(_ requestId: UUID) async {
        activeDetections.removeValue(forKey: requestId)
        detectionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[LanguageDetection] 🚫 Cancelled detection: \(requestId)")
        }
    }
    
    public func getActiveDetections() async -> [LanguageDetectionRequest] {
        return Array(activeDetections.values)
    }
    
    public func getDetectionHistory(since: Date? = nil) async -> [LanguageDetectionResult] {
        if let since = since {
            return detectionHistory.filter { $0.timestamp >= since }
        }
        return detectionHistory
    }
    
    // MARK: - Language Support
    
    public func getSupportedLanguages() async -> [String] {
        return NLLanguageRecognizer.supportedLanguages.map { $0.rawValue }
    }
    
    public func isLanguageSupported(_ languageCode: String) async -> Bool {
        let supportedLanguages = await getSupportedLanguages()
        return supportedLanguages.contains(languageCode)
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> LanguageDetectionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = LanguageDetectionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[LanguageDetection] ⚡ Performance optimization enabled")
        }
    }
    
    private func performLanguageDetection(
        text: String,
        request: LanguageDetectionRequest,
        startTime: Date
    ) async throws -> LanguageDetectionResult {
        
        guard let recognizer = languageRecognizer else {
            throw LanguageDetectionError.recognizerNotAvailable
        }
        
        // Reset and process text
        recognizer.reset()
        recognizer.processString(text)
        
        // Get language hypotheses
        let hypotheses = recognizer.languageHypotheses(withMaximum: request.options.maxHypotheses)
        
        // Filter by confidence threshold
        let filteredHypotheses = hypotheses.filter { $0.value >= request.options.confidenceThreshold }
        
        // Convert to LanguageHypothesis objects
        let languageHypotheses = filteredHypotheses.map { (language, confidence) in
            LanguageDetectionResult.LanguageHypothesis(
                languageCode: language.rawValue,
                languageName: getLanguageName(for: language.rawValue),
                confidence: confidence
            )
        }.sorted { $0.confidence > $1.confidence }
        
        let dominantLanguage = languageHypotheses.first
        
        // Create text statistics
        let textStatistics = createTextStatistics(text: text)
        
        // Perform segment analysis if requested
        var segmentAnalysis: [LanguageDetectionResult.LanguageSegment] = []
        if request.options.enableSegmentAnalysis {
            segmentAnalysis = await performSegmentAnalysis(text: text, granularity: request.options.granularity)
        }
        
        // Perform mixed language analysis if enabled
        var mixedLanguageAnalysis: LanguageDetectionResult.MixedLanguageAnalysis?
        if request.options.enableMixedLanguageDetection && configuration.enableMixedLanguageDetection {
            mixedLanguageAnalysis = await performMixedLanguageAnalysis(text: text, segments: segmentAnalysis)
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return LanguageDetectionResult(
            requestId: request.id,
            dominantLanguage: dominantLanguage,
            languageHypotheses: languageHypotheses,
            segmentAnalysis: segmentAnalysis,
            mixedLanguageAnalysis: mixedLanguageAnalysis,
            textStatistics: textStatistics,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func createTextStatistics(text: String) -> LanguageDetectionResult.TextStatistics {
        let characterCount = text.count
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let sentenceCount = sentences.count
        let paragraphs = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let paragraphCount = paragraphs.count
        
        // Calculate unique character ratio
        let uniqueCharacters = Set(text.lowercased())
        let uniqueCharacterRatio = characterCount > 0 ? Double(uniqueCharacters.count) / Double(characterCount) : 0
        
        // Detect script types
        let scriptTypes = detectScriptTypes(text: text)
        
        // Calculate average word length
        let averageWordLength = wordCount > 0 ? Double(words.reduce(0) { $0 + $1.count }) / Double(wordCount) : 0
        
        // Simple text complexity calculation
        let averageSentenceLength = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0
        let textComplexity = min((averageSentenceLength + averageWordLength) / 20.0, 1.0) // Normalize to 0-1
        
        return LanguageDetectionResult.TextStatistics(
            characterCount: characterCount,
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            uniqueCharacterRatio: uniqueCharacterRatio,
            scriptTypes: scriptTypes,
            averageWordLength: averageWordLength,
            textComplexity: textComplexity
        )
    }
    
    private func detectScriptTypes(text: String) -> [LanguageDetectionResult.TextStatistics.ScriptType] {
        var scriptTypes: Set<LanguageDetectionResult.TextStatistics.ScriptType> = []
        
        for char in text {
            let scalar = char.unicodeScalars.first!
            
            switch scalar.value {
            case 0x0000...0x007F, 0x0080...0x00FF, 0x0100...0x017F, 0x0180...0x024F: // Latin
                scriptTypes.insert(.latin)
            case 0x0400...0x04FF: // Cyrillic
                scriptTypes.insert(.cyrillic)
            case 0x0600...0x06FF: // Arabic
                scriptTypes.insert(.arabic)
            case 0x4E00...0x9FFF: // Chinese
                scriptTypes.insert(.chinese)
            case 0x3040...0x309F, 0x30A0...0x30FF: // Japanese (Hiragana, Katakana)
                scriptTypes.insert(.japanese)
            case 0xAC00...0xD7AF: // Korean
                scriptTypes.insert(.korean)
            case 0x0E00...0x0E7F: // Thai
                scriptTypes.insert(.thai)
            case 0x0590...0x05FF: // Hebrew
                scriptTypes.insert(.hebrew)
            case 0x0370...0x03FF: // Greek
                scriptTypes.insert(.greek)
            case 0x0900...0x097F: // Devanagari
                scriptTypes.insert(.devanagari)
            default:
                break
            }
        }
        
        return scriptTypes.isEmpty ? [.unknown] : Array(scriptTypes)
    }
    
    private func performSegmentAnalysis(text: String, granularity: LanguageDetectionCapabilityConfiguration.DetectionGranularity) async -> [LanguageDetectionResult.LanguageSegment] {
        guard let tokenizer = tokenizer else { return [] }
        
        var segments: [LanguageDetectionResult.LanguageSegment] = []
        
        let unit: NLTokenUnit = switch granularity {
        case .word: .word
        case .sentence: .sentence
        case .paragraph: .paragraph
        default: .sentence
        }
        
        tokenizer.setLanguage(.undetermined)
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let segmentText = String(text[tokenRange])
            
            // Detect language for this segment
            let segmentRecognizer = NLLanguageRecognizer()
            segmentRecognizer.processString(segmentText)
            let hypotheses = segmentRecognizer.languageHypotheses(withMaximum: 3)
            
            if let dominantLanguage = hypotheses.max(by: { $0.value < $1.value }) {
                let languageHypothesis = LanguageDetectionResult.LanguageHypothesis(
                    languageCode: dominantLanguage.key.rawValue,
                    languageName: getLanguageName(for: dominantLanguage.key.rawValue),
                    confidence: dominantLanguage.value
                )
                
                let alternativeLanguages = hypotheses.filter { $0.key != dominantLanguage.key }.map { (language, confidence) in
                    LanguageDetectionResult.LanguageHypothesis(
                        languageCode: language.rawValue,
                        languageName: getLanguageName(for: language.rawValue),
                        confidence: confidence
                    )
                }
                
                let segmentType: LanguageDetectionResult.LanguageSegment.SegmentType = switch unit {
                case .word: .word
                case .sentence: .sentence
                case .paragraph: .paragraph
                default: .sentence
                }
                
                segments.append(LanguageDetectionResult.LanguageSegment(
                    text: segmentText,
                    range: tokenRange,
                    dominantLanguage: languageHypothesis,
                    alternativeLanguages: alternativeLanguages,
                    confidence: dominantLanguage.value,
                    segmentType: segmentType
                ))
            }
            
            return true
        }
        
        return segments
    }
    
    private func performMixedLanguageAnalysis(text: String, segments: [LanguageDetectionResult.LanguageSegment]) async -> LanguageDetectionResult.MixedLanguageAnalysis {
        // Analyze language distribution
        let languageFrequency = Dictionary(grouping: segments) { $0.dominantLanguage.languageCode }
            .mapValues { $0.count }
        
        let totalSegments = segments.count
        let languageDistribution = languageFrequency.mapValues { Double($0) / Double(totalSegments) }
        
        let isMixedLanguage = languageFrequency.count > 1
        
        let primaryLanguage = languageFrequency.max(by: { $0.value < $1.value })?.key ?? "unknown"
        let secondaryLanguages = languageFrequency.filter { $0.key != primaryLanguage }.map { $0.key }
        
        // Detect code-switching points
        var codeSwitchPoints: [LanguageDetectionResult.MixedLanguageAnalysis.CodeSwitchPoint] = []
        for i in 1..<segments.count {
            let prevLanguage = segments[i-1].dominantLanguage.languageCode
            let currLanguage = segments[i].dominantLanguage.languageCode
            
            if prevLanguage != currLanguage {
                let switchPoint = LanguageDetectionResult.MixedLanguageAnalysis.CodeSwitchPoint(
                    position: segments[i].range.lowerBound,
                    fromLanguage: prevLanguage,
                    toLanguage: currLanguage,
                    confidence: segments[i].confidence,
                    context: String(text[segments[i].range].prefix(50))
                )
                codeSwitchPoints.append(switchPoint)
            }
        }
        
        // Determine mixing pattern
        let mixingPattern: LanguageDetectionResult.MixedLanguageAnalysis.MixingPattern
        if codeSwitchPoints.count == 0 {
            mixingPattern = .sequential
        } else if codeSwitchPoints.count > segments.count / 2 {
            mixingPattern = .random
        } else {
            mixingPattern = .intersentential
        }
        
        return LanguageDetectionResult.MixedLanguageAnalysis(
            isMixedLanguage: isMixedLanguage,
            languageDistribution: languageDistribution,
            primaryLanguage: primaryLanguage,
            secondaryLanguages: secondaryLanguages,
            codeSwitch: codeSwitchPoints,
            mixingPattern: mixingPattern
        )
    }
    
    private func getLanguageName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode) ?? languageCode
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
                _ = try await detectLanguage(request)
            } catch {
                if configuration.enableLogging {
                    print("[LanguageDetection] ⚠️ Queued detection failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: LanguageDetectionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: LanguageDetectionRequest) -> String {
        let textHash = request.text.hashValue
        let granularity = request.options.granularity.rawValue
        let maxHypotheses = request.options.maxHypotheses
        let threshold = Int(request.options.confidenceThreshold * 1000)
        let mixed = request.options.enableMixedLanguageDetection
        let segments = request.options.enableSegmentAnalysis
        let preferred = request.options.preferredLanguages.joined(separator: ",")
        
        return "\(textHash)_\(granularity)_\(maxHypotheses)_\(threshold)_\(mixed)_\(segments)_\(preferred)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalDetections)) + 1
        let totalDetections = metrics.totalDetections + 1
        let newCacheHitRate = cacheHits / Double(totalDetections)
        
        metrics = LanguageDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: metrics.successfulDetections + 1,
            failedDetections: metrics.failedDetections,
            averageProcessingTime: metrics.averageProcessingTime,
            detectionsByLanguage: metrics.detectionsByLanguage,
            detectionsByConfidence: metrics.detectionsByConfidence,
            detectionsByGranularity: metrics.detectionsByGranularity,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageTextLength: metrics.averageTextLength,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            mixedLanguageStats: metrics.mixedLanguageStats
        )
    }
    
    private func updateSuccessMetrics(_ result: LanguageDetectionResult) async {
        let totalDetections = metrics.totalDetections + 1
        let successfulDetections = metrics.successfulDetections + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalDetections)) + result.processingTime) / Double(totalDetections)
        
        var detectionsByLanguage = metrics.detectionsByLanguage
        if let dominantLanguage = result.dominantLanguage {
            detectionsByLanguage[dominantLanguage.languageCode, default: 0] += 1
        }
        
        var detectionsByConfidence = metrics.detectionsByConfidence
        let confidenceRange = getConfidenceRange(result.confidenceScore)
        detectionsByConfidence[confidenceRange, default: 0] += 1
        
        var detectionsByGranularity = metrics.detectionsByGranularity
        detectionsByGranularity[configuration.detectionGranularity.rawValue, default: 0] += 1
        
        let newAverageTextLength = ((metrics.averageTextLength * Double(metrics.successfulDetections)) + Double(result.textStatistics.characterCount)) / Double(successfulDetections)
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulDetections)) + result.confidenceScore) / Double(successfulDetections)
        
        // Update mixed language stats
        var mixedLanguageStats = metrics.mixedLanguageStats
        if let mixedAnalysis = result.mixedLanguageAnalysis, mixedAnalysis.isMixedLanguage {
            let totalMixed = mixedLanguageStats.totalMixedLanguageTexts + 1
            let avgLanguages = ((mixedLanguageStats.averageLanguagesPerText * Double(mixedLanguageStats.totalMixedLanguageTexts)) + Double(mixedAnalysis.languageDistribution.count)) / Double(totalMixed)
            
            mixedLanguageStats = LanguageDetectionMetrics.MixedLanguageStats(
                totalMixedLanguageTexts: totalMixed,
                averageLanguagesPerText: avgLanguages,
                mostCommonLanguagePairs: mixedLanguageStats.mostCommonLanguagePairs,
                codeSwitchFrequency: ((mixedLanguageStats.codeSwitchFrequency * Double(mixedLanguageStats.totalMixedLanguageTexts)) + Double(mixedAnalysis.codeSwitch.count)) / Double(totalMixed)
            )
        }
        
        metrics = LanguageDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: successfulDetections,
            failedDetections: metrics.failedDetections,
            averageProcessingTime: newAverageProcessingTime,
            detectionsByLanguage: detectionsByLanguage,
            detectionsByConfidence: detectionsByConfidence,
            detectionsByGranularity: detectionsByGranularity,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageTextLength: newAverageTextLength,
            averageConfidence: newAverageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            mixedLanguageStats: mixedLanguageStats
        )
    }
    
    private func updateFailureMetrics(_ result: LanguageDetectionResult) async {
        let totalDetections = metrics.totalDetections + 1
        let failedDetections = metrics.failedDetections + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = LanguageDetectionMetrics(
            totalDetections: totalDetections,
            successfulDetections: metrics.successfulDetections,
            failedDetections: failedDetections,
            averageProcessingTime: metrics.averageProcessingTime,
            detectionsByLanguage: metrics.detectionsByLanguage,
            detectionsByConfidence: metrics.detectionsByConfidence,
            detectionsByGranularity: metrics.detectionsByGranularity,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageTextLength: metrics.averageTextLength,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            mixedLanguageStats: metrics.mixedLanguageStats
        )
    }
    
    private func getConfidenceRange(_ confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "very-high"
        case 0.7..<0.9: return "high"
        case 0.5..<0.7: return "medium"
        case 0.3..<0.5: return "low"
        default: return "very-low"
        }
    }
    
    private func logDetection(_ result: LanguageDetectionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let charCount = result.textStatistics.characterCount
        let languageCode = result.detectedLanguageCode ?? "unknown"
        let confidence = String(format: "%.3f", result.confidenceScore)
        let languageCount = result.uniqueLanguages.count
        let isMixed = result.mixedLanguageAnalysis?.isMixedLanguage == true
        
        print("[LanguageDetection] \(statusIcon) Detection: \(charCount) chars, language: \(languageCode) (\(confidence)), \(languageCount) languages\(isMixed ? ", mixed" : "") (\(timeStr)s)")
        
        if let error = result.error {
            print("[LanguageDetection] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Language Detection Capability Implementation

/// Language Detection capability providing comprehensive language identification and analysis
@available(iOS 13.0, macOS 10.15, *)
public actor LanguageDetectionCapability: DomainCapability {
    public typealias ConfigurationType = LanguageDetectionCapabilityConfiguration
    public typealias ResourceType = LanguageDetectionCapabilityResource
    
    private var _configuration: LanguageDetectionCapabilityConfiguration
    private var _resources: LanguageDetectionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "language-detection-capability" }
    
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
    
    public var configuration: LanguageDetectionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: LanguageDetectionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: LanguageDetectionCapabilityConfiguration = LanguageDetectionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = LanguageDetectionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: LanguageDetectionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Language Detection configuration")
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
        // Language detection is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Language detection doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Language Detection Operations
    
    /// Detect language in text
    public func detectLanguage(_ request: LanguageDetectionRequest) async throws -> LanguageDetectionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return try await _resources.detectLanguage(request)
    }
    
    /// Cancel language detection
    public func cancelDetection(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        await _resources.cancelDetection(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<LanguageDetectionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get supported languages
    public func getSupportedLanguages() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.getSupportedLanguages()
    }
    
    /// Check if language is supported
    public func isLanguageSupported(_ languageCode: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.isLanguageSupported(languageCode)
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active detections
    public func getActiveDetections() async throws -> [LanguageDetectionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.getActiveDetections()
    }
    
    /// Get detection history
    public func getDetectionHistory(since: Date? = nil) async throws -> [LanguageDetectionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.getDetectionHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> LanguageDetectionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Language Detection capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick language detection with default options
    public func quickDetectLanguage(_ text: String, maxHypotheses: Int = 3) async throws -> String? {
        let options = LanguageDetectionRequest.DetectionOptions(maxHypotheses: maxHypotheses)
        let request = LanguageDetectionRequest(text: text, options: options)
        let result = try await detectLanguage(request)
        return result.detectedLanguageCode
    }
    
    /// Detect language with confidence
    public func detectLanguageWithConfidence(_ text: String, maxHypotheses: Int = 5) async throws -> [(String, Double)] {
        let options = LanguageDetectionRequest.DetectionOptions(maxHypotheses: maxHypotheses)
        let request = LanguageDetectionRequest(text: text, options: options)
        let result = try await detectLanguage(request)
        return result.languageHypotheses.map { ($0.languageCode, $0.confidence) }
    }
    
    /// Detect mixed languages
    public func detectMixedLanguages(_ text: String) async throws -> LanguageDetectionResult.MixedLanguageAnalysis? {
        let options = LanguageDetectionRequest.DetectionOptions(
            enableMixedLanguageDetection: true,
            enableSegmentAnalysis: true
        )
        let request = LanguageDetectionRequest(text: text, options: options)
        let result = try await detectLanguage(request)
        return result.mixedLanguageAnalysis
    }
    
    /// Batch detect languages for multiple texts
    public func batchDetectLanguages(_ texts: [String]) async throws -> [String?] {
        var results: [String?] = []
        
        for text in texts {
            let languageCode = try await quickDetectLanguage(text)
            results.append(languageCode)
        }
        
        return results
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
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Language Detection specific errors
public enum LanguageDetectionError: Error, LocalizedError {
    case languageDetectionDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case detectionError(String)
    case textTooShort
    case textTooLong
    case detectionQueued(UUID)
    case detectionTimeout(UUID)
    case recognizerNotAvailable
    case invalidText
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .languageDetectionDisabled:
            return "Language detection is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .detectionError(let reason):
            return "Language detection failed: \(reason)"
        case .textTooShort:
            return "Text is too short for language detection"
        case .textTooLong:
            return "Text is too long for language detection"
        case .detectionQueued(let id):
            return "Language detection queued: \(id)"
        case .detectionTimeout(let id):
            return "Language detection timeout: \(id)"
        case .recognizerNotAvailable:
            return "Language recognizer not available"
        case .invalidText:
            return "Invalid text provided for detection"
        case .configurationError(let reason):
            return "Language detection configuration error: \(reason)"
        }
    }
}