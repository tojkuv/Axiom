import Foundation
import Logging
import HotReloadProtocol

// MARK: - SwiftUI Specific Error Types

public enum SwiftUIHotReloadError: Error, LocalizedError {
    case tokenizationFailed(String, line: Int?)
    case astBuildingFailed(String, context: String?)
    case stateExtractionFailed(String, propertyName: String?)
    case jsonGenerationFailed(String, viewType: String?)
    case invalidSwiftUICode(String, filePath: String)
    case unsupportedSyntax(String, construct: String)
    case propertyWrapperError(String, wrapperType: String)
    case viewHierarchyError(String, viewName: String?)
    case parsingTimeout(String, timeoutDuration: TimeInterval)
    case fileReadError(String, filePath: String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .tokenizationFailed(let message, let line):
            return "Tokenization failed: \(message)" + (line.map { " at line \($0)" } ?? "")
        case .astBuildingFailed(let message, let context):
            return "AST building failed: \(message)" + (context.map { " in \($0)" } ?? "")
        case .stateExtractionFailed(let message, let propertyName):
            return "State extraction failed: \(message)" + (propertyName.map { " for property \($0)" } ?? "")
        case .jsonGenerationFailed(let message, let viewType):
            return "JSON generation failed: \(message)" + (viewType.map { " for view type \($0)" } ?? "")
        case .invalidSwiftUICode(let message, let filePath):
            return "Invalid SwiftUI code in \(filePath): \(message)"
        case .unsupportedSyntax(let message, let construct):
            return "Unsupported syntax '\(construct)': \(message)"
        case .propertyWrapperError(let message, let wrapperType):
            return "Property wrapper error for \(wrapperType): \(message)"
        case .viewHierarchyError(let message, let viewName):
            return "View hierarchy error: \(message)" + (viewName.map { " in view \($0)" } ?? "")
        case .parsingTimeout(let message, let timeoutDuration):
            return "Parsing timeout after \(timeoutDuration)s: \(message)"
        case .fileReadError(let message, let filePath):
            return "File read error for \(filePath): \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}

// MARK: - Error Context

public struct SwiftUIErrorContext {
    public let filePath: String
    public let fileName: String
    public let line: Int?
    public let column: Int?
    public let snippet: String?
    public let parsePhase: SwiftUIParsePhase
    public let timestamp: Date
    
    public init(filePath: String, fileName: String? = nil, line: Int? = nil, column: Int? = nil, snippet: String? = nil, parsePhase: SwiftUIParsePhase, timestamp: Date = Date()) {
        self.filePath = filePath
        self.fileName = fileName ?? URL(fileURLWithPath: filePath).lastPathComponent
        self.line = line
        self.column = column
        self.snippet = snippet
        self.parsePhase = parsePhase
        self.timestamp = timestamp
    }
}

public enum SwiftUIParsePhase: String, CaseIterable {
    case tokenization = "tokenization"
    case astBuilding = "ast_building"
    case stateExtraction = "state_extraction"
    case jsonGeneration = "json_generation"
    case fileReading = "file_reading"
    case validation = "validation"
}

// MARK: - Error Recovery

public protocol SwiftUIErrorRecovery {
    func attemptRecovery(from error: SwiftUIHotReloadError, context: SwiftUIErrorContext) -> SwiftUIRecoveryResult
}

public struct SwiftUIRecoveryResult {
    public let succeeded: Bool
    public let fallbackContent: String?
    public let recoveryActions: [SwiftUIRecoveryAction]
    public let shouldRetry: Bool
    
    public init(succeeded: Bool, fallbackContent: String? = nil, recoveryActions: [SwiftUIRecoveryAction] = [], shouldRetry: Bool = false) {
        self.succeeded = succeeded
        self.fallbackContent = fallbackContent
        self.recoveryActions = recoveryActions
        self.shouldRetry = shouldRetry
    }
}

public enum SwiftUIRecoveryAction: String, CaseIterable {
    case skipFile = "skip_file"
    case useFallbackContent = "use_fallback"
    case reportToClient = "report_to_client"
    case retryWithSimplifiedParsing = "retry_simplified"
    case ignoreParseErrors = "ignore_errors"
    case requestClientRefresh = "request_refresh"
}

// MARK: - Error Handler

public final class SwiftUIErrorHandler {
    private let logger: Logger
    private let configuration: SwiftUIErrorHandlerConfiguration
    private let recovery: SwiftUIErrorRecovery?
    
    public init(
        configuration: SwiftUIErrorHandlerConfiguration = SwiftUIErrorHandlerConfiguration(),
        recovery: SwiftUIErrorRecovery? = nil,
        logger: Logger = Logger(label: "axiom.hotreload.swiftui.error")
    ) {
        self.configuration = configuration
        self.recovery = recovery
        self.logger = logger
    }
    
    public func handleError(
        _ error: Error,
        context: SwiftUIErrorContext,
        completion: @escaping (SwiftUIErrorHandlerResult) -> Void
    ) {
        logger.debug("Handling SwiftUI error in \(context.parsePhase.rawValue) phase for \(context.fileName)")
        
        let swiftUIError = mapToSwiftUIError(error, context: context)
        let severity = determineSeverity(error: swiftUIError, context: context)
        
        // Log the error
        logError(swiftUIError, severity: severity, context: context)
        
        // Attempt recovery if configured
        let recoveryResult: SwiftUIRecoveryResult?
        if configuration.enableRecovery, let recovery = recovery {
            recoveryResult = recovery.attemptRecovery(from: swiftUIError, context: context)
        } else {
            recoveryResult = nil
        }
        
        // Generate error report
        let errorReport = generateErrorReport(
            error: swiftUIError,
            context: context,
            severity: severity,
            recoveryResult: recoveryResult
        )
        
        // Determine response
        let response = determineResponse(
            error: swiftUIError,
            severity: severity,
            recoveryResult: recoveryResult,
            context: context
        )
        
        let result = SwiftUIErrorHandlerResult(
            originalError: error,
            mappedError: swiftUIError,
            severity: severity,
            context: context,
            errorReport: errorReport,
            recoveryResult: recoveryResult,
            response: response
        )
        
        completion(result)
    }
    
    private func mapToSwiftUIError(_ error: Error, context: SwiftUIErrorContext) -> SwiftUIHotReloadError {
        if let swiftUIError = error as? SwiftUIHotReloadError {
            return swiftUIError
        }
        
        // Map common error types to SwiftUI-specific errors
        let errorMessage = error.localizedDescription
        
        switch context.parsePhase {
        case .tokenization:
            return .tokenizationFailed(errorMessage, line: context.line)
        case .astBuilding:
            return .astBuildingFailed(errorMessage, context: context.fileName)
        case .stateExtraction:
            return .stateExtractionFailed(errorMessage, propertyName: nil)
        case .jsonGeneration:
            return .jsonGenerationFailed(errorMessage, viewType: nil)
        case .fileReading:
            return .fileReadError(errorMessage, filePath: context.filePath)
        case .validation:
            return .invalidSwiftUICode(errorMessage, filePath: context.filePath)
        }
    }
    
    private func determineSeverity(error: SwiftUIHotReloadError, context: SwiftUIErrorContext) -> SwiftUIErrorSeverity {
        switch error {
        case .parsingTimeout, .fileReadError:
            return .critical
        case .invalidSwiftUICode, .astBuildingFailed:
            return .high
        case .unsupportedSyntax, .propertyWrapperError:
            return .medium
        case .tokenizationFailed, .stateExtractionFailed:
            return .low
        default:
            return .medium
        }
    }
    
    private func logError(_ error: SwiftUIHotReloadError, severity: SwiftUIErrorSeverity, context: SwiftUIErrorContext) {
        let logMessage = "SwiftUI Error [\(severity.rawValue.uppercased())]: \(error.localizedDescription ?? "Unknown error")"
        
        switch severity {
        case .critical:
            logger.critical("\(logMessage) | File: \(context.fileName) | Phase: \(context.parsePhase.rawValue)")
        case .high:
            logger.error("\(logMessage) | File: \(context.fileName) | Phase: \(context.parsePhase.rawValue)")
        case .medium:
            logger.warning("\(logMessage) | File: \(context.fileName) | Phase: \(context.parsePhase.rawValue)")
        case .low:
            logger.debug("\(logMessage) | File: \(context.fileName) | Phase: \(context.parsePhase.rawValue)")
        }
        
        // Log additional context if available
        if let line = context.line, let column = context.column {
            logger.debug("Error location: line \(line), column \(column)")
        }
        
        if let snippet = context.snippet {
            logger.debug("Code snippet: \(snippet)")
        }
    }
    
    private func generateErrorReport(
        error: SwiftUIHotReloadError,
        context: SwiftUIErrorContext,
        severity: SwiftUIErrorSeverity,
        recoveryResult: SwiftUIRecoveryResult?
    ) -> SwiftUIErrorReport {
        return SwiftUIErrorReport(
            errorId: UUID().uuidString,
            error: error,
            context: context,
            severity: severity,
            timestamp: Date(),
            recoveryAttempted: recoveryResult != nil,
            recoverySucceeded: recoveryResult?.succeeded ?? false,
            suggestions: generateSuggestions(for: error, context: context)
        )
    }
    
    private func generateSuggestions(for error: SwiftUIHotReloadError, context: SwiftUIErrorContext) -> [String] {
        switch error {
        case .invalidSwiftUICode:
            return [
                "Check SwiftUI syntax in \(context.fileName)",
                "Ensure all view modifiers are properly formatted",
                "Verify that all property wrappers are correctly declared"
            ]
        case .propertyWrapperError(_, let wrapperType):
            return [
                "Check \(wrapperType) property declaration syntax",
                "Ensure the property wrapper is imported and available",
                "Verify the property type is compatible with \(wrapperType)"
            ]
        case .unsupportedSyntax(_, let construct):
            return [
                "The construct '\(construct)' is not yet supported in hot reload",
                "Consider using an alternative approach",
                "This may be added in future versions"
            ]
        case .parsingTimeout:
            return [
                "File may be too large or complex for hot reload",
                "Consider breaking down large view hierarchies",
                "Check for infinite loops in view construction"
            ]
        default:
            return ["Check the file syntax and try again"]
        }
    }
    
    private func determineResponse(
        error: SwiftUIHotReloadError,
        severity: SwiftUIErrorSeverity,
        recoveryResult: SwiftUIRecoveryResult?,
        context: SwiftUIErrorContext
    ) -> SwiftUIErrorResponse {
        // If recovery succeeded, continue with recovered content
        if let recoveryResult = recoveryResult, recoveryResult.succeeded {
            return .continueWithRecovery(recoveryResult.fallbackContent)
        }
        
        // Based on severity and configuration, determine response
        switch severity {
        case .critical:
            return .abort("Critical error in SwiftUI parsing")
        case .high:
            if configuration.skipFileOnHighSeverityError {
                return .skipFile("Skipping file due to high severity error")
            } else {
                return .reportError("High severity error reported to client")
            }
        case .medium, .low:
            if configuration.continueOnLowSeverityError {
                return .continueWithWarning("Continuing with warning")
            } else {
                return .reportError("Error reported to client")
            }
        }
    }
}

// MARK: - Supporting Types

public enum SwiftUIErrorSeverity: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum SwiftUIErrorResponse {
    case continueWithRecovery(String?)
    case continueWithWarning(String)
    case skipFile(String)
    case reportError(String)
    case abort(String)
}

public struct SwiftUIErrorReport {
    public let errorId: String
    public let error: SwiftUIHotReloadError
    public let context: SwiftUIErrorContext
    public let severity: SwiftUIErrorSeverity
    public let timestamp: Date
    public let recoveryAttempted: Bool
    public let recoverySucceeded: Bool
    public let suggestions: [String]
}

public struct SwiftUIErrorHandlerResult {
    public let originalError: Error
    public let mappedError: SwiftUIHotReloadError
    public let severity: SwiftUIErrorSeverity
    public let context: SwiftUIErrorContext
    public let errorReport: SwiftUIErrorReport
    public let recoveryResult: SwiftUIRecoveryResult?
    public let response: SwiftUIErrorResponse
}

public struct SwiftUIErrorHandlerConfiguration {
    public let enableRecovery: Bool
    public let skipFileOnHighSeverityError: Bool
    public let continueOnLowSeverityError: Bool
    public let maxRetryAttempts: Int
    public let enableDetailedLogging: Bool
    public let reportErrorsToClient: Bool
    
    public init(
        enableRecovery: Bool = true,
        skipFileOnHighSeverityError: Bool = true,
        continueOnLowSeverityError: Bool = true,
        maxRetryAttempts: Int = 3,
        enableDetailedLogging: Bool = true,
        reportErrorsToClient: Bool = true
    ) {
        self.enableRecovery = enableRecovery
        self.skipFileOnHighSeverityError = skipFileOnHighSeverityError
        self.continueOnLowSeverityError = continueOnLowSeverityError
        self.maxRetryAttempts = maxRetryAttempts
        self.enableDetailedLogging = enableDetailedLogging
        self.reportErrorsToClient = reportErrorsToClient
    }
    
    public static func forHotReload() -> SwiftUIErrorHandlerConfiguration {
        return SwiftUIErrorHandlerConfiguration(
            enableRecovery: true,
            skipFileOnHighSeverityError: true,
            continueOnLowSeverityError: true,
            maxRetryAttempts: 2,
            enableDetailedLogging: false,
            reportErrorsToClient: true
        )
    }
}

// MARK: - Default Recovery Implementation

public final class DefaultSwiftUIErrorRecovery: SwiftUIErrorRecovery {
    private let logger: Logger
    
    public init(logger: Logger = Logger(label: "axiom.hotreload.swiftui.recovery")) {
        self.logger = logger
    }
    
    public func attemptRecovery(from error: SwiftUIHotReloadError, context: SwiftUIErrorContext) -> SwiftUIRecoveryResult {
        logger.debug("Attempting recovery for \(error) in \(context.fileName)")
        
        switch error {
        case .tokenizationFailed:
            return attemptTokenizationRecovery(context: context)
        case .stateExtractionFailed:
            return attemptStateExtractionRecovery(context: context)
        case .unsupportedSyntax:
            return attemptUnsupportedSyntaxRecovery(context: context)
        case .propertyWrapperError:
            return attemptPropertyWrapperRecovery(context: context)
        default:
            return SwiftUIRecoveryResult(
                succeeded: false,
                recoveryActions: [.reportToClient],
                shouldRetry: false
            )
        }
    }
    
    private func attemptTokenizationRecovery(context: SwiftUIErrorContext) -> SwiftUIRecoveryResult {
        // For tokenization errors, try to provide a minimal valid SwiftUI structure
        let fallbackContent = generateMinimalSwiftUIStructure(fileName: context.fileName)
        
        return SwiftUIRecoveryResult(
            succeeded: true,
            fallbackContent: fallbackContent,
            recoveryActions: [.useFallbackContent, .reportToClient],
            shouldRetry: false
        )
    }
    
    private func attemptStateExtractionRecovery(context: SwiftUIErrorContext) -> SwiftUIRecoveryResult {
        // For state extraction errors, continue without state information
        return SwiftUIRecoveryResult(
            succeeded: true,
            recoveryActions: [.ignoreParseErrors],
            shouldRetry: true
        )
    }
    
    private func attemptUnsupportedSyntaxRecovery(context: SwiftUIErrorContext) -> SwiftUIRecoveryResult {
        // For unsupported syntax, provide fallback and continue
        let fallbackContent = generateSimplifiedSwiftUIStructure(fileName: context.fileName)
        
        return SwiftUIRecoveryResult(
            succeeded: true,
            fallbackContent: fallbackContent,
            recoveryActions: [.useFallbackContent, .reportToClient],
            shouldRetry: false
        )
    }
    
    private func attemptPropertyWrapperRecovery(context: SwiftUIErrorContext) -> SwiftUIRecoveryResult {
        // For property wrapper errors, try simplified parsing
        return SwiftUIRecoveryResult(
            succeeded: true,
            recoveryActions: [.retryWithSimplifiedParsing],
            shouldRetry: true
        )
    }
    
    private func generateMinimalSwiftUIStructure(fileName: String) -> String {
        let viewName = fileName.replacingOccurrences(of: ".swift", with: "").capitalized
        return """
        import SwiftUI
        
        struct \(viewName): View {
            var body: some View {
                Text("Hot Reload Error - Minimal Fallback")
                    .foregroundColor(.red)
            }
        }
        """
    }
    
    private func generateSimplifiedSwiftUIStructure(fileName: String) -> String {
        let viewName = fileName.replacingOccurrences(of: ".swift", with: "").capitalized
        return """
        import SwiftUI
        
        struct \(viewName): View {
            var body: some View {
                VStack {
                    Text("Simplified View")
                    Text("Some syntax not supported in hot reload")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        """
    }
}