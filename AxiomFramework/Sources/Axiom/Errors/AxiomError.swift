import Foundation

// MARK: - Core Error Protocol

/// The base protocol for all errors in the Axiom framework
public protocol AxiomError: Error, LocalizedError, Sendable, Identifiable {
    var id: UUID { get }
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    var context: ErrorContext { get }
    var recoveryActions: [RecoveryAction] { get }
    var userMessage: String { get }
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
    
    public var id: UUID {
        UUID()
    }
    
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
    
    public var userMessage: String {
        switch self {
        case .denied(let capability):
            return "You don't have permission to use \(capability). Please contact your administrator for access."
        case .expired(let lease):
            return "Your access has expired. Please refresh to continue."
        case .unavailable(let capability):
            return "The \(capability) feature is currently unavailable. Please try again later."
        case .configurationInvalid:
            return "There's a configuration issue. Please contact support for assistance."
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
    
    public var id: UUID {
        UUID()
    }
    
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
    
    public var userMessage: String {
        switch self {
        case .validationFailed(let result):
            let errorList = result.errors.prefix(3).joined(separator: ", ")
            let suffix = result.errors.count > 3 ? " and \(result.errors.count - 3) more..." : ""
            return "Please correct the following: \(errorList)\(suffix)"
        case .businessRuleViolation(let rule):
            return "This action violates a business rule: \(rule.description)"
        case .stateInconsistent:
            return "An inconsistency was detected. Please refresh and try again."
        case .aggregateNotFound:
            return "The requested item could not be found. It may have been deleted or moved."
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
    
    public var id: UUID {
        UUID()
    }
    
    public var category: ErrorCategory { .validation }
    
    public var severity: ErrorSeverity { .error }
    
    public var context: ErrorContext {
        ErrorContext(component: ComponentID("Unknown"))
    }
    
    public var recoveryActions: [RecoveryAction] {
        [.retry(after: 1.0), .escalate]
    }
    
    public var userMessage: String {
        "An unexpected error occurred. Please try again or contact support if the problem persists."
    }
    
    public var errorDescription: String? {
        "An error occurred: \(underlyingError.localizedDescription)"
    }
}

// MARK: - Context Error (Simplified Wrapper)

/// ENHANCED: A context-aware error wrapper that eliminates boilerplate
/// Automatically infers component information and provides sensible defaults
public struct ContextError: AxiomError {
    public let id = UUID()
    public let underlyingError: Error
    public let componentName: String
    public let category: ErrorCategory
    public let severity: ErrorSeverity
    public let customUserMessage: String?
    public let customRecoveryActions: [RecoveryAction]?
    
    /// Simple initializer for contexts - minimal boilerplate
    public init(
        _ error: Error,
        in componentName: String,
        category: ErrorCategory = .architectural,
        severity: ErrorSeverity = .error,
        userMessage: String? = nil,
        recoveryActions: [RecoveryAction]? = nil
    ) {
        self.underlyingError = error
        self.componentName = componentName
        self.category = category
        self.severity = severity
        self.customUserMessage = userMessage
        self.customRecoveryActions = recoveryActions
    }
    
    /// Automatic initializer that infers component name from context type
    public init<T: AxiomContext>(
        _ error: Error,
        in contextType: T.Type,
        category: ErrorCategory = .architectural,
        severity: ErrorSeverity = .error,
        userMessage: String? = nil,
        recoveryActions: [RecoveryAction]? = nil
    ) {
        let typeName = String(describing: contextType)
        self.init(
            error,
            in: typeName,
            category: category,
            severity: severity,
            userMessage: userMessage,
            recoveryActions: recoveryActions
        )
    }
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID(componentName),
            timestamp: Date(),
            additionalInfo: [
                "underlying_error": String(describing: underlyingError),
                "error_type": String(describing: type(of: underlyingError))
            ]
        )
    }
    
    public var recoveryActions: [RecoveryAction] {
        customRecoveryActions ?? defaultRecoveryActions
    }
    
    private var defaultRecoveryActions: [RecoveryAction] {
        switch severity {
        case .info, .warning:
            return [.ignore, .retry(after: 1.0)]
        case .error:
            return [.retry(after: 2.0), .escalate]
        case .critical, .fatal:
            return [.escalate, .fallback("Use safe mode")]
        }
    }
    
    public var userMessage: String {
        customUserMessage ?? generateUserMessage()
    }
    
    private func generateUserMessage() -> String {
        switch category {
        case .architectural:
            return "A system error occurred. Please try again or contact support if the issue persists."
        case .capability:
            return "You don't have the required permissions for this action. Please contact your administrator."
        case .domain:
            return "The action couldn't be completed due to business rules. Please check your input and try again."
        case .intelligence:
            return "The AI assistant encountered an issue. Please try rephrasing your request."
        case .performance:
            return "The system is running slowly. Please wait a moment and try again."
        case .validation:
            return "Please check your input and correct any errors before continuing."
        case .state:
            return "A synchronization issue occurred. Please refresh and try again."
        case .configuration:
            return "There's a configuration issue. Please contact support for assistance."
        }
    }
    
    public var errorDescription: String? {
        "[\(componentName)] \(category.rawValue.capitalized) error: \(underlyingError.localizedDescription)"
    }
}

// MARK: - Context Error Helper Extension

/// Extension to AxiomContext for easy error creation
extension AxiomContext {
    /// Creates a context error with automatic component name inference
    public func createError(
        _ error: Error,
        category: ErrorCategory = .architectural,
        severity: ErrorSeverity = .error,
        userMessage: String? = nil,
        recoveryActions: [RecoveryAction]? = nil
    ) -> ContextError {
        return ContextError(
            error,
            in: Self.self,
            category: category,
            severity: severity,
            userMessage: userMessage,
            recoveryActions: recoveryActions
        )
    }
    
    /// Quick error creation for common cases
    public func wrapError(_ error: Error) -> ContextError {
        return createError(error)
    }
}

// MARK: - Supporting Types (Placeholder implementations)

// These will be properly implemented in their respective modules

public struct BusinessRule: Sendable {
    let description: String
}