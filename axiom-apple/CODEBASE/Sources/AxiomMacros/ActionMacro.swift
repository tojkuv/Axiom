import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// ActionMacro generates Action protocol conformance with execution pipeline and validation
///
/// Usage:
/// ```swift
/// @Action
/// enum TodoAction {
///     case addItem(String)
///     case toggleItem(UUID)
///     case deleteItem(UUID)
/// }
/// ```
///
/// This macro generates:
/// - Sendable conformance for thread safety
/// - Execution pipeline with pre/post processing
/// - Action validation and sanitization
/// - Performance tracking for action execution
/// - Automatic error handling integration
public struct ActionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Validate that this is applied to an enum or struct
        let isEnum = declaration.is(EnumDeclSyntax.self)
        let isStruct = declaration.is(StructDeclSyntax.self)
        
        guard isEnum || isStruct else {
            throw ActionMacroError.mustBeAppliedToEnumOrStruct
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        // Get the type name
        let typeName = if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            enumDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            structDecl.name.text
        } else {
            throw ActionMacroError.mustBeAppliedToEnumOrStruct
        }
        
        // Generate extensions
        let actionExtension = try generateActionExtension(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters,
            context: context
        )
        
        let executionExtension = try generateExecutionExtension(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters,
            context: context
        )
        
        return [actionExtension, executionExtension]
    }
    
    // MARK: - Parameter Extraction
    
    private struct ActionMacroParameters {
        let enableValidation: Bool
        let trackPerformance: Bool
        let enableRetry: Bool
        let timeout: Double?
        let priority: String
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> ActionMacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // Default parameters
            return ActionMacroParameters(
                enableValidation: true,
                trackPerformance: true,
                enableRetry: false,
                timeout: nil,
                priority: "medium"
            )
        }
        
        var enableValidation = true
        var trackPerformance = true
        var enableRetry = false
        var timeout: Double?
        var priority = "medium"
        
        for argument in arguments {
            switch argument.label?.text {
            case "validation":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableValidation = boolLiteral.literal.text == "true"
                }
            case "performance":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    trackPerformance = boolLiteral.literal.text == "true"
                }
            case "retry":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableRetry = boolLiteral.literal.text == "true"
                }
            case "timeout":
                if let floatLiteral = argument.expression.as(FloatLiteralExprSyntax.self) {
                    timeout = Double(floatLiteral.literal.text) ?? 5.0
                }
            case "priority":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    priority = stringLiteral.segments.description
                        .trimmingCharacters(in: CharacterSet(["\"", " "]))
                }
            default:
                break
            }
        }
        
        return ActionMacroParameters(
            enableValidation: enableValidation,
            trackPerformance: trackPerformance,
            enableRetry: enableRetry,
            timeout: timeout,
            priority: priority
        )
    }
    
    // MARK: - Extension Generation
    
    private static func generateActionExtension(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        // Generate Sendable conformance and basic action protocol support
        let actionCode = generateActionConformanceCode(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName): Sendable {
                \(raw: actionCode)
            }
            """
        )
    }
    
    private static func generateExecutionExtension(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        let executionCode = generateExecutionPipelineCode(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName) {
                \(raw: executionCode)
            }
            """
        )
    }
    
    // MARK: - Code Generation Helpers
    
    private static func generateActionConformanceCode(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters
    ) -> String {
        var code = """
        
        // MARK: - Generated Action Protocol Conformance
        
        /// Action identifier for tracking and debugging
        public var actionId: String {
            return "\\(type(of: self)).\\(String(describing: self))"
        }
        
        /// Action priority for execution scheduling
        public var priority: ActionPriority {
            return .\(parameters.priority)
        }
        
        /// Action metadata for analytics and debugging
        public var metadata: ActionMetadata {
            return ActionMetadata(
                id: actionId,
                priority: priority,
                timestamp: Date(),
                source: "\(typeName)"
            )
        }
        """
        
        if parameters.enableValidation {
            code += """
            
            // MARK: - Action Validation
            
            /// Validates the action before execution
            public func validate() -> ActionValidationResult {
                var issues: [String] = []
                
                // Perform action-specific validation
                let customValidation = performCustomValidation()
                if !customValidation.isValid {
                    issues.append(contentsOf: customValidation.issues)
                }
                
                // Validate action parameters
                if !validateParameters() {
                    issues.append("Invalid action parameters")
                }
                
                return ActionValidationResult(
                    isValid: issues.isEmpty,
                    issues: issues,
                    action: self
                )
            }
            
            /// Custom validation logic - override in extensions
            private func performCustomValidation() -> ActionValidationResult {
                return ActionValidationResult(isValid: true, issues: [], action: self)
            }
            
            /// Validates action parameters
            private func validateParameters() -> Bool {
                // Default implementation - override for specific validation
                return true
            }
            """
        }
        
        return code
    }
    
    private static func generateExecutionPipelineCode(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters
    ) -> String {
        var code = """
        
        // MARK: - Generated Execution Pipeline
        
        /// Execute action with full pipeline support
        public func execute<StateType: State>(
            on client: any Client<StateType, Self>,
            with context: ActionExecutionContext = ActionExecutionContext()
        ) async throws -> ActionExecutionResult {
            let startTime = CFAbsoluteTimeGetCurrent()
            var executionContext = context
            executionContext.actionId = actionId
            executionContext.startTime = startTime
            
            // Pre-execution phase
            try await preExecution(context: &executionContext)
            
            // Validation phase
            \(parameters.enableValidation ? """
            let validationResult = validate()
            guard validationResult.isValid else {
                throw ActionExecutionError.validationFailed(validationResult.issues)
            }
            """ : "")
            
            // Execution phase with optional retry
            let result: ActionExecutionResult
            \(parameters.enableRetry ? """
            result = try await executeWithRetry(on: client, context: executionContext)
            """ : """
            result = try await performExecution(on: client, context: executionContext)
            """)
            
            // Post-execution phase
            await postExecution(result: result, context: executionContext)
            
            // Performance tracking
            \(parameters.trackPerformance ? """
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            await trackPerformance(duration: duration, result: result)
            """ : "")
            
            return result
        }
        
        /// Pre-execution hook
        private func preExecution(context: inout ActionExecutionContext) async throws {
            context.phase = .preExecution
            
            // Timeout setup
            \(parameters.timeout != nil ? """
            context.timeout = \(parameters.timeout!)
            """ : "")
            
            // Custom pre-execution logic
            await customPreExecution(context: &context)
        }
        
        /// Post-execution hook
        private func postExecution(result: ActionExecutionResult, context: ActionExecutionContext) async {
            // Custom post-execution logic
            await customPostExecution(result: result, context: context)
        }
        
        /// Custom pre-execution hook - override in extensions
        func customPreExecution(context: inout ActionExecutionContext) async {
            // Override in extension
        }
        
        /// Custom post-execution hook - override in extensions
        func customPostExecution(result: ActionExecutionResult, context: ActionExecutionContext) async {
            // Override in extension
        }
        """
        
        if parameters.enableRetry {
            code += """
            
            // MARK: - Retry Logic
            
            /// Execute action with retry support
            private func executeWithRetry<StateType: State>(
                on client: any Client<StateType, Self>,
                context: ActionExecutionContext
            ) async throws -> ActionExecutionResult {
                let maxRetries = 3
                var lastError: Error?
                
                for attempt in 0..<maxRetries {
                    do {
                        return try await performExecution(on: client, context: context)
                    } catch {
                        lastError = error
                        
                        // Don't retry on validation errors
                        if error is ActionExecutionError {
                            throw error
                        }
                        
                        // Wait before retry with exponential backoff
                        if attempt < maxRetries - 1 {
                            let delay = pow(2.0, Double(attempt)) * 0.1 // 100ms, 200ms, 400ms
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                    }
                }
                
                throw lastError ?? ActionExecutionError.maxRetriesExceeded
            }
            """
        }
        
        code += """
        
        /// Core execution logic
        private func performExecution<StateType: State>(
            on client: any Client<StateType, Self>,
            context: ActionExecutionContext
        ) async throws -> ActionExecutionResult {
            \(parameters.timeout != nil ? """
            // Execute with timeout
            return try await withThrowingTaskGroup(of: ActionExecutionResult.self) { group in
                group.addTask {
                    try await client.process(self)
                    return ActionExecutionResult(
                        success: true,
                        action: self,
                        duration: CFAbsoluteTimeGetCurrent() - context.startTime,
                        context: context
                    )
                }
                
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(\(parameters.timeout!) * 1_000_000_000))
                    throw ActionExecutionError.timeout
                }
                
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            """ : """
            // Execute without timeout
            try await client.process(self)
            return ActionExecutionResult(
                success: true,
                action: self,
                duration: CFAbsoluteTimeGetCurrent() - context.startTime,
                context: context
            )
            """)
        }
        """
        
        if parameters.trackPerformance {
            code += """
            
            // MARK: - Performance Tracking
            
            /// Track action execution performance
            private func trackPerformance(duration: Double, result: ActionExecutionResult) async {
                let metrics = ActionPerformanceMetrics(
                    actionId: actionId,
                    duration: duration,
                    success: result.success,
                    timestamp: Date()
                )
                
                // Send to performance monitoring system
                await ActionPerformanceTracker.shared.record(metrics)
            }
            """
        }
        
        return code
    }
}

