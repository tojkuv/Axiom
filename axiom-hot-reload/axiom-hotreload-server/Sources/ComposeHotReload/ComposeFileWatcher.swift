import Foundation
import Logging
import HotReloadProtocol
import NetworkCore

public protocol ComposeFileWatcherDelegate: AnyObject {
    func fileWatcher(_ watcher: ComposeFileWatcher, didDetectChange filePath: String, changeType: ChangeType)
    func fileWatcher(_ watcher: ComposeFileWatcher, didFailWithError error: Error)
}

public final class ComposeFileWatcher {
    
    public weak var delegate: ComposeFileWatcherDelegate?
    
    private let directoryPath: String
    private let logger: Logger
    private var isWatchingFlag = false
    private var fileSystemWatcher: FileSystemWatcher?
    
    public var isWatching: Bool {
        return isWatchingFlag
    }
    
    public init(directoryPath: String, logger: Logger = Logger(label: "axiom.hotreload.compose.watcher")) {
        self.directoryPath = directoryPath
        self.logger = logger
    }
    
    public func startWatching() async throws {
        guard !isWatchingFlag else {
            throw ComposeFileWatcherError.alreadyWatching
        }
        
        logger.info("Starting Compose file watcher for directory: \(directoryPath)")
        
        do {
            fileSystemWatcher = try FileSystemWatcher(
                directoryPath: directoryPath,
                fileExtensions: [".kt", ".kts"],
                delegate: self,
                logger: logger
            )
            
            try await fileSystemWatcher?.startWatching()
            isWatchingFlag = true
            
            logger.info("Compose file watcher started successfully")
        } catch {
            logger.error("Failed to start Compose file watcher: \(error)")
            throw ComposeFileWatcherError.watchingFailed(error)
        }
    }
    
    public func stopWatching() async {
        guard isWatchingFlag else { return }
        
        logger.info("Stopping Compose file watcher")
        
        await fileSystemWatcher?.stopWatching()
        fileSystemWatcher = nil
        isWatchingFlag = false
        
        logger.info("Compose file watcher stopped")
    }
    
    public func getCurrentWatchedFiles() -> [String] {
        return fileSystemWatcher?.getCurrentWatchedFiles() ?? []
    }
}

extension ComposeFileWatcher: FileSystemWatcherDelegate {
    public func fileSystemWatcher(_ watcher: FileSystemWatcher, didDetectChange filePath: String, changeType: ChangeType) {
        // Filter for Kotlin/Compose files
        guard filePath.hasSuffix(".kt") || filePath.hasSuffix(".kts") else { return }
        
        logger.debug("Compose file change detected: \(filePath) (\(changeType.rawValue))")
        delegate?.fileWatcher(self, didDetectChange: filePath, changeType: changeType)
    }
    
    public func fileSystemWatcher(_ watcher: FileSystemWatcher, didFailWithError error: Error) {
        logger.error("Compose file watcher error: \(error)")
        delegate?.fileWatcher(self, didFailWithError: error)
    }
}

public enum ComposeFileWatcherError: Error, LocalizedError {
    case alreadyWatching
    case notWatching
    case watchingFailed(Error)
    case invalidDirectory(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyWatching:
            return "Compose file watcher is already watching"
        case .notWatching:
            return "Compose file watcher is not watching"
        case .watchingFailed(let error):
            return "Failed to start watching: \(error.localizedDescription)"
        case .invalidDirectory(let path):
            return "Invalid directory path: \(path)"
        }
    }
}