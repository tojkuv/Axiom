import Foundation
import SwiftUI
import Combine

// MARK: - Comprehensive State Debugging and Inspection System

/// Advanced state debugger that provides inspection, tracking, and analysis of application state
@MainActor
public final class StateDebugger: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentStateSnapshot: StateSnapshot?
    @Published public private(set) var stateHistory: [StateSnapshot] = []
    @Published public private(set) var detectedStateIssues: [StateIssue] = []
    @Published public private(set) var stateChangeEvents: [StateChangeEvent] = []
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var monitoringStatistics: MonitoringStatistics = MonitoringStatistics()
    
    // MARK: - Properties
    
    private let configuration: StateDebuggerConfiguration
    private var monitoringTimer: Timer?
    private var analysisTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // State tracking
    private var stateTracking: [String: StateValueTracking] = [:]
    private var stateBaseline: [String: Any] = [:]
    private var changeDetectionThresholds: [String: StateChangeThreshold] = [:]
    
    // Inspection tools
    private var stateInspector: StateInspector
    private var stateComparator: StateComparator
    private var stateValidator: StateValidator
    private var stateExporter: StateExporter
    
    // Performance tracking
    private var statePerformanceMetrics: [String: StatePerformanceMetrics] = [:]
    private var stateAccessPatterns: [String: StateAccessPattern] = [:]
    
    // System integration
    private weak var stateManager: SwiftUIStateManager?
    private weak var errorReportingManager: ErrorReportingManager?
    private weak var memoryProfiler: MemoryProfiler?
    
    public init(configuration: StateDebuggerConfiguration = StateDebuggerConfiguration()) {
        self.configuration = configuration
        self.stateInspector = StateInspector(configuration: configuration.inspectorConfig)
        self.stateComparator = StateComparator(configuration: configuration.comparatorConfig)
        self.stateValidator = StateValidator(configuration: configuration.validatorConfig)
        self.stateExporter = StateExporter(configuration: configuration.exporterConfig)
        
        if configuration.enableAutoMonitoring {
            startMonitoring()
        }
    }
    
    deinit {
        // Clean up timers directly since we can't call MainActor methods from deinit
        monitoringTimer?.invalidate()
        analysisTimer?.invalidate()
    }
    
    // MARK: - Public API
    
    /// Start state monitoring and analysis
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startStateMonitoring()
        startStateAnalysis()
        
        if configuration.enableDebugLogging {
            print("🔍 State debugger started monitoring")
        }
    }
    
    /// Stop state monitoring
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        analysisTimer?.invalidate()
        
        if configuration.enableDebugLogging {
            print("🔍 State debugger stopped monitoring")
        }
    }
    
    /// Set the state manager to monitor
    public func setStateManager(_ manager: SwiftUIStateManager) {
        self.stateManager = manager
        
        // Capture initial state as baseline
        captureStateBaseline()
        
        if configuration.enableDebugLogging {
            print("🔗 State debugger connected to state manager")
        }
    }
    
    /// Register a state key for detailed tracking
    public func registerStateKey(_ key: String, threshold: StateChangeThreshold? = nil) {
        let tracking = StateValueTracking(
            key: key,
            registeredAt: Date(),
            changeHistory: [],
            accessCount: 0,
            lastAccessed: Date(),
            performanceMetrics: StatePerformanceMetrics()
        )
        
        stateTracking[key] = tracking
        
        if let threshold = threshold {
            changeDetectionThresholds[key] = threshold
        }
        
        if configuration.enableDebugLogging {
            print("📝 Registered state key for tracking: \(key)")
        }
    }
    
    /// Manually capture current state snapshot
    public func captureStateSnapshot(reason: String = "Manual capture") -> StateSnapshot {
        let snapshot = createStateSnapshot(reason: reason)
        stateHistory.append(snapshot)
        currentStateSnapshot = snapshot
        
        // Limit history size
        if stateHistory.count > configuration.maxHistorySize {
            stateHistory.removeFirst(stateHistory.count - configuration.maxHistorySize)
        }
        
        analyzeStateSnapshot(snapshot)
        
        if configuration.enableDebugLogging {
            print("📸 Captured state snapshot: \(snapshot.reason)")
        }
        
        return snapshot
    }
    
    /// Track a state change event
    public func trackStateChange(_ key: String, oldValue: Any?, newValue: Any?, context: StateChangeContext? = nil) {
        let changeEvent = StateChangeEvent(
            key: key,
            oldValue: oldValue,
            newValue: newValue,
            timestamp: Date(),
            context: context
        )
        
        stateChangeEvents.append(changeEvent)
        
        // Limit change events
        if stateChangeEvents.count > configuration.maxChangeEvents {
            stateChangeEvents.removeFirst(stateChangeEvents.count - configuration.maxChangeEvents)
        }
        
        // Update tracking
        updateStateTracking(key, changeEvent: changeEvent)
        
        // Check for issues
        checkForStateIssues(changeEvent)
        
        if configuration.enableDebugLogging {
            print("🔄 State change tracked: \(key)")
        }
    }
    
    /// Inspect current state structure
    public func inspectState() -> StateInspectionResult {
        guard let stateManager = stateManager else {
            return StateInspectionResult(
                timestamp: Date(),
                stateKeys: [],
                stateStructure: [:],
                issues: [StateIssue(
                    id: "no_state_manager",
                    type: .corruption,
                    severity: .warning,
                    key: "system",
                    description: "No state manager connected",
                    detectedAt: Date(),
                    context: nil
                )],
                recommendations: ["Connect state manager to enable inspection"]
            )
        }
        
        let allStateRaw = stateManager.getAllState()
        let allState = allStateRaw.mapValues { SwiftUIStateValue(value: $0.value) }
        return stateInspector.inspect(state: allState, tracking: stateTracking)
    }
    
    /// Compare two state snapshots
    public func compareStates(_ snapshot1: StateSnapshot, _ snapshot2: StateSnapshot) -> StateComparisonResult {
        return stateComparator.compare(snapshot1: snapshot1, snapshot2: snapshot2)
    }
    
    /// Validate current state integrity
    public func validateState() -> StateValidationResult {
        guard let stateManager = stateManager else {
            return StateValidationResult(
                timestamp: Date(),
                isValid: false,
                validationErrors: [StateValidationError(
                    key: "system",
                    errorType: .missing,
                    description: "No state manager connected",
                    severity: .warning
                )],
                warnings: [],
                recommendations: ["Connect state manager to enable validation"]
            )
        }
        
        let allStateRaw = stateManager.getAllState()
        let allState = allStateRaw.mapValues { SwiftUIStateValue(value: $0.value) }
        return stateValidator.validate(state: allState, baseline: stateBaseline)
    }
    
    /// Export state data for external analysis
    public func exportStateData(format: StateExportFormat = .json, includeHistory: Bool = true) -> StateExportData {
        return stateExporter.export(
            currentState: currentStateSnapshot,
            history: includeHistory ? stateHistory : [],
            changeEvents: stateChangeEvents,
            issues: detectedStateIssues,
            tracking: stateTracking,
            format: format
        )
    }
    
    /// Search for state values matching criteria
    public func searchState(_ criteria: StateSearchCriteria) -> StateSearchResult {
        guard let stateManager = stateManager else {
            return StateSearchResult(criteria: criteria, matches: [], totalChecked: 0)
        }
        
        let allState = stateManager.getAllState()
        var matches: [StateSearchMatch] = []
        var totalChecked = 0
        
        for (key, stateValue) in allState {
            totalChecked += 1
            
            if matchesSearchCriteria(key: key, value: stateValue.value, criteria: criteria) {
                matches.append(StateSearchMatch(
                    key: key,
                    value: stateValue.value,
                    matchType: determineMatchType(criteria),
                    path: [key]
                ))
            }
        }
        
        return StateSearchResult(criteria: criteria, matches: matches, totalChecked: totalChecked)
    }
    
    /// Get comprehensive state analysis
    public func generateStateAnalysis() -> StateAnalysis {
        let currentInspection = inspectState()
        let validation = validateState()
        let issuesSummary = summarizeStateIssues()
        let performanceAnalysis = analyzeStatePerformance()
        let accessPatterns = analyzeAccessPatterns()
        
        return StateAnalysis(
            timestamp: Date(),
            inspection: currentInspection,
            validation: validation,
            issuesSummary: issuesSummary,
            performanceAnalysis: performanceAnalysis,
            accessPatterns: accessPatterns,
            monitoringStatistics: monitoringStatistics,
            recommendations: generateRecommendations()
        )
    }
    
    /// Get state change trends
    public func getStateChangeTrends(timeWindow: TimeInterval = 3600) -> StateChangeTrends {
        let cutoffDate = Date().addingTimeInterval(-timeWindow)
        let recentChanges = stateChangeEvents.filter { $0.timestamp >= cutoffDate }
        
        let changesByKey = Dictionary(grouping: recentChanges, by: \.key)
        let changeFrequencies = changesByKey.mapValues { $0.count }
        let mostActiveKeys = changeFrequencies.sorted { $0.value > $1.value }.prefix(10)
        
        return StateChangeTrends(
            timeWindow: timeWindow,
            totalChanges: recentChanges.count,
            changesByKey: changeFrequencies,
            mostActiveKeys: Array(mostActiveKeys.map { $0.key }),
            averageChangesPerMinute: Double(recentChanges.count) / (timeWindow / 60),
            patterns: identifyChangePatterns(recentChanges)
        )
    }
    
    // MARK: - State Monitoring
    
    private func startStateMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performStateMonitoring()
            }
        }
    }
    
    private func performStateMonitoring() {
        // Capture periodic state snapshot
        if configuration.enablePeriodicSnapshots {
            let _ = captureStateSnapshot(reason: "Periodic monitoring")
        }
        
        // Update monitoring statistics
        updateMonitoringStatistics()
        
        // Check for state corruption
        if configuration.enableCorruptionDetection {
            detectStateCorruption()
        }
        
        // Update access patterns
        updateStateAccessPatterns()
    }
    
    private func startStateAnalysis() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: configuration.analysisInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performStateAnalysis()
            }
        }
    }
    
    private func performStateAnalysis() {
        // Analyze state change patterns
        analyzeStateChangePatterns()
        
        // Detect anomalies
        detectStateAnomalies()
        
        // Update performance metrics
        updateStatePerformanceMetrics()
        
        // Clean up old data
        if configuration.enableDataCleanup {
            cleanupOldStateData()
        }
    }
    
    // MARK: - State Analysis
    
    private func createStateSnapshot(reason: String) -> StateSnapshot {
        guard let stateManager = stateManager else {
            return StateSnapshot(
                id: UUID().uuidString,
                timestamp: Date(),
                reason: reason,
                stateData: [:],
                metadata: StateSnapshotMetadata(
                    stateCount: 0,
                    memoryUsage: 0,
                    captureTime: 0
                )
            )
        }
        
        let startTime = Date()
        let allState = stateManager.getAllState()
        let captureTime = Date().timeIntervalSince(startTime)
        
        let stateData = allState.mapValues { $0.value }
        let memoryUsage = estimateStateMemoryUsage(stateData)
        
        return StateSnapshot(
            id: UUID().uuidString,
            timestamp: Date(),
            reason: reason,
            stateData: stateData,
            metadata: StateSnapshotMetadata(
                stateCount: stateData.count,
                memoryUsage: memoryUsage,
                captureTime: captureTime
            )
        )
    }
    
    private func analyzeStateSnapshot(_ snapshot: StateSnapshot) {
        // Check for state size growth
        if let previousSnapshot = stateHistory.last {
            let growthRatio = Double(snapshot.stateData.count) / Double(previousSnapshot.stateData.count)
            
            if growthRatio > configuration.stateGrowthThreshold {
                reportStateIssue(StateIssue(
                    id: "state_growth_\(snapshot.id)",
                    type: .performance,
                    severity: .warning,
                    key: "system",
                    description: "State size grew by \(String(format: "%.1f", (growthRatio - 1) * 100))%",
                    detectedAt: Date(),
                    context: StateIssueContext(
                        snapshot: snapshot,
                        previousSnapshot: previousSnapshot
                    )
                ))
            }
        }
        
        // Check for memory usage
        if snapshot.metadata.memoryUsage > configuration.memoryUsageThreshold {
            reportStateIssue(StateIssue(
                id: "memory_usage_\(snapshot.id)",
                type: .performance,
                severity: .warning,
                key: "system",
                description: "High state memory usage: \(formatBytes(snapshot.metadata.memoryUsage))",
                detectedAt: Date(),
                context: StateIssueContext(snapshot: snapshot)
            ))
        }
    }
    
    private func updateStateTracking(_ key: String, changeEvent: StateChangeEvent) {
        guard var tracking = stateTracking[key] else { return }
        
        tracking.changeHistory.append(changeEvent)
        tracking.accessCount += 1
        tracking.lastAccessed = Date()
        
        // Limit change history
        if tracking.changeHistory.count > configuration.maxChangeHistoryPerKey {
            tracking.changeHistory.removeFirst(tracking.changeHistory.count - configuration.maxChangeHistoryPerKey)
        }
        
        // Update performance metrics
        tracking.performanceMetrics.updateFrequency = calculateUpdateFrequency(tracking.changeHistory)
        tracking.performanceMetrics.lastUpdateTime = Date().timeIntervalSince(tracking.lastAccessed)
        
        stateTracking[key] = tracking
    }
    
    private func checkForStateIssues(_ changeEvent: StateChangeEvent) {
        // Check for excessive change frequency
        if let tracking = stateTracking[changeEvent.key] {
            let recentChanges = tracking.changeHistory.filter { 
                Date().timeIntervalSince($0.timestamp) < 60 // Last minute
            }
            
            if Double(recentChanges.count) > configuration.excessiveChangeThreshold {
                reportStateIssue(StateIssue(
                    id: "excessive_changes_\(changeEvent.key)_\(Date().timeIntervalSince1970)",
                    type: .performance,
                    severity: .warning,
                    key: changeEvent.key,
                    description: "Excessive state changes: \(recentChanges.count) in the last minute",
                    detectedAt: Date(),
                    context: StateIssueContext(changeEvent: changeEvent)
                ))
            }
        }
        
        // Check for suspicious value changes
        if let threshold = changeDetectionThresholds[changeEvent.key] {
            if violatesChangeThreshold(changeEvent, threshold: threshold) {
                reportStateIssue(StateIssue(
                    id: "threshold_violation_\(changeEvent.key)_\(Date().timeIntervalSince1970)",
                    type: .corruption,
                    severity: .warning,
                    key: changeEvent.key,
                    description: "State change violates configured threshold",
                    detectedAt: Date(),
                    context: StateIssueContext(changeEvent: changeEvent)
                ))
            }
        }
    }
    
    // MARK: - System Integration
    
    public func setErrorReportingManager(_ manager: ErrorReportingManager) {
        self.errorReportingManager = manager
    }
    
    public func setMemoryProfiler(_ profiler: MemoryProfiler) {
        self.memoryProfiler = profiler
    }
    
    private func reportStateIssue(_ issue: StateIssue) {
        detectedStateIssues.append(issue)
        
        // Limit issues list
        if detectedStateIssues.count > configuration.maxStoredIssues {
            detectedStateIssues.removeFirst(detectedStateIssues.count - configuration.maxStoredIssues)
        }
        
        // Report to error reporting manager
        if issue.severity == .critical {
            let error = StateDebugError.stateIssue(issue)
            errorReportingManager?.reportError(
                error,
                component: .state,
                context: ErrorReportContext(
                    operation: "State debugging",
                    metadata: [
                        "issueType": issue.type.rawValue,
                        "stateKey": issue.key,
                        "severity": issue.severity.rawValue
                    ]
                ),
                severity: mapIssueSeverity(issue.severity)
            )
        }
        
        if configuration.enableDebugLogging {
            print("⚠️ State issue detected: \(issue.description)")
        }
    }
    
    // MARK: - Utility Methods
    
    private func captureStateBaseline() {
        guard let stateManager = stateManager else { return }
        
        let allState = stateManager.getAllState()
        stateBaseline = allState.mapValues { $0.value }
        
        if configuration.enableDebugLogging {
            print("📏 State baseline captured: \(stateBaseline.count) keys")
        }
    }
    
    private func updateMonitoringStatistics() {
        monitoringStatistics = MonitoringStatistics(
            totalSnapshots: stateHistory.count,
            totalChangeEvents: stateChangeEvents.count,
            totalIssuesDetected: detectedStateIssues.count,
            trackedKeys: stateTracking.count,
            monitoringDuration: isMonitoring ? Date().timeIntervalSince(Date()) : 0,
            averageSnapshotSize: calculateAverageSnapshotSize(),
            memoryUsage: calculateCurrentStateMemoryUsage()
        )
    }
    
    private func estimateStateMemoryUsage(_ stateData: [String: Any]) -> UInt64 {
        // Rough estimation of memory usage
        var totalSize: UInt64 = 0
        
        for (key, value) in stateData {
            totalSize += UInt64(key.utf8.count)
            totalSize += estimateValueSize(value)
        }
        
        return totalSize
    }
    
    private func estimateValueSize(_ value: Any) -> UInt64 {
        // Rough estimation based on type
        switch value {
        case is String:
            return UInt64((value as! String).utf8.count)
        case is Int, is Double, is Float:
            return 8
        case is Bool:
            return 1
        case is Array<Any>:
            return UInt64((value as! Array<Any>).count * 8) // Rough estimate
        case is Dictionary<String, Any>:
            return UInt64((value as! Dictionary<String, Any>).count * 16) // Rough estimate
        default:
            return 64 // Default estimate for unknown types
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func mapIssueSeverity(_ severity: StateIssueSeverity) -> ErrorSeverity {
        switch severity {
        case .info:
            return .low
        case .warning:
            return .medium
        case .critical:
            return .critical
        }
    }
    
    // MARK: - Placeholder Implementation Methods
    
    private func detectStateCorruption() {
        // Placeholder for corruption detection logic
    }
    
    private func updateStateAccessPatterns() {
        // Update access patterns for tracked state keys
        for (key, tracking) in stateTracking {
            var pattern = stateAccessPatterns[key] ?? StateAccessPattern(
                key: key,
                accessCount: 0,
                lastAccessed: Date(),
                accessFrequency: 0
            )
            
            pattern.accessCount = tracking.accessCount
            pattern.lastAccessed = tracking.lastAccessed
            pattern.accessFrequency = Double(tracking.accessCount) / max(1, Date().timeIntervalSince(tracking.registeredAt) / 60)
            
            stateAccessPatterns[key] = pattern
        }
    }
    
    private func analyzeStateChangePatterns() {
        // Analyze patterns in state changes
    }
    
    private func detectStateAnomalies() {
        // Detect anomalies in state behavior
    }
    
    private func updateStatePerformanceMetrics() {
        // Update performance metrics for state operations
    }
    
    private func cleanupOldStateData() {
        let cutoffDate = Date().addingTimeInterval(-configuration.dataRetentionPeriod)
        
        stateHistory.removeAll { $0.timestamp < cutoffDate }
        stateChangeEvents.removeAll { $0.timestamp < cutoffDate }
        detectedStateIssues.removeAll { $0.detectedAt < cutoffDate }
    }
    
    private func calculateUpdateFrequency(_ changeHistory: [StateChangeEvent]) -> Double {
        guard changeHistory.count >= 2 else { return 0 }
        
        let timeSpan = changeHistory.last!.timestamp.timeIntervalSince(changeHistory.first!.timestamp)
        return timeSpan > 0 ? Double(changeHistory.count) / (timeSpan / 60) : 0 // Changes per minute
    }
    
    private func violatesChangeThreshold(_ changeEvent: StateChangeEvent, threshold: StateChangeThreshold) -> Bool {
        // Check if change violates configured threshold
        return false // Placeholder
    }
    
    private func matchesSearchCriteria(key: String, value: Any, criteria: StateSearchCriteria) -> Bool {
        switch criteria.searchType {
        case .keyPattern:
            return key.contains(criteria.searchTerm)
        case .valuePattern:
            return String(describing: value).contains(criteria.searchTerm)
        case .exact:
            return key == criteria.searchTerm || String(describing: value) == criteria.searchTerm
        case .type:
            return String(describing: type(of: value)).contains(criteria.searchTerm)
        }
    }
    
    private func determineMatchType(_ criteria: StateSearchCriteria) -> StateSearchMatchType {
        switch criteria.searchType {
        case .keyPattern: return .keyMatch
        case .valuePattern: return .valueMatch
        case .exact: return .exactMatch
        case .type: return .typeMatch
        }
    }
    
    private func summarizeStateIssues() -> StateIssuesSummary {
        let byType = Dictionary(grouping: detectedStateIssues, by: \.type)
        let bySeverity = Dictionary(grouping: detectedStateIssues, by: \.severity)
        
        return StateIssuesSummary(
            totalIssues: detectedStateIssues.count,
            byType: byType.mapValues(\.count),
            bySeverity: bySeverity.mapValues(\.count),
            mostRecentIssue: detectedStateIssues.max(by: { $0.detectedAt < $1.detectedAt })
        )
    }
    
    private func analyzeStatePerformance() -> StatePerformanceAnalysis {
        var totalUpdateFrequency = 0.0
        var slowestUpdates: [String] = []
        
        for (key, metrics) in statePerformanceMetrics {
            totalUpdateFrequency += metrics.updateFrequency
            
            if metrics.lastUpdateTime > configuration.slowUpdateThreshold {
                slowestUpdates.append(key)
            }
        }
        
        return StatePerformanceAnalysis(
            averageUpdateFrequency: totalUpdateFrequency / max(1, Double(statePerformanceMetrics.count)),
            slowestUpdatingKeys: slowestUpdates,
            totalTrackedKeys: statePerformanceMetrics.count,
            memoryEfficiency: calculateMemoryEfficiency()
        )
    }
    
    private func analyzeAccessPatterns() -> StateAccessPatternAnalysis {
        let sortedPatterns = stateAccessPatterns.values.sorted { $0.accessFrequency > $1.accessFrequency }
        let mostAccessedKeys = Array(sortedPatterns.prefix(10).map(\.key))
        let leastAccessedKeys = Array(sortedPatterns.suffix(10).map(\.key))
        
        return StateAccessPatternAnalysis(
            mostAccessedKeys: mostAccessedKeys,
            leastAccessedKeys: leastAccessedKeys,
            totalAccessCount: stateAccessPatterns.values.map(\.accessCount).reduce(0, +),
            averageAccessFrequency: stateAccessPatterns.values.map(\.accessFrequency).reduce(0, +) / max(1, Double(stateAccessPatterns.count))
        )
    }
    
    private func generateRecommendations() -> [StateRecommendation] {
        var recommendations: [StateRecommendation] = []
        
        // Check for excessive state changes
        let excessiveChangeKeys = stateTracking.values.filter { 
            $0.performanceMetrics.updateFrequency > configuration.excessiveChangeThreshold 
        }
        
        if !excessiveChangeKeys.isEmpty {
            recommendations.append(StateRecommendation(
                type: .performance,
                priority: .high,
                description: "\(excessiveChangeKeys.count) state keys updating excessively",
                action: "Consider debouncing or batching state updates"
            ))
        }
        
        // Check for memory usage
        if monitoringStatistics.memoryUsage > configuration.memoryUsageThreshold {
            recommendations.append(StateRecommendation(
                type: .memory,
                priority: .medium,
                description: "High state memory usage: \(formatBytes(monitoringStatistics.memoryUsage))",
                action: "Review state structure and remove unnecessary data"
            ))
        }
        
        // Check for issues
        if !detectedStateIssues.isEmpty {
            recommendations.append(StateRecommendation(
                type: .issues,
                priority: .high,
                description: "\(detectedStateIssues.count) state issues detected",
                action: "Investigate and resolve state issues"
            ))
        }
        
        return recommendations
    }
    
    private func identifyChangePatterns(_ changes: [StateChangeEvent]) -> [StateChangePattern] {
        // Identify patterns in state changes
        return [] // Placeholder
    }
    
    private func calculateAverageSnapshotSize() -> UInt64 {
        guard !stateHistory.isEmpty else { return 0 }
        return stateHistory.map(\.metadata.memoryUsage).reduce(0, +) / UInt64(stateHistory.count)
    }
    
    private func calculateCurrentStateMemoryUsage() -> UInt64 {
        return currentStateSnapshot?.metadata.memoryUsage ?? 0
    }
    
    private func calculateMemoryEfficiency() -> Double {
        // Calculate memory efficiency based on state usage patterns
        return 0.8 // Placeholder
    }
}

// MARK: - Supporting Components

public class StateInspector {
    private let configuration: StateInspectorConfiguration
    
    init(configuration: StateInspectorConfiguration) {
        self.configuration = configuration
    }
    
    func inspect(state: [String: SwiftUIStateValue], tracking: [String: StateValueTracking]) -> StateInspectionResult {
        var stateKeys: [StateKeyInfo] = []
        var stateStructure: [String: StateStructureInfo] = [:]
        var issues: [StateIssue] = []
        
        for (key, stateValue) in state {
            let keyInfo = StateKeyInfo(
                key: key,
                type: String(describing: type(of: stateValue.value)),
                size: estimateValueSize(stateValue.value),
                isTracked: tracking[key] != nil,
                lastModified: stateValue.timestamp
            )
            stateKeys.append(keyInfo)
            
            let structureInfo = StateStructureInfo(
                type: String(describing: type(of: stateValue.value)),
                complexity: calculateComplexity(stateValue.value),
                depth: calculateDepth(stateValue.value)
            )
            stateStructure[key] = structureInfo
        }
        
        return StateInspectionResult(
            timestamp: Date(),
            stateKeys: stateKeys,
            stateStructure: stateStructure,
            issues: issues,
            recommendations: generateInspectionRecommendations(stateKeys)
        )
    }
    
    private func estimateValueSize(_ value: Any) -> UInt64 {
        // Same implementation as in StateDebugger
        return 64 // Placeholder
    }
    
    private func calculateComplexity(_ value: Any) -> Int {
        // Calculate structural complexity
        return 1 // Placeholder
    }
    
    private func calculateDepth(_ value: Any) -> Int {
        // Calculate nesting depth
        return 1 // Placeholder
    }
    
    private func generateInspectionRecommendations(_ stateKeys: [StateKeyInfo]) -> [String] {
        var recommendations: [String] = []
        
        let largeKeys = stateKeys.filter { $0.size > 1024 * 1024 } // > 1MB
        if !largeKeys.isEmpty {
            recommendations.append("Consider optimizing large state values: \(largeKeys.map(\.key).joined(separator: ", "))")
        }
        
        return recommendations
    }
}

public class StateComparator {
    private let configuration: StateComparatorConfiguration
    
    init(configuration: StateComparatorConfiguration) {
        self.configuration = configuration
    }
    
    func compare(snapshot1: StateSnapshot, snapshot2: StateSnapshot) -> StateComparisonResult {
        var differences: [StateDifference] = []
        var addedKeys: [String] = []
        var removedKeys: [String] = []
        var modifiedKeys: [String] = []
        
        let keys1 = Set(snapshot1.stateData.keys)
        let keys2 = Set(snapshot2.stateData.keys)
        
        addedKeys = Array(keys2.subtracting(keys1))
        removedKeys = Array(keys1.subtracting(keys2))
        
        for key in keys1.intersection(keys2) {
            if !areValuesEqual(snapshot1.stateData[key], snapshot2.stateData[key]) {
                modifiedKeys.append(key)
                
                differences.append(StateDifference(
                    key: key,
                    type: .modified,
                    oldValue: snapshot1.stateData[key],
                    newValue: snapshot2.stateData[key]
                ))
            }
        }
        
        // Add differences for added/removed keys
        for key in addedKeys {
            differences.append(StateDifference(
                key: key,
                type: .added,
                oldValue: nil,
                newValue: snapshot2.stateData[key]
            ))
        }
        
        for key in removedKeys {
            differences.append(StateDifference(
                key: key,
                type: .removed,
                oldValue: snapshot1.stateData[key],
                newValue: nil
            ))
        }
        
        return StateComparisonResult(
            timestamp: Date(),
            snapshot1: snapshot1,
            snapshot2: snapshot2,
            differences: differences,
            addedKeys: addedKeys,
            removedKeys: removedKeys,
            modifiedKeys: modifiedKeys,
            summary: generateComparisonSummary(differences)
        )
    }
    
    private func areValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        // Compare values for equality
        guard let v1 = value1, let v2 = value2 else {
            return value1 == nil && value2 == nil
        }
        
        return String(describing: v1) == String(describing: v2) // Simplified comparison
    }
    
    private func generateComparisonSummary(_ differences: [StateDifference]) -> String {
        let added = differences.filter { $0.type == .added }.count
        let removed = differences.filter { $0.type == .removed }.count
        let modified = differences.filter { $0.type == .modified }.count
        
        return "\(added) added, \(removed) removed, \(modified) modified"
    }
}

