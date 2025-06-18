import Foundation
import Logging
import HotReloadProtocol

public protocol FileSystemWatcherDelegate: AnyObject {
    func fileSystemWatcher(_ watcher: FileSystemWatcher, didDetectChange filePath: String, changeType: ChangeType)
    func fileSystemWatcher(_ watcher: FileSystemWatcher, didFailWithError error: Error)
}

public final class FileSystemWatcher {
    
    public weak var delegate: FileSystemWatcherDelegate?
    
    private let directoryPath: String
    private let fileExtensions: [String]
    private let logger: Logger
    
    private var fileDescriptor: Int32 = -1
    private var watchingTask: Task<Void, Never>?
    private var isWatchingFlag = false
    
    private let debouncer = FileChangeDebouncer()
    
    public init(
        directoryPath: String,
        fileExtensions: [String] = [],
        delegate: FileSystemWatcherDelegate,
        logger: Logger = Logger(label: "axiom.hotreload.filesystem")
    ) throws {
        self.directoryPath = directoryPath
        self.fileExtensions = fileExtensions
        self.delegate = delegate
        self.logger = logger
        
        // Validate directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw FileSystemWatcherError.invalidDirectory(directoryPath)
        }
    }
    
    deinit {
        if isWatchingFlag {
            Task {
                await stopWatching()
            }
        }
    }
    
    public func startWatching() async throws {
        guard !isWatchingFlag else {
            throw FileSystemWatcherError.alreadyWatching
        }
        
        logger.info("Starting file system watcher for: \(directoryPath)")
        
        // Open directory for monitoring
        fileDescriptor = open(directoryPath, O_EVTONLY)
        guard fileDescriptor != -1 else {
            throw FileSystemWatcherError.failedToOpenDirectory(directoryPath)
        }
        
        isWatchingFlag = true
        
        // Start monitoring in background task
        watchingTask = Task { [weak self] in
            await self?.monitorFileChanges()
        }
        
        logger.info("File system watcher started successfully")
    }
    
    public func stopWatching() async {
        guard isWatchingFlag else { return }
        
        logger.info("Stopping file system watcher")
        
        isWatchingFlag = false
        
        // Cancel monitoring task
        watchingTask?.cancel()
        watchingTask = nil
        
        // Close file descriptor
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        
        logger.info("File system watcher stopped")
    }
    
    public func getCurrentWatchedFiles() -> [String] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            return contents.compactMap { fileName in
                let fullPath = (directoryPath as NSString).appendingPathComponent(fileName)
                
                // Check if file matches our extensions
                if fileExtensions.isEmpty {
                    return fullPath
                } else {
                    for ext in fileExtensions {
                        if fileName.hasSuffix(ext) {
                            return fullPath
                        }
                    }
                    return nil
                }
            }
        } catch {
            logger.error("Failed to get directory contents: \(error)")
            return []
        }
    }
    
    private func monitorFileChanges() async {
        logger.debug("Starting file change monitoring loop")
        
        var lastDirectoryModification = getDirectoryModificationTime()
        
        while isWatchingFlag && !Task.isCancelled {
            do {
                // Check for directory changes
                let currentModificationTime = getDirectoryModificationTime()
                
                if currentModificationTime != lastDirectoryModification {
                    logger.debug("Directory modification detected")
                    await scanForChanges()
                    lastDirectoryModification = currentModificationTime
                }
                
                // Sleep for a short interval to avoid excessive CPU usage
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
            } catch {
                if !Task.isCancelled {
                    logger.error("Error in file monitoring loop: \(error)")
                    delegate?.fileSystemWatcher(self, didFailWithError: error)
                }
                break
            }
        }
        
        logger.debug("File change monitoring loop ended")
    }
    
    private func getDirectoryModificationTime() -> TimeInterval {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: directoryPath)
            return (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        } catch {
            logger.debug("Failed to get directory modification time: \(error)")
            return 0
        }
    }
    
    private func scanForChanges() async {
        do {
            let currentFiles = Set(getCurrentWatchedFiles())
            
            // For now, treat any change as a modification
            // In a more sophisticated implementation, we would track
            // file timestamps and detect creates/deletes/modifications
            for filePath in currentFiles {
                await debouncer.debounce(filePath: filePath) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.fileSystemWatcher(self, didDetectChange: filePath, changeType: .modified)
                }
            }
        }
    }
}

// Simple debouncer to avoid excessive file change notifications
private actor FileChangeDebouncer {
    private var pendingFiles: [String: Task<Void, Never>] = [:]
    private let debounceDelay: TimeInterval = 0.5
    
    func debounce(filePath: String, action: @escaping () -> Void) {
        // Cancel existing task for this file
        pendingFiles[filePath]?.cancel()
        
        // Create new debounced task
        pendingFiles[filePath] = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
            
            if !Task.isCancelled {
                action()
            }
            
            pendingFiles[filePath] = nil
        }
    }
}

public enum FileSystemWatcherError: Error, LocalizedError {
    case invalidDirectory(String)
    case alreadyWatching
    case notWatching
    case failedToOpenDirectory(String)
    case monitoringFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidDirectory(let path):
            return "Invalid directory: \(path)"
        case .alreadyWatching:
            return "File system watcher is already watching"
        case .notWatching:
            return "File system watcher is not watching"
        case .failedToOpenDirectory(let path):
            return "Failed to open directory for monitoring: \(path)"
        case .monitoringFailed(let error):
            return "File monitoring failed: \(error.localizedDescription)"
        }
    }
}