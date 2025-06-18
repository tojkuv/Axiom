import Foundation
import AVFoundation
import Accelerate
import AxiomCore
import AxiomCapabilities

// MARK: - Microphone Capability Configuration

/// Configuration for Microphone capability
public struct MicrophoneCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let defaultSampleRate: Double
    public let defaultBitDepth: AudioBitDepth
    public let defaultChannelCount: Int
    public let defaultFormat: AudioFormat
    public let enableRealtimeProcessing: Bool
    public let enableAudioLevelMonitoring: Bool
    public let enableNoiseReduction: Bool
    public let enableEchoCancellation: Bool
    public let enableAutomaticGainControl: Bool
    public let audioQuality: AudioQuality
    public let bufferSize: Int
    public let maxRecordingDuration: TimeInterval
    public let enableBackgroundRecording: Bool
    public let enableAudioSessionManagement: Bool
    public let audioSessionCategory: AudioSessionCategory
    public let audioSessionMode: AudioSessionMode
    public let enableAudioInterruption: Bool
    public let enableMetering: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let storageLocation: StorageLocation
    public let compressionSettings: CompressionSettings?
    public let enableSpeechDetection: Bool
    public let enableVoiceActivityDetection: Bool
    public let silenceThreshold: Float
    public let customProcessingEnabled: Bool
    
    public enum AudioBitDepth: Int, Codable, CaseIterable, Sendable {
        case depth8 = 8
        case depth16 = 16
        case depth24 = 24
        case depth32 = 32
    }
    
    public enum AudioFormat: String, Codable, CaseIterable, Sendable {
        case pcm = "pcm"
        case aac = "aac"
        case mp3 = "mp3"
        case wav = "wav"
        case m4a = "m4a"
        case caf = "caf"
    }
    
    public enum AudioQuality: String, Codable, CaseIterable, Sendable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case lossless = "lossless"
    }
    
    public enum AudioSessionCategory: String, Codable, CaseIterable, Sendable {
        case ambient = "ambient"
        case soloAmbient = "soloAmbient"
        case playback = "playback"
        case record = "record"
        case playAndRecord = "playAndRecord"
        case multiRoute = "multiRoute"
    }
    
    public enum AudioSessionMode: String, Codable, CaseIterable, Sendable {
        case `default` = "default"
        case voiceChat = "voiceChat"
        case measurement = "measurement"
        case moviePlayback = "moviePlayback"
        case videoRecording = "videoRecording"
        case gameChat = "gameChat"
        case videoChat = "videoChat"
        case spokenAudio = "spokenAudio"
    }
    
    public enum StorageLocation: String, Codable, CaseIterable, Sendable {
        case documents = "documents"
        case temporary = "temporary"
        case caches = "caches"
        case custom = "custom"
    }
    
    public struct CompressionSettings: Codable, Sendable {
        public let bitRate: Int
        public let compressionQuality: Float
        public let enableVariableBitRate: Bool
        
        public init(
            bitRate: Int = 128000, // 128 kbps
            compressionQuality: Float = 0.7,
            enableVariableBitRate: Bool = true
        ) {
            self.bitRate = bitRate
            self.compressionQuality = compressionQuality
            self.enableVariableBitRate = enableVariableBitRate
        }
    }
    
    public init(
        defaultSampleRate: Double = 44100.0,
        defaultBitDepth: AudioBitDepth = .depth16,
        defaultChannelCount: Int = 1,
        defaultFormat: AudioFormat = .m4a,
        enableRealtimeProcessing: Bool = false,
        enableAudioLevelMonitoring: Bool = true,
        enableNoiseReduction: Bool = true,
        enableEchoCancellation: Bool = true,
        enableAutomaticGainControl: Bool = true,
        audioQuality: AudioQuality = .high,
        bufferSize: Int = 1024,
        maxRecordingDuration: TimeInterval = 3600.0, // 1 hour
        enableBackgroundRecording: Bool = false,
        enableAudioSessionManagement: Bool = true,
        audioSessionCategory: AudioSessionCategory = .record,
        audioSessionMode: AudioSessionMode = .default,
        enableAudioInterruption: Bool = true,
        enableMetering: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        storageLocation: StorageLocation = .documents,
        compressionSettings: CompressionSettings? = CompressionSettings(),
        enableSpeechDetection: Bool = false,
        enableVoiceActivityDetection: Bool = false,
        silenceThreshold: Float = -40.0, // dB
        customProcessingEnabled: Bool = false
    ) {
        self.defaultSampleRate = defaultSampleRate
        self.defaultBitDepth = defaultBitDepth
        self.defaultChannelCount = defaultChannelCount
        self.defaultFormat = defaultFormat
        self.enableRealtimeProcessing = enableRealtimeProcessing
        self.enableAudioLevelMonitoring = enableAudioLevelMonitoring
        self.enableNoiseReduction = enableNoiseReduction
        self.enableEchoCancellation = enableEchoCancellation
        self.enableAutomaticGainControl = enableAutomaticGainControl
        self.audioQuality = audioQuality
        self.bufferSize = bufferSize
        self.maxRecordingDuration = maxRecordingDuration
        self.enableBackgroundRecording = enableBackgroundRecording
        self.enableAudioSessionManagement = enableAudioSessionManagement
        self.audioSessionCategory = audioSessionCategory
        self.audioSessionMode = audioSessionMode
        self.enableAudioInterruption = enableAudioInterruption
        self.enableMetering = enableMetering
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.storageLocation = storageLocation
        self.compressionSettings = compressionSettings
        self.enableSpeechDetection = enableSpeechDetection
        self.enableVoiceActivityDetection = enableVoiceActivityDetection
        self.silenceThreshold = silenceThreshold
        self.customProcessingEnabled = customProcessingEnabled
    }
    
    public var isValid: Bool {
        defaultSampleRate > 0 &&
        defaultChannelCount > 0 &&
        bufferSize > 0 &&
        maxRecordingDuration > 0 &&
        silenceThreshold <= 0
    }
    
    public func merged(with other: MicrophoneCapabilityConfiguration) -> MicrophoneCapabilityConfiguration {
        MicrophoneCapabilityConfiguration(
            defaultSampleRate: other.defaultSampleRate,
            defaultBitDepth: other.defaultBitDepth,
            defaultChannelCount: other.defaultChannelCount,
            defaultFormat: other.defaultFormat,
            enableRealtimeProcessing: other.enableRealtimeProcessing,
            enableAudioLevelMonitoring: other.enableAudioLevelMonitoring,
            enableNoiseReduction: other.enableNoiseReduction,
            enableEchoCancellation: other.enableEchoCancellation,
            enableAutomaticGainControl: other.enableAutomaticGainControl,
            audioQuality: other.audioQuality,
            bufferSize: other.bufferSize,
            maxRecordingDuration: other.maxRecordingDuration,
            enableBackgroundRecording: other.enableBackgroundRecording,
            enableAudioSessionManagement: other.enableAudioSessionManagement,
            audioSessionCategory: other.audioSessionCategory,
            audioSessionMode: other.audioSessionMode,
            enableAudioInterruption: other.enableAudioInterruption,
            enableMetering: other.enableMetering,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            storageLocation: other.storageLocation,
            compressionSettings: other.compressionSettings ?? compressionSettings,
            enableSpeechDetection: other.enableSpeechDetection,
            enableVoiceActivityDetection: other.enableVoiceActivityDetection,
            silenceThreshold: other.silenceThreshold,
            customProcessingEnabled: other.customProcessingEnabled
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> MicrophoneCapabilityConfiguration {
        var adjustedQuality = audioQuality
        var adjustedSampleRate = defaultSampleRate
        var adjustedLogging = enableLogging
        var adjustedDuration = maxRecordingDuration
        var adjustedProcessing = enableRealtimeProcessing
        
        if environment.isLowPowerMode {
            adjustedQuality = .medium
            adjustedSampleRate = min(defaultSampleRate, 22050.0)
            adjustedProcessing = false
            adjustedDuration = min(maxRecordingDuration, 1800.0) // 30 minutes max
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return MicrophoneCapabilityConfiguration(
            defaultSampleRate: adjustedSampleRate,
            defaultBitDepth: defaultBitDepth,
            defaultChannelCount: defaultChannelCount,
            defaultFormat: defaultFormat,
            enableRealtimeProcessing: adjustedProcessing,
            enableAudioLevelMonitoring: enableAudioLevelMonitoring,
            enableNoiseReduction: enableNoiseReduction,
            enableEchoCancellation: enableEchoCancellation,
            enableAutomaticGainControl: enableAutomaticGainControl,
            audioQuality: adjustedQuality,
            bufferSize: bufferSize,
            maxRecordingDuration: adjustedDuration,
            enableBackgroundRecording: enableBackgroundRecording,
            enableAudioSessionManagement: enableAudioSessionManagement,
            audioSessionCategory: audioSessionCategory,
            audioSessionMode: audioSessionMode,
            enableAudioInterruption: enableAudioInterruption,
            enableMetering: enableMetering,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            storageLocation: storageLocation,
            compressionSettings: compressionSettings,
            enableSpeechDetection: enableSpeechDetection,
            enableVoiceActivityDetection: enableVoiceActivityDetection,
            silenceThreshold: silenceThreshold,
            customProcessingEnabled: customProcessingEnabled
        )
    }
}

// MARK: - Audio Types

/// Audio recording state
public enum AudioRecordingState: String, Codable, CaseIterable, Sendable {
    case stopped = "stopped"
    case recording = "recording"
    case paused = "paused"
}

/// Microphone authorization status
public enum MicrophoneAuthorizationStatus: String, Codable, CaseIterable, Sendable {
    case notDetermined = "notDetermined"
    case denied = "denied"
    case granted = "granted"
}

/// Audio recording result
public struct AudioRecordingResult: Sendable {
    public let audioURL: URL
    public let duration: TimeInterval
    public let format: MicrophoneCapabilityConfiguration.AudioFormat
    public let sampleRate: Double
    public let channelCount: Int
    public let bitDepth: MicrophoneCapabilityConfiguration.AudioBitDepth
    public let fileSize: Int64
    public let averageLevel: Float
    public let peakLevel: Float
    public let recordingDate: Date
    public let metadata: [String: Any]?
    
    public init(
        audioURL: URL,
        duration: TimeInterval,
        format: MicrophoneCapabilityConfiguration.AudioFormat,
        sampleRate: Double,
        channelCount: Int,
        bitDepth: MicrophoneCapabilityConfiguration.AudioBitDepth,
        fileSize: Int64,
        averageLevel: Float = 0,
        peakLevel: Float = 0,
        recordingDate: Date = Date(),
        metadata: [String: Any]? = nil
    ) {
        self.audioURL = audioURL
        self.duration = duration
        self.format = format
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitDepth = bitDepth
        self.fileSize = fileSize
        self.averageLevel = averageLevel
        self.peakLevel = peakLevel
        self.recordingDate = recordingDate
        self.metadata = metadata
    }
}

/// Audio level information
public struct AudioLevel: Sendable {
    public let averageLevel: Float
    public let peakLevel: Float
    public let timestamp: Date
    
    public init(averageLevel: Float, peakLevel: Float, timestamp: Date = Date()) {
        self.averageLevel = averageLevel
        self.peakLevel = peakLevel
        self.timestamp = timestamp
    }
    
    public var isAboveSilenceThreshold: Bool {
        averageLevel > -40.0 // Default silence threshold
    }
}

/// Audio buffer data for real-time processing
public struct AudioBuffer: Sendable {
    public let data: Data
    public let sampleCount: Int
    public let channelCount: Int
    public let sampleRate: Double
    public let timestamp: Date
    
    public init(
        data: Data,
        sampleCount: Int,
        channelCount: Int,
        sampleRate: Double,
        timestamp: Date = Date()
    ) {
        self.data = data
        self.sampleCount = sampleCount
        self.channelCount = channelCount
        self.sampleRate = sampleRate
        self.timestamp = timestamp
    }
}

/// Audio recording settings
public struct AudioRecordingSettings: Sendable {
    public let sampleRate: Double
    public let bitDepth: MicrophoneCapabilityConfiguration.AudioBitDepth
    public let channelCount: Int
    public let format: MicrophoneCapabilityConfiguration.AudioFormat
    public let quality: MicrophoneCapabilityConfiguration.AudioQuality
    public let enableMetering: Bool
    public let bufferSize: Int
    
    public init(
        sampleRate: Double = 44100.0,
        bitDepth: MicrophoneCapabilityConfiguration.AudioBitDepth = .depth16,
        channelCount: Int = 1,
        format: MicrophoneCapabilityConfiguration.AudioFormat = .m4a,
        quality: MicrophoneCapabilityConfiguration.AudioQuality = .high,
        enableMetering: Bool = true,
        bufferSize: Int = 1024
    ) {
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channelCount = channelCount
        self.format = format
        self.quality = quality
        self.enableMetering = enableMetering
        self.bufferSize = bufferSize
    }
    
    public var avAudioSettings: [String: Any] {
        var settings: [String: Any] = [:]
        
        // Sample rate
        settings[AVSampleRateKey] = sampleRate
        
        // Format
        switch format {
        case .pcm, .wav:
            settings[AVFormatIDKey] = kAudioFormatLinearPCM
        case .aac, .m4a:
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
        case .mp3:
            settings[AVFormatIDKey] = kAudioFormatMPEGLayer3
        case .caf:
            settings[AVFormatIDKey] = kAudioFormatAppleLossless
        }
        
        // Channels
        settings[AVNumberOfChannelsKey] = channelCount
        
        // Bit depth (for PCM)
        if format == .pcm || format == .wav {
            settings[AVLinearPCMBitDepthKey] = bitDepth.rawValue
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
        }
        
        // Quality
        switch quality {
        case .low:
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.low.rawValue
        case .medium:
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.medium.rawValue
        case .high:
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue
        case .lossless:
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.max.rawValue
        }
        
        return settings
    }
}

/// Microphone metrics
public struct MicrophoneMetrics: Sendable {
    public let recordingsStarted: Int
    public let recordingsCompleted: Int
    public let recordingsFailed: Int
    public let totalRecordingTime: TimeInterval
    public let averageRecordingDuration: TimeInterval
    public let averageFileSize: Int64
    public let averageAudioLevel: Float
    public let peakAudioLevel: Float
    public let silenceDetectedCount: Int
    public let speechDetectedCount: Int
    public let sessionCount: Int
    public let interruptionCount: Int
    public let errorCount: Int
    
    public init(
        recordingsStarted: Int = 0,
        recordingsCompleted: Int = 0,
        recordingsFailed: Int = 0,
        totalRecordingTime: TimeInterval = 0,
        averageRecordingDuration: TimeInterval = 0,
        averageFileSize: Int64 = 0,
        averageAudioLevel: Float = 0,
        peakAudioLevel: Float = 0,
        silenceDetectedCount: Int = 0,
        speechDetectedCount: Int = 0,
        sessionCount: Int = 0,
        interruptionCount: Int = 0,
        errorCount: Int = 0
    ) {
        self.recordingsStarted = recordingsStarted
        self.recordingsCompleted = recordingsCompleted
        self.recordingsFailed = recordingsFailed
        self.totalRecordingTime = totalRecordingTime
        self.averageRecordingDuration = averageRecordingDuration
        self.averageFileSize = averageFileSize
        self.averageAudioLevel = averageAudioLevel
        self.peakAudioLevel = peakAudioLevel
        self.silenceDetectedCount = silenceDetectedCount
        self.speechDetectedCount = speechDetectedCount
        self.sessionCount = sessionCount
        self.interruptionCount = interruptionCount
        self.errorCount = errorCount
    }
    
    public var successRate: Double {
        guard recordingsStarted > 0 else { return 0.0 }
        return Double(recordingsCompleted) / Double(recordingsStarted)
    }
}

// MARK: - Microphone Resource

/// Microphone resource management
public actor MicrophoneCapabilityResource: AxiomCapabilityResource {
    private let configuration: MicrophoneCapabilityConfiguration
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var currentRecordingURL: URL?
    private var recordingState: AudioRecordingState = .stopped
    private var recordingStartTime: Date?
    private var audioLevels: [Float] = []
    private var currentAudioLevel: AudioLevel?
    private var metrics: MicrophoneMetrics = MicrophoneMetrics()
    private var recordingDurations: [TimeInterval] = []
    private var fileSizes: [Int64] = []
    private var audioLevelsContinuation: AsyncStream<AudioLevel>.Continuation?
    private var audioBufferContinuation: AsyncStream<AudioBuffer>.Continuation?
    
    public init(configuration: MicrophoneCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 50_000_000, // 50MB for audio buffers
            cpu: 20.0, // 20% CPU for audio processing
            bandwidth: 0, // No network bandwidth
            storage: 100_000_000 // 100MB for audio storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let isRecording = recordingState == .recording
            let memoryUsage = isRecording ? 25_000_000 : 5_000_000
            let cpuUsage = isRecording ? 15.0 : 1.0
            
            return ResourceUsage(
                memory: memoryUsage,
                cpu: cpuUsage,
                bandwidth: 0,
                storage: 0 // Dynamic based on recording
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        await getAuthorizationStatus() == .granted
    }
    
    public func release() async {
        await stopRecording()
        audioRecorder = nil
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        currentRecordingURL = nil
        recordingState = .stopped
        recordingStartTime = nil
        audioLevelsContinuation?.finish()
        audioBufferContinuation?.finish()
        audioLevelsContinuation = nil
        audioBufferContinuation = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        try await setupAudioSession()
        if configuration.enableRealtimeProcessing {
            try await setupAudioEngine()
        }
    }
    
    internal func updateConfiguration(_ configuration: MicrophoneCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Authorization
    
    public func getAuthorizationStatus() async -> MicrophoneAuthorizationStatus {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .undetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .granted:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }
    
    public func requestPermission() async throws -> MicrophoneAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted ? .granted : .denied)
            }
        }
    }
    
    // MARK: - Recording Operations
    
    public func startRecording(
        settings: AudioRecordingSettings? = nil,
        outputURL: URL? = nil
    ) async throws -> URL {
        guard await isAvailable() else {
            throw MicrophoneError.permissionDenied
        }
        
        guard recordingState == .stopped else {
            throw MicrophoneError.recordingInProgress
        }
        
        let recordingSettings = settings ?? defaultRecordingSettings()
        let url = outputURL ?? try generateOutputURL()
        
        // Setup audio recorder
        try await setupAudioRecorder(url: url, settings: recordingSettings)
        
        // Start recording
        guard let recorder = audioRecorder, recorder.record() else {
            throw MicrophoneError.recordingStartFailed
        }
        
        recordingState = .recording
        recordingStartTime = Date()
        currentRecordingURL = url
        
        await updateMetrics(recordingStarted: true)
        
        return url
    }
    
    public func stopRecording() async throws -> AudioRecordingResult? {
        guard recordingState == .recording else {
            return nil
        }
        
        guard let recorder = audioRecorder else {
            throw MicrophoneError.recorderNotConfigured
        }
        
        recorder.stop()
        recordingState = .stopped
        
        guard let url = currentRecordingURL,
              let startTime = recordingStartTime else {
            throw MicrophoneError.recordingDataNotAvailable
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let fileSize = try getFileSize(at: url)
        
        let result = AudioRecordingResult(
            audioURL: url,
            duration: duration,
            format: configuration.defaultFormat,
            sampleRate: configuration.defaultSampleRate,
            channelCount: configuration.defaultChannelCount,
            bitDepth: configuration.defaultBitDepth,
            fileSize: fileSize,
            averageLevel: audioLevels.reduce(0, +) / Float(max(audioLevels.count, 1)),
            peakLevel: audioLevels.max() ?? 0,
            recordingDate: startTime
        )
        
        // Reset state
        currentRecordingURL = nil
        recordingStartTime = nil
        audioLevels.removeAll()
        
        await updateMetrics(recordingCompleted: true, duration: duration, fileSize: fileSize)
        
        return result
    }
    
    public func pauseRecording() async throws {
        guard recordingState == .recording else {
            throw MicrophoneError.notRecording
        }
        
        audioRecorder?.pause()
        recordingState = .paused
    }
    
    public func resumeRecording() async throws {
        guard recordingState == .paused else {
            throw MicrophoneError.notPaused
        }
        
        guard let recorder = audioRecorder, recorder.record() else {
            throw MicrophoneError.recordingStartFailed
        }
        
        recordingState = .recording
    }
    
    public func getRecordingState() -> AudioRecordingState {
        recordingState
    }
    
    public func getRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    public func isCurrentlyRecording() -> Bool {
        recordingState == .recording
    }
    
    // MARK: - Audio Level Monitoring
    
    public func startAudioLevelMonitoring() -> AsyncStream<AudioLevel> {
        AsyncStream { continuation in
            audioLevelsContinuation = continuation
            
            if configuration.enableMetering {
                setupLevelMonitoring()
            }
        }
    }
    
    public func stopAudioLevelMonitoring() {
        audioLevelsContinuation?.finish()
        audioLevelsContinuation = nil
    }
    
    public func getCurrentAudioLevel() -> AudioLevel? {
        currentAudioLevel
    }
    
    // MARK: - Real-time Audio Processing
    
    public func startAudioBufferStream() -> AsyncStream<AudioBuffer> {
        AsyncStream { continuation in
            audioBufferContinuation = continuation
            
            if configuration.enableRealtimeProcessing {
                Task {
                    await startRealtimeAudioProcessing()
                }
            }
        }
    }
    
    public func stopAudioBufferStream() {
        audioBufferContinuation?.finish()
        audioBufferContinuation = nil
        audioEngine?.stop()
    }
    
    // MARK: - Audio Processing
    
    public func processAudioFile(
        url: URL,
        processingOptions: AudioProcessingOptions
    ) async throws -> URL {
        // Process audio file with noise reduction, etc.
        let outputURL = try generateProcessedOutputURL()
        
        // Implementation would use AVAudioEngine for processing
        try await performAudioProcessing(
            inputURL: url,
            outputURL: outputURL,
            options: processingOptions
        )
        
        return outputURL
    }
    
    public func analyzeAudioFile(url: URL) async throws -> AudioAnalysisResult {
        // Analyze audio file for speech detection, etc.
        let analysis = try await performAudioAnalysis(url: url)
        return analysis
    }
    
    public func getMetrics() -> MicrophoneMetrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func setupAudioSession() async throws {
        guard configuration.enableAudioSessionManagement else { return }
        
        let session = AVAudioSession.sharedInstance()
        
        let category: AVAudioSession.Category
        switch configuration.audioSessionCategory {
        case .ambient:
            category = .ambient
        case .soloAmbient:
            category = .soloAmbient
        case .playback:
            category = .playback
        case .record:
            category = .record
        case .playAndRecord:
            category = .playAndRecord
        case .multiRoute:
            category = .multiRoute
        }
        
        let mode: AVAudioSession.Mode
        switch configuration.audioSessionMode {
        case .default:
            mode = .default
        case .voiceChat:
            mode = .voiceChat
        case .measurement:
            mode = .measurement
        case .moviePlayback:
            mode = .moviePlayback
        case .videoRecording:
            mode = .videoRecording
        case .gameChat:
            mode = .gameChat
        case .videoChat:
            mode = .videoChat
        case .spokenAudio:
            mode = .spokenAudio
        }
        
        var options: AVAudioSession.CategoryOptions = []
        if configuration.enableEchoCancellation {
            options.insert(.defaultToSpeaker)
        }
        if configuration.enableBackgroundRecording {
            options.insert(.mixWithOthers)
        }
        
        try session.setCategory(category, mode: mode, options: options)
        try session.setActive(true)
        
        await updateMetrics(sessionStarted: true)
    }
    
    private func setupAudioEngine() async throws {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        inputNode = engine.inputNode
        
        // Setup audio processing chain
        let format = inputNode?.inputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: AVAudioFrameCount(configuration.bufferSize), format: format) { [weak self] buffer, time in
            Task { [weak self] in
                await self?.processAudioBuffer(buffer, time: time)
            }
        }
        
        try engine.start()
    }
    
    private func setupAudioRecorder(url: URL, settings: AudioRecordingSettings) async throws {
        audioRecorder = try AVAudioRecorder(url: url, settings: settings.avAudioSettings)
        
        guard let recorder = audioRecorder else {
            throw MicrophoneError.recorderInitializationFailed
        }
        
        recorder.isMeteringEnabled = configuration.enableMetering
        recorder.prepareToRecord()
    }
    
    private func defaultRecordingSettings() -> AudioRecordingSettings {
        AudioRecordingSettings(
            sampleRate: configuration.defaultSampleRate,
            bitDepth: configuration.defaultBitDepth,
            channelCount: configuration.defaultChannelCount,
            format: configuration.defaultFormat,
            quality: configuration.audioQuality,
            enableMetering: configuration.enableMetering,
            bufferSize: configuration.bufferSize
        )
    }
    
    private func generateOutputURL() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "audio_\(Date().timeIntervalSince1970).\(configuration.defaultFormat.rawValue)"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func generateProcessedOutputURL() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "processed_audio_\(Date().timeIntervalSince1970).\(configuration.defaultFormat.rawValue)"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    private func setupLevelMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { [weak self] in
                await self?.updateAudioLevels()
            }
        }
    }
    
    private func updateAudioLevels() async {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        let averageLevel = recorder.averagePower(forChannel: 0)
        let peakLevel = recorder.peakPower(forChannel: 0)
        
        audioLevels.append(averageLevel)
        
        let level = AudioLevel(averageLevel: averageLevel, peakLevel: peakLevel)
        currentAudioLevel = level
        
        audioLevelsContinuation?.yield(level)
        
        // Voice activity detection
        if configuration.enableVoiceActivityDetection {
            if averageLevel > configuration.silenceThreshold {
                await updateMetrics(speechDetected: true)
            } else {
                await updateMetrics(silenceDetected: true)
            }
        }
    }
    
    private func startRealtimeAudioProcessing() async {
        // Real-time audio processing implementation
        // This would process audio buffers in real-time
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) async {
        guard let audioBufferContinuation = audioBufferContinuation else { return }
        
        // Convert AVAudioPCMBuffer to AudioBuffer
        guard let data = buffer.floatChannelData else { return }
        
        let sampleCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        let sampleRate = buffer.format.sampleRate
        
        // Convert float data to Data
        let dataSize = sampleCount * channelCount * MemoryLayout<Float>.size
        let audioData = Data(bytes: data[0], count: dataSize)
        
        let audioBuffer = AudioBuffer(
            data: audioData,
            sampleCount: sampleCount,
            channelCount: channelCount,
            sampleRate: sampleRate
        )
        
        audioBufferContinuation.yield(audioBuffer)
    }
    
    private func performAudioProcessing(
        inputURL: URL,
        outputURL: URL,
        options: AudioProcessingOptions
    ) async throws {
        // Implementation for audio processing (noise reduction, etc.)
        // This would use AVAudioEngine and various audio units
    }
    
    private func performAudioAnalysis(url: URL) async throws -> AudioAnalysisResult {
        // Implementation for audio analysis
        // This would analyze the audio file and return results
        return AudioAnalysisResult(
            duration: 0,
            speechPercentage: 0,
            averageLevel: 0,
            peakLevel: 0,
            hasVoice: false
        )
    }
    
    private func updateMetrics(
        recordingStarted: Bool = false,
        recordingCompleted: Bool = false,
        recordingFailed: Bool = false,
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        speechDetected: Bool = false,
        silenceDetected: Bool = false,
        sessionStarted: Bool = false,
        interrupted: Bool = false,
        error: Bool = false
    ) async {
        
        if recordingStarted {
            metrics = MicrophoneMetrics(
                recordingsStarted: metrics.recordingsStarted + 1,
                recordingsCompleted: metrics.recordingsCompleted,
                recordingsFailed: metrics.recordingsFailed,
                totalRecordingTime: metrics.totalRecordingTime,
                averageRecordingDuration: metrics.averageRecordingDuration,
                averageFileSize: metrics.averageFileSize,
                averageAudioLevel: metrics.averageAudioLevel,
                peakAudioLevel: metrics.peakAudioLevel,
                silenceDetectedCount: metrics.silenceDetectedCount,
                speechDetectedCount: metrics.speechDetectedCount,
                sessionCount: metrics.sessionCount,
                interruptionCount: metrics.interruptionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if recordingCompleted {
            recordingDurations.append(duration)
            fileSizes.append(fileSize)
            
            let avgDuration = recordingDurations.reduce(0, +) / Double(recordingDurations.count)
            let avgFileSize = fileSizes.reduce(0, +) / Int64(fileSizes.count)
            
            metrics = MicrophoneMetrics(
                recordingsStarted: metrics.recordingsStarted,
                recordingsCompleted: metrics.recordingsCompleted + 1,
                recordingsFailed: metrics.recordingsFailed,
                totalRecordingTime: metrics.totalRecordingTime + duration,
                averageRecordingDuration: avgDuration,
                averageFileSize: avgFileSize,
                averageAudioLevel: metrics.averageAudioLevel,
                peakAudioLevel: metrics.peakAudioLevel,
                silenceDetectedCount: metrics.silenceDetectedCount,
                speechDetectedCount: metrics.speechDetectedCount,
                sessionCount: metrics.sessionCount,
                interruptionCount: metrics.interruptionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if speechDetected {
            metrics = MicrophoneMetrics(
                recordingsStarted: metrics.recordingsStarted,
                recordingsCompleted: metrics.recordingsCompleted,
                recordingsFailed: metrics.recordingsFailed,
                totalRecordingTime: metrics.totalRecordingTime,
                averageRecordingDuration: metrics.averageRecordingDuration,
                averageFileSize: metrics.averageFileSize,
                averageAudioLevel: metrics.averageAudioLevel,
                peakAudioLevel: metrics.peakAudioLevel,
                silenceDetectedCount: metrics.silenceDetectedCount,
                speechDetectedCount: metrics.speechDetectedCount + 1,
                sessionCount: metrics.sessionCount,
                interruptionCount: metrics.interruptionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if sessionStarted {
            metrics = MicrophoneMetrics(
                recordingsStarted: metrics.recordingsStarted,
                recordingsCompleted: metrics.recordingsCompleted,
                recordingsFailed: metrics.recordingsFailed,
                totalRecordingTime: metrics.totalRecordingTime,
                averageRecordingDuration: metrics.averageRecordingDuration,
                averageFileSize: metrics.averageFileSize,
                averageAudioLevel: metrics.averageAudioLevel,
                peakAudioLevel: metrics.peakAudioLevel,
                silenceDetectedCount: metrics.silenceDetectedCount,
                speechDetectedCount: metrics.speechDetectedCount,
                sessionCount: metrics.sessionCount + 1,
                interruptionCount: metrics.interruptionCount,
                errorCount: metrics.errorCount
            )
        }
    }
}

// MARK: - Additional Types

/// Audio processing options
public struct AudioProcessingOptions: Sendable {
    public let enableNoiseReduction: Bool
    public let enableEchoCancellation: Bool
    public let enableAutomaticGainControl: Bool
    public let normalizeAudio: Bool
    
    public init(
        enableNoiseReduction: Bool = true,
        enableEchoCancellation: Bool = true,
        enableAutomaticGainControl: Bool = true,
        normalizeAudio: Bool = false
    ) {
        self.enableNoiseReduction = enableNoiseReduction
        self.enableEchoCancellation = enableEchoCancellation
        self.enableAutomaticGainControl = enableAutomaticGainControl
        self.normalizeAudio = normalizeAudio
    }
}

/// Audio analysis result
public struct AudioAnalysisResult: Sendable {
    public let duration: TimeInterval
    public let speechPercentage: Float
    public let averageLevel: Float
    public let peakLevel: Float
    public let hasVoice: Bool
    
    public init(
        duration: TimeInterval,
        speechPercentage: Float,
        averageLevel: Float,
        peakLevel: Float,
        hasVoice: Bool
    ) {
        self.duration = duration
        self.speechPercentage = speechPercentage
        self.averageLevel = averageLevel
        self.peakLevel = peakLevel
        self.hasVoice = hasVoice
    }
}

// MARK: - Microphone Capability Implementation

/// Microphone capability providing audio recording and processing
public actor MicrophoneCapability: DomainCapability {
    public typealias ConfigurationType = MicrophoneCapabilityConfiguration
    public typealias ResourceType = MicrophoneCapabilityResource
    
    private var _configuration: MicrophoneCapabilityConfiguration
    private var _resources: MicrophoneCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "microphone-capability" }
    
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
    
    public var configuration: MicrophoneCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: MicrophoneCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: MicrophoneCapabilityConfiguration = MicrophoneCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = MicrophoneCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: MicrophoneCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Microphone configuration")
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
        // Check if device has microphone
        let session = AVAudioSession.sharedInstance()
        return session.isInputAvailable
    }
    
    public func requestPermission() async throws {
        let status = try await _resources.requestPermission()
        guard status == .granted else {
            throw MicrophoneError.permissionDenied
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Recording Operations
    
    /// Start audio recording
    public func startRecording(
        settings: AudioRecordingSettings? = nil,
        outputURL: URL? = nil
    ) async throws -> URL {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        return try await _resources.startRecording(settings: settings, outputURL: outputURL)
    }
    
    /// Stop audio recording
    public func stopRecording() async throws -> AudioRecordingResult? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        return try await _resources.stopRecording()
    }
    
    /// Pause audio recording
    public func pauseRecording() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        try await _resources.pauseRecording()
    }
    
    /// Resume audio recording
    public func resumeRecording() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        try await _resources.resumeRecording()
    }
    
    /// Get current recording state
    public func getRecordingState() async -> AudioRecordingState {
        await _resources.getRecordingState()
    }
    
    /// Get current recording duration
    public func getRecordingDuration() async -> TimeInterval {
        await _resources.getRecordingDuration()
    }
    
    /// Check if currently recording
    public func isCurrentlyRecording() async -> Bool {
        await _resources.isCurrentlyRecording()
    }
    
    // MARK: - Audio Level Monitoring
    
    /// Start monitoring audio levels
    public func startAudioLevelMonitoring() async -> AsyncStream<AudioLevel> {
        await _resources.startAudioLevelMonitoring()
    }
    
    /// Stop monitoring audio levels
    public func stopAudioLevelMonitoring() async {
        await _resources.stopAudioLevelMonitoring()
    }
    
    /// Get current audio level
    public func getCurrentAudioLevel() async -> AudioLevel? {
        await _resources.getCurrentAudioLevel()
    }
    
    // MARK: - Real-time Audio Processing
    
    /// Start real-time audio buffer stream
    public func startAudioBufferStream() async -> AsyncStream<AudioBuffer> {
        await _resources.startAudioBufferStream()
    }
    
    /// Stop real-time audio buffer stream
    public func stopAudioBufferStream() async {
        await _resources.stopAudioBufferStream()
    }
    
    // MARK: - Audio Processing
    
    /// Process audio file with various enhancements
    public func processAudioFile(
        url: URL,
        processingOptions: AudioProcessingOptions = AudioProcessingOptions()
    ) async throws -> URL {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        return try await _resources.processAudioFile(url: url, processingOptions: processingOptions)
    }
    
    /// Analyze audio file for speech detection and other metrics
    public func analyzeAudioFile(url: URL) async throws -> AudioAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Microphone capability not available")
        }
        
        return try await _resources.analyzeAudioFile(url: url)
    }
    
    /// Get microphone metrics
    public func getMetrics() async -> MicrophoneMetrics {
        await _resources.getMetrics()
    }
    
    /// Get authorization status
    public func getAuthorizationStatus() async -> MicrophoneAuthorizationStatus {
        await _resources.getAuthorizationStatus()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Microphone specific errors
public enum MicrophoneError: Error, LocalizedError {
    case permissionDenied
    case microphoneNotAvailable
    case recorderNotConfigured
    case recorderInitializationFailed
    case recordingStartFailed
    case recordingInProgress
    case notRecording
    case notPaused
    case recordingDataNotAvailable
    case audioSessionConfigurationFailed
    case audioEngineSetupFailed
    case audioProcessingFailed(Error)
    case fileProcessingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .microphoneNotAvailable:
            return "Microphone not available"
        case .recorderNotConfigured:
            return "Audio recorder not configured"
        case .recorderInitializationFailed:
            return "Failed to initialize audio recorder"
        case .recordingStartFailed:
            return "Failed to start recording"
        case .recordingInProgress:
            return "Recording already in progress"
        case .notRecording:
            return "Not currently recording"
        case .notPaused:
            return "Recording is not paused"
        case .recordingDataNotAvailable:
            return "Recording data not available"
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .audioEngineSetupFailed:
            return "Failed to setup audio engine"
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
        case .fileProcessingFailed(let error):
            return "File processing failed: \(error.localizedDescription)"
        }
    }
}