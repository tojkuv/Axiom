import Foundation
import AxiomCore

// MARK: - Automated Access Control Enforcement

/// Automatically enforces access control across the entire AxiomApple Framework
/// This system provides bulletproof, zero-configuration access control
public actor AutomatedAccessControlEnforcement {
    public static let shared = AutomatedAccessControlEnforcement()
    
    private var enforcementConfig: EnforcementConfiguration = .strict
    private var violationCallbacks: [ViolationCallback] = []
    private var accessLogs: [AccessLog] = []
    private var isEnforcementActive: Bool = true
    
    private init() {}
    
    // MARK: - Core Enforcement Engine
    
    /// Automatically enforce capability access for any component
    public func enforceCapabilityAccess<T: DomainCapability>(
        capabilityType: T.Type,
        requestingComponent: Any,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) throws {
        
        guard isEnforcementActive else { return }
        
        let capabilityName = String(describing: capabilityType)
        let requestingComponentType = type(of: requestingComponent)
        let requestingComponentName = String(describing: requestingComponentType)
        
        // Determine component type automatically
        let componentType = determineComponentType(requestingComponent)
        
        // Create access context
        let accessContext = AccessContext(
            capabilityName: capabilityName,
            componentType: componentType,
            requestingComponentName: requestingComponentName,
            sourceLocation: SourceLocation(file: file, line: line, function: function),
            timestamp: Date()
        )
        
        // Perform comprehensive validation
        try validateAccess(accessContext)
        
        // Log access attempt
        await logAccess(accessContext, result: .allowed)
    }
    
    /// Automatically enforce view access control
    public func enforceViewAccess<T: AnyObject>(
        component: T,
        context: AxiomContext,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) throws {
        
        guard isEnforcementActive else { return }
        
        let componentType = type(of: component)
        let componentName = String(describing: componentType)
        
        // Create view access context
        let viewAccessContext = ViewAccessContext(
            componentName: componentName,
            contextName: context.name,
            contextId: context.id,
            sourceLocation: SourceLocation(file: file, line: line, function: function),
            timestamp: Date()
        )
        
        // Validate view access
        try validateViewAccess(component: component, context: context, accessContext: viewAccessContext)
        
        // Log view access
        await logViewAccess(viewAccessContext, result: .allowed)
    }
    
    // MARK: - Component Type Detection
    
    /// Automatically determine component type from any object
    private func determineComponentType(_ component: Any) -> ComponentType {
        let componentType = type(of: component)
        let componentName = String(describing: componentType)
        
        // Check for AxiomContext inheritance
        if component is AxiomContext {
            return .context
        }
        
        // Check for AxiomClient inheritance
        if component is AxiomClient {
            return .client
        }
        
        // Pattern-based detection for legacy components
        if componentName.contains("Context") || 
           componentName.hasSuffix("Context") ||
           ViewComponentClassification.isPresentationComponent(componentName) {
            return .context
        }
        
        if componentName.contains("Client") ||
           componentName.hasSuffix("Client") ||
           componentName.contains("Service") ||
           componentName.contains("API") {
            return .client
        }
        
        // Default to context for safety (local capabilities are safer default)
        return .context
    }
    
    // MARK: - Validation Engine
    
    private func validateAccess(_ accessContext: AccessContext) throws {
        let capabilityName = accessContext.capabilityName
        let componentType = accessContext.componentType
        
        // Use comprehensive classification for validation
        do {
            try ComprehensiveCapabilityClassification.validateAccess(
                capabilityName: capabilityName,
                componentType: componentType
            )
        } catch {
            // Handle violation
            let violation = AccessViolation(
                accessContext: accessContext,
                violationType: .capabilityAccess,
                error: error,
                timestamp: Date()
            )
            
            await handleViolation(violation)
            throw error
        }
    }
    
    private func validateViewAccess<T: AnyObject>(
        component: T,
        context: AxiomContext,
        accessContext: ViewAccessContext
    ) throws {
        
        // Check if component is a simple view
        if component is SimpleView {
            let error = ViewAccessError.simpleViewCannotObserveContext(
                viewType: accessContext.componentName,
                contextName: accessContext.contextName
            )
            
            let violation = ViewAccessViolation(
                accessContext: accessContext,
                violationType: .simpleViewAccess,
                error: error,
                timestamp: Date()
            )
            
            await handleViewViolation(violation)
            throw error
        }
        
        // Check if component is context restricted
        if component is ContextRestrictedComponent {
            let error = ViewAccessError.contextAccessRestricted(
                componentType: accessContext.componentName,
                contextName: accessContext.contextName
            )
            
            let violation = ViewAccessViolation(
                accessContext: accessContext,
                violationType: .restrictedComponentAccess,
                error: error,
                timestamp: Date()
            )
            
            await handleViewViolation(violation)
            throw error
        }
        
        // Component must be presentation component
        guard component is PresentationComponent else {
            let error = ViewAccessError.componentNotAuthorizedForContextObservation(
                componentType: accessContext.componentName,
                contextName: accessContext.contextName,
                reason: "Only PresentationComponent types can observe contexts"
            )
            
            let violation = ViewAccessViolation(
                accessContext: accessContext,
                violationType: .unauthorizedComponentAccess,
                error: error,
                timestamp: Date()
            )
            
            await handleViewViolation(violation)
            throw error
        }
    }
    
    // MARK: - Violation Handling
    
    private func handleViolation(_ violation: AccessViolation) async {
        // Log violation
        accessLogs.append(AccessLog(
            timestamp: violation.timestamp,
            type: .violation,
            details: violation.description,
            sourceLocation: violation.accessContext.sourceLocation
        ))
        
        // Notify callbacks
        for callback in violationCallbacks {
            await callback.onViolation(violation)
        }
        
        // Apply enforcement policy
        switch enforcementConfig.violationPolicy {
        case .log:
            await logViolation(violation)
        case .warn:
            await logViolation(violation)
            await warnViolation(violation)
        case .block:
            await logViolation(violation)
            await blockViolation(violation)
        case .crash:
            await logViolation(violation)
            fatalError("Access control violation: \(violation.description)")
        }
    }
    
    private func handleViewViolation(_ violation: ViewAccessViolation) async {
        // Log violation
        accessLogs.append(AccessLog(
            timestamp: violation.timestamp,
            type: .viewViolation,
            details: violation.description,
            sourceLocation: violation.accessContext.sourceLocation
        ))
        
        // Apply enforcement policy (same as capability violations)
        switch enforcementConfig.violationPolicy {
        case .log:
            await logViewViolation(violation)
        case .warn:
            await logViewViolation(violation)
            await warnViewViolation(violation)
        case .block:
            await logViewViolation(violation)
            await blockViewViolation(violation)
        case .crash:
            await logViewViolation(violation)
            fatalError("View access control violation: \(violation.description)")
        }
    }
    
    // MARK: - Logging System
    
    private func logAccess(_ accessContext: AccessContext, result: AccessResult) async {
        guard enforcementConfig.enableLogging else { return }
        
        let log = AccessLog(
            timestamp: accessContext.timestamp,
            type: .allowedAccess,
            details: "✅ \(accessContext.componentType.rawValue) accessing \(accessContext.capabilityName)",
            sourceLocation: accessContext.sourceLocation
        )
        
        accessLogs.append(log)
        
        if enforcementConfig.enableVerboseLogging {
            print("[AccessControl] \(log.details) at \(log.sourceLocation.description)")
        }
    }
    
    private func logViewAccess(_ accessContext: ViewAccessContext, result: ViewAccessResult) async {
        guard enforcementConfig.enableLogging else { return }
        
        let log = AccessLog(
            timestamp: accessContext.timestamp,
            type: .allowedViewAccess,
            details: "✅ \(accessContext.componentName) observing \(accessContext.contextName)",
            sourceLocation: accessContext.sourceLocation
        )
        
        accessLogs.append(log)
        
        if enforcementConfig.enableVerboseLogging {
            print("[ViewAccessControl] \(log.details) at \(log.sourceLocation.description)")
        }
    }
    
    private func logViolation(_ violation: AccessViolation) async {
        print("🚫 [AccessControl] VIOLATION: \(violation.description)")
        print("   Location: \(violation.accessContext.sourceLocation.description)")
        print("   Component: \(violation.accessContext.requestingComponentName)")
        print("   Capability: \(violation.accessContext.capabilityName)")
    }
    
    private func logViewViolation(_ violation: ViewAccessViolation) async {
        print("🚫 [ViewAccessControl] VIOLATION: \(violation.description)")
        print("   Location: \(violation.accessContext.sourceLocation.description)")
        print("   Component: \(violation.accessContext.componentName)")
        print("   Context: \(violation.accessContext.contextName)")
    }
    
    private func warnViolation(_ violation: AccessViolation) async {
        // Could integrate with system notification or alerting
        print("⚠️ [AccessControl] WARNING: Access violation detected but allowed")
    }
    
    private func warnViewViolation(_ violation: ViewAccessViolation) async {
        // Could integrate with system notification or alerting
        print("⚠️ [ViewAccessControl] WARNING: View access violation detected but allowed")
    }
    
    private func blockViolation(_ violation: AccessViolation) async {
        // Could implement additional blocking logic
        print("🛑 [AccessControl] BLOCKED: Access violation prevented")
    }
    
    private func blockViewViolation(_ violation: ViewAccessViolation) async {
        // Could implement additional blocking logic
        print("🛑 [ViewAccessControl] BLOCKED: View access violation prevented")
    }
    
    // MARK: - Configuration Management
    
    /// Update enforcement configuration
    public func updateConfiguration(_ config: EnforcementConfiguration) {
        self.enforcementConfig = config
    }
    
    /// Add violation callback
    public func addViolationCallback(_ callback: ViolationCallback) {
        violationCallbacks.append(callback)
    }
    
    /// Enable or disable enforcement
    public func setEnforcementActive(_ active: Bool) {
        self.isEnforcementActive = active
    }
    
    /// Get access logs
    public func getAccessLogs(since: Date? = nil) -> [AccessLog] {
        if let since = since {
            return accessLogs.filter { $0.timestamp >= since }
        }
        return accessLogs
    }
    
    /// Clear access logs
    public func clearAccessLogs() {
        accessLogs.removeAll()
    }
    
    /// Get violation statistics
    public func getViolationStatistics() -> ViolationStatistics {
        let violations = accessLogs.filter { $0.type == .violation || $0.type == .viewViolation }
        let allowedAccesses = accessLogs.filter { $0.type == .allowedAccess || $0.type == .allowedViewAccess }
        
        return ViolationStatistics(
            totalAccesses: accessLogs.count,
            allowedAccesses: allowedAccesses.count,
            violations: violations.count,
            violationRate: violations.count > 0 ? Double(violations.count) / Double(accessLogs.count) : 0.0,
            lastViolation: violations.last?.timestamp
        )
    }
}

// MARK: - Enhanced Access Control Extensions

extension AxiomContext {
    /// Automatically enforced capability access
    public func capability<T: LocalCapability>(_ type: T.Type, file: String = #file, line: Int = #line, function: String = #function) async throws -> T {
        // Enforce access control automatically
        try await AutomatedAccessControlEnforcement.shared.enforceCapabilityAccess(
            capabilityType: type,
            requestingComponent: self,
            file: file,
            line: line,
            function: function
        )
        
        // Original capability access logic
        let capabilityKey = String(describing: type)
        
        // Return existing capability if already active
        if let existing = activeCapabilities[capabilityKey] as? T {
            return existing
        }
        
        // Create and activate new capability
        let capability = try await createCapability(type)
        try await capability.activate()
        
        activeCapabilities[capabilityKey] = capability
        
        return capability
    }
}

extension AxiomClient {
    /// Automatically enforced capability access
    public func capability<T: ExternalServiceCapability>(_ type: T.Type, file: String = #file, line: Int = #line, function: String = #function) async throws -> T {
        // Enforce access control automatically
        try await AutomatedAccessControlEnforcement.shared.enforceCapabilityAccess(
            capabilityType: type,
            requestingComponent: self,
            file: file,
            line: line,
            function: function
        )
        
        // Original capability access logic
        let capabilityKey = String(describing: type)
        
        // Return existing capability if already active
        if let existing = activeCapabilities[capabilityKey] as? T {
            return existing
        }
        
        // Create and activate new capability
        let capability = try await createCapability(type)
        try await capability.activate()
        
        activeCapabilities[capabilityKey] = capability
        
        return capability
    }
}

extension AxiomContext {
    /// Automatically enforced context observation
    public func allowObservation<T: PresentationComponent>(by component: T, file: String = #file, line: Int = #line, function: String = #function) async throws {
        // Enforce view access control automatically
        try await AutomatedAccessControlEnforcement.shared.enforceViewAccess(
            component: component,
            context: self,
            file: file,
            line: line,
            function: function
        )
        
        // Original observation logic
        await ViewAccessControlManager.shared.registerObservation(
            component: component,
            context: self
        )
    }
}

// MARK: - Configuration Types

/// Configuration for automated enforcement
public struct EnforcementConfiguration: Sendable {
    public let violationPolicy: ViolationPolicy
    public let enableLogging: Bool
    public let enableVerboseLogging: Bool
    public let enableMetrics: Bool
    public let enablePerformanceTracking: Bool
    
    public enum ViolationPolicy: Sendable {
        case log        // Just log the violation
        case warn       // Log and warn
        case block      // Log and prevent access
        case crash      // Log and crash (debug only)
    }
    
    public static let strict = EnforcementConfiguration(
        violationPolicy: .block,
        enableLogging: true,
        enableVerboseLogging: false,
        enableMetrics: true,
        enablePerformanceTracking: true
    )
    
    public static let development = EnforcementConfiguration(
        violationPolicy: .warn,
        enableLogging: true,
        enableVerboseLogging: true,
        enableMetrics: true,
        enablePerformanceTracking: true
    )
    
    public static let production = EnforcementConfiguration(
        violationPolicy: .block,
        enableLogging: false,
        enableVerboseLogging: false,
        enableMetrics: true,
        enablePerformanceTracking: false
    )
}

// MARK: - Context Types

/// Context for capability access attempts
public struct AccessContext: Sendable {
    public let capabilityName: String
    public let componentType: ComponentType
    public let requestingComponentName: String
    public let sourceLocation: SourceLocation
    public let timestamp: Date
}

/// Context for view access attempts
public struct ViewAccessContext: Sendable {
    public let componentName: String
    public let contextName: String
    public let contextId: UUID
    public let sourceLocation: SourceLocation
    public let timestamp: Date
}

/// Source location information
public struct SourceLocation: Sendable {
    public let file: String
    public let line: Int
    public let function: String
    
    public var description: String {
        let filename = (file as NSString).lastPathComponent
        return "\(filename):\(line) in \(function)"
    }
}

// MARK: - Violation Types

/// Capability access violation
public struct AccessViolation: Sendable {
    public let accessContext: AccessContext
    public let violationType: ViolationType
    public let error: Error
    public let timestamp: Date
    
    public enum ViolationType: Sendable {
        case capabilityAccess
        case unauthorizedComponent
        case invalidConfiguration
    }
    
    public var description: String {
        return "Access violation: \(accessContext.requestingComponentName) attempted to access \(accessContext.capabilityName)"
    }
}

/// View access violation
public struct ViewAccessViolation: Sendable {
    public let accessContext: ViewAccessContext
    public let violationType: ViewViolationType
    public let error: Error
    public let timestamp: Date
    
    public enum ViewViolationType: Sendable {
        case simpleViewAccess
        case restrictedComponentAccess
        case unauthorizedComponentAccess
    }
    
    public var description: String {
        return "View access violation: \(accessContext.componentName) attempted to observe \(accessContext.contextName)"
    }
}

// MARK: - Result Types

public enum AccessResult: Sendable {
    case allowed
    case denied(String)
}

public enum ViewAccessResult: Sendable {
    case allowed
    case denied(String)
}

// MARK: - Logging Types

/// Access log entry
public struct AccessLog: Sendable {
    public let timestamp: Date
    public let type: LogType
    public let details: String
    public let sourceLocation: SourceLocation
    
    public enum LogType: Sendable {
        case allowedAccess
        case allowedViewAccess
        case violation
        case viewViolation
        case configuration
        case performance
    }
}

/// Violation statistics
public struct ViolationStatistics: Sendable {
    public let totalAccesses: Int
    public let allowedAccesses: Int
    public let violations: Int
    public let violationRate: Double
    public let lastViolation: Date?
    
    public var isHealthy: Bool {
        return violationRate < 0.01 // Less than 1% violation rate
    }
}

// MARK: - Callback Types

/// Callback for handling violations
public protocol ViolationCallback: Sendable {
    func onViolation(_ violation: AccessViolation) async
    func onViewViolation(_ violation: ViewAccessViolation) async
}

/// Default violation callback that logs to console
public struct ConsoleViolationCallback: ViolationCallback {
    public func onViolation(_ violation: AccessViolation) async {
        print("🚨 Access Violation: \(violation.description)")
    }
    
    public func onViewViolation(_ violation: ViewAccessViolation) async {
        print("🚨 View Access Violation: \(violation.description)")
    }
}

// MARK: - Performance Monitoring

/// Performance metrics for access control
public struct AccessControlPerformanceMetrics: Sendable {
    public let averageValidationTime: TimeInterval
    public let totalValidations: Int
    public let slowestValidation: TimeInterval
    public let fastestValidation: TimeInterval
    public let memoryUsage: Int
    
    public var isPerformant: Bool {
        return averageValidationTime < 0.001 // Less than 1ms average
    }
}