import Foundation
import AVFoundation
import AxiomCore
import AxiomCapabilities

// MARK: - Text To Speech Capability Configuration

/// Configuration for Text-To-Speech capability
public struct TextToSpeechCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableTextToSpeech: Bool
    public let enableVoiceCustomization: Bool
    public let enableRealTimeSpeech: Bool
    public let enableSpeechQueue: Bool
    public let enableBackgroundSpeech: Bool
    public let maxConcurrentSpeech: Int
    public let speechTimeout: TimeInterval
    public let defaultSpeechRate: Float
    public let defaultPitchMultiplier: Float
    public let defaultVolume: Float
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let preferredVoiceLanguage: String
    public let enableSSML: Bool
    public let enablePhonemesGeneration: Bool
    
    public init(
        enableTextToSpeech: Bool = true,
        enableVoiceCustomization: Bool = true,
        enableRealTimeSpeech: Bool = true,
        enableSpeechQueue: Bool = true,
        enableBackgroundSpeech: Bool = false,
        maxConcurrentSpeech: Int = 3,
        speechTimeout: TimeInterval = 300.0,
        defaultSpeechRate: Float = 0.5,
        defaultPitchMultiplier: Float = 1.0,
        defaultVolume: Float = 1.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 50,
        enablePerformanceOptimization: Bool = true,
        preferredVoiceLanguage: String = "en-US",
        enableSSML: Bool = true,
        enablePhonemesGeneration: Bool = false
    ) {
        self.enableTextToSpeech = enableTextToSpeech
        self.enableVoiceCustomization = enableVoiceCustomization
        self.enableRealTimeSpeech = enableRealTimeSpeech
        self.enableSpeechQueue = enableSpeechQueue
        self.enableBackgroundSpeech = enableBackgroundSpeech
        self.maxConcurrentSpeech = maxConcurrentSpeech
        self.speechTimeout = speechTimeout
        self.defaultSpeechRate = defaultSpeechRate
        self.defaultPitchMultiplier = defaultPitchMultiplier
        self.defaultVolume = defaultVolume
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.preferredVoiceLanguage = preferredVoiceLanguage
        self.enableSSML = enableSSML
        self.enablePhonemesGeneration = enablePhonemesGeneration
    }
    
    public var isValid: Bool {
        maxConcurrentSpeech > 0 &&
        speechTimeout > 0 &&
        defaultSpeechRate >= 0.0 && defaultSpeechRate <= 1.0 &&
        defaultPitchMultiplier >= 0.5 && defaultPitchMultiplier <= 2.0 &&
        defaultVolume >= 0.0 && defaultVolume <= 1.0 &&
        cacheSize >= 0 &&
        !preferredVoiceLanguage.isEmpty
    }
    
    public func merged(with other: TextToSpeechCapabilityConfiguration) -> TextToSpeechCapabilityConfiguration {
        TextToSpeechCapabilityConfiguration(
            enableTextToSpeech: other.enableTextToSpeech,
            enableVoiceCustomization: other.enableVoiceCustomization,
            enableRealTimeSpeech: other.enableRealTimeSpeech,
            enableSpeechQueue: other.enableSpeechQueue,
            enableBackgroundSpeech: other.enableBackgroundSpeech,
            maxConcurrentSpeech: other.maxConcurrentSpeech,
            speechTimeout: other.speechTimeout,
            defaultSpeechRate: other.defaultSpeechRate,
            defaultPitchMultiplier: other.defaultPitchMultiplier,
            defaultVolume: other.defaultVolume,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            preferredVoiceLanguage: other.preferredVoiceLanguage,
            enableSSML: other.enableSSML,
            enablePhonemesGeneration: other.enablePhonemesGeneration
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> TextToSpeechCapabilityConfiguration {
        var adjustedTimeout = speechTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentSpeech = maxConcurrentSpeech
        var adjustedCacheSize = cacheSize
        var adjustedBackgroundSpeech = enableBackgroundSpeech
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(speechTimeout, 60.0)
            adjustedConcurrentSpeech = min(maxConcurrentSpeech, 1)
            adjustedCacheSize = min(cacheSize, 10)
            adjustedBackgroundSpeech = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return TextToSpeechCapabilityConfiguration(
            enableTextToSpeech: enableTextToSpeech,
            enableVoiceCustomization: enableVoiceCustomization,
            enableRealTimeSpeech: enableRealTimeSpeech,
            enableSpeechQueue: enableSpeechQueue,
            enableBackgroundSpeech: adjustedBackgroundSpeech,
            maxConcurrentSpeech: adjustedConcurrentSpeech,
            speechTimeout: adjustedTimeout,
            defaultSpeechRate: defaultSpeechRate,
            defaultPitchMultiplier: defaultPitchMultiplier,
            defaultVolume: defaultVolume,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            preferredVoiceLanguage: preferredVoiceLanguage,
            enableSSML: enableSSML,
            enablePhonemesGeneration: enablePhonemesGeneration
        )
    }
}

// MARK: - Text To Speech Types

/// Text-to-speech request
public struct TextToSpeechRequest: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let options: SpeechOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct SpeechOptions: Sendable {
        public let voiceIdentifier: String?
        public let language: String?
        public let speechRate: Float?
        public let pitchMultiplier: Float?
        public let volume: Float?
        public let preUtteranceDelay: TimeInterval
        public let postUtteranceDelay: TimeInterval
        public let enablePhonemes: Bool
        public let enableSSML: Bool
        public let audioSessionCategory: AudioSessionCategory
        public let outputToFile: URL?
        
        public enum AudioSessionCategory: String, Sendable, CaseIterable {
            case ambient = "ambient"
            case soloAmbient = "soloAmbient"
            case playback = "playback"
            case record = "record"
            case playAndRecord = "playAndRecord"
            case multiRoute = "multiRoute"
        }
        
        public init(
            voiceIdentifier: String? = nil,
            language: String? = nil,
            speechRate: Float? = nil,
            pitchMultiplier: Float? = nil,
            volume: Float? = nil,
            preUtteranceDelay: TimeInterval = 0.0,
            postUtteranceDelay: TimeInterval = 0.0,
            enablePhonemes: Bool = false,
            enableSSML: Bool = false,
            audioSessionCategory: AudioSessionCategory = .playback,
            outputToFile: URL? = nil
        ) {
            self.voiceIdentifier = voiceIdentifier
            self.language = language
            self.speechRate = speechRate
            self.pitchMultiplier = pitchMultiplier
            self.volume = volume
            self.preUtteranceDelay = preUtteranceDelay
            self.postUtteranceDelay = postUtteranceDelay
            self.enablePhonemes = enablePhonemes
            self.enableSSML = enableSSML
            self.audioSessionCategory = audioSessionCategory
            self.outputToFile = outputToFile
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
        options: SpeechOptions = SpeechOptions(),
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

/// Text-to-speech result
public struct TextToSpeechResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let voiceInfo: VoiceInfo
    public let speechMetrics: SpeechMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: TextToSpeechError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct VoiceInfo: Sendable {
        public let identifier: String
        public let name: String
        public let language: String
        public let quality: VoiceQuality
        public let gender: VoiceGender
        public let age: VoiceAge?
        
        public enum VoiceQuality: String, Sendable, CaseIterable {
            case default_ = "default"
            case enhanced = "enhanced"
            case premium = "premium"
        }
        
        public enum VoiceGender: String, Sendable, CaseIterable {
            case male = "male"
            case female = "female"
            case unspecified = "unspecified"
        }
        
        public enum VoiceAge: String, Sendable, CaseIterable {
            case child = "child"
            case teen = "teen"
            case adult = "adult"
            case senior = "senior"
        }
        
        public init(identifier: String, name: String, language: String, quality: VoiceQuality, gender: VoiceGender, age: VoiceAge? = nil) {
            self.identifier = identifier
            self.name = name
            self.language = language
            self.quality = quality
            self.gender = gender
            self.age = age
        }
    }
    
    public struct SpeechMetrics: Sendable {
        public let speechDuration: TimeInterval
        public let speechRate: Float
        public let pitchMultiplier: Float
        public let volume: Float
        public let wordCount: Int
        public let characterCount: Int
        public let phonemeCount: Int?
        public let averagePitch: Float?
        public let speechRanges: [SpeechRange]
        
        public struct SpeechRange: Sendable {
            public let textRange: NSRange
            public let speechTimeRange: TimeInterval
            public let phonemes: [PhonemeInfo]?
            
            public struct PhonemeInfo: Sendable {
                public let phoneme: String
                public let timeRange: TimeInterval
                
                public init(phoneme: String, timeRange: TimeInterval) {
                    self.phoneme = phoneme
                    self.timeRange = timeRange
                }
            }
            
            public init(textRange: NSRange, speechTimeRange: TimeInterval, phonemes: [PhonemeInfo]? = nil) {
                self.textRange = textRange
                self.speechTimeRange = speechTimeRange
                self.phonemes = phonemes
            }
        }
        
        public init(
            speechDuration: TimeInterval,
            speechRate: Float,
            pitchMultiplier: Float,
            volume: Float,
            wordCount: Int,
            characterCount: Int,
            phonemeCount: Int? = nil,
            averagePitch: Float? = nil,
            speechRanges: [SpeechRange] = []
        ) {
            self.speechDuration = speechDuration
            self.speechRate = speechRate
            self.pitchMultiplier = pitchMultiplier
            self.volume = volume
            self.wordCount = wordCount
            self.characterCount = characterCount
            self.phonemeCount = phonemeCount
            self.averagePitch = averagePitch
            self.speechRanges = speechRanges
        }
    }
    
    public init(
        requestId: UUID,
        voiceInfo: VoiceInfo,
        speechMetrics: SpeechMetrics,
        processingTime: TimeInterval,
        success: Bool,
        error: TextToSpeechError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.voiceInfo = voiceInfo
        self.speechMetrics = speechMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var wordsPerMinute: Double {
        speechMetrics.speechDuration > 0 ? Double(speechMetrics.wordCount) / (speechMetrics.speechDuration / 60.0) : 0
    }
    
    public var charactersPerSecond: Double {
        speechMetrics.speechDuration > 0 ? Double(speechMetrics.characterCount) / speechMetrics.speechDuration : 0
    }
}

/// Text-to-speech metrics
public struct TextToSpeechMetrics: Sendable {
    public let totalSpeechRequests: Int
    public let successfulSpeechRequests: Int
    public let failedSpeechRequests: Int
    public let averageProcessingTime: TimeInterval
    public let speechByLanguage: [String: Int]
    public let speechByVoice: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageSpeechDuration: TimeInterval
    public let averageWordsPerMinute: Double
    public let throughputPerSecond: Double
    public let voiceUsageStats: VoiceUsageStats
    
    public struct VoiceUsageStats: Sendable {
        public let totalVoicesUsed: Int
        public let mostUsedVoice: String?
        public let averageVoiceQuality: Double
        public let genderDistribution: [String: Int]
        public let languageDistribution: [String: Int]
        
        public init(
            totalVoicesUsed: Int = 0,
            mostUsedVoice: String? = nil,
            averageVoiceQuality: Double = 0,
            genderDistribution: [String: Int] = [:],
            languageDistribution: [String: Int] = [:]
        ) {
            self.totalVoicesUsed = totalVoicesUsed
            self.mostUsedVoice = mostUsedVoice
            self.averageVoiceQuality = averageVoiceQuality
            self.genderDistribution = genderDistribution
            self.languageDistribution = languageDistribution
        }
    }
    
    public init(
        totalSpeechRequests: Int = 0,
        successfulSpeechRequests: Int = 0,
        failedSpeechRequests: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        speechByLanguage: [String: Int] = [:],
        speechByVoice: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageSpeechDuration: TimeInterval = 0,
        averageWordsPerMinute: Double = 0,
        throughputPerSecond: Double = 0,
        voiceUsageStats: VoiceUsageStats = VoiceUsageStats()
    ) {
        self.totalSpeechRequests = totalSpeechRequests
        self.successfulSpeechRequests = successfulSpeechRequests
        self.failedSpeechRequests = failedSpeechRequests
        self.averageProcessingTime = averageProcessingTime
        self.speechByLanguage = speechByLanguage
        self.speechByVoice = speechByVoice
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageSpeechDuration = averageSpeechDuration
        self.averageWordsPerMinute = averageWordsPerMinute
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalSpeechRequests) / averageProcessingTime : 0
        self.voiceUsageStats = voiceUsageStats
    }
    
    public var successRate: Double {
        totalSpeechRequests > 0 ? Double(successfulSpeechRequests) / Double(totalSpeechRequests) : 0
    }
}

// MARK: - Text To Speech Resource

/// Text-to-speech resource management
@available(iOS 13.0, macOS 10.15, *)
public actor TextToSpeechCapabilityResource: AxiomCapabilityResource {
    private let configuration: TextToSpeechCapabilityConfiguration
    private var activeSpeechRequests: [UUID: TextToSpeechRequest] = [:]
    private var speechQueue: [TextToSpeechRequest] = [:]
    private var speechHistory: [TextToSpeechResult] = [:]
    private var resultCache: [String: TextToSpeechResult] = [:]
    private var speechSynthesizers: [UUID: AVSpeechSynthesizer] = [:]
    private var availableVoices: [AVSpeechSynthesisVoice] = []
    private var metrics: TextToSpeechMetrics = TextToSpeechMetrics()
    private var resultStreamContinuation: AsyncStream<TextToSpeechResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: TextToSpeechCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 100_000_000, // 100MB for text-to-speech
            cpu: 2.5, // Moderate CPU usage for speech synthesis
            bandwidth: 0,
            storage: 30_000_000 // 30MB for caching and voice data
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let speechMemory = activeSpeechRequests.count * 15_000_000 // ~15MB per active speech
            let cacheMemory = resultCache.count * 50_000 // ~50KB per cached result
            let synthesizerMemory = speechSynthesizers.count * 5_000_000 // ~5MB per synthesizer
            let historyMemory = speechHistory.count * 10_000
            let voiceMemory = availableVoices.count * 50_000 // ~50KB per voice
            
            return ResourceUsage(
                memory: speechMemory + cacheMemory + synthesizerMemory + historyMemory + voiceMemory + 15_000_000,
                cpu: activeSpeechRequests.isEmpty ? 0.1 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 25_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Text-to-speech is available on iOS 7+, macOS 10.9+
        if #available(iOS 7.0, macOS 10.9, *) {
            return configuration.enableTextToSpeech
        }
        return false
    }
    
    public func release() async {
        // Stop all active speech
        for synthesizer in speechSynthesizers.values {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        activeSpeechRequests.removeAll()
        speechQueue.removeAll()
        speechHistory.removeAll()
        resultCache.removeAll()
        speechSynthesizers.removeAll()
        availableVoices.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = TextToSpeechMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Load available voices
        await loadAvailableVoices()
        
        // Setup audio session if needed
        await setupAudioSession()
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[TextToSpeech] 🚀 Text-to-Speech capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: TextToSpeechCapabilityConfiguration) async throws {
        // Update voice configurations
        await loadAvailableVoices()
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<TextToSpeechResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Voice Management
    
    public func getAvailableVoices() async -> [TextToSpeechResult.VoiceInfo] {
        return availableVoices.map { voice in
            TextToSpeechResult.VoiceInfo(
                identifier: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: mapVoiceQuality(voice.quality),
                gender: mapVoiceGender(voice.gender)
            )
        }
    }
    
    public func getVoicesForLanguage(_ language: String) async -> [TextToSpeechResult.VoiceInfo] {
        let voices = await getAvailableVoices()
        return voices.filter { $0.language.hasPrefix(language) }
    }
    
    public func getPreferredVoice() async -> TextToSpeechResult.VoiceInfo? {
        let voices = await getVoicesForLanguage(configuration.preferredVoiceLanguage)
        return voices.first
    }
    
    // MARK: - Text-to-Speech
    
    public func synthesizeSpeech(_ request: TextToSpeechRequest) async throws -> TextToSpeechResult {
        guard configuration.enableTextToSpeech else {
            throw TextToSpeechError.textToSpeechDisabled
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
        if activeSpeechRequests.count >= configuration.maxConcurrentSpeech {
            speechQueue.append(request)
            throw TextToSpeechError.speechQueued(request.id)
        }
        
        let startTime = Date()
        activeSpeechRequests[request.id] = request
        
        do {
            // Get voice for synthesis
            let voice = try await getVoiceForRequest(request)
            
            // Create speech utterance
            let utterance = createUtterance(from: request, voice: voice)
            
            // Perform synthesis
            let result = try await performSpeechSynthesis(
                request: request,
                utterance: utterance,
                voice: voice,
                startTime: startTime
            )
            
            activeSpeechRequests.removeValue(forKey: request.id)
            speechHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logSpeech(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processSpeechQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Create default voice info for error case
            let defaultVoice = TextToSpeechResult.VoiceInfo(
                identifier: "default",
                name: "Default Voice",
                language: configuration.preferredVoiceLanguage,
                quality: .default_,
                gender: .unspecified
            )
            
            let speechMetrics = TextToSpeechResult.SpeechMetrics(
                speechDuration: 0,
                speechRate: configuration.defaultSpeechRate,
                pitchMultiplier: configuration.defaultPitchMultiplier,
                volume: configuration.defaultVolume,
                wordCount: request.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
                characterCount: request.text.count
            )
            
            let result = TextToSpeechResult(
                requestId: request.id,
                voiceInfo: defaultVoice,
                speechMetrics: speechMetrics,
                processingTime: processingTime,
                success: false,
                error: error as? TextToSpeechError ?? TextToSpeechError.speechError(error.localizedDescription)
            )
            
            activeSpeechRequests.removeValue(forKey: request.id)
            speechHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logSpeech(result)
            }
            
            throw error
        }
    }
    
    public func stopSpeech(_ requestId: UUID) async {
        activeSpeechRequests.removeValue(forKey: requestId)
        speechQueue.removeAll { $0.id == requestId }
        
        // Stop the specific synthesizer if it exists
        if let synthesizer = speechSynthesizers[requestId] {
            synthesizer.stopSpeaking(at: .immediate)
            speechSynthesizers.removeValue(forKey: requestId)
        }
        
        if configuration.enableLogging {
            print("[TextToSpeech] 🛑 Stopped speech: \(requestId)")
        }
    }
    
    public func stopAllSpeech() async {
        for synthesizer in speechSynthesizers.values {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        activeSpeechRequests.removeAll()
        speechQueue.removeAll()
        speechSynthesizers.removeAll()
        
        if configuration.enableLogging {
            print("[TextToSpeech] 🛑 Stopped all speech")
        }
    }
    
    public func pauseSpeech(_ requestId: UUID) async {
        if let synthesizer = speechSynthesizers[requestId] {
            synthesizer.pauseSpeaking(at: .word)
            
            if configuration.enableLogging {
                print("[TextToSpeech] ⏸️ Paused speech: \(requestId)")
            }
        }
    }
    
    public func resumeSpeech(_ requestId: UUID) async {
        if let synthesizer = speechSynthesizers[requestId] {
            synthesizer.continueSpeaking()
            
            if configuration.enableLogging {
                print("[TextToSpeech] ▶️ Resumed speech: \(requestId)")
            }
        }
    }
    
    public func getActiveSpeechRequests() async -> [TextToSpeechRequest] {
        return Array(activeSpeechRequests.values)
    }
    
    public func getSpeechHistory(since: Date? = nil) async -> [TextToSpeechResult] {
        if let since = since {
            return speechHistory.filter { $0.timestamp >= since }
        }
        return speechHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> TextToSpeechMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = TextToSpeechMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableVoices() async {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        if configuration.enableLogging {
            print("[TextToSpeech] 📦 Loaded \(availableVoices.count) voices")
        }
    }
    
    private func setupAudioSession() async {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            
            if configuration.enableLogging {
                print("[TextToSpeech] 🔊 Audio session configured")
            }
        } catch {
            if configuration.enableLogging {
                print("[TextToSpeech] ⚠️ Failed to setup audio session: \(error)")
            }
        }
    }
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[TextToSpeech] ⚡ Performance optimization enabled")
        }
    }
    
    private func getVoiceForRequest(_ request: TextToSpeechRequest) async throws -> AVSpeechSynthesisVoice {
        if let voiceId = request.options.voiceIdentifier {
            if let voice = availableVoices.first(where: { $0.identifier == voiceId }) {
                return voice
            }
            throw TextToSpeechError.voiceNotFound(voiceId)
        }
        
        let language = request.options.language ?? configuration.preferredVoiceLanguage
        if let voice = availableVoices.first(where: { $0.language == language }) {
            return voice
        }
        
        // Fallback to default voice
        if let defaultVoice = availableVoices.first {
            return defaultVoice
        }
        
        throw TextToSpeechError.noVoicesAvailable
    }
    
    private func createUtterance(from request: TextToSpeechRequest, voice: AVSpeechSynthesisVoice) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: request.text)
        
        utterance.voice = voice
        utterance.rate = request.options.speechRate ?? configuration.defaultSpeechRate
        utterance.pitchMultiplier = request.options.pitchMultiplier ?? configuration.defaultPitchMultiplier
        utterance.volume = request.options.volume ?? configuration.defaultVolume
        utterance.preUtteranceDelay = request.options.preUtteranceDelay
        utterance.postUtteranceDelay = request.options.postUtteranceDelay
        
        return utterance
    }
    
    private func performSpeechSynthesis(
        request: TextToSpeechRequest,
        utterance: AVSpeechUtterance,
        voice: AVSpeechSynthesisVoice,
        startTime: Date
    ) async throws -> TextToSpeechResult {
        
        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = AVSpeechSynthesizer()
            speechSynthesizers[request.id] = synthesizer
            
            var speechStartTime: Date?
            var speechEndTime: Date?
            var hasFinished = false
            
            // Set up synthesizer delegate
            let delegate = SpeechSynthesizerDelegate(
                onStart: { _ in
                    speechStartTime = Date()
                },
                onFinish: { _ in
                    speechEndTime = Date()
                    
                    guard !hasFinished else { return }
                    hasFinished = true
                    
                    let processingTime = Date().timeIntervalSince(startTime)
                    let speechDuration = speechEndTime?.timeIntervalSince(speechStartTime ?? Date()) ?? 0
                    
                    let voiceInfo = TextToSpeechResult.VoiceInfo(
                        identifier: voice.identifier,
                        name: voice.name,
                        language: voice.language,
                        quality: self.mapVoiceQuality(voice.quality),
                        gender: self.mapVoiceGender(voice.gender)
                    )
                    
                    let speechMetrics = TextToSpeechResult.SpeechMetrics(
                        speechDuration: speechDuration,
                        speechRate: utterance.rate,
                        pitchMultiplier: utterance.pitchMultiplier,
                        volume: utterance.volume,
                        wordCount: request.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
                        characterCount: request.text.count
                    )
                    
                    let result = TextToSpeechResult(
                        requestId: request.id,
                        voiceInfo: voiceInfo,
                        speechMetrics: speechMetrics,
                        processingTime: processingTime,
                        success: true,
                        metadata: request.metadata
                    )
                    
                    continuation.resume(returning: result)
                },
                onError: { error in
                    guard !hasFinished else { return }
                    hasFinished = true
                    continuation.resume(throwing: error)
                }
            )
            
            synthesizer.delegate = delegate
            
            // Start speaking
            synthesizer.speak(utterance)
            
            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.speechTimeout) {
                if !hasFinished {
                    hasFinished = true
                    synthesizer.stopSpeaking(at: .immediate)
                    continuation.resume(throwing: TextToSpeechError.speechTimeout(request.id))
                }
            }
        }
    }
    
    private func mapVoiceQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> TextToSpeechResult.VoiceInfo.VoiceQuality {
        switch quality {
        case .default: return .default_
        case .enhanced: return .enhanced
        case .premium: return .premium
        @unknown default: return .default_
        }
    }
    
    private func mapVoiceGender(_ gender: AVSpeechSynthesisVoiceGender) -> TextToSpeechResult.VoiceInfo.VoiceGender {
        switch gender {
        case .male: return .male
        case .female: return .female
        case .unspecified: return .unspecified
        @unknown default: return .unspecified
        }
    }
    
    private func processSpeechQueue() async {
        guard !isProcessingQueue && !speechQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        speechQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !speechQueue.isEmpty && activeSpeechRequests.count < configuration.maxConcurrentSpeech {
            let request = speechQueue.removeFirst()
            
            do {
                _ = try await synthesizeSpeech(request)
            } catch {
                if configuration.enableLogging {
                    print("[TextToSpeech] ⚠️ Queued speech failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: TextToSpeechRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: TextToSpeechRequest) -> String {
        let textHash = request.text.hashValue
        let voiceId = request.options.voiceIdentifier ?? "default"
        let language = request.options.language ?? configuration.preferredVoiceLanguage
        let rate = Int((request.options.speechRate ?? configuration.defaultSpeechRate) * 100)
        let pitch = Int((request.options.pitchMultiplier ?? configuration.defaultPitchMultiplier) * 100)
        
        return "\(textHash)_\(voiceId)_\(language)_\(rate)_\(pitch)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalSpeechRequests)) + 1
        let totalRequests = metrics.totalSpeechRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = TextToSpeechMetrics(
            totalSpeechRequests: totalRequests,
            successfulSpeechRequests: metrics.successfulSpeechRequests + 1,
            failedSpeechRequests: metrics.failedSpeechRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            speechByLanguage: metrics.speechByLanguage,
            speechByVoice: metrics.speechByVoice,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageSpeechDuration: metrics.averageSpeechDuration,
            averageWordsPerMinute: metrics.averageWordsPerMinute,
            throughputPerSecond: metrics.throughputPerSecond,
            voiceUsageStats: metrics.voiceUsageStats
        )
    }
    
    private func updateSuccessMetrics(_ result: TextToSpeechResult) async {
        let totalRequests = metrics.totalSpeechRequests + 1
        let successfulRequests = metrics.successfulSpeechRequests + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalSpeechRequests)) + result.processingTime) / Double(totalRequests)
        
        var speechByLanguage = metrics.speechByLanguage
        speechByLanguage[result.voiceInfo.language, default: 0] += 1
        
        var speechByVoice = metrics.speechByVoice
        speechByVoice[result.voiceInfo.identifier, default: 0] += 1
        
        let newAverageSpeechDuration = ((metrics.averageSpeechDuration * Double(metrics.successfulSpeechRequests)) + result.speechMetrics.speechDuration) / Double(successfulRequests)
        
        let newAverageWordsPerMinute = ((metrics.averageWordsPerMinute * Double(metrics.successfulSpeechRequests)) + result.wordsPerMinute) / Double(successfulRequests)
        
        // Update voice usage stats
        var genderDistribution = metrics.voiceUsageStats.genderDistribution
        genderDistribution[result.voiceInfo.gender.rawValue, default: 0] += 1
        
        var languageDistribution = metrics.voiceUsageStats.languageDistribution
        languageDistribution[result.voiceInfo.language, default: 0] += 1
        
        let voiceUsageStats = TextToSpeechMetrics.VoiceUsageStats(
            totalVoicesUsed: Set(speechByVoice.keys).count,
            mostUsedVoice: speechByVoice.max(by: { $0.value < $1.value })?.key,
            averageVoiceQuality: calculateAverageVoiceQuality(),
            genderDistribution: genderDistribution,
            languageDistribution: languageDistribution
        )
        
        metrics = TextToSpeechMetrics(
            totalSpeechRequests: totalRequests,
            successfulSpeechRequests: successfulRequests,
            failedSpeechRequests: metrics.failedSpeechRequests,
            averageProcessingTime: newAverageProcessingTime,
            speechByLanguage: speechByLanguage,
            speechByVoice: speechByVoice,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageSpeechDuration: newAverageSpeechDuration,
            averageWordsPerMinute: newAverageWordsPerMinute,
            throughputPerSecond: metrics.throughputPerSecond,
            voiceUsageStats: voiceUsageStats
        )
    }
    
    private func updateFailureMetrics(_ result: TextToSpeechResult) async {
        let totalRequests = metrics.totalSpeechRequests + 1
        let failedRequests = metrics.failedSpeechRequests + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = TextToSpeechMetrics(
            totalSpeechRequests: totalRequests,
            successfulSpeechRequests: metrics.successfulSpeechRequests,
            failedSpeechRequests: failedRequests,
            averageProcessingTime: metrics.averageProcessingTime,
            speechByLanguage: metrics.speechByLanguage,
            speechByVoice: metrics.speechByVoice,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageSpeechDuration: metrics.averageSpeechDuration,
            averageWordsPerMinute: metrics.averageWordsPerMinute,
            throughputPerSecond: metrics.throughputPerSecond,
            voiceUsageStats: metrics.voiceUsageStats
        )
    }
    
    private func calculateAverageVoiceQuality() -> Double {
        // Simplified quality calculation based on voice types
        return 0.75 // Would be calculated from actual voice quality metrics
    }
    
    private func logSpeech(_ result: TextToSpeechResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let durationStr = String(format: "%.1f", result.speechMetrics.speechDuration)
        let wordCount = result.speechMetrics.wordCount
        let wpm = String(format: "%.0f", result.wordsPerMinute)
        
        print("[TextToSpeech] \(statusIcon) Speech: \(wordCount) words, \(wpm) WPM, \(durationStr)s duration (\(timeStr)s processing)")
        
        if let error = result.error {
            print("[TextToSpeech] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Speech Synthesizer Delegate

@available(iOS 13.0, macOS 10.15, *)
private class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let onStart: (AVSpeechUtterance) -> Void
    private let onFinish: (AVSpeechUtterance) -> Void
    private let onError: (Error) -> Void
    
    init(
        onStart: @escaping (AVSpeechUtterance) -> Void,
        onFinish: @escaping (AVSpeechUtterance) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onStart = onStart
        self.onFinish = onFinish
        self.onError = onError
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onStart(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onError(TextToSpeechError.speechCancelled)
    }
}

// MARK: - Text To Speech Capability Implementation

/// Text-to-Speech capability providing comprehensive speech synthesis
@available(iOS 13.0, macOS 10.15, *)
public actor TextToSpeechCapability: DomainCapability {
    public typealias ConfigurationType = TextToSpeechCapabilityConfiguration
    public typealias ResourceType = TextToSpeechCapabilityResource
    
    private var _configuration: TextToSpeechCapabilityConfiguration
    private var _resources: TextToSpeechCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "text-to-speech-capability" }
    
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
    
    public var configuration: TextToSpeechCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: TextToSpeechCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: TextToSpeechCapabilityConfiguration = TextToSpeechCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = TextToSpeechCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: TextToSpeechCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Text-to-Speech configuration")
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
        // Text-to-speech is supported on iOS 7+, macOS 10.9+
        if #available(iOS 7.0, macOS 10.9, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Text-to-speech doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Text-to-Speech Operations
    
    /// Synthesize speech from text
    public func synthesizeSpeech(_ request: TextToSpeechRequest) async throws -> TextToSpeechResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return try await _resources.synthesizeSpeech(request)
    }
    
    /// Stop speech synthesis
    public func stopSpeech(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.stopSpeech(requestId)
    }
    
    /// Stop all speech synthesis
    public func stopAllSpeech() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.stopAllSpeech()
    }
    
    /// Pause speech synthesis
    public func pauseSpeech(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.pauseSpeech(requestId)
    }
    
    /// Resume speech synthesis
    public func resumeSpeech(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.resumeSpeech(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<TextToSpeechResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get available voices
    public func getAvailableVoices() async throws -> [TextToSpeechResult.VoiceInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getAvailableVoices()
    }
    
    /// Get voices for language
    public func getVoicesForLanguage(_ language: String) async throws -> [TextToSpeechResult.VoiceInfo] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getVoicesForLanguage(language)
    }
    
    /// Get preferred voice
    public func getPreferredVoice() async throws -> TextToSpeechResult.VoiceInfo? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getPreferredVoice()
    }
    
    /// Get active speech requests
    public func getActiveSpeechRequests() async throws -> [TextToSpeechRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getActiveSpeechRequests()
    }
    
    /// Get speech history
    public func getSpeechHistory(since: Date? = nil) async throws -> [TextToSpeechResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getSpeechHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> TextToSpeechMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Text-to-Speech capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick speech synthesis with default options
    public func quickSpeak(_ text: String, language: String = "en-US", rate: Float = 0.5) async throws -> TextToSpeechResult {
        let options = TextToSpeechRequest.SpeechOptions(
            language: language,
            speechRate: rate
        )
        
        let request = TextToSpeechRequest(text: text, options: options)
        return try await synthesizeSpeech(request)
    }
    
    /// Check if speech is active
    public func hasActiveSpeech() async throws -> Bool {
        let activeSpeech = try await getActiveSpeechRequests()
        return !activeSpeech.isEmpty
    }
    
    /// Get voice count
    public func getVoiceCount() async throws -> Int {
        let voices = try await getAvailableVoices()
        return voices.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Text-to-Speech specific errors
public enum TextToSpeechError: Error, LocalizedError {
    case textToSpeechDisabled
    case voiceNotFound(String)
    case noVoicesAvailable
    case speechError(String)
    case speechQueued(UUID)
    case speechTimeout(UUID)
    case speechCancelled
    case audioSessionError(String)
    case invalidText
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .textToSpeechDisabled:
            return "Text-to-speech is disabled"
        case .voiceNotFound(let identifier):
            return "Voice not found: \(identifier)"
        case .noVoicesAvailable:
            return "No voices available for speech synthesis"
        case .speechError(let reason):
            return "Speech synthesis failed: \(reason)"
        case .speechQueued(let id):
            return "Speech synthesis queued: \(id)"
        case .speechTimeout(let id):
            return "Speech synthesis timeout: \(id)"
        case .speechCancelled:
            return "Speech synthesis was cancelled"
        case .audioSessionError(let reason):
            return "Audio session error: \(reason)"
        case .invalidText:
            return "Invalid text provided for speech synthesis"
        case .configurationError(let reason):
            return "Text-to-speech configuration error: \(reason)"
        }
    }
}