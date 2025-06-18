import Foundation
import Logging
import HotReloadProtocol
import NetworkCore
import SwiftUIHotReload
import ComposeHotReload

public protocol HotReloadServerDelegate: AnyObject {
    func server(_ server: HotReloadServer, didStartOnPort port: Int)
    func server(_ server: HotReloadServer, didStop error: Error?)
    func server(_ server: HotReloadServer, didConnectClient client: ClientSession)
    func server(_ server: HotReloadServer, didDisconnectClient client: ClientSession, reason: String?)
    func server(_ server: HotReloadServer, didReceiveFileChange filePath: String, platform: Platform)
    func server(_ server: HotReloadServer, didEncounterError error: Error)
}

public final class HotReloadServer {
    
    public weak var delegate: HotReloadServerDelegate?
    
    private let configuration: ServerConfiguration
    private let logger: Logger
    
    private let webSocketServer: WebSocketServer
    private let clientManager = ClientManager()
    private let messageBroadcaster: MessageBroadcaster
    private let connectionManager: ConnectionManager
    
    private let dualDirectoryWatcher: DualDirectoryWatcher?
    private let swiftUIParser: SwiftUIHotReloadParser?
    
    private var isRunning = false
    
    public init(
        configuration: ServerConfiguration,
        logger: Logger = Logger(label: "axiom.hotreload.server")
    ) {
        self.configuration = configuration
        self.logger = logger
        
        // Convert to NetworkCore.ServerConfiguration
        let networkConfig = NetworkCore.ServerConfiguration(
            host: configuration.host,
            port: configuration.port,
            maxClients: configuration.maxClients,
            heartbeatInterval: configuration.heartbeatInterval,
            maxMessageSize: configuration.maxMessageSize,
            enableCompression: configuration.enableCompression
        )
        
        self.webSocketServer = WebSocketServer(configuration: networkConfig, logger: logger)
        self.messageBroadcaster = MessageBroadcaster(clientManager: clientManager, logger: logger)
        self.connectionManager = ConnectionManager(
            clientManager: clientManager,
            messageBroadcaster: messageBroadcaster,
            logger: logger
        )
        
        // Initialize dual directory watcher if directories are provided
        if configuration.swiftUIDirectory != nil || configuration.composeDirectory != nil {
            self.dualDirectoryWatcher = DualDirectoryWatcher(
                swiftUIDirectory: configuration.swiftUIDirectory,
                composeDirectory: configuration.composeDirectory,
                logger: logger
            )
            
            // Initialize SwiftUI parser if SwiftUI directory is provided
            if configuration.swiftUIDirectory != nil {
                self.swiftUIParser = SwiftUIHotReloadParser(
                    configuration: SwiftUIParseConfiguration.forHotReload(),
                    logger: logger
                )
            } else {
                self.swiftUIParser = nil
            }
        } else {
            self.dualDirectoryWatcher = nil
            self.swiftUIParser = nil
        }
        
        setupDelegates()
    }
    
    public func start() async throws {
        guard !isRunning else {
            throw HotReloadServerError.alreadyRunning
        }
        
        logger.info("Starting Axiom Hot Reload Server")
        
        do {
            // Start WebSocket server
            try await webSocketServer.start()
            
            // Start file watchers
            try await startFileWatchers()
            
            // Start connection health monitoring
            connectionManager.startHealthCheck()
            
            isRunning = true
            
            logger.info("Axiom Hot Reload Server started successfully on port \(configuration.port)")
            delegate?.server(self, didStartOnPort: configuration.port)
            
        } catch {
            logger.error("Failed to start server: \(error)")
            delegate?.server(self, didStop: error)
            throw error
        }
    }
    
    public func stop() async throws {
        guard isRunning else { return }
        
        logger.info("Stopping Axiom Hot Reload Server")
        
        // Stop connection monitoring
        connectionManager.stopHealthCheck()
        
        // Stop file watchers
        await stopFileWatchers()
        
        // Stop WebSocket server
        try await webSocketServer.stop()
        
        isRunning = false
        
        logger.info("Axiom Hot Reload Server stopped")
        delegate?.server(self, didStop: nil)
    }
    
