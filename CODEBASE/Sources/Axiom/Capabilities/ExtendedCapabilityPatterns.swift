import Foundation
import SwiftUI
import Network
import AVFoundation
import Photos
import CoreLocation
import UserNotifications

// MARK: - Core Location Extensions

extension CLLocationCoordinate2D: @retroactive Codable, @retroactive @unchecked Sendable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Environment Awareness
// Note: CapabilityEnvironment defined in DomainCapabilityPatterns.swift

// MARK: - Resource Management  
// Note: ResourceUsage and CapabilityResource defined in DomainCapabilityPatterns.swift

// MARK: - Configuration Framework
// Note: CapabilityConfiguration defined in DomainCapabilityPatterns.swift

// MARK: - Network Configuration Example

public struct NetworkConfiguration: CapabilityConfiguration {
    public let baseURL: URL
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let enableLogging: Bool
    public let sslPinningEnabled: Bool
    
    public init(
        baseURL: URL,
        timeout: TimeInterval = 15.0,
        maxRetries: Int = 3,
        enableLogging: Bool = false,
        sslPinningEnabled: Bool = true
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.enableLogging = enableLogging
        self.sslPinningEnabled = sslPinningEnabled
    }
    
    public var isValid: Bool {
        return timeout > 0 && maxRetries >= 0
    }
    
    public func merged(with other: NetworkConfiguration) -> NetworkConfiguration {
        return NetworkConfiguration(
            baseURL: other.baseURL, // Use other's URL
            timeout: other.timeout, // Use other's timeout
            maxRetries: other.maxRetries, // Use other's retries
            enableLogging: other.enableLogging, // Use other's logging
            sslPinningEnabled: other.sslPinningEnabled // Use other's SSL setting
        )
    }
    
    public static let `default` = NetworkConfiguration(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 15.0,
        maxRetries: 3,
        enableLogging: false,
        sslPinningEnabled: true
    )
    
    public func adjusted(for environment: CapabilityEnvironment) -> NetworkConfiguration {
        if environment.isDebug {
            return NetworkConfiguration(
                baseURL: baseURL,
                timeout: timeout * 2, // More lenient in dev
                maxRetries: maxRetries,
                enableLogging: true,
                sslPinningEnabled: false
            )
        } else {
            return NetworkConfiguration(
                baseURL: baseURL,
                timeout: timeout,
                maxRetries: maxRetries,
                enableLogging: false,
                sslPinningEnabled: true
            )
        }
    }
}

// MARK: - Network Resource Example

public actor NetworkResource: CapabilityResource {
    private var activeConnections: Set<String> = []
    private let maxConnections: Int
    private var _isAvailable: Bool = true
    
    public init(maxConnections: Int = 10) {
        self.maxConnections = maxConnections
    }
    
    /// Maximum allowed usage
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: maxConnections * 1_000_000, // 1MB per connection max
            cpu: Double(maxConnections * 5), // 5% CPU per connection max
            bandwidth: maxConnections * 10_000, // 10KB/s per connection max
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let connectionCount = activeConnections.count
            let estimatedBandwidth = connectionCount * 10_000 // 10KB/s per connection
            
            return ResourceUsage(
                memory: connectionCount * 1_000_000, // 1MB per connection
                cpu: Double(connectionCount * 5), // 5% CPU per connection
                bandwidth: estimatedBandwidth,
                storage: 0
            )
        }
    }
    
    public var isAvailable: Bool {
        get async { _isAvailable && activeConnections.count < maxConnections }
    }
    
    public func isAvailable() async -> Bool {
        return _isAvailable && activeConnections.count < maxConnections
    }
    
    public func allocate() async throws {
        guard await isAvailable else {
            throw CapabilityError.resourceAllocationFailed("Connection limit reached or resource unavailable")
        }
        
        let connectionId = UUID().uuidString
        activeConnections.insert(connectionId)
    }
    
    public func release() async {
        if let connectionId = activeConnections.first {
            activeConnections.remove(connectionId)
        }
    }
    
    public func checkAvailability() async -> Bool {
        return _isAvailable && activeConnections.count < maxConnections
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
}