public class StateValidator {
    private let configuration: StateValidatorConfiguration
    
    init(configuration: StateValidatorConfiguration) {
        self.configuration = configuration
    }
    
    func validate(state: [String: SwiftUIStateValue], baseline: [String: Any]) -> StateValidationResult {
        var validationErrors: [StateValidationError] = []
        var warnings: [StateValidationWarning] = []
        var isValid = true
        
        // Check for missing required keys
        for (key, _) in baseline {
            if state[key] == nil {
                validationErrors.append(StateValidationError(
                    key: key,
                    errorType: .missing,
                    description: "Required state key is missing",
                    severity: .critical
                ))
                isValid = false
            }
        }
        
        // Check for unexpected keys
        for (key, _) in state {
            if baseline[key] == nil {
                warnings.append(StateValidationWarning(
                    key: key,
                    warningType: .unexpected,
                    description: "Unexpected state key found"
                ))
            }
        }
        
        return StateValidationResult(
            timestamp: Date(),
            isValid: isValid,
            validationErrors: validationErrors,
            warnings: warnings,
            recommendations: generateValidationRecommendations(validationErrors, warnings)
        )
    }
    
    private func generateValidationRecommendations(_ errors: [StateValidationError], _ warnings: [StateValidationWarning]) -> [String] {
        var recommendations: [String] = []
        
        if !errors.isEmpty {
            recommendations.append("Fix \(errors.count) validation errors")
        }
        
        if !warnings.isEmpty {
            recommendations.append("Review \(warnings.count) validation warnings")
        }
        
        return recommendations
    }
}

