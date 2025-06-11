import Foundation
import OSLog

// MARK: - Core Logging Types

/// Log levels for filtering and categorizing log messages
public enum LogLevel: Int, Comparable, Sendable, CaseIterable {
    case trace = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

/// Protocol for values that can be logged safely
public protocol LoggableValue: CustomStringConvertible, Sendable {
    /// Whether this value contains private information
    var isPrivate: Bool { get }
}

/// Public string that can be safely logged in all builds
public struct PublicString: LoggableValue {
    private let value: String
    public let isPrivate = false
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var description: String {
        value
    }
}

/// Private string that is redacted in non-debug builds
public struct PrivateString: LoggableValue {
    private let value: String
    public let isPrivate = true
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var description: String {
        #if DEBUG
        return value
        #else
        return "<private>"
        #endif
    }
}

/// Metadata for structured logging
public struct LogMetadata: ExpressibleByDictionaryLiteral, Sendable {
    public let values: [String: LoggableValue]
    
    public init(dictionaryLiteral elements: (String, LoggableValue)...) {
        self.values = Dictionary(uniqueKeysWithValues: elements)
    }
    
    public init(_ values: [String: LoggableValue] = [:]) {
        self.values = values
    }
}

/// Log categories for filtering and organization
public struct LogCategory: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    // Standard categories
    public static let context = LogCategory(rawValue: "axiom.context")
    public static let client = LogCategory(rawValue: "axiom.client")
    public static let capability = LogCategory(rawValue: "axiom.capability")
    public static let navigation = LogCategory(rawValue: "axiom.navigation")
    public static let performance = LogCategory(rawValue: "axiom.performance")
    public static let error = LogCategory(rawValue: "axiom.error")
    
    public static let allCases: [LogCategory] = [
        .context, .client, .capability, .navigation, .performance, .error
    ]
}

// MARK: - Logger Protocol

/// Core logger protocol
public protocol Logger: Sendable {
    /// Log a message with specified level and metadata
    func log(_ level: LogLevel, _ message: @autoclosure () -> String, metadata: LogMetadata?)
    
    /// Log a loggable value with specified level and metadata
    func log<T: LoggableValue>(_ level: LogLevel, _ value: T, metadata: LogMetadata?)
}

// MARK: - Log Destinations

/// Protocol for log output destinations
public protocol LogDestination: Sendable {
    /// Write a log entry to the destination
    func write(_ entry: LogEntry)
    
    /// Flush any buffered log entries
    func flush()
}

/// Represents a single log entry
public struct LogEntry: Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let metadata: LogMetadata?
    public let category: LogCategory
    public let subsystem: String
    
    public init(
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        metadata: LogMetadata?,
        category: LogCategory,
        subsystem: String
    ) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.metadata = metadata
        self.category = category
        self.subsystem = subsystem
    }
}

/// Log destination types
public enum LogDestinationType: Sendable {
    case console
    case oslog
    case file(URL)
    case custom(LogDestination)
}

// MARK: - Console Log Destination

/// Console output destination for development
public struct ConsoleLogDestination: LogDestination {
    public init() {}
    
    public func write(_ entry: LogEntry) {
        let timestamp = DateFormatter.logFormatter.string(from: entry.timestamp)
        let metadataString = formatMetadata(entry.metadata)
        
        let output = "[\(timestamp)] [\(entry.level.description)] [\(entry.category.rawValue)] \(entry.message)\(metadataString)"
        print(output)
    }
    
    public func flush() {
        // Console output is immediately flushed
    }
    
    private func formatMetadata(_ metadata: LogMetadata?) -> String {
        guard let metadata = metadata, !metadata.values.isEmpty else { return "" }
        
        let items = metadata.values.map { key, value in
            "\(key)=\(value.description)"
        }.joined(separator: ", ")
        
        return " {\(items)}"
    }
}

/// OSLog destination for production logging
public struct OSLogDestination: LogDestination {
    private let osLog: OSLog
    
    public init(subsystem: String, category: LogCategory) {
        self.osLog = OSLog(subsystem: subsystem, category: category.rawValue)
    }
    
    public func write(_ entry: LogEntry) {
        let osLogType: OSLogType = switch entry.level {
        case .trace, .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        case .critical: .fault
        }
        
        let metadataString = formatMetadata(entry.metadata)
        let message = "\(entry.message)\(metadataString)"
        
        os_log("%{public}@", log: osLog, type: osLogType, message)
    }
    
    public func flush() {
        // OSLog handles flushing automatically
    }
    
    private func formatMetadata(_ metadata: LogMetadata?) -> String {
        guard let metadata = metadata, !metadata.values.isEmpty else { return "" }
        
        let items = metadata.values.map { key, value in
            if value.isPrivate {
                return "\(key)=%{private}@"
            } else {
                return "\(key)=%{public}@"
            }
        }.joined(separator: ", ")
        
        return " {\(items)}"
    }
}

// MARK: - Log Configuration

/// Configuration for logging behavior
public struct LogConfiguration: Sendable {
    public let minimumLevel: LogLevel
    public let enabledCategories: Set<LogCategory>
    public let outputDestination: LogDestinationType
    
    public init(
        minimumLevel: LogLevel,
        enabledCategories: Set<LogCategory>,
        outputDestination: LogDestinationType
    ) {
        self.minimumLevel = minimumLevel
        self.enabledCategories = enabledCategories
        self.outputDestination = outputDestination
    }
    
    /// Debug configuration for development
    public static let debug = LogConfiguration(
        minimumLevel: .debug,
        enabledCategories: Set(LogCategory.allCases),
        outputDestination: .console
    )
    
