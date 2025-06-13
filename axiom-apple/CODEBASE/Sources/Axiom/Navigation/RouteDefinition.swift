import Foundation
import SwiftUI

// MARK: - Core Route Definitions and Types (W-04-005)

// MARK: - Presentation Style Definition

/// Presentation style for route navigation
public enum PresentationStyle: Equatable, Hashable, Sendable {
    case push
    case replace
    case present(ModalPresentationStyle)
    
    /// Modal presentation styles
    public enum ModalPresentationStyle: Equatable, Hashable, Sendable {
        case sheet
        case fullScreenCover
        case popover
    }
}

// MARK: - Core Route Types

/// Route definition for compilation and validation
public struct RouteDefinition: Equatable, Hashable {
    public let identifier: String
    public let path: String
    public let parameters: [RouteParameter]
    public let presentation: PresentationStyle
    
    public init(identifier: String, path: String, parameters: [RouteParameter], presentation: PresentationStyle) {
        self.identifier = identifier
        self.path = path
        self.parameters = parameters
        self.presentation = presentation
    }
}

/// Route parameter definition with type safety
public enum RouteParameter: Equatable, Hashable {
    case required(String, Any.Type)
    case optional(String, Any.Type)
    
    public var name: String {
        switch self {
        case .required(let name, _), .optional(let name, _):
            return name
        }
    }
    
    public var isRequired: Bool {
        switch self {
        case .required:
            return true
        case .optional:
            return false
        }
    }
    
    public var type: Any.Type {
        switch self {
        case .required(_, let type), .optional(_, let type):
            return type
        }
    }
    
    public static func == (lhs: RouteParameter, rhs: RouteParameter) -> Bool {
        return lhs.name == rhs.name && lhs.isRequired == rhs.isRequired
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isRequired)
    }
}

/// Route validation errors
public enum RouteValidationError: Error, Equatable {
    case duplicateIdentifier(String)
    case invalidPathSyntax(String)
    case conflictingPattern(String)
    case requiredParameterCannotBeOptional(String)
    case parameterPathMismatch(String, String)
    case emptyIdentifier
    case emptyPath
    case missingParameterDefinition(String)
    case cyclicDependency([String])
    case unreachableRoute(String)
    
