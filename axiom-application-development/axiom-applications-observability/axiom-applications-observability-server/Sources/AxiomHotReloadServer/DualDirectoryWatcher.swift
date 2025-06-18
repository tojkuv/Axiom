import Foundation
import Logging
import HotReloadProtocol

public protocol DualDirectoryWatcherDelegate: AnyObject {
    func watcher(_ watcher: DualDirectoryWatcher, didDetectChange event: PlatformFileChangeEvent)
    func watcher(_ watcher: DualDirectoryWatcher, didEncounterError error: Error)
}

public final class DualDirectoryWatcher {
    
    public weak var delegate: DualDirectoryWatcherDelegate?
    
    private let swiftUIDirectory: String?
    private let composeDirectory: String?
    private let logger: Logger
    
    private var swiftUIMonitor: DebouncedFileMonitor?
    private var composeMonitor: DebouncedFileMonitor?
    
    private let configuration: DualDirectoryConfiguration
    
    public init(
        swiftUIDirectory: String?,
        composeDirectory: String?,
        configuration: DualDirectoryConfiguration = DualDirectoryConfiguration(),
        logger: Logger = Logger(label: "axiom.hotreload.dual-directory")
    ) {
        self.swiftUIDirectory = swiftUIDirectory
        self.composeDirectory = composeDirectory
        self.configuration = configuration
        self.logger = logger
    }
    
    public func startWatching() async throws {
        logger.info("Starting dual directory watching")
        
        // Start SwiftUI directory monitoring
        if let swiftUIDirectory = swiftUIDirectory {
            logger.info("Starting SwiftUI directory monitoring: \(swiftUIDirectory)")
            try await startSwiftUIMonitoring(directory: swiftUIDirectory)
        }
        
        // Start Compose directory monitoring
        if let composeDirectory = composeDirectory {
            logger.info("Starting Compose directory monitoring: \(composeDirectory)")
            try await startComposeMonitoring(directory: composeDirectory)
        }
        
        if swiftUIDirectory == nil && composeDirectory == nil {
            throw DualDirectoryWatcherError.noDirectoriesSpecified
        }
        
        logger.info("Dual directory watching started successfully")
    }
    
    public func stopWatching() async {
        logger.info("Stopping dual directory watching")
        
        swiftUIMonitor?.stopMonitoring()
        composeMonitor?.stopMonitoring()
        
        swiftUIMonitor = nil
        composeMonitor = nil
        
        logger.info("Dual directory watching stopped")
    }
    
    private func startSwiftUIMonitoring(directory: String) async throws {
        let directoryURL = URL(fileURLWithPath: directory)
        
        guard FileManager.default.fileExists(atPath: directory) else {
            throw DualDirectoryWatcherError.directoryNotFound(directory)
        }
        
        let monitor = DebouncedFileMonitor(debounceInterval: configuration.debounceInterval)
        
        // Configure for Swift files
        monitor.configure(
            includeExtensions: [".swift"],
            excludePatterns: configuration.swiftUIExcludePatterns
        )
        
        try monitor.startMonitoring(directory: directoryURL) { [weak self] event in
            self?.handleSwiftUIFileChange(event)
        }
        
        self.swiftUIMonitor = monitor
        logger.debug("SwiftUI file monitoring started for: \(directory)")
    }
    
    private func startComposeMonitoring(directory: String) async throws {
        let directoryURL = URL(fileURLWithPath: directory)
        
        guard FileManager.default.fileExists(atPath: directory) else {
            throw DualDirectoryWatcherError.directoryNotFound(directory)
        }
        
        let monitor = DebouncedFileMonitor(debounceInterval: configuration.debounceInterval)
        
        // Configure for Kotlin files
        monitor.configure(
            includeExtensions: [".kt", ".kts"],
            excludePatterns: configuration.composeExcludePatterns
        )
        
        try monitor.startMonitoring(directory: directoryURL) { [weak self] event in
            self?.handleComposeFileChange(event)
        }
        
        self.composeMonitor = monitor
        logger.debug("Compose file monitoring started for: \(directory)")
    }
    
