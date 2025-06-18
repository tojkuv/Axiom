import Foundation
import NaturalLanguage
import AxiomCore
import AxiomCapabilities

// MARK: - Natural Language Capability Configuration

/// Configuration for Natural Language capability
public struct NaturalLanguageCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableNaturalLanguage: Bool
    public let enableLanguageDetection: Bool
    public let enableSentimentAnalysis: Bool
    public let enableNamedEntityRecognition: Bool
    public let enablePartOfSpeechTagging: Bool
    public let enableTokenization: Bool
    public let enableTextClassification: Bool
    public let enableTextEmbedding: Bool
    public let maxConcurrentRequests: Int
    public let requestTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let preferredLanguages: [String]
    public let minimumConfidence: Float
    
    public init(
        enableNaturalLanguage: Bool = true,
        enableLanguageDetection: Bool = true,
        enableSentimentAnalysis: Bool = true,
        enableNamedEntityRecognition: Bool = true,
        enablePartOfSpeechTagging: Bool = true,
        enableTokenization: Bool = true,
        enableTextClassification: Bool = true,
        enableTextEmbedding: Bool = true,
        maxConcurrentRequests: Int = 20,
        requestTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 500,
        enablePerformanceOptimization: Bool = true,
        preferredLanguages: [String] = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh"],
        minimumConfidence: Float = 0.1
    ) {
        self.enableNaturalLanguage = enableNaturalLanguage
        self.enableLanguageDetection = enableLanguageDetection
        self.enableSentimentAnalysis = enableSentimentAnalysis
        self.enableNamedEntityRecognition = enableNamedEntityRecognition
        self.enablePartOfSpeechTagging = enablePartOfSpeechTagging
        self.enableTokenization = enableTokenization
        self.enableTextClassification = enableTextClassification
        self.enableTextEmbedding = enableTextEmbedding
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestTimeout = requestTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.preferredLanguages = preferredLanguages
        self.minimumConfidence = minimumConfidence
    }
    
    public var isValid: Bool {
        maxConcurrentRequests > 0 &&
        requestTimeout > 0 &&
        cacheSize >= 0 &&
        minimumConfidence >= 0.0 && minimumConfidence <= 1.0
    }
    
    public func merged(with other: NaturalLanguageCapabilityConfiguration) -> NaturalLanguageCapabilityConfiguration {
        NaturalLanguageCapabilityConfiguration(
            enableNaturalLanguage: other.enableNaturalLanguage,
            enableLanguageDetection: other.enableLanguageDetection,
            enableSentimentAnalysis: other.enableSentimentAnalysis,
            enableNamedEntityRecognition: other.enableNamedEntityRecognition,
            enablePartOfSpeechTagging: other.enablePartOfSpeechTagging,
            enableTokenization: other.enableTokenization,
            enableTextClassification: other.enableTextClassification,
            enableTextEmbedding: other.enableTextEmbedding,
            maxConcurrentRequests: other.maxConcurrentRequests,
            requestTimeout: other.requestTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            preferredLanguages: other.preferredLanguages,
            minimumConfidence: other.minimumConfidence
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> NaturalLanguageCapabilityConfiguration {
        var adjustedTimeout = requestTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRequests = maxConcurrentRequests
        var adjustedCacheSize = cacheSize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(requestTimeout, 15.0)
            adjustedConcurrentRequests = min(maxConcurrentRequests, 5)
            adjustedCacheSize = min(cacheSize, 100)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return NaturalLanguageCapabilityConfiguration(
            enableNaturalLanguage: enableNaturalLanguage,
            enableLanguageDetection: enableLanguageDetection,
            enableSentimentAnalysis: enableSentimentAnalysis,
            enableNamedEntityRecognition: enableNamedEntityRecognition,
            enablePartOfSpeechTagging: enablePartOfSpeechTagging,
            enableTokenization: enableTokenization,
            enableTextClassification: enableTextClassification,
            enableTextEmbedding: enableTextEmbedding,
            maxConcurrentRequests: adjustedConcurrentRequests,
            requestTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            preferredLanguages: preferredLanguages,
            minimumConfidence: minimumConfidence
        )
    }
}

// MARK: - Natural Language Types

/// Natural language analysis request
public struct NaturalLanguageAnalysisRequest: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let requestTypes: Set<NLRequestType>
    public let options: NLOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public enum NLRequestType: String, Sendable, CaseIterable {
        case languageDetection = "language-detection"
        case sentimentAnalysis = "sentiment-analysis"
        case namedEntityRecognition = "named-entity-recognition"
        case partOfSpeechTagging = "part-of-speech-tagging"
        case tokenization = "tokenization"
        case textClassification = "text-classification"
        case textEmbedding = "text-embedding"
        case lemmatization = "lemmatization"
        case gazetteer = "gazetteer"
    }
    
    public struct NLOptions: Sendable {
        public let language: NLLanguage?
        public let minimumConfidence: Float
        public let maximumCandidates: Int
        public let tokenUnit: TokenUnit
        public let sentimentScale: SentimentScale
        public let entityTypes: Set<String>
        public let customModel: String?
        
        public enum TokenUnit: String, Sendable, CaseIterable {
            case word = "word"
            case sentence = "sentence"
            case paragraph = "paragraph"
            case document = "document"
        }
        
        public enum SentimentScale: String, Sendable, CaseIterable {
            case negative_positive = "negative-positive" // -1.0 to 1.0
            case zero_one = "zero-one" // 0.0 to 1.0
        }
        
        public init(
            language: NLLanguage? = nil,
            minimumConfidence: Float = 0.1,
            maximumCandidates: Int = 10,
            tokenUnit: TokenUnit = .word,
            sentimentScale: SentimentScale = .negative_positive,
            entityTypes: Set<String> = [],
            customModel: String? = nil
        ) {
            self.language = language
            self.minimumConfidence = minimumConfidence
            self.maximumCandidates = maximumCandidates
            self.tokenUnit = tokenUnit
            self.sentimentScale = sentimentScale
            self.entityTypes = entityTypes
            self.customModel = customModel
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
        requestTypes: Set<NLRequestType>,
        options: NLOptions = NLOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.text = text
        self.requestTypes = requestTypes
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Natural language analysis result
public struct NaturalLanguageAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let results: [NaturalLanguageAnalysisRequest.NLRequestType: NLRequestResult]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: NaturalLanguageError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public enum NLRequestResult: Sendable {
        case languageDetection([LanguageHypothesis])
        case sentimentAnalysis(SentimentAnalysis)
        case namedEntityRecognition([NamedEntity])
        case partOfSpeechTagging([POSTag])
        case tokenization([Token])
        case textClassification([Classification])
        case textEmbedding(TextEmbedding)
        case lemmatization([Lemma])
        case gazetteer([GazetteerEntity])
    }
    
    public struct LanguageHypothesis: Sendable {
        public let language: NLLanguage
        public let confidence: Double
        public let languageCode: String
        
        public init(language: NLLanguage, confidence: Double) {
            self.language = language
            self.confidence = confidence
            self.languageCode = language.rawValue
        }
    }
    
    public struct SentimentAnalysis: Sendable {
        public let sentiment: Sentiment
        public let score: Double
        public let confidence: Double
        public let label: String
        
        public enum Sentiment: String, Sendable, CaseIterable {
            case veryNegative = "very-negative"
            case negative = "negative"
            case neutral = "neutral"
            case positive = "positive"
            case veryPositive = "very-positive"
        }
        
        public init(sentiment: Sentiment, score: Double, confidence: Double) {
            self.sentiment = sentiment
            self.score = score
            self.confidence = confidence
            self.label = sentiment.rawValue
        }
    }
    
    public struct NamedEntity: Sendable {
        public let text: String
        public let range: NSRange
        public let entityType: EntityType
        public let confidence: Double
        
        public enum EntityType: String, Sendable, CaseIterable {
            case personalName = "personal-name"
            case placeName = "place-name"
            case organizationName = "organization-name"
            case unknown = "unknown"
        }
        
        public init(text: String, range: NSRange, entityType: EntityType, confidence: Double) {
            self.text = text
            self.range = range
            self.entityType = entityType
            self.confidence = confidence
        }
    }
    
    public struct POSTag: Sendable {
        public let text: String
        public let range: NSRange
        public let tag: PartOfSpeech
        public let confidence: Double
        
        public enum PartOfSpeech: String, Sendable, CaseIterable {
            case noun = "noun"
            case verb = "verb"
            case adjective = "adjective"
            case adverb = "adverb"
            case pronoun = "pronoun"
            case determiner = "determiner"
            case particle = "particle"
            case preposition = "preposition"
            case number = "number"
            case conjunction = "conjunction"
            case interjection = "interjection"
            case classifier = "classifier"
            case idiom = "idiom"
            case otherWord = "other-word"
            case sentenceTerminator = "sentence-terminator"
            case openQuote = "open-quote"
            case closeQuote = "close-quote"
            case openParenthesis = "open-parenthesis"
            case closeParenthesis = "close-parenthesis"
            case wordJoiner = "word-joiner"
            case dash = "dash"
            case otherPunctuation = "other-punctuation"
            case paragraphBreak = "paragraph-break"
            case other = "other"
        }
        
        public init(text: String, range: NSRange, tag: PartOfSpeech, confidence: Double) {
            self.text = text
            self.range = range
            self.tag = tag
            self.confidence = confidence
        }
    }
    
    public struct Token: Sendable {
        public let text: String
        public let range: NSRange
        public let tokenType: TokenType
        
        public enum TokenType: String, Sendable, CaseIterable {
            case word = "word"
            case punctuation = "punctuation"
            case whitespace = "whitespace"
            case sentence = "sentence"
            case paragraph = "paragraph"
        }
        
        public init(text: String, range: NSRange, tokenType: TokenType) {
            self.text = text
            self.range = range
            self.tokenType = tokenType
        }
    }
    
    public struct Classification: Sendable {
        public let category: String
        public let confidence: Double
        
        public init(category: String, confidence: Double) {
            self.category = category
            self.confidence = confidence
        }
    }
    
    public struct TextEmbedding: Sendable {
        public let vector: [Double]
        public let dimension: Int
        public let model: String?
        
        public init(vector: [Double], model: String? = nil) {
            self.vector = vector
            self.dimension = vector.count
            self.model = model
        }
    }
    
    public struct Lemma: Sendable {
        public let originalText: String
        public let lemma: String
        public let range: NSRange
        
        public init(originalText: String, lemma: String, range: NSRange) {
            self.originalText = originalText
            self.lemma = lemma
            self.range = range
        }
    }
    
    public struct GazetteerEntity: Sendable {
        public let text: String
        public let range: NSRange
        public let label: String
        
        public init(text: String, range: NSRange, label: String) {
            self.text = text
            self.range = range
            self.label = label
        }
    }
    
    public init(
        requestId: UUID,
        results: [NaturalLanguageAnalysisRequest.NLRequestType: NLRequestResult],
        processingTime: TimeInterval,
        success: Bool,
        error: NaturalLanguageError? = nil,
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

/// Natural language metrics
public struct NaturalLanguageMetrics: Sendable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageProcessingTime: TimeInterval
    public let requestsByType: [String: Int]
    public let languagesByDetection: [String: Int]
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
        languagesByDetection: [String: Int] = [:],
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
        self.languagesByDetection = languagesByDetection
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRequests) / averageProcessingTime : 0
    }
    
    public var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
    }
}

