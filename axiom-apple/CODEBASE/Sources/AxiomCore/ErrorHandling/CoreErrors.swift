import Foundation

// MARK: - Unified Error Types

/// Unified error hierarchy for the Axiom framework
public enum AxiomError: Error, Codable, Equatable, Hashable {
    case contextError(AxiomContextError)
    case clientError(AxiomClientError)
    case navigationError(AxiomNavigationError)
    case persistenceError(AxiomPersistenceError)
    case validationError(AxiomValidationError)
    case capabilityError(AxiomCapabilityError)
    case actorError(AxiomActorError)
    case deviceError(AxiomDeviceError)
    case infrastructureError(AxiomInfrastructureError)
    case networkError(AxiomNetworkError)
    case unknownError
    
    /// Human-readable error description
    public var localizedDescription: String {
        switch self {
        case .contextError(let error):
            return "Context Error: \(error.localizedDescription)"
        case .clientError(let error):
            return "Client Error: \(error.localizedDescription)"
        case .navigationError(let error):
            return "Navigation Error: \(error.localizedDescription)"
        case .persistenceError(let error):
            return "Persistence Error: \(error.localizedDescription)"
        case .validationError(let error):
            return "Validation Error: \(error.localizedDescription)"
        case .capabilityError(let error):
            return "Capability Error: \(error.localizedDescription)"
        case .actorError(let error):
            return "Actor Error: \(error.localizedDescription)"
        case .deviceError(let error):
            return "Device Error: \(error.localizedDescription)"
        case .infrastructureError(let error):
            return "Infrastructure Error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
    
    /// Recommended recovery strategy for this error
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .contextError:
            return .propagate
        case .clientError(let error):
            return error.recoveryStrategy
        case .navigationError:
            return .userPrompt(message: "Navigation failed. Please try again.")
        case .persistenceError:
            return .retry(attempts: 3)
        case .validationError:
            return .userPrompt(message: "Please correct the input")
        case .capabilityError:
            return .silent
        case .actorError:
            return .propagate
        case .deviceError:
            return .silent
        case .infrastructureError:
            return .retry(attempts: 2)
        case .networkError(let error):
            return error.recoveryStrategy
        case .unknownError:
            return .propagate
        }
    }
}

// MARK: - Specific Error Types

/// Context-related errors
public enum AxiomContextError: Error, Codable, Equatable, Hashable {
    case lifecycleError(String)
    case initializationFailed(String)
    case childContextError(String)
    case configurationError(String)
    case stateInconsistency(String)
    case memoryWarning(String)
    case invalidOperation(String)
    
    public var localizedDescription: String {
        switch self {
        case .lifecycleError(let message):
            return "Context lifecycle error: \(message)"
        case .initializationFailed(let message):
            return "Context initialization failed: \(message)"
        case .childContextError(let message):
            return "Child context error: \(message)"
        case .configurationError(let message):
            return "Context configuration error: \(message)"
        case .stateInconsistency(let message):
            return "Context state inconsistency: \(message)"
        case .memoryWarning(let message):
            return "Context memory warning: \(message)"
        case .invalidOperation(let message):
            return "Invalid context operation: \(message)"
        }
    }
}

/// Client-related errors
public enum AxiomClientError: Error, Codable, Equatable, Hashable {
    case timeout(duration: TimeInterval)
    case invalidAction(String)
    case stateCorruption(String)
    case actionProcessingFailed(String)
    case actorIsolationViolation(String)
    case memoryExhaustion
    case invalidState(String)
    
    public var localizedDescription: String {
        switch self {
        case .timeout(let duration):
            return "Client operation timed out after \(duration) seconds"
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        case .stateCorruption(let message):
            return "State corruption detected: \(message)"
        case .actionProcessingFailed(let message):
            return "Action processing failed: \(message)"
        case .actorIsolationViolation(let message):
            return "Actor isolation violation: \(message)"
        case .memoryExhaustion:
            return "Client memory exhaustion"
        case .invalidState(let message):
            return "Invalid client state: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .timeout:
            return .retry(attempts: 3)
        case .invalidAction, .stateCorruption, .invalidState:
            return .propagate
        case .actionProcessingFailed:
            return .retry(attempts: 2)
        case .actorIsolationViolation:
            return .propagate
        case .memoryExhaustion:
            return .silent
        }
    }
}

/// Navigation-related errors
public enum AxiomNavigationError: Error, Codable, Equatable, Hashable {
    case routeNotFound(String)
    case invalidRoute(String)
    case unauthorized
    case navigationFailed(String)
    case cycleDetected(String)
    case authenticationRequired
    case deepLinkingFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .routeNotFound(let route):
            return "Route not found: \(route)"
        case .invalidRoute(let route):
            return "Invalid route: \(route)"
        case .unauthorized:
            return "Unauthorized navigation attempt"
        case .navigationFailed(let message):
            return "Navigation failed: \(message)"
        case .cycleDetected(let message):
            return "Navigation cycle detected: \(message)"
        case .authenticationRequired:
            return "Authentication required for navigation"
        case .deepLinkingFailed(let message):
            return "Deep linking failed: \(message)"
        }
    }
}

/// Persistence-related errors
public enum AxiomPersistenceError: Error, Codable, Equatable, Hashable {
    case storageError(String)
    case serializationFailed(String)
    case deserializationFailed(String)
    case migrationFailed(String)
    case permissionDenied
    case diskSpaceExhausted
    case corruptedData(String)
    
