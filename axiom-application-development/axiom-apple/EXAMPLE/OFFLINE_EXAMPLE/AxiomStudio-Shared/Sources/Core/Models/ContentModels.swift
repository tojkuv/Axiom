import Foundation

public struct MLModel: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let modelType: MLModelType
    public let filePath: String
    public let isLoaded: Bool
    public let accuracy: Double?
    public let lastTrainingDate: Date?
    public let version: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        modelType: MLModelType,
        filePath: String,
        isLoaded: Bool = false,
        accuracy: Double? = nil,
        lastTrainingDate: Date? = nil,
        version: String = "1.0"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.modelType = modelType
        self.filePath = filePath
        self.isLoaded = isLoaded
        self.accuracy = accuracy
        self.lastTrainingDate = lastTrainingDate
        self.version = version
    }
}

public enum MLModelType: String, CaseIterable, Codable, Hashable, Sendable {
    case textClassification = "textClassification"
    case sentimentAnalysis = "sentimentAnalysis"
    case imageClassification = "imageClassification"
    case objectDetection = "objectDetection"
    case speechRecognition = "speechRecognition"
    case naturalLanguageProcessing = "naturalLanguageProcessing"
    
    public var displayName: String {
        switch self {
        case .textClassification: return "Text Classification"
        case .sentimentAnalysis: return "Sentiment Analysis"
        case .imageClassification: return "Image Classification"
        case .objectDetection: return "Object Detection"
        case .speechRecognition: return "Speech Recognition"
        case .naturalLanguageProcessing: return "Natural Language Processing"
        }
    }
}

public struct TextAnalysisResult: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let sourceText: String
    public let analysisType: TextAnalysisType
    public let results: [String: Double]
    public let entities: [NamedEntity]
    public let sentiment: SentimentResult?
    public let language: String?
    public let confidence: Double
    public let processingDate: Date
    
    public init(
        id: UUID = UUID(),
        sourceText: String,
        analysisType: TextAnalysisType,
        results: [String: Double] = [:],
        entities: [NamedEntity] = [],
        sentiment: SentimentResult? = nil,
        language: String? = nil,
        confidence: Double,
        processingDate: Date = Date()
    ) {
        self.id = id
        self.sourceText = sourceText
        self.analysisType = analysisType
        self.results = results
        self.entities = entities
        self.sentiment = sentiment
        self.language = language
        self.confidence = confidence
        self.processingDate = processingDate
    }
}

public enum TextAnalysisType: String, CaseIterable, Codable, Hashable, Sendable {
    case sentiment = "sentiment"
    case entityRecognition = "entityRecognition"
    case languageDetection = "languageDetection"
    case tokenization = "tokenization"
    case partOfSpeech = "partOfSpeech"
    case keywordExtraction = "keywordExtraction"
    
    public var displayName: String {
        switch self {
        case .sentiment: return "Sentiment Analysis"
        case .entityRecognition: return "Entity Recognition"
        case .languageDetection: return "Language Detection"
        case .tokenization: return "Tokenization"
        case .partOfSpeech: return "Part of Speech"
        case .keywordExtraction: return "Keyword Extraction"
        }
    }
}

public struct NamedEntity: Codable, Equatable, Hashable, Sendable {
    public let text: String
    public let range: NSRange
    public let category: EntityCategory
    public let confidence: Double
    
    public init(text: String, range: NSRange, category: EntityCategory, confidence: Double) {
        self.text = text
        self.range = range
        self.category = category
        self.confidence = confidence
    }
}

public enum EntityCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case person = "person"
    case organization = "organization"
    case location = "location"
    case date = "date"
    case phoneNumber = "phoneNumber"
    case email = "email"
    case url = "url"
    case other = "other"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct SentimentResult: Codable, Equatable, Hashable, Sendable {
    public let sentiment: Sentiment
    public let confidence: Double
    public let positiveScore: Double
    public let negativeScore: Double
    public let neutralScore: Double
    
    public init(
        sentiment: Sentiment,
        confidence: Double,
        positiveScore: Double,
        negativeScore: Double,
        neutralScore: Double
    ) {
        self.sentiment = sentiment
        self.confidence = confidence
        self.positiveScore = positiveScore
        self.negativeScore = negativeScore
        self.neutralScore = neutralScore
    }
}

public enum Sentiment: String, CaseIterable, Codable, Hashable, Sendable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct ImageProcessingResult: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let imageId: UUID
    public let processingType: ImageProcessingType
    public let classifications: [ImageClassification]
    public let detectedObjects: [DetectedObject]
    public let extractedText: String?
    public let processingDate: Date
    public let confidence: Double
    
    public init(
        id: UUID = UUID(),
        imageId: UUID,
        processingType: ImageProcessingType,
        classifications: [ImageClassification] = [],
        detectedObjects: [DetectedObject] = [],
        extractedText: String? = nil,
        processingDate: Date = Date(),
        confidence: Double
    ) {
        self.id = id
        self.imageId = imageId
        self.processingType = processingType
        self.classifications = classifications
        self.detectedObjects = detectedObjects
        self.extractedText = extractedText
        self.processingDate = processingDate
        self.confidence = confidence
    }
}

public enum ImageProcessingType: String, CaseIterable, Codable, Hashable, Sendable {
    case classification = "classification"
    case objectDetection = "objectDetection"
    case textRecognition = "textRecognition"
    case faceDetection = "faceDetection"
    case sceneAnalysis = "sceneAnalysis"
    
    public var displayName: String {
        switch self {
        case .classification: return "Image Classification"
        case .objectDetection: return "Object Detection"
        case .textRecognition: return "Text Recognition"
        case .faceDetection: return "Face Detection"
        case .sceneAnalysis: return "Scene Analysis"
        }
    }
}

public struct ImageClassification: Codable, Equatable, Hashable, Sendable {
    public let label: String
    public let confidence: Double
    
    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

public struct DetectedObject: Codable, Equatable, Hashable, Sendable {
    public let label: String
    public let confidence: Double
    public let boundingBox: CGRect
    
    public init(label: String, confidence: Double, boundingBox: CGRect) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

public struct SpeechRecognitionResult: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let audioFileId: UUID
    public let transcribedText: String
    public let confidence: Double
    public let language: String?
    public let duration: TimeInterval
    public let segments: [SpeechSegment]
    public let processingDate: Date
    
    public init(
        id: UUID = UUID(),
        audioFileId: UUID,
        transcribedText: String,
        confidence: Double,
        language: String? = nil,
        duration: TimeInterval,
        segments: [SpeechSegment] = [],
        processingDate: Date = Date()
    ) {
        self.id = id
        self.audioFileId = audioFileId
        self.transcribedText = transcribedText
        self.confidence = confidence
        self.language = language
        self.duration = duration
        self.segments = segments
        self.processingDate = processingDate
    }
}

public struct SpeechSegment: Codable, Equatable, Hashable, Sendable {
    public let text: String
    public let startTime: TimeInterval
    public let duration: TimeInterval
    public let confidence: Double
    
    public init(text: String, startTime: TimeInterval, duration: TimeInterval, confidence: Double) {
        self.text = text
        self.startTime = startTime
        self.duration = duration
        self.confidence = confidence
    }
}