public class StateExporter {
    private let configuration: StateExporterConfiguration
    
    init(configuration: StateExporterConfiguration) {
        self.configuration = configuration
    }
    
    func export(
        currentState: StateSnapshot?,
        history: [StateSnapshot],
        changeEvents: [StateChangeEvent],
        issues: [StateIssue],
        tracking: [String: StateValueTracking],
        format: StateExportFormat
    ) -> StateExportData {
        
        let exportData = StateExportableData(
            timestamp: Date(),
            currentState: currentState,
            history: history,
            changeEvents: changeEvents,
            issues: issues,
            tracking: tracking,
            metadata: StateExportMetadata(
                version: "1.0",
                format: format,
                generatedBy: "StateDebugger"
            )
        )
        
        let serializedData: Data
        
        switch format {
        case .json:
            serializedData = serializeToJSON(exportData)
        case .plist:
            serializedData = serializeToPlist(exportData)
        case .csv:
            serializedData = serializeToCSV(exportData)
        }
        
        return StateExportData(
            format: format,
            data: serializedData,
            metadata: exportData.metadata
        )
    }
    
    private func serializeToJSON(_ data: StateExportableData) -> Data {
        // Serialize to JSON
        return "{}".data(using: .utf8) ?? Data() // Placeholder
    }
    
