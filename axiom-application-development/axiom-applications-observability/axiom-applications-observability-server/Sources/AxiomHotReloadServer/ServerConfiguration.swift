import Foundation
import HotReloadProtocol

public struct ServerConfiguration {
    public let host: String
    public let port: Int
    public let maxClients: Int
    public let heartbeatInterval: TimeInterval
    public let maxMessageSize: Int
    public let enableCompression: Bool
    
    // Directory watching configuration
    public let swiftUIDirectory: String?
    public let composeDirectory: String?
    public let watchSubdirectories: Bool
    public let ignoredPatterns: [String]
    
    // Performance configuration
    public let maxConcurrentConnections: Int
    public let connectionTimeout: TimeInterval
    public let messageQueueSize: Int
    
    // Feature flags
    public let enableStatePreservation: Bool
    public let enableCrossPlattformSync: Bool
    public let enableFileChangeDebouncing: Bool
    public let debounceDelay: TimeInterval
    
    // Security configuration
    public let allowedOrigins: [String]
    public let enableClientAuthentication: Bool
    public let maxFailedAttempts: Int
    
    public init(
        host: String = "localhost",
        port: Int = 8080,
        maxClients: Int = 100,
        heartbeatInterval: TimeInterval = 30.0,
        maxMessageSize: Int = 1024 * 1024, // 1MB
        enableCompression: Bool = true,
        swiftUIDirectory: String? = nil,
        composeDirectory: String? = nil,
        watchSubdirectories: Bool = true,
        ignoredPatterns: [String] = [".git", ".build", "node_modules", "*.tmp", "*.log"],
        maxConcurrentConnections: Int = 50,
        connectionTimeout: TimeInterval = 30.0,
        messageQueueSize: Int = 1000,
        enableStatePreservation: Bool = true,
        enableCrossPlattformSync: Bool = false,
        enableFileChangeDebouncing: Bool = true,
        debounceDelay: TimeInterval = 0.5,
        allowedOrigins: [String] = ["*"],
        enableClientAuthentication: Bool = false,
        maxFailedAttempts: Int = 3
    ) {
        self.host = host
        self.port = port
        self.maxClients = maxClients
        self.heartbeatInterval = heartbeatInterval
        self.maxMessageSize = maxMessageSize
        self.enableCompression = enableCompression
        self.swiftUIDirectory = swiftUIDirectory
        self.composeDirectory = composeDirectory
        self.watchSubdirectories = watchSubdirectories
        self.ignoredPatterns = ignoredPatterns
        self.maxConcurrentConnections = maxConcurrentConnections
        self.connectionTimeout = connectionTimeout
        self.messageQueueSize = messageQueueSize
        self.enableStatePreservation = enableStatePreservation
        self.enableCrossPlattformSync = enableCrossPlattformSync
        self.enableFileChangeDebouncing = enableFileChangeDebouncing
        self.debounceDelay = debounceDelay
        self.allowedOrigins = allowedOrigins
        self.enableClientAuthentication = enableClientAuthentication
        self.maxFailedAttempts = maxFailedAttempts
    }
    
    public func validate() throws {
        guard port > 0 && port <= 65535 else {
            throw ConfigurationError.invalidPort(port)
        }
        
        guard maxClients > 0 else {
            throw ConfigurationError.invalidMaxClients(maxClients)
        }
        
        guard heartbeatInterval > 0 else {
            throw ConfigurationError.invalidHeartbeatInterval(heartbeatInterval)
        }
        
        guard maxMessageSize > 0 else {
            throw ConfigurationError.invalidMaxMessageSize(maxMessageSize)
        }
        
        guard maxConcurrentConnections > 0 else {
            throw ConfigurationError.invalidMaxConcurrentConnections(maxConcurrentConnections)
        }
        
        guard connectionTimeout > 0 else {
            throw ConfigurationError.invalidConnectionTimeout(connectionTimeout)
        }
        
        guard messageQueueSize > 0 else {
            throw ConfigurationError.invalidMessageQueueSize(messageQueueSize)
        }
        
        if let swiftUIDirectory = swiftUIDirectory {
            guard FileManager.default.fileExists(atPath: swiftUIDirectory) else {
                throw ConfigurationError.directoryNotFound(swiftUIDirectory)
            }
        }
        
        if let composeDirectory = composeDirectory {
            guard FileManager.default.fileExists(atPath: composeDirectory) else {
                throw ConfigurationError.directoryNotFound(composeDirectory)
            }
        }
        
        if swiftUIDirectory == nil && composeDirectory == nil {
            throw ConfigurationError.noDirectoriesSpecified
        }
    }
    
    public static func development() -> ServerConfiguration {
        return ServerConfiguration(
            host: "localhost",
            port: 8080,
            maxClients: 10,
            heartbeatInterval: 15.0,
            enableFileChangeDebouncing: true,
            debounceDelay: 0.2,
            enableClientAuthentication: false
        )
    }
    
