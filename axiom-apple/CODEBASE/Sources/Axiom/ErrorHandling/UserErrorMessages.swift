import Foundation

// MARK: - Localization Provider

/// Protocol for providing localized strings
public protocol LocalizationProvider {
    func string(for key: String) -> String
    func string(for key: String, _ args: String...) -> String
}

/// Default implementation of localization provider
public class DefaultLocalizationProvider: LocalizationProvider {
    private let localizations: [String: [String: String]] = [
        "en": [
            // Network errors
            "error.network.title": "Connection Problem",
            "error.network.no_connection": "Please check your internet connection and try again.",
            "error.network.timeout": "The request took too long to complete. Please try again.",
            "error.network.server_error": "Our servers are temporarily unavailable. Please try again later.",
            
            // Payment errors
            "error.payment.cancelled.title": "Payment Cancelled",
            "error.payment.cancelled.description": "You cancelled the payment. No charges were made to your account.",
            "error.payment.declined.title": "Payment Declined",
            "error.payment.declined.description": "Your payment was declined. Please check your payment method or try a different card.",
            
            // Capability errors
            "error.capability.unavailable.title": "Feature Unavailable",
            "error.capability.unavailable.description": "The feature '%@' is not available on your device.",
            
            // Validation errors
            "error.validation.invalid_input.title": "Invalid Input",
            "error.validation.missing_required.title": "Missing Information",
            "error.validation.format_error.title": "Format Error",
            
            // Generic errors
            "error.generic.title": "Something Went Wrong",
            "error.generic.description": "An unexpected error occurred. Please try again.",
            
            // Suggestions
            "suggestion.check_connection": "Check your internet connection",
            "suggestion.try_again": "Try again",
            "suggestion.different_payment": "Try a different payment method",
            "suggestion.contact_bank": "Contact your bank",
            "suggestion.contact_support": "Contact support",
            "suggestion.restart_app": "Restart the app",
            "suggestion.update_app": "Update the app"
        ],
        "es": [
            // Network errors
            "error.network.title": "Problema de Conexión",
            "error.network.no_connection": "Verifique su conexión a internet e intente nuevamente.",
            "error.network.timeout": "La solicitud tardó demasiado en completarse. Intente nuevamente.",
            "error.network.server_error": "Nuestros servidores no están disponibles temporalmente. Intente más tarde.",
            
            // Payment errors
            "error.payment.cancelled.title": "Pago Cancelado",
            "error.payment.cancelled.description": "Canceló el pago. No se realizaron cargos a su cuenta.",
            
            // Generic errors
            "error.generic.title": "Algo Salió Mal",
            "error.generic.description": "Ocurrió un error inesperado. Intente nuevamente.",
            
            // Suggestions
            "suggestion.try_again": "Intentar nuevamente",
            "suggestion.contact_support": "Contactar soporte"
        ]
    ]
    
    private let currentLanguage: String
    
    public init(language: String = "en") {
        self.currentLanguage = language
    }
    
    public func string(for key: String) -> String {
        return localizations[currentLanguage]?[key] ?? localizations["en"]?[key] ?? key
    }
    
    public func string(for key: String, _ args: String...) -> String {
        let format = string(for: key)
        return String(format: format, arguments: args)
    }
}

// MARK: - Error Context

/// Context information for generating user-friendly error messages
public struct ErrorContext {
    public let userAction: String?
    public let feature: String?
    public let operationId: String?
    public let metadata: [String: String]
    
    public init(
        userAction: String? = nil,
        feature: String? = nil,
        operationId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.userAction = userAction
        self.feature = feature
        self.operationId = operationId
        self.metadata = metadata
    }
}

// MARK: - User Error Message

/// User-friendly error message with actionable suggestions
public struct UserErrorMessage {
    public let title: String
    public let description: String
    public let suggestions: [ActionableSuggestion]
    public let severity: AxiomErrorSeverity
    
    public init(
        title: String,
        description: String,
        suggestions: [ActionableSuggestion],
        severity: AxiomErrorSeverity
    ) {
        self.title = title
        self.description = description
        self.suggestions = suggestions
        self.severity = severity
    }
}

// MARK: - Base Error Message

/// Base error message structure
public struct BaseErrorMessage {
    public let title: String
    public let description: String
    
    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}

// MARK: - Actionable Suggestion