// MARK: - Supporting Types

/// Action priority levels
public enum ActionPriority: String, CaseIterable {
    case low, medium, high, critical
}

/// Action metadata for tracking
public struct ActionMetadata {
    public let id: String
    public let priority: ActionPriority
    public let timestamp: Date
    public let source: String
    
    public init(id: String, priority: ActionPriority, timestamp: Date, source: String) {
        self.id = id
        self.priority = priority
        self.timestamp = timestamp
        self.source = source
    }
}

/// Action validation result
public struct ActionValidationResult {
    public let isValid: Bool
    public let issues: [String]
    public let action: Any
    
    public init(isValid: Bool, issues: [String], action: Any) {
        self.isValid = isValid
        self.issues = issues
        self.action = action
    }
}

/// Action execution context
public struct ActionExecutionContext {
    public var actionId: String = ""
    public var startTime: CFAbsoluteTime = 0
    public var timeout: Double?
    public var phase: ExecutionPhase = .created
    public var metadata: [String: Any] = [:]
    
    public enum ExecutionPhase {
        case created, preExecution, executing, postExecution, completed
    }
    
    public init() {}
}

/// Action execution result
public struct ActionExecutionResult {
    public let success: Bool
    public let action: Any
    public let duration: Double
    public let context: ActionExecutionContext
    public let error: Error?
    
