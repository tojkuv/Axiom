import Foundation

public struct Document: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let fileName: String
    public let filePath: String
    public let fileType: DocumentType
    public let fileSize: Int64
    public let createdDate: Date
    public let modifiedDate: Date
    public let tags: [String]
    public let extractedText: String?
    public let metadata: [String: String]
    public let isProcessed: Bool
    public let associatedTaskIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        fileType: DocumentType,
        fileSize: Int64,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        tags: [String] = [],
        extractedText: String? = nil,
        metadata: [String: String] = [:],
        isProcessed: Bool = false,
        associatedTaskIds: [UUID] = []
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.fileType = fileType
        self.fileSize = fileSize
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.tags = tags
        self.extractedText = extractedText
        self.metadata = metadata
        self.isProcessed = isProcessed
        self.associatedTaskIds = associatedTaskIds
    }
}

public enum DocumentType: String, CaseIterable, Codable, Hashable, Sendable {
    case pdf = "pdf"
    case text = "text"
    case word = "word"
    case excel = "excel"
    case powerpoint = "powerpoint"
    case image = "image"
    case audio = "audio"
    case video = "video"
    case archive = "archive"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .text: return "Text"
        case .word: return "Word Document"
        case .excel: return "Excel Spreadsheet"
        case .powerpoint: return "PowerPoint Presentation"
        case .image: return "Image"
        case .audio: return "Audio"
        case .video: return "Video"
        case .archive: return "Archive"
        case .other: return "Other"
        }
    }
}

public struct Photo: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let localIdentifier: String?
    public let fileName: String?
    public let filePath: String
    public let width: Int
    public let height: Int
    public let fileSize: Int64
    public let creationDate: Date
    public let modificationDate: Date?
    public let location: LocationData?
    public let isFavorite: Bool
    public let tags: [String]
    public let extractedText: String?
    public let classifications: [ImageClassification]
    public let detectedObjects: [DetectedObject]
    public let associatedTaskIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        localIdentifier: String? = nil,
        fileName: String? = nil,
        filePath: String,
        width: Int,
        height: Int,
        fileSize: Int64,
        creationDate: Date = Date(),
        modificationDate: Date? = nil,
        location: LocationData? = nil,
        isFavorite: Bool = false,
        tags: [String] = [],
        extractedText: String? = nil,
        classifications: [ImageClassification] = [],
        detectedObjects: [DetectedObject] = [],
        associatedTaskIds: [UUID] = []
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.fileName = fileName
        self.filePath = filePath
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.location = location
        self.isFavorite = isFavorite
        self.tags = tags
        self.extractedText = extractedText
        self.classifications = classifications
        self.detectedObjects = detectedObjects
        self.associatedTaskIds = associatedTaskIds
    }
}

public struct AudioFile: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let fileName: String
    public let filePath: String
    public let duration: TimeInterval
    public let fileSize: Int64
    public let format: AudioFormat
    public let sampleRate: Double?
    public let bitRate: Int?
    public let createdDate: Date
    public let tags: [String]
    public let transcription: SpeechRecognitionResult?
    public let associatedTaskIds: [UUID]
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        duration: TimeInterval,
        fileSize: Int64,
        format: AudioFormat,
        sampleRate: Double? = nil,
        bitRate: Int? = nil,
        createdDate: Date = Date(),
        tags: [String] = [],
        transcription: SpeechRecognitionResult? = nil,
        associatedTaskIds: [UUID] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.duration = duration
        self.fileSize = fileSize
        self.format = format
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.createdDate = createdDate
        self.tags = tags
        self.transcription = transcription
        self.associatedTaskIds = associatedTaskIds
        self.metadata = metadata
    }
}

public enum AudioFormat: String, CaseIterable, Codable, Hashable, Sendable {
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"
    case m4a = "m4a"
    case flac = "flac"
    case other = "other"
    
    public var displayName: String {
        return rawValue.uppercased()
    }
}

public struct ProcessingQueue: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let queueType: ProcessingQueueType
    public let items: [ProcessingItem]
    public let status: ProcessingStatus
    public let progress: Double
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        name: String,
        queueType: ProcessingQueueType,
        items: [ProcessingItem] = [],
        status: ProcessingStatus = .idle,
        progress: Double = 0.0,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.id = id
        self.name = name
        self.queueType = queueType
        self.items = items
        self.status = status
        self.progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

public enum ProcessingQueueType: String, CaseIterable, Codable, Hashable, Sendable {
    case imageProcessing = "imageProcessing"
    case textAnalysis = "textAnalysis"
    case speechRecognition = "speechRecognition"
    case documentProcessing = "documentProcessing"
    case mlInference = "mlInference"
    
    public var displayName: String {
        switch self {
        case .imageProcessing: return "Image Processing"
        case .textAnalysis: return "Text Analysis"
        case .speechRecognition: return "Speech Recognition"
        case .documentProcessing: return "Document Processing"
        case .mlInference: return "ML Inference"
        }
    }
}

public struct ProcessingItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let sourceId: UUID
    public let processingType: ProcessingType
    public let status: ProcessingItemStatus
    public let progress: Double
    public let createdDate: Date
    public let startedDate: Date?
    public let completedDate: Date?
    public let error: String?
    
    public init(
        id: UUID = UUID(),
        sourceId: UUID,
        processingType: ProcessingType,
        status: ProcessingItemStatus = .pending,
        progress: Double = 0.0,
        createdDate: Date = Date(),
        startedDate: Date? = nil,
        completedDate: Date? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.sourceId = sourceId
        self.processingType = processingType
        self.status = status
        self.progress = progress
        self.createdDate = createdDate
        self.startedDate = startedDate
        self.completedDate = completedDate
        self.error = error
    }
}

public enum ProcessingType: String, CaseIterable, Codable, Hashable, Sendable {
    case imageClassification = "imageClassification"
    case textExtraction = "textExtraction"
    case speechTranscription = "speechTranscription"
    case documentIndexing = "documentIndexing"
    case mlAnalysis = "mlAnalysis"
    
    public var displayName: String {
        switch self {
        case .imageClassification: return "Image Classification"
        case .textExtraction: return "Text Extraction"
        case .speechTranscription: return "Speech Transcription"
        case .documentIndexing: return "Document Indexing"
        case .mlAnalysis: return "ML Analysis"
        }
    }
}

public enum ProcessingItemStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public enum ProcessingStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case idle = "idle"
    case processing = "processing"
    case paused = "paused"
    case completed = "completed"
    case error = "error"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}