    private func handleSwiftUIFileChange(_ event: FileChangeEvent) {
        logger.debug("SwiftUI file change detected: \(event.path)")
        
        let platformEvent = PlatformFileChangeEvent(
            platform: .ios,
            filePath: event.path,
            fileName: URL(fileURLWithPath: event.path).lastPathComponent,
            changeType: mapChangeType(event.type),
            timestamp: event.timestamp
        )
        
        delegate?.watcher(self, didDetectChange: platformEvent)
    }
    
    private func handleComposeFileChange(_ event: FileChangeEvent) {
        logger.debug("Compose file change detected: \(event.path)")
        
        let platformEvent = PlatformFileChangeEvent(
            platform: .android,
            filePath: event.path,
            fileName: URL(fileURLWithPath: event.path).lastPathComponent,
            changeType: mapChangeType(event.type),
            timestamp: event.timestamp
        )
        
        delegate?.watcher(self, didDetectChange: platformEvent)
    }
    
    private func mapChangeType(_ fileChangeType: FileChangeType) -> ChangeType {
        switch fileChangeType {
        case .created:
            return .created
        case .modified:
            return .modified
        case .deleted:
            return .deleted
        case .renamed:
            return .renamed
        case .moved:
            return .renamed // Map moved to renamed for simplicity
        }
    }
}

// MARK: - Supporting Types

public struct PlatformFileChangeEvent {
    public let platform: Platform
    public let filePath: String
    public let fileName: String
    public let changeType: ChangeType
    public let timestamp: Date
    
    public init(platform: Platform, filePath: String, fileName: String, changeType: ChangeType, timestamp: Date) {
        self.platform = platform
        self.filePath = filePath
        self.fileName = fileName
        self.changeType = changeType
        self.timestamp = timestamp
    }
}

public struct DualDirectoryConfiguration {
    public let debounceInterval: TimeInterval
    public let swiftUIExcludePatterns: [String]
    public let composeExcludePatterns: [String]
    public let enableRecursiveMonitoring: Bool
    public let maxFileSize: Int // Maximum file size to process (in bytes)
    
    public init(
        debounceInterval: TimeInterval = 0.5,
        swiftUIExcludePatterns: [String] = ["*.xcodeproj", "*.git", "*.build", "DerivedData", ".swiftpm"],
        composeExcludePatterns: [String] = ["*.gradle", "*.git", "build", ".idea", "*.iml"],
        enableRecursiveMonitoring: Bool = true,
        maxFileSize: Int = 1024 * 1024 // 1MB
    ) {
        self.debounceInterval = debounceInterval
        self.swiftUIExcludePatterns = swiftUIExcludePatterns
        self.composeExcludePatterns = composeExcludePatterns
        self.enableRecursiveMonitoring = enableRecursiveMonitoring
        self.maxFileSize = maxFileSize
    }
}

public enum DualDirectoryWatcherError: Error, LocalizedError {
    case noDirectoriesSpecified
    case directoryNotFound(String)
    case monitoringFailed(String)
    case invalidConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .noDirectoriesSpecified:
            return "No directories specified for monitoring"
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .monitoringFailed(let details):
            return "File monitoring failed: \(details)"
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
        }
    }
}

// MARK: - Adapted File System Monitor Classes

/// Monitors file system changes for hot reload
internal class FileSystemMonitor {
    private var dispatchSources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [Int32] = []
    private var changeHandler: ((FileChangeEvent) -> Void)?
    
    /// Configuration for file monitoring
    internal var includeExtensions: [String] = [".swift"]
    internal var excludePatterns: [String] = ["*.xcodeproj", "*.git", "*.build"]
    
    internal init() {}
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Configuration
    
    /// Configures file monitoring parameters
    internal func configure(includeExtensions: [String], excludePatterns: [String]) {
        self.includeExtensions = includeExtensions
        self.excludePatterns = excludePatterns
    }
    
    // MARK: - Directory Monitoring
    
    /// Starts monitoring a directory for file changes
    internal func startMonitoring(directory: URL, onChange: @escaping (FileChangeEvent) -> Void) throws {
        guard directory.hasDirectoryPath else {
            throw FileMonitorError.invalidPath("Path is not a directory: \(directory.path)")
        }
        
        self.changeHandler = onChange
        
        let fileDescriptor = open(directory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            throw FileMonitorError.cannotOpenFile("Cannot open directory: \(directory.path)")
        }
        
        fileDescriptors.append(fileDescriptor)
        
        let dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: DispatchQueue.global(qos: .utility)
        )
        
