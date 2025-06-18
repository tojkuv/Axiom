import Foundation
import Vision
import CoreImage
import CoreML
import NaturalLanguage
import AxiomCore
import AxiomCapabilities

// MARK: - Text Recognition Capability Configuration

/// Configuration for Text Recognition capability
public struct TextRecognitionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableTextRecognition: Bool
    public let enableLanguageDetection: Bool
    public let enableConfidenceFiltering: Bool
    public let enableTextCorrection: Bool
    public let enableRealTimeRecognition: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentRecognitions: Int
    public let recognitionTimeout: TimeInterval
    public let minimumTextHeight: Float
    public let minimumConfidence: Float
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let recognitionLevel: RecognitionLevel
    public let preferredLanguages: [String]
    public let customWords: [String]
    
    public enum RecognitionLevel: String, Codable, CaseIterable {
        case fast = "fast"
        case accurate = "accurate"
    }
    
    public init(
        enableTextRecognition: Bool = true,
        enableLanguageDetection: Bool = true,
        enableConfidenceFiltering: Bool = true,
        enableTextCorrection: Bool = true,
        enableRealTimeRecognition: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentRecognitions: Int = 8,
        recognitionTimeout: TimeInterval = 30.0,
        minimumTextHeight: Float = 0.02,
        minimumConfidence: Float = 0.5,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 150,
        enablePerformanceOptimization: Bool = true,
        recognitionLevel: RecognitionLevel = .accurate,
        preferredLanguages: [String] = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh"],
        customWords: [String] = []
    ) {
        self.enableTextRecognition = enableTextRecognition
        self.enableLanguageDetection = enableLanguageDetection
        self.enableConfidenceFiltering = enableConfidenceFiltering
        self.enableTextCorrection = enableTextCorrection
        self.enableRealTimeRecognition = enableRealTimeRecognition
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentRecognitions = maxConcurrentRecognitions
        self.recognitionTimeout = recognitionTimeout
        self.minimumTextHeight = minimumTextHeight
        self.minimumConfidence = minimumConfidence
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.recognitionLevel = recognitionLevel
        self.preferredLanguages = preferredLanguages
        self.customWords = customWords
    }
    
    public var isValid: Bool {
        maxConcurrentRecognitions > 0 &&
        recognitionTimeout > 0 &&
        minimumTextHeight > 0.0 && minimumTextHeight <= 1.0 &&
        minimumConfidence >= 0.0 && minimumConfidence <= 1.0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: TextRecognitionCapabilityConfiguration) -> TextRecognitionCapabilityConfiguration {
        TextRecognitionCapabilityConfiguration(
            enableTextRecognition: other.enableTextRecognition,
            enableLanguageDetection: other.enableLanguageDetection,
            enableConfidenceFiltering: other.enableConfidenceFiltering,
            enableTextCorrection: other.enableTextCorrection,
            enableRealTimeRecognition: other.enableRealTimeRecognition,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentRecognitions: other.maxConcurrentRecognitions,
            recognitionTimeout: other.recognitionTimeout,
            minimumTextHeight: other.minimumTextHeight,
            minimumConfidence: other.minimumConfidence,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            recognitionLevel: other.recognitionLevel,
            preferredLanguages: other.preferredLanguages,
            customWords: other.customWords
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> TextRecognitionCapabilityConfiguration {
        var adjustedTimeout = recognitionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRecognitions = maxConcurrentRecognitions
        var adjustedCacheSize = cacheSize
        var adjustedRecognitionLevel = recognitionLevel
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(recognitionTimeout, 15.0)
            adjustedConcurrentRecognitions = min(maxConcurrentRecognitions, 3)
            adjustedCacheSize = min(cacheSize, 30)
            adjustedRecognitionLevel = .fast
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return TextRecognitionCapabilityConfiguration(
            enableTextRecognition: enableTextRecognition,
            enableLanguageDetection: enableLanguageDetection,
            enableConfidenceFiltering: enableConfidenceFiltering,
            enableTextCorrection: enableTextCorrection,
            enableRealTimeRecognition: enableRealTimeRecognition,
            enableCustomModels: enableCustomModels,
            maxConcurrentRecognitions: adjustedConcurrentRecognitions,
            recognitionTimeout: adjustedTimeout,
            minimumTextHeight: minimumTextHeight,
            minimumConfidence: minimumConfidence,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            recognitionLevel: adjustedRecognitionLevel,
            preferredLanguages: preferredLanguages,
            customWords: customWords
        )
    }
}

// MARK: - Text Recognition Types

/// Text recognition request
public struct TextRecognitionRequest: Sendable, Identifiable {
    public let id: UUID
    public let image: CIImage
    public let options: RecognitionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct RecognitionOptions: Sendable {
        public let recognitionLevel: TextRecognitionCapabilityConfiguration.RecognitionLevel
        public let minimumTextHeight: Float
        public let minimumConfidence: Float
        public let enableLanguageCorrection: Bool
        public let enableAutoLanguageDetection: Bool
        public let preferredLanguages: [String]
        public let customWords: [String]
        public let regionOfInterest: CGRect?
        public let customModelId: String?
        public let usesLanguageCorrection: Bool
        public let revision: Int?
        
        public init(
            recognitionLevel: TextRecognitionCapabilityConfiguration.RecognitionLevel = .accurate,
            minimumTextHeight: Float = 0.02,
            minimumConfidence: Float = 0.5,
            enableLanguageCorrection: Bool = true,
            enableAutoLanguageDetection: Bool = true,
            preferredLanguages: [String] = ["en"],
            customWords: [String] = [],
            regionOfInterest: CGRect? = nil,
            customModelId: String? = nil,
            usesLanguageCorrection: Bool = true,
            revision: Int? = nil
        ) {
            self.recognitionLevel = recognitionLevel
            self.minimumTextHeight = minimumTextHeight
            self.minimumConfidence = minimumConfidence
            self.enableLanguageCorrection = enableLanguageCorrection
            self.enableAutoLanguageDetection = enableAutoLanguageDetection
            self.preferredLanguages = preferredLanguages
            self.customWords = customWords
            self.regionOfInterest = regionOfInterest
            self.customModelId = customModelId
            self.usesLanguageCorrection = usesLanguageCorrection
            self.revision = revision
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

/// Text recognition result
public struct TextRecognitionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let textObservations: [TextObservation]
    public let fullText: String
    public let detectedLanguages: [LanguageDetection]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: TextRecognitionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct TextObservation: Sendable, Identifiable {
        public let id: UUID
        public let text: String
        public let confidence: Float
        public let boundingBox: CGRect
        public let characterBoxes: [CharacterBox]
        public let recognizedLanguage: String?
        public let correctedText: String?
        public let textType: TextType
        public let readingOrder: Int
        public let topCandidates: [TextCandidate]
        
        public struct CharacterBox: Sendable {
            public let character: String
            public let boundingBox: CGRect
            public let confidence: Float
            
            public init(character: String, boundingBox: CGRect, confidence: Float) {
                self.character = character
                self.boundingBox = boundingBox
                self.confidence = confidence
            }
        }
        
        public struct TextCandidate: Sendable {
            public let text: String
            public let confidence: Float
            
            public init(text: String, confidence: Float) {
                self.text = text
                self.confidence = confidence
            }
        }
        
        public enum TextType: String, Sendable, CaseIterable {
            case printed = "printed"
            case handwritten = "handwritten"
            case mixed = "mixed"
            case unknown = "unknown"
        }
        
        public init(
            text: String,
            confidence: Float,
            boundingBox: CGRect,
            characterBoxes: [CharacterBox] = [],
            recognizedLanguage: String? = nil,
            correctedText: String? = nil,
            textType: TextType = .unknown,
            readingOrder: Int = 0,
            topCandidates: [TextCandidate] = []
        ) {
            self.id = UUID()
            self.text = text
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.characterBoxes = characterBoxes
            self.recognizedLanguage = recognizedLanguage
            self.correctedText = correctedText
            self.textType = textType
            self.readingOrder = readingOrder
            self.topCandidates = topCandidates
        }
    }
    
    public struct LanguageDetection: Sendable {
        public let languageCode: String
        public let confidence: Double
        public let textRange: Range<String.Index>?
        
        public init(languageCode: String, confidence: Double, textRange: Range<String.Index>? = nil) {
            self.languageCode = languageCode
            self.confidence = confidence
            self.textRange = textRange
        }
    }
    
    public init(
        requestId: UUID,
        textObservations: [TextObservation],
        detectedLanguages: [LanguageDetection] = [],
        processingTime: TimeInterval,
        success: Bool,
        error: TextRecognitionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.textObservations = textObservations
        self.fullText = textObservations.map { $0.text }.joined(separator: " ")
        self.detectedLanguages = detectedLanguages
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var wordCount: Int {
        fullText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    public var averageConfidence: Float {
        guard !textObservations.isEmpty else { return 0.0 }
        return textObservations.reduce(0) { $0 + $1.confidence } / Float(textObservations.count)
    }
    
    public var highestConfidenceObservation: TextObservation? {
        textObservations.max(by: { $0.confidence < $1.confidence })
    }
    
    public func observations(withMinimumConfidence confidence: Float) -> [TextObservation] {
        textObservations.filter { $0.confidence >= confidence }
    }
    
    public func observations(containing searchText: String) -> [TextObservation] {
        textObservations.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
}

/// Text recognition metrics
public struct TextRecognitionMetrics: Sendable {
    public let totalRecognitions: Int
    public let successfulRecognitions: Int
    public let failedRecognitions: Int
    public let averageProcessingTime: TimeInterval
    public let recognitionsByLanguage: [String: Int]
    public let recognitionsByLevel: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let averageWordsPerImage: Double
    public let throughputPerSecond: Double
    public let languageDetectionAccuracy: Double
    
    public init(
        totalRecognitions: Int = 0,
        successfulRecognitions: Int = 0,
        failedRecognitions: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        recognitionsByLanguage: [String: Int] = [:],
        recognitionsByLevel: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        averageWordsPerImage: Double = 0,
        throughputPerSecond: Double = 0,
        languageDetectionAccuracy: Double = 0
    ) {
        self.totalRecognitions = totalRecognitions
        self.successfulRecognitions = successfulRecognitions
        self.failedRecognitions = failedRecognitions
        self.averageProcessingTime = averageProcessingTime
        self.recognitionsByLanguage = recognitionsByLanguage
        self.recognitionsByLevel = recognitionsByLevel
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.averageWordsPerImage = averageWordsPerImage
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRecognitions) / averageProcessingTime : 0
        self.languageDetectionAccuracy = languageDetectionAccuracy
    }
    
    public var successRate: Double {
        totalRecognitions > 0 ? Double(successfulRecognitions) / Double(totalRecognitions) : 0
    }
}

// MARK: - Text Recognition Resource

/// Text recognition resource management
@available(iOS 13.0, macOS 10.15, *)
public actor TextRecognitionCapabilityResource: AxiomCapabilityResource {
    private let configuration: TextRecognitionCapabilityConfiguration
    private var activeRecognitions: [UUID: TextRecognitionRequest] = [:]
    private var recognitionQueue: [TextRecognitionRequest] = [:]
    private var recognitionHistory: [TextRecognitionResult] = [:]
    private var resultCache: [String: TextRecognitionResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var languageRecognizer: NLLanguageRecognizer?
    private var metrics: TextRecognitionMetrics = TextRecognitionMetrics()
    private var resultStreamContinuation: AsyncStream<TextRecognitionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: TextRecognitionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 200_000_000, // 200MB for text recognition
            cpu: 3.5, // Moderate-high CPU usage for text processing
            bandwidth: 0,
            storage: 80_000_000 // 80MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let recognitionMemory = activeRecognitions.count * 25_000_000 // ~25MB per active recognition
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let modelMemory = customModels.count * 60_000_000 // ~60MB per loaded model
            let historyMemory = recognitionHistory.count * 15_000
            
            return ResourceUsage(
                memory: recognitionMemory + cacheMemory + modelMemory + historyMemory + 20_000_000,
                cpu: activeRecognitions.isEmpty ? 0.2 : 3.0,
                bandwidth: 0,
                storage: resultCache.count * 50_000 + customModels.count * 120_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Text recognition is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableTextRecognition
        }
        return false
    }
    
    public func release() async {
        activeRecognitions.removeAll()
        recognitionQueue.removeAll()
        recognitionHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        languageRecognizer = nil
        
        resultStreamContinuation?.finish()
        
        metrics = TextRecognitionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize language recognizer for language detection
        if configuration.enableLanguageDetection {
            languageRecognizer = NLLanguageRecognizer()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[TextRecognition] 🚀 Text Recognition capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: TextRecognitionCapabilityConfiguration) async throws {
        // Configuration updates for text recognition
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<TextRecognitionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw TextRecognitionError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[TextRecognition] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw TextRecognitionError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[TextRecognition] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Text Recognition
    
    public func recognizeText(_ request: TextRecognitionRequest) async throws -> TextRecognitionResult {
        guard configuration.enableTextRecognition else {
            throw TextRecognitionError.textRecognitionDisabled
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
            throw TextRecognitionError.recognitionQueued(request.id)
        }
        
        let startTime = Date()
        activeRecognitions[request.id] = request
        
        do {
            // Perform text recognition
            let textObservations = try await performTextRecognition(image: request.image, options: request.options)
            
            // Detect languages if enabled
            var detectedLanguages: [TextRecognitionResult.LanguageDetection] = []
            if configuration.enableLanguageDetection {
                detectedLanguages = await detectLanguages(in: textObservations)
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = TextRecognitionResult(
                requestId: request.id,
                textObservations: textObservations,
                detectedLanguages: detectedLanguages,
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
            let result = TextRecognitionResult(
                requestId: request.id,
                textObservations: [],
                processingTime: processingTime,
                success: false,
                error: error as? TextRecognitionError ?? TextRecognitionError.recognitionError(error.localizedDescription)
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
            print("[TextRecognition] 🚫 Cancelled recognition: \(requestId)")
        }
    }
    
    public func getActiveRecognitions() async -> [TextRecognitionRequest] {
        return Array(activeRecognitions.values)
    }
    
    public func getRecognitionHistory(since: Date? = nil) async -> [TextRecognitionResult] {
        if let since = since {
            return recognitionHistory.filter { $0.timestamp >= since }
        }
        return recognitionHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> TextRecognitionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = TextRecognitionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[TextRecognition] ⚡ Performance optimization enabled")
        }
    }
    
    private func performTextRecognition(image: CIImage, options: TextRecognitionRequest.RecognitionOptions) async throws -> [TextRecognitionResult.TextObservation] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                    return
                }
                
                let textObservations = observations.enumerated().compactMap { index, observation -> TextRecognitionResult.TextObservation? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    guard topCandidate.confidence >= options.minimumConfidence else { return nil }
                    
                    // Get all candidates
                    let allCandidates = observation.topCandidates(5)
                    let topCandidates = allCandidates.map { candidate in
                        TextRecognitionResult.TextObservation.TextCandidate(
                            text: candidate.string,
                            confidence: candidate.confidence
                        )
                    }
                    
                    // Extract character boxes if available
                    var characterBoxes: [TextRecognitionResult.TextObservation.CharacterBox] = []
                    do {
                        let characterRange = topCandidate.string.startIndex..<topCandidate.string.endIndex
                        if let characterObservations = try topCandidate.boundingBox(for: characterRange) {
                            for (index, char) in topCandidate.string.enumerated() {
                                if index < characterObservations.count {
                                    let charBox = TextRecognitionResult.TextObservation.CharacterBox(
                                        character: String(char),
                                        boundingBox: characterObservations[index].boundingBox,
                                        confidence: topCandidate.confidence
                                    )
                                    characterBoxes.append(charBox)
                                }
                            }
                        }
                    } catch {
                        // Continue without character boxes if extraction fails
                    }
                    
                    // Determine text type (simplified)
                    let textType: TextRecognitionResult.TextObservation.TextType = self.determineTextType(topCandidate.string)
                    
                    // Apply text correction if enabled
                    var correctedText: String? = nil
                    if options.enableLanguageCorrection {
                        correctedText = self.correctText(topCandidate.string, preferredLanguages: options.preferredLanguages)
                    }
                    
                    return TextRecognitionResult.TextObservation(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox,
                        characterBoxes: characterBoxes,
                        correctedText: correctedText,
                        textType: textType,
                        readingOrder: index,
                        topCandidates: topCandidates
                    )
                }
                
                continuation.resume(returning: textObservations)
            }
            
            // Configure the request
            request.recognitionLevel = options.recognitionLevel == .fast ? .fast : .accurate
            request.usesLanguageCorrection = options.usesLanguageCorrection
            request.minimumTextHeight = options.minimumTextHeight
            
            if !options.customWords.isEmpty {
                request.customWords = options.customWords
            }
            
            if !options.preferredLanguages.isEmpty {
                request.recognitionLanguages = options.preferredLanguages
            }
            
            if let revision = options.revision {
                request.revision = revision
            }
            
            // Apply region of interest if specified
            var requestOptions: [VNImageOption: Any] = [:]
            if let roi = options.regionOfInterest {
                // Create a cropped image for the region of interest
                let croppedImage = image.cropped(to: roi)
                let requestHandler = VNImageRequestHandler(ciImage: croppedImage, options: requestOptions)
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            } else {
                let requestHandler = VNImageRequestHandler(ciImage: image, options: requestOptions)
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func detectLanguages(in observations: [TextRecognitionResult.TextObservation]) async -> [TextRecognitionResult.LanguageDetection] {
        guard let recognizer = languageRecognizer else { return [] }
        
        let fullText = observations.map { $0.text }.joined(separator: " ")
        guard !fullText.isEmpty else { return [] }
        
        recognizer.reset()
        recognizer.processString(fullText)
        
        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        return hypotheses.map { language, confidence in
            TextRecognitionResult.LanguageDetection(
                languageCode: language.rawValue,
                confidence: confidence
            )
        }
    }
    
    private func determineTextType(_ text: String) -> TextRecognitionResult.TextObservation.TextType {
        // Simple heuristic to determine if text is printed or handwritten
        // In a real implementation, this would use ML models
        
        let hasConsistentSpacing = text.range(of: "\\s{2,}", options: .regularExpression) == nil
        let hasConsistentCasing = text.range(of: "[a-z][A-Z]", options: .regularExpression) == nil
        
        if hasConsistentSpacing && hasConsistentCasing {
            return .printed
        } else {
            return .mixed
        }
    }
    
    private func correctText(_ text: String, preferredLanguages: [String]) -> String? {
        // Simple text correction using NLLanguage
        // In a real implementation, this would use more sophisticated correction
        
        guard !text.isEmpty else { return nil }
        
        // Basic spell checking and correction
        let checker = NSSpellChecker.shared
        let range = NSRange(location: 0, length: text.utf16.count)
        
        for language in preferredLanguages {
            checker.setLanguage(language)
            let misspelledRange = checker.rangeOfMisspelledWord(in: text, range: range, startingAt: 0, wrap: false, language: language)
            
            if misspelledRange.location != NSNotFound {
                let guesses = checker.guesses(forWordRange: misspelledRange, in: text, language: language, inSpellDocumentWithTag: 0)
                if let correction = guesses?.first {
                    let correctedText = (text as NSString).replacingCharacters(in: misspelledRange, with: correction)
                    return correctedText
                }
            }
        }
        
        return nil
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
                _ = try await recognizeText(request)
            } catch {
                if configuration.enableLogging {
                    print("[TextRecognition] ⚠️ Queued recognition failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: TextRecognitionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: TextRecognitionRequest) -> String {
        // Generate a cache key based on image hash and request parameters
        let imageHash = request.image.extent.hashValue
        let recognitionLevel = request.options.recognitionLevel.rawValue
        let minimumHeight = Int(request.options.minimumTextHeight * 1000)
        let minimumConfidence = Int(request.options.minimumConfidence * 1000)
        let languages = request.options.preferredLanguages.joined(separator: ",")
        let roi = request.options.regionOfInterest?.debugDescription ?? "full"
        return "\(imageHash)_\(recognitionLevel)_\(minimumHeight)_\(minimumConfidence)_\(languages)_\(roi)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRecognitions)) + 1
        let totalRecognitions = metrics.totalRecognitions + 1
        let newCacheHitRate = cacheHits / Double(totalRecognitions)
        
        metrics = TextRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions + 1,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByLanguage: metrics.recognitionsByLanguage,
            recognitionsByLevel: metrics.recognitionsByLevel,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageWordsPerImage: metrics.averageWordsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            languageDetectionAccuracy: metrics.languageDetectionAccuracy
        )
    }
    
    private func updateSuccessMetrics(_ result: TextRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let successfulRecognitions = metrics.successfulRecognitions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRecognitions)) + result.processingTime) / Double(totalRecognitions)
        
        var recognitionsByLanguage = metrics.recognitionsByLanguage
        for detection in result.detectedLanguages {
            recognitionsByLanguage[detection.languageCode, default: 0] += 1
        }
        
        var recognitionsByLevel = metrics.recognitionsByLevel
        recognitionsByLevel[configuration.recognitionLevel.rawValue, default: 0] += 1
        
        let newAverageConfidence = result.textObservations.isEmpty ? metrics.averageConfidence :
            ((metrics.averageConfidence * Double(metrics.successfulRecognitions)) + Double(result.averageConfidence)) / Double(successfulRecognitions)
        
        let newAverageWordsPerImage = ((metrics.averageWordsPerImage * Double(metrics.successfulRecognitions)) + Double(result.wordCount)) / Double(successfulRecognitions)
        
        metrics = TextRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: successfulRecognitions,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: newAverageProcessingTime,
            recognitionsByLanguage: recognitionsByLanguage,
            recognitionsByLevel: recognitionsByLevel,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            averageWordsPerImage: newAverageWordsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            languageDetectionAccuracy: metrics.languageDetectionAccuracy
        )
    }
    
    private func updateFailureMetrics(_ result: TextRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let failedRecognitions = metrics.failedRecognitions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = TextRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions,
            failedRecognitions: failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByLanguage: metrics.recognitionsByLanguage,
            recognitionsByLevel: metrics.recognitionsByLevel,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageWordsPerImage: metrics.averageWordsPerImage,
            throughputPerSecond: metrics.throughputPerSecond,
            languageDetectionAccuracy: metrics.languageDetectionAccuracy
        )
    }
    
    private func logRecognition(_ result: TextRecognitionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let textCount = result.textObservations.count
        let wordCount = result.wordCount
        let avgConfidence = result.averageConfidence
        
        print("[TextRecognition] \(statusIcon) Recognition: \(textCount) text blocks, \(wordCount) words, avg confidence: \(String(format: "%.3f", avgConfidence)) (\(timeStr)s)")
        
        if let error = result.error {
            print("[TextRecognition] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Text Recognition Capability Implementation

/// Text Recognition capability providing comprehensive optical character recognition
@available(iOS 13.0, macOS 10.15, *)
public actor TextRecognitionCapability: DomainCapability {
    public typealias ConfigurationType = TextRecognitionCapabilityConfiguration
    public typealias ResourceType = TextRecognitionCapabilityResource
    
    private var _configuration: TextRecognitionCapabilityConfiguration
    private var _resources: TextRecognitionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "text-recognition-capability" }
    
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
    
    public var configuration: TextRecognitionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: TextRecognitionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: TextRecognitionCapabilityConfiguration = TextRecognitionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = TextRecognitionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: TextRecognitionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Text Recognition configuration")
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
        // Text recognition is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Text recognition doesn't require special permissions beyond camera if using live camera
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Text Recognition Operations
    
    /// Recognize text in image
    public func recognizeText(_ request: TextRecognitionRequest) async throws -> TextRecognitionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return try await _resources.recognizeText(request)
    }
    
    /// Cancel text recognition
    public func cancelRecognition(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        await _resources.cancelRecognition(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<TextRecognitionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active recognitions
    public func getActiveRecognitions() async throws -> [TextRecognitionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return await _resources.getActiveRecognitions()
    }
    
    /// Get recognition history
    public func getRecognitionHistory(since: Date? = nil) async throws -> [TextRecognitionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return await _resources.getRecognitionHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> TextRecognitionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text Recognition capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick text recognition with default options
    public func quickRecognizeText(_ image: CIImage, language: String = "en", minimumConfidence: Float = 0.5) async throws -> String {
        let options = TextRecognitionRequest.RecognitionOptions(
            minimumConfidence: minimumConfidence,
            preferredLanguages: [language]
        )
        
        let request = TextRecognitionRequest(image: image, options: options)
        let result = try await recognizeText(request)
        
        return result.fullText
    }
    
    /// Recognize text with language detection
    public func recognizeTextWithLanguageDetection(_ image: CIImage, minimumConfidence: Float = 0.5) async throws -> TextRecognitionResult {
        let options = TextRecognitionRequest.RecognitionOptions(
            minimumConfidence: minimumConfidence,
            enableAutoLanguageDetection: true
        )
        
        let request = TextRecognitionRequest(image: image, options: options)
        return try await recognizeText(request)
    }
    
    /// Check if text recognition is active
    public func hasActiveRecognitions() async throws -> Bool {
        let activeRecognitions = try await getActiveRecognitions()
        return !activeRecognitions.isEmpty
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

/// Text Recognition specific errors
public enum TextRecognitionError: Error, LocalizedError {
    case textRecognitionDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case recognitionError(String)
    case invalidImage
    case noTextFound
    case recognitionQueued(UUID)
    case recognitionTimeout(UUID)
    case languageNotSupported(String)
    case unsupportedImageFormat
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .textRecognitionDisabled:
            return "Text recognition is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .recognitionError(let reason):
            return "Text recognition failed: \(reason)"
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        case .recognitionQueued(let id):
            return "Text recognition queued: \(id)"
        case .recognitionTimeout(let id):
            return "Text recognition timeout: \(id)"
        case .languageNotSupported(let language):
            return "Language not supported: \(language)"
        case .unsupportedImageFormat:
            return "Unsupported image format"
        case .configurationError(let reason):
            return "Text recognition configuration error: \(reason)"
        }
    }
}