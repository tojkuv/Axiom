import Foundation
import HotReloadProtocol

// MARK: - Public API for Axiom Hot Reload Server

/// The main entry point for integrating Axiom Hot Reload Server into Mac applications
public final class AxiomHotReload {
    
    private let server: HotReloadServer
    
    /// Initialize the hot reload server with configuration
    /// - Parameter configuration: Server configuration including directories and settings
    public init(configuration: ServerConfiguration) {
        self.server = HotReloadServer(configuration: configuration)
    }
    
    /// Convenience initializer with SwiftUI and Compose directories
    /// - Parameters:
    ///   - swiftUIDirectory: Path to SwiftUI source files
    ///   - composeDirectory: Path to Compose source files  
    ///   - port: Server port (default: 8080)
    public convenience init(
        swiftUIDirectory: String? = nil,
        composeDirectory: String? = nil,
        port: Int = 8080
    ) {
        let config = ServerConfiguration.development()
            .withSwiftUIDirectory(swiftUIDirectory ?? "")
            .withComposeDirectory(composeDirectory ?? "")
            .withPort(port)
        
        self.init(configuration: config)
    }
    
    /// Set the delegate to receive server events
    public func setDelegate(_ delegate: HotReloadServerDelegate?) {
        server.delegate = delegate
    }
    
    /// Start the hot reload server
    /// - Throws: `HotReloadServerError` if the server fails to start
    public func start() async throws {
        try await server.start()
    }
    
    /// Stop the hot reload server
    /// - Throws: `HotReloadServerError` if the server fails to stop
    public func stop() async throws {
        try await server.stop()
    }
    
    /// Get the current server status
    /// - Returns: `ServerStatus` containing current server state
    public func getStatus() async -> ServerStatus {
        return await server.getServerStatus()
    }
    
    /// Broadcast a message to all connected clients
    /// - Parameters:
    ///   - message: The message to broadcast
    ///   - platform: Optional platform filter (iOS or Android)
    public func broadcast(_ message: BaseMessage, to platform: Platform? = nil) async {
        await server.broadcastMessage(message, to: platform)
    }
    
    /// Send a message to a specific client
    /// - Parameters:
    ///   - message: The message to send
    ///   - clientId: The target client ID
    /// - Throws: `MessageBroadcasterError` if the client is not found
    public func send(_ message: BaseMessage, to clientId: String) async throws {
        try await server.sendMessage(message, to: clientId)
    }
    
    /// Force reconnect a specific client
    /// - Parameter clientId: The client ID to reconnect
    public func reconnectClient(_ clientId: String) async {
        await server.forceReconnectClient(clientId)
    }
    
    /// Force reconnect all clients
    public func reconnectAllClients() async {
        await server.forceReconnectAllClients()
    }
}

// MARK: - Convenience Extensions

public extension AxiomHotReload {
    
    /// Quick start with automatic directory detection
    /// Attempts to find SwiftUI and Compose directories automatically
    static func quickStart(port: Int = 8080) async throws -> AxiomHotReload {
        let currentDirectory = FileManager.default.currentDirectoryPath
        
        // Try to find SwiftUI directory
        let swiftUIPath = findSwiftUIDirectory(from: currentDirectory)
        
        // Try to find Compose directory  
        let composePath = findComposeDirectory(from: currentDirectory)
        
        guard swiftUIPath != nil || composePath != nil else {
            throw HotReloadServerError.configurationInvalid("No SwiftUI or Compose directories found")
        }
        
        let hotReload = AxiomHotReload(
            swiftUIDirectory: swiftUIPath,
            composeDirectory: composePath,
            port: port
        )
        
        try await hotReload.start()
        return hotReload
    }
    
    /// Create a development server with sensible defaults
    static func development(
        swiftUIDirectory: String? = nil,
        composeDirectory: String? = nil
    ) -> AxiomHotReload {
        return AxiomHotReload(
            swiftUIDirectory: swiftUIDirectory,
            composeDirectory: composeDirectory,
            port: 8080
        )
    }
    
