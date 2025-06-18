import Foundation
import Logging

public struct SwiftUIHotReloadEngine {
    private let logger = Logger(label: "axiom.swiftui.hotreload")
    
    public init() {
        logger.info("SwiftUI Hot Reload Engine initialized")
    }
    
    public func processFileChange(_ payload: FileChangedPayload) async throws {
        logger.info("Processing SwiftUI file change: \(payload.fileName)")
    }
}

// Re-export from HotReloadProtocol for convenience
@_exported import HotReloadProtocol