/// Actionable suggestion for error recovery
public struct ActionableSuggestion {
    public let title: String
    public let action: SuggestionAction
    
    public init(title: String, action: SuggestionAction) {
        self.title = title
        self.action = action
    }
}

// MARK: - Suggestion Action

/// Actions that can be suggested to users for error recovery
public enum SuggestionAction {
    case retry
    case checkNetworkSettings
    case changPaymentMethod
    case contactSupport
    case restartApp
    case updateApp
    case refreshAuthentication
    case dismissError
    case viewOfflineContent
    case waitAndRetry
}

// MARK: - User Error Message Service

/// Service for generating user-friendly error messages
public actor UserErrorMessageService {
    private let localizationProvider: any LocalizationProvider
    private var customMessageMappings: [String: UserErrorMessage] = [:]
    private var contextualEnhancements: [String: (ErrorContext) -> String] = [:]
    private var isSetupComplete = false
    
    public init(localizationProvider: any LocalizationProvider = DefaultLocalizationProvider()) {
        self.localizationProvider = localizationProvider
    }
    
    private func ensureSetup() {
        if !isSetupComplete {
            setupContextualEnhancements()
            isSetupComplete = true
        }
    }
    
    /// Generates a user-friendly message for an error with context
    public func getUserFriendlyMessage(
        for error: AxiomError,
        context: ErrorContext? = nil
    ) async -> UserErrorMessage {
        // Check for custom mappings first
        let errorKey = String(describing: error)
        if let customMessage = customMessageMappings[errorKey] {
            return await enhanceWithContext(customMessage, context: context)
        }
        
        let baseMessage = getBaseMessage(for: error)
        let contextualMessage = await addContextualInformation(baseMessage, context: context)
        let actionableSuggestions = await getActionableSuggestions(for: error, context: context)
        
        return UserErrorMessage(
            title: contextualMessage.title,
            description: contextualMessage.description,
            suggestions: actionableSuggestions,
            severity: determineSeverity(for: error)
        )
    }
    
    /// Adds a custom message mapping for specific error types
    public func addCustomMapping(for errorType: String, message: UserErrorMessage) {
        customMessageMappings[errorType] = message
    }
    
    /// Removes a custom message mapping
    public func removeCustomMapping(for errorType: String) {
        customMessageMappings.removeValue(forKey: errorType)
    }
    
    /// Adds contextual enhancement for specific features
    public func addContextualEnhancement(
        for feature: String,
        enhancement: @escaping (ErrorContext) -> String
    ) {
        contextualEnhancements[feature] = enhancement
    }
    
    // MARK: - Private Implementation
    
    private func getBaseMessage(for error: AxiomError) -> BaseErrorMessage {
        switch error {
        case .navigationError(let navError):
            return getNavigationErrorMessage(navError)
        case .validationError(let validationError):
            return getValidationErrorMessage(validationError)
        case .persistenceError(let persistenceError):
            return getAxiomPersistenceErrorMessage(persistenceError)
        case .capabilityError(let capabilityError):
            return getAxiomCapabilityErrorMessage(capabilityError)
        case .clientError(let clientError):
            return getClientErrorMessage(clientError)
        case .contextError(let contextError):
            return getContextErrorMessage(contextError)
        case .actorError(let actorError):
            return getAxiomActorErrorMessage(actorError)
        case .deviceError(let deviceError):
            return getAxiomDeviceErrorMessage(deviceError)
        case .infrastructureError(let infraError):
            return getAxiomInfrastructureErrorMessage(infraError)
        case .networkError(let networkError):
            return getAxiomNetworkErrorMessage(networkError)
        case .unknownError:
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.generic.title"),
                description: localizationProvider.string(for: "error.generic.description")
            )
        }
    }
    
    private func getNavigationErrorMessage(_ error: AxiomNavigationError) -> BaseErrorMessage {
        switch error {
        case .invalidURL(let component, _) where component == "network":
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.network.title"),
                description: localizationProvider.string(for: "error.network.no_connection")
            )
        case .unauthorized:
            return BaseErrorMessage(
                title: "Authentication Required",
                description: "Please sign in to access this feature."
            )
        case .navigationBlocked(let reason):
            return BaseErrorMessage(
                title: "Access Blocked",
                description: "Access to this section is currently blocked: \(reason)"
            )
        default:
            return BaseErrorMessage(
                title: "Navigation Error",
                description: "Unable to navigate to the requested location."
            )
        }
    }
    
    private func getValidationErrorMessage(_ error: AxiomValidationError) -> BaseErrorMessage {
        switch error {
        case .invalidInput(let field, let reason):
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.validation.invalid_input.title"),
                description: "The \(field) field is invalid: \(reason)"
            )
        case .missingRequired(let field):
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.validation.missing_required.title"),
                description: "The \(field) field is required."
            )
        case .formatError(let field, let format):
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.validation.format_error.title"),
                description: "The \(field) field must be in the format: \(format)"
            )
        case .rangeError(let field, let range):
            return BaseErrorMessage(
                title: "Value Out of Range",
                description: "The \(field) value must be within: \(range)"
            )
        case .ruleFailed(let field, let rule, let reason):
            return BaseErrorMessage(
                title: "Validation Failed",
                description: "The \(field) field failed validation rule '\(rule)': \(reason)"
            )
        case .multipleFailures(let failures):
            return BaseErrorMessage(
                title: "Multiple Validation Errors",
                description: "Please correct the following: \(failures.joined(separator: ", "))"
            )
        }
    }
    
    private func getAxiomPersistenceErrorMessage(_ error: AxiomPersistenceError) -> BaseErrorMessage {
        switch error {
        case .saveFailed:
            return BaseErrorMessage(
                title: "Save Failed",
                description: "Your changes could not be saved. Please try again."
            )
        case .loadFailed:
            return BaseErrorMessage(
                title: "Load Failed",
                description: "Unable to load your data. Please check your connection and try again."
            )
        case .deleteFailed:
            return BaseErrorMessage(
                title: "Delete Failed",
                description: "The item could not be deleted. Please try again."
            )
        case .migrationFailed:
            return BaseErrorMessage(
                title: "Update Required",
                description: "Your data needs to be updated. Please restart the app."
            )
        }
    }
    
    private func getAxiomCapabilityErrorMessage(_ error: AxiomCapabilityError) -> BaseErrorMessage {
        switch error {
        case .notAvailable(let capability):
            return BaseErrorMessage(
                title: localizationProvider.string(for: "error.capability.unavailable.title"),
                description: localizationProvider.string(for: "error.capability.unavailable.description", capability)
            )
        case .restricted(let capability):
            return BaseErrorMessage(
                title: "Feature Restricted",
                description: "The \(capability) feature is restricted on your device."
            )
        case .permissionRequired(let capability):
            return BaseErrorMessage(
                title: "Permission Required",
                description: "Please grant permission to use \(capability)."
            )
        default:
            return BaseErrorMessage(
                title: "Feature Unavailable",
                description: "This feature is currently unavailable."
            )
        }
    }
    
    private func getClientErrorMessage(_ error: AxiomClientError) -> BaseErrorMessage {
        switch error {
        case .timeout:
            return BaseErrorMessage(
                title: "Request Timeout",
                description: localizationProvider.string(for: "error.network.timeout")
            )
        case .invalidAction(let action):
            return BaseErrorMessage(
                title: "Invalid Action",
                description: "The action '\(action)' is not valid at this time."
            )
        case .stateUpdateFailed:
            return BaseErrorMessage(
                title: "Update Failed",
                description: "Unable to update the current state. Please try again."
            )
        case .notInitialized:
            return BaseErrorMessage(
                title: "Service Unavailable",
                description: "The service is starting up. Please wait a moment and try again."
            )
        case .atomicActionSequenceFailed(let processed, let total, _):
            return BaseErrorMessage(
                title: "Action Sequence Failed",
                description: "Failed to complete action sequence (\(processed)/\(total) actions completed). Previous state has been restored."
            )
        case .maxRetriesExceeded(let attempts, _):
            return BaseErrorMessage(
                title: "Maximum Retries Exceeded",
                description: "Operation failed after \(attempts) attempts. Please try again later."
            )
        }
    }
    
    private func getContextErrorMessage(_ error: AxiomContextError) -> BaseErrorMessage {
        switch error {
        case .lifecycleError:
            return BaseErrorMessage(
                title: "App Error",
                description: "An application error occurred. Please restart the app."
            )
        case .initializationFailed:
            return BaseErrorMessage(
                title: "Startup Error",
                description: "The app failed to start properly. Please restart."
            )
        case .childContextError:
            return BaseErrorMessage(
                title: "Component Error",
                description: "A component error occurred. Please try again."
            )
        }
    }
    
    private func getAxiomActorErrorMessage(_ error: AxiomActorError) -> BaseErrorMessage {
        return BaseErrorMessage(
            title: "System Error",
            description: "A system error occurred. Please try again or restart the app."
        )
    }
    
    private func getAxiomDeviceErrorMessage(_ error: AxiomDeviceError) -> BaseErrorMessage {
        switch error {
        case .performanceThrottled:
            return BaseErrorMessage(
                title: "Performance Reduced",
                description: "Performance has been reduced due to device conditions."
            )
        case .systemResourceLimited:
            return BaseErrorMessage(
                title: "Resource Limited",
                description: "System resources are limited. Please close other apps."
            )
        default:
            return BaseErrorMessage(
                title: "Device Error",
                description: "A device-related error occurred."
            )
        }
    }
    
    private func getAxiomInfrastructureErrorMessage(_ error: AxiomInfrastructureError) -> BaseErrorMessage {
        switch error {
        case .serviceUnavailable:
            return BaseErrorMessage(
                title: "Service Unavailable",
                description: localizationProvider.string(for: "error.network.server_error")
            )
        case .criticalSystemError:
            return BaseErrorMessage(
                title: "Critical Error",
                description: "A critical system error occurred. Please restart the app."
            )
        default:
            return BaseErrorMessage(
                title: "System Error",
                description: "A system error occurred. Please try again later."
            )
        }
    }
    
    private func getAxiomNetworkErrorMessage(_ error: AxiomNetworkError) -> BaseErrorMessage {
        switch error {
        case .invalidURL(let url):
            return BaseErrorMessage(
                title: "Invalid URL",
                description: "The URL '\(url)' is not valid. Please check the address and try again."
            )
        case .sessionNotAvailable:
            return BaseErrorMessage(
                title: "Connection Error",
                description: "Network session is not available. Please check your connection."
            )
        case .requestFailed(let reason):
            return BaseErrorMessage(
                title: "Request Failed",
                description: "Network request failed: \(reason)"
            )
        case .invalidResponse(let reason):
            return BaseErrorMessage(
                title: "Invalid Response",
                description: "Received invalid response: \(reason)"
            )
        case .clientError(let code):
            return BaseErrorMessage(
                title: "Request Error",
                description: "Request error (code \(code)). Please check your input and try again."
            )
        case .serverError(let code):
            return BaseErrorMessage(
                title: "Server Error",
                description: "Server error (code \(code)). Please try again later."
            )
        case .unexpectedStatusCode(let code):
            return BaseErrorMessage(
                title: "Unexpected Response",
                description: "Received unexpected status code \(code)."
            )
        case .noInternetConnection:
            return BaseErrorMessage(
                title: "No Internet Connection",
                description: "Please check your internet connection and try again."
            )
        case .timeout:
            return BaseErrorMessage(
                title: "Request Timeout",
                description: "The request timed out. Please try again."
            )
        case .cancelled:
            return BaseErrorMessage(
                title: "Request Cancelled",
                description: "The request was cancelled."
            )
        case .tlsError(let reason):
            return BaseErrorMessage(
                title: "Security Error",
                description: "TLS/SSL error: \(reason)"
            )
        case .authenticationFailed:
            return BaseErrorMessage(
                title: "Authentication Failed",
                description: "Authentication failed. Please check your credentials."
            )
        case .rateLimitExceeded:
            return BaseErrorMessage(
                title: "Rate Limit Exceeded",
                description: "Too many requests. Please wait a moment and try again."
            )
        }
    }
    
    private func addContextualInformation(
        _ baseMessage: BaseErrorMessage,
        context: ErrorContext?
    ) async -> BaseErrorMessage {
        guard let context = context else { return baseMessage }
        
        var enhancedDescription = baseMessage.description
        
        // Add user action context
        if let userAction = context.userAction {
            enhancedDescription = "While trying to \(userAction.lowercased()): \(enhancedDescription)"
        }
        
        // Add feature-specific enhancements
        ensureSetup()
        if let feature = context.feature,
           let enhancement = contextualEnhancements[feature] {
            let additionalInfo = enhancement(context)
            enhancedDescription += " \(additionalInfo)"
        }
        
        return BaseErrorMessage(
            title: baseMessage.title,
            description: enhancedDescription
        )
    }
    
    private func getActionableSuggestions(
        for error: AxiomError,
        context: ErrorContext?
    ) async -> [ActionableSuggestion] {
        var suggestions: [ActionableSuggestion] = []
        
        switch error {
        case .navigationError(let navError):
            suggestions = getNavigationSuggestions(navError)
        case .validationError:
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                )
            ]
        case .persistenceError:
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                ),
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.check_connection"),
                    action: .checkNetworkSettings
                )
            ]
        case .capabilityError:
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.contact_support"),
                    action: .contactSupport
                )
            ]
        case .clientError(.timeout):
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                ),
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.check_connection"),
                    action: .checkNetworkSettings
                )
            ]
        case .contextError, .actorError:
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.restart_app"),
                    action: .restartApp
                )
            ]
        default:
            suggestions = [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                ),
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.contact_support"),
                    action: .contactSupport
                )
            ]
        }
        
        return suggestions
    }
    
    private func getNavigationSuggestions(_ error: AxiomNavigationError) -> [ActionableSuggestion] {
        switch error {
        case .invalidURL(let component, _) where component == "network":
            return [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.check_connection"),
                    action: .checkNetworkSettings
                ),
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                )
            ]
        case .unauthorized, .authenticationRequired:
            return [
                ActionableSuggestion(
                    title: "Sign In",
                    action: .refreshAuthentication
                )
            ]
        default:
            return [
                ActionableSuggestion(
                    title: localizationProvider.string(for: "suggestion.try_again"),
                    action: .retry
                )
            ]
        }
    }
    
    private func determineSeverity(for error: AxiomError) -> AxiomErrorSeverity {
        switch error {
        case .validationError:
            return .warning
        case .navigationError(.unauthorized), .navigationError(.authenticationRequired):
            return .warning
        case .persistenceError(.migrationFailed):
            return .critical
        case .contextError, .actorError:
            return .error
        case .infrastructureError(.criticalSystemError):
            return .critical
        case .deviceError(.performanceThrottled):
            return .warning
        default:
            return .error
        }
    }
    
    private func enhanceWithContext(
        _ message: UserErrorMessage,
        context: ErrorContext?
    ) async -> UserErrorMessage {
        guard let context = context else { return message }
        
        let enhancedMessage = await addContextualInformation(
            BaseErrorMessage(title: message.title, description: message.description),
            context: context
        )
        
        return UserErrorMessage(
            title: enhancedMessage.title,
            description: enhancedMessage.description,
            suggestions: message.suggestions,
            severity: message.severity
        )
    }
    
    private func setupContextualEnhancements() {
        // Payment feature enhancements
        contextualEnhancements["payment"] = { (context: ErrorContext) in
            if let operationId = context.operationId {
                return "Transaction ID: \(operationId). No charges were made to your account."
            }
            return "No charges were made to your account."
        }
        
        // Search feature enhancements
        contextualEnhancements["search"] = { (context: ErrorContext) in
            if let query = context.metadata["query"] {
                return "Try searching for '\(query)' with different terms."
            }
            return "Try using different search terms."
        }
        
        // Media feature enhancements
        contextualEnhancements["media"] = { (_: ErrorContext) in
            return "You can still view offline content while we resolve this issue."
        }
    }
}

// MARK: - AxiomError Extensions

extension AxiomError {
    /// Gets user-friendly title for the error
    public var userFriendlyTitle: String {
        // This would integrate with UserErrorMessageService in production
        switch self {
        case .validationError:
            return "Invalid Input"
        case .navigationError(.unauthorized):
            return "Authentication Required"
        case .persistenceError:
            return "Save Error"
        case .capabilityError:
            return "Feature Unavailable"
        default:
            return "Error"
        }
    }
    
    /// Gets user-friendly description for the error
    public var userFriendlyDescription: String {
        // This would integrate with UserErrorMessageService in production
        switch self {
        case .validationError:
            return "Please check your input and try again."
        case .navigationError(.unauthorized):
            return "Please sign in to continue."
        case .persistenceError:
            return "Your changes could not be saved."
        case .capabilityError:
            return "This feature is not available."
        default:
            return "An unexpected error occurred."
        }
    }
}