    public init(success: Bool, action: Any, duration: Double, context: ActionExecutionContext, error: Error? = nil) {
        self.success = success
        self.action = action
        self.duration = duration
        self.context = context
        self.error = error
    }
}

/// Action execution errors
public enum ActionExecutionError: Error {
    case validationFailed([String])
    case timeout
    case maxRetriesExceeded
    case executionFailed(Error)
}

/// Performance metrics for actions
public struct ActionPerformanceMetrics {
    public let actionId: String
    public let duration: Double
    public let success: Bool
    public let timestamp: Date
    
    public init(actionId: String, duration: Double, success: Bool, timestamp: Date) {
        self.actionId = actionId
        self.duration = duration
        self.success = success
        self.timestamp = timestamp
    }
}

/// Performance tracker singleton
public actor ActionPerformanceTracker {
    public static let shared = ActionPerformanceTracker()
    
    private var metrics: [ActionPerformanceMetrics] = []
    
    public func record(_ metric: ActionPerformanceMetrics) {
        metrics.append(metric)
        
        // Keep only recent metrics (last 1000)
        if metrics.count > 1000 {
            metrics = Array(metrics.suffix(1000))
        }
    }
    
    public func getMetrics(for actionId: String) -> [ActionPerformanceMetrics] {
        return metrics.filter { $0.actionId == actionId }
    }
}

// MARK: - Error Types

enum ActionMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToEnumOrStruct
    case invalidParameters
    case missingRequiredCases
    
    var description: String {
        switch self {
        case .mustBeAppliedToEnumOrStruct:
            return "@Action can only be applied to enum or struct declarations"
        case .invalidParameters:
            return "@Action has invalid parameters"
        case .missingRequiredCases:
            return "@Action requires at least one case or property"
        }
    }
}