    private func serializeToPlist(_ data: StateExportableData) -> Data {
        // Serialize to plist
        return Data() // Placeholder
    }
    
    private func serializeToCSV(_ data: StateExportableData) -> Data {
        // Serialize to CSV
        return Data() // Placeholder
    }
}

// MARK: - Core Types

public struct SwiftUIStateValue {
    public let value: Any
    public let timestamp: Date
    public let type: String
    
    public init(value: Any, timestamp: Date = Date()) {
        self.value = value
        self.timestamp = timestamp
        self.type = String(describing: Swift.type(of: value))
    }
}

// MARK: - Supporting Types

public struct StateSnapshot {
    public let id: String
    public let timestamp: Date
    public let reason: String
    public let stateData: [String: Any]
    public let metadata: StateSnapshotMetadata
}

public struct StateSnapshotMetadata {
    public let stateCount: Int
    public let memoryUsage: UInt64
    public let captureTime: TimeInterval
}

public struct StateChangeEvent {
    public let key: String
    public let oldValue: Any?
    public let newValue: Any?
    public let timestamp: Date
    public let context: StateChangeContext?
}

public struct StateChangeContext {
    public let operation: String?
    public let component: String?
    public let metadata: [String: Any]?
    
    public init(operation: String? = nil, component: String? = nil, metadata: [String: Any]? = nil) {
        self.operation = operation
        self.component = component
        self.metadata = metadata
    }
}