    public func getServerStatus() async -> ServerStatus {
        let clients = await clientManager.getConnectedClients()
        let healthReport = await connectionManager.getHealthReport()
        
        return ServerStatus(
            isRunning: isRunning,
            port: configuration.port,
            clientCount: clients.count,
            iosClientCount: clients.filter { $0.platform == .ios }.count,
            androidClientCount: clients.filter { $0.platform == .android }.count,
            healthReport: healthReport,
            swiftUIWatcherActive: dualDirectoryWatcher != nil && configuration.swiftUIDirectory != nil,
            composeWatcherActive: dualDirectoryWatcher != nil && configuration.composeDirectory != nil
        )
    }
    
    public func broadcastMessage(_ message: BaseMessage, to platform: Platform? = nil) async {
        await messageBroadcaster.broadcast(message, to: platform.map { .platform($0) } ?? .all)
    }
    
    public func sendMessage(_ message: BaseMessage, to clientId: String) async throws {
        try await messageBroadcaster.send(message, to: clientId)
    }
    
    public func forceReconnectClient(_ clientId: String) async {
        await connectionManager.forceReconnectClient(clientId)
    }
    
    public func forceReconnectAllClients() async {
        await connectionManager.forceReconnectAllClients()
    }
    
    private func setupDelegates() {
        webSocketServer.delegate = self
        connectionManager.delegate = self
        messageBroadcaster.delegate = self
        
        dualDirectoryWatcher?.delegate = self
        swiftUIParser?.delegate = self
    }
    
    private func startFileWatchers() async throws {
        if let dualDirectoryWatcher = dualDirectoryWatcher {
            try await dualDirectoryWatcher.startWatching()
            logger.info("Dual directory watcher started - SwiftUI: \(configuration.swiftUIDirectory ?? "none"), Compose: \(configuration.composeDirectory ?? "none")")
        }
    }
    
    private func stopFileWatchers() async {
        if let dualDirectoryWatcher = dualDirectoryWatcher {
            await dualDirectoryWatcher.stopWatching()
            logger.info("Dual directory watcher stopped")
        }
    }
}

// MARK: - WebSocketServerDelegate

extension HotReloadServer: WebSocketServerDelegate {
    public func server(_ server: WebSocketServer, didConnect client: ClientSession) {
        logger.info("Client connected: \(client.id) (platform: \(client.platform?.rawValue ?? "unknown"))")
        delegate?.server(self, didConnectClient: client)
    }
    
    public func server(_ server: WebSocketServer, didDisconnect client: ClientSession, reason: String?) {
        logger.info("Client disconnected: \(client.id)\(reason.map { " - \($0)" } ?? "")")
        delegate?.server(self, didDisconnectClient: client, reason: reason)
    }
    
    public func server(_ server: WebSocketServer, didReceiveMessage message: BaseMessage, from client: ClientSession) {
        logger.debug("Received message from client \(client.id): \(message.type)")
        
        Task {
            await handleClientMessage(message, from: client)
        }
    }
    
    public func server(_ server: WebSocketServer, didEncounterError error: Error, for client: ClientSession?) {
        logger.error("WebSocket server error: \(error)")
        delegate?.server(self, didEncounterError: error)
    }
    
    private func handleClientMessage(_ message: BaseMessage, from client: ClientSession) async {
        switch message.type {
        case .stateSync:
            await handleStateSync(message, from: client)
        case .previewSwitch:
            await handlePreviewSwitch(message, from: client)
        case .ping:
            await handlePing(message, from: client)
        default:
            logger.debug("Unhandled message type from client \(client.id): \(message.type)")
        }
    }
    
    private func handleStateSync(_ message: BaseMessage, from client: ClientSession) async {
        guard case .stateSync(let payload) = message.payload else { return }
        
        logger.debug("Handling state sync from client \(client.id) for file: \(payload.fileName)")
        
        // Forward state sync to other clients of the same platform
        if let platform = client.platform {
            await messageBroadcaster.broadcastStateSync(
                stateData: payload.stateData,
                fileName: payload.fileName,
                operation: payload.operation,
                platform: platform
            )
        }
    }
    
