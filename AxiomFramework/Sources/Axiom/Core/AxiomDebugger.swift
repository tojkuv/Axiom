import Foundation
import SwiftUI

// MARK: - Axiom Framework Debugger

/// Comprehensive debugging utilities for the Axiom framework
public actor AxiomDebugger {
    public static let shared = AxiomDebugger()
    
    // MARK: - Configuration
    private var isEnabled: Bool = true
    private var logLevel: LogLevel = .info
    private var logHistory: [LogEntry] = []
    private let maxLogEntries = 1000
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable debugging
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// Set the minimum log level
    public func setLogLevel(_ level: LogLevel) {
        logLevel = level
    }
    
    // MARK: - Logging Methods
    
    /// Log a debug message
    public func log(
        _ message: String,
        level: LogLevel = .debug,
        component: String = "Unknown",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled && level >= logLevel else { return }
        
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            component: component,
            message: message,
            file: URL(fileURLWithPath: file).lastPathComponent,
            function: function,
            line: line
        )
        
        addLogEntry(entry)
        
        // Print to console for immediate visibility
        print("🧠 [\(level.emoji) \(component)] \(message)")
    }
    
    /// Log client state changes
    public func logClientStateChange<T: AxiomClient>(_ client: T, state: T.State) {
        log(
            "State changed: \(String(describing: state))",
            level: .info,
            component: "Client[\(String(describing: type(of: client)))]"
        )
    }
    
    /// Log context operations
    public func logContextOperation(_ operation: String, context: any AxiomContext) {
        log(
            "Operation: \(operation)",
            level: .info,
            component: "Context[\(String(describing: type(of: context)))]"
        )
    }
    
    /// Log capability validation
    public func logCapabilityValidation(_ capability: Capability, result: Bool, reason: String? = nil) {
        let message = result ? "✅ Validated" : "❌ Failed: \(reason ?? "Unknown reason")"
        log(
            "\(capability.rawValue) - \(message)",
            level: result ? .info : .warning,
            component: "CapabilityValidator"
        )
    }
    
    /// Log intelligence queries
    public func logIntelligenceQuery(_ query: String, response: String, confidence: Double) {
        log(
            "Query: '\(query)' → Response: '\(response)' (confidence: \(String(format: "%.2f", confidence)))",
            level: .info,
            component: "Intelligence"
        )
    }
    
    /// Log performance metrics
    public func logPerformanceMetric(_ operation: String, duration: TimeInterval, category: PerformanceCategory) {
        let level: LogLevel = duration > 0.1 ? .warning : .debug
        log(
            "Performance: \(operation) took \(String(format: "%.3f", duration))s",
            level: level,
            component: "Performance[\(category.rawValue)]"
        )
    }
    
    // MARK: - Error Logging
    
    /// Log an error with full context
    public func logError(_ error: any AxiomError) {
        log(
            "Error [\(error.category.rawValue)]: \(error.userMessage)",
            level: .error,
            component: error.context.component.description
        )
        
        // Log recovery actions if available
        if !error.recoveryActions.isEmpty {
            log(
                "Recovery actions: \(error.recoveryActions.map(\.description).joined(separator: ", "))",
                level: .info,
                component: error.context.component.description
            )
        }
    }
    
    // MARK: - State Inspection
    
    /// Generate a comprehensive debug report
    public func generateDebugReport() -> DebugReport {
        let recentLogs = Array(logHistory.suffix(100))
        
        return DebugReport(
            timestamp: Date(),
            logEntries: recentLogs,
            systemInfo: gatherSystemInfo(),
            frameworkInfo: gatherFrameworkInfo()
        )
    }
    
    /// Get recent log entries
    public func getRecentLogs(count: Int = 50) -> [LogEntry] {
        Array(logHistory.suffix(count))
    }
    
    /// Clear log history
    public func clearLogs() {
        logHistory.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func addLogEntry(_ entry: LogEntry) {
        logHistory.append(entry)
        
        // Maintain size limit
        if logHistory.count > maxLogEntries {
            let excess = logHistory.count - maxLogEntries
            logHistory.removeFirst(excess)
        }
    }
    
    private func gatherSystemInfo() -> SystemInfo {
        return SystemInfo(
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: ProcessInfo.processInfo.hostName,
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage()
        )
    }
    
    private func gatherFrameworkInfo() -> FrameworkInfo {
        return FrameworkInfo(
            version: "1.0.0", // Would be read from build info
            buildDate: Date(),
            enabledCapabilities: [], // Would query capability manager
            activeClients: 0, // Would query active clients
            activeContexts: 0 // Would query active contexts
        )
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    private func getCPUUsage() -> Double {
        // Simplified CPU usage - in a real implementation would use task_info
        return 0.0
    }
}

// MARK: - Log Level

public enum LogLevel: Int, CaseIterable, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

// MARK: - Log Entry

public struct LogEntry: Sendable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let level: LogLevel
    public let component: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    
    public var formattedMessage: String {
        let timeString = DateFormatter.debugTimestamp.string(from: timestamp)
        return "\(timeString) [\(level.name)] \(component): \(message)"
    }
}

