import Foundation
import Logging
import HotReloadProtocol
import NetworkCore

public protocol SwiftUIFileWatcherDelegate: AnyObject {
    func fileWatcher(_ watcher: SwiftUIFileWatcher, didDetectChange filePath: String, changeType: ChangeType)
    func fileWatcher(_ watcher: SwiftUIFileWatcher, didFailWithError error: Error)
}

public final class SwiftUIFileWatcher {
    
    public weak var delegate: SwiftUIFileWatcherDelegate?
    
    private let directoryPath: String
    private let logger: Logger
    private var isWatchingFlag = false
    private var fileSystemWatcher: FileSystemWatcher?
    
    public var isWatching: Bool {
        return isWatchingFlag
    }
    
    public init(directoryPath: String, logger: Logger = Logger(label: "axiom.hotreload.swiftui.watcher")) {
        self.directoryPath = directoryPath
        self.logger = logger
    }
    
    public func startWatching() async throws {
        guard !isWatchingFlag else {
            throw SwiftUIFileWatcherError.alreadyWatching
        }
        
        logger.info("Starting SwiftUI file watcher for directory: \(directoryPath)")
        
        do {
            fileSystemWatcher = try FileSystemWatcher(
                directoryPath: directoryPath,
                fileExtensions: [".swift"],
                delegate: self,
                logger: logger
            )
            
            try await fileSystemWatcher?.startWatching()
            isWatchingFlag = true
            
            logger.info("SwiftUI file watcher started successfully")
        } catch {
            logger.error("Failed to start SwiftUI file watcher: \(error)")
            throw SwiftUIFileWatcherError.watchingFailed(error)
        }
    }
    
    public func stopWatching() async {
        guard isWatchingFlag else { return }
        
        logger.info("Stopping SwiftUI file watcher")
        
        await fileSystemWatcher?.stopWatching()
        fileSystemWatcher = nil
        isWatchingFlag = false
        
        logger.info("SwiftUI file watcher stopped")
    }
    
    public func getCurrentWatchedFiles() -> [String] {
        return fileSystemWatcher?.getCurrentWatchedFiles() ?? []
    }
}

extension SwiftUIFileWatcher: FileSystemWatcherDelegate {
    public func fileSystemWatcher(_ watcher: FileSystemWatcher, didDetectChange filePath: String, changeType: ChangeType) {
        // Filter for SwiftUI files
        guard filePath.hasSuffix(".swift") else { return }
        
        logger.debug("SwiftUI file change detected: \(filePath) (\(changeType.rawValue))")
        delegate?.fileWatcher(self, didDetectChange: filePath, changeType: changeType)
    }
    
    public func fileSystemWatcher(_ watcher: FileSystemWatcher, didFailWithError error: Error) {
        logger.error("SwiftUI file watcher error: \(error)")
        delegate?.fileWatcher(self, didFailWithError: error)
    }
}

public enum SwiftUIFileWatcherError: Error, LocalizedError {
    case alreadyWatching
    case notWatching
    case watchingFailed(Error)
    case invalidDirectory(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyWatching:
            return "SwiftUI file watcher is already watching"
        case .notWatching:
            return "SwiftUI file watcher is not watching"
        case .watchingFailed(let error):
            return "Failed to start watching: \(error.localizedDescription)"
        case .invalidDirectory(let path):
            return "Invalid directory path: \(path)"
        }
    }
}