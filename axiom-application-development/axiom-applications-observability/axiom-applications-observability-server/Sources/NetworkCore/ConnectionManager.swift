import Foundation
import Logging
import HotReloadProtocol

public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager, didUpdateConnectionStatus status: ConnectionStatus)
    func connectionManager(_ manager: ConnectionManager, didDetectUnhealthyClient clientId: String)
    func connectionManager(_ manager: ConnectionManager, didCompleteHealthCheck healthy: Int, unhealthy: Int)
}

public final class ConnectionManager {
    
    public weak var delegate: ConnectionManagerDelegate?
    
    private let clientManager: ClientManager
    private let messageBroadcaster: MessageBroadcaster
    private let logger: Logger
    private let configuration: ConnectionConfiguration
    
    private var healthCheckTimer: Timer?
    private var connectionMetrics = ConnectionMetrics()
    private var isHealthCheckRunning = false
    
    public var currentStatus: ConnectionStatus = .disconnected
    
    public init(
        clientManager: ClientManager,
        messageBroadcaster: MessageBroadcaster,
        configuration: ConnectionConfiguration = ConnectionConfiguration(),
        logger: Logger = Logger(label: "axiom.hotreload.connection")
    ) {
        self.clientManager = clientManager
        self.messageBroadcaster = messageBroadcaster
        self.configuration = configuration
        self.logger = logger
    }
    
    deinit {
        stopHealthCheck()
    }
    
    public func startHealthCheck() {
        guard !isHealthCheckRunning else { return }
        
        logger.info("Starting connection health check (interval: \(configuration.healthCheckInterval)s)")
        
        isHealthCheckRunning = true
        updateConnectionStatus(.connected)
        
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: configuration.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performHealthCheck()
            }
        }
    }
    
    public func stopHealthCheck() {
        guard isHealthCheckRunning else { return }
        
        logger.info("Stopping connection health check")
        
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        isHealthCheckRunning = false
        updateConnectionStatus(.disconnected)
    }
    
    public func getConnectionMetrics() -> ConnectionMetrics {
        return connectionMetrics
    }
    
    public func getHealthReport() async -> HealthReport {
        let clients = await clientManager.getConnectedClients()
        let totalClients = clients.count
        let iosClients = clients.filter { $0.platform == .ios }.count
        let androidClients = clients.filter { $0.platform == .android }.count
        
        var healthyClients = 0
        var unhealthyClients = 0
        var averageLatency: TimeInterval = 0
        
        for client in clients {
            if client.isActive && client.timeSinceLastHeartbeat() < configuration.heartbeatTimeout {
                healthyClients += 1
                averageLatency += client.timeSinceLastHeartbeat()
            } else {
                unhealthyClients += 1
            }
        }
        
        if healthyClients > 0 {
            averageLatency /= Double(healthyClients)
        }
        
        return HealthReport(
            totalClients: totalClients,
            healthyClients: healthyClients,
            unhealthyClients: unhealthyClients,
            iosClients: iosClients,
            androidClients: androidClients,
            averageLatency: averageLatency,
            uptime: Date().timeIntervalSince(connectionMetrics.startTime),
            lastHealthCheck: Date()
        )
    }
    
    private func performHealthCheck() async {
        logger.debug("Performing connection health check")
        
        let clients = await clientManager.getConnectedClients()
        var healthyCount = 0
        var unhealthyCount = 0
        
        await clientManager.performHeartbeatCheck(timeout: configuration.heartbeatTimeout)
        
        for client in clients {
            if client.isActive && client.timeSinceLastHeartbeat() < configuration.heartbeatTimeout {
                healthyCount += 1
            } else {
                unhealthyCount += 1
                logger.warning("Unhealthy client detected: \(client.id)")
                delegate?.connectionManager(self, didDetectUnhealthyClient: client.id)
            }
        }
        
        connectionMetrics.lastHealthCheck = Date()
        connectionMetrics.totalHealthChecks += 1
        connectionMetrics.lastHealthyCount = healthyCount
        connectionMetrics.lastUnhealthyCount = unhealthyCount
        
        logger.debug("Health check completed - Healthy: \(healthyCount), Unhealthy: \(unhealthyCount)")
        delegate?.connectionManager(self, didCompleteHealthCheck: healthyCount, unhealthy: unhealthyCount)
        
        // Update connection status based on client health
        let newStatus = determineConnectionStatus(healthy: healthyCount, total: clients.count)
        if newStatus != currentStatus {
            updateConnectionStatus(newStatus)
        }
    }
    
    private func determineConnectionStatus(healthy: Int, total: Int) -> ConnectionStatus {
        if total == 0 {
            return .disconnected
        }
        
        let healthRatio = Double(healthy) / Double(total)
        
        if healthRatio >= 0.9 {
            return .connected
        } else if healthRatio >= 0.5 {
            return .reconnecting
        } else {
            return .error
        }
    }
    
    private func updateConnectionStatus(_ status: ConnectionStatus) {
        guard status != currentStatus else { return }
        
        logger.info("Connection status changed: \(currentStatus.rawValue) -> \(status.rawValue)")
        currentStatus = status
        connectionMetrics.lastStatusChange = Date()
        
        delegate?.connectionManager(self, didUpdateConnectionStatus: status)
        
        // Broadcast status update to all clients
        Task {
            await broadcastConnectionStatus(status)
        }
    }
    
    private func broadcastConnectionStatus(_ status: ConnectionStatus) async {
        let clientCount = await clientManager.getClientCount()
        let serverLoad = calculateServerLoad()
        
        let payload = ConnectionStatusPayload(
            status: status,
            clientCount: clientCount,
            serverLoad: serverLoad
        )
        
        let message = BaseMessage(
            type: .connectionStatus,
            payload: .connectionStatus(payload)
        )
        
        await messageBroadcaster.broadcast(message, priority: .normal)
    }
    
    private func calculateServerLoad() -> Double {
        // Simple load calculation based on client count and health check frequency
        let clientCount = Double(connectionMetrics.lastHealthyCount + connectionMetrics.lastUnhealthyCount)
        let maxClients = Double(configuration.maxClients)
        return min(clientCount / maxClients, 1.0)
    }
    
    public func forceReconnectClient(_ clientId: String, reason: String = "Manual reconnect") async {
        guard let client = await clientManager.getClient(id: clientId) else {
            logger.warning("Cannot reconnect client \(clientId) - not found")
            return
        }
        
        logger.info("Force reconnecting client \(clientId) - \(reason)")
        await client.disconnect(reason: reason)
        await clientManager.removeClient(id: clientId)
    }
    
    public func forceReconnectAllClients(reason: String = "Server maintenance") async {
        logger.info("Force reconnecting all clients - \(reason)")
        await clientManager.disconnectAllClients()
        updateConnectionStatus(.disconnected)
    }
}

