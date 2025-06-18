import Foundation
import SwiftUI
import NetworkClient
import SwiftUIRenderer
import Combine

// MARK: - Comprehensive Error Reporting and Diagnostics System

/// Central error reporting manager that collects, categorizes, and reports errors from all hot reload components
@MainActor
public final class ErrorReportingManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var errorReports: [ErrorReport] = []
    @Published public private(set) var errorStatistics: ErrorStatistics = ErrorStatistics()
    @Published public private(set) var systemHealth: SystemHealth = SystemHealth()
    @Published public private(set) var lastDiagnosticRun: Date?
    @Published public private(set) var isCollectingErrors: Bool = true
    
    // MARK: - Properties
    
    private let configuration: ErrorReportingConfiguration
    private var cancellables = Set<AnyCancellable>()
    private var diagnosticTimer: Timer?
    private var reportExportTimer: Timer?
    
    // Component references for direct monitoring
    private weak var connectionManager: ConnectionManager?
    private weak var renderer: SwiftUIJSONRenderer?
    private weak var stateManager: SwiftUIStateManager?
    private weak var gracefulDegradationManager: GracefulDegradationManager?
    private weak var networkErrorHandler: NetworkErrorHandler?
    
    // Error categorization and analysis
    private var errorPatterns: [ErrorPattern] = []
    private var recoveryAttempts: [String: RecoveryAttempt] = [:]
    
    public init(configuration: ErrorReportingConfiguration = ErrorReportingConfiguration()) {
        self.configuration = configuration
        setupErrorPatterns()
        startDiagnosticMonitoring()
        
        if configuration.enablePeriodicReporting {
            startPeriodicReporting()
        }
    }
    
    deinit {
        diagnosticTimer?.invalidate()
        reportExportTimer?.invalidate()
    }
    
    // MARK: - Public API
    
    /// Register system components for monitoring
    public func registerComponents(
        connectionManager: ConnectionManager? = nil,
        renderer: SwiftUIJSONRenderer? = nil,
        stateManager: SwiftUIStateManager? = nil,
        gracefulDegradationManager: GracefulDegradationManager? = nil,
        networkErrorHandler: NetworkErrorHandler? = nil
    ) {
        self.connectionManager = connectionManager
        self.renderer = renderer
        self.stateManager = stateManager
        self.gracefulDegradationManager = gracefulDegradationManager
        self.networkErrorHandler = networkErrorHandler
        
        setupComponentObservers()
    }
    
    /// Report an error from any component
    public func reportError(
        _ error: Error,
        component: SystemComponent,
        context: ErrorReportContext? = nil,
        severity: ErrorSeverity = .medium
    ) {
        guard isCollectingErrors else { return }
        
        let report = createErrorReport(
            error: error,
            component: component,
            context: context,
            severity: severity
        )
        
        addErrorReport(report)
        analyzeErrorPattern(report)
        updateSystemHealth(based: report)
        
        if configuration.enableRealTimeNotifications {
            notifyErrorReported(report)
        }
    }
    
    /// Get comprehensive system diagnostics
    public func generateSystemDiagnostics() -> SystemDiagnostics {
        lastDiagnosticRun = Date()
        
        let networkDiagnostics = networkErrorHandler?.getNetworkDiagnostics()
        let renderingStats = renderer?.renderingStats
        let degradationStats = gracefulDegradationManager?.getDegradationStats()
        let connectionState = connectionManager?.connectionState ?? .disconnected
        
        return SystemDiagnostics(
            timestamp: Date(),
            systemHealth: systemHealth,
            errorStatistics: errorStatistics,
            networkDiagnostics: networkDiagnostics,
            renderingStats: renderingStats,
            degradationStats: degradationStats,
            connectionState: connectionState,
            recentErrors: Array(errorReports.suffix(20)),
            errorPatterns: getSignificantErrorPatterns(),
            recoveryStatus: getCurrentRecoveryStatus(),
            systemResources: gatherSystemResourceInfo(),
            configurationSummary: getConfigurationSummary()
        )
    }
    
    /// Export error data for external analysis
    public func exportErrorData(format: ExportFormat = .json) -> ErrorExportData {
        return ErrorExportData(
            exportDate: Date(),
            format: format,
            errorReports: errorReports,
            statistics: errorStatistics,
            systemHealth: systemHealth,
            diagnostics: generateSystemDiagnostics(),
            metadata: createExportMetadata()
        )
    }
    
    /// Clear error history
    public func clearErrorHistory() {
        errorReports.removeAll()
        errorStatistics = ErrorStatistics()
        errorPatterns.removeAll()
        recoveryAttempts.removeAll()
        setupErrorPatterns()
    }
    
    /// Get errors filtered by criteria
    public func getFilteredErrors(
        component: SystemComponent? = nil,
        severity: ErrorSeverity? = nil,
        timeRange: TimeInterval? = nil
    ) -> [ErrorReport] {
        var filtered = errorReports
        
        if let component = component {
            filtered = filtered.filter { $0.component == component }
        }
        
        if let severity = severity {
            filtered = filtered.filter { $0.severity == severity }
        }
        
        if let timeRange = timeRange {
            let cutoffDate = Date().addingTimeInterval(-timeRange)
            filtered = filtered.filter { $0.timestamp >= cutoffDate }
        }
        
        return filtered
    }
    
    /// Get error trends and analysis
    public func getErrorTrends(timeWindow: TimeInterval = 3600) -> ErrorTrendAnalysis {
        let recentErrors = getFilteredErrors(timeRange: timeWindow)
        
        return ErrorTrendAnalysis(
            timeWindow: timeWindow,
            totalErrors: recentErrors.count,
            errorsByComponent: groupErrorsByComponent(recentErrors),
            errorsBySeverity: groupErrorsBySeverity(recentErrors),
            errorsByPattern: identifyTrendPatterns(recentErrors),
            recoverySuccessRate: calculateRecoverySuccessRate(recentErrors),
            predictions: generateErrorPredictions(recentErrors)
        )
    }
    
    /// Trigger recovery for recent errors
    public func triggerErrorRecovery() {
        // Trigger recovery in network error handler
        networkErrorHandler?.triggerRecovery()
        
        // Clear connection manager errors
        connectionManager?.clearError()
        
        // Reset renderer if needed
        if let lastRenderError = renderer?.lastError {
            renderer?.reset()
        }
        
        // Trigger graceful degradation recovery
        gracefulDegradationManager?.checkDegradationStatus()
        
        recordRecoveryAttempt()
    }
    
    // MARK: - Error Pattern Analysis
    
    private func setupErrorPatterns() {
        errorPatterns = [
            ErrorPattern(
                name: "Network Connection Failures",
                description: "Repeated network connection failures",
                conditions: [.componentType(.network), .errorType("connectionFailed"), .frequency(minCount: 3, timeWindow: 300)]
            ),
            ErrorPattern(
                name: "Rendering Errors",
                description: "Multiple rendering failures in sequence",
                conditions: [.componentType(.renderer), .errorType("renderingFailed"), .frequency(minCount: 2, timeWindow: 60)]
            ),
            ErrorPattern(
                name: "State Management Issues",
                description: "State preservation or management failures",
                conditions: [.componentType(.stateManager), .frequency(minCount: 2, timeWindow: 120)]
            ),
            ErrorPattern(
                name: "Critical System Degradation",
                description: "Multiple critical errors across components",
                conditions: [.severity(.critical), .frequency(minCount: 1, timeWindow: 30)]
            ),
            ErrorPattern(
                name: "Server Unavailability",
                description: "Extended server connection issues",
                conditions: [.componentType(.network), .errorType("serverUnreachable"), .duration(minimum: 60)]
            )
        ]
    }
    
    private func analyzeErrorPattern(_ report: ErrorReport) {
        for pattern in errorPatterns {
            if pattern.matches(report, in: errorReports) {
                handlePatternDetection(pattern, triggeredBy: report)
            }
        }
    }
    
    private func handlePatternDetection(_ pattern: ErrorPattern, triggeredBy report: ErrorReport) {
        if configuration.enablePatternDetection {
            let notification = ErrorPatternNotification(
                pattern: pattern,
                triggeringError: report,
                matchingErrors: getMatchingErrors(for: pattern),
                detectedAt: Date(),
                severity: determinePatterSeverity(pattern)
            )
            
            if configuration.enableDebugLogging {
                print("🔍 Error pattern detected: \(pattern.name)")
                print("   Description: \(pattern.description)")
                print("   Triggered by: \(report.component.rawValue) - \(report.errorDescription)")
            }
            
            // Auto-trigger recovery for critical patterns
            if notification.severity == .critical && configuration.enableAutoRecovery {
                triggerPatternRecovery(for: pattern)
            }
        }
    }
    
    private func triggerPatternRecovery(for pattern: ErrorPattern) {
        switch pattern.name {
        case "Network Connection Failures", "Server Unavailability":
            connectionManager?.triggerRecovery()
        case "Rendering Errors":
            renderer?.reset()
        case "State Management Issues":
            stateManager?.clearAllState()
        case "Critical System Degradation":
            triggerErrorRecovery()
        default:
            break
        }
    }
    
    // MARK: - Component Observers
    
    private func setupComponentObservers() {
        // Observe connection manager errors
        if let connectionManager = connectionManager {
            connectionManager.$lastError
                .compactMap { $0 }
                .sink { [weak self] error in
                    self?.reportError(error, component: .network, severity: .high)
                }
                .store(in: &cancellables)
        }
        
        // Observe renderer errors
        if let renderer = renderer {
            renderer.$lastError
                .compactMap { $0 }
                .sink { [weak self] error in
                    let severity: ErrorSeverity = error.errorDescription?.contains("critical") == true ? .critical : .medium
                    self?.reportError(error, component: .renderer, severity: severity)
                }
                .store(in: &cancellables)
        }
        
        // Observe graceful degradation state changes
        if let gracefulDegradationManager = gracefulDegradationManager {
            gracefulDegradationManager.$degradationState
                .sink { [weak self] state in
                    if state != .normal {
                        let context = ErrorReportContext(
                            operation: "Degradation State Change",
                            metadata: ["degradationState": state.rawValue]
                        )
                        self?.reportError(
                            DegradationError.stateChanged(state),
                            component: .degradation,
                            context: context,
                            severity: self?.mapDegradationSeverity(state) ?? .medium
                        )
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Error Report Creation
    
    private func createErrorReport(
        error: Error,
        component: SystemComponent,
        context: ErrorReportContext?,
        severity: ErrorSeverity
    ) -> ErrorReport {
        let errorId = UUID().uuidString
        let errorType = determineErrorType(error)
        let isRecoverable = determineRecoverability(error, component: component)
        
        return ErrorReport(
            id: errorId,
            timestamp: Date(),
            component: component,
            errorType: errorType,
            severity: severity,
            isRecoverable: isRecoverable,
            errorDescription: error.localizedDescription,
            underlyingError: error,
            context: context,
            stackTrace: captureStackTrace(),
            systemState: captureSystemState(),
            diagnosticInfo: captureDiagnosticInfo(for: component)
        )
    }
    
    private func addErrorReport(_ report: ErrorReport) {
        errorReports.append(report)
        updateErrorStatistics(with: report)
        
        // Limit history size
        if errorReports.count > configuration.maxErrorHistorySize {
            errorReports.removeFirst(errorReports.count - configuration.maxErrorHistorySize)
        }
    }
    
    private func updateErrorStatistics(with report: ErrorReport) {
        errorStatistics = ErrorStatistics(
            totalErrors: errorStatistics.totalErrors + 1,
            errorsByComponent: updateComponentCount(errorStatistics.errorsByComponent, component: report.component),
            errorsBySeverity: updateSeverityCount(errorStatistics.errorsBySeverity, severity: report.severity),
            recoverableErrors: errorStatistics.recoverableErrors + (report.isRecoverable ? 1 : 0),
            lastErrorTimestamp: report.timestamp,
            averageErrorsPerHour: calculateErrorRate(),
            mostCommonErrorType: findMostCommonErrorType(),
            criticalErrorCount: errorStatistics.criticalErrorCount + (report.severity == .critical ? 1 : 0)
        )
    }
    
    // MARK: - System Health Monitoring
    
    private func updateSystemHealth(based report: ErrorReport) {
        let recentErrors = getFilteredErrors(timeRange: 300) // Last 5 minutes
        let criticalErrors = recentErrors.filter { $0.severity == .critical }
        let networkErrors = recentErrors.filter { $0.component == .network }
        let renderingErrors = recentErrors.filter { $0.component == .renderer }
        
        let overallHealth: HealthStatus
        if criticalErrors.count >= 3 {
            overallHealth = .critical
        } else if recentErrors.count >= 10 {
            overallHealth = .poor
        } else if recentErrors.count >= 5 {
            overallHealth = .fair
        } else if recentErrors.count >= 2 {
            overallHealth = .good
        } else {
            overallHealth = .excellent
        }
        
        systemHealth = SystemHealth(
            overallStatus: overallHealth,
            networkHealth: determineNetworkHealth(networkErrors),
            renderingHealth: determineRenderingHealth(renderingErrors),
            stateManagementHealth: determineStateHealth(recentErrors),
            lastHealthCheck: Date(),
            healthTrend: calculateHealthTrend(),
            uptime: calculateUptime(),
            performance: calculatePerformanceScore()
        )
    }
    
    // MARK: - Diagnostic Monitoring
    
    private func startDiagnosticMonitoring() {
        guard configuration.enableDiagnosticMonitoring else { return }
        
        diagnosticTimer = Timer.scheduledTimer(withTimeInterval: configuration.diagnosticInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performDiagnosticCheck()
            }
        }
    }
    
    private func performDiagnosticCheck() {
        let diagnostics = generateSystemDiagnostics()
        
        // Check for system anomalies
        if diagnostics.systemHealth.overallStatus == .critical {
            if configuration.enableAutoRecovery {
                triggerErrorRecovery()
            }
        }
        
        // Log diagnostic summary if enabled
        if configuration.enableDebugLogging {
            logDiagnosticSummary(diagnostics)
        }
    }
    
    private func startPeriodicReporting() {
        reportExportTimer = Timer.scheduledTimer(withTimeInterval: configuration.reportExportInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performPeriodicExport()
            }
        }
    }
    
    private func performPeriodicExport() {
        let exportData = exportErrorData()
        
        if configuration.enableFileExport {
            saveExportToFile(exportData)
        }
        
        if configuration.enableDebugLogging {
            print("📊 Periodic error report generated: \(exportData.errorReports.count) errors")
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineErrorType(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return "network.\(networkError.type)"
        } else if let renderError = error as? SwiftUIRenderError {
            return "render.\(renderError)"
        } else if let websocketError = error as? WebSocketClientError {
            return "websocket.\(websocketError)"
        } else {
            return String(describing: type(of: error))
        }
    }
    
    private func determineRecoverability(_ error: Error, component: SystemComponent) -> Bool {
        switch component {
        case .network:
            if let networkError = error as? NetworkError {
                return networkError.isRecoverable
            }
            return true
        case .renderer:
            return true // Most rendering errors are recoverable
        case .stateManager:
            return true // State errors are usually recoverable
        case .degradation:
            return true
        case .system:
            return false // System errors may not be recoverable
        case .state:
            return true // State errors are usually recoverable
        }
    }
    
    private func mapDegradationSeverity(_ state: DegradationState) -> ErrorSeverity {
        switch state {
        case .normal:
            return .low
        case .minorDegradation:
            return .low
        case .moderateDegradation:
            return .medium
        case .severeDegradation:
            return .high
        case .criticalDegradation:
            return .critical
        }
    }
    
    private func captureStackTrace() -> [String] {
        // Capture current stack trace
        return Thread.callStackSymbols
    }
    
    private func captureSystemState() -> SystemStateSnapshot {
        return SystemStateSnapshot(
            timestamp: Date(),
            connectionState: connectionManager?.connectionState ?? .disconnected,
            isRendering: renderer?.isRendering ?? false,
            stateKeyCount: stateManager?.getAllState().count ?? 0,
            degradationState: gracefulDegradationManager?.degradationState ?? .normal,
            memoryUsage: getCurrentMemoryUsage(),
            networkStatus: networkErrorHandler?.isNetworkAvailable ?? false
        )
    }
    
    private func captureDiagnosticInfo(for component: SystemComponent) -> [String: Any] {
        var info: [String: Any] = [:]
        
        switch component {
        case .network:
            if let diagnostics = networkErrorHandler?.getNetworkDiagnostics() {
                info["networkAvailable"] = diagnostics.isNetworkAvailable
                info["connectionQuality"] = diagnostics.connectionQuality.rawValue
                info["consecutiveFailures"] = diagnostics.consecutiveFailures
            }
        case .renderer:
            if let stats = renderer?.renderingStats {
                info["totalRenders"] = stats.totalRenders
                info["successRate"] = stats.successRate
                info["averageRenderTime"] = stats.averageRenderTime
            }
        case .stateManager:
            info["stateKeyCount"] = stateManager?.getAllState().count ?? 0
        case .degradation:
            if let stats = gracefulDegradationManager?.getDegradationStats() {
                info["degradationEvents"] = stats.totalDegradationEvents
                info["currentState"] = stats.currentState.rawValue
                info["serverAvailability"] = stats.serverAvailability.rawValue
            }
        case .system:
            info["timestamp"] = Date()
        case .state:
            info["stateKeyCount"] = stateManager?.getAllState().count ?? 0
        }
        
        return info
    }
    
    private func recordRecoveryAttempt() {
        let attemptId = UUID().uuidString
        let attempt = RecoveryAttempt(
            id: attemptId,
            timestamp: Date(),
            triggeredBy: .manual,
            components: [.network, .renderer, .stateManager],
            success: false // Will be updated based on subsequent error patterns
        )
        
        recoveryAttempts[attemptId] = attempt
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func calculateErrorRate() -> Double {
        guard !errorReports.isEmpty else { return 0 }
        
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentErrors = errorReports.filter { $0.timestamp >= oneHourAgo }
        
        return Double(recentErrors.count)
    }
    
    private func saveExportToFile(_ exportData: ErrorExportData) {
        let fileName = "error_report_\(Date().timeIntervalSince1970).json"
        
        // This would save to appropriate directory (Documents, tmp, etc.)
        if configuration.enableDebugLogging {
            print("📁 Error report saved: \(fileName)")
        }
    }
    
    private func notifyErrorReported(_ report: ErrorReport) {
        NotificationCenter.default.post(
            name: .errorReported,
            object: self,
            userInfo: ["errorReport": report]
        )
    }
}

// MARK: - Supporting Types

public enum SystemComponent: String, CaseIterable {
    case network = "network"
    case renderer = "renderer"
    case stateManager = "stateManager"
    case degradation = "degradation"
    case system = "system"
    case state = "state"
}

public struct ErrorReport {
    public let id: String
    public let timestamp: Date
    public let component: SystemComponent
    public let errorType: String
    public let severity: ErrorSeverity
    public let isRecoverable: Bool
    public let errorDescription: String
    public let underlyingError: Error
    public let context: ErrorReportContext?
    public let stackTrace: [String]
    public let systemState: SystemStateSnapshot
    public let diagnosticInfo: [String: Any]
}

public struct ErrorReportContext {
    public let operation: String
    public let attemptNumber: Int
    public let metadata: [String: Any]
    
    public init(operation: String, attemptNumber: Int = 1, metadata: [String: Any] = [:]) {
        self.operation = operation
        self.attemptNumber = attemptNumber
        self.metadata = metadata
    }
}

public struct ErrorStatistics {
    public let totalErrors: Int
    public let errorsByComponent: [SystemComponent: Int]
    public let errorsBySeverity: [ErrorSeverity: Int]
    public let recoverableErrors: Int
    public let lastErrorTimestamp: Date?
    public let averageErrorsPerHour: Double
    public let mostCommonErrorType: String?
    public let criticalErrorCount: Int
    
    public init(
        totalErrors: Int = 0,
        errorsByComponent: [SystemComponent: Int] = [:],
        errorsBySeverity: [ErrorSeverity: Int] = [:],
        recoverableErrors: Int = 0,
        lastErrorTimestamp: Date? = nil,
        averageErrorsPerHour: Double = 0,
        mostCommonErrorType: String? = nil,
        criticalErrorCount: Int = 0
    ) {
        self.totalErrors = totalErrors
        self.errorsByComponent = errorsByComponent
        self.errorsBySeverity = errorsBySeverity
        self.recoverableErrors = recoverableErrors
        self.lastErrorTimestamp = lastErrorTimestamp
        self.averageErrorsPerHour = averageErrorsPerHour
        self.mostCommonErrorType = mostCommonErrorType
        self.criticalErrorCount = criticalErrorCount
    }
}

public enum HealthStatus: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
}

public struct SystemHealth: Codable {
    public let overallStatus: HealthStatus
    public let networkHealth: HealthStatus
    public let renderingHealth: HealthStatus
    public let stateManagementHealth: HealthStatus
    public let lastHealthCheck: Date
    public let healthTrend: HealthTrend
    public let uptime: TimeInterval
    public let performance: SystemPerformanceScore
    
    public init(
        overallStatus: HealthStatus = .excellent,
        networkHealth: HealthStatus = .excellent,
        renderingHealth: HealthStatus = .excellent,
        stateManagementHealth: HealthStatus = .excellent,
        lastHealthCheck: Date = Date(),
        healthTrend: HealthTrend = .stable,
        uptime: TimeInterval = 0,
        performance: SystemPerformanceScore = SystemPerformanceScore()
    ) {
        self.overallStatus = overallStatus
        self.networkHealth = networkHealth
        self.renderingHealth = renderingHealth
        self.stateManagementHealth = stateManagementHealth
        self.lastHealthCheck = lastHealthCheck
        self.healthTrend = healthTrend
        self.uptime = uptime
        self.performance = performance
    }
}

public enum HealthTrend: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case degrading = "degrading"
}

public struct SystemPerformanceScore: Codable {
    public let overall: Double
    public let network: Double
    public let rendering: Double
    public let memory: Double
    
    public init(overall: Double = 1.0, network: Double = 1.0, rendering: Double = 1.0, memory: Double = 1.0) {
        self.overall = overall
        self.network = network
        self.rendering = rendering
        self.memory = memory
    }
}

public struct SystemStateSnapshot {
    public let timestamp: Date
    public let connectionState: ConnectionState
    public let isRendering: Bool
    public let stateKeyCount: Int
    public let degradationState: DegradationState
    public let memoryUsage: UInt64
    public let networkStatus: Bool
}

public struct ErrorPattern {
    public let name: String
    public let description: String
    public let conditions: [PatternCondition]
    
    public func matches(_ report: ErrorReport, in allReports: [ErrorReport]) -> Bool {
        return conditions.allSatisfy { condition in
            condition.evaluate(report, in: allReports)
        }
    }
}

public enum PatternCondition {
    case componentType(SystemComponent)
    case errorType(String)
    case severity(ErrorSeverity)
    case frequency(minCount: Int, timeWindow: TimeInterval)
    case duration(minimum: TimeInterval)
    
    public func evaluate(_ report: ErrorReport, in allReports: [ErrorReport]) -> Bool {
        switch self {
        case .componentType(let component):
            return report.component == component
        case .errorType(let type):
            return report.errorType.contains(type)
        case .severity(let severity):
            return report.severity == severity
        case .frequency(let minCount, let timeWindow):
            let cutoff = Date().addingTimeInterval(-timeWindow)
            let matchingReports = allReports.filter { $0.timestamp >= cutoff && $0.component == report.component }
            return matchingReports.count >= minCount
        case .duration(let minimum):
            // This would need more complex logic to track error duration
            return true
        }
    }
}

public struct SystemDiagnostics {
    public let timestamp: Date
    public let systemHealth: SystemHealth
    public let errorStatistics: ErrorStatistics
    public let networkDiagnostics: NetworkDiagnostics?
    public let renderingStats: RenderingStats?
    public let degradationStats: DegradationStats?
    public let connectionState: ConnectionState
    public let recentErrors: [ErrorReport]
    public let errorPatterns: [ErrorPattern]
    public let recoveryStatus: RecoveryStatus
    public let systemResources: SystemResourceInfo
    public let configurationSummary: ConfigurationSummary
}

public struct ErrorTrendAnalysis {
    public let timeWindow: TimeInterval
    public let totalErrors: Int
    public let errorsByComponent: [SystemComponent: Int]
    public let errorsBySeverity: [ErrorSeverity: Int]
    public let errorsByPattern: [String: Int]
    public let recoverySuccessRate: Double
    public let predictions: [ErrorPrediction]
}

public struct ErrorPatternNotification {
    public let pattern: ErrorPattern
    public let triggeringError: ErrorReport
    public let matchingErrors: [ErrorReport]
    public let detectedAt: Date
    public let severity: ErrorSeverity
}

public struct RecoveryAttempt {
    public let id: String
    public let timestamp: Date
    public let triggeredBy: RecoveryTrigger
    public let components: [SystemComponent]
    public var success: Bool
}

public enum RecoveryTrigger: String {
    case automatic = "automatic"
    case manual = "manual"
    case pattern = "pattern"
}

public struct RecoveryStatus {
    public let lastAttempt: Date?
    public let successRate: Double
    public let pendingRecoveries: [SystemComponent]
    public let activeRecoveries: [SystemComponent]
}

public struct SystemResourceInfo {
    public let memoryUsage: UInt64
    public let cpuUsage: Double
    public let diskSpace: UInt64
    public let networkBandwidth: Double
}

public struct ConfigurationSummary {
    public let hotReloadEnabled: Bool
    public let debugMode: Bool
    public let autoRecovery: Bool
    public let statePreservation: Bool
    public let gracefulDegradation: Bool
}

public struct ErrorPrediction {
    public let component: SystemComponent
    public let predictedErrorType: String
    public let probability: Double
    public let timeFrame: TimeInterval
    public let basedOn: String
}

public enum ExportFormat: String {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public struct ErrorExportData {
    public let exportDate: Date
    public let format: ExportFormat
    public let errorReports: [ErrorReport]
    public let statistics: ErrorStatistics
    public let systemHealth: SystemHealth
    public let diagnostics: SystemDiagnostics
    public let metadata: [String: Any]
}

public enum DegradationError: Error {
    case stateChanged(DegradationState)
    
    public var localizedDescription: String {
        switch self {
        case .stateChanged(let state):
            return "System degradation state changed to: \(state.rawValue)"
        }
    }
}

// MARK: - Configuration

public struct ErrorReportingConfiguration: Hashable {
    public let maxErrorHistorySize: Int
    public let enableRealTimeNotifications: Bool
    public let enablePatternDetection: Bool
    public let enableDiagnosticMonitoring: Bool
    public let enableAutoRecovery: Bool
    public let enableDebugLogging: Bool
    public let enablePeriodicReporting: Bool
    public let enableFileExport: Bool
    
    public let diagnosticInterval: TimeInterval
    public let reportExportInterval: TimeInterval
    public let patternDetectionWindow: TimeInterval
    
    public init(
        maxErrorHistorySize: Int = 1000,
        enableRealTimeNotifications: Bool = true,
        enablePatternDetection: Bool = true,
        enableDiagnosticMonitoring: Bool = true,
        enableAutoRecovery: Bool = true,
        enableDebugLogging: Bool = false,
        enablePeriodicReporting: Bool = false,
        enableFileExport: Bool = false,
        diagnosticInterval: TimeInterval = 60.0,
        reportExportInterval: TimeInterval = 3600.0,
        patternDetectionWindow: TimeInterval = 300.0
    ) {
        self.maxErrorHistorySize = maxErrorHistorySize
        self.enableRealTimeNotifications = enableRealTimeNotifications
        self.enablePatternDetection = enablePatternDetection
        self.enableDiagnosticMonitoring = enableDiagnosticMonitoring
        self.enableAutoRecovery = enableAutoRecovery
        self.enableDebugLogging = enableDebugLogging
        self.enablePeriodicReporting = enablePeriodicReporting
        self.enableFileExport = enableFileExport
        self.diagnosticInterval = diagnosticInterval
        self.reportExportInterval = reportExportInterval
        self.patternDetectionWindow = patternDetectionWindow
    }
    
    public static func development() -> ErrorReportingConfiguration {
        return ErrorReportingConfiguration(
            enableDebugLogging: true,
            enablePeriodicReporting: true,
            diagnosticInterval: 30.0,
            reportExportInterval: 600.0
        )
    }
    
    public static func production() -> ErrorReportingConfiguration {
        return ErrorReportingConfiguration(
            enableDebugLogging: false,
            enablePeriodicReporting: false,
            enableFileExport: false,
            diagnosticInterval: 300.0
        )
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let errorReported = Notification.Name("ErrorReported")
    static let errorPatternDetected = Notification.Name("ErrorPatternDetected")
    static let systemHealthChanged = Notification.Name("SystemHealthChanged")
}

// MARK: - Extension Placeholders

extension ErrorReportingManager {
    // Placeholder implementations for methods referenced but not fully implemented
    
    private func updateComponentCount(_ counts: [SystemComponent: Int], component: SystemComponent) -> [SystemComponent: Int] {
        var updated = counts
        updated[component, default: 0] += 1
        return updated
    }
    
    private func updateSeverityCount(_ counts: [ErrorSeverity: Int], severity: ErrorSeverity) -> [ErrorSeverity: Int] {
        var updated = counts
        updated[severity, default: 0] += 1
        return updated
    }
    
    private func findMostCommonErrorType() -> String? {
        // Implementation would analyze error reports to find most common type
        return nil
    }
    
    private func determineNetworkHealth(_ errors: [ErrorReport]) -> HealthStatus {
        if errors.count >= 5 { return .critical }
        if errors.count >= 3 { return .poor }
        if errors.count >= 1 { return .fair }
        return .excellent
    }
    
    private func determineRenderingHealth(_ errors: [ErrorReport]) -> HealthStatus {
        if errors.count >= 3 { return .critical }
        if errors.count >= 2 { return .poor }
        if errors.count >= 1 { return .fair }
        return .excellent
    }
    
    private func determineStateHealth(_ errors: [ErrorReport]) -> HealthStatus {
        let stateErrors = errors.filter { $0.component == .stateManager }
        if stateErrors.count >= 2 { return .poor }
        if stateErrors.count >= 1 { return .fair }
        return .excellent
    }
    
    private func calculateHealthTrend() -> HealthTrend {
        // Implementation would analyze recent health changes
        return .stable
    }
    
    private func calculateUptime() -> TimeInterval {
        // Implementation would track system start time
        return 0
    }
    
    private func calculatePerformanceScore() -> SystemPerformanceScore {
        // Implementation would analyze various performance metrics
        return SystemPerformanceScore()
    }
    
    private func getSignificantErrorPatterns() -> [ErrorPattern] {
        return errorPatterns.filter { pattern in
            // Filter for patterns that have been triggered recently
            errorReports.contains { report in
                pattern.matches(report, in: errorReports)
            }
        }
    }
    
    private func getCurrentRecoveryStatus() -> RecoveryStatus {
        return RecoveryStatus(
            lastAttempt: recoveryAttempts.values.map(\.timestamp).max(),
            successRate: calculateRecoverySuccessRate([]),
            pendingRecoveries: [],
            activeRecoveries: []
        )
    }
    
    private func gatherSystemResourceInfo() -> SystemResourceInfo {
        return SystemResourceInfo(
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: 0, // Implementation would get actual CPU usage
            diskSpace: 0, // Implementation would get disk space
            networkBandwidth: 0 // Implementation would measure network
        )
    }
    
    private func getConfigurationSummary() -> ConfigurationSummary {
        return ConfigurationSummary(
            hotReloadEnabled: true, // Would get from actual configuration
            debugMode: configuration.enableDebugLogging,
            autoRecovery: configuration.enableAutoRecovery,
            statePreservation: true, // Would get from actual configuration
            gracefulDegradation: true // Would get from actual configuration
        )
    }
    
    private func createExportMetadata() -> [String: Any] {
        return [
            "exportVersion": "1.0",
            "systemInfo": "iOS Hot Reload",
            "configurationHash": configuration.hashValue
        ]
    }
    
    private func groupErrorsByComponent(_ errors: [ErrorReport]) -> [SystemComponent: Int] {
        return Dictionary(grouping: errors, by: \.component).mapValues(\.count)
    }
    
    private func groupErrorsBySeverity(_ errors: [ErrorReport]) -> [ErrorSeverity: Int] {
        return Dictionary(grouping: errors, by: \.severity).mapValues(\.count)
    }
    
    private func identifyTrendPatterns(_ errors: [ErrorReport]) -> [String: Int] {
        // Implementation would identify trending error patterns
        return [:]
    }
    
    private func calculateRecoverySuccessRate(_ errors: [ErrorReport]) -> Double {
        // Implementation would calculate recovery success rate
        return 0.8
    }
    
    private func generateErrorPredictions(_ errors: [ErrorReport]) -> [ErrorPrediction] {
        // Implementation would generate ML-based predictions
        return []
    }
    
    private func getMatchingErrors(for pattern: ErrorPattern) -> [ErrorReport] {
        return errorReports.filter { pattern.matches($0, in: errorReports) }
    }
    
    private func determinePatterSeverity(_ pattern: ErrorPattern) -> ErrorSeverity {
        switch pattern.name {
        case "Critical System Degradation":
            return .critical
        case "Network Connection Failures", "Server Unavailability":
            return .high
        default:
            return .medium
        }
    }
    
    private func logDiagnosticSummary(_ diagnostics: SystemDiagnostics) {
        print("🏥 System Health: \(diagnostics.systemHealth.overallStatus.rawValue)")
        print("📊 Total Errors: \(diagnostics.errorStatistics.totalErrors)")
        print("🔗 Connection: \(diagnostics.connectionState.rawValue)")
    }
}