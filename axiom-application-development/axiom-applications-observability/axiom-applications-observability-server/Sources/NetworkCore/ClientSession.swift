import Foundation
import WebSocketKit
import NIO
import NIOWebSocket
import Logging
import HotReloadProtocol

public final class ClientSession {
    
    public let id: String
    public let platform: Platform?
    public let deviceInfo: DeviceInfo?
    public let capabilities: [ClientCapability]
    public let connectedAt: Date
    
    private let webSocket: WebSocketProtocol
    private let logger: Logger
    private var isConnected: Bool = true
    private var lastHeartbeat: Date = Date()
    private var heartbeatSequence: Int = 0
    
    public var isActive: Bool {
        return isConnected && !webSocket.isClosed
    }
    
    public init(
        id: String,
        webSocket: WebSocketProtocol,
        platform: Platform? = nil,
        deviceInfo: DeviceInfo? = nil,
        capabilities: [ClientCapability] = [],
        logger: Logger
    ) {
        self.id = id
        self.webSocket = webSocket
        self.platform = platform
        self.deviceInfo = deviceInfo
        self.capabilities = capabilities
        self.connectedAt = Date()
        self.logger = logger
        
        // setupWebSocketHandlers() - removed since our protocol doesn't support event handlers
    }
    
    public func send(message: BaseMessage) async throws {
        guard isActive else {
            throw ClientSessionError.disconnected
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)
            
            logger.debug("Sending message to client \(id): \(message.type)")
            try await webSocket.send(data)
        } catch {
            logger.error("Failed to send message to client \(id): \(error)")
            throw ClientSessionError.sendFailed(error)
        }
    }
    
    public func sendHeartbeat() async {
        heartbeatSequence += 1
        let heartbeat = BaseMessage(
            type: .ping,
            clientId: id,
            platform: platform,
            payload: .ping(PingPayload(sequence: heartbeatSequence))
        )
        
        do {
            try await send(message: heartbeat)
            lastHeartbeat = Date()
        } catch {
            logger.warning("Failed to send heartbeat to client \(id): \(error)")
        }
    }
    
    public func disconnect(reason: String? = nil) async {
        guard isConnected else { return }
        
        logger.info("Disconnecting client \(id)\(reason.map { " - \($0)" } ?? "")")
        isConnected = false
        
        try? await webSocket.close()
    }
    
    public func timeSinceLastHeartbeat() -> TimeInterval {
        return Date().timeIntervalSince(lastHeartbeat)
    }
    
}

extension ClientSession: Hashable {
    public static func == (lhs: ClientSession, rhs: ClientSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum ClientSessionError: Error, LocalizedError {
    case disconnected
    case sendFailed(Error)
    case invalidMessage
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .disconnected:
            return "Client session is disconnected"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .invalidMessage:
            return "Invalid message format"
        case .timeout:
            return "Client session timed out"
        }
    }
}

public actor ClientManager {
    
    private var clients: [String: ClientSession] = [:]
    private var platformClients: [Platform: Set<String>] = [
        .ios: Set<String>(),
        .android: Set<String>()
    ]
    private let logger = Logger(label: "axiom.hotreload.clientmanager")
    
    public init() {}
    
    public func addClient(_ client: ClientSession) throws {
        guard clients[client.id] == nil else {
            throw ClientManagerError.clientAlreadyExists(client.id)
        }
        
        clients[client.id] = client
        
        if let platform = client.platform {
            platformClients[platform]?.insert(client.id)
        }
        
        logger.info("Added client \(client.id) (platform: \(client.platform?.rawValue ?? "unknown"))")
    }
    
    public func removeClient(id: String) {
        guard let client = clients[id] else { return }
        
        clients.removeValue(forKey: id)
        
        if let platform = client.platform {
            platformClients[platform]?.remove(id)
        }
        
        logger.info("Removed client \(id)")
    }
    
    public func getClient(id: String) -> ClientSession? {
        return clients[id]
    }
    
    public func getConnectedClients() -> [ClientSession] {
        return Array(clients.values.filter { $0.isActive })
    }
    
    public func getClientCount() -> Int {
        return clients.count
    }
    
    public func getClientCount(for platform: Platform) -> Int {
        return platformClients[platform]?.count ?? 0
    }
    
    public func broadcast(message: BaseMessage, to platform: Platform? = nil) async {
        let targetClients: [ClientSession]
        
        if let platform = platform {
            let clientIds = platformClients[platform] ?? Set<String>()
            targetClients = clientIds.compactMap { clients[$0] }.filter { $0.isActive }
        } else {
            targetClients = Array(clients.values.filter { $0.isActive })
        }
        
        logger.debug("Broadcasting message to \(targetClients.count) clients (platform: \(platform?.rawValue ?? "all"))")
        
        await withTaskGroup(of: Void.self) { group in
            for client in targetClients {
                group.addTask {
                    do {
                        try await client.send(message: message)
                    } catch {
                        self.logger.warning("Failed to send broadcast message to client \(client.id): \(error)")
                    }
                }
            }
        }
    }
    
    public func send(message: BaseMessage, to clientId: String) async {
        guard let client = clients[clientId], client.isActive else {
            logger.warning("Attempted to send message to inactive client \(clientId)")
            return
        }
        
        do {
            try await client.send(message: message)
            logger.debug("Sent message to client \(clientId)")
        } catch {
            logger.error("Failed to send message to client \(clientId): \(error)")
        }
    }
    
    public func disconnectAllClients() async {
        logger.info("Disconnecting all clients")
        
        await withTaskGroup(of: Void.self) { group in
            for client in clients.values {
                group.addTask {
                    await client.disconnect(reason: "Server shutdown")
                }
            }
        }
        
        clients.removeAll()
        platformClients[.ios]?.removeAll()
        platformClients[.android]?.removeAll()
    }
    
    public func performHeartbeatCheck(timeout: TimeInterval = 60.0) async {
        let now = Date()
        var clientsToRemove: [String] = []
        
        for (clientId, client) in clients {
            if !client.isActive {
                clientsToRemove.append(clientId)
                continue
            }
            
            if now.timeIntervalSince(client.connectedAt) > timeout && client.timeSinceLastHeartbeat() > timeout {
                logger.warning("Client \(clientId) timed out - removing")
                await client.disconnect(reason: "Heartbeat timeout")
                clientsToRemove.append(clientId)
            } else {
                await client.sendHeartbeat()
            }
        }
        
        for clientId in clientsToRemove {
            removeClient(id: clientId)
        }
    }
}

public enum ClientManagerError: Error, LocalizedError {
    case clientAlreadyExists(String)
    case clientNotFound(String)
    case platformNotSupported(String)
    
    public var errorDescription: String? {
        switch self {
        case .clientAlreadyExists(let id):
            return "Client already exists: \(id)"
        case .clientNotFound(let id):
            return "Client not found: \(id)"
        case .platformNotSupported(let platform):
            return "Platform not supported: \(platform)"
        }
    }
}