public struct ConnectionConfiguration {
    public let healthCheckInterval: TimeInterval
    public let heartbeatTimeout: TimeInterval
    public let maxClients: Int
    public let reconnectDelay: TimeInterval
    public let maxReconnectAttempts: Int
    
    public init(
        healthCheckInterval: TimeInterval = 30.0,
        heartbeatTimeout: TimeInterval = 60.0,
        maxClients: Int = 100,
        reconnectDelay: TimeInterval = 5.0,
        maxReconnectAttempts: Int = 3
    ) {
        self.healthCheckInterval = healthCheckInterval
        self.heartbeatTimeout = heartbeatTimeout
        self.maxClients = maxClients
        self.reconnectDelay = reconnectDelay
        self.maxReconnectAttempts = maxReconnectAttempts
    }
}

public struct ConnectionMetrics {
    public var startTime: Date = Date()
    public var lastHealthCheck: Date = Date()
    public var lastStatusChange: Date = Date()
    public var totalHealthChecks: Int = 0
    public var lastHealthyCount: Int = 0
    public var lastUnhealthyCount: Int = 0
}

public struct HealthReport {
    public let totalClients: Int
    public let healthyClients: Int
    public let unhealthyClients: Int
    public let iosClients: Int
    public let androidClients: Int
    public let averageLatency: TimeInterval
    public let uptime: TimeInterval
    public let lastHealthCheck: Date
    
    public var healthPercentage: Double {
        guard totalClients > 0 else { return 0.0 }
        return Double(healthyClients) / Double(totalClients) * 100.0
    }
    
    public var isHealthy: Bool {
        return healthPercentage >= 80.0
    }
}