// MARK: - Debug Report

public struct DebugReport: Sendable {
    public let timestamp: Date
    public let logEntries: [LogEntry]
    public let systemInfo: SystemInfo
    public let frameworkInfo: FrameworkInfo
    
    public func exportAsText() -> String {
        var output = """
        AXIOM FRAMEWORK DEBUG REPORT
        Generated: \(DateFormatter.debugTimestamp.string(from: timestamp))
        
        SYSTEM INFO:
        OS Version: \(systemInfo.osVersion)
        Device: \(systemInfo.deviceModel)
        Memory Usage: \(ByteCountFormatter.string(fromByteCount: Int64(systemInfo.memoryUsage), countStyle: .memory))
        CPU Usage: \(String(format: "%.1f", systemInfo.cpuUsage))%
        
        FRAMEWORK INFO:
        Version: \(frameworkInfo.version)
        Build Date: \(DateFormatter.debugTimestamp.string(from: frameworkInfo.buildDate))
        Active Clients: \(frameworkInfo.activeClients)
        Active Contexts: \(frameworkInfo.activeContexts)
        
        RECENT LOG ENTRIES:
        """
        
        for entry in logEntries {
            output += "\n\(entry.formattedMessage)"
        }
        
        return output
    }
}

// MARK: - System Info

public struct SystemInfo: Sendable {
    public let osVersion: String
    public let deviceModel: String
    public let memoryUsage: Int
    public let cpuUsage: Double
}

// MARK: - Framework Info

public struct FrameworkInfo: Sendable {
    public let version: String
    public let buildDate: Date
    public let enabledCapabilities: [Capability]
    public let activeClients: Int
    public let activeContexts: Int
}

// MARK: - Convenience Extensions

extension DateFormatter {
    static let debugTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - SwiftUI Integration

/// SwiftUI view for displaying debug information
public struct AxiomDebugView: View {
    @State private var debugReport: DebugReport?
    @State private var isLoading = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Generating debug report...")
                        .padding()
                } else if let report = debugReport {
                    DebugReportView(report: report)
                } else {
                    Text("Tap to generate debug report")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Generate Debug Report") {
                    generateReport()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Axiom Debug")
            .onAppear {
                generateReport()
            }
        }
    }
    
    private func generateReport() {
        isLoading = true
        Task {
            let report = await AxiomDebugger.shared.generateDebugReport()
            await MainActor.run {
                self.debugReport = report
                self.isLoading = false
            }
        }
    }
}

private struct DebugReportView: View {
    let report: DebugReport
    
    var body: some View {
        List {
            Section("System Information") {
                HStack {
                    Text("OS Version")
                    Spacer()
                    Text(report.systemInfo.osVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(report.systemInfo.memoryUsage), countStyle: .memory))
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Framework Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(report.frameworkInfo.version)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Active Clients")
                    Spacer()
                    Text("\(report.frameworkInfo.activeClients)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Active Contexts")
                    Spacer()
                    Text("\(report.frameworkInfo.activeContexts)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Recent Log Entries") {
                ForEach(report.logEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.level.emoji)
                            Text(entry.component)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(DateFormatter.debugTimestamp.string(from: entry.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(entry.message)
                            .font(.body)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

// MARK: - Global Debug Macros

/// Log a debug message using the global debugger
public func axiomLog(
    _ message: String,
    level: LogLevel = .debug,
    component: String = "App",
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Task {
        await AxiomDebugger.shared.log(
            message,
            level: level,
            component: component,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Log an error using the global debugger
public func axiomLogError(_ error: any AxiomError) {
    Task {
        await AxiomDebugger.shared.logError(error)
    }
}