public struct StateIssue {
    public let id: String
    public let type: StateIssueType
    public let severity: StateIssueSeverity
    public let key: String
    public let description: String
    public let detectedAt: Date
    public let context: StateIssueContext?
}

public enum StateIssueType: String {
    case corruption = "corruption"
    case performance = "performance"
    case validation = "validation"
    case memory = "memory"
}

public enum StateIssueSeverity: String {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

public struct StateIssueContext {
    public let snapshot: StateSnapshot?
    public let previousSnapshot: StateSnapshot?
    public let changeEvent: StateChangeEvent?
    
    public init(snapshot: StateSnapshot? = nil, previousSnapshot: StateSnapshot? = nil, changeEvent: StateChangeEvent? = nil) {
        self.snapshot = snapshot
        self.previousSnapshot = previousSnapshot
        self.changeEvent = changeEvent
    }
}

public struct StateValueTracking {
    public let key: String
    public let registeredAt: Date
    public var changeHistory: [StateChangeEvent]
    public var accessCount: Int
    public var lastAccessed: Date
    public var performanceMetrics: StatePerformanceMetrics
}

public struct StatePerformanceMetrics {
    public var updateFrequency: Double = 0
    public var lastUpdateTime: TimeInterval = 0
    public var averageUpdateSize: UInt64 = 0
    public var memoryImpact: UInt64 = 0
}

public struct StateAccessPattern {
    public let key: String
    public var accessCount: Int
    public var lastAccessed: Date
    public var accessFrequency: Double
}

public struct StateChangeThreshold {
    public let maxFrequency: Double
    public let maxValueSize: UInt64
    public let allowedTypes: Set<String>
    