    private func handlePreviewSwitch(_ message: BaseMessage, from client: ClientSession) async {
        guard case .previewSwitch(let payload) = message.payload else { return }
        
        logger.debug("Handling preview switch from client \(client.id) to file: \(payload.targetFile)")
        
        // Broadcast preview switch to other clients
        if let platform = client.platform {
            await messageBroadcaster.broadcast(message, to: .platform(platform))
        }
    }
    
    private func handlePing(_ message: BaseMessage, from client: ClientSession) async {
        // Ping/pong is handled automatically by the WebSocket infrastructure
        logger.debug("Received ping from client \(client.id)")
    }
}

// MARK: - ConnectionManagerDelegate

extension HotReloadServer: ConnectionManagerDelegate {
    public func connectionManager(_ manager: ConnectionManager, didUpdateConnectionStatus status: ConnectionStatus) {
        logger.info("Connection status updated: \(status.rawValue)")
    }
    
    public func connectionManager(_ manager: ConnectionManager, didDetectUnhealthyClient clientId: String) {
        logger.warning("Unhealthy client detected: \(clientId)")
        
        Task {
            await manager.forceReconnectClient(clientId, reason: "Health check failed")
        }
    }
    
    public func connectionManager(_ manager: ConnectionManager, didCompleteHealthCheck healthy: Int, unhealthy: Int) {
        logger.debug("Health check completed - Healthy: \(healthy), Unhealthy: \(unhealthy)")
    }
}

// MARK: - MessageBroadcasterDelegate

extension HotReloadServer: MessageBroadcasterDelegate {
    public func broadcaster(_ broadcaster: MessageBroadcaster, didFailToSend message: BaseMessage, to clientId: String, error: Error) {
        logger.warning("Failed to send message to client \(clientId): \(error)")
    }
    
    public func broadcaster(_ broadcaster: MessageBroadcaster, didBroadcast message: BaseMessage, to clientCount: Int) {
        logger.debug("Broadcasted message \(message.type) to \(clientCount) clients")
    }
}

// MARK: - DualDirectoryWatcherDelegate

extension HotReloadServer: DualDirectoryWatcherDelegate {
    public func watcher(_ watcher: DualDirectoryWatcher, didDetectChange event: PlatformFileChangeEvent) {
        logger.info("\(event.platform.rawValue.capitalized) file change detected: \(event.filePath) (\(event.changeType.rawValue))")
        
        Task {
            await handleFileChange(event)
        }
    }
    
    public func watcher(_ watcher: DualDirectoryWatcher, didEncounterError error: Error) {
        logger.error("Dual directory watcher error: \(error)")
        delegate?.server(self, didEncounterError: error)
    }
    
    private func handleFileChange(_ event: PlatformFileChangeEvent) async {
        switch event.platform {
        case .ios:
            await handleSwiftUIFileChange(event)
        case .android:
            await handleComposeFileChange(event)
        }
    }
    
    private func handleSwiftUIFileChange(_ event: PlatformFileChangeEvent) async {
        guard let swiftUIParser = swiftUIParser else {
            logger.warning("SwiftUI parser not available, falling back to raw file broadcast")
            await broadcastRawFileChange(event)
            return
        }
        
        // Parse SwiftUI file and generate hot reload message
        await swiftUIParser.parseFile(at: event.filePath)
    }
    
    private func handleComposeFileChange(_ event: PlatformFileChangeEvent) async {
        // For now, broadcast raw file content for Compose files
        // TODO: Implement Compose parser integration
        logger.info("Compose file parsing not yet implemented, broadcasting raw content")
        await broadcastRawFileChange(event)
    }
    
    private func broadcastRawFileChange(_ event: PlatformFileChangeEvent) async {
        do {
            let content = try String(contentsOfFile: event.filePath, encoding: .utf8)
            
            await messageBroadcaster.broadcastFileChange(
                filePath: event.filePath,
                fileName: event.fileName,
                content: content,
                changeType: event.changeType,
                platform: event.platform
            )
            
            delegate?.server(self, didReceiveFileChange: event.filePath, platform: event.platform)
        } catch {
            logger.error("Failed to read file \(event.filePath): \(error)")
            await messageBroadcaster.broadcastError(
                code: "FILE_READ_ERROR",
                errorMessage: "Failed to read file: \(error.localizedDescription)",
                errorType: .file,
                platform: event.platform
            )
        }
    }
}

