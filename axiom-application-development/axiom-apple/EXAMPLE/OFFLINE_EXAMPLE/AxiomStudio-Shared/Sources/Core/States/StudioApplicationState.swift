import Foundation
import AxiomCore
import AxiomArchitecture

public struct StudioApplicationState: AxiomState, Hashable, Sendable {
    public let personalInfo: PersonalInfoState
    public let healthLocation: HealthLocationState
    public let contentProcessor: ContentProcessorState
    public let mediaHub: MediaHubState
    public let performance: PerformanceState
    public let navigation: NavigationState
    
    public init(
        personalInfo: PersonalInfoState = PersonalInfoState(),
        healthLocation: HealthLocationState = HealthLocationState(),
        contentProcessor: ContentProcessorState = ContentProcessorState(),
        mediaHub: MediaHubState = MediaHubState(),
        performance: PerformanceState = PerformanceState(),
        navigation: NavigationState = NavigationState()
    ) {
        self.personalInfo = personalInfo
        self.healthLocation = healthLocation
        self.contentProcessor = contentProcessor
        self.mediaHub = mediaHub
        self.performance = performance
        self.navigation = navigation
    }
}

public struct PersonalInfoState: AxiomState, Hashable, Sendable {
    public let tasks: [StudioTask]
    public let calendarEvents: [CalendarEvent]
    public let contacts: [Contact]
    public let reminders: [Reminder]
    public let isLoading: Bool
    public let error: PersonalInfoError?
    
    public init(
        tasks: [StudioTask] = [],
        calendarEvents: [CalendarEvent] = [],
        contacts: [Contact] = [],
        reminders: [Reminder] = [],
        isLoading: Bool = false,
        error: PersonalInfoError? = nil
    ) {
        self.tasks = tasks
        self.calendarEvents = calendarEvents
        self.contacts = contacts
        self.reminders = reminders
        self.isLoading = isLoading
        self.error = error
    }
}

public struct HealthLocationState: AxiomState, Hashable, Sendable {
    public let healthMetrics: [HealthMetric]
    public let locationData: [LocationData]
    public let movementPatterns: [MovementPattern]
    public let isHealthAvailable: Bool
    public let isLocationAvailable: Bool
    public let error: HealthLocationError?
    
    public init(
        healthMetrics: [HealthMetric] = [],
        locationData: [LocationData] = [],
        movementPatterns: [MovementPattern] = [],
        isHealthAvailable: Bool = false,
        isLocationAvailable: Bool = false,
        error: HealthLocationError? = nil
    ) {
        self.healthMetrics = healthMetrics
        self.locationData = locationData
        self.movementPatterns = movementPatterns
        self.isHealthAvailable = isHealthAvailable
        self.isLocationAvailable = isLocationAvailable
        self.error = error
    }
}

public struct ContentProcessorState: AxiomState, Hashable, Sendable {
    public let mlModels: [MLModel]
    public let textAnalysisResults: [TextAnalysisResult]
    public let imageProcessingResults: [ImageProcessingResult]
    public let speechRecognitionResults: [SpeechRecognitionResult]
    public let isProcessing: Bool
    public let error: ContentProcessorError?
    
    public init(
        mlModels: [MLModel] = [],
        textAnalysisResults: [TextAnalysisResult] = [],
        imageProcessingResults: [ImageProcessingResult] = [],
        speechRecognitionResults: [SpeechRecognitionResult] = [],
        isProcessing: Bool = false,
        error: ContentProcessorError? = nil
    ) {
        self.mlModels = mlModels
        self.textAnalysisResults = textAnalysisResults
        self.imageProcessingResults = imageProcessingResults
        self.speechRecognitionResults = speechRecognitionResults
        self.isProcessing = isProcessing
        self.error = error
    }
}

public struct MediaHubState: AxiomState, Hashable, Sendable {
    public let documents: [Document]
    public let photos: [Photo]
    public let audioFiles: [AudioFile]
    public let processingQueues: [ProcessingQueue]
    public let isProcessing: Bool
    public let error: MediaHubError?
    
    public init(
        documents: [Document] = [],
        photos: [Photo] = [],
        audioFiles: [AudioFile] = [],
        processingQueues: [ProcessingQueue] = [],
        isProcessing: Bool = false,
        error: MediaHubError? = nil
    ) {
        self.documents = documents
        self.photos = photos
        self.audioFiles = audioFiles
        self.processingQueues = processingQueues
        self.isProcessing = isProcessing
        self.error = error
    }
}

public struct PerformanceState: AxiomState, Hashable, Sendable {
    public let memoryUsage: MemoryUsage
    public let performanceMetrics: [PerformanceMetric]
    public let capabilityStatus: [CapabilityStatus]
    public let batteryImpact: BatteryImpact?
    public let thermalState: ThermalState?
    public let error: PerformanceError?
    
    public init(
        memoryUsage: MemoryUsage = MemoryUsage(),
        performanceMetrics: [PerformanceMetric] = [],
        capabilityStatus: [CapabilityStatus] = [],
        batteryImpact: BatteryImpact? = nil,
        thermalState: ThermalState? = nil,
        error: PerformanceError? = nil
    ) {
        self.memoryUsage = memoryUsage
        self.performanceMetrics = performanceMetrics
        self.capabilityStatus = capabilityStatus
        self.batteryImpact = batteryImpact
        self.thermalState = thermalState
        self.error = error
    }
}

public struct NavigationState: AxiomState, Hashable, Sendable {
    public let currentRoute: StudioRoute
    public let navigationStack: [StudioRoute]
    public let deepLinkingContext: DeepLinkingContext?
    
    public init(
        currentRoute: StudioRoute = .personalInfo,
        navigationStack: [StudioRoute] = [],
        deepLinkingContext: DeepLinkingContext? = nil
    ) {
        self.currentRoute = currentRoute
        self.navigationStack = navigationStack
        self.deepLinkingContext = deepLinkingContext
    }
}