    public init(maxFrequency: Double = 100, maxValueSize: UInt64 = 1024 * 1024, allowedTypes: Set<String> = []) {
        self.maxFrequency = maxFrequency
        self.maxValueSize = maxValueSize
        self.allowedTypes = allowedTypes
    }
}

public struct MonitoringStatistics {
    public let totalSnapshots: Int
    public let totalChangeEvents: Int
    public let totalIssuesDetected: Int
    public let trackedKeys: Int
    public let monitoringDuration: TimeInterval
    public let averageSnapshotSize: UInt64
    public let memoryUsage: UInt64
    
    public init(
        totalSnapshots: Int = 0,
        totalChangeEvents: Int = 0,
        totalIssuesDetected: Int = 0,
        trackedKeys: Int = 0,
        monitoringDuration: TimeInterval = 0,
        averageSnapshotSize: UInt64 = 0,
        memoryUsage: UInt64 = 0
    ) {
        self.totalSnapshots = totalSnapshots
        self.totalChangeEvents = totalChangeEvents
        self.totalIssuesDetected = totalIssuesDetected
        self.trackedKeys = trackedKeys
        self.monitoringDuration = monitoringDuration
        self.averageSnapshotSize = averageSnapshotSize
        self.memoryUsage = memoryUsage
    }
}

// Search and Analysis Types
public struct StateSearchCriteria {
    public let searchTerm: String
    public let searchType: StateSearchType
    public let caseSensitive: Bool
    