// MARK: - Natural Language Resource

/// Natural language resource management
@available(iOS 12.0, macOS 10.14, watchOS 5.0, tvOS 12.0, *)
public actor NaturalLanguageCapabilityResource: AxiomCapabilityResource {
    private let configuration: NaturalLanguageCapabilityConfiguration
    private var activeRequests: [UUID: NaturalLanguageAnalysisRequest] = [:]
    private var requestQueue: [NaturalLanguageAnalysisRequest] = []
    private var requestHistory: [NaturalLanguageAnalysisResult] = []
    private var resultCache: [String: NaturalLanguageAnalysisResult] = [:]
    private var metrics: NaturalLanguageMetrics = NaturalLanguageMetrics()
    private var resultStreamContinuation: AsyncStream<NaturalLanguageAnalysisResult>.Continuation?
    private var isProcessingQueue: Bool = false
    private var languageRecognizer: NLLanguageRecognizer?
    private var sentimentAnalyzer: NLModel?
    
    public init(configuration: NaturalLanguageCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 50_000_000, // 50MB for NL processing
            cpu: 2.0, // Moderate CPU usage for text processing
            bandwidth: 0,
            storage: 20_000_000 // 20MB for caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let requestMemory = activeRequests.count * 1_000_000 // ~1MB per active request
            let cacheMemory = resultCache.count * 50_000 // ~50KB per cached result
            let historyMemory = requestHistory.count * 5_000
            
            return ResourceUsage(
                memory: requestMemory + cacheMemory + historyMemory + 10_000_000,
                cpu: activeRequests.isEmpty ? 0.1 : 1.5,
                bandwidth: 0,
                storage: resultCache.count * 20_000 // ~20KB per cached result
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Natural Language is available on iOS 12+, macOS 10.14+
        if #available(iOS 12.0, macOS 10.14, watchOS 5.0, tvOS 12.0, *) {
            return configuration.enableNaturalLanguage
        }
        return false
    }
    
    public func release() async {
        activeRequests.removeAll()
        requestQueue.removeAll()
        requestHistory.removeAll()
        resultCache.removeAll()
        
        languageRecognizer = nil
        sentimentAnalyzer = nil
        
        resultStreamContinuation?.finish()
        
        metrics = NaturalLanguageMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Natural Language processing
        languageRecognizer = NLLanguageRecognizer()
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[NaturalLanguage] 🚀 Natural Language capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: NaturalLanguageCapabilityConfiguration) async throws {
        // Configuration updates for Natural Language
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<NaturalLanguageAnalysisResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Natural Language Analysis
    
    public func analyzeText(_ request: NaturalLanguageAnalysisRequest) async throws -> NaturalLanguageAnalysisResult {
        guard configuration.enableNaturalLanguage else {
            throw NaturalLanguageError.naturalLanguageDisabled
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
            throw NaturalLanguageError.requestQueued(request.id)
        }
        
        let startTime = Date()
        activeRequests[request.id] = request
        
        do {
            var results: [NaturalLanguageAnalysisRequest.NLRequestType: NaturalLanguageAnalysisResult.NLRequestResult] = [:]
            
            // Process each request type
            for requestType in request.requestTypes {
                let result = try await processNLRequest(type: requestType, text: request.text, options: request.options)
                results[requestType] = result
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let analysisResult = NaturalLanguageAnalysisResult(
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
            let analysisResult = NaturalLanguageAnalysisResult(
                requestId: request.id,
                results: [:],
                processingTime: processingTime,
                success: false,
                error: error as? NaturalLanguageError ?? NaturalLanguageError.analysisError(error.localizedDescription)
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
            print("[NaturalLanguage] 🚫 Cancelled request: \(requestId)")
        }
    }
    
    public func getActiveRequests() async -> [NaturalLanguageAnalysisRequest] {
        return Array(activeRequests.values)
    }
    
    public func getRequestHistory(since: Date? = nil) async -> [NaturalLanguageAnalysisResult] {
        if let since = since {
            return requestHistory.filter { $0.timestamp >= since }
        }
        return requestHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> NaturalLanguageMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = NaturalLanguageMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        // Performance optimization for Natural Language
        if configuration.enableLogging {
            print("[NaturalLanguage] ⚡ Performance optimization enabled")
        }
    }
    
    private func processNLRequest(type: NaturalLanguageAnalysisRequest.NLRequestType, text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        
        switch type {
        case .languageDetection:
            return try await performLanguageDetection(text: text, options: options)
        case .sentimentAnalysis:
            return try await performSentimentAnalysis(text: text, options: options)
        case .namedEntityRecognition:
            return try await performNamedEntityRecognition(text: text, options: options)
        case .partOfSpeechTagging:
            return try await performPartOfSpeechTagging(text: text, options: options)
        case .tokenization:
            return try await performTokenization(text: text, options: options)
        case .textClassification:
            return try await performTextClassification(text: text, options: options)
        case .textEmbedding:
            return try await performTextEmbedding(text: text, options: options)
        case .lemmatization:
            return try await performLemmatization(text: text, options: options)
        case .gazetteer:
            return try await performGazetteerAnalysis(text: text, options: options)
        }
    }
    
    private func performLanguageDetection(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let recognizer = languageRecognizer else {
                continuation.resume(throwing: NaturalLanguageError.recognizerNotAvailable)
                return
            }
            
            recognizer.reset()
            recognizer.processString(text)
            
            let hypotheses = recognizer.languageHypotheses(withMaximum: options.maximumCandidates)
            let languageHypotheses = hypotheses.compactMap { (language, confidence) -> NaturalLanguageAnalysisResult.LanguageHypothesis? in
                guard confidence >= Double(options.minimumConfidence) else { return nil }
                return NaturalLanguageAnalysisResult.LanguageHypothesis(language: language, confidence: confidence)
            }
            
            continuation.resume(returning: .languageDetection(languageHypotheses))
        }
    }
    
    private func performSentimentAnalysis(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = text
            
            let (sentiment, range) = tagger.tag(at: text.startIndex, unit: .document, scheme: .sentimentScore)
            
            if let sentimentScore = sentiment?.rawValue, let score = Double(sentimentScore) {
                let normalizedScore = options.sentimentScale == .zero_one ? (score + 1.0) / 2.0 : score
                
                let sentimentCategory: NaturalLanguageAnalysisResult.SentimentAnalysis.Sentiment
                switch score {
                case ..<(-0.5):
                    sentimentCategory = .veryNegative
                case ..<(-0.1):
                    sentimentCategory = .negative
                case -0.1...0.1:
                    sentimentCategory = .neutral
                case 0.1...0.5:
                    sentimentCategory = .positive
                default:
                    sentimentCategory = .veryPositive
                }
                
                let analysis = NaturalLanguageAnalysisResult.SentimentAnalysis(
                    sentiment: sentimentCategory,
                    score: normalizedScore,
                    confidence: abs(score) // Use absolute value as confidence
                )
                
                continuation.resume(returning: .sentimentAnalysis(analysis))
            } else {
                let neutralAnalysis = NaturalLanguageAnalysisResult.SentimentAnalysis(
                    sentiment: .neutral,
                    score: options.sentimentScale == .zero_one ? 0.5 : 0.0,
                    confidence: 0.0
                )
                continuation.resume(returning: .sentimentAnalysis(neutralAnalysis))
            }
        }
    }
    
    private func performNamedEntityRecognition(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = text
            
            if let language = options.language {
                tagger.setLanguage(language, range: NSRange(location: 0, length: text.utf16.count))
            }
            
            var entities: [NaturalLanguageAnalysisResult.NamedEntity] = []
            
            tagger.enumerateTags(in: NSRange(location: 0, length: text.utf16.count), unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
                if let tag = tag {
                    let entityText = (text as NSString).substring(with: range)
                    
                    let entityType: NaturalLanguageAnalysisResult.NamedEntity.EntityType
                    switch tag {
                    case .personalName:
                        entityType = .personalName
                    case .placeName:
                        entityType = .placeName
                    case .organizationName:
                        entityType = .organizationName
                    default:
                        entityType = .unknown
                    }
                    
                    let entity = NaturalLanguageAnalysisResult.NamedEntity(
                        text: entityText,
                        range: range,
                        entityType: entityType,
                        confidence: 0.8 // NL framework doesn't provide confidence, use default
                    )
                    
                    entities.append(entity)
                }
                return true
            }
            
            continuation.resume(returning: .namedEntityRecognition(entities))
        }
    }
    
    private func performPartOfSpeechTagging(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = text
            
            if let language = options.language {
                tagger.setLanguage(language, range: NSRange(location: 0, length: text.utf16.count))
            }
            
            var tags: [NaturalLanguageAnalysisResult.POSTag] = []
            
            tagger.enumerateTags(in: NSRange(location: 0, length: text.utf16.count), unit: .word, scheme: .lexicalClass, options: [.omitWhitespace]) { tag, range in
                if let tag = tag {
                    let tagText = (text as NSString).substring(with: range)
                    
                    let posTag = convertNLTagToPOSTag(tag)
                    
                    let posTagResult = NaturalLanguageAnalysisResult.POSTag(
                        text: tagText,
                        range: range,
                        tag: posTag,
                        confidence: 0.9 // NL framework doesn't provide confidence, use default
                    )
                    
                    tags.append(posTagResult)
                }
                return true
            }
            
            continuation.resume(returning: .partOfSpeechTagging(tags))
        }
    }
    
    private func performTokenization(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let tokenizer = NLTokenizer(unit: convertTokenUnit(options.tokenUnit))
            tokenizer.string = text
            
            if let language = options.language {
                tokenizer.setLanguage(language)
            }
            
            var tokens: [NaturalLanguageAnalysisResult.Token] = []
            
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let tokenText = String(text[range])
                let nsRange = NSRange(range, in: text)
                
                let tokenType = determineTokenType(tokenText)
                
                let token = NaturalLanguageAnalysisResult.Token(
                    text: tokenText,
                    range: nsRange,
                    tokenType: tokenType
                )
                
                tokens.append(token)
                return true
            }
            
            continuation.resume(returning: .tokenization(tokens))
        }
    }
    
    private func performTextClassification(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            // This would typically use a custom trained model
            // For demonstration, we'll provide a simple classification
            
            let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
            let sentenceCount = text.components(separatedBy: .punctuationCharacters).count
            
            var classifications: [NaturalLanguageAnalysisResult.Classification] = []
            
            // Length-based classification
            if wordCount < 10 {
                classifications.append(NaturalLanguageAnalysisResult.Classification(category: "short", confidence: 0.8))
            } else if wordCount < 50 {
                classifications.append(NaturalLanguageAnalysisResult.Classification(category: "medium", confidence: 0.7))
            } else {
                classifications.append(NaturalLanguageAnalysisResult.Classification(category: "long", confidence: 0.9))
            }
            
            // Content-based classification (simple keyword detection)
            let lowercaseText = text.lowercased()
            if lowercaseText.contains("question") || lowercaseText.contains("?") {
                classifications.append(NaturalLanguageAnalysisResult.Classification(category: "question", confidence: 0.6))
            }
            
            if lowercaseText.contains("thank") || lowercaseText.contains("please") {
                classifications.append(NaturalLanguageAnalysisResult.Classification(category: "polite", confidence: 0.5))
            }
            
            continuation.resume(returning: .textClassification(classifications))
        }
    }
    
    private func performTextEmbedding(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
                do {
                    let embedding = try NLEmbedding.wordEmbedding(for: options.language ?? .english)
                    
                    // Get embeddings for words and average them
                    let tokenizer = NLTokenizer(unit: .word)
                    tokenizer.string = text
                    
                    var vectors: [[Double]] = []
                    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                        let word = String(text[range])
                        if let vector = embedding?.vector(for: word) {
                            vectors.append(vector)
                        }
                        return true
                    }
                    
                    // Average the vectors
                    let avgVector: [Double]
                    if !vectors.isEmpty {
                        let dimension = vectors.first?.count ?? 0
                        avgVector = (0..<dimension).map { i in
                            vectors.map { $0.count > i ? $0[i] : 0.0 }.reduce(0, +) / Double(vectors.count)
                        }
                    } else {
                        // Return zero vector if no embeddings found
                        avgVector = Array(repeating: 0.0, count: 300) // Common embedding dimension
                    }
                    
                    let textEmbedding = NaturalLanguageAnalysisResult.TextEmbedding(
                        vector: avgVector,
                        model: "NLEmbedding"
                    )
                    
                    continuation.resume(returning: .textEmbedding(textEmbedding))
                } catch {
                    continuation.resume(throwing: error)
                }
            } else {
                // Fallback for older versions - create simple hash-based embedding
                let simpleVector = createSimpleEmbedding(text: text)
                let textEmbedding = NaturalLanguageAnalysisResult.TextEmbedding(
                    vector: simpleVector,
                    model: "SimpleHash"
                )
                continuation.resume(returning: .textEmbedding(textEmbedding))
            }
        }
    }
    
    private func performLemmatization(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let tagger = NLTagger(tagSchemes: [.lemma])
            tagger.string = text
            
            if let language = options.language {
                tagger.setLanguage(language, range: NSRange(location: 0, length: text.utf16.count))
            }
            
            var lemmas: [NaturalLanguageAnalysisResult.Lemma] = []
            
            tagger.enumerateTags(in: NSRange(location: 0, length: text.utf16.count), unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
                let originalText = (text as NSString).substring(with: range)
                let lemmaText = tag?.rawValue ?? originalText
                
                let lemma = NaturalLanguageAnalysisResult.Lemma(
                    originalText: originalText,
                    lemma: lemmaText,
                    range: range
                )
                
                lemmas.append(lemma)
                return true
            }
            
            continuation.resume(returning: .lemmatization(lemmas))
        }
    }
    
    private func performGazetteerAnalysis(text: String, options: NaturalLanguageAnalysisRequest.NLOptions) async throws -> NaturalLanguageAnalysisResult.NLRequestResult {
        return try await withCheckedThrowingContinuation { continuation in
            // This would typically use a custom gazetteer/dictionary
            // For demonstration, we'll provide a simple implementation
            
            var entities: [NaturalLanguageAnalysisResult.GazetteerEntity] = []
            
            // Simple pattern matching for common entities
            let patterns = [
                ("\\b\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}\\b", "date"),
                ("\\b\\d{1,2}:\\d{2}(?::\\d{2})?(?:\\s?[AaPp][Mm])?\\b", "time"),
                ("\\b\\d{3}-\\d{3}-\\d{4}\\b", "phone"),
                ("\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", "email"),
                ("\\bhttps?://[^\\s]+\\b", "url")
            ]
            
            for (pattern, label) in patterns {
                do {
                    let regex = try NSRegularExpression(pattern: pattern, options: [])
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                    
                    for match in matches {
                        let matchText = (text as NSString).substring(with: match.range)
                        let entity = NaturalLanguageAnalysisResult.GazetteerEntity(
                            text: matchText,
                            range: match.range,
                            label: label
                        )
                        entities.append(entity)
                    }
                } catch {
                    // Skip invalid regex patterns
                    continue
                }
            }
            
            continuation.resume(returning: .gazetteer(entities))
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
                _ = try await analyzeText(request)
            } catch {
                if configuration.enableLogging {
                    print("[NaturalLanguage] ⚠️ Queued request failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: NaturalLanguageAnalysisRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: NaturalLanguageAnalysisRequest) -> String {
        let textHash = request.text.hashValue
        let requestTypes = request.requestTypes.sorted { $0.rawValue < $1.rawValue }.map { $0.rawValue }.joined(separator: ",")
        let language = request.options.language?.rawValue ?? "auto"
        return "\(textHash)_\(requestTypes)_\(language)_\(request.options.minimumConfidence)"
    }
    
    private func convertNLTagToPOSTag(_ tag: NLTag) -> NaturalLanguageAnalysisResult.POSTag.PartOfSpeech {
        switch tag {
        case .noun: return .noun
        case .verb: return .verb
        case .adjective: return .adjective
        case .adverb: return .adverb
        case .pronoun: return .pronoun
        case .determiner: return .determiner
        case .particle: return .particle
        case .preposition: return .preposition
        case .number: return .number
        case .conjunction: return .conjunction
        case .interjection: return .interjection
        case .classifier: return .classifier
        case .idiom: return .idiom
        case .otherWord: return .otherWord
        case .sentenceTerminator: return .sentenceTerminator
        case .openQuote: return .openQuote
        case .closeQuote: return .closeQuote
        case .openParenthesis: return .openParenthesis
        case .closeParenthesis: return .closeParenthesis
        case .wordJoiner: return .wordJoiner
        case .dash: return .dash
        case .otherPunctuation: return .otherPunctuation
        case .paragraphBreak: return .paragraphBreak
        default: return .other
        }
    }
    
    private func convertTokenUnit(_ unit: NaturalLanguageAnalysisRequest.NLOptions.TokenUnit) -> NLTokenUnit {
        switch unit {
        case .word: return .word
        case .sentence: return .sentence
        case .paragraph: return .paragraph
        case .document: return .document
        }
    }
    
    private func determineTokenType(_ text: String) -> NaturalLanguageAnalysisResult.Token.TokenType {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .whitespace
        } else if text.rangeOfCharacter(from: .punctuationCharacters) != nil {
            return .punctuation
        } else {
            return .word
        }
    }
    
    private func createSimpleEmbedding(text: String) -> [Double] {
        // Create a simple hash-based embedding for fallback
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let dimension = 100
        var vector = Array(repeating: 0.0, count: dimension)
        
        for word in words {
            let hash = abs(word.hashValue)
            for i in 0..<dimension {
                vector[i] += sin(Double(hash + i)) * 0.1
            }
        }
        
        // Normalize
        let magnitude = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            for i in 0..<dimension {
                vector[i] /= magnitude
            }
        }
        
        return vector
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRequests)) + 1
        let totalRequests = metrics.totalRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = NaturalLanguageMetrics(
            totalRequests: totalRequests,
            successfulRequests: metrics.successfulRequests + 1,
            failedRequests: metrics.failedRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            requestsByType: metrics.requestsByType,
            languagesByDetection: metrics.languagesByDetection,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateSuccessMetrics(_ result: NaturalLanguageAnalysisResult) async {
        let totalRequests = metrics.totalRequests + 1
        let successfulRequests = metrics.successfulRequests + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRequests)) + result.processingTime) / Double(totalRequests)
        
        var requestsByType = metrics.requestsByType
        for requestType in result.results.keys {
            requestsByType[requestType.rawValue, default: 0] += 1
        }
        
        var languagesByDetection = metrics.languagesByDetection
        if case .languageDetection(let hypotheses) = result.results[.languageDetection] {
            for hypothesis in hypotheses {
                languagesByDetection[hypothesis.languageCode, default: 0] += 1
            }
        }
        
        metrics = NaturalLanguageMetrics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: metrics.failedRequests,
            averageProcessingTime: newAverageProcessingTime,
            requestsByType: requestsByType,
            languagesByDetection: languagesByDetection,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateFailureMetrics(_ result: NaturalLanguageAnalysisResult) async {
        let totalRequests = metrics.totalRequests + 1
        let failedRequests = metrics.failedRequests + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = NaturalLanguageMetrics(
            totalRequests: totalRequests,
            successfulRequests: metrics.successfulRequests,
            failedRequests: failedRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            requestsByType: metrics.requestsByType,
            languagesByDetection: metrics.languagesByDetection,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func logAnalysis(_ result: NaturalLanguageAnalysisResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let resultCount = result.results.count
        
        print("[NaturalLanguage] \(statusIcon) Analysis: \(resultCount) types (\(timeStr)s)")
        
        if let error = result.error {
            print("[NaturalLanguage] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Natural Language Capability Implementation

/// Natural Language capability providing comprehensive text analysis
@available(iOS 12.0, macOS 10.14, watchOS 5.0, tvOS 12.0, *)
public actor NaturalLanguageCapability: DomainCapability {
    public typealias ConfigurationType = NaturalLanguageCapabilityConfiguration
    public typealias ResourceType = NaturalLanguageCapabilityResource
    
    private var _configuration: NaturalLanguageCapabilityConfiguration
    private var _resources: NaturalLanguageCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "natural-language-capability" }
    
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
    
    public var configuration: NaturalLanguageCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: NaturalLanguageCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: NaturalLanguageCapabilityConfiguration = NaturalLanguageCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = NaturalLanguageCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: NaturalLanguageCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Natural Language configuration")
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
        // Natural Language is supported on iOS 12+, macOS 10.14+
        if #available(iOS 12.0, macOS 10.14, watchOS 5.0, tvOS 12.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Natural Language doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Natural Language Operations
    
    /// Analyze text with Natural Language
    public func analyzeText(_ request: NaturalLanguageAnalysisRequest) async throws -> NaturalLanguageAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        return try await _resources.analyzeText(request)
    }
    
    /// Cancel text analysis request
    public func cancelRequest(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        await _resources.cancelRequest(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<NaturalLanguageAnalysisResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active requests
    public func getActiveRequests() async throws -> [NaturalLanguageAnalysisRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        return await _resources.getActiveRequests()
    }
    
    /// Get request history
    public func getRequestHistory(since: Date? = nil) async throws -> [NaturalLanguageAnalysisResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        return await _resources.getRequestHistory(since: since)
    }
    
    /// Get Natural Language metrics
    public func getMetrics() async throws -> NaturalLanguageMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Natural Language capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Detect language in text
    public func detectLanguage(in text: String, options: NaturalLanguageAnalysisRequest.NLOptions = NaturalLanguageAnalysisRequest.NLOptions()) async throws -> [NaturalLanguageAnalysisResult.LanguageHypothesis] {
        let request = NaturalLanguageAnalysisRequest(
            text: text,
            requestTypes: [.languageDetection],
            options: options
        )
        
        let result = try await analyzeText(request)
        
        if case .languageDetection(let hypotheses) = result.results[.languageDetection] {
            return hypotheses
        }
        
        return []
    }
    
    /// Analyze sentiment in text
    public func analyzeSentiment(in text: String, options: NaturalLanguageAnalysisRequest.NLOptions = NaturalLanguageAnalysisRequest.NLOptions()) async throws -> NaturalLanguageAnalysisResult.SentimentAnalysis? {
        let request = NaturalLanguageAnalysisRequest(
            text: text,
            requestTypes: [.sentimentAnalysis],
            options: options
        )
        
        let result = try await analyzeText(request)
        
        if case .sentimentAnalysis(let analysis) = result.results[.sentimentAnalysis] {
            return analysis
        }
        
        return nil
    }
    
    /// Extract named entities from text
    public func extractNamedEntities(from text: String, options: NaturalLanguageAnalysisRequest.NLOptions = NaturalLanguageAnalysisRequest.NLOptions()) async throws -> [NaturalLanguageAnalysisResult.NamedEntity] {
        let request = NaturalLanguageAnalysisRequest(
            text: text,
            requestTypes: [.namedEntityRecognition],
            options: options
        )
        
        let result = try await analyzeText(request)
        
        if case .namedEntityRecognition(let entities) = result.results[.namedEntityRecognition] {
            return entities
        }
        
        return []
    }
    
    /// Tokenize text
    public func tokenize(_ text: String, options: NaturalLanguageAnalysisRequest.NLOptions = NaturalLanguageAnalysisRequest.NLOptions()) async throws -> [NaturalLanguageAnalysisResult.Token] {
        let request = NaturalLanguageAnalysisRequest(
            text: text,
            requestTypes: [.tokenization],
            options: options
        )
        
        let result = try await analyzeText(request)
        
        if case .tokenization(let tokens) = result.results[.tokenization] {
            return tokens
        }
        
        return []
    }
    
    /// Check if natural language processing is active
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

/// Natural Language specific errors
public enum NaturalLanguageError: Error, LocalizedError {
    case naturalLanguageDisabled
    case analysisError(String)
    case invalidText
    case noResults
    case requestQueued(UUID)
    case requestTimeout(UUID)
    case recognizerNotAvailable
    case unsupportedLanguage(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .naturalLanguageDisabled:
            return "Natural Language is disabled"
        case .analysisError(let reason):
            return "Natural Language analysis failed: \(reason)"
        case .invalidText:
            return "Invalid text provided"
        case .noResults:
            return "No results found in natural language analysis"
        case .requestQueued(let id):
            return "Natural Language request queued: \(id)"
        case .requestTimeout(let id):
            return "Natural Language request timeout: \(id)"
        case .recognizerNotAvailable:
            return "Language recognizer not available"
        case .unsupportedLanguage(let language):
            return "Unsupported language: \(language)"
        case .configurationError(let reason):
            return "Natural Language configuration error: \(reason)"
        }
    }
}