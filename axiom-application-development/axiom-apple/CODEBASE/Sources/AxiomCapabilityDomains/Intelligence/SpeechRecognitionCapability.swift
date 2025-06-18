import Foundation
import Speech
import AVFoundation
import CoreAudio
import AxiomCore
import AxiomCapabilities

// MARK: - Speech Recognition Capability Configuration

/// Configuration for Speech Recognition capability
public struct SpeechRecognitionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableSpeechRecognition: Bool
    public let enableOnDeviceRecognition: Bool
    public let enableContinuousRecognition: Bool
    public let enableRealTimeRecognition: Bool
    public let enablePartialResults: Bool
    public let enableProfanityFilter: Bool
    public let maxConcurrentRecognitions: Int
    public let recognitionTimeout: TimeInterval
    public let audioSessionCategory: AudioSessionCategory
    public let preferredLanguage: String
    public let alternativeLanguages: [String]
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let contextualStrings: [String]
    public let taskHint: TaskHint
    public let speechRecognitionEngine: RecognitionEngine
    
    public enum AudioSessionCategory: String, Codable, CaseIterable {
        case record = "record"
        case playAndRecord = "playAndRecord"
        case ambient = "ambient"
        case soloAmbient = "soloAmbient"
        case playback = "playback"
        case multiRoute = "multiRoute"
    }
    
    public enum TaskHint: String, Codable, CaseIterable {
        case unspecified = "unspecified"
        case dictation = "dictation"
        case search = "search"
        case confirmation = "confirmation"
    }
    
    public enum RecognitionEngine: String, Codable, CaseIterable {
        case system = "system"
        case onDevice = "onDevice"
        case cloud = "cloud"
        case adaptive = "adaptive"
    }
    
    public init(
        enableSpeechRecognition: Bool = true,
        enableOnDeviceRecognition: Bool = true,
        enableContinuousRecognition: Bool = true,
        enableRealTimeRecognition: Bool = true,
        enablePartialResults: Bool = true,
        enableProfanityFilter: Bool = false,
        maxConcurrentRecognitions: Int = 3,
        recognitionTimeout: TimeInterval = 60.0,
        audioSessionCategory: AudioSessionCategory = .record,
        preferredLanguage: String = "en-US",
        alternativeLanguages: [String] = [],
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 50,
        enablePerformanceOptimization: Bool = true,
        contextualStrings: [String] = [],
        taskHint: TaskHint = .unspecified,
        speechRecognitionEngine: RecognitionEngine = .adaptive
    ) {
        self.enableSpeechRecognition = enableSpeechRecognition
        self.enableOnDeviceRecognition = enableOnDeviceRecognition
        self.enableContinuousRecognition = enableContinuousRecognition
        self.enableRealTimeRecognition = enableRealTimeRecognition
        self.enablePartialResults = enablePartialResults
        self.enableProfanityFilter = enableProfanityFilter
        self.maxConcurrentRecognitions = maxConcurrentRecognitions
        self.recognitionTimeout = recognitionTimeout
        self.audioSessionCategory = audioSessionCategory
        self.preferredLanguage = preferredLanguage
        self.alternativeLanguages = alternativeLanguages
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.contextualStrings = contextualStrings
        self.taskHint = taskHint
        self.speechRecognitionEngine = speechRecognitionEngine
    }
    
    public var isValid: Bool {
        maxConcurrentRecognitions > 0 &&
        recognitionTimeout > 0 &&
        cacheSize >= 0 &&
        !preferredLanguage.isEmpty
    }
    
    public func merged(with other: SpeechRecognitionCapabilityConfiguration) -> SpeechRecognitionCapabilityConfiguration {
        SpeechRecognitionCapabilityConfiguration(
            enableSpeechRecognition: other.enableSpeechRecognition,
            enableOnDeviceRecognition: other.enableOnDeviceRecognition,
            enableContinuousRecognition: other.enableContinuousRecognition,
            enableRealTimeRecognition: other.enableRealTimeRecognition,
            enablePartialResults: other.enablePartialResults,
            enableProfanityFilter: other.enableProfanityFilter,
            maxConcurrentRecognitions: other.maxConcurrentRecognitions,
            recognitionTimeout: other.recognitionTimeout,
            audioSessionCategory: other.audioSessionCategory,
            preferredLanguage: other.preferredLanguage,
            alternativeLanguages: other.alternativeLanguages,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            contextualStrings: other.contextualStrings,
            taskHint: other.taskHint,
            speechRecognitionEngine: other.speechRecognitionEngine
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SpeechRecognitionCapabilityConfiguration {
        var adjustedTimeout = recognitionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRecognitions = maxConcurrentRecognitions
        var adjustedCacheSize = cacheSize
        var adjustedEngine = speechRecognitionEngine
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(recognitionTimeout, 30.0)
            adjustedConcurrentRecognitions = min(maxConcurrentRecognitions, 1)
            adjustedCacheSize = min(cacheSize, 10)
            adjustedEngine = .onDevice
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return SpeechRecognitionCapabilityConfiguration(
            enableSpeechRecognition: enableSpeechRecognition,
            enableOnDeviceRecognition: enableOnDeviceRecognition,
            enableContinuousRecognition: enableContinuousRecognition,
            enableRealTimeRecognition: enableRealTimeRecognition,
            enablePartialResults: enablePartialResults,
            enableProfanityFilter: enableProfanityFilter,
            maxConcurrentRecognitions: adjustedConcurrentRecognitions,
            recognitionTimeout: adjustedTimeout,
            audioSessionCategory: audioSessionCategory,
            preferredLanguage: preferredLanguage,
            alternativeLanguages: alternativeLanguages,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            contextualStrings: contextualStrings,
            taskHint: taskHint,
            speechRecognitionEngine: adjustedEngine
        )
    }
}

// MARK: - Speech Recognition Types

/// Speech recognition request
public struct SpeechRecognitionRequest: Sendable, Identifiable {
    public let id: UUID
    public let audioInput: AudioInput
    public let options: RecognitionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public enum AudioInput: Sendable {
        case audioBuffer(AVAudioPCMBuffer)
        case audioFile(URL)
        case liveAudio(AVAudioEngine)
        case audioData(Data, format: AVAudioFormat)
    }
    
    public struct RecognitionOptions: Sendable {
        public let language: String
        public let enablePartialResults: Bool
        public let enableProfanityFilter: Bool
        public let enablePunctuation: Bool
        public let enableCapitalization: Bool
        public let contextualStrings: [String]
        public let taskHint: SpeechRecognitionCapabilityConfiguration.TaskHint
        public let requireOnDeviceRecognition: Bool
        public let maximumRecognitionDuration: TimeInterval
        public let interactionIdentifier: String?
        
        public init(
            language: String = "en-US",
            enablePartialResults: Bool = true,
            enableProfanityFilter: Bool = false,
            enablePunctuation: Bool = true,
            enableCapitalization: Bool = true,
            contextualStrings: [String] = [],
            taskHint: SpeechRecognitionCapabilityConfiguration.TaskHint = .unspecified,
            requireOnDeviceRecognition: Bool = false,
            maximumRecognitionDuration: TimeInterval = 60.0,
            interactionIdentifier: String? = nil
        ) {
            self.language = language
            self.enablePartialResults = enablePartialResults
            self.enableProfanityFilter = enableProfanityFilter
            self.enablePunctuation = enablePunctuation
            self.enableCapitalization = enableCapitalization
            self.contextualStrings = contextualStrings
            self.taskHint = taskHint
            self.requireOnDeviceRecognition = requireOnDeviceRecognition
            self.maximumRecognitionDuration = maximumRecognitionDuration
            self.interactionIdentifier = interactionIdentifier
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        audioInput: AudioInput,
        options: RecognitionOptions = RecognitionOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.audioInput = audioInput
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Speech recognition result
public struct SpeechRecognitionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let transcriptions: [Transcription]
    public let bestTranscription: Transcription?
    public let isFinal: Bool
    public let processingTime: TimeInterval
    public let audioMetrics: AudioMetrics?
    public let success: Bool
    public let error: SpeechRecognitionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct Transcription: Sendable {
        public let formattedString: String
        public let segments: [TranscriptionSegment]
        public let confidence: Float
        public let averageConfidence: Float
        public let speakingRate: Double?
        public let averagePauseDuration: TimeInterval?
        
        public init(formattedString: String, segments: [TranscriptionSegment], confidence: Float) {
            self.formattedString = formattedString
            self.segments = segments
            self.confidence = confidence
            self.averageConfidence = segments.isEmpty ? confidence : segments.reduce(0) { $0 + $1.confidence } / Float(segments.count)
            self.speakingRate = nil // Would be calculated from timing data
            self.averagePauseDuration = nil // Would be calculated from timing data
        }
    }
    
    public struct TranscriptionSegment: Sendable {
        public let substring: String
        public let confidence: Float
        public let timestamp: TimeInterval
        public let duration: TimeInterval
        public let alternativeSubstrings: [AlternativeTranscription]
        
        public struct AlternativeTranscription: Sendable {
            public let substring: String
            public let confidence: Float
            
            public init(substring: String, confidence: Float) {
                self.substring = substring
                self.confidence = confidence
            }
        }
        
        public init(
            substring: String,
            confidence: Float,
            timestamp: TimeInterval,
            duration: TimeInterval,
            alternativeSubstrings: [AlternativeTranscription] = []
        ) {
            self.substring = substring
            self.confidence = confidence
            self.timestamp = timestamp
            self.duration = duration
            self.alternativeSubstrings = alternativeSubstrings
        }
    }
    
    public struct AudioMetrics: Sendable {
        public let averagePower: Float
        public let peakPower: Float
        public let duration: TimeInterval
        public let sampleRate: Double
        public let channels: UInt32
        public let speechDetected: Bool
        public let silenceRatio: Float
        
        public init(
            averagePower: Float,
            peakPower: Float,
            duration: TimeInterval,
            sampleRate: Double,
            channels: UInt32,
            speechDetected: Bool,
            silenceRatio: Float
        ) {
            self.averagePower = averagePower
            self.peakPower = peakPower
            self.duration = duration
            self.sampleRate = sampleRate
            self.channels = channels
            self.speechDetected = speechDetected
            self.silenceRatio = silenceRatio
        }
    }
    
    public init(
        requestId: UUID,
        transcriptions: [Transcription],
        isFinal: Bool,
        processingTime: TimeInterval,
        audioMetrics: AudioMetrics? = nil,
        success: Bool,
        error: SpeechRecognitionError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.transcriptions = transcriptions
        self.bestTranscription = transcriptions.max(by: { $0.confidence < $1.confidence })
        self.isFinal = isFinal
        self.processingTime = processingTime
        self.audioMetrics = audioMetrics
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var recognizedText: String {
        bestTranscription?.formattedString ?? ""
    }
    
    public var averageConfidence: Float {
        guard !transcriptions.isEmpty else { return 0.0 }
        return transcriptions.reduce(0) { $0 + $1.confidence } / Float(transcriptions.count)
    }
    
    public var wordCount: Int {
        recognizedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}

/// Speech recognition metrics
public struct SpeechRecognitionMetrics: Sendable {
    public let totalRecognitions: Int
    public let successfulRecognitions: Int
    public let failedRecognitions: Int
    public let averageProcessingTime: TimeInterval
    public let recognitionsByLanguage: [String: Int]
    public let recognitionsByEngine: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageConfidence: Double
    public let averageAudioDuration: TimeInterval
    public let throughputPerSecond: Double
    public let onDeviceUsageRate: Double
    public let realTimeRecognitionRate: Double
    
    public init(
        totalRecognitions: Int = 0,
        successfulRecognitions: Int = 0,
        failedRecognitions: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        recognitionsByLanguage: [String: Int] = [:],
        recognitionsByEngine: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageConfidence: Double = 0,
        averageAudioDuration: TimeInterval = 0,
        throughputPerSecond: Double = 0,
        onDeviceUsageRate: Double = 0,
        realTimeRecognitionRate: Double = 0
    ) {
        self.totalRecognitions = totalRecognitions
        self.successfulRecognitions = successfulRecognitions
        self.failedRecognitions = failedRecognitions
        self.averageProcessingTime = averageProcessingTime
        self.recognitionsByLanguage = recognitionsByLanguage
        self.recognitionsByEngine = recognitionsByEngine
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageConfidence = averageConfidence
        self.averageAudioDuration = averageAudioDuration
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRecognitions) / averageProcessingTime : 0
        self.onDeviceUsageRate = onDeviceUsageRate
        self.realTimeRecognitionRate = realTimeRecognitionRate
    }
    
    public var successRate: Double {
        totalRecognitions > 0 ? Double(successfulRecognitions) / Double(totalRecognitions) : 0
    }
}

// MARK: - Speech Recognition Resource

/// Speech recognition resource management
@available(iOS 13.0, macOS 10.15, *)
public actor SpeechRecognitionCapabilityResource: AxiomCapabilityResource {
    private let configuration: SpeechRecognitionCapabilityConfiguration
    private var activeRecognitions: [UUID: SpeechRecognitionRequest] = [:]
    private var recognitionQueue: [SpeechRecognitionRequest] = [:]
    private var recognitionHistory: [SpeechRecognitionResult] = [:]
    private var resultCache: [String: SpeechRecognitionResult] = [:]
    private var speechRecognizers: [String: SFSpeechRecognizer] = [:]
    private var audioEngine: AVAudioEngine?
    private var metrics: SpeechRecognitionMetrics = SpeechRecognitionMetrics()
    private var resultStreamContinuation: AsyncStream<SpeechRecognitionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    private var hasAudioSessionPermission: Bool = false
    private var hasSpeechRecognitionPermission: Bool = false
    
    public init(configuration: SpeechRecognitionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for speech recognition
            cpu: 3.0, // Moderate CPU usage for speech processing
            bandwidth: 10_000_000, // 10MB for cloud-based recognition
            storage: 50_000_000 // 50MB for caching and models
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let recognitionMemory = activeRecognitions.count * 20_000_000 // ~20MB per active recognition
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let recognizerMemory = speechRecognizers.count * 10_000_000 // ~10MB per loaded recognizer
            let historyMemory = recognitionHistory.count * 20_000
            let audioEngineMemory = audioEngine != nil ? 30_000_000 : 0
            
            return ResourceUsage(
                memory: recognitionMemory + cacheMemory + recognizerMemory + historyMemory + audioEngineMemory + 20_000_000,
                cpu: activeRecognitions.isEmpty ? 0.2 : 2.5,
                bandwidth: activeRecognitions.count * 1_000_000, // ~1MB per active recognition
                storage: resultCache.count * 50_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Speech recognition is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableSpeechRecognition && SFSpeechRecognizer.authorizationStatus() != .denied
        }
        return false
    }
    
    public func release() async {
        activeRecognitions.removeAll()
        recognitionQueue.removeAll()
        recognitionHistory.removeAll()
        resultCache.removeAll()
        speechRecognizers.removeAll()
        
        if let engine = audioEngine {
            engine.stop()
            audioEngine = nil
        }
        
        resultStreamContinuation?.finish()
        
        metrics = SpeechRecognitionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Request permissions
        try await requestPermissions()
        
        // Initialize speech recognizers for configured languages
        await setupSpeechRecognizers()
        
        // Setup audio engine if needed
        if configuration.enableRealTimeRecognition {
            await setupAudioEngine()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[SpeechRecognition] 🚀 Speech Recognition capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: SpeechRecognitionCapabilityConfiguration) async throws {
        // Update recognizers if languages changed
        await setupSpeechRecognizers()
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() async throws {
        // Request speech recognition permission
        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    Task { await self.setSpeechRecognitionPermission(true) }
                    continuation.resume()
                case .denied, .restricted, .notDetermined:
                    Task { await self.setSpeechRecognitionPermission(false) }
                    continuation.resume(throwing: SpeechRecognitionError.permissionDenied)
                @unknown default:
                    Task { await self.setSpeechRecognitionPermission(false) }
                    continuation.resume(throwing: SpeechRecognitionError.permissionDenied)
                }
            }
        }
    }
    
    private func setSpeechRecognitionPermission(_ granted: Bool) {
        hasSpeechRecognitionPermission = granted
    }
    
    private func setAudioSessionPermission(_ granted: Bool) {
        hasAudioSessionPermission = granted
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<SpeechRecognitionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupSpeechRecognizers() async {
        speechRecognizers.removeAll()
        
        // Primary language recognizer
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: configuration.preferredLanguage)) {
            speechRecognizers[configuration.preferredLanguage] = recognizer
        }
        
        // Alternative language recognizers
        for language in configuration.alternativeLanguages {
            if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) {
                speechRecognizers[language] = recognizer
            }
        }
        
        if configuration.enableLogging {
            print("[SpeechRecognition] 📦 Loaded \(speechRecognizers.count) speech recognizers")
        }
    }
    
    private func setupAudioEngine() async {
        audioEngine = AVAudioEngine()
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            let category = convertAudioSessionCategory(configuration.audioSessionCategory)
            try audioSession.setCategory(category, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            hasAudioSessionPermission = true
        } catch {
            if configuration.enableLogging {
                print("[SpeechRecognition] ⚠️ Failed to setup audio session: \(error)")
            }
            hasAudioSessionPermission = false
        }
    }
    
    private func convertAudioSessionCategory(_ category: SpeechRecognitionCapabilityConfiguration.AudioSessionCategory) -> AVAudioSession.Category {
        switch category {
        case .record: return .record
        case .playAndRecord: return .playAndRecord
        case .ambient: return .ambient
        case .soloAmbient: return .soloAmbient
        case .playback: return .playback
        case .multiRoute: return .multiRoute
        }
    }
    
    // MARK: - Speech Recognition
    
    public func recognizeSpeech(_ request: SpeechRecognitionRequest) async throws -> SpeechRecognitionResult {
        guard configuration.enableSpeechRecognition else {
            throw SpeechRecognitionError.speechRecognitionDisabled
        }
        
        guard hasSpeechRecognitionPermission else {
            throw SpeechRecognitionError.permissionDenied
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
            throw SpeechRecognitionError.recognitionQueued(request.id)
        }
        
        let startTime = Date()
        activeRecognitions[request.id] = request
        
        do {
            // Get appropriate recognizer
            guard let recognizer = speechRecognizers[request.options.language] else {
                throw SpeechRecognitionError.languageNotSupported(request.options.language)
            }
            
            // Perform speech recognition
            let result = try await performSpeechRecognition(
                recognizer: recognizer,
                request: request,
                startTime: startTime
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
            let result = SpeechRecognitionResult(
                requestId: request.id,
                transcriptions: [],
                isFinal: true,
                processingTime: processingTime,
                success: false,
                error: error as? SpeechRecognitionError ?? SpeechRecognitionError.recognitionError(error.localizedDescription)
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
    
    private func performSpeechRecognition(
        recognizer: SFSpeechRecognizer,
        request: SpeechRecognitionRequest,
        startTime: Date
    ) async throws -> SpeechRecognitionResult {
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create speech recognition request based on audio input
            let speechRequest: SFSpeechRecognitionRequest
            
            switch request.audioInput {
            case .audioFile(let url):
                speechRequest = SFSpeechURLRecognitionRequest(url: url)
            case .audioBuffer(let buffer):
                speechRequest = SFSpeechAudioBufferRecognitionRequest()
                (speechRequest as! SFSpeechAudioBufferRecognitionRequest).append(buffer)
                (speechRequest as! SFSpeechAudioBufferRecognitionRequest).endAudio()
            case .audioData(let data, let format):
                speechRequest = SFSpeechAudioBufferRecognitionRequest()
                // Convert data to PCM buffer and append
                let bufferRequest = speechRequest as! SFSpeechAudioBufferRecognitionRequest
                // Create buffer from data (simplified)
                if let buffer = createPCMBuffer(from: data, format: format) {
                    bufferRequest.append(buffer)
                }
                bufferRequest.endAudio()
            case .liveAudio(let engine):
                speechRequest = SFSpeechAudioBufferRecognitionRequest()
                // Setup live audio processing (would need more complex implementation)
                (speechRequest as! SFSpeechAudioBufferRecognitionRequest).endAudio()
            }
            
            // Configure request
            speechRequest.shouldReportPartialResults = request.options.enablePartialResults
            speechRequest.taskHint = convertTaskHint(request.options.taskHint)
            speechRequest.requiresOnDeviceRecognition = request.options.requireOnDeviceRecognition
            
            if !request.options.contextualStrings.isEmpty {
                speechRequest.contextualStrings = request.options.contextualStrings
            }
            
            if let interactionId = request.options.interactionIdentifier {
                speechRequest.interactionIdentifier = interactionId
            }
            
            // Start recognition
            let recognitionTask = recognizer.recognitionTask(with: speechRequest) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: SpeechRecognitionError.noSpeechDetected)
                    return
                }
                
                // Process recognition result
                let transcriptions = self.processRecognitionResult(result)
                let processingTime = Date().timeIntervalSince(startTime)
                
                let speechResult = SpeechRecognitionResult(
                    requestId: request.id,
                    transcriptions: transcriptions,
                    isFinal: result.isFinal,
                    processingTime: processingTime,
                    success: true
                )
                
                // For partial results, yield to stream but don't complete continuation
                if !result.isFinal && request.options.enablePartialResults {
                    Task {
                        await self.resultStreamContinuation?.yield(speechResult)
                    }
                } else if result.isFinal {
                    continuation.resume(returning: speechResult)
                }
            }
            
            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + request.options.maximumRecognitionDuration) {
                if recognitionTask.state == .running {
                    recognitionTask.cancel()
                    continuation.resume(throwing: SpeechRecognitionError.recognitionTimeout(request.id))
                }
            }
        }
    }
    
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) -> [SpeechRecognitionResult.Transcription] {
        return result.transcriptions.map { transcription in
            let segments = transcription.segments.map { segment in
                let alternatives = segment.alternativeSubstrings.map { alt in
                    SpeechRecognitionResult.TranscriptionSegment.AlternativeTranscription(
                        substring: alt.substring,
                        confidence: alt.confidence
                    )
                }
                
                return SpeechRecognitionResult.TranscriptionSegment(
                    substring: segment.substring,
                    confidence: segment.confidence,
                    timestamp: segment.timestamp,
                    duration: segment.duration,
                    alternativeSubstrings: alternatives
                )
            }
            
            return SpeechRecognitionResult.Transcription(
                formattedString: transcription.formattedString,
                segments: segments,
                confidence: Float(result.confidence)
            )
        }
    }
    
    private func createPCMBuffer(from data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            buffer.audioBufferList.pointee.mBuffers.mData = UnsafeMutableRawPointer(mutating: baseAddress)
        }
        
        return buffer
    }
    
    private func convertTaskHint(_ hint: SpeechRecognitionCapabilityConfiguration.TaskHint) -> SFSpeechRecognitionTaskHint {
        switch hint {
        case .unspecified: return .unspecified
        case .dictation: return .dictation
        case .search: return .search
        case .confirmation: return .confirmation
        }
    }
    
    public func cancelRecognition(_ requestId: UUID) async {
        activeRecognitions.removeValue(forKey: requestId)
        recognitionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[SpeechRecognition] 🚫 Cancelled recognition: \(requestId)")
        }
    }
    
    public func getActiveRecognitions() async -> [SpeechRecognitionRequest] {
        return Array(activeRecognitions.values)
    }
    
    public func getRecognitionHistory(since: Date? = nil) async -> [SpeechRecognitionResult] {
        if let since = since {
            return recognitionHistory.filter { $0.timestamp >= since }
        }
        return recognitionHistory
    }
    
    // MARK: - Language Support
    
    public func getSupportedLanguages() async -> [String] {
        return Array(speechRecognizers.keys)
    }
    
    public func isLanguageSupported(_ language: String) async -> Bool {
        return speechRecognizers[language] != nil
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> SpeechRecognitionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = SpeechRecognitionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[SpeechRecognition] ⚡ Performance optimization enabled")
        }
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
                _ = try await recognizeSpeech(request)
            } catch {
                if configuration.enableLogging {
                    print("[SpeechRecognition] ⚠️ Queued recognition failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: SpeechRecognitionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: SpeechRecognitionRequest) -> String {
        // Generate a cache key based on audio input hash and request parameters
        let language = request.options.language
        let taskHint = request.options.taskHint.rawValue
        let onDevice = request.options.requireOnDeviceRecognition
        let contextual = request.options.contextualStrings.joined(separator: ",")
        
        // For audio input, we'd need to generate a hash of the audio data
        let audioHash = "audio_\(request.id.uuidString.prefix(8))" // Simplified
        
        return "\(audioHash)_\(language)_\(taskHint)_\(onDevice)_\(contextual)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRecognitions)) + 1
        let totalRecognitions = metrics.totalRecognitions + 1
        let newCacheHitRate = cacheHits / Double(totalRecognitions)
        
        metrics = SpeechRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions + 1,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByLanguage: metrics.recognitionsByLanguage,
            recognitionsByEngine: metrics.recognitionsByEngine,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageAudioDuration: metrics.averageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            onDeviceUsageRate: metrics.onDeviceUsageRate,
            realTimeRecognitionRate: metrics.realTimeRecognitionRate
        )
    }
    
    private func updateSuccessMetrics(_ result: SpeechRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let successfulRecognitions = metrics.successfulRecognitions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRecognitions)) + result.processingTime) / Double(totalRecognitions)
        
        var recognitionsByLanguage = metrics.recognitionsByLanguage
        // Extract language from result metadata or configuration
        recognitionsByLanguage[configuration.preferredLanguage, default: 0] += 1
        
        var recognitionsByEngine = metrics.recognitionsByEngine
        let engine = configuration.speechRecognitionEngine.rawValue
        recognitionsByEngine[engine, default: 0] += 1
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulRecognitions)) + Double(result.averageConfidence)) / Double(successfulRecognitions)
        
        let audioDuration = result.audioMetrics?.duration ?? 0
        let newAverageAudioDuration = ((metrics.averageAudioDuration * Double(metrics.successfulRecognitions)) + audioDuration) / Double(successfulRecognitions)
        
        metrics = SpeechRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: successfulRecognitions,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: newAverageProcessingTime,
            recognitionsByLanguage: recognitionsByLanguage,
            recognitionsByEngine: recognitionsByEngine,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: newAverageConfidence,
            averageAudioDuration: newAverageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            onDeviceUsageRate: metrics.onDeviceUsageRate,
            realTimeRecognitionRate: metrics.realTimeRecognitionRate
        )
    }
    
    private func updateFailureMetrics(_ result: SpeechRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let failedRecognitions = metrics.failedRecognitions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = SpeechRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions,
            failedRecognitions: failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByLanguage: metrics.recognitionsByLanguage,
            recognitionsByEngine: metrics.recognitionsByEngine,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageConfidence: metrics.averageConfidence,
            averageAudioDuration: metrics.averageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            onDeviceUsageRate: metrics.onDeviceUsageRate,
            realTimeRecognitionRate: metrics.realTimeRecognitionRate
        )
    }
    
    private func logRecognition(_ result: SpeechRecognitionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let transcriptionCount = result.transcriptions.count
        let avgConfidence = result.averageConfidence
        let recognizedText = result.recognizedText.prefix(50)
        
        print("[SpeechRecognition] \(statusIcon) Recognition: \(transcriptionCount) transcriptions, avg confidence: \(String(format: "%.3f", avgConfidence)), text: \"\(recognizedText)...\" (\(timeStr)s)")
        
        if let error = result.error {
            print("[SpeechRecognition] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Speech Recognition Capability Implementation

/// Speech Recognition capability providing speech-to-text conversion
@available(iOS 13.0, macOS 10.15, *)
public actor SpeechRecognitionCapability: DomainCapability {
    public typealias ConfigurationType = SpeechRecognitionCapabilityConfiguration
    public typealias ResourceType = SpeechRecognitionCapabilityResource
    
    private var _configuration: SpeechRecognitionCapabilityConfiguration
    private var _resources: SpeechRecognitionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "speech-recognition-capability" }
    
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
    
    public var configuration: SpeechRecognitionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: SpeechRecognitionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SpeechRecognitionCapabilityConfiguration = SpeechRecognitionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SpeechRecognitionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: SpeechRecognitionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Speech Recognition configuration")
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
        // Speech recognition is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return SFSpeechRecognizer.authorizationStatus() != .denied
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Permission request is handled during allocation
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Speech Recognition Operations
    
    /// Recognize speech from audio input
    public func recognizeSpeech(_ request: SpeechRecognitionRequest) async throws -> SpeechRecognitionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return try await _resources.recognizeSpeech(request)
    }
    
    /// Cancel speech recognition
    public func cancelRecognition(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        await _resources.cancelRecognition(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<SpeechRecognitionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get supported languages
    public func getSupportedLanguages() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.getSupportedLanguages()
    }
    
    /// Check if language is supported
    public func isLanguageSupported(_ language: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.isLanguageSupported(language)
    }
    
    /// Get active recognitions
    public func getActiveRecognitions() async throws -> [SpeechRecognitionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.getActiveRecognitions()
    }
    
    /// Get recognition history
    public func getRecognitionHistory(since: Date? = nil) async throws -> [SpeechRecognitionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.getRecognitionHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> SpeechRecognitionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Speech Recognition capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick speech recognition from audio file
    public func quickRecognizeFromFile(_ url: URL, language: String = "en-US") async throws -> String {
        let options = SpeechRecognitionRequest.RecognitionOptions(language: language)
        let request = SpeechRecognitionRequest(audioInput: .audioFile(url), options: options)
        let result = try await recognizeSpeech(request)
        return result.recognizedText
    }
    
    /// Recognize speech from audio buffer
    public func recognizeFromBuffer(_ buffer: AVAudioPCMBuffer, language: String = "en-US") async throws -> String {
        let options = SpeechRecognitionRequest.RecognitionOptions(language: language)
        let request = SpeechRecognitionRequest(audioInput: .audioBuffer(buffer), options: options)
        let result = try await recognizeSpeech(request)
        return result.recognizedText
    }
    
    /// Check if speech recognition is active
    public func hasActiveRecognitions() async throws -> Bool {
        let activeRecognitions = try await getActiveRecognitions()
        return !activeRecognitions.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Speech Recognition specific errors
public enum SpeechRecognitionError: Error, LocalizedError {
    case speechRecognitionDisabled
    case permissionDenied
    case recognitionError(String)
    case languageNotSupported(String)
    case noSpeechDetected
    case recognitionQueued(UUID)
    case recognitionTimeout(UUID)
    case audioSessionError(String)
    case microphoneUnavailable
    case networkError(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .speechRecognitionDisabled:
            return "Speech recognition is disabled"
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .recognitionError(let reason):
            return "Speech recognition failed: \(reason)"
        case .languageNotSupported(let language):
            return "Language not supported: \(language)"
        case .noSpeechDetected:
            return "No speech detected in audio"
        case .recognitionQueued(let id):
            return "Speech recognition queued: \(id)"
        case .recognitionTimeout(let id):
            return "Speech recognition timeout: \(id)"
        case .audioSessionError(let reason):
            return "Audio session error: \(reason)"
        case .microphoneUnavailable:
            return "Microphone unavailable"
        case .networkError(let reason):
            return "Network error during recognition: \(reason)"
        case .configurationError(let reason):
            return "Speech recognition configuration error: \(reason)"
        }
    }
}