// MARK: - SwiftUIHotReloadParserDelegate

extension HotReloadServer: SwiftUIHotReloadParserDelegate {
    public func parser(_ parser: SwiftUIHotReloadParser, didParseFile filePath: String, result: SwiftUIParseResult) {
        logger.info("SwiftUI file parsed successfully: \(filePath)")
        
        Task {
            if result.success {
                await broadcastSwiftUIParseResult(result)
            } else {
                await broadcastSwiftUIParseError(result)
            }
        }
    }
    
    public func parser(_ parser: SwiftUIHotReloadParser, didFailWithError error: Error, filePath: String) {
        logger.error("SwiftUI parser failed for file \(filePath): \(error)")
        
        Task {
            await messageBroadcaster.broadcastError(
                code: "SWIFTUI_PARSE_ERROR",
                errorMessage: "Failed to parse SwiftUI file: \(error.localizedDescription)",
                errorType: .parsing,
                platform: .ios
            )
        }
    }
    
    private func broadcastSwiftUIParseResult(_ result: SwiftUIParseResult) async {
        guard let swiftUIJSON = result.swiftUIJSON else {
            logger.warning("Parse result successful but no SwiftUI JSON generated")
            return
        }
        
        // Generate hot reload message from parse result
        do {
            let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
            let checksum = generateChecksum(for: result.content)
            
            let payload = FileChangedPayload(
                filePath: result.filePath,
                fileName: fileName,
                fileContent: try generateCompactJSON(from: swiftUIJSON),
                changeType: .modified,
                checksum: checksum
            )
            
            let message = BaseMessage(
                type: .fileChanged,
                platform: .ios,
                payload: .fileChanged(payload)
            )
            
            await messageBroadcaster.broadcast(message, to: .platform(.ios))
            delegate?.server(self, didReceiveFileChange: result.filePath, platform: .ios)
            
            logger.info("Broadcasted SwiftUI hot reload message for \(fileName) with \(swiftUIJSON.views.count) views")
            
        } catch {
            logger.error("Failed to generate hot reload message from parse result: \(error)")
            await messageBroadcaster.broadcastError(
                code: "MESSAGE_GENERATION_ERROR",
                errorMessage: "Failed to generate hot reload message: \(error.localizedDescription)",
                errorType: .server,
                platform: .ios
            )
        }
    }
    
    private func broadcastSwiftUIParseError(_ result: SwiftUIParseResult) async {
        let errorMessages = result.errors.map { $0.localizedDescription }.joined(separator: "; ")
        
        await messageBroadcaster.broadcastError(
            code: "SWIFTUI_PARSE_ERROR",
            errorMessage: "SwiftUI parsing errors: \(errorMessages)",
            errorType: .parsing,
            platform: .ios
        )
        
        logger.warning("SwiftUI parse errors for \(result.filePath): \(errorMessages)")
    }
    
    private func generateCompactJSON(from swiftUIJSON: SwiftUIJSONOutput) throws -> String {
        let layoutJSON = SwiftUILayoutJSON(
            views: swiftUIJSON.views,
            metadata: LayoutMetadata(
                fileName: "dynamic",
                checksum: UUID().uuidString
            )
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // Compact output for hot reload
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(layoutJSON)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func generateChecksum(for content: String) -> String {
        return content.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
}

public struct ServerStatus {
    public let isRunning: Bool
    public let port: Int
    public let clientCount: Int
    public let iosClientCount: Int
    public let androidClientCount: Int
    public let healthReport: HealthReport
    public let swiftUIWatcherActive: Bool
    public let composeWatcherActive: Bool
}

public enum HotReloadServerError: Error, LocalizedError {
    case alreadyRunning
    case notRunning
    case configurationInvalid(String)
    case startupFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "Hot reload server is already running"
        case .notRunning:
            return "Hot reload server is not running"
        case .configurationInvalid(let message):
            return "Invalid configuration: \(message)"
        case .startupFailed(let error):
            return "Failed to start server: \(error.localizedDescription)"
        }
    }
}