    public var localizedDescription: String {
        switch self {
        case .storageError(let message):
            return "Storage error: \(message)"
        case .serializationFailed(let message):
            return "Serialization failed: \(message)"
        case .deserializationFailed(let message):
            return "Deserialization failed: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .permissionDenied:
            return "Storage permission denied"
        case .diskSpaceExhausted:
            return "Disk space exhausted"
        case .corruptedData(let message):
            return "Corrupted data: \(message)"
        }
    }
}

/// Validation-related errors
public enum AxiomValidationError: Error, Codable, Equatable, Hashable {
    case invalidInput(String, String) // field, reason
    case formatError(String, String) // field, expected format
    case rangeError(String, String) // field, valid range
    case constraintViolation(String)
    case schemaValidationFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .formatError(let field, let format):
            return "\(field) must be in format: \(format)"
        case .rangeError(let field, let range):
            return "\(field) must be in range: \(range)"
        case .constraintViolation(let message):
            return "Constraint violation: \(message)"
        case .schemaValidationFailed(let message):
            return "Schema validation failed: \(message)"
        }
    }
}

/// Capability-related errors
public enum AxiomCapabilityError: Error, Codable, Equatable, Hashable {
    case unavailable(String)
    case initializationFailed(String)
    case permissionDenied(String)
    case permissionRequired(String)
    case resourceAllocationFailed(String)
    case operationFailed(String)
    case timeoutError(String)
    case configurationError(String)
    
    public var localizedDescription: String {
        switch self {
        case .unavailable(let message):
            return "Capability unavailable: \(message)"
        case .initializationFailed(let message):
            return "Capability initialization failed: \(message)"
        case .permissionDenied(let message):
            return "Capability permission denied: \(message)"
        case .permissionRequired(let message):
            return "Capability permission required: \(message)"
        case .resourceAllocationFailed(let message):
            return "Capability resource allocation failed: \(message)"
        case .operationFailed(let message):
            return "Capability operation failed: \(message)"
        case .timeoutError(let message):
            return "Capability timeout: \(message)"
        case .configurationError(let message):
            return "Capability configuration error: \(message)"
        }
    }
}

/// Actor-related errors
public enum AxiomActorError: Error, Codable, Equatable, Hashable {
    case isolationViolation(String)
    case deadlock(String)
    case cancellation(String)
    case queueOverflow(String)
    
    public var localizedDescription: String {
        switch self {
        case .isolationViolation(let message):
            return "Actor isolation violation: \(message)"
        case .deadlock(let message):
            return "Actor deadlock: \(message)"
        case .cancellation(let message):
            return "Actor task cancelled: \(message)"
        case .queueOverflow(let message):
            return "Actor queue overflow: \(message)"
        }
    }
}

/// Device-related errors
public enum AxiomDeviceError: Error, Codable, Equatable, Hashable {
    case lowMemory
    case lowStorage
    case unsupportedDevice(String)
    case hardwareFailure(String)
    case osVersionUnsupported(String)
    
    public var localizedDescription: String {
        switch self {
        case .lowMemory:
            return "Device low memory"
        case .lowStorage:
            return "Device low storage"
        case .unsupportedDevice(let message):
            return "Unsupported device: \(message)"
        case .hardwareFailure(let message):
            return "Hardware failure: \(message)"
        case .osVersionUnsupported(let message):
            return "OS version unsupported: \(message)"
        }
    }
}

/// Infrastructure-related errors
public enum AxiomInfrastructureError: Error, Codable, Equatable, Hashable {
    case serviceUnavailable(String)
    case configurationError(String)
    case performanceDegradation(String)
    case resourceExhaustion(String)
    
    public var localizedDescription: String {
        switch self {
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .configurationError(let message):
            return "Infrastructure configuration error: \(message)"
        case .performanceDegradation(let message):
            return "Performance degradation: \(message)"
        case .resourceExhaustion(let message):
            return "Resource exhaustion: \(message)"
        }
    }
}

/// Network-related errors
public enum AxiomNetworkError: Error, Codable, Equatable, Hashable {
    case connectionFailed(String)
    case timeout
    case noInternetConnection
    case serverError(Int)
    case invalidResponse(String)
    case sslError(String)
    case requestFailed(String)
    case cancelled
    case invalidURL(String)
    case tlsError(String)
    
    public var localizedDescription: String {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .timeout:
            return "Network timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .sslError(let message):
            return "SSL error: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .cancelled:
            return "Request was cancelled"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .tlsError(let message):
            return "TLS error: \(message)"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .connectionFailed, .timeout:
            return .retry(attempts: 3)
        case .noInternetConnection:
            return .userPrompt(message: "Please check your internet connection")
        case .serverError(let code) where code >= 500:
            return .retry(attempts: 2)
        case .serverError:
            return .propagate
        case .invalidResponse:
            return .propagate
        case .sslError:
            return .propagate
        case .requestFailed:
            return .retry(attempts: 2)
        case .cancelled:
            return .silent
        case .invalidURL:
            return .propagate
        case .tlsError:
            return .propagate
        }
    }
}

// MARK: - Error Recovery Strategy

/// Strategy for error recovery
public enum ErrorRecoveryStrategy: Equatable, Sendable {
    case retry(attempts: Int)
    case propagate
    case silent
    case userPrompt(message: String)
}