    public init(searchTerm: String, searchType: StateSearchType, caseSensitive: Bool = false) {
        self.searchTerm = searchTerm
        self.searchType = searchType
        self.caseSensitive = caseSensitive
    }
}

public enum StateSearchType {
    case keyPattern
    case valuePattern
    case exact
    case type
}

public struct StateSearchResult {
    public let criteria: StateSearchCriteria
    public let matches: [StateSearchMatch]
    public let totalChecked: Int
}

public struct StateSearchMatch {
    public let key: String
    public let value: Any
    public let matchType: StateSearchMatchType
    public let path: [String]
}

public enum StateSearchMatchType {
    case keyMatch
    case valueMatch
    case exactMatch
    case typeMatch
}

// Inspection and Validation Types
public struct StateInspectionResult {
    public let timestamp: Date
    public let stateKeys: [StateKeyInfo]
    public let stateStructure: [String: StateStructureInfo]
    public let issues: [StateIssue]
    public let recommendations: [String]
}

public struct StateKeyInfo {
    public let key: String
    public let type: String
    public let size: UInt64
    public let isTracked: Bool
    public let lastModified: Date
}

public struct StateStructureInfo {
    public let type: String
    public let complexity: Int
    public let depth: Int
}

public struct StateValidationResult {
    public let timestamp: Date
    public let isValid: Bool
    public let validationErrors: [StateValidationError]
    public let warnings: [StateValidationWarning]
    public let recommendations: [String]
}

public struct StateValidationError {
    public let key: String
    public let errorType: StateValidationErrorType
    public let description: String
    public let severity: StateIssueSeverity
}

public enum StateValidationErrorType {
    case missing
    case typeMismatch
    case invalidValue
    case corruption
}

public struct StateValidationWarning {
    public let key: String
    public let warningType: StateValidationWarningType
    public let description: String
}

public enum StateValidationWarningType {
    case unexpected
    case deprecated
    case performance
    case size
}

// Comparison Types
public struct StateComparisonResult {
    public let timestamp: Date
    public let snapshot1: StateSnapshot
    public let snapshot2: StateSnapshot
    public let differences: [StateDifference]
    public let addedKeys: [String]
    public let removedKeys: [String]
    public let modifiedKeys: [String]
    public let summary: String
}

public struct StateDifference {
    public let key: String
    public let type: StateDifferenceType
    public let oldValue: Any?
    public let newValue: Any?
}

public enum StateDifferenceType {
    case added
    case removed
    case modified
}

// Export Types
public enum StateExportFormat {
    case json
    case plist
    case csv
}

public struct StateExportData {
    public let format: StateExportFormat
    public let data: Data
    public let metadata: StateExportMetadata
}

public struct StateExportableData {
    public let timestamp: Date
    public let currentState: StateSnapshot?
    public let history: [StateSnapshot]
    public let changeEvents: [StateChangeEvent]
    public let issues: [StateIssue]
    public let tracking: [String: StateValueTracking]
    public let metadata: StateExportMetadata
}

public struct StateExportMetadata {
    public let version: String
    public let format: StateExportFormat
    public let generatedBy: String
}

// Analysis Types
public struct StateAnalysis {
    public let timestamp: Date
    public let inspection: StateInspectionResult
    public let validation: StateValidationResult
    public let issuesSummary: StateIssuesSummary
    public let performanceAnalysis: StatePerformanceAnalysis
    public let accessPatterns: StateAccessPatternAnalysis
    public let monitoringStatistics: MonitoringStatistics
    public let recommendations: [StateRecommendation]
}

public struct StateIssuesSummary {
    public let totalIssues: Int
    public let byType: [StateIssueType: Int]
    public let bySeverity: [StateIssueSeverity: Int]
    public let mostRecentIssue: StateIssue?
}

public struct StatePerformanceAnalysis {
    public let averageUpdateFrequency: Double
    public let slowestUpdatingKeys: [String]
    public let totalTrackedKeys: Int
    public let memoryEfficiency: Double
}

public struct StateAccessPatternAnalysis {
    public let mostAccessedKeys: [String]
    public let leastAccessedKeys: [String]
    public let totalAccessCount: Int
    public let averageAccessFrequency: Double
}

public struct StateChangeTrends {
    public let timeWindow: TimeInterval
    public let totalChanges: Int
    public let changesByKey: [String: Int]
    public let mostActiveKeys: [String]
    public let averageChangesPerMinute: Double
    public let patterns: [StateChangePattern]
}

public struct StateChangePattern {
    public let type: String
    public let description: String
    public let frequency: Double
    public let affectedKeys: [String]
}

public struct StateRecommendation {
    public let type: StateRecommendationType
    public let priority: RecommendationPriority
    public let description: String
    public let action: String
}

public enum StateRecommendationType: String {
    case performance = "performance"
    case memory = "memory"
    case issues = "issues"
    case structure = "structure"
}

public enum StateDebugError: Error, LocalizedError {
    case stateIssue(StateIssue)
    case validationFailed(String)
    case exportFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .stateIssue(let issue):
            return "State issue detected: \(issue.description)"
        case .validationFailed(let reason):
            return "State validation failed: \(reason)"
        case .exportFailed(let reason):
            return "State export failed: \(reason)"
        }
    }
}

