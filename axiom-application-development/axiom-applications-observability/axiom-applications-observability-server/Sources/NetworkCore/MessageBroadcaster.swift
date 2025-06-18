import Foundation
import Logging
import HotReloadProtocol

public protocol MessageBroadcasterDelegate: AnyObject {
    func broadcaster(_ broadcaster: MessageBroadcaster, didFailToSend message: BaseMessage, to clientId: String, error: Error)
    func broadcaster(_ broadcaster: MessageBroadcaster, didBroadcast message: BaseMessage, to clientCount: Int)
}

public final class MessageBroadcaster {
    
    public weak var delegate: MessageBroadcasterDelegate?
    
    private let clientManager: ClientManager
    private let logger: Logger
    private let configuration: BroadcastConfiguration
    
    public init(
        clientManager: ClientManager,
        configuration: BroadcastConfiguration = BroadcastConfiguration(),
        logger: Logger = Logger(label: "axiom.hotreload.broadcaster")
    ) {
        self.clientManager = clientManager
        self.configuration = configuration
        self.logger = logger
    }
    
    public func broadcast(
        _ message: BaseMessage,
        to filter: BroadcastFilter = .all,
        priority: BroadcastPriority = .normal
    ) async {
        let startTime = Date()
        
        let targetClients = await getTargetClients(for: filter)
        
        guard !targetClients.isEmpty else {
            logger.debug("No clients to broadcast to for filter: \(filter)")
            return
        }
        
        logger.info("Broadcasting message \(message.type) to \(targetClients.count) clients")
        
        var successCount = 0
        var failureCount = 0
        
        if priority == .realtime {
            // Send to all clients concurrently for real-time updates
            await withTaskGroup(of: (String, Result<Void, Error>).self) { group in
                for client in targetClients {
                    group.addTask {
                        do {
                            try await client.send(message: message)
                            return (client.id, .success(()))
                        } catch {
                            return (client.id, .failure(error))
                        }
                    }
                }
                
                for await (clientId, result) in group {
                    switch result {
                    case .success:
                        successCount += 1
                    case .failure(let error):
                        failureCount += 1
                        logger.warning("Failed to send message to client \(clientId): \(error)")
                        delegate?.broadcaster(self, didFailToSend: message, to: clientId, error: error)
                    }
                }
            }
        } else {
            // Send with throttling for normal priority
            for client in targetClients {
                do {
                    try await client.send(message: message)
                    successCount += 1
                    
                    if configuration.throttleDelay > 0 {
                        try await Task.sleep(nanoseconds: UInt64(configuration.throttleDelay * 1_000_000_000))
                    }
                } catch {
                    failureCount += 1
                    logger.warning("Failed to send message to client \(client.id): \(error)")
                    delegate?.broadcaster(self, didFailToSend: message, to: client.id, error: error)
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.debug("Broadcast completed in \(String(format: "%.3f", duration))s - Success: \(successCount), Failed: \(failureCount)")
        
        delegate?.broadcaster(self, didBroadcast: message, to: successCount)
    }
    
    public func send(
        _ message: BaseMessage,
        to clientId: String,
        priority: BroadcastPriority = .normal
    ) async throws {
        guard let client = await clientManager.getClient(id: clientId) else {
            throw MessageBroadcasterError.clientNotFound(clientId)
        }
        
        guard client.isActive else {
            throw MessageBroadcasterError.clientInactive(clientId)
        }
        
        try await client.send(message: message)
        logger.debug("Sent message \(message.type) to client \(clientId)")
    }
    
    public func broadcastToiOS(_ message: BaseMessage, priority: BroadcastPriority = .normal) async {
        await broadcast(message, to: .platform(.ios), priority: priority)
    }
    
    public func broadcastToAndroid(_ message: BaseMessage, priority: BroadcastPriority = .normal) async {
        await broadcast(message, to: .platform(.android), priority: priority)
    }
    
    public func broadcastFileChange(
        filePath: String,
        fileName: String,
        content: String,
        changeType: ChangeType,
        platform: Platform
    ) async {
        let checksum = generateChecksum(for: content)
        
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
        
        await broadcast(message, to: .platform(platform), priority: .realtime)
    }
    
    public func broadcastStateSync(
        stateData: [String: AnyCodable],
        fileName: String,
        operation: StateOperation,
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
        
        await broadcast(message, to: .platform(platform), priority: .realtime)
    }
    
    public func broadcastError(
        code: String,
        errorMessage: String,
        errorType: ErrorType,
        platform: Platform? = nil,
        recoverable: Bool = true
    ) async {
        let message = BaseMessage(
            type: .error,
            platform: platform,
            payload: .error(
                ErrorPayload(
                    errorCode: code,
                    errorMessage: errorMessage,
                    errorType: errorType,
                    recoverable: recoverable
                )
            )
        )
        
        let filter: BroadcastFilter = platform.map { .platform($0) } ?? .all
        await broadcast(message, to: filter, priority: .normal)
    }
    
    private func getTargetClients(for filter: BroadcastFilter) async -> [ClientSession] {
        let allClients = await clientManager.getConnectedClients()
        
        switch filter {
        case .all:
            return allClients
        case .platform(let platform):
            return allClients.filter { $0.platform == platform }
        case .clients(let clientIds):
            return allClients.filter { clientIds.contains($0.id) }
        case .capability(let capabilityName):
            return allClients.filter { client in
                client.capabilities.contains { $0.name == capabilityName && $0.enabled }
            }
        case .deviceType(let deviceType):
            return allClients.filter { client in
                client.deviceInfo?.deviceModel.lowercased().contains(deviceType.lowercased()) == true
            }
        case .custom(let predicate):
            return allClients.filter(predicate)
        }
    }
    
    private func generateChecksum(for content: String) -> String {
        return content.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
}

public struct BroadcastConfiguration {
    public let maxConcurrentBroadcasts: Int
    public let throttleDelay: TimeInterval
    public let retryAttempts: Int
    public let retryDelay: TimeInterval
    
    public init(
        maxConcurrentBroadcasts: Int = 50,
        throttleDelay: TimeInterval = 0.01,
        retryAttempts: Int = 2,
        retryDelay: TimeInterval = 1.0
    ) {
        self.maxConcurrentBroadcasts = maxConcurrentBroadcasts
        self.throttleDelay = throttleDelay
        self.retryAttempts = retryAttempts
        self.retryDelay = retryDelay
    }
}

public enum BroadcastFilter {
    case all
    case platform(Platform)
    case clients([String])
    case capability(String)
    case deviceType(String)
    case custom((ClientSession) -> Bool)
}

public enum BroadcastPriority {
    case low
    case normal
    case high
    case realtime
}

public enum MessageBroadcasterError: Error, LocalizedError {
    case clientNotFound(String)
    case clientInactive(String)
    case broadcastFailed([String: Error])
    case invalidMessage
    
    public var errorDescription: String? {
        switch self {
        case .clientNotFound(let id):
            return "Client not found: \(id)"
        case .clientInactive(let id):
            return "Client is inactive: \(id)"
        case .broadcastFailed(let errors):
            return "Broadcast failed for \(errors.count) clients"
        case .invalidMessage:
            return "Invalid message format"
        }
    }
}