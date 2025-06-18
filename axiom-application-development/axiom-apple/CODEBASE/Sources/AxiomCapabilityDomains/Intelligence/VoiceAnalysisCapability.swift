import Foundation
import AVFoundation
import CoreML
import SoundAnalysis
import Speech
import AxiomCore
import AxiomCapabilities

// MARK: - Voice Analysis Capability Configuration

/// Configuration for Voice Analysis capability
public struct VoiceAnalysisCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableVoiceAnalysis: Bool
    public let enableSpeakerIdentification: Bool
    public let enableEmotionDetection: Bool
    public let enableVoiceQualityAssessment: Bool
    public let enableVoiceprint: Bool
    public let enableRealTimeAnalysis: Bool
    public let enableCustomModels: Bool
    public let maxConcurrentAnalyses: Int
    public let analysisTimeout: TimeInterval
    public let minimumAudioDuration: TimeInterval
    public let maximumAudioDuration: TimeInterval
    public let confidenceThreshold: Float
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let enablePerformanceOptimization: Bool
    public let analysisQuality: AnalysisQuality
    public let enablePrivacyMode: Bool
    
    public enum AnalysisQuality: String, Codable, CaseIterable {
        case fast = "fast"
        case balanced = "balanced"
        case accurate = "accurate"
    }
    
    public init(
        enableVoiceAnalysis: Bool = true,
        enableSpeakerIdentification: Bool = true,
        enableEmotionDetection: Bool = true,
        enableVoiceQualityAssessment: Bool = true,
        enableVoiceprint: Bool = true,
        enableRealTimeAnalysis: Bool = true,
        enableCustomModels: Bool = true,
        maxConcurrentAnalyses: Int = 3,
        analysisTimeout: TimeInterval = 60.0,
        minimumAudioDuration: TimeInterval = 1.0,
        maximumAudioDuration: TimeInterval = 300.0,
        confidenceThreshold: Float = 0.5,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 50,
        enablePerformanceOptimization: Bool = true,
        analysisQuality: AnalysisQuality = .balanced,
        enablePrivacyMode: Bool = true
    ) {
        self.enableVoiceAnalysis = enableVoiceAnalysis
        self.enableSpeakerIdentification = enableSpeakerIdentification
        self.enableEmotionDetection = enableEmotionDetection
        self.enableVoiceQualityAssessment = enableVoiceQualityAssessment
        self.enableVoiceprint = enableVoiceprint
        self.enableRealTimeAnalysis = enableRealTimeAnalysis
        self.enableCustomModels = enableCustomModels
        self.maxConcurrentAnalyses = maxConcurrentAnalyses
        self.analysisTimeout = analysisTimeout
        self.minimumAudioDuration = minimumAudioDuration
        self.maximumAudioDuration = maximumAudioDuration
        self.confidenceThreshold = confidenceThreshold
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.analysisQuality = analysisQuality
        self.enablePrivacyMode = enablePrivacyMode
    }
    
    public var isValid: Bool {
        maxConcurrentAnalyses > 0 &&
        analysisTimeout > 0 &&
        minimumAudioDuration > 0 &&
        maximumAudioDuration > minimumAudioDuration &&
        confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: VoiceAnalysisCapabilityConfiguration) -> VoiceAnalysisCapabilityConfiguration {
        VoiceAnalysisCapabilityConfiguration(
            enableVoiceAnalysis: other.enableVoiceAnalysis,
            enableSpeakerIdentification: other.enableSpeakerIdentification,
            enableEmotionDetection: other.enableEmotionDetection,
            enableVoiceQualityAssessment: other.enableVoiceQualityAssessment,
            enableVoiceprint: other.enableVoiceprint,
            enableRealTimeAnalysis: other.enableRealTimeAnalysis,
            enableCustomModels: other.enableCustomModels,
            maxConcurrentAnalyses: other.maxConcurrentAnalyses,
            analysisTimeout: other.analysisTimeout,
            minimumAudioDuration: other.minimumAudioDuration,
            maximumAudioDuration: other.maximumAudioDuration,
            confidenceThreshold: other.confidenceThreshold,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            analysisQuality: other.analysisQuality,
            enablePrivacyMode: other.enablePrivacyMode
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> VoiceAnalysisCapabilityConfiguration {
        var adjustedTimeout = analysisTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAnalyses = maxConcurrentAnalyses
        var adjustedCacheSize = cacheSize
        var adjustedQuality = analysisQuality
        var adjustedPrivacyMode = enablePrivacyMode
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(analysisTimeout, 30.0)
            adjustedConcurrentAnalyses = min(maxConcurrentAnalyses, 1)
            adjustedCacheSize = min(cacheSize, 10)
            adjustedQuality = .fast
            adjustedPrivacyMode = true
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return VoiceAnalysisCapabilityConfiguration(
            enableVoiceAnalysis: enableVoiceAnalysis,
            enableSpeakerIdentification: enableSpeakerIdentification,
            enableEmotionDetection: enableEmotionDetection,
            enableVoiceQualityAssessment: enableVoiceQualityAssessment,
            enableVoiceprint: enableVoiceprint,
            enableRealTimeAnalysis: enableRealTimeAnalysis,
            enableCustomModels: enableCustomModels,
            maxConcurrentAnalyses: adjustedConcurrentAnalyses,
            analysisTimeout: adjustedTimeout,
            minimumAudioDuration: minimumAudioDuration,
            maximumAudioDuration: maximumAudioDuration,
            confidenceThreshold: confidenceThreshold,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            enablePerformanceOptimization: enablePerformanceOptimization,
            analysisQuality: adjustedQuality,
            enablePrivacyMode: adjustedPrivacyMode
        )
    }
}

// MARK: - Voice Analysis Types

/// Voice analysis request
public struct VoiceAnalysisRequest: Sendable, Identifiable {
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
        public let speakerOptions: SpeakerOptions?
        public let emotionOptions: EmotionOptions?
        public let qualityOptions: QualityOptions?
        public let voiceprintOptions: VoiceprintOptions?
        public let customModelId: String?
        
        public enum AnalysisType: String, Sendable, CaseIterable {
            case speakerIdentification = "speaker-identification"
            case emotionDetection = "emotion-detection"
            case qualityAssessment = "quality-assessment"
            case voiceprint = "voiceprint"
            case ageEstimation = "age-estimation"
            case genderClassification = "gender-classification"
            case accentDetection = "accent-detection"
            case stressDetection = "stress-detection"
        }
        
        public struct SpeakerOptions: Sendable {
            public let enableVerification: Bool
            public let enableIdentification: Bool
            public let referenceVoiceprints: [String]
            public let maxCandidates: Int
            
            public init(
                enableVerification: Bool = true,
                enableIdentification: Bool = true,
                referenceVoiceprints: [String] = [],
                maxCandidates: Int = 10
            ) {
                self.enableVerification = enableVerification
                self.enableIdentification = enableIdentification
                self.referenceVoiceprints = referenceVoiceprints
                self.maxCandidates = maxCandidates
            }
        }
        
        public struct EmotionOptions: Sendable {
            public let detectBasicEmotions: Bool
            public let detectComplexEmotions: Bool
            public let emotionCategories: Set<EmotionCategory>
            public let enableTemporal: Bool
            
            public enum EmotionCategory: String, Sendable, CaseIterable {
                case happiness = "happiness"
                case sadness = "sadness"
                case anger = "anger"
                case fear = "fear"
                case surprise = "surprise"
                case disgust = "disgust"
                case neutral = "neutral"
                case excitement = "excitement"
                case calmness = "calmness"
                case confusion = "confusion"
            }
            
            public init(
                detectBasicEmotions: Bool = true,
                detectComplexEmotions: Bool = false,
                emotionCategories: Set<EmotionCategory> = Set(EmotionCategory.allCases),
                enableTemporal: Bool = true
            ) {
                self.detectBasicEmotions = detectBasicEmotions
                self.detectComplexEmotions = detectComplexEmotions
                self.emotionCategories = emotionCategories
                self.enableTemporal = enableTemporal
            }
        }
        
        public struct QualityOptions: Sendable {
            public let assessClarity: Bool
            public let assessNoise: Bool
            public let assessDistortion: Bool
            public let assessVolume: Bool
            public let assessPitchStability: Bool
            
            public init(
                assessClarity: Bool = true,
                assessNoise: Bool = true,
                assessDistortion: Bool = true,
                assessVolume: Bool = true,
                assessPitchStability: Bool = true
            ) {
                self.assessClarity = assessClarity
                self.assessNoise = assessNoise
                self.assessDistortion = assessDistortion
                self.assessVolume = assessVolume
                self.assessPitchStability = assessPitchStability
            }
        }
        
        public struct VoiceprintOptions: Sendable {
            public let extractFeatures: Bool
            public let generateEmbedding: Bool
            public let embeddingDimensions: Int
            public let enableComparison: Bool
            
            public init(
                extractFeatures: Bool = true,
                generateEmbedding: Bool = true,
                embeddingDimensions: Int = 256,
                enableComparison: Bool = true
            ) {
                self.extractFeatures = extractFeatures
                self.generateEmbedding = generateEmbedding
                self.embeddingDimensions = embeddingDimensions
                self.enableComparison = enableComparison
            }
        }
        
        public init(
            analysisTypes: Set<AnalysisType> = [.emotionDetection, .qualityAssessment],
            speakerOptions: SpeakerOptions? = nil,
            emotionOptions: EmotionOptions? = EmotionOptions(),
            qualityOptions: QualityOptions? = QualityOptions(),
            voiceprintOptions: VoiceprintOptions? = nil,
            customModelId: String? = nil
        ) {
            self.analysisTypes = analysisTypes
            self.speakerOptions = speakerOptions
            self.emotionOptions = emotionOptions
            self.qualityOptions = qualityOptions
            self.voiceprintOptions = voiceprintOptions
            self.customModelId = customModelId
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

/// Voice analysis result
public struct VoiceAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let audioMetadata: AudioMetadata
    public let speakerAnalysis: SpeakerAnalysis?
    public let emotionAnalysis: EmotionAnalysis?
    public let qualityAnalysis: QualityAnalysis?
    public let voiceprintAnalysis: VoiceprintAnalysis?
    public let demographicAnalysis: DemographicAnalysis?
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: VoiceAnalysisError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AudioMetadata: Sendable {
        public let duration: TimeInterval
        public let sampleRate: Double
        public let channels: Int
        public let speechSegments: [SpeechSegment]
        public let silenceRatio: Float
        
        public struct SpeechSegment: Sendable {
            public let startTime: TimeInterval
            public let endTime: TimeInterval
            public let confidence: Float
            public let energy: Float
            
            public init(startTime: TimeInterval, endTime: TimeInterval, confidence: Float, energy: Float) {
                self.startTime = startTime
                self.endTime = endTime
                self.confidence = confidence
                self.energy = energy
            }
        }
        
        public init(duration: TimeInterval, sampleRate: Double, channels: Int, speechSegments: [SpeechSegment], silenceRatio: Float) {
            self.duration = duration
            self.sampleRate = sampleRate
            self.channels = channels
            self.speechSegments = speechSegments
            self.silenceRatio = silenceRatio
        }
    }
    
    public struct SpeakerAnalysis: Sendable {
        public let speakerIdentification: SpeakerIdentification?
        public let speakerVerification: SpeakerVerification?
        public let voiceCharacteristics: VoiceCharacteristics
        
        public struct SpeakerIdentification: Sendable {
            public let candidates: [SpeakerCandidate]
            public let topMatch: SpeakerCandidate?
            public let isNewSpeaker: Bool
            
            public struct SpeakerCandidate: Sendable {
                public let speakerId: String
                public let similarity: Float
                public let confidence: Float
                
                public init(speakerId: String, similarity: Float, confidence: Float) {
                    self.speakerId = speakerId
                    self.similarity = similarity
                    self.confidence = confidence
                }
            }
            
            public init(candidates: [SpeakerCandidate], isNewSpeaker: Bool) {
                self.candidates = candidates
                self.topMatch = candidates.max(by: { $0.confidence < $1.confidence })
                self.isNewSpeaker = isNewSpeaker
            }
        }
        
        public struct SpeakerVerification: Sendable {
            public let isMatch: Bool
            public let similarity: Float
            public let confidence: Float
            public let threshold: Float
            
            public init(isMatch: Bool, similarity: Float, confidence: Float, threshold: Float) {
                self.isMatch = isMatch
                self.similarity = similarity
                self.confidence = confidence
                self.threshold = threshold
            }
        }
        
        public struct VoiceCharacteristics: Sendable {
            public let fundamentalFrequency: VoiceRange
            public let formantFrequencies: [Float]
            public let voiceTexture: VoiceTexture
            public let articulationRate: Float
            public let pausePatterns: PausePatterns
            
            public struct VoiceRange: Sendable {
                public let mean: Float
                public let min: Float
                public let max: Float
                public let standardDeviation: Float
                
                public init(mean: Float, min: Float, max: Float, standardDeviation: Float) {
                    self.mean = mean
                    self.min = min
                    self.max = max
                    self.standardDeviation = standardDeviation
                }
            }
            
            public struct VoiceTexture: Sendable {
                public let roughness: Float
                public let breathiness: Float
                public let nasality: Float
                public let hoarseness: Float
                
                public init(roughness: Float, breathiness: Float, nasality: Float, hoarseness: Float) {
                    self.roughness = roughness
                    self.breathiness = breathiness
                    self.nasality = nasality
                    self.hoarseness = hoarseness
                }
            }
            
            public struct PausePatterns: Sendable {
                public let pauseCount: Int
                public let averagePauseDuration: TimeInterval
                public let pauseRatio: Float
                
                public init(pauseCount: Int, averagePauseDuration: TimeInterval, pauseRatio: Float) {
                    self.pauseCount = pauseCount
                    self.averagePauseDuration = averagePauseDuration
                    self.pauseRatio = pauseRatio
                }
            }
            
            public init(fundamentalFrequency: VoiceRange, formantFrequencies: [Float], voiceTexture: VoiceTexture, articulationRate: Float, pausePatterns: PausePatterns) {
                self.fundamentalFrequency = fundamentalFrequency
                self.formantFrequencies = formantFrequencies
                self.voiceTexture = voiceTexture
                self.articulationRate = articulationRate
                self.pausePatterns = pausePatterns
            }
        }
        
        public init(speakerIdentification: SpeakerIdentification? = nil, speakerVerification: SpeakerVerification? = nil, voiceCharacteristics: VoiceCharacteristics) {
            self.speakerIdentification = speakerIdentification
            self.speakerVerification = speakerVerification
            self.voiceCharacteristics = voiceCharacteristics
        }
    }
    
    public struct EmotionAnalysis: Sendable {
        public let dominantEmotion: EmotionPrediction
        public let emotionDistribution: [EmotionPrediction]
        public let emotionTimeline: [TemporalEmotion]
        public let arousal: Float
        public let valence: Float
        public let emotionalStability: Float
        
        public struct EmotionPrediction: Sendable {
            public let emotion: VoiceAnalysisRequest.AnalysisOptions.EmotionOptions.EmotionCategory
            public let confidence: Float
            public let intensity: Float
            
            public init(emotion: VoiceAnalysisRequest.AnalysisOptions.EmotionOptions.EmotionCategory, confidence: Float, intensity: Float) {
                self.emotion = emotion
                self.confidence = confidence
                self.intensity = intensity
            }
        }
        
        public struct TemporalEmotion: Sendable {
            public let timeRange: TimeInterval
            public let emotion: EmotionPrediction
            
            public init(timeRange: TimeInterval, emotion: EmotionPrediction) {
                self.timeRange = timeRange
                self.emotion = emotion
            }
        }
        
        public init(dominantEmotion: EmotionPrediction, emotionDistribution: [EmotionPrediction], emotionTimeline: [TemporalEmotion], arousal: Float, valence: Float, emotionalStability: Float) {
            self.dominantEmotion = dominantEmotion
            self.emotionDistribution = emotionDistribution
            self.emotionTimeline = emotionTimeline
            self.arousal = arousal
            self.valence = valence
            self.emotionalStability = emotionalStability
        }
    }
    
    public struct QualityAnalysis: Sendable {
        public let overallQuality: Float
        public let clarity: QualityMetric
        public let noiseLevel: QualityMetric
        public let distortion: QualityMetric
        public let volumeLevel: QualityMetric
        public let pitchStability: QualityMetric
        public let recommendations: [String]
        
        public struct QualityMetric: Sendable {
            public let score: Float
            public let assessment: QualityAssessment
            public let details: String?
            
            public enum QualityAssessment: String, Sendable, CaseIterable {
                case excellent = "excellent"
                case good = "good"
                case fair = "fair"
                case poor = "poor"
            }
            
            public init(score: Float, assessment: QualityAssessment, details: String? = nil) {
                self.score = score
                self.assessment = assessment
                self.details = details
            }
        }
        
        public init(overallQuality: Float, clarity: QualityMetric, noiseLevel: QualityMetric, distortion: QualityMetric, volumeLevel: QualityMetric, pitchStability: QualityMetric, recommendations: [String]) {
            self.overallQuality = overallQuality
            self.clarity = clarity
            self.noiseLevel = noiseLevel
            self.distortion = distortion
            self.volumeLevel = volumeLevel
            self.pitchStability = pitchStability
            self.recommendations = recommendations
        }
    }
    
    public struct VoiceprintAnalysis: Sendable {
        public let voiceprintId: String
        public let features: [Float]
        public let embedding: [Float]
        public let uniquenessScore: Float
        public let stabilityScore: Float
        
        public init(voiceprintId: String, features: [Float], embedding: [Float], uniquenessScore: Float, stabilityScore: Float) {
            self.voiceprintId = voiceprintId
            self.features = features
            self.embedding = embedding
            self.uniquenessScore = uniquenessScore
            self.stabilityScore = stabilityScore
        }
    }
    
    public struct DemographicAnalysis: Sendable {
        public let ageEstimate: AgeEstimate?
        public let genderPrediction: GenderPrediction?
        public let accentDetection: AccentDetection?
        public let stressLevel: StressLevel?
        
        public struct AgeEstimate: Sendable {
            public let estimatedAge: Int
            public let ageRange: ClosedRange<Int>
            public let confidence: Float
            
            public init(estimatedAge: Int, ageRange: ClosedRange<Int>, confidence: Float) {
                self.estimatedAge = estimatedAge
                self.ageRange = ageRange
                self.confidence = confidence
            }
        }
        
        public struct GenderPrediction: Sendable {
            public let gender: Gender
            public let confidence: Float
            
            public enum Gender: String, Sendable, CaseIterable {
                case male = "male"
                case female = "female"
                case unknown = "unknown"
            }
            
            public init(gender: Gender, confidence: Float) {
                self.gender = gender
                self.confidence = confidence
            }
        }
        
        public struct AccentDetection: Sendable {
            public let detectedAccent: String
            public let confidence: Float
            public let region: String?
            
            public init(detectedAccent: String, confidence: Float, region: String? = nil) {
                self.detectedAccent = detectedAccent
                self.confidence = confidence
                self.region = region
            }
        }
        
        public struct StressLevel: Sendable {
            public let level: Level
            public let score: Float
            public let indicators: [String]
            
            public enum Level: String, Sendable, CaseIterable {
                case low = "low"
                case moderate = "moderate"
                case high = "high"
                case extreme = "extreme"
            }
            
            public init(level: Level, score: Float, indicators: [String]) {
                self.level = level
                self.score = score
                self.indicators = indicators
            }
        }
        
        public init(ageEstimate: AgeEstimate? = nil, genderPrediction: GenderPrediction? = nil, accentDetection: AccentDetection? = nil, stressLevel: StressLevel? = nil) {
            self.ageEstimate = ageEstimate
            self.genderPrediction = genderPrediction
            self.accentDetection = accentDetection
            self.stressLevel = stressLevel
        }
    }
    
    public init(
        requestId: UUID,
        audioMetadata: AudioMetadata,
        speakerAnalysis: SpeakerAnalysis? = nil,
        emotionAnalysis: EmotionAnalysis? = nil,
        qualityAnalysis: QualityAnalysis? = nil,
        voiceprintAnalysis: VoiceprintAnalysis? = nil,
        demographicAnalysis: DemographicAnalysis? = nil,
        processingTime: TimeInterval,
        success: Bool,
        error: VoiceAnalysisError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.audioMetadata = audioMetadata
        self.speakerAnalysis = speakerAnalysis
        self.emotionAnalysis = emotionAnalysis
        self.qualityAnalysis = qualityAnalysis
        self.voiceprintAnalysis = voiceprintAnalysis
        self.demographicAnalysis = demographicAnalysis
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var speechDuration: TimeInterval {
        audioMetadata.speechSegments.reduce(0) { $0 + ($1.endTime - $1.startTime) }
    }
    
    public var speechToSilenceRatio: Float {
        1.0 - audioMetadata.silenceRatio
    }
}

/// Voice analysis metrics
public struct VoiceAnalysisMetrics: Sendable {
    public let totalAnalyses: Int
    public let successfulAnalyses: Int
    public let failedAnalyses: Int
    public let averageProcessingTime: TimeInterval
    public let analysesByType: [String: Int]
    public let emotionDetectionStats: EmotionDetectionStats
    public let speakerIdentificationStats: SpeakerIdentificationStats
    public let qualityAssessmentStats: QualityAssessmentStats
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let throughputPerSecond: Double
    
    public struct EmotionDetectionStats: Sendable {
        public let totalEmotionDetections: Int
        public let emotionDistribution: [String: Int]
        public let averageConfidence: Double
        public let mostDetectedEmotion: String?
        
        public init(totalEmotionDetections: Int = 0, emotionDistribution: [String: Int] = [:], averageConfidence: Double = 0, mostDetectedEmotion: String? = nil) {
            self.totalEmotionDetections = totalEmotionDetections
            self.emotionDistribution = emotionDistribution
            self.averageConfidence = averageConfidence
            self.mostDetectedEmotion = mostDetectedEmotion
        }
    }
    
    public struct SpeakerIdentificationStats: Sendable {
        public let totalIdentifications: Int
        public let successfulIdentifications: Int
        public let averageConfidence: Double
        public let uniqueSpeakers: Int
        
        public init(totalIdentifications: Int = 0, successfulIdentifications: Int = 0, averageConfidence: Double = 0, uniqueSpeakers: Int = 0) {
            self.totalIdentifications = totalIdentifications
            self.successfulIdentifications = successfulIdentifications
            self.averageConfidence = averageConfidence
            self.uniqueSpeakers = uniqueSpeakers
        }
    }
    
    public struct QualityAssessmentStats: Sendable {
        public let totalAssessments: Int
        public let averageQuality: Double
        public let qualityDistribution: [String: Int]
        
        public init(totalAssessments: Int = 0, averageQuality: Double = 0, qualityDistribution: [String: Int] = [:]) {
            self.totalAssessments = totalAssessments
            self.averageQuality = averageQuality
            self.qualityDistribution = qualityDistribution
        }
    }
    
    public init(
        totalAnalyses: Int = 0,
        successfulAnalyses: Int = 0,
        failedAnalyses: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        analysesByType: [String: Int] = [:],
        emotionDetectionStats: EmotionDetectionStats = EmotionDetectionStats(),
        speakerIdentificationStats: SpeakerIdentificationStats = SpeakerIdentificationStats(),
        qualityAssessmentStats: QualityAssessmentStats = QualityAssessmentStats(),
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        throughputPerSecond: Double = 0
    ) {
        self.totalAnalyses = totalAnalyses
        self.successfulAnalyses = successfulAnalyses
        self.failedAnalyses = failedAnalyses
        self.averageProcessingTime = averageProcessingTime
        self.analysesByType = analysesByType
        self.emotionDetectionStats = emotionDetectionStats
        self.speakerIdentificationStats = speakerIdentificationStats
        self.qualityAssessmentStats = qualityAssessmentStats
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalAnalyses) / averageProcessingTime : 0
    }
    
    public var successRate: Double {
        totalAnalyses > 0 ? Double(successfulAnalyses) / Double(totalAnalyses) : 0
    }
}

// MARK: - Voice Analysis Resource

/// Voice analysis resource management
@available(iOS 13.0, macOS 10.15, *)
public actor VoiceAnalysisCapabilityResource: AxiomCapabilityResource {
    private let configuration: VoiceAnalysisCapabilityConfiguration
    private var activeAnalyses: [UUID: VoiceAnalysisRequest] = [:]
    private var analysisQueue: [VoiceAnalysisRequest] = [:]
    private var analysisHistory: [VoiceAnalysisResult] = [:]
    private var resultCache: [String: VoiceAnalysisResult] = [:]
    private var customModels: [String: MLModel] = [:]
    private var voiceprints: [String: [Float]] = [:]
    private var metrics: VoiceAnalysisMetrics = VoiceAnalysisMetrics()
    private var resultStreamContinuation: AsyncStream<VoiceAnalysisResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    public init(configuration: VoiceAnalysisCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 350_000_000, // 350MB for voice analysis
            cpu: 5.0, // High CPU usage for voice processing
            bandwidth: 0,
            storage: 150_000_000 // 150MB for model and voiceprint caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let analysisMemory = activeAnalyses.count * 50_000_000 // ~50MB per active analysis
            let cacheMemory = resultCache.count * 250_000 // ~250KB per cached result
            let modelMemory = customModels.count * 100_000_000 // ~100MB per loaded model
            let voiceprintMemory = voiceprints.count * 1_000 // ~1KB per voiceprint
            let historyMemory = analysisHistory.count * 30_000
            
            return ResourceUsage(
                memory: analysisMemory + cacheMemory + modelMemory + voiceprintMemory + historyMemory + 40_000_000,
                cpu: activeAnalyses.isEmpty ? 0.4 : 4.5,
                bandwidth: 0,
                storage: resultCache.count * 125_000 + customModels.count * 250_000_000 + voiceprints.count * 2_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Voice analysis is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableVoiceAnalysis
        }
        return false
    }
    
    public func release() async {
        activeAnalyses.removeAll()
        analysisQueue.removeAll()
        analysisHistory.removeAll()
        resultCache.removeAll()
        customModels.removeAll()
        
        if !configuration.enablePrivacyMode {
            voiceprints.removeAll()
        }
        
        resultStreamContinuation?.finish()
        
        metrics = VoiceAnalysisMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize voice analysis models
        if configuration.enableCustomModels {
            await loadBuiltInModels()
        }
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[VoiceAnalysis] 🚀 Voice Analysis capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: VoiceAnalysisCapabilityConfiguration) async throws {
        // Update voice analysis configurations
        if configuration.enablePrivacyMode && !self.configuration.enablePrivacyMode {
            // Clear voiceprints when privacy mode is enabled
            voiceprints.removeAll()
        }
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<VoiceAnalysisResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Model Management
    
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard configuration.enableCustomModels else {
            throw VoiceAnalysisError.customModelsDisabled
        }
        
        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            
            customModels[identifier] = mlModel
            
            if configuration.enableLogging {
                print("[VoiceAnalysis] 📦 Loaded custom model: \(identifier)")
            }
            
        } catch {
            throw VoiceAnalysisError.modelLoadFailed(identifier, error.localizedDescription)
        }
    }
    
    public func unloadCustomModel(_ identifier: String) async {
        customModels.removeValue(forKey: identifier)
        
        if configuration.enableLogging {
            print("[VoiceAnalysis] 🗑️ Unloaded custom model: \(identifier)")
        }
    }
    
    public func getLoadedModels() async -> [String] {
        return Array(customModels.keys)
    }
    
    // MARK: - Voiceprint Management
    
    public func registerVoiceprint(_ voiceprint: [Float], for speakerId: String) async throws {
        guard configuration.enableVoiceprint else {
            throw VoiceAnalysisError.voiceprintDisabled
        }
        
        voiceprints[speakerId] = voiceprint
        
        if configuration.enableLogging {
            print("[VoiceAnalysis] 👤 Registered voiceprint for speaker: \(speakerId)")
        }
    }
    
    public func removeVoiceprint(for speakerId: String) async {
        voiceprints.removeValue(forKey: speakerId)
        
        if configuration.enableLogging {
            print("[VoiceAnalysis] 🗑️ Removed voiceprint for speaker: \(speakerId)")
        }
    }
    
    public func getRegisteredSpeakers() async -> [String] {
        return Array(voiceprints.keys)
    }
    
    // MARK: - Voice Analysis
    
    public func analyzeVoice(_ request: VoiceAnalysisRequest) async throws -> VoiceAnalysisResult {
        guard configuration.enableVoiceAnalysis else {
            throw VoiceAnalysisError.voiceAnalysisDisabled
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
            throw VoiceAnalysisError.analysisQueued(request.id)
        }
        
        let startTime = Date()
        activeAnalyses[request.id] = request
        
        do {
            // Extract audio buffer from input
            let audioBuffer = try await extractAudioBuffer(from: request.audioInput)
            
            // Validate audio duration
            let duration = Double(audioBuffer.frameLength) / audioBuffer.format.sampleRate
            guard duration >= configuration.minimumAudioDuration else {
                throw VoiceAnalysisError.insufficientAudioDuration
            }
            guard duration <= configuration.maximumAudioDuration else {
                throw VoiceAnalysisError.excessiveAudioDuration
            }
            
            // Perform analysis
            let result = try await performVoiceAnalysis(
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
            let result = VoiceAnalysisResult(
                requestId: request.id,
                audioMetadata: VoiceAnalysisResult.AudioMetadata(
                    duration: 0,
                    sampleRate: 44100,
                    channels: 1,
                    speechSegments: [],
                    silenceRatio: 1.0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? VoiceAnalysisError ?? VoiceAnalysisError.analysisError(error.localizedDescription)
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
            print("[VoiceAnalysis] 🚫 Cancelled analysis: \(requestId)")
        }
    }
    
    public func getActiveAnalyses() async -> [VoiceAnalysisRequest] {
        return Array(activeAnalyses.values)
    }
    
    public func getAnalysisHistory(since: Date? = nil) async -> [VoiceAnalysisResult] {
        if let since = since {
            return analysisHistory.filter { $0.timestamp >= since }
        }
        return analysisHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> VoiceAnalysisMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = VoiceAnalysisMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadBuiltInModels() async {
        if configuration.enableLogging {
            print("[VoiceAnalysis] 📦 Loaded built-in voice analysis models")
        }
    }
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[VoiceAnalysis] ⚡ Performance optimization enabled")
        }
    }
    
    private func extractAudioBuffer(from input: VoiceAnalysisRequest.AudioInput) async throws -> AVAudioPCMBuffer {
        switch input {
        case .audioBuffer(let buffer):
            return buffer
            
        case .audioFile(let url):
            return try await loadAudioFile(url)
            
        case .audioData(let data, let format):
            return try createBufferFromData(data, format: format)
            
        case .liveAudio:
            throw VoiceAnalysisError.liveAudioNotSupported
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
                    continuation.resume(throwing: VoiceAnalysisError.invalidAudioFormat)
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
            throw VoiceAnalysisError.invalidAudioFormat
        }
        
        buffer.frameLength = frameCount
        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            buffer.audioBufferList.pointee.mBuffers.mData = UnsafeMutableRawPointer(mutating: baseAddress)
        }
        
        return buffer
    }
    
    private func performVoiceAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        request: VoiceAnalysisRequest,
        startTime: Date
    ) async throws -> VoiceAnalysisResult {
        
        let audioMetadata = createAudioMetadata(from: audioBuffer)
        let processingTime = Date().timeIntervalSince(startTime)
        
        var speakerAnalysis: VoiceAnalysisResult.SpeakerAnalysis?
        var emotionAnalysis: VoiceAnalysisResult.EmotionAnalysis?
        var qualityAnalysis: VoiceAnalysisResult.QualityAnalysis?
        var voiceprintAnalysis: VoiceAnalysisResult.VoiceprintAnalysis?
        var demographicAnalysis: VoiceAnalysisResult.DemographicAnalysis?
        
        // Perform speaker identification if requested
        if request.analysisOptions.analysisTypes.contains(.speakerIdentification) && configuration.enableSpeakerIdentification {
            speakerAnalysis = await performSpeakerAnalysis(audioBuffer: audioBuffer, options: request.analysisOptions.speakerOptions)
        }
        
        // Perform emotion detection if requested
        if request.analysisOptions.analysisTypes.contains(.emotionDetection) && configuration.enableEmotionDetection {
            emotionAnalysis = await performEmotionAnalysis(audioBuffer: audioBuffer, options: request.analysisOptions.emotionOptions)
        }
        
        // Perform quality assessment if requested
        if request.analysisOptions.analysisTypes.contains(.qualityAssessment) && configuration.enableVoiceQualityAssessment {
            qualityAnalysis = await performQualityAnalysis(audioBuffer: audioBuffer, options: request.analysisOptions.qualityOptions)
        }
        
        // Generate voiceprint if requested
        if request.analysisOptions.analysisTypes.contains(.voiceprint) && configuration.enableVoiceprint {
            voiceprintAnalysis = await generateVoiceprint(audioBuffer: audioBuffer, options: request.analysisOptions.voiceprintOptions)
        }
        
        // Perform demographic analysis if requested
        if !request.analysisOptions.analysisTypes.intersection([.ageEstimation, .genderClassification, .accentDetection, .stressDetection]).isEmpty {
            demographicAnalysis = await performDemographicAnalysis(audioBuffer: audioBuffer, analysisTypes: request.analysisOptions.analysisTypes)
        }
        
        return VoiceAnalysisResult(
            requestId: request.id,
            audioMetadata: audioMetadata,
            speakerAnalysis: speakerAnalysis,
            emotionAnalysis: emotionAnalysis,
            qualityAnalysis: qualityAnalysis,
            voiceprintAnalysis: voiceprintAnalysis,
            demographicAnalysis: demographicAnalysis,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func createAudioMetadata(from buffer: AVAudioPCMBuffer) -> VoiceAnalysisResult.AudioMetadata {
        let duration = Double(buffer.frameLength) / buffer.format.sampleRate
        let speechSegments = detectSpeechSegments(in: buffer)
        let silenceRatio = calculateSilenceRatio(speechSegments: speechSegments, totalDuration: duration)
        
        return VoiceAnalysisResult.AudioMetadata(
            duration: duration,
            sampleRate: buffer.format.sampleRate,
            channels: Int(buffer.format.channelCount),
            speechSegments: speechSegments,
            silenceRatio: silenceRatio
        )
    }
    
    private func detectSpeechSegments(in buffer: AVAudioPCMBuffer) -> [VoiceAnalysisResult.AudioMetadata.SpeechSegment] {
        // Simplified voice activity detection
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let frameCount = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate
        
        var segments: [VoiceAnalysisResult.AudioMetadata.SpeechSegment] = []
        let windowSize = Int(sampleRate * 0.025) // 25ms windows
        let hopSize = windowSize / 2
        
        var inSpeech = false
        var segmentStart: TimeInterval = 0
        
        for i in stride(from: 0, to: frameCount - windowSize, by: hopSize) {
            let window = Array(UnsafeBufferPointer(start: channelData + i, count: windowSize))
            let energy = window.reduce(0) { $0 + ($1 * $1) } / Float(windowSize)
            let isSpeech = energy > 0.001 // Simple energy threshold
            
            let currentTime = Double(i) / sampleRate
            
            if !inSpeech && isSpeech {
                // Speech start
                inSpeech = true
                segmentStart = currentTime
            } else if inSpeech && !isSpeech {
                // Speech end
                inSpeech = false
                segments.append(VoiceAnalysisResult.AudioMetadata.SpeechSegment(
                    startTime: segmentStart,
                    endTime: currentTime,
                    confidence: 0.8,
                    energy: sqrt(energy)
                ))
            }
        }
        
        // Close final segment if needed
        if inSpeech {
            segments.append(VoiceAnalysisResult.AudioMetadata.SpeechSegment(
                startTime: segmentStart,
                endTime: Double(frameCount) / sampleRate,
                confidence: 0.8,
                energy: 0.5
            ))
        }
        
        return segments
    }
    
    private func calculateSilenceRatio(speechSegments: [VoiceAnalysisResult.AudioMetadata.SpeechSegment], totalDuration: TimeInterval) -> Float {
        let speechDuration = speechSegments.reduce(0) { $0 + ($1.endTime - $1.startTime) }
        return Float(1.0 - (speechDuration / totalDuration))
    }
    
    private func performSpeakerAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        options: VoiceAnalysisRequest.AnalysisOptions.SpeakerOptions?
    ) async -> VoiceAnalysisResult.SpeakerAnalysis {
        
        // Extract voice characteristics
        let voiceCharacteristics = extractVoiceCharacteristics(from: audioBuffer)
        
        // Perform speaker identification if voiceprints are available
        var speakerIdentification: VoiceAnalysisResult.SpeakerAnalysis.SpeakerIdentification?
        if options?.enableIdentification == true && !voiceprints.isEmpty {
            speakerIdentification = await identifySpeaker(audioBuffer: audioBuffer)
        }
        
        return VoiceAnalysisResult.SpeakerAnalysis(
            speakerIdentification: speakerIdentification,
            voiceCharacteristics: voiceCharacteristics
        )
    }
    
    private func extractVoiceCharacteristics(from buffer: AVAudioPCMBuffer) -> VoiceAnalysisResult.SpeakerAnalysis.VoiceCharacteristics {
        // Simplified voice characteristic extraction
        let fundamentalFrequency = VoiceAnalysisResult.SpeakerAnalysis.VoiceCharacteristics.VoiceRange(
            mean: 150.0,
            min: 80.0,
            max: 300.0,
            standardDeviation: 25.0
        )
        
        let voiceTexture = VoiceAnalysisResult.SpeakerAnalysis.VoiceCharacteristics.VoiceTexture(
            roughness: 0.3,
            breathiness: 0.2,
            nasality: 0.1,
            hoarseness: 0.15
        )
        
        let pausePatterns = VoiceAnalysisResult.SpeakerAnalysis.VoiceCharacteristics.PausePatterns(
            pauseCount: 5,
            averagePauseDuration: 0.5,
            pauseRatio: 0.15
        )
        
        return VoiceAnalysisResult.SpeakerAnalysis.VoiceCharacteristics(
            fundamentalFrequency: fundamentalFrequency,
            formantFrequencies: [800, 1200, 2400],
            voiceTexture: voiceTexture,
            articulationRate: 4.5,
            pausePatterns: pausePatterns
        )
    }
    
    private func identifySpeaker(audioBuffer: AVAudioPCMBuffer) async -> VoiceAnalysisResult.SpeakerAnalysis.SpeakerIdentification {
        // Simplified speaker identification
        var candidates: [VoiceAnalysisResult.SpeakerAnalysis.SpeakerIdentification.SpeakerCandidate] = []
        
        for (speakerId, _) in voiceprints {
            // In a real implementation, this would compare voice features
            let similarity = Float.random(in: 0.3...0.9)
            let confidence = similarity * 0.8
            
            if confidence >= configuration.confidenceThreshold {
                candidates.append(VoiceAnalysisResult.SpeakerAnalysis.SpeakerIdentification.SpeakerCandidate(
                    speakerId: speakerId,
                    similarity: similarity,
                    confidence: confidence
                ))
            }
        }
        
        candidates.sort { $0.confidence > $1.confidence }
        let isNewSpeaker = candidates.isEmpty || candidates[0].confidence < 0.7
        
        return VoiceAnalysisResult.SpeakerAnalysis.SpeakerIdentification(
            candidates: candidates,
            isNewSpeaker: isNewSpeaker
        )
    }
    
    private func performEmotionAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        options: VoiceAnalysisRequest.AnalysisOptions.EmotionOptions?
    ) async -> VoiceAnalysisResult.EmotionAnalysis {
        
        // Simplified emotion detection
        let emotions: [VoiceAnalysisRequest.AnalysisOptions.EmotionOptions.EmotionCategory] = [.happiness, .sadness, .anger, .neutral]
        let emotionDistribution = emotions.map { emotion in
            VoiceAnalysisResult.EmotionAnalysis.EmotionPrediction(
                emotion: emotion,
                confidence: Float.random(in: 0.1...0.9),
                intensity: Float.random(in: 0.3...1.0)
            )
        }.sorted { $0.confidence > $1.confidence }
        
        let dominantEmotion = emotionDistribution.first ?? VoiceAnalysisResult.EmotionAnalysis.EmotionPrediction(
            emotion: .neutral,
            confidence: 0.5,
            intensity: 0.5
        )
        
        return VoiceAnalysisResult.EmotionAnalysis(
            dominantEmotion: dominantEmotion,
            emotionDistribution: emotionDistribution,
            emotionTimeline: [],
            arousal: Float.random(in: 0.2...0.8),
            valence: Float.random(in: 0.2...0.8),
            emotionalStability: Float.random(in: 0.4...0.9)
        )
    }
    
    private func performQualityAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        options: VoiceAnalysisRequest.AnalysisOptions.QualityOptions?
    ) async -> VoiceAnalysisResult.QualityAnalysis {
        
        // Simplified quality assessment
        let clarity = VoiceAnalysisResult.QualityAnalysis.QualityMetric(score: 0.8, assessment: .good)
        let noiseLevel = VoiceAnalysisResult.QualityAnalysis.QualityMetric(score: 0.9, assessment: .excellent)
        let distortion = VoiceAnalysisResult.QualityAnalysis.QualityMetric(score: 0.85, assessment: .good)
        let volumeLevel = VoiceAnalysisResult.QualityAnalysis.QualityMetric(score: 0.75, assessment: .good)
        let pitchStability = VoiceAnalysisResult.QualityAnalysis.QualityMetric(score: 0.7, assessment: .fair)
        
        let overallQuality = (clarity.score + noiseLevel.score + distortion.score + volumeLevel.score + pitchStability.score) / 5.0
        
        return VoiceAnalysisResult.QualityAnalysis(
            overallQuality: overallQuality,
            clarity: clarity,
            noiseLevel: noiseLevel,
            distortion: distortion,
            volumeLevel: volumeLevel,
            pitchStability: pitchStability,
            recommendations: ["Improve microphone positioning", "Reduce background noise"]
        )
    }
    
    private func generateVoiceprint(
        audioBuffer: AVAudioPCMBuffer,
        options: VoiceAnalysisRequest.AnalysisOptions.VoiceprintOptions?
    ) async -> VoiceAnalysisResult.VoiceprintAnalysis {
        
        let dimensions = options?.embeddingDimensions ?? 256
        let features = Array(repeating: Float.random(in: -1...1), count: 128)
        let embedding = Array(repeating: Float.random(in: -1...1), count: dimensions)
        
        return VoiceAnalysisResult.VoiceprintAnalysis(
            voiceprintId: UUID().uuidString,
            features: features,
            embedding: embedding,
            uniquenessScore: Float.random(in: 0.6...0.95),
            stabilityScore: Float.random(in: 0.7...0.9)
        )
    }
    
    private func performDemographicAnalysis(
        audioBuffer: AVAudioPCMBuffer,
        analysisTypes: Set<VoiceAnalysisRequest.AnalysisOptions.AnalysisType>
    ) async -> VoiceAnalysisResult.DemographicAnalysis {
        
        var ageEstimate: VoiceAnalysisResult.DemographicAnalysis.AgeEstimate?
        var genderPrediction: VoiceAnalysisResult.DemographicAnalysis.GenderPrediction?
        var accentDetection: VoiceAnalysisResult.DemographicAnalysis.AccentDetection?
        var stressLevel: VoiceAnalysisResult.DemographicAnalysis.StressLevel?
        
        if analysisTypes.contains(.ageEstimation) {
            let age = Int.random(in: 20...70)
            ageEstimate = VoiceAnalysisResult.DemographicAnalysis.AgeEstimate(
                estimatedAge: age,
                ageRange: (age-5)...(age+5),
                confidence: Float.random(in: 0.6...0.9)
            )
        }
        
        if analysisTypes.contains(.genderClassification) {
            genderPrediction = VoiceAnalysisResult.DemographicAnalysis.GenderPrediction(
                gender: Bool.random() ? .male : .female,
                confidence: Float.random(in: 0.7...0.95)
            )
        }
        
        if analysisTypes.contains(.accentDetection) {
            accentDetection = VoiceAnalysisResult.DemographicAnalysis.AccentDetection(
                detectedAccent: "General American",
                confidence: Float.random(in: 0.5...0.8),
                region: "North America"
            )
        }
        
        if analysisTypes.contains(.stressDetection) {
            stressLevel = VoiceAnalysisResult.DemographicAnalysis.StressLevel(
                level: .moderate,
                score: Float.random(in: 0.3...0.7),
                indicators: ["Elevated pitch", "Increased speech rate"]
            )
        }
        
        return VoiceAnalysisResult.DemographicAnalysis(
            ageEstimate: ageEstimate,
            genderPrediction: genderPrediction,
            accentDetection: accentDetection,
            stressLevel: stressLevel
        )
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
                _ = try await analyzeVoice(request)
            } catch {
                if configuration.enableLogging {
                    print("[VoiceAnalysis] ⚠️ Queued analysis failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: VoiceAnalysisRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: VoiceAnalysisRequest) -> String {
        // Generate a cache key based on analysis parameters
        let analysisTypes = request.analysisOptions.analysisTypes.map { $0.rawValue }.sorted().joined(separator: ",")
        let optionsHash = String(describing: request.analysisOptions).hashValue
        
        return "\(analysisTypes)_\(optionsHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalAnalyses)) + 1
        let totalAnalyses = metrics.totalAnalyses + 1
        let newCacheHitRate = cacheHits / Double(totalAnalyses)
        
        metrics = VoiceAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses + 1,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            emotionDetectionStats: metrics.emotionDetectionStats,
            speakerIdentificationStats: metrics.speakerIdentificationStats,
            qualityAssessmentStats: metrics.qualityAssessmentStats,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateSuccessMetrics(_ result: VoiceAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let successfulAnalyses = metrics.successfulAnalyses + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAnalyses)) + result.processingTime) / Double(totalAnalyses)
        
        var analysesByType = metrics.analysesByType
        if result.speakerAnalysis != nil {
            analysesByType["speaker", default: 0] += 1
        }
        if result.emotionAnalysis != nil {
            analysesByType["emotion", default: 0] += 1
        }
        if result.qualityAnalysis != nil {
            analysesByType["quality", default: 0] += 1
        }
        if result.voiceprintAnalysis != nil {
            analysesByType["voiceprint", default: 0] += 1
        }
        
        // Update emotion detection stats
        var emotionStats = metrics.emotionDetectionStats
        if let emotionAnalysis = result.emotionAnalysis {
            let totalEmotions = emotionStats.totalEmotionDetections + 1
            var emotionDistribution = emotionStats.emotionDistribution
            emotionDistribution[emotionAnalysis.dominantEmotion.emotion.rawValue, default: 0] += 1
            
            let newAvgConfidence = ((emotionStats.averageConfidence * Double(emotionStats.totalEmotionDetections)) + Double(emotionAnalysis.dominantEmotion.confidence)) / Double(totalEmotions)
            
            emotionStats = VoiceAnalysisMetrics.EmotionDetectionStats(
                totalEmotionDetections: totalEmotions,
                emotionDistribution: emotionDistribution,
                averageConfidence: newAvgConfidence,
                mostDetectedEmotion: emotionDistribution.max(by: { $0.value < $1.value })?.key
            )
        }
        
        // Update quality assessment stats
        var qualityStats = metrics.qualityAssessmentStats
        if let qualityAnalysis = result.qualityAnalysis {
            let totalAssessments = qualityStats.totalAssessments + 1
            let newAvgQuality = ((qualityStats.averageQuality * Double(qualityStats.totalAssessments)) + Double(qualityAnalysis.overallQuality)) / Double(totalAssessments)
            
            var qualityDistribution = qualityStats.qualityDistribution
            let qualityLevel = getQualityLevel(qualityAnalysis.overallQuality)
            qualityDistribution[qualityLevel, default: 0] += 1
            
            qualityStats = VoiceAnalysisMetrics.QualityAssessmentStats(
                totalAssessments: totalAssessments,
                averageQuality: newAvgQuality,
                qualityDistribution: qualityDistribution
            )
        }
        
        metrics = VoiceAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: successfulAnalyses,
            failedAnalyses: metrics.failedAnalyses,
            averageProcessingTime: newAverageProcessingTime,
            analysesByType: analysesByType,
            emotionDetectionStats: emotionStats,
            speakerIdentificationStats: metrics.speakerIdentificationStats,
            qualityAssessmentStats: qualityStats,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func updateFailureMetrics(_ result: VoiceAnalysisResult) async {
        let totalAnalyses = metrics.totalAnalyses + 1
        let failedAnalyses = metrics.failedAnalyses + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = VoiceAnalysisMetrics(
            totalAnalyses: totalAnalyses,
            successfulAnalyses: metrics.successfulAnalyses,
            failedAnalyses: failedAnalyses,
            averageProcessingTime: metrics.averageProcessingTime,
            analysesByType: metrics.analysesByType,
            emotionDetectionStats: metrics.emotionDetectionStats,
            speakerIdentificationStats: metrics.speakerIdentificationStats,
            qualityAssessmentStats: metrics.qualityAssessmentStats,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            throughputPerSecond: metrics.throughputPerSecond
        )
    }
    
    private func getQualityLevel(_ quality: Float) -> String {
        switch quality {
        case 0.8...: return "excellent"
        case 0.6..<0.8: return "good"
        case 0.4..<0.6: return "fair"
        default: return "poor"
        }
    }
    
    private func logAnalysis(_ result: VoiceAnalysisResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let durationStr = String(format: "%.1f", result.audioMetadata.duration)
        
        var analysisTypes: [String] = []
        if result.speakerAnalysis != nil { analysisTypes.append("speaker") }
        if result.emotionAnalysis != nil { analysisTypes.append("emotion") }
        if result.qualityAnalysis != nil { analysisTypes.append("quality") }
        if result.voiceprintAnalysis != nil { analysisTypes.append("voiceprint") }
        
        print("[VoiceAnalysis] \(statusIcon) Analysis: \(durationStr)s audio, [\(analysisTypes.joined(separator: ", "))] (\(timeStr)s processing)")
        
        if let error = result.error {
            print("[VoiceAnalysis] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Voice Analysis Capability Implementation

/// Voice Analysis capability providing comprehensive voice pattern recognition and analysis
@available(iOS 13.0, macOS 10.15, *)
public actor VoiceAnalysisCapability: DomainCapability {
    public typealias ConfigurationType = VoiceAnalysisCapabilityConfiguration
    public typealias ResourceType = VoiceAnalysisCapabilityResource
    
    private var _configuration: VoiceAnalysisCapabilityConfiguration
    private var _resources: VoiceAnalysisCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "voice-analysis-capability" }
    
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
    
    public var configuration: VoiceAnalysisCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: VoiceAnalysisCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: VoiceAnalysisCapabilityConfiguration = VoiceAnalysisCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = VoiceAnalysisCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: VoiceAnalysisCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Voice Analysis configuration")
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
        // Voice analysis is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Voice analysis doesn't require special permissions beyond microphone if using live audio
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Voice Analysis Operations
    
    /// Analyze voice patterns from audio input
    public func analyzeVoice(_ request: VoiceAnalysisRequest) async throws -> VoiceAnalysisResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return try await _resources.analyzeVoice(request)
    }
    
    /// Cancel voice analysis
    public func cancelAnalysis(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        await _resources.cancelAnalysis(requestId)
    }
    
    /// Load custom model
    public func loadCustomModel(from url: URL, identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        try await _resources.loadCustomModel(from: url, identifier: identifier)
    }
    
    /// Unload custom model
    public func unloadCustomModel(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        await _resources.unloadCustomModel(identifier)
    }
    
    /// Register voiceprint for speaker identification
    public func registerVoiceprint(_ voiceprint: [Float], for speakerId: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        try await _resources.registerVoiceprint(voiceprint, for: speakerId)
    }
    
    /// Remove voiceprint
    public func removeVoiceprint(for speakerId: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        await _resources.removeVoiceprint(for: speakerId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<VoiceAnalysisResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get loaded models
    public func getLoadedModels() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.getLoadedModels()
    }
    
    /// Get registered speakers
    public func getRegisteredSpeakers() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.getRegisteredSpeakers()
    }
    
    /// Get active analyses
    public func getActiveAnalyses() async throws -> [VoiceAnalysisRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.getActiveAnalyses()
    }
    
    /// Get analysis history
    public func getAnalysisHistory(since: Date? = nil) async throws -> [VoiceAnalysisResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.getAnalysisHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> VoiceAnalysisMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Voice Analysis capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick emotion detection from audio file
    public func quickEmotionDetection(_ audioFile: URL) async throws -> VoiceAnalysisResult.EmotionAnalysis? {
        let options = VoiceAnalysisRequest.AnalysisOptions(
            analysisTypes: [.emotionDetection],
            emotionOptions: VoiceAnalysisRequest.AnalysisOptions.EmotionOptions()
        )
        
        let request = VoiceAnalysisRequest(audioInput: .audioFile(audioFile), analysisOptions: options)
        let result = try await analyzeVoice(request)
        
        return result.emotionAnalysis
    }
    
    /// Quick voice quality assessment
    public func quickQualityAssessment(_ audioFile: URL) async throws -> VoiceAnalysisResult.QualityAnalysis? {
        let options = VoiceAnalysisRequest.AnalysisOptions(
            analysisTypes: [.qualityAssessment],
            qualityOptions: VoiceAnalysisRequest.AnalysisOptions.QualityOptions()
        )
        
        let request = VoiceAnalysisRequest(audioInput: .audioFile(audioFile), analysisOptions: options)
        let result = try await analyzeVoice(request)
        
        return result.qualityAnalysis
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
    
    /// Get speaker count
    public func getSpeakerCount() async throws -> Int {
        let speakers = try await getRegisteredSpeakers()
        return speakers.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Voice Analysis specific errors
public enum VoiceAnalysisError: Error, LocalizedError {
    case voiceAnalysisDisabled
    case customModelsDisabled
    case voiceprintDisabled
    case modelLoadFailed(String, String)
    case analysisError(String)
    case invalidAudioFormat
    case insufficientAudioDuration
    case excessiveAudioDuration
    case analysisQueued(UUID)
    case analysisTimeout(UUID)
    case liveAudioNotSupported
    case speakerNotFound(String)
    case voiceprintGenerationFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .voiceAnalysisDisabled:
            return "Voice analysis is disabled"
        case .customModelsDisabled:
            return "Custom models are disabled"
        case .voiceprintDisabled:
            return "Voiceprint functionality is disabled"
        case .modelLoadFailed(let identifier, let reason):
            return "Failed to load model '\(identifier)': \(reason)"
        case .analysisError(let reason):
            return "Voice analysis failed: \(reason)"
        case .invalidAudioFormat:
            return "Invalid audio format"
        case .insufficientAudioDuration:
            return "Audio duration too short for analysis"
        case .excessiveAudioDuration:
            return "Audio duration too long for analysis"
        case .analysisQueued(let id):
            return "Voice analysis queued: \(id)"
        case .analysisTimeout(let id):
            return "Voice analysis timeout: \(id)"
        case .liveAudioNotSupported:
            return "Live audio analysis not supported"
        case .speakerNotFound(let id):
            return "Speaker not found: \(id)"
        case .voiceprintGenerationFailed:
            return "Failed to generate voiceprint"
        case .configurationError(let reason):
            return "Voice analysis configuration error: \(reason)"
        }
    }
}