// MARK: - Configuration

public struct StateDebuggerConfiguration {
    public let enableAutoMonitoring: Bool
    public let enableDebugLogging: Bool
    public let enablePeriodicSnapshots: Bool
    public let enableCorruptionDetection: Bool
    public let enableDataCleanup: Bool
    
    public let monitoringInterval: TimeInterval
    public let analysisInterval: TimeInterval
    public let dataRetentionPeriod: TimeInterval
    
    public let maxHistorySize: Int
    public let maxChangeEvents: Int
    public let maxChangeHistoryPerKey: Int
    public let maxStoredIssues: Int
    
    public let stateGrowthThreshold: Double
    public let memoryUsageThreshold: UInt64
    public let excessiveChangeThreshold: Double
    public let slowUpdateThreshold: TimeInterval
    
    public let inspectorConfig: StateInspectorConfiguration
    public let comparatorConfig: StateComparatorConfiguration
    public let validatorConfig: StateValidatorConfiguration
    public let exporterConfig: StateExporterConfiguration
    
    public init(
        enableAutoMonitoring: Bool = true,
        enableDebugLogging: Bool = false,
        enablePeriodicSnapshots: Bool = true,
        enableCorruptionDetection: Bool = true,
        enableDataCleanup: Bool = true,
        monitoringInterval: TimeInterval = 30.0,
        analysisInterval: TimeInterval = 60.0,
        dataRetentionPeriod: TimeInterval = 3600.0,
        maxHistorySize: Int = 50,
        maxChangeEvents: Int = 1000,
        maxChangeHistoryPerKey: Int = 100,
        maxStoredIssues: Int = 200,
        stateGrowthThreshold: Double = 1.5,
        memoryUsageThreshold: UInt64 = 50 * 1024 * 1024,
        excessiveChangeThreshold: Double = 60.0,
        slowUpdateThreshold: TimeInterval = 1.0
    ) {
        self.enableAutoMonitoring = enableAutoMonitoring
        self.enableDebugLogging = enableDebugLogging
        self.enablePeriodicSnapshots = enablePeriodicSnapshots
        self.enableCorruptionDetection = enableCorruptionDetection
        self.enableDataCleanup = enableDataCleanup
        self.monitoringInterval = monitoringInterval
        self.analysisInterval = analysisInterval
        self.dataRetentionPeriod = dataRetentionPeriod
        self.maxHistorySize = maxHistorySize
        self.maxChangeEvents = maxChangeEvents
        self.maxChangeHistoryPerKey = maxChangeHistoryPerKey
        self.maxStoredIssues = maxStoredIssues
        self.stateGrowthThreshold = stateGrowthThreshold
        self.memoryUsageThreshold = memoryUsageThreshold
        self.excessiveChangeThreshold = excessiveChangeThreshold
        self.slowUpdateThreshold = slowUpdateThreshold
        
        self.inspectorConfig = StateInspectorConfiguration()
        self.comparatorConfig = StateComparatorConfiguration()
        self.validatorConfig = StateValidatorConfiguration()
        self.exporterConfig = StateExporterConfiguration()
    }
    
    public static func development() -> StateDebuggerConfiguration {
        return StateDebuggerConfiguration(
            enableDebugLogging: true,
            monitoringInterval: 10.0,
            analysisInterval: 30.0,
            maxHistorySize: 100,
            maxChangeEvents: 2000,
            stateGrowthThreshold: 1.3,
            memoryUsageThreshold: 20 * 1024 * 1024,
            excessiveChangeThreshold: 30.0
        )
    }
    
    public static func production() -> StateDebuggerConfiguration {
        return StateDebuggerConfiguration(
            enableDebugLogging: false,
            enablePeriodicSnapshots: false,
            monitoringInterval: 120.0,
            analysisInterval: 300.0,
            maxHistorySize: 20,
            maxChangeEvents: 500
        )
    }
}

public struct StateInspectorConfiguration {
    public let maxInspectionDepth: Int
    public let enableTypeAnalysis: Bool
    
    public init(maxInspectionDepth: Int = 10, enableTypeAnalysis: Bool = true) {
        self.maxInspectionDepth = maxInspectionDepth
        self.enableTypeAnalysis = enableTypeAnalysis
    }
}

public struct StateComparatorConfiguration {
    public let enableDeepComparison: Bool
    public let maxComparisonDepth: Int
    
    public init(enableDeepComparison: Bool = true, maxComparisonDepth: Int = 5) {
        self.enableDeepComparison = enableDeepComparison
        self.maxComparisonDepth = maxComparisonDepth
    }
}

public struct StateValidatorConfiguration {
    public let enableTypeValidation: Bool
    public let enableRangeValidation: Bool
    
    public init(enableTypeValidation: Bool = true, enableRangeValidation: Bool = true) {
        self.enableTypeValidation = enableTypeValidation
        self.enableRangeValidation = enableRangeValidation
    }
}

public struct StateExporterConfiguration {
    public let defaultFormat: StateExportFormat
    public let includeMetadata: Bool
    
    public init(defaultFormat: StateExportFormat = .json, includeMetadata: Bool = true) {
        self.defaultFormat = defaultFormat
        self.includeMetadata = includeMetadata
    }
}