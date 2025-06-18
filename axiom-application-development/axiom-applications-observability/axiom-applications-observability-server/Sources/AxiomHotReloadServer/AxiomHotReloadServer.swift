import Foundation
import Logging

public struct AxiomHotReloadServer {
    private let logger = Logger(label: "axiom.hot-reload.server")
    
    public init() {
        logger.info("Axiom Hot Reload Server initialized")
    }
    
    public func start() async throws {
        logger.info("Starting Axiom Hot Reload Server")
    }
    
    public func stop() async {
        logger.info("Stopping Axiom Hot Reload Server")
    }
}

public struct ServerConfiguration {
    public let host: String
    public let port: Int
    public let maxClients: Int
    public let heartbeatInterval: Double
    public let swiftUIDirectory: String
    public let composeDirectory: String
    public let enableStatePreservation: Bool
    
    public init(
        host: String = "localhost",
        port: Int = 8080,
        maxClients: Int = 10,
        heartbeatInterval: Double = 30.0,
        swiftUIDirectory: String = "",
        composeDirectory: String = ""
    ) {
        self.host = host
        self.port = port
        self.maxClients = maxClients
        self.heartbeatInterval = heartbeatInterval
        self.swiftUIDirectory = swiftUIDirectory
        self.composeDirectory = composeDirectory
        self.enableStatePreservation = true
    }
    
    public static func development() -> Self {
        return Self()
    }
    
    public func withPort(_ port: Int) -> Self {
        return ServerConfiguration(
            host: self.host,
            port: port,
            maxClients: self.maxClients,
            heartbeatInterval: self.heartbeatInterval,
            swiftUIDirectory: self.swiftUIDirectory,
            composeDirectory: self.composeDirectory
        )
    }
    
    public func withSwiftUIDirectory(_ directory: String) -> Self {
        return ServerConfiguration(
            host: self.host,
            port: self.port,
            maxClients: self.maxClients,
            heartbeatInterval: self.heartbeatInterval,
            swiftUIDirectory: directory,
            composeDirectory: self.composeDirectory
        )
    }
    
    public func withComposeDirectory(_ directory: String) -> Self {
        return ServerConfiguration(
            host: self.host,
            port: self.port,
            maxClients: self.maxClients,
            heartbeatInterval: self.heartbeatInterval,
            swiftUIDirectory: self.swiftUIDirectory,
            composeDirectory: directory
        )
    }
    
    public func validate() throws {
        if port < 0 || port > 65535 {
            throw ConfigurationError.invalidPort
        }
        
        if maxClients <= 0 {
            throw ConfigurationError.invalidMaxClients
        }
    }
}

public enum ConfigurationError: Error {
    case invalidPort
    case invalidMaxClients
}