    public static func == (lhs: RouteValidationError, rhs: RouteValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateIdentifier(let a), .duplicateIdentifier(let b)):
            return a == b
        case (.invalidPathSyntax(let a), .invalidPathSyntax(let b)):
            return a == b
        case (.conflictingPattern(let a), .conflictingPattern(let b)):
            return a == b
        case (.requiredParameterCannotBeOptional(let a), .requiredParameterCannotBeOptional(let b)):
            return a == b
        case (.parameterPathMismatch(let a1, let a2), .parameterPathMismatch(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.emptyIdentifier, .emptyIdentifier):
            return true
        case (.emptyPath, .emptyPath):
            return true
        case (.missingParameterDefinition(let a), .missingParameterDefinition(let b)):
            return a == b
        case (.cyclicDependency(let a), .cyclicDependency(let b)):
            return a == b
        case (.unreachableRoute(let a), .unreachableRoute(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Route compilation result
public struct RouteCompilationResult {
    public let isSuccess: Bool
    public let errors: [RouteValidationError]
    public let warnings: [String]
    public let compiledRoutes: [String: CompiledRoute]
    
    public init(isSuccess: Bool, errors: [RouteValidationError] = [], warnings: [String] = [], compiledRoutes: [String: CompiledRoute] = [:]) {
        self.isSuccess = isSuccess
        self.errors = errors
        self.warnings = warnings
        self.compiledRoutes = compiledRoutes
    }
}

/// Compiled route information
public struct CompiledRoute {
    public let definition: RouteDefinition
    public let pathPattern: String
    public let parameterTypes: [String: Any.Type]
    public let isValid: Bool
    
    public init(definition: RouteDefinition, pathPattern: String, parameterTypes: [String: Any.Type], isValid: Bool) {
        self.definition = definition
        self.pathPattern = pathPattern
        self.parameterTypes = parameterTypes
        self.isValid = isValid
    }
}

/// Route manifest for build-time information
public struct RouteManifest {
    public let routes: [String: RouteInfo]
    public let timestamp: Date
    public let version: String
    
    public init(routes: [String: RouteInfo], timestamp: Date = Date(), version: String = "1.0") {
        self.routes = routes
        self.timestamp = timestamp
        self.version = version
    }
}

/// Route information in manifest
public struct RouteInfo {
    public let path: String
    public let parameters: [RouteParameter]
    public let presentation: PresentationStyle
    public let isValid: Bool
    
    public init(path: String, parameters: [RouteParameter], presentation: PresentationStyle, isValid: Bool = true) {
        self.path = path
        self.parameters = parameters
        self.presentation = presentation
        self.isValid = isValid
    }
}

/// Route exhaustiveness check result
public struct RouteExhaustivenessResult {
    public let isComplete: Bool
    public let missingHandlers: [String]
    public let registeredHandlers: [String]
    
    public init(isComplete: Bool, missingHandlers: [String], registeredHandlers: [String]) {
        self.isComplete = isComplete
        self.missingHandlers = missingHandlers
        self.registeredHandlers = registeredHandlers
    }
}

/// Type system compatibility result
public struct TypeSystemCompatibilityResult {
    public let isCompatible: Bool
    public let incompatibleRoutes: [String]
    public let compatibilityIssues: [String]
    
    public init(isCompatible: Bool, incompatibleRoutes: [String] = [], compatibilityIssues: [String] = []) {
        self.isCompatible = isCompatible
        self.incompatibleRoutes = incompatibleRoutes
        self.compatibilityIssues = compatibilityIssues
    }
}

// MARK: - Validation Report Types

/// Validation report structure
public struct ValidationReport {
    public let timestamp: Date
    public let routes: RouteStats
    public let graph: GraphStats
    public let performance: PerformanceStats
    
    public struct RouteStats {
        public let total: Int
        public let valid: Int
        public let warnings: Int
        public let errors: Int
        
        public init(total: Int, valid: Int, warnings: Int, errors: Int) {
            self.total = total
            self.valid = valid
            self.warnings = warnings
            self.errors = errors
        }
    }
    
    public struct GraphStats {
        public let cycles: [[String]]
        public let unreachable: [String]
        public let maxDepth: Int
        
        public init(cycles: [[String]], unreachable: [String], maxDepth: Int) {
            self.cycles = cycles
            self.unreachable = unreachable
            self.maxDepth = maxDepth
        }
    }
    
    public struct PerformanceStats {
        public let validationTime: String
        public let routeCount: Int
        public let patternComplexity: String
        
        public init(validationTime: String, routeCount: Int, patternComplexity: String) {
            self.validationTime = validationTime
            self.routeCount = routeCount
            self.patternComplexity = patternComplexity
        }
    }
    
    public init(timestamp: Date, routes: RouteStats, graph: GraphStats, performance: PerformanceStats) {
        self.timestamp = timestamp
        self.routes = routes
        self.graph = graph
        self.performance = performance
    }
}

/// Route build validation result
public struct RouteValidationResult {
    public let isSuccess: Bool
    public let report: ValidationReport
    
    public init(isSuccess: Bool, report: ValidationReport) {
        self.isSuccess = isSuccess
        self.report = report
    }
}

// MARK: - SwiftLint Integration Types

/// SwiftLint validation result
public struct SwiftLintResult {
    public let errors: [SwiftLintError]
    public let warnings: [SwiftLintWarning]
    
    public var hasErrors: Bool { !errors.isEmpty }
    public var hasWarnings: Bool { !warnings.isEmpty }
    
    public init(errors: [SwiftLintError], warnings: [SwiftLintWarning]) {
        self.errors = errors
        self.warnings = warnings
    }
}

/// SwiftLint error
public struct SwiftLintError {
    public let rule: String
    public let message: String
    public let line: Int
    
    public init(rule: String, message: String, line: Int) {
        self.rule = rule
        self.message = message
        self.line = line
    }
}

/// SwiftLint warning
public struct SwiftLintWarning {
    public let rule: String
    public let message: String
    public let line: Int
    
    public init(rule: String, message: String, line: Int) {
        self.rule = rule
        self.message = message
        self.line = line
    }
}

// MARK: - Testing Support Types

/// Route validation result for testing
public struct RouteTestValidationResult {
    public let isValid: Bool
    public let warnings: [String]
    
    public init(isValid: Bool, warnings: [String]) {
        self.isValid = isValid
        self.warnings = warnings
    }
}

// MARK: - Performance Metric Types

/// Performance metric for tracking operations
public struct PerformanceMetric: Sendable {
    public let operation: String
    public let duration: TimeInterval
    public let itemCount: Int
    public let timestamp: Date
    
    public init(operation: String, duration: TimeInterval, itemCount: Int, timestamp: Date = Date()) {
        self.operation = operation
        self.duration = duration
        self.itemCount = itemCount
        self.timestamp = timestamp
    }
}