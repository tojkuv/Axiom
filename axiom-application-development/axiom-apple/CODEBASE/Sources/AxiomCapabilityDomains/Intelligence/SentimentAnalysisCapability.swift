import Foundation
import NaturalLanguage
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Sentiment Analysis Capability Configuration

/// Configuration for Sentiment Analysis capability
public struct SentimentAnalysisCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableSentimentAnalysis: Bool
    public let enableEmotionDetection: Bool
    public let enableConfidenceScoring: Bool
    public let enableBatchAnalysis: Bool
    public let enableRealTimeAnalysis: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentAnalyses: Int
    public let analysisTimeout: TimeInterval
    public let minimumTextLength: Int
    public let maximumTextLength: Int
    public let confidenceThreshold: Float
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let supportedLanguages: [String]
    public let defaultLanguage: String
    public let analysisGranularity: AnalysisGranularity
    
    public enum AnalysisGranularity: String, Codable, CaseIterable {
        case sentence = "sentence"
        case paragraph = "paragraph"
        case document = "document"
        case all = "all"
    }
    
    public init(
        enableSentimentAnalysis: Bool = true,
        enableEmotionDetection: Bool = true,
        enableConfidenceScoring: Bool = true,
        enableBatchAnalysis: Bool = true,
        enableRealTimeAnalysis: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentAnalyses: Int = 10,
        analysisTimeout: TimeInterval = 30.0,
        minimumTextLength: Int = 1,
        maximumTextLength: Int = 10000,
        confidenceThreshold: Float = 0.1,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        enablePerformanceOptimization: Bool = true,
        supportedLanguages: [String] = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar"],
        defaultLanguage: String = "en",
        analysisGranularity: AnalysisGranularity = .document
    ) {
        self.enableSentimentAnalysis = enableSentimentAnalysis
        self.enableEmotionDetection = enableEmotionDetection
        self.enableConfidenceScoring = enableConfidenceScoring
        self.enableBatchAnalysis = enableBatchAnalysis
        self.enableRealTimeAnalysis = enableRealTimeAnalysis
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentAnalyses = maxConcurrentAnalyses
        self.analysisTimeout = analysisTimeout
        self.minimumTextLength = minimumTextLength
        self.maximumTextLength = maximumTextLength
        self.confidenceThreshold = confidenceThreshold
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.supportedLanguages = supportedLanguages
        self.defaultLanguage = defaultLanguage
        self.analysisGranularity = analysisGranularity
    }
    
    public var isValid: Bool {
        maxConcurrentAnalyses > 0 &&
        analysisTimeout > 0 &&
        minimumTextLength >= 0 &&
        maximumTextLength > minimumTextLength &&
        confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0 &&
        cacheSize >= 0 &&
        !supportedLanguages.isEmpty &&
        !defaultLanguage.isEmpty
    }
    
    public func merged(with other: SentimentAnalysisCapabilityConfiguration) -> SentimentAnalysisCapabilityConfiguration {
        SentimentAnalysisCapabilityConfiguration(
            enableSentimentAnalysis: other.enableSentimentAnalysis,
            enableEmotionDetection: other.enableEmotionDetection,
            enableConfidenceScoring: other.enableConfidenceScoring,
            enableBatchAnalysis: other.enableBatchAnalysis,
            enableRealTimeAnalysis: other.enableRealTimeAnalysis,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentAnalyses: other.maxConcurrentAnalyses,
            analysisTimeout: other.analysisTimeout,
            minimumTextLength: other.minimumTextLength,
            maximumTextLength: other.maximumTextLength,
            confidenceThreshold: other.confidenceThreshold,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            supportedLanguages: other.supportedLanguages,
            defaultLanguage: other.defaultLanguage,
            analysisGranularity: other.analysisGranularity
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SentimentAnalysisCapabilityConfiguration {
        var adjustedTimeout = analysisTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAnalyses = maxConcurrentAnalyses
        var adjustedCacheSize = cacheSize
        var adjustedMaxTextLength = maximumTextLength
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(analysisTimeout, 15.0)
            adjustedConcurrentAnalyses = min(maxConcurrentAnalyses, 3)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedMaxTextLength = min(maximumTextLength, 5000)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return SentimentAnalysisCapabilityConfiguration(
            enableSentimentAnalysis: enableSentimentAnalysis,
            enableEmotionDetection: enableEmotionDetection,
            enableConfidenceScoring: enableConfidenceScoring,
            enableBatchAnalysis: enableBatchAnalysis,
            enableRealTimeAnalysis: enableRealTimeAnalysis,
            enableCustomModels: enableCustomModels,
            maxConcurrentAnalyses: adjustedConcurrentAnalyses,
            analysisTimeout: adjustedTimeout,
            minimumTextLength: minimumTextLength,
            maximumTextLength: adjustedMaxTextLength,
            confidenceThreshold: confidenceThreshold,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            supportedLanguages: supportedLanguages,
            defaultLanguage: defaultLanguage,
            analysisGranularity: analysisGranularity
        )
    }
}

// MARK: - Sentiment Analysis Types

/// Sentiment analysis request
public struct SentimentAnalysisRequest: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let options: AnalysisOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct AnalysisOptions: Sendable {
        public let language: String?
        public let enableEmotionDetection: Bool
        public let granularity: SentimentAnalysisCapabilityConfiguration.AnalysisGranularity
        public let customModelId: String?
        public let includeConfidenceScores: Bool
        public let enableDetailedAnalysis: Bool
        public let contextualKeywords: [String]
        public let analysisCategories: Set<AnalysisCategory>
        
        public enum AnalysisCategory: String, Sendable, CaseIterable {
            case overall = "overall"
            case aspectBased = "aspect-based"
            case emotional = "emotional"
            case topical = "topical"
            case temporal = "temporal"
        }
        
        public init(
            language: String? = nil,
            enableEmotionDetection: Bool = true,
            granularity: SentimentAnalysisCapabilityConfiguration.AnalysisGranularity = .document,
            customModelId: String? = nil,
            includeConfidenceScores: Bool = true,
            enableDetailedAnalysis: Bool = false,
            contextualKeywords: [String] = [],
            analysisCategories: Set<AnalysisCategory> = [.overall, .emotional]
        ) {
            self.language = language
            self.enableEmotionDetection = enableEmotionDetection
            self.granularity = granularity
            self.customModelId = customModelId
            self.includeConfidenceScores = includeConfidenceScores
            self.enableDetailedAnalysis = enableDetailedAnalysis
            self.contextualKeywords = contextualKeywords
            self.analysisCategories = analysisCategories
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
        options: AnalysisOptions = AnalysisOptions(),
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

/// Sentiment analysis result
public struct SentimentAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let overallSentiment: SentimentScore
    public let detailedAnalysis: DetailedAnalysis?
    public let emotions: [EmotionScore]
    public let aspectAnalysis: [AspectSentiment]
    public let temporalAnalysis: [TemporalSentiment]?
    public let textMetadata: TextMetadata
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: SentimentAnalysisError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct SentimentScore: Sendable {
        public let sentiment: SentimentType
        public let confidence: Float
        public let score: Float
        public let normalizedScore: Float
        
        public enum SentimentType: String, Sendable, CaseIterable {
            case positive = "positive"
            case negative = "negative"
            case neutral = "neutral"
            case mixed = "mixed"
        }
        
        public init(sentiment: SentimentType, confidence: Float, score: Float) {
            self.sentiment = sentiment
            self.confidence = confidence
            self.score = score
            self.normalizedScore = (score + 1.0) / 2.0 // Normalize from [-1,1] to [0,1]
        }
    }
    
    public struct DetailedAnalysis: Sendable {
        public let sentenceAnalysis: [SentenceAnalysis]
        public let keyPhrases: [KeyPhrase]
        public let sentimentIntensity: Float
        public let emotionalRange: Float
        public let subjectivity: Float
        
        public struct SentenceAnalysis: Sendable {
            public let text: String
            public let range: Range<String.Index>
            public let sentiment: SentimentScore
            public let emotions: [EmotionScore]
            
            public init(text: String, range: Range<String.Index>, sentiment: SentimentScore, emotions: [EmotionScore]) {
                self.text = text
                self.range = range
                self.sentiment = sentiment
                self.emotions = emotions
            }
        }
        
        public struct KeyPhrase: Sendable {
            public let phrase: String
            public let sentiment: SentimentScore
            public let importance: Float
            public let frequency: Int
            
            public init(phrase: String, sentiment: SentimentScore, importance: Float, frequency: Int) {
                self.phrase = phrase
                self.sentiment = sentiment
                self.importance = importance
                self.frequency = frequency
            }
        }
        
        public init(sentenceAnalysis: [SentenceAnalysis], keyPhrases: [KeyPhrase], sentimentIntensity: Float, emotionalRange: Float, subjectivity: Float) {
            self.sentenceAnalysis = sentenceAnalysis
            self.keyPhrases = keyPhrases
            self.sentimentIntensity = sentimentIntensity
            self.emotionalRange = emotionalRange
            self.subjectivity = subjectivity
        }
    }
    
    public struct EmotionScore: Sendable {
        public let emotion: EmotionType
        public let confidence: Float
        public let intensity: Float
        
        public enum EmotionType: String, Sendable, CaseIterable {
            case joy = "joy"
            case sadness = "sadness"
            case anger = "anger"
            case fear = "fear"
            case surprise = "surprise"
            case disgust = "disgust"
            case anticipation = "anticipation"
            case trust = "trust"
            case love = "love"
            case excitement = "excitement"
            case disappointment = "disappointment"
            case frustration = "frustration"
        }
        
        public init(emotion: EmotionType, confidence: Float, intensity: Float) {
            self.emotion = emotion
            self.confidence = confidence
            self.intensity = intensity
        }
    }
    
    public struct AspectSentiment: Sendable {
        public let aspect: String
        public let sentiment: SentimentScore
        public let mentions: [String]
        public let importance: Float
        
        public init(aspect: String, sentiment: SentimentScore, mentions: [String], importance: Float) {
            self.aspect = aspect
            self.sentiment = sentiment
            self.mentions = mentions
            self.importance = importance
        }
    }
    
    public struct TemporalSentiment: Sendable {
        public let timeRange: Range<String.Index>
        public let sentiment: SentimentScore
        public let emotionalProgression: [EmotionScore]
        
        public init(timeRange: Range<String.Index>, sentiment: SentimentScore, emotionalProgression: [EmotionScore]) {
            self.timeRange = timeRange
            self.sentiment = sentiment
            self.emotionalProgression = emotionalProgression
        }
    }
    
    public struct TextMetadata: Sendable {
        public let language: String
        public let wordCount: Int
        public let sentenceCount: Int
        public let avgWordsPerSentence: Double
        public let complexity: Float
        public let readabilityScore: Float?
        
        public init(language: String, wordCount: Int, sentenceCount: Int, complexity: Float, readabilityScore: Float? = nil) {
            self.language = language
            self.wordCount = wordCount
            self.sentenceCount = sentenceCount
            self.avgWordsPerSentence = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0
            self.complexity = complexity
            self.readabilityScore = readabilityScore
        }
    }
    
    public init(
        requestId: UUID,
        overallSentiment: SentimentScore,
        detailedAnalysis: DetailedAnalysis? = nil,
        emotions: [EmotionScore] = [],
        aspectAnalysis: [AspectSentiment] = [],
        temporalAnalysis: [TemporalSentiment]? = nil,
        textMetadata: TextMetadata,
        processingTime: TimeInterval,
        success: Bool,
        error: SentimentAnalysisError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.overallSentiment = overallSentiment
        self.detailedAnalysis = detailedAnalysis
        self.emotions = emotions
        self.aspectAnalysis = aspectAnalysis
        self.temporalAnalysis = temporalAnalysis
        self.textMetadata = textMetadata
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var dominantEmotion: EmotionScore? {
        emotions.max(by: { $0.confidence < $1.confidence })
    }
    
    public var sentimentPolarity: Float {
        overallSentiment.score
    }
    
    public var emotionalDiversity: Float {
        guard !emotions.isEmpty else { return 0.0 }
        let totalIntensity = emotions.reduce(0) { $0 + $1.intensity }
        return totalIntensity / Float(emotions.count)
    }
}

/// Sentiment analysis metrics
public struct SentimentAnalysisMetrics: Sendable {
    public let totalAnalyses: Int
    public let successfulAnalyses: Int
    public let failedAnalyses: Int
    public let averageProcessingTime: TimeInterval
    public let analysesByLanguage: [String: Int]
    public let analysesByGranularity: [String: Int]
    public let sentimentDistribution: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageTextLength: Double
    public let averageConfidence: Double
    public let throughputPerSecond: Double
    public let emotionDetectionStats: EmotionDetectionStats
    
    public struct EmotionDetectionStats: Sendable {
        public let totalEmotionsDetected: Int
        public let emotionDistribution: [String: Int]
        public let averageEmotionalIntensity: Double
        public let mostFrequentEmotion: String?
        
        public init(totalEmotionsDetected: Int = 0, emotionDistribution: [String: Int] = [:], averageEmotionalIntensity: Double = 0, mostFrequentEmotion: String? = nil) {
            self.totalEmotionsDetected = totalEmotionsDetected
            self.emotionDistribution = emotionDistribution
            self.averageEmotionalIntensity = averageEmotionalIntensity
            self.mostFrequentEmotion = mostFrequentEmotion
        }
    }
    
    public init(
        totalAnalyses: Int = 0,
        successfulAnalyses: Int = 0,
        failedAnalyses: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        analysesByLanguage: [String: Int] = [:],
        analysesByGranularity: [String: Int] = [:],
        sentimentDistribution: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageTextLength: Double = 0,
        averageConfidence: Double = 0,
        throughputPerSecond: Double = 0,
        emotionDetectionStats: EmotionDetectionStats = EmotionDetectionStats()
    ) {
        self.totalAnalyses = totalAnalyses
        self.successfulAnalyses = successfulAnalyses
        self.failedAnalyses = failedAnalyses
        self.averageProcessingTime = averageProcessingTime
        self.analysesByLanguage = analysesByLanguage
        self.analysesByGranularity = analysesByGranularity
        self.sentimentDistribution = sentimentDistribution
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageTextLength = averageTextLength
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalAnalyses) / averageProcessingTime : 0
        self.emotionDetectionStats = emotionDetectionStats
    }
    
    public var successRate: Double {
        totalAnalyses > 0 ? Double(successfulAnalyses) / Double(totalAnalyses) : 0
    }
}

// MARK: - Sentiment Analysis Resource

/// Sentiment analysis resource management
@available(iOS 13.0, macOS 10.15, *)
public actor SentimentAnalysisCapabilityResource: AxiomCapabilityResource {
    private let configuration: SentimentAnalysisCapabilityConfiguration
    private var activeAnalyses: [UUID: SentimentAnalysisRequest] = [:]
    private var analysisQueue: [SentimentAnalysisRequest] = []
    private var analysisHistory: [SentimentAnalysisResult] = []
    private var resultCache: [String: SentimentAnalysisResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var sentimentClassifier: NLModel?
    private var languageRecognizer: NLLanguageRecognizer?
    private var tokenizer: NLTokenizer?
    private var metrics: SentimentAnalysisMetrics = SentimentAnalysisMetrics()
    private var resultStreamContinuation: AsyncStream<SentimentAnalysisResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: SentimentAnalysisCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 180_000_000, // 180MB for sentiment analysis
            cpu: 2.5, // Moderate CPU usage for text processing
            bandwidth: 0,
            storage: 60_000_000 // 60MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let analysisMemory = activeAnalyses.count * 15_000_000 // ~15MB per active analysis
            let cacheMemory = resultCache.count * 80_000 // ~80KB per cached result
            let modelMemory = customModels.count * 50_000_000 // ~50MB per loaded model
            let historyMemory = analysisHistory.count * 12_000
            let nlModelMemory = sentimentClassifier != nil ? 40_000_000 : 0
            
            return ResourceUsage(
                memory: analysisMemory + cacheMemory + modelMemory + historyMemory + nlModelMemory + 25_000_000,
                cpu: activeAnalyses.isEmpty ? 0.2 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 40_000 + customModels.count * 100_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Sentiment analysis is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableSentimentAnalysis
        }
        return false
    }
    
    public func release() async {
        activeAnalyses.removeAll()
        analysisQueue.removeAll()
        analysisHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        sentimentClassifier = nil
        languageRecognizer = nil
        tokenizer = nil
        
        resultStreamContinuation?.finish()
        
        metrics = SentimentAnalysisMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize sentiment classifier
        await loadSentimentClassifier()
        
        // Initialize language recognizer for multilingual support
        if configuration.supportedLanguages.count > 1 {
            languageRecognizer = NLLanguageRecognizer()
        }
        
        // Initialize tokenizer
        tokenizer = NLTokenizer(unit: .sentence)
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[SentimentAnalysis] 🚀 Sentiment Analysis capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: SentimentAnalysisCapabilityConfiguration) async throws {
        // Update sentiment analysis configurations
        await loadSentimentClassifier()
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<SentimentAnalysisResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw SentimentAnalysisError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[SentimentAnalysis] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw SentimentAnalysisError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[SentimentAnalysis] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Sentiment Analysis
    
    public func analyzeSentiment(_ request: SentimentAnalysisRequest) async throws -> SentimentAnalysisResult {
        guard configuration.enableSentimentAnalysis else {
            throw SentimentAnalysisError.sentimentAnalysisDisabled
        }
        
        // Validate text length
        guard request.text.count >= configuration.minimumTextLength else {
            throw SentimentAnalysisError.textTooShort
        }
        guard request.text.count <= configuration.maximumTextLength else {
            throw SentimentAnalysisError.textTooLong
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
            throw SentimentAnalysisError.analysisQueued(request.id)
        }
        
        let startTime = Date()
        activeAnalyses[request.id] = request
        
        do {
            // Detect language if not specified
            let language = request.options.language ?? await detectLanguage(request.text)
            
            // Perform sentiment analysis
            let result = try await performSentimentAnalysis(
                text: request.text,
                language: language,
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
            let result = SentimentAnalysisResult(
                requestId: request.id,
                overallSentiment: SentimentAnalysisResult.SentimentScore(sentiment: .neutral, confidence: 0.0, score: 0.0),
                textMetadata: SentimentAnalysisResult.TextMetadata(
                    language: configuration.defaultLanguage,
                    wordCount: request.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
                    sentenceCount: 1,
                    complexity: 0.0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? SentimentAnalysisError ?? SentimentAnalysisError.analysisError(error.localizedDescription)
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
            print("[SentimentAnalysis] 🚫 Cancelled analysis: \(requestId)")
        }
    }
    
    public func getActiveAnalyses() async -> [SentimentAnalysisRequest] {
        return Array(activeAnalyses.values)
    }
    
    public func getAnalysisHistory(since: Date? = nil) async -> [SentimentAnalysisResult] {
        if let since = since {
            return analysisHistory.filter { $0.timestamp >= since }
        }
        return analysisHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> SentimentAnalysisMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = SentimentAnalysisMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadSentimentClassifier() async {
        do {
            sentimentClassifier = try NLModel(mlModel: NLModel.sentiment)
            
            if configuration.enableLogging {
                print("[SentimentAnalysis] 📦 Loaded sentiment classifier")
            }
        } catch {
            if configuration.enableLogging {
                print("[SentimentAnalysis] ⚠️ Failed to load sentiment classifier: \(error)")
            }
        }
    }
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[SentimentAnalysis] ⚡ Performance optimization enabled")
        }
    }
    
    private func detectLanguage(_ text: String) async -> String {
        guard let recognizer = languageRecognizer else {
            return configuration.defaultLanguage
        }
        
        recognizer.reset()
        recognizer.processString(text)
        
        let dominantLanguage = recognizer.dominantLanguage?.rawValue ?? configuration.defaultLanguage
        return configuration.supportedLanguages.contains(dominantLanguage) ? dominantLanguage : configuration.defaultLanguage
    }
    
    private func performSentimentAnalysis(
        text: String,
        language: String,
        request: SentimentAnalysisRequest,
        startTime: Date
    ) async throws -> SentimentAnalysisResult {
        
        // Analyze overall sentiment
        let overallSentiment = await analyzeSentimentScore(text: text)
        
        // Create text metadata
        let textMetadata = createTextMetadata(text: text, language: language)
        
        // Perform detailed analysis if requested
        var detailedAnalysis: SentimentAnalysisResult.DetailedAnalysis?
        if request.options.enableDetailedAnalysis {
            detailedAnalysis = await performDetailedAnalysis(text: text)
        }
        
        // Detect emotions if enabled
        var emotions: [SentimentAnalysisResult.EmotionScore] = []
        if request.options.enableEmotionDetection && configuration.enableEmotionDetection {
            emotions = await detectEmotions(text: text)
        }
        
        // Perform aspect-based analysis if requested
        var aspectAnalysis: [SentimentAnalysisResult.AspectSentiment] = []
        if request.options.analysisCategories.contains(.aspectBased) {
            aspectAnalysis = await performAspectAnalysis(text: text)
        }
        
        // Perform temporal analysis if requested
        var temporalAnalysis: [SentimentAnalysisResult.TemporalSentiment]?
        if request.options.analysisCategories.contains(.temporal) {
            temporalAnalysis = await performTemporalAnalysis(text: text)
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return SentimentAnalysisResult(
            requestId: request.id,
            overallSentiment: overallSentiment,
            detailedAnalysis: detailedAnalysis,
            emotions: emotions,
            aspectAnalysis: aspectAnalysis,
            temporalAnalysis: temporalAnalysis,
            textMetadata: textMetadata,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func analyzeSentimentScore(text: String) async -> SentimentAnalysisResult.SentimentScore {
        guard let classifier = sentimentClassifier else {
            return SentimentAnalysisResult.SentimentScore(sentiment: .neutral, confidence: 0.5, score: 0.0)
        }
        
        // Use NLModel for sentiment classification
        let prediction = classifier.prediction(from: text)
        let sentimentLabel = prediction?.label ?? "neutral"
        let confidence = prediction?.confidence ?? 0.5
        
        let sentimentType: SentimentAnalysisResult.SentimentScore.SentimentType
        let score: Float
        
        switch sentimentLabel.lowercased() {
        case "positive":
            sentimentType = .positive
            score = Float(confidence)
        case "negative":
            sentimentType = .negative
            score = -Float(confidence)
        default:
            sentimentType = .neutral
            score = 0.0
        }
        
        return SentimentAnalysisResult.SentimentScore(
            sentiment: sentimentType,
            confidence: Float(confidence),
            score: score
        )
    }
    
    private func createTextMetadata(text: String, language: String) -> SentimentAnalysisResult.TextMetadata {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Simple complexity calculation based on sentence and word length
        let avgWordLength = words.isEmpty ? 0 : words.reduce(0) { $0 + $1.count } / words.count
        let complexity = Float(avgWordLength) / 10.0 // Normalize to 0-1 range roughly
        
        return SentimentAnalysisResult.TextMetadata(
            language: language,
            wordCount: words.count,
            sentenceCount: sentences.count,
            complexity: min(complexity, 1.0)
        )
    }
    
    private func performDetailedAnalysis(text: String) async -> SentimentAnalysisResult.DetailedAnalysis {
        guard let tokenizer = tokenizer else {
            return SentimentAnalysisResult.DetailedAnalysis(
                sentenceAnalysis: [],
                keyPhrases: [],
                sentimentIntensity: 0.5,
                emotionalRange: 0.5,
                subjectivity: 0.5
            )
        }
        
        // Tokenize into sentences
        tokenizer.string = text
        var sentenceAnalysis: [SentimentAnalysisResult.DetailedAnalysis.SentenceAnalysis] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let sentence = String(text[tokenRange])
            let sentiment = Task { await self.analyzeSentimentScore(text: sentence) }
            let emotions = Task { await self.detectEmotions(text: sentence) }
            
            Task {
                let sentimentResult = await sentiment.value
                let emotionResults = await emotions.value
                
                sentenceAnalysis.append(SentimentAnalysisResult.DetailedAnalysis.SentenceAnalysis(
                    text: sentence,
                    range: tokenRange,
                    sentiment: sentimentResult,
                    emotions: emotionResults
                ))
            }
            
            return true
        }
        
        // Extract key phrases (simplified)
        let keyPhrases = await extractKeyPhrases(text: text)
        
        // Calculate sentiment intensity and emotional range
        let sentimentIntensity = sentenceAnalysis.isEmpty ? 0.5 : sentenceAnalysis.reduce(0) { $0 + abs($1.sentiment.score) } / Float(sentenceAnalysis.count)
        let emotionalRange = sentenceAnalysis.isEmpty ? 0.5 : calculateEmotionalRange(sentenceAnalysis)
        
        return SentimentAnalysisResult.DetailedAnalysis(
            sentenceAnalysis: sentenceAnalysis,
            keyPhrases: keyPhrases,
            sentimentIntensity: sentimentIntensity,
            emotionalRange: emotionalRange,
            subjectivity: 0.5 // Simplified calculation
        )
    }
    
    private func detectEmotions(text: String) async -> [SentimentAnalysisResult.EmotionScore] {
        // Simplified emotion detection based on keyword matching
        let emotionKeywords: [SentimentAnalysisResult.EmotionScore.EmotionType: [String]] = [
            .joy: ["happy", "joy", "excited", "pleased", "delighted", "cheerful"],
            .sadness: ["sad", "depressed", "disappointed", "melancholy", "grief"],
            .anger: ["angry", "furious", "mad", "irritated", "annoyed"],
            .fear: ["afraid", "scared", "terrified", "anxious", "worried"],
            .surprise: ["surprised", "amazed", "astonished", "shocked"],
            .love: ["love", "adore", "cherish", "affection", "caring"],
            .excitement: ["excited", "thrilled", "enthusiastic", "energetic"],
            .disappointment: ["disappointed", "let down", "frustrated"]
        ]
        
        var emotions: [SentimentAnalysisResult.EmotionScore] = []
        let lowercaseText = text.lowercased()
        
        for (emotion, keywords) in emotionKeywords {
            let matches = keywords.filter { lowercaseText.contains($0) }
            if !matches.isEmpty {
                let intensity = Float(matches.count) / Float(keywords.count)
                let confidence = min(intensity * 2.0, 1.0) // Scale confidence
                
                emotions.append(SentimentAnalysisResult.EmotionScore(
                    emotion: emotion,
                    confidence: confidence,
                    intensity: intensity
                ))
            }
        }
        
        return emotions.sorted { $0.confidence > $1.confidence }
    }
    
    private func performAspectAnalysis(text: String) async -> [SentimentAnalysisResult.AspectSentiment] {
        // Simplified aspect-based sentiment analysis
        let commonAspects = ["price", "quality", "service", "delivery", "support", "product", "experience"]
        var aspectAnalysis: [SentimentAnalysisResult.AspectSentiment] = []
        
        for aspect in commonAspects {
            if text.lowercased().contains(aspect) {
                let sentiment = await analyzeSentimentScore(text: text) // Simplified - would analyze context around aspect
                aspectAnalysis.append(SentimentAnalysisResult.AspectSentiment(
                    aspect: aspect,
                    sentiment: sentiment,
                    mentions: [aspect], // Simplified
                    importance: 0.5
                ))
            }
        }
        
        return aspectAnalysis
    }
    
    private func performTemporalAnalysis(text: String) async -> [SentimentAnalysisResult.TemporalSentiment] {
        // Simplified temporal analysis - divide text into segments
        let segments = text.split(separator: ".", omittingEmptySubsequences: true)
        var temporalAnalysis: [SentimentAnalysisResult.TemporalSentiment] = []
        
        for (index, segment) in segments.enumerated() {
            let segmentText = String(segment)
            let sentiment = await analyzeSentimentScore(text: segmentText)
            let emotions = await detectEmotions(text: segmentText)
            
            if let range = text.range(of: segmentText) {
                temporalAnalysis.append(SentimentAnalysisResult.TemporalSentiment(
                    timeRange: range,
                    sentiment: sentiment,
                    emotionalProgression: emotions
                ))
            }
        }
        
        return temporalAnalysis
    }
    
    private func extractKeyPhrases(text: String) async -> [SentimentAnalysisResult.DetailedAnalysis.KeyPhrase] {
        // Simplified key phrase extraction
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordFrequency = Dictionary(grouping: words) { $0.lowercased() }.mapValues { $0.count }
        
        let topWords = wordFrequency.sorted { $0.value > $1.value }.prefix(5)
        
        var keyPhrases: [SentimentAnalysisResult.DetailedAnalysis.KeyPhrase] = []
        for (word, frequency) in topWords where word.count > 3 {
            let sentiment = await analyzeSentimentScore(text: word)
            keyPhrases.append(SentimentAnalysisResult.DetailedAnalysis.KeyPhrase(
                phrase: word,
                sentiment: sentiment,
                importance: Float(frequency) / Float(words.count),
                frequency: frequency
            ))
        }
        
        return keyPhrases
    }
    
    private func calculateEmotionalRange(_ sentenceAnalysis: [SentimentAnalysisResult.DetailedAnalysis.SentenceAnalysis]) -> Float {
        let sentimentScores = sentenceAnalysis.map { $0.sentiment.score }
        guard !sentimentScores.isEmpty else { return 0.0 }
        
        let maxScore = sentimentScores.max() ?? 0.0
        let minScore = sentimentScores.min() ?? 0.0
        return abs(maxScore - minScore)
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
                _ = try await analyzeSentiment(request)
            } catch {
                if configuration.enableLogging {
                    print("[SentimentAnalysis] ⚠️ Queued analysis failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: SentimentAnalysisRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: SentimentAnalysisRequest) -> String {
        let textHash = request.text.hashValue
        let language = request.options.language ?? configuration.defaultLanguage
        let granularity = request.options.granularity.rawValue
        let emotions = request.options.enableEmotionDetection
        let detailed = request.options.enableDetailedAnalysis
        let categories = request.options.analysisCategories.map { $0.rawValue }.sorted().joined(separator: ",")
        
        return "\(textHash)_\(language)_\(granularity)_\(emotions)_\(detailed)_\(categories)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalAnalyses)) + 1
        let totalAnalyses = metrics.totalAnalyses + 1
        let newCacheHitRate = cacheHits / Double(totalAnalyses)
        
        metrics = SentimentAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses + 1,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByLanguage: metrics.analysesByLanguage,
            analysesByGranularity: metrics.analysesByGranularity,
            sentimentDistribution: metrics.sentimentDistribution,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageTextLength: metrics.averageTextLength,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            emotionDetectionStats: metrics.emotionDetectionStats
        )
    }
    
    private func updateSuccessMetrics(_ result: SentimentAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let successfulAnalyses = metrics.successfulAnalyses + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAnalyses)) + result.processingTime) / Double(totalAnalyses)
        
        var analysesByLanguage = metrics.analysesByLanguage
        analysesByLanguage[result.textMetadata.language, default: 0] += 1
        
        var analysesByGranularity = metrics.analysesByGranularity
        analysesByGranularity[configuration.analysisGranularity.rawValue, default: 0] += 1
        
        var sentimentDistribution = metrics.sentimentDistribution
        sentimentDistribution[result.overallSentiment.sentiment.rawValue, default: 0] += 1
        
        let newAverageTextLength = ((metrics.averageTextLength * Double(metrics.successfulAnalyses)) + Double(result.textMetadata.wordCount)) / Double(successfulAnalyses)
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulAnalyses)) + Double(result.overallSentiment.confidence)) / Double(successfulAnalyses)
        
        // Update emotion detection stats
        var emotionStats = metrics.emotionDetectionStats
        if !result.emotions.isEmpty {
            let totalEmotions = emotionStats.totalEmotionsDetected + result.emotions.count
            var emotionDistribution = emotionStats.emotionDistribution
            
            for emotion in result.emotions {
                emotionDistribution[emotion.emotion.rawValue, default: 0] += 1
            }
            
            let avgIntensity = result.emotions.reduce(0) { $0 + $1.intensity } / Float(result.emotions.count)
            let newAvgEmotionalIntensity = ((emotionStats.averageEmotionalIntensity * Double(emotionStats.totalEmotionsDetected)) + Double(avgIntensity)) / Double(totalEmotions)
            
            emotionStats = SentimentAnalysisMetrics.EmotionDetectionStats(
                totalEmotionsDetected: totalEmotions,
                emotionDistribution: emotionDistribution,
                averageEmotionalIntensity: newAvgEmotionalIntensity,
                mostFrequentEmotion: emotionDistribution.max(by: { $0.value < $1.value })?.key
            )
        }
        
        metrics = SentimentAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: successfulAnalyses,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: newAverageProcessingTime,
            analysesByLanguage: analysesByLanguage,
            analysesByGranularity: analysesByGranularity,
            sentimentDistribution: sentimentDistribution,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageTextLength: newAverageTextLength,
            averageConfidence: newAverageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            emotionDetectionStats: emotionStats
        )
    }
    
    private func updateFailureMetrics(_ result: SentimentAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let failedAnalyses = metrics.failedAnalyses + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = SentimentAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses,
            failedAnalyses: failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByLanguage: metrics.analysesByLanguage,
            analysesByGranularity: metrics.analysesByGranularity,
            sentimentDistribution: metrics.sentimentDistribution,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageTextLength: metrics.averageTextLength,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond,
            emotionDetectionStats: metrics.emotionDetectionStats
        )
    }
    
    private func logAnalysis(_ result: SentimentAnalysisResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let wordCount = result.textMetadata.wordCount
        let sentiment = result.overallSentiment.sentiment.rawValue
        let confidence = String(format: "%.3f", result.overallSentiment.confidence)
        let emotionCount = result.emotions.count
        
        print("[SentimentAnalysis] \(statusIcon) Analysis: \(wordCount) words, sentiment: \(sentiment) (\(confidence)), \(emotionCount) emotions (\(timeStr)s)")
        
        if let error = result.error {
            print("[SentimentAnalysis] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sentiment Analysis Capability Implementation

/// Sentiment Analysis capability providing comprehensive text sentiment and emotion analysis
@available(iOS 13.0, macOS 10.15, *)
public actor SentimentAnalysisCapability: DomainCapability {
    public typealias ConfigurationType = SentimentAnalysisCapabilityConfiguration
    public typealias ResourceType = SentimentAnalysisCapabilityResource
    
    private var _configuration: SentimentAnalysisCapabilityConfiguration
    private var _resources: SentimentAnalysisCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "sentiment-analysis-capability" }
    
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
    
    public var configuration: SentimentAnalysisCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: SentimentAnalysisCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SentimentAnalysisCapabilityConfiguration = SentimentAnalysisCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SentimentAnalysisCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: SentimentAnalysisCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Sentiment Analysis configuration")
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
        // Sentiment analysis is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Sentiment analysis doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Sentiment Analysis Operations
    
    /// Analyze sentiment and emotions in text
    public func analyzeSentiment(_ request: SentimentAnalysisRequest) async throws -> SentimentAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return try await _resources.analyzeSentiment(request)
    }
    
    /// Cancel sentiment analysis
    public func cancelAnalysis(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        await _resources.cancelAnalysis(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<SentimentAnalysisResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active analyses
    public func getActiveAnalyses() async throws -> [SentimentAnalysisRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return await _resources.getActiveAnalyses()
    }
    
    /// Get analysis history
    public func getAnalysisHistory(since: Date? = nil) async throws -> [SentimentAnalysisResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return await _resources.getAnalysisHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> SentimentAnalysisMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Sentiment Analysis capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick sentiment analysis with default options
    public func quickAnalyzeSentiment(_ text: String, language: String? = nil) async throws -> SentimentAnalysisResult.SentimentScore {
        let options = SentimentAnalysisRequest.AnalysisOptions(language: language)
        let request = SentimentAnalysisRequest(text: text, options: options)
        let result = try await analyzeSentiment(request)
        return result.overallSentiment
    }
    
    /// Analyze emotions in text
    public func analyzeEmotions(_ text: String, language: String? = nil) async throws -> [SentimentAnalysisResult.EmotionScore] {
        let options = SentimentAnalysisRequest.AnalysisOptions(
            language: language,
            enableEmotionDetection: true,
            analysisCategories: [.emotional]
        )
        let request = SentimentAnalysisRequest(text: text, options: options)
        let result = try await analyzeSentiment(request)
        return result.emotions
    }
    
    /// Batch analyze multiple texts
    public func batchAnalyzeSentiment(_ texts: [String], language: String? = nil) async throws -> [SentimentAnalysisResult] {
        var results: [SentimentAnalysisResult] = []
        
        for text in texts {
            let options = SentimentAnalysisRequest.AnalysisOptions(language: language)
            let request = SentimentAnalysisRequest(text: text, options: options)
            let result = try await analyzeSentiment(request)
            results.append(result)
        }
        
        return results
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

/// Sentiment Analysis specific errors
public enum SentimentAnalysisError: Error, LocalizedError {
    case sentimentAnalysisDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case analysisError(String)
    case textTooShort
    case textTooLong
    case analysisQueued(UUID)
    case analysisTimeout(UUID)
    case languageNotSupported(String)
    case invalidText
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .sentimentAnalysisDisabled:
            return "Sentiment analysis is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .analysisError(let reason):
            return "Sentiment analysis failed: \(reason)"
        case .textTooShort:
            return "Text is too short for analysis"
        case .textTooLong:
            return "Text is too long for analysis"
        case .analysisQueued(let id):
            return "Sentiment analysis queued: \(id)"
        case .analysisTimeout(let id):
            return "Sentiment analysis timeout: \(id)"
        case .languageNotSupported(let language):
            return "Language not supported: \(language)"
        case .invalidText:
            return "Invalid text provided for analysis"
        case .configurationError(let reason):
            return "Sentiment analysis configuration error: \(reason)"
        }
    }
}