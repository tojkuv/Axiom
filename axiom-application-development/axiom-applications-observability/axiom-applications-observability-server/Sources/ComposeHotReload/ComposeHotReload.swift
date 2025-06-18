import Foundation
import Logging

public struct ComposeHotReloadEngine {
    private let logger = Logger(label: "axiom.compose.hotreload")
    
    public init() {
        logger.info("Compose Hot Reload Engine initialized")
    }
    
    public func processFileChange(_ payload: FileChangedPayload) async throws {
        logger.info("Processing Compose file change: \(payload.fileName)")
    }
}

// Re-export from HotReloadProtocol for convenience
@_exported import HotReloadProtocol