    /// Create a production server with optimized settings
    static func production(
        swiftUIDirectory: String? = nil,
        composeDirectory: String? = nil,
        port: Int = 8080
    ) -> AxiomHotReload {
        let config = ServerConfiguration.production()
            .withSwiftUIDirectory(swiftUIDirectory ?? "")
            .withComposeDirectory(composeDirectory ?? "")
            .withPort(port)
        
        return AxiomHotReload(configuration: config)
    }
}

// MARK: - Directory Discovery

private func findSwiftUIDirectory(from basePath: String) -> String? {
    let fileManager = FileManager.default
    let searchPaths = [
        "\(basePath)/Sources",
        "\(basePath)/App", 
        "\(basePath)/iOS",
        "\(basePath)/SwiftUI",
        basePath
    ]
    
    for searchPath in searchPaths {
        if let found = findDirectoryContaining(fileExtension: ".swift", in: searchPath, fileManager: fileManager) {
            return found
        }
    }
    
    return nil
}

private func findComposeDirectory(from basePath: String) -> String? {
    let fileManager = FileManager.default
    let searchPaths = [
        "\(basePath)/app/src/main/java",
        "\(basePath)/android/src",
        "\(basePath)/src/main/kotlin",
        "\(basePath)/Android",
        "\(basePath)/Compose",
        basePath
    ]
    
    for searchPath in searchPaths {
        if let found = findDirectoryContaining(fileExtension: ".kt", in: searchPath, fileManager: fileManager) {
            return found
        }
    }
    
    return nil
}

private func findDirectoryContaining(
    fileExtension: String,
    in directory: String,
    fileManager: FileManager
) -> String? {
    guard fileManager.fileExists(atPath: directory) else { return nil }
    
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: directory)
        
        // Check if current directory contains files with the extension
        for item in contents {
            if item.hasSuffix(fileExtension) {
                return directory
            }
        }
        
        // Recursively search subdirectories
        for item in contents {
            let itemPath = "\(directory)/\(item)"
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
               isDirectory.boolValue {
                if let found = findDirectoryContaining(
                    fileExtension: fileExtension,
                    in: itemPath,
                    fileManager: fileManager
                ) {
                    return found
                }
            }
        }
    } catch {
        // Ignore errors and continue searching
    }
    
    return nil
}

// MARK: - Message Helpers

public extension AxiomHotReload {
    
    /// Send a file change notification to clients
    func notifyFileChange(
        filePath: String,
        fileName: String,
        content: String,
        changeType: ChangeType = .modified,
        platform: Platform
    ) async {
        let checksum = content.data(using: .utf8)?.base64EncodedString() ?? ""
        
        let message = BaseMessage(
            type: .fileChanged,
            platform: platform,
            payload: .fileChanged(
                FileChangedPayload(
                    filePath: filePath,
                    fileName: fileName,
                    fileContent: content,
                    changeType: changeType,
                    checksum: checksum
                )
            )
        )
        
        await broadcast(message, to: platform)
    }
    
    /// Send a state synchronization message
    func syncState(
        stateData: [String: AnyCodable],
        fileName: String,
        operation: StateOperation = .sync,
        platform: Platform
    ) async {
        let message = BaseMessage(
            type: .stateSync,
            platform: platform,
            payload: .stateSync(
                StateSyncPayload(
                    stateData: stateData,
                    fileName: fileName,
                    operation: operation
                )
            )
        )
        
        await broadcast(message, to: platform)
    }
    
    /// Send an error message to clients
    func notifyError(
        code: String,
        message: String,
        type: ErrorType = .server,
        platform: Platform? = nil,
        recoverable: Bool = true
    ) async {
        let errorMessage = BaseMessage(
            type: .error,
            platform: platform,
            payload: .error(
                ErrorPayload(
                    errorCode: code,
                    errorMessage: message,
                    errorType: type,
                    recoverable: recoverable
                )
            )
        )
        
        await broadcast(errorMessage, to: platform)
    }
}