    public static func production() -> ServerConfiguration {
        return ServerConfiguration(
            host: "0.0.0.0",
            port: 8080,
            maxClients: 100,
            heartbeatInterval: 60.0,
            enableCompression: true,
            maxConcurrentConnections: 75,
            connectionTimeout: 60.0,
            enableStatePreservation: true,
            enableFileChangeDebouncing: true,
            debounceDelay: 1.0,
            enableClientAuthentication: true,
            maxFailedAttempts: 5
        )
    }
    
    public func withSwiftUIDirectory(_ directory: String) -> ServerConfiguration {
        return ServerConfiguration(
            host: host,
            port: port,
            maxClients: maxClients,
            heartbeatInterval: heartbeatInterval,
            maxMessageSize: maxMessageSize,
            enableCompression: enableCompression,
            swiftUIDirectory: directory,
            composeDirectory: composeDirectory,
            watchSubdirectories: watchSubdirectories,
            ignoredPatterns: ignoredPatterns,
            maxConcurrentConnections: maxConcurrentConnections,
            connectionTimeout: connectionTimeout,
            messageQueueSize: messageQueueSize,
            enableStatePreservation: enableStatePreservation,
            enableCrossPlattformSync: enableCrossPlattformSync,
            enableFileChangeDebouncing: enableFileChangeDebouncing,
            debounceDelay: debounceDelay,
            allowedOrigins: allowedOrigins,
            enableClientAuthentication: enableClientAuthentication,
            maxFailedAttempts: maxFailedAttempts
        )
    }
    
    public func withComposeDirectory(_ directory: String) -> ServerConfiguration {
        return ServerConfiguration(
            host: host,
            port: port,
            maxClients: maxClients,
            heartbeatInterval: heartbeatInterval,
            maxMessageSize: maxMessageSize,
            enableCompression: enableCompression,
            swiftUIDirectory: swiftUIDirectory,
            composeDirectory: directory,
            watchSubdirectories: watchSubdirectories,
            ignoredPatterns: ignoredPatterns,
            maxConcurrentConnections: maxConcurrentConnections,
            connectionTimeout: connectionTimeout,
            messageQueueSize: messageQueueSize,
            enableStatePreservation: enableStatePreservation,
            enableCrossPlattformSync: enableCrossPlattformSync,
            enableFileChangeDebouncing: enableFileChangeDebouncing,
            debounceDelay: debounceDelay,
            allowedOrigins: allowedOrigins,
            enableClientAuthentication: enableClientAuthentication,
            maxFailedAttempts: maxFailedAttempts
        )
    }
    
    public func withPort(_ port: Int) -> ServerConfiguration {
        return ServerConfiguration(
            host: host,
            port: port,
            maxClients: maxClients,
            heartbeatInterval: heartbeatInterval,
            maxMessageSize: maxMessageSize,
            enableCompression: enableCompression,
            swiftUIDirectory: swiftUIDirectory,
            composeDirectory: composeDirectory,
            watchSubdirectories: watchSubdirectories,
            ignoredPatterns: ignoredPatterns,
            maxConcurrentConnections: maxConcurrentConnections,
            connectionTimeout: connectionTimeout,
            messageQueueSize: messageQueueSize,
            enableStatePreservation: enableStatePreservation,
            enableCrossPlattformSync: enableCrossPlattformSync,
            enableFileChangeDebouncing: enableFileChangeDebouncing,
            debounceDelay: debounceDelay,
            allowedOrigins: allowedOrigins,
            enableClientAuthentication: enableClientAuthentication,
            maxFailedAttempts: maxFailedAttempts
        )
    }
}

public enum ConfigurationError: Error, LocalizedError {
    case invalidPort(Int)
    case invalidMaxClients(Int)
    case invalidHeartbeatInterval(TimeInterval)
    case invalidMaxMessageSize(Int)
    case invalidMaxConcurrentConnections(Int)
    case invalidConnectionTimeout(TimeInterval)
    case invalidMessageQueueSize(Int)
    case directoryNotFound(String)
    case noDirectoriesSpecified
    case invalidIgnorePattern(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPort(let port):
            return "Invalid port number: \(port). Must be between 1 and 65535"
        case .invalidMaxClients(let maxClients):
            return "Invalid max clients: \(maxClients). Must be greater than 0"
        case .invalidHeartbeatInterval(let interval):
            return "Invalid heartbeat interval: \(interval). Must be greater than 0"
        case .invalidMaxMessageSize(let size):
            return "Invalid max message size: \(size). Must be greater than 0"
        case .invalidMaxConcurrentConnections(let connections):
            return "Invalid max concurrent connections: \(connections). Must be greater than 0"
        case .invalidConnectionTimeout(let timeout):
            return "Invalid connection timeout: \(timeout). Must be greater than 0"
        case .invalidMessageQueueSize(let size):
            return "Invalid message queue size: \(size). Must be greater than 0"
        case .directoryNotFound(let directory):
            return "Directory not found: \(directory)"
        case .noDirectoriesSpecified:
            return "At least one directory (SwiftUI or Compose) must be specified"
        case .invalidIgnorePattern(let pattern):
            return "Invalid ignore pattern: \(pattern)"
        }
    }
}