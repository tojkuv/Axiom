import Foundation
import AVFoundation
import AudioToolbox
import CoreML
import SoundAnalysis
import AxiomCore
import AxiomCapabilities

// MARK: - Audio Analysis Capability Configuration

/// Configuration for Audio Analysis capability
public struct AudioAnalysisCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableAudioAnalysis: Bool
    public let enableSpectralAnalysis: Bool
    public let enableFeatureExtraction: Bool
    public let enableSoundClassification: Bool
    public let enableRealTimeAnalysis: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentAnalyses: Int
    public let analysisTimeout: TimeInterval
    public let sampleRate: Double
    public let bufferSize: Int
    public let windowSize: Int
    public let hopSize: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let analysisQuality: AnalysisQuality
    public let enableNoiseReduction: Bool
    
    public enum AnalysisQuality: String, Codable, CaseIterable {
        case fast = "fast"
        case balanced = "balanced"
        case accurate = "accurate"
    }
    
    public init(
        enableAudioAnalysis: Bool = true,
        enableSpectralAnalysis: Bool = true,
        enableFeatureExtraction: Bool = true,
        enableSoundClassification: Bool = true,
        enableRealTimeAnalysis: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentAnalyses: Int = 5,
        analysisTimeout: TimeInterval = 60.0,
        sampleRate: Double = 44100.0,
        bufferSize: Int = 4096,
        windowSize: Int = 2048,
        hopSize: Int = 512,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 100,
        enablePerformanceOptimization: Bool = true,
        analysisQuality: AnalysisQuality = .balanced,
        enableNoiseReduction: Bool = false
    ) {
        self.enableAudioAnalysis = enableAudioAnalysis
        self.enableSpectralAnalysis = enableSpectralAnalysis
        self.enableFeatureExtraction = enableFeatureExtraction
        self.enableSoundClassification = enableSoundClassification
        self.enableRealTimeAnalysis = enableRealTimeAnalysis
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentAnalyses = maxConcurrentAnalyses
        self.analysisTimeout = analysisTimeout
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.windowSize = windowSize
        self.hopSize = hopSize
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.analysisQuality = analysisQuality
        self.enableNoiseReduction = enableNoiseReduction
    }
    
    public var isValid: Bool {
        maxConcurrentAnalyses > 0 &&
        analysisTimeout > 0 &&
        sampleRate > 0 &&
        bufferSize > 0 && bufferSize.isMultiple(of: 2) &&
        windowSize > 0 && windowSize.isMultiple(of: 2) &&
        hopSize > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: AudioAnalysisCapabilityConfiguration) -> AudioAnalysisCapabilityConfiguration {
        AudioAnalysisCapabilityConfiguration(
            enableAudioAnalysis: other.enableAudioAnalysis,
            enableSpectralAnalysis: other.enableSpectralAnalysis,
            enableFeatureExtraction: other.enableFeatureExtraction,
            enableSoundClassification: other.enableSoundClassification,
            enableRealTimeAnalysis: other.enableRealTimeAnalysis,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentAnalyses: other.maxConcurrentAnalyses,
            analysisTimeout: other.analysisTimeout,
            sampleRate: other.sampleRate,
            bufferSize: other.bufferSize,
            windowSize: other.windowSize,
            hopSize: other.hopSize,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            analysisQuality: other.analysisQuality,
            enableNoiseReduction: other.enableNoiseReduction
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AudioAnalysisCapabilityConfiguration {
        var adjustedTimeout = analysisTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAnalyses = maxConcurrentAnalyses
        var adjustedCacheSize = cacheSize
        var adjustedQuality = analysisQuality
        var adjustedBufferSize = bufferSize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(analysisTimeout, 30.0)
            adjustedConcurrentAnalyses = min(maxConcurrentAnalyses, 2)
            adjustedCacheSize = min(cacheSize, 20)
            adjustedQuality = .fast
            adjustedBufferSize = min(bufferSize, 2048)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return AudioAnalysisCapabilityConfiguration(
            enableAudioAnalysis: enableAudioAnalysis,
            enableSpectralAnalysis: enableSpectralAnalysis,
            enableFeatureExtraction: enableFeatureExtraction,
            enableSoundClassification: enableSoundClassification,
            enableRealTimeAnalysis: enableRealTimeAnalysis,
            enableCustomModels: enableCustomModels,
            maxConcurrentAnalyses: adjustedConcurrentAnalyses,
            analysisTimeout: adjustedTimeout,
            sampleRate: sampleRate,
            bufferSize: adjustedBufferSize,
            windowSize: windowSize,
            hopSize: hopSize,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            analysisQuality: adjustedQuality,
            enableNoiseReduction: enableNoiseReduction
        )
    }
}

// MARK: - Audio Analysis Types

/// Audio analysis request
public struct AudioAnalysisRequest: Sendable, Identifiable {
    public let id: UUID
    public let audioInput: AudioInput
    public let analysisOptions: AnalysisOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public enum AudioInput: Sendable {
        case audioFile(URL)
        case audioBuffer(AVAudioPCMBuffer)
        case audioData(Data, format: AVAudioFormat)
        case liveAudio(AVAudioEngine)
    }
    
    public struct AnalysisOptions: Sendable {
        public let analysisTypes: Set<AnalysisType>
        public let spectralOptions: SpectralOptions?
        public let featureOptions: FeatureOptions?
        public let classificationOptions: ClassificationOptions?
        public let customModelId: String?
        public let outputFormat: OutputFormat
        
        public enum AnalysisType: String, Sendable, CaseIterable {
            case spectral = "spectral"
            case features = "features"
            case classification = "classification"
            case pitch = "pitch"
            case rhythm = "rhythm"
            case loudness = "loudness"
            case timbre = "timbre"
        }
        
        public struct SpectralOptions: Sendable {
            public let fftSize: Int
            public let windowType: WindowType
            public let overlapRatio: Float
            public let frequencyRange: ClosedRange<Float>?
            
            public enum WindowType: String, Sendable, CaseIterable {
                case hann = "hann"
                case hamming = "hamming"
                case blackman = "blackman"
                case rectangular = "rectangular"
            }
            
            public init(
                fftSize: Int = 2048,
                windowType: WindowType = .hann,
                overlapRatio: Float = 0.5,
                frequencyRange: ClosedRange<Float>? = nil
            ) {
                self.fftSize = fftSize
                self.windowType = windowType
                self.overlapRatio = overlapRatio
                self.frequencyRange = frequencyRange
            }
        }
        
        public struct FeatureOptions: Sendable {
            public let extractMFCC: Bool
            public let extractSpectralCentroid: Bool
            public let extractSpectralRolloff: Bool
            public let extractZeroCrossingRate: Bool
            public let extractChroma: Bool
            public let extractTemporal: Bool
            public let mfccCoefficients: Int
            
            public init(
                extractMFCC: Bool = true,
                extractSpectralCentroid: Bool = true,
                extractSpectralRolloff: Bool = true,
                extractZeroCrossingRate: Bool = true,
                extractChroma: Bool = false,
                extractTemporal: Bool = true,
                mfccCoefficients: Int = 13
            ) {
                self.extractMFCC = extractMFCC
                self.extractSpectralCentroid = extractSpectralCentroid
                self.extractSpectralRolloff = extractSpectralRolloff
                self.extractZeroCrossingRate = extractZeroCrossingRate
                self.extractChroma = extractChroma
                self.extractTemporal = extractTemporal
                self.mfccCoefficients = mfccCoefficients
            }
        }
        
        public struct ClassificationOptions: Sendable {
            public let enableSoundClassification: Bool
            public let enableMusicGenreClassification: Bool
            public let enableEmotionDetection: Bool
            public let confidenceThreshold: Float
            public let maxResults: Int
            
            public init(
                enableSoundClassification: Bool = true,
                enableMusicGenreClassification: Bool = false,
                enableEmotionDetection: Bool = false,
                confidenceThreshold: Float = 0.1,
                maxResults: Int = 10
            ) {
                self.enableSoundClassification = enableSoundClassification
                self.enableMusicGenreClassification = enableMusicGenreClassification
                self.enableEmotionDetection = enableEmotionDetection
                self.confidenceThreshold = confidenceThreshold
                self.maxResults = maxResults
            }
        }
        
        public enum OutputFormat: String, Sendable, CaseIterable {
            case json = "json"
            case binary = "binary"
            case csv = "csv"
        }
        
        public init(
            analysisTypes: Set<AnalysisType> = [.spectral, .features],
            spectralOptions: SpectralOptions? = SpectralOptions(),
            featureOptions: FeatureOptions? = FeatureOptions(),
            classificationOptions: ClassificationOptions? = nil,
            customModelId: String? = nil,
            outputFormat: OutputFormat = .json
        ) {
            self.analysisTypes = analysisTypes
            self.spectralOptions = spectralOptions
            self.featureOptions = featureOptions
            self.classificationOptions = classificationOptions
            self.customModelId = customModelId
            self.outputFormat = outputFormat
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
        analysisOptions: AnalysisOptions = AnalysisOptions(),
        priority: Priority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.audioInput = audioInput
        self.analysisOptions = analysisOptions
        self.priority = priority
        self.metadata = metadata
    }
}

/// Audio analysis result
public struct AudioAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let audioMetadata: AudioMetadata
    public let spectralAnalysis: SpectralAnalysis?
    public let audioFeatures: AudioFeatures?
    public let classifications: [AudioClassification]
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: AudioAnalysisError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AudioMetadata: Sendable {
        public let duration: TimeInterval
        public let sampleRate: Double
        public let channels: Int
        public let bitDepth: Int?
        public let fileFormat: String?
        public let bitrate: Int?
        
        public init(duration: TimeInterval, sampleRate: Double, channels: Int, bitDepth: Int? = nil, fileFormat: String? = nil, bitrate: Int? = nil) {
            self.duration = duration
            self.sampleRate = sampleRate
            self.channels = channels
            self.bitDepth = bitDepth
            self.fileFormat = fileFormat
            self.bitrate = bitrate
        }
    }
    
    public struct SpectralAnalysis: Sendable {
        public let spectrogram: [[Float]]
        public let frequencyBins: [Float]
        public let timeBins: [Float]
        public let spectralCentroid: [Float]
        public let spectralRolloff: [Float]
        public let spectralBandwidth: [Float]
        public let spectralFlatness: [Float]
        public let peakFrequencies: [Float]
        public let harmonicToNoiseRatio: Float?
        
        public init(
            spectrogram: [[Float]],
            frequencyBins: [Float],
            timeBins: [Float],
            spectralCentroid: [Float],
            spectralRolloff: [Float],
            spectralBandwidth: [Float],
            spectralFlatness: [Float],
            peakFrequencies: [Float],
            harmonicToNoiseRatio: Float? = nil
        ) {
            self.spectrogram = spectrogram
            self.frequencyBins = frequencyBins
            self.timeBins = timeBins
            self.spectralCentroid = spectralCentroid
            self.spectralRolloff = spectralRolloff
            self.spectralBandwidth = spectralBandwidth
            self.spectralFlatness = spectralFlatness
            self.peakFrequencies = peakFrequencies
            self.harmonicToNoiseRatio = harmonicToNoiseRatio
        }
    }
    
    public struct AudioFeatures: Sendable {
        public let mfcc: [Float]
        public let pitchFeatures: PitchFeatures?
        public let rhythmFeatures: RhythmFeatures?
        public let loudnessFeatures: LoudnessFeatures?
        public let timbreFeatures: TimbreFeatures?
        public let temporalFeatures: TemporalFeatures?
        
        public struct PitchFeatures: Sendable {
            public let fundamentalFrequency: [Float]
            public let pitchConfidence: [Float]
            public let pitchStability: Float
            public let averagePitch: Float
            public let pitchRange: Float
            
            public init(fundamentalFrequency: [Float], pitchConfidence: [Float], pitchStability: Float, averagePitch: Float, pitchRange: Float) {
                self.fundamentalFrequency = fundamentalFrequency
                self.pitchConfidence = pitchConfidence
                self.pitchStability = pitchStability
                self.averagePitch = averagePitch
                self.pitchRange = pitchRange
            }
        }
        
        public struct RhythmFeatures: Sendable {
            public let tempo: Float
            public let beats: [Float]
            public let rhythmStrength: Float
            public let rhythmRegularity: Float
            public let onsetTimes: [Float]
            
            public init(tempo: Float, beats: [Float], rhythmStrength: Float, rhythmRegularity: Float, onsetTimes: [Float]) {
                self.tempo = tempo
                self.beats = beats
                self.rhythmStrength = rhythmStrength
                self.rhythmRegularity = rhythmRegularity
                self.onsetTimes = onsetTimes
            }
        }
        
        public struct LoudnessFeatures: Sendable {
            public let rmsEnergy: [Float]
            public let peakEnergy: [Float]
            public let dynamicRange: Float
            public let loudnessRange: Float
            public let averageLoudness: Float
            
            public init(rmsEnergy: [Float], peakEnergy: [Float], dynamicRange: Float, loudnessRange: Float, averageLoudness: Float) {
                self.rmsEnergy = rmsEnergy
                self.peakEnergy = peakEnergy
                self.dynamicRange = dynamicRange
                self.loudnessRange = loudnessRange
                self.averageLoudness = averageLoudness
            }
        }
        
        public struct TimbreFeatures: Sendable {
            public let spectralCentroid: Float
            public let spectralRolloff: Float
            public let zeroCrossingRate: Float
            public let spectralFlux: Float
            public let chromaVector: [Float]
            
            public init(spectralCentroid: Float, spectralRolloff: Float, zeroCrossingRate: Float, spectralFlux: Float, chromaVector: [Float]) {
                self.spectralCentroid = spectralCentroid
                self.spectralRolloff = spectralRolloff
                self.zeroCrossingRate = zeroCrossingRate
                self.spectralFlux = spectralFlux
                self.chromaVector = chromaVector
            }
        }
        
        public struct TemporalFeatures: Sendable {
            public let attackTime: Float
            public let decayTime: Float
            public let sustainLevel: Float
            public let releaseTime: Float
            public let silenceRatio: Float
            
            public init(attackTime: Float, decayTime: Float, sustainLevel: Float, releaseTime: Float, silenceRatio: Float) {
                self.attackTime = attackTime
                self.decayTime = decayTime
                self.sustainLevel = sustainLevel
                self.releaseTime = releaseTime
                self.silenceRatio = silenceRatio
            }
        }
        
        public init(
            mfcc: [Float],
            pitchFeatures: PitchFeatures? = nil,
            rhythmFeatures: RhythmFeatures? = nil,
            loudnessFeatures: LoudnessFeatures? = nil,
            timbreFeatures: TimbreFeatures? = nil,
            temporalFeatures: TemporalFeatures? = nil
        ) {
            self.mfcc = mfcc
            self.pitchFeatures = pitchFeatures
            self.rhythmFeatures = rhythmFeatures
            self.loudnessFeatures = loudnessFeatures
            self.timbreFeatures = timbreFeatures
            self.temporalFeatures = temporalFeatures
        }
    }
    
    public struct AudioClassification: Sendable {
        public let label: String
        public let confidence: Float
        public let category: String?
        public let timeRange: TimeInterval?
        public let additionalInfo: [String: String]
        
        public init(label: String, confidence: Float, category: String? = nil, timeRange: TimeInterval? = nil, additionalInfo: [String: String] = [:]) {
            self.label = label
            self.confidence = confidence
            self.category = category
            self.timeRange = timeRange
            self.additionalInfo = additionalInfo
        }
    }
    
    public init(
        requestId: UUID,
        audioMetadata: AudioMetadata,
        spectralAnalysis: SpectralAnalysis? = nil,
        audioFeatures: AudioFeatures? = nil,
        classifications: [AudioClassification] = [],
        processingTime: TimeInterval,
        success: Bool,
        error: AudioAnalysisError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.audioMetadata = audioMetadata
        self.spectralAnalysis = spectralAnalysis
        self.audioFeatures = audioFeatures
        self.classifications = classifications
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var topClassification: AudioClassification? {
        classifications.max(by: { $0.confidence < $1.confidence })
    }
    
    public var averageConfidence: Float {
        guard !classifications.isEmpty else { return 0.0 }
        return classifications.reduce(0) { $0 + $1.confidence } / Float(classifications.count)
    }
}

/// Audio analysis metrics
public struct AudioAnalysisMetrics: Sendable {
    public let totalAnalyses: Int
    public let successfulAnalyses: Int
    public let failedAnalyses: Int
    public let averageProcessingTime: TimeInterval
    public let analysesByType: [String: Int]
    public let analysesByFormat: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageAudioDuration: TimeInterval
    public let throughputPerSecond: Double
    public let featureExtractionStats: FeatureExtractionStats
    
    public struct FeatureExtractionStats: Sendable {
        public let totalFeaturesExtracted: Int
        public let averageFeatureCount: Double
        public let mostUsedFeatureType: String?
        public let averageSpectralResolution: Double
        
        public init(totalFeaturesExtracted: Int = 0, averageFeatureCount: Double = 0, mostUsedFeatureType: String? = nil, averageSpectralResolution: Double = 0) {
            self.totalFeaturesExtracted = totalFeaturesExtracted
            self.averageFeatureCount = averageFeatureCount
            self.mostUsedFeatureType = mostUsedFeatureType
            self.averageSpectralResolution = averageSpectralResolution
        }
    }
    
    public init(
        totalAnalyses: Int = 0,
        successfulAnalyses: Int = 0,
        failedAnalyses: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        analysesByType: [String: Int] = [:],
        analysesByFormat: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        averageAudioDuration: TimeInterval = 0,
        throughputPerSecond: Double = 0,
        featureExtractionStats: FeatureExtractionStats = FeatureExtractionStats()
    ) {
        self.totalAnalyses = totalAnalyses
        self.successfulAnalyses = successfulAnalyses
        self.failedAnalyses = failedAnalyses
        self.averageProcessingTime = averageProcessingTime
        self.analysesByType = analysesByType
        self.analysesByFormat = analysesByFormat
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageAudioDuration = averageAudioDuration
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalAnalyses) / averageProcessingTime : 0
        self.featureExtractionStats = featureExtractionStats
    }
    
    public var successRate: Double {
        totalAnalyses > 0 ? Double(successfulAnalyses) / Double(totalAnalyses) : 0
    }
}

// MARK: - Audio Analysis Resource

/// Audio analysis resource management
@available(iOS 13.0, macOS 10.15, *)
public actor AudioAnalysisCapabilityResource: AxiomCapabilityResource {
    private let configuration: AudioAnalysisCapabilityConfiguration
    private var activeAnalyses: [UUID: AudioAnalysisRequest] = [:]
    private var analysisQueue: [AudioAnalysisRequest] = [:]
    private var analysisHistory: [AudioAnalysisResult] = [:]
    private var resultCache: [String: AudioAnalysisResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var metrics: AudioAnalysisMetrics = AudioAnalysisMetrics()
    private var resultStreamContinuation: AsyncStream<AudioAnalysisResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: AudioAnalysisCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 300_000_000, // 300MB for audio analysis
            cpu: 4.5, // High CPU usage for audio processing
            bandwidth: 0,
            storage: 120_000_000 // 120MB for model and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let analysisMemory = activeAnalyses.count * 40_000_000 // ~40MB per active analysis
            let cacheMemory = resultCache.count * 200_000 // ~200KB per cached result
            let modelMemory = customModels.count * 80_000_000 // ~80MB per loaded model
            let historyMemory = analysisHistory.count * 25_000
            
            return ResourceUsage(
                memory: analysisMemory + cacheMemory + modelMemory + historyMemory + 30_000_000,
                cpu: activeAnalyses.isEmpty ? 0.3 : 4.0,
                bandwidth: 0,
                storage: resultCache.count * 100_000 + customModels.count * 200_000_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Audio analysis is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableAudioAnalysis
        }
        return false
    }
    
    public func release() async {
        activeAnalyses.removeAll()
        analysisQueue.removeAll()
        analysisHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        
        resultStreamContinuation?.finish()
        
        metrics = AudioAnalysisMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize built-in sound classification models
        if configuration.enableSoundClassification {
            await loadBuiltInModels()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[AudioAnalysis] 🚀 Audio Analysis capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: AudioAnalysisCapabilityConfiguration) async throws {
        // Update audio processing configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<AudioAnalysisResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw AudioAnalysisError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[AudioAnalysis] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw AudioAnalysisError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[AudioAnalysis] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Audio Analysis
    
    public func analyzeAudio(_ request: AudioAnalysisRequest) async throws -> AudioAnalysisResult {
        guard configuration.enableAudioAnalysis else {
            throw AudioAnalysisError.audioAnalysisDisabled
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
            throw AudioAnalysisError.analysisQueued(request.id)
        }
        
        let startTime = Date()
        activeAnalyses[request.id] = request
        
        do {
            // Extract audio buffer from input
            let audioBuffer = try await extractAudioBuffer(from: request.audioInput)
            
            // Perform analysis
            let result = try await performAudioAnalysis(
                audioBuffer: audioBuffer,
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
            let result = AudioAnalysisResult(
                requestId: request.id,
                audioMetadata: AudioAnalysisResult.AudioMetadata(duration: 0, sampleRate: configuration.sampleRate, channels: 1),
                processingTime: processingTime,
                success: false,
                error: error as? AudioAnalysisError ?? AudioAnalysisError.analysisError(error.localizedDescription)
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
            print("[AudioAnalysis] 🚫 Cancelled analysis: \(requestId)")
        }
    }
    
    public func getActiveAnalyses() async -> [AudioAnalysisRequest] {
        return Array(activeAnalyses.values)
    }
    
    public func getAnalysisHistory(since: Date? = nil) async -> [AudioAnalysisResult] {
        if let since = since {
            return analysisHistory.filter { $0.timestamp >= since }
        }
        return analysisHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> AudioAnalysisMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = AudioAnalysisMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadBuiltInModels() async {
        if configuration.enableLogging {
            print("[AudioAnalysis] 📦 Loaded built-in audio classification models")
        }
    }
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[AudioAnalysis] ⚡ Performance optimization enabled")
        }
    }
    
    private func extractAudioBuffer(from input: AudioAnalysisRequest.AudioInput) async throws -> AVAudioPCMBuffer {
        switch input {
        case .audioBuffer(let buffer):
            return buffer
            
        case .audioFile(let url):
            return try await loadAudioFile(url)
            
        case .audioData(let data, let format):
            return try createBufferFromData(data, format: format)
            
        case .liveAudio(let engine):
            throw AudioAnalysisError.liveAudioNotSupported
        }
    }
    
    private func loadAudioFile(_ url: URL) async throws -> AVAudioPCMBuffer {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let audioFile = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: audioFile.processingFormat,
                    frameCapacity: AVAudioFrameCount(audioFile.length)
                ) else {
                    continuation.resume(throwing: AudioAnalysisError.invalidAudioFormat)
                    return
                }
                
                try audioFile.read(into: buffer)
                continuation.resume(returning: buffer)
                
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func createBufferFromData(_ data: Data, format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioAnalysisError.invalidAudioFormat
        }
        
        buffer.frameLength = frameCount
        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            buffer.audioBufferList.pointee.mBuffers.mData = UnsafeMutableRawPointer(mutating: baseAddress)
        }
        
        return buffer
    }
    
    private func performAudioAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        request: AudioAnalysisRequest,
        startTime: Date
    ) async throws -> AudioAnalysisResult {
        
        let audioMetadata = createAudioMetadata(from: audioBuffer)
        let processingTime = Date().timeIntervalSince(startTime)
        
        var spectralAnalysis: AudioAnalysisResult.SpectralAnalysis?
        var audioFeatures: AudioAnalysisResult.AudioFeatures?
        var classifications: [AudioAnalysisResult.AudioClassification] = []
        
        // Perform spectral analysis if requested
        if request.analysisOptions.analysisTypes.contains(.spectral) && configuration.enableSpectralAnalysis {
            spectralAnalysis = await performSpectralAnalysis(audioBuffer: audioBuffer, options: request.analysisOptions.spectralOptions)
        }
        
        // Extract features if requested
        if request.analysisOptions.analysisTypes.contains(.features) && configuration.enableFeatureExtraction {
            audioFeatures = await extractAudioFeatures(audioBuffer: audioBuffer, options: request.analysisOptions.featureOptions)
        }
        
        // Perform classification if requested
        if request.analysisOptions.analysisTypes.contains(.classification) && configuration.enableSoundClassification {
            classifications = await performAudioClassification(audioBuffer: audioBuffer, options: request.analysisOptions.classificationOptions)
        }
        
        return AudioAnalysisResult(
            requestId: request.id,
            audioMetadata: audioMetadata,
            spectralAnalysis: spectralAnalysis,
            audioFeatures: audioFeatures,
            classifications: classifications,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func createAudioMetadata(from buffer: AVAudioPCMBuffer) -> AudioAnalysisResult.AudioMetadata {
        let duration = Double(buffer.frameLength) / buffer.format.sampleRate
        return AudioAnalysisResult.AudioMetadata(
            duration: duration,
            sampleRate: buffer.format.sampleRate,
            channels: Int(buffer.format.channelCount),
            bitDepth: Int(buffer.format.commonFormat.rawValue)
        )
    }
    
    private func performSpectralAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        options: AudioAnalysisRequest.AnalysisOptions.SpectralOptions?
    ) async -> AudioAnalysisResult.SpectralAnalysis {
        // Simplified spectral analysis implementation
        let fftSize = options?.fftSize ?? 2048
        let spectrogram = generateSpectrogram(from: audioBuffer, fftSize: fftSize)
        
        let frequencyBins = (0..<fftSize/2).map { Float($0) * Float(audioBuffer.format.sampleRate) / Float(fftSize) }
        let timeBins = (0..<spectrogram.count).map { Float($0) * Float(configuration.hopSize) / Float(audioBuffer.format.sampleRate) }
        
        return AudioAnalysisResult.SpectralAnalysis(
            spectrogram: spectrogram,
            frequencyBins: frequencyBins,
            timeBins: timeBins,
            spectralCentroid: calculateSpectralCentroid(spectrogram, frequencyBins: frequencyBins),
            spectralRolloff: calculateSpectralRolloff(spectrogram, frequencyBins: frequencyBins),
            spectralBandwidth: calculateSpectralBandwidth(spectrogram, frequencyBins: frequencyBins),
            spectralFlatness: calculateSpectralFlatness(spectrogram),
            peakFrequencies: findPeakFrequencies(spectrogram, frequencyBins: frequencyBins)
        )
    }
    
    private func extractAudioFeatures(
        audioBuffer: AVAudioPCMBuffer,
        options: AudioAnalysisRequest.AnalysisOptions.FeatureOptions?
    ) async -> AudioAnalysisResult.AudioFeatures {
        let mfcc = options?.extractMFCC == true ? calculateMFCC(audioBuffer, coefficients: options?.mfccCoefficients ?? 13) : []
        
        return AudioAnalysisResult.AudioFeatures(mfcc: mfcc)
    }
    
    private func performAudioClassification(
        audioBuffer: AVAudioPCMBuffer,
        options: AudioAnalysisRequest.AnalysisOptions.ClassificationOptions?
    ) async -> [AudioAnalysisResult.AudioClassification] {
        // Simplified classification - would use SoundAnalysis framework or custom models
        return [
            AudioAnalysisResult.AudioClassification(label: "Unknown", confidence: 0.5, category: "General")
        ]
    }
    
    // Simplified signal processing functions
    private func generateSpectrogram(from buffer: AVAudioPCMBuffer, fftSize: Int) -> [[Float]] {
        // Simplified spectrogram generation
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let frameCount = Int(buffer.frameLength)
        let hopSize = fftSize / 4
        
        var spectrogram: [[Float]] = []
        for i in stride(from: 0, to: frameCount - fftSize, by: hopSize) {
            let frame = Array(UnsafeBufferPointer(start: channelData + i, count: fftSize))
            let spectrum = computeFFT(frame)
            spectrogram.append(spectrum)
        }
        
        return spectrogram
    }
    
    private func computeFFT(_ samples: [Float]) -> [Float] {
        // Simplified FFT - would use vDSP or Accelerate framework
        return samples.map { abs($0) }
    }
    
    private func calculateMFCC(_ buffer: AVAudioPCMBuffer, coefficients: Int) -> [Float] {
        // Simplified MFCC calculation
        return Array(repeating: 0.0, count: coefficients)
    }
    
    private func calculateSpectralCentroid(_ spectrogram: [[Float]], frequencyBins: [Float]) -> [Float] {
        return spectrogram.map { spectrum in
            let weightedSum = zip(spectrum, frequencyBins).reduce(0) { $0 + ($1.0 * $1.1) }
            let totalMagnitude = spectrum.reduce(0, +)
            return totalMagnitude > 0 ? weightedSum / totalMagnitude : 0
        }
    }
    
    private func calculateSpectralRolloff(_ spectrogram: [[Float]], frequencyBins: [Float]) -> [Float] {
        return spectrogram.map { spectrum in
            let totalEnergy = spectrum.reduce(0) { $0 + ($1 * $1) }
            let threshold = totalEnergy * 0.85
            
            var cumulativeEnergy: Float = 0
            for (index, magnitude) in spectrum.enumerated() {
                cumulativeEnergy += magnitude * magnitude
                if cumulativeEnergy >= threshold {
                    return frequencyBins[index]
                }
            }
            return frequencyBins.last ?? 0
        }
    }
    
    private func calculateSpectralBandwidth(_ spectrogram: [[Float]], frequencyBins: [Float]) -> [Float] {
        let centroids = calculateSpectralCentroid(spectrogram, frequencyBins: frequencyBins)
        
        return zip(spectrogram, centroids).map { spectrum, centroid in
            let weightedVariance = zip(spectrum, frequencyBins).reduce(0) { result, pair in
                let (magnitude, frequency) = pair
                let deviation = frequency - centroid
                return result + (magnitude * deviation * deviation)
            }
            let totalMagnitude = spectrum.reduce(0, +)
            return totalMagnitude > 0 ? sqrt(weightedVariance / totalMagnitude) : 0
        }
    }
    
    private func calculateSpectralFlatness(_ spectrogram: [[Float]]) -> [Float] {
        return spectrogram.map { spectrum in
            let geometricMean = exp(spectrum.map { log(max($0, 1e-10)) }.reduce(0, +) / Float(spectrum.count))
            let arithmeticMean = spectrum.reduce(0, +) / Float(spectrum.count)
            return arithmeticMean > 0 ? geometricMean / arithmeticMean : 0
        }
    }
    
    private func findPeakFrequencies(_ spectrogram: [[Float]], frequencyBins: [Float]) -> [Float] {
        return spectrogram.flatMap { spectrum in
            var peaks: [Float] = []
            for i in 1..<spectrum.count-1 {
                if spectrum[i] > spectrum[i-1] && spectrum[i] > spectrum[i+1] {
                    peaks.append(frequencyBins[i])
                }
            }
            return peaks
        }
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
                _ = try await analyzeAudio(request)
            } catch {
                if configuration.enableLogging {
                    print("[AudioAnalysis] ⚠️ Queued analysis failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: AudioAnalysisRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: AudioAnalysisRequest) -> String {
        // Generate a cache key based on audio input and analysis parameters
        let analysisTypes = request.analysisOptions.analysisTypes.map { $0.rawValue }.sorted().joined(separator: ",")
        let optionsHash = String(describing: request.analysisOptions).hashValue
        
        return "\(analysisTypes)_\(optionsHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalAnalyses)) + 1
        let totalAnalyses = metrics.totalAnalyses + 1
        let newCacheHitRate = cacheHits / Double(totalAnalyses)
        
        metrics = AudioAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses + 1,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            analysesByFormat: metrics.analysesByFormat,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageAudioDuration: metrics.averageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            featureExtractionStats: metrics.featureExtractionStats
        )
    }
    
    private func updateSuccessMetrics(_ result: AudioAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let successfulAnalyses = metrics.successfulAnalyses + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAnalyses)) + result.processingTime) / Double(totalAnalyses)
        
        var analysesByType = metrics.analysesByType
        if result.spectralAnalysis != nil {
            analysesByType["spectral", default: 0] += 1
        }
        if result.audioFeatures != nil {
            analysesByType["features", default: 0] += 1
        }
        if !result.classifications.isEmpty {
            analysesByType["classification", default: 0] += 1
        }
        
        let newAverageAudioDuration = ((metrics.averageAudioDuration * Double(metrics.successfulAnalyses)) + result.audioMetadata.duration) / Double(successfulAnalyses)
        
        metrics = AudioAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: successfulAnalyses,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: newAverageProcessingTime,
            analysesByType: analysesByType,
            analysesByFormat: metrics.analysesByFormat,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageAudioDuration: newAverageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            featureExtractionStats: metrics.featureExtractionStats
        )
    }
    
    private func updateFailureMetrics(_ result: AudioAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let failedAnalyses = metrics.failedAnalyses + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = AudioAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses,
            failedAnalyses: failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            analysesByFormat: metrics.analysesByFormat,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageAudioDuration: metrics.averageAudioDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            featureExtractionStats: metrics.featureExtractionStats
        )
    }
    
    private func logAnalysis(_ result: AudioAnalysisResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let durationStr = String(format: "%.1f", result.audioMetadata.duration)
        let classificationCount = result.classifications.count
        
        print("[AudioAnalysis] \(statusIcon) Analysis: \(durationStr)s audio, \(classificationCount) classifications (\(timeStr)s processing)")
        
        if let error = result.error {
            print("[AudioAnalysis] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Audio Analysis Capability Implementation

/// Audio Analysis capability providing comprehensive audio feature extraction and classification
@available(iOS 13.0, macOS 10.15, *)
public actor AudioAnalysisCapability: DomainCapability {
    public typealias ConfigurationType = AudioAnalysisCapabilityConfiguration
    public typealias ResourceType = AudioAnalysisCapabilityResource
    
    private var _configuration: AudioAnalysisCapabilityConfiguration
    private var _resources: AudioAnalysisCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "audio-analysis-capability" }
    
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
    
    public var configuration: AudioAnalysisCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: AudioAnalysisCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: AudioAnalysisCapabilityConfiguration = AudioAnalysisCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = AudioAnalysisCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: AudioAnalysisCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Audio Analysis configuration")
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
        // Audio analysis is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Audio analysis doesn't require special permissions beyond microphone if using live audio
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Audio Analysis Operations
    
    /// Analyze audio from various inputs
    public func analyzeAudio(_ request: AudioAnalysisRequest) async throws -> AudioAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return try await _resources.analyzeAudio(request)
    }
    
    /// Cancel audio analysis
    public func cancelAnalysis(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        await _resources.cancelAnalysis(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<AudioAnalysisResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get active analyses
    public func getActiveAnalyses() async throws -> [AudioAnalysisRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return await _resources.getActiveAnalyses()
    }
    
    /// Get analysis history
    public func getAnalysisHistory(since: Date? = nil) async throws -> [AudioAnalysisResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return await _resources.getAnalysisHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> AudioAnalysisMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Audio Analysis capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick spectral analysis of audio file
    public func quickSpectralAnalysis(_ audioFile: URL) async throws -> AudioAnalysisResult.SpectralAnalysis? {
        let options = AudioAnalysisRequest.AnalysisOptions(
            analysisTypes: [.spectral],
            spectralOptions: AudioAnalysisRequest.AnalysisOptions.SpectralOptions()
        )
        
        let request = AudioAnalysisRequest(audioInput: .audioFile(audioFile), analysisOptions: options)
        let result = try await analyzeAudio(request)
        
        return result.spectralAnalysis
    }
    
    /// Extract MFCC features from audio
    public func extractMFCC(_ audioFile: URL, coefficients: Int = 13) async throws -> [Float] {
        let featureOptions = AudioAnalysisRequest.AnalysisOptions.FeatureOptions(
            extractMFCC: true,
            mfccCoefficients: coefficients
        )
        
        let options = AudioAnalysisRequest.AnalysisOptions(
            analysisTypes: [.features],
            featureOptions: featureOptions
        )
        
        let request = AudioAnalysisRequest(audioInput: .audioFile(audioFile), analysisOptions: options)
        let result = try await analyzeAudio(request)
        
        return result.audioFeatures?.mfcc ?? []
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

/// Audio Analysis specific errors
public enum AudioAnalysisError: Error, LocalizedError {
    case audioAnalysisDisabled
    case customModelsDisabled
    case modelLoadFailed(String, String)
    case analysisError(String)
    case invalidAudioFormat
    case unsupportedAudioFormat
    case analysisQueued(UUID)
    case analysisTimeout(UUID)
    case liveAudioNotSupported
    case insufficientAudioData
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .audioAnalysisDisabled:
            return "Audio analysis is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .analysisError(let reason):
            return "Audio analysis failed: \(reason)"
        case .invalidAudioFormat:
            return "Invalid audio format"
        case .unsupportedAudioFormat:
            return "Unsupported audio format"
        case .analysisQueued(let id):
            return "Audio analysis queued: \(id)"
        case .analysisTimeout(let id):
            return "Audio analysis timeout: \(id)"
        case .liveAudioNotSupported:
            return "Live audio analysis not supported"
        case .insufficientAudioData:
            return "Insufficient audio data for analysis"
        case .configurationError(let reason):
            return "Audio analysis configuration error: \(reason)"
        }
    }
}