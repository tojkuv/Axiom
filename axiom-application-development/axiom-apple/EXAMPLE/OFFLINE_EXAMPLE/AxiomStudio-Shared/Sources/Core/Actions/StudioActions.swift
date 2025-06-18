import Foundation
import AxiomCore
import AxiomArchitecture

@AxiomAction
public enum StudioAction {
    case personalInfo(PersonalInfoAction)
    case healthLocation(HealthLocationAction)
    case contentProcessor(ContentProcessorAction)
    case mediaHub(MediaHubAction)
    case performance(PerformanceAction)
    case navigation(NavigationAction)
}

@AxiomAction
public enum PersonalInfoAction {
    case loadTasks
    case createTask(StudioTask)
    case updateTask(StudioTask)
    case deleteTask(UUID)
    case toggleTaskComplete(UUID)
    case loadCalendarEvents
    case createCalendarEvent(CalendarEvent)
    case loadContacts
    case createContact(Contact)
    case updateContact(Contact)
    case linkTaskToContact(taskId: UUID, contactId: UUID)
    case linkTaskToEvent(taskId: UUID, eventId: String)
    case setError(PersonalInfoError?)
    case setLoading(Bool)
}

@AxiomAction
public enum HealthLocationAction {
    case loadHealthMetrics
    case loadLocationData
    case loadMovementPatterns
    case requestHealthPermission
    case requestLocationPermission
    case startLocationTracking
    case stopLocationTracking
    case addHealthMetric(HealthMetric)
    case addLocationData(LocationData)
    case addMovementPattern(MovementPattern)
    case setHealthAvailable(Bool)
    case setLocationAvailable(Bool)
    case setError(HealthLocationError?)
}

@AxiomAction
public enum ContentProcessorAction {
    case loadMLModels
    case loadMLModel(String)
    case unloadMLModel(String)
    case processText(String, TextAnalysisType)
    case processImage(UUID, ImageProcessingType)
    case processAudio(UUID)
    case addTextAnalysisResult(TextAnalysisResult)
    case addImageProcessingResult(ImageProcessingResult)
    case addSpeechRecognitionResult(SpeechRecognitionResult)
    case setProcessing(Bool)
    case setError(ContentProcessorError?)
}

@AxiomAction
public enum MediaHubAction {
    case loadDocuments
    case loadPhotos
    case loadAudioFiles
    case importDocument(URL)
    case importPhoto(URL)
    case recordAudio
    case stopRecording
    case processDocument(UUID)
    case processPhoto(UUID)
    case processAudio(UUID)
    case addDocument(Document)
    case addPhoto(Photo)
    case addAudioFile(AudioFile)
    case updateProcessingQueue(ProcessingQueue)
    case setProcessing(Bool)
    case setError(MediaHubError?)
}

@AxiomAction
public enum PerformanceAction {
    case startMonitoring
    case stopMonitoring
    case updateMemoryUsage(MemoryUsage)
    case addPerformanceMetric(PerformanceMetric)
    case updateCapabilityStatus(CapabilityStatus)
    case updateBatteryImpact(BatteryImpact)
    case updateThermalState(ThermalState)
    case setError(PerformanceError?)
}

@AxiomAction
public enum NavigationAction {
    case navigate(StudioRoute)
    case goBack
    case setDeepLinkingContext(DeepLinkingContext)
    case clearDeepLinkingContext
    case recordTransition(RouteTransition)
}