import Foundation

// MARK: - Core Error Protocol

/// The base protocol for all errors in the Axiom framework
public protocol AxiomError: Error, LocalizedError, Sendable {
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    var context: ErrorContext { get }
    var recoveryActions: [RecoveryAction] { get }
}

// MARK: - Error Categories

/// Categories of errors that can occur in the framework
public enum ErrorCategory: String, CaseIterable, Sendable {
    case architectural = "architectural"
    case capability = "capability"
    case domain = "domain"
    case intelligence = "intelligence"
    case performance = "performance"
    case validation = "validation"
    case state = "state"
    case configuration = "configuration"
}

// MARK: - Error Severity

/// The severity level of an error
public enum ErrorSeverity: Int, CaseIterable, Sendable, Comparable {
    case info = 0
    case warning = 1
    case error = 2
    case critical = 3
    case fatal = 4
    
    public static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Error Context

/// Additional context about where and when an error occurred
public struct ErrorContext: Sendable {
    public let component: ComponentID
    public let timestamp: Date
    public let additionalInfo: [String: String]
    
    public init(
        component: ComponentID,
        timestamp: Date = Date(),
        additionalInfo: [String: String] = [:]
    ) {
        self.component = component
        self.timestamp = timestamp
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Recovery Actions

/// Possible actions to recover from an error
public enum RecoveryAction: Sendable {
    case retry(after: TimeInterval)
    case reconfigure(String)
    case fallback(String)
    case ignore
    case escalate
    case custom(String, @Sendable () -> Void)
    
    public var description: String {
        switch self {
        case .retry(let interval):
            return "Retry after \(interval) seconds"
        case .reconfigure(let message):
            return "Reconfigure: \(message)"
        case .fallback(let message):
            return "Fallback: \(message)"
        case .ignore:
            return "Ignore and continue"
        case .escalate:
            return "Escalate to administrator"
        case .custom(let message, _):
            return message
        }
    }
}

// MARK: - Capability Errors

/// Errors related to the capability system
public enum CapabilityError: AxiomError {
    case denied(Capability)
    case expired(CapabilityLease)
    case unavailable(Capability)
    case configurationInvalid(String)
    
    public var category: ErrorCategory { .capability }
    
    public var severity: ErrorSeverity {
        switch self {
        case .denied:
            return .error
        case .expired:
            return .warning
        case .unavailable:
            return .critical
        case .configurationInvalid:
            return .error
        }
    }
    
    public var context: ErrorContext {
        ErrorContext(component: ComponentID("CapabilitySystem"))
    }
    
    public var recoveryActions: [RecoveryAction] {
        switch self {
        case .denied:
            return [.reconfigure("Request appropriate permissions"), .escalate]
        case .expired:
            return [.retry(after: 1.0), .reconfigure("Renew capability lease")]
        case .unavailable:
            return [.fallback("Use alternative capability"), .escalate]
        case .configurationInvalid:
            return [.reconfigure("Fix capability configuration"), .escalate]
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .denied(let capability):
            return "Access to capability '\(capability)' was denied"
        case .expired(let lease):
            return "Capability lease '\(lease.id)' has expired"
        case .unavailable(let capability):
            return "Capability '\(capability)' is not available"
        case .configurationInvalid(let message):
            return "Invalid capability configuration: \(message)"
        }
    }
}

// MARK: - Domain Errors

/// Errors related to domain models and business logic
public enum DomainError: AxiomError {
    case validationFailed(DomainValidationResult)
    case businessRuleViolation(BusinessRule)
    case stateInconsistent(String)
    case aggregateNotFound(String)
    
    public var category: ErrorCategory { .domain }
    
    public var severity: ErrorSeverity {
        switch self {
        case .validationFailed:
            return .error
        case .businessRuleViolation:
            return .error
        case .stateInconsistent:
            return .critical
        case .aggregateNotFound:
            return .warning
        }
    }
    
    public var context: ErrorContext {
        ErrorContext(component: ComponentID("DomainSystem"))
    }
    
    public var recoveryActions: [RecoveryAction] {
        switch self {
        case .validationFailed:
            return [.reconfigure("Fix validation errors"), .ignore]
        case .businessRuleViolation:
            return [.reconfigure("Adjust to comply with business rules")]
        case .stateInconsistent:
            return [.escalate, .fallback("Restore from backup")]
        case .aggregateNotFound:
            return [.retry(after: 2.0), .ignore]
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let result):
            return "Validation failed: \(result.errors.joined(separator: ", "))"
        case .businessRuleViolation(let rule):
            return "Business rule violation: \(rule.description)"
        case .stateInconsistent(let message):
            return "State inconsistency detected: \(message)"
        case .aggregateNotFound(let id):
            return "Aggregate not found: \(id)"
        }
    }
}

// MARK: - Generic Error

/// A generic error wrapper for non-AxiomError types
public struct GenericError: AxiomError {
    public let underlyingError: Error
    
    public init(underlyingError: Error) {
        self.underlyingError = underlyingError
    }
    
    public var category: ErrorCategory { .validation }
    
    public var severity: ErrorSeverity { .error }
    
    public var context: ErrorContext {
        ErrorContext(component: ComponentID("Unknown"))
    }
    
    public var recoveryActions: [RecoveryAction] {
        [.retry(after: 1.0), .escalate]
    }
    
    public var errorDescription: String? {
        "An error occurred: \(underlyingError.localizedDescription)"
    }
}

// MARK: - Supporting Types (Placeholder implementations)

// These will be properly implemented in their respective modules

public struct BusinessRule: Sendable {
    let description: String
}