        dispatchSource.setEventHandler { [weak self] in
            self?.handleDirectoryChange(at: directory.path)
        }
        
        dispatchSource.setCancelHandler {
            close(fileDescriptor)
        }
        
        dispatchSources.append(dispatchSource)
        dispatchSource.resume()
    }
    
    /// Stops all monitoring
    internal func stopMonitoring() {
        for source in dispatchSources {
            source.cancel()
        }
        dispatchSources.removeAll()
        
        for fd in fileDescriptors {
            close(fd)
        }
        fileDescriptors.removeAll()
        
        changeHandler = nil
    }
    
    // MARK: - Directory Change Handling
    
    private func handleDirectoryChange(at path: String) {
        // Enumerate directory contents to find changed files
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for case let fileURL as URL in enumerator {
            guard shouldMonitorFile(fileURL) else { continue }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = resourceValues.contentModificationDate {
                    // Check if file was modified recently (within last second)
                    if abs(modDate.timeIntervalSinceNow) < 1.0 {
                        let event = FileChangeEvent(
                            path: fileURL.path,
                            type: .modified,
                            timestamp: modDate
                        )
                        changeHandler?(event)
                    }
                }
            } catch {
                // Log error but continue monitoring
                print("Error reading file modification date: \(error)")
            }
        }
    }
    
    /// Determines if a file should be monitored based on configuration
    private func shouldMonitorFile(_ url: URL) -> Bool {
        let path = url.path
        let filename = url.lastPathComponent
        
        // Check if file has monitored extension
        let hasValidExtension = includeExtensions.isEmpty || includeExtensions.contains { ext in
            path.hasSuffix(ext)
        }
        
        // Check if file matches exclude patterns
        let isExcluded = excludePatterns.contains { pattern in
            filename.contains(pattern.replacingOccurrences(of: "*", with: ""))
        }
        
        return hasValidExtension && !isExcluded
    }
}

// MARK: - Supporting Types

/// Represents a file system change event
internal struct FileChangeEvent {
    internal let path: String
    internal let type: FileChangeType
    internal let timestamp: Date
    
    internal init(path: String, type: FileChangeType, timestamp: Date) {
        self.path = path
        self.type = type
        self.timestamp = timestamp
    }
}

/// Types of file system changes
internal enum FileChangeType {
    case created
    case modified
    case deleted
    case renamed
    case moved
}

/// Errors that can occur during file monitoring
internal enum FileMonitorError: LocalizedError {
    case invalidPath(String)
    case cannotOpenFile(String)
    case monitoringFailed(String)
    
    internal var errorDescription: String? {
        switch self {
        case .invalidPath(let details):
            return "Invalid path: \(details)"
        case .cannotOpenFile(let details):
            return "Cannot open file: \(details)"
        case .monitoringFailed(let details):
            return "Monitoring failed: \(details)"
        }
    }
}

// MARK: - Debounced File Monitor

/// File monitor with built-in debouncing for rapid changes
internal class DebouncedFileMonitor {
    private let monitor = FileSystemMonitor()
    private var debounceTimers: [String: Timer] = [:]
    private let debounceInterval: TimeInterval
    
    internal init(debounceInterval: TimeInterval = 0.3) {
        self.debounceInterval = debounceInterval
    }
    
    internal func configure(includeExtensions: [String], excludePatterns: [String]) {
        monitor.configure(includeExtensions: includeExtensions, excludePatterns: excludePatterns)
    }
    
    internal func startMonitoring(directory: URL, onChange: @escaping (FileChangeEvent) -> Void) throws {
        try monitor.startMonitoring(directory: directory) { [weak self] event in
            self?.debounceEvent(event, onChange: onChange)
        }
    }
    
    internal func stopMonitoring() {
        monitor.stopMonitoring()
        
        for timer in debounceTimers.values {
            timer.invalidate()
        }
        debounceTimers.removeAll()
    }
    
    private func debounceEvent(_ event: FileChangeEvent, onChange: @escaping (FileChangeEvent) -> Void) {
        // Cancel existing timer for this file
        debounceTimers[event.path]?.invalidate()
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
            onChange(event)
            self.debounceTimers.removeValue(forKey: event.path)
        }
        
        debounceTimers[event.path] = timer
    }
}