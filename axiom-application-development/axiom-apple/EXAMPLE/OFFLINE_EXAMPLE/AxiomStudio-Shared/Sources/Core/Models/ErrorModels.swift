import Foundation

public enum PersonalInfoError: Error, Codable, Equatable, Hashable, Sendable {
    case taskNotFound(UUID)
    case invalidTaskData
    case calendarAccessDenied
    case contactsAccessDenied
    case eventKitNotAvailable
    case contactsNotAvailable
    case storageError(String)
    case networkError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .taskNotFound(let id):
            return "Task with ID \(id) not found"
        case .invalidTaskData:
            return "Invalid task data provided"
        case .calendarAccessDenied:
            return "Calendar access denied. Please enable access in Settings."
        case .contactsAccessDenied:
            return "Contacts access denied. Please enable access in Settings."
        case .eventKitNotAvailable:
            return "EventKit is not available on this device"
        case .contactsNotAvailable:
            return "Contacts framework is not available on this device"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .taskNotFound:
            return .refresh
        case .invalidTaskData:
            return .userInput
        case .calendarAccessDenied, .contactsAccessDenied:
            return .requestPermission
        case .eventKitNotAvailable, .contactsNotAvailable:
            return .disable
        case .storageError:
            return .retry
        case .networkError:
            return .offline
        case .unknown:
            return .report
        }
    }
}

public enum HealthLocationError: Error, Codable, Equatable, Hashable, Sendable {
    case healthKitNotAvailable
    case healthAccessDenied
    case locationAccessDenied
    case locationNotAvailable
    case healthDataNotFound
    case locationDataNotFound
    case invalidHealthData
    case invalidLocationData
    case storageError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .healthAccessDenied:
            return "Health access denied. Please enable access in Settings."
        case .locationAccessDenied:
            return "Location access denied. Please enable access in Settings."
        case .locationNotAvailable:
            return "Location services are not available"
        case .healthDataNotFound:
            return "No health data found"
        case .locationDataNotFound:
            return "No location data found"
        case .invalidHealthData:
            return "Invalid health data received"
        case .invalidLocationData:
            return "Invalid location data received"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .healthKitNotAvailable, .locationNotAvailable:
            return .disable
        case .healthAccessDenied, .locationAccessDenied:
            return .requestPermission
        case .healthDataNotFound, .locationDataNotFound:
            return .refresh
        case .invalidHealthData, .invalidLocationData:
            return .validate
        case .storageError:
            return .retry
        case .unknown:
            return .report
        }
    }
}

public enum ContentProcessorError: Error, Codable, Equatable, Hashable, Sendable {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case processingFailed(String)
    case invalidInput
    case insufficientMemory
    case processingTimeout
    case storageError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .modelNotFound(let name):
            return "Model '\(name)' not found"
        case .modelLoadFailed(let name):
            return "Failed to load model '\(name)'"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .invalidInput:
            return "Invalid input provided for processing"
        case .insufficientMemory:
            return "Insufficient memory for processing"
        case .processingTimeout:
            return "Processing operation timed out"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .modelNotFound:
            return .download
        case .modelLoadFailed:
            return .retry
        case .processingFailed:
            return .reduce
        case .invalidInput:
            return .userInput
        case .insufficientMemory:
            return .reduce
        case .processingTimeout:
            return .retry
        case .storageError:
            return .retry
        case .unknown:
            return .report
        }
    }
}

public enum MediaHubError: Error, Codable, Equatable, Hashable, Sendable {
    case fileNotFound(String)
    case fileAccessDenied(String)
    case unsupportedFileType(String)
    case photoLibraryAccessDenied
    case audioAccessDenied
    case processingFailed(String)
    case storageError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .fileAccessDenied(let path):
            return "Access denied for file: \(path)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .photoLibraryAccessDenied:
            return "Photo library access denied. Please enable access in Settings."
        case .audioAccessDenied:
            return "Audio access denied. Please enable access in Settings."
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .fileNotFound:
            return .refresh
        case .fileAccessDenied:
            return .requestPermission
        case .unsupportedFileType:
            return .convert
        case .photoLibraryAccessDenied, .audioAccessDenied:
            return .requestPermission
        case .processingFailed:
            return .retry
        case .storageError:
            return .retry
        case .unknown:
            return .report
        }
    }
}

public enum PerformanceError: Error, Codable, Equatable, Hashable, Sendable {
    case memoryMonitoringFailed
    case metricCollectionFailed(String)
    case capabilityStatusUnavailable
    case systemInfoUnavailable
    case storageError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .memoryMonitoringFailed:
            return "Memory monitoring failed"
        case .metricCollectionFailed(let metric):
            return "Failed to collect metric: \(metric)"
        case .capabilityStatusUnavailable:
            return "Capability status unavailable"
        case .systemInfoUnavailable:
            return "System information unavailable"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .memoryMonitoringFailed:
            return .restart
        case .metricCollectionFailed:
            return .retry
        case .capabilityStatusUnavailable:
            return .refresh
        case .systemInfoUnavailable:
            return .refresh
        case .storageError:
            return .retry
        case .unknown:
            return .report
        }
    }
}

public enum ErrorRecoveryStrategy: String, CaseIterable, Codable, Sendable {
    case retry = "retry"
    case refresh = "refresh"
    case restart = "restart"
    case requestPermission = "requestPermission"
    case userInput = "userInput"
    case validate = "validate"
    case reduce = "reduce"
    case convert = "convert"
    case download = "download"
    case disable = "disable"
    case offline = "offline"
    case report = "report"
    
    public var displayName: String {
        switch self {
        case .retry: return "Retry"
        case .refresh: return "Refresh"
        case .restart: return "Restart"
        case .requestPermission: return "Request Permission"
        case .userInput: return "Check Input"
        case .validate: return "Validate Data"
        case .reduce: return "Reduce Quality"
        case .convert: return "Convert Format"
        case .download: return "Download"
        case .disable: return "Disable Feature"
        case .offline: return "Use Offline Mode"
        case .report: return "Report Issue"
        }
    }
    
    public var description: String {
        switch self {
        case .retry: return "Try the operation again"
        case .refresh: return "Refresh the data"
        case .restart: return "Restart the application"
        case .requestPermission: return "Grant required permissions in Settings"
        case .userInput: return "Check and correct the input data"
        case .validate: return "Validate the data format"
        case .reduce: return "Reduce processing requirements"
        case .convert: return "Convert to a supported format"
        case .download: return "Download required resources"
        case .disable: return "Disable this feature"
        case .offline: return "Continue in offline mode"
        case .report: return "Report this issue to support"
        }
    }
}