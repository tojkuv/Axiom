import Foundation

public enum StudioRoute: String, CaseIterable, Codable, Hashable, Sendable {
    case personalInfo = "personalInfo"
    case healthLocation = "healthLocation"
    case contentProcessor = "contentProcessor"
    case mediaHub = "mediaHub"
    case performance = "performance"
    case settings = "settings"
    
    // Personal Info sub-routes
    case taskList = "taskList"
    case taskDetail = "taskDetail"
    case createTask = "createTask"
    case editTask = "editTask"
    case calendarView = "calendarView"
    case contactList = "contactList"
    case contactDetail = "contactDetail"
    
    // Health Location sub-routes
    case healthDashboard = "healthDashboard"
    case locationHistory = "locationHistory"
    case movementPatterns = "movementPatterns"
    case locationSettings = "locationSettings"
    
    // Content Processor sub-routes
    case mlModels = "mlModels"
    case textAnalysis = "textAnalysis"
    case imageProcessing = "imageProcessing"
    case speechRecognition = "speechRecognition"
    
    // Media Hub sub-routes
    case documentBrowser = "documentBrowser"
    case photoLibrary = "photoLibrary"
    case audioRecordings = "audioRecordings"
    case processingQueues = "processingQueues"
    
    // Performance sub-routes
    case memoryMonitor = "memoryMonitor"
    case performanceMetrics = "performanceMetrics"
    case capabilityStatus = "capabilityStatus"
    case systemHealth = "systemHealth"
    
    public var displayName: String {
        switch self {
        case .personalInfo: return "Personal Info"
        case .healthLocation: return "Health & Location"
        case .contentProcessor: return "Content Processor"
        case .mediaHub: return "Media Hub"
        case .performance: return "Performance"
        case .settings: return "Settings"
        case .taskList: return "Tasks"
        case .taskDetail: return "Task Detail"
        case .createTask: return "Create Task"
        case .editTask: return "Edit Task"
        case .calendarView: return "Calendar"
        case .contactList: return "Contacts"
        case .contactDetail: return "Contact Detail"
        case .healthDashboard: return "Health Dashboard"
        case .locationHistory: return "Location History"
        case .movementPatterns: return "Movement Patterns"
        case .locationSettings: return "Location Settings"
        case .mlModels: return "ML Models"
        case .textAnalysis: return "Text Analysis"
        case .imageProcessing: return "Image Processing"
        case .speechRecognition: return "Speech Recognition"
        case .documentBrowser: return "Documents"
        case .photoLibrary: return "Photos"
        case .audioRecordings: return "Audio"
        case .processingQueues: return "Processing Queues"
        case .memoryMonitor: return "Memory Monitor"
        case .performanceMetrics: return "Performance Metrics"
        case .capabilityStatus: return "Capability Status"
        case .systemHealth: return "System Health"
        }
    }
    
    public var category: RouteCategory {
        switch self {
        case .personalInfo, .taskList, .taskDetail, .createTask, .editTask, .calendarView, .contactList, .contactDetail:
            return .personalInfo
        case .healthLocation, .healthDashboard, .locationHistory, .movementPatterns, .locationSettings:
            return .healthLocation
        case .contentProcessor, .mlModels, .textAnalysis, .imageProcessing, .speechRecognition:
            return .contentProcessor
        case .mediaHub, .documentBrowser, .photoLibrary, .audioRecordings, .processingQueues:
            return .mediaHub
        case .performance, .memoryMonitor, .performanceMetrics, .capabilityStatus, .systemHealth:
            return .performance
        case .settings:
            return .settings
        }
    }
    
    public var isRootRoute: Bool {
        switch self {
        case .personalInfo, .healthLocation, .contentProcessor, .mediaHub, .performance, .settings:
            return true
        default:
            return false
        }
    }
}

public enum RouteCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case personalInfo = "personalInfo"
    case healthLocation = "healthLocation"
    case contentProcessor = "contentProcessor"
    case mediaHub = "mediaHub"
    case performance = "performance"
    case settings = "settings"
    
    public var displayName: String {
        switch self {
        case .personalInfo: return "Personal Info"
        case .healthLocation: return "Health & Location"
        case .contentProcessor: return "Content Processor"
        case .mediaHub: return "Media Hub"
        case .performance: return "Performance"
        case .settings: return "Settings"
        }
    }
    
    public var rootRoute: StudioRoute {
        switch self {
        case .personalInfo: return .personalInfo
        case .healthLocation: return .healthLocation
        case .contentProcessor: return .contentProcessor
        case .mediaHub: return .mediaHub
        case .performance: return .performance
        case .settings: return .settings
        }
    }
}

public struct DeepLinkingContext: Codable, Equatable, Hashable, Sendable {
    public let sourceURL: URL?
    public let parameters: [String: String]
    public let timestamp: Date
    public let sourceApplication: String?
    
    public init(
        sourceURL: URL? = nil,
        parameters: [String: String] = [:],
        timestamp: Date = Date(),
        sourceApplication: String? = nil
    ) {
        self.sourceURL = sourceURL
        self.parameters = parameters
        self.timestamp = timestamp
        self.sourceApplication = sourceApplication
    }
}

public struct RouteTransition: Codable, Equatable, Hashable, Sendable {
    public let fromRoute: StudioRoute
    public let toRoute: StudioRoute
    public let timestamp: Date
    public let duration: TimeInterval?
    public let parameters: [String: String]
    
    public init(
        fromRoute: StudioRoute,
        toRoute: StudioRoute,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        parameters: [String: String] = [:]
    ) {
        self.fromRoute = fromRoute
        self.toRoute = toRoute
        self.timestamp = timestamp
        self.duration = duration
        self.parameters = parameters
    }
}