    /// Release configuration for production
    public static let release = LogConfiguration(
        minimumLevel: .warning,
        enabledCategories: [.error, .performance],
        outputDestination: .oslog
    )
    
    /// Check if a log should be written based on level and category
    public func shouldLog(level: LogLevel, category: LogCategory) -> Bool {
        level >= minimumLevel && enabledCategories.contains(category)
    }
}

// MARK: - Category Logger

/// Logger implementation with category support
public struct CategoryLogger: Logger {
    public let category: LogCategory
    public let subsystem: String
    private let destination: LogDestination
    private let configuration: LogConfiguration
    
    public init(
        category: LogCategory,
        subsystem: String,
        destination: LogDestination,
        configuration: LogConfiguration = .debug
    ) {
        self.category = category
        self.subsystem = subsystem
        self.destination = destination
        self.configuration = configuration
    }
    
    /// Create a logger for a specific category with default configuration
    public static func logger(for category: LogCategory) -> CategoryLogger {
        return CategoryLogger(
            category: category,
            subsystem: "com.axiom.framework",
            destination: ConsoleLogDestination(),
            configuration: .debug
        )
    }
    
    public func log(_ level: LogLevel, _ message: @autoclosure () -> String, metadata: LogMetadata?) {
        guard configuration.shouldLog(level: level, category: category) else { return }
        
        let entry = LogEntry(
            level: level,
            message: message(),
            metadata: metadata,
            category: category,
            subsystem: subsystem
        )
        
        destination.write(entry)
    }
    
    public func log<T: LoggableValue>(_ level: LogLevel, _ value: T, metadata: LogMetadata?) {
        log(level, value.description, metadata: metadata)
    }
}

// MARK: - Performance Logger

/// Logger specialized for performance metrics
public struct PerformanceLogger: Sendable {
    private let logger: Logger
    
    public init(logger: Logger) {
        self.logger = logger
    }
    
    /// Time an async operation and log the duration
    public func time<T>(
        _ operation: String,
        metadata: LogMetadata? = nil,
        body: () async throws -> T
    ) async rethrows -> T {
        let start = ContinuousClock.now
        defer {
            let duration = ContinuousClock.now - start
            let durationMs = Double(duration.components.attoseconds) / 1_000_000_000_000_000.0
            logger.log(LogLevel.debug, "Operation '\(operation)' took \(String(format: "%.2f", durationMs))ms", 
                      metadata: metadata)
        }
        return try await body()
    }
    
    /// Log current memory usage
    public func memory(
        _ label: String,
        metadata: LogMetadata? = nil
    ) {
        let usage = getMemoryUsage()
        logger.log(LogLevel.debug, "Memory at '\(label)': \(String(format: "%.1f", usage))MB", 
                  metadata: metadata)
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024.0 * 1024.0) // Convert to MB
        } else {
            return 0.0
        }
    }
}

// MARK: - Log Manager

/// Global log manager for configuration
public actor LogManager {
    public static let shared = LogManager()
    
    private var _configuration: LogConfiguration = .debug
    private var _destination: LogDestination = ConsoleLogDestination()
    
    private init() {}
    
    public var configuration: LogConfiguration {
        _configuration
    }
    
    public var destination: LogDestination {
        _destination
    }
    
    public func setConfiguration(_ configuration: LogConfiguration) {
        _configuration = configuration
        
        // Update destination based on configuration
        switch configuration.outputDestination {
        case .console:
            _destination = ConsoleLogDestination()
        case .oslog:
            _destination = OSLogDestination(subsystem: "com.axiom.framework", category: .context)
        case .file(let url):
            // File destination would be implemented here
            _destination = ConsoleLogDestination() // Fallback for now
        case .custom(let destination):
            _destination = destination
        }
    }
    
    public func setDestination(_ destination: LogDestination) {
        _destination = destination
    }
}

// MARK: - Extensions

public extension Logger {
    /// Log private information safely
    func logPrivate(_ level: LogLevel, _ message: String, metadata: LogMetadata? = nil) {
        log(level, PrivateString(message), metadata: metadata)
    }
    
    /// Convenience methods for each log level
    func trace(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.trace, message(), metadata: metadata)
    }
    
    func debug(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.debug, message(), metadata: metadata)
    }
    
    func info(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.info, message(), metadata: metadata)
    }
    
    func warning(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.warning, message(), metadata: metadata)
    }
    
    func error(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.error, message(), metadata: metadata)
    }
    
    func critical(_ message: @autoclosure () -> String, metadata: LogMetadata? = nil) {
        log(LogLevel.critical, message(), metadata: metadata)
    }
}

// MARK: - Helper Extensions

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Framework Integration Extensions

public extension Context {
    var logger: CategoryLogger {
        .logger(for: .context)
    }
    
    func logLifecycle(_ event: String) {
        logger.log(LogLevel.debug, "[\(type(of: self))] \(event)", metadata: nil)
    }
}

public extension Client {
    var logger: CategoryLogger {
        .logger(for: .client)
    }
    
    func logAction(_ action: ActionType) {
        logger.log(LogLevel.debug, "Processing action: \(action)", metadata: nil)
    }
}

public extension Capability {
    var logger: CategoryLogger {
        .logger(for: .capability)
    }
    
    func logStateTransition(from oldState: String, to newState: String) {
        logger.log(LogLevel.debug, "[\(type(of: self))] State transition: \(oldState) -> \(newState)", metadata: nil)
    }
}