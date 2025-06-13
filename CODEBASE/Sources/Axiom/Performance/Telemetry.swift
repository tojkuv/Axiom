import Foundation
import OSLog
import os.log
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Telemetry Types

/// Represents different types of telemetry events
public enum TelemetryEventType: String, Sendable, CaseIterable {
    case error = "error"
    case performance = "performance"
    case navigation = "navigation"
    case userAction = "user_action"
    case systemMetric = "system_metric"
    case lifecycle = "lifecycle"
}

/// Core telemetry event structure
public struct TelemetryEvent: Sendable {
    public let id: UUID
    public let type: TelemetryEventType
    public let name: String
    public let data: [String: String]
    public let timestamp: Date
    
    public init(type: TelemetryEventType, name: String, data: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.data = data
        self.timestamp = Date()
    }
}

/// Enhanced telemetry data with device context
public struct TelemetryData: Sendable {
    public let event: TelemetryEvent
    public let deviceContext: DeviceContext
    
    public init(event: TelemetryEvent, deviceContext: DeviceContext) {
        self.event = event
        self.deviceContext = deviceContext
    }
}

/// Device context for telemetry enrichment
public struct DeviceContext: Sendable {
    public let platform: String
    public let deviceModel: String
    public let memoryPressure: Double
    public let thermalState: String
    public let batteryLevel: Float
    public let isLowPowerMode: Bool
    public let timestamp: Date
    
    public init(platform: String, deviceModel: String, memoryPressure: Double, 
                thermalState: String, batteryLevel: Float, isLowPowerMode: Bool) {
        self.platform = platform
        self.deviceModel = deviceModel
        self.memoryPressure = memoryPressure
        self.thermalState = thermalState
        self.batteryLevel = batteryLevel
        self.isLowPowerMode = isLowPowerMode
        self.timestamp = Date()
    }
}

/// Error telemetry data structure
public struct ErrorTelemetryData: Sendable {
    public let error: any Error
    public let context: String
    public let severity: String
    
    public init(error: any Error, context: String, severity: String = "error") {
        self.error = error
        self.context = context
        self.severity = severity
    }
}

/// Telemetry performance alert data structure
public struct TelemetryPerformanceAlert: Sendable {
    public let type: PerformanceAlertType
    public let message: String
    public let value: Double?
    public let threshold: Double?
    public let timestamp: Date
    
    public init(type: PerformanceAlertType, message: String, value: Double? = nil, threshold: Double? = nil) {
        self.type = type
        self.message = message
        self.value = value
        self.threshold = threshold
        self.timestamp = Date()
    }
}

/// Performance alert types
public enum PerformanceAlertType: String, Sendable, CaseIterable {
    case slaAdjustment = "sla_adjustment"
    case memoryPressure = "memory_pressure"
    case cpuThreshold = "cpu_threshold"
    case thermalThrottle = "thermal_throttle"
    case networkLatency = "network_latency"
}

/// Error recovery option types
public enum ErrorRecoveryOption: String, Sendable, CaseIterable {
    case retry = "retry"
    case fallback = "fallback"
    case ignore = "ignore"
    case escalate = "escalate"
    case abort = "abort"
}

/// Error recovery event data structure
public struct ErrorRecoveryEvent: Sendable {
    public let error: AxiomError
    public let option: ErrorRecoveryOption
    public let success: Bool
    public let timestamp: Date
    
    public init(error: AxiomError, option: ErrorRecoveryOption, success: Bool) {
        self.error = error
        self.option = option
        self.success = success
        self.timestamp = Date()
    }
}

// MARK: - Telemetry Destinations

/// Protocol for telemetry destinations
public protocol TelemetryDestination: Sendable {
    func send(_ data: TelemetryData) async
    func isAvailable() async -> Bool
}

/// Console telemetry destination
public struct ConsoleTelemetryDestination: TelemetryDestination {
    private let logger = os.Logger(subsystem: "com.axiom.framework", category: "telemetry")
    
    public init() {}
    
    public func send(_ data: TelemetryData) async {
        let logMessage = formatTelemetryMessage(data)
        
        switch data.event.type {
        case .error:
            logger.error("🚨 \(logMessage)")
        case .performance:
            logger.info("📊 \(logMessage)")
        case .navigation:
            logger.debug("🧭 \(logMessage)")
        case .userAction:
            logger.debug("👆 \(logMessage)")
        case .systemMetric:
            logger.info("⚙️ \(logMessage)")
        case .lifecycle:
            logger.info("🔄 \(logMessage)")
        }
    }
    
    public func isAvailable() async -> Bool {
        return true
    }
    
    private func formatTelemetryMessage(_ data: TelemetryData) -> String {
        let deviceInfo = "[\(data.deviceContext.platform)/\(data.deviceContext.deviceModel)]"
        let eventInfo = "[\(data.event.type.rawValue):\(data.event.name)]"
        let dataInfo = data.event.data.isEmpty ? "" : " \(data.event.data)"
        return "\(deviceInfo) \(eventInfo)\(dataInfo)"
    }
}

/// System log telemetry destination
public struct SystemLogTelemetryDestination: TelemetryDestination {
    private let logger = os.Logger(subsystem: "com.axiom.framework", category: "telemetry-system")
    
    public init() {}
    
    public func send(_ data: TelemetryData) async {
        let logLevel: OSLogType = switch data.event.type {
        case .error: .error
        case .performance, .systemMetric: .info
        case .navigation, .userAction, .lifecycle: .debug
        }
        
        logger.log(level: logLevel, "Telemetry: \(data.event.name) | Device: \(data.deviceContext.deviceModel) | Data: \(data.event.data)")
    }
    
    public func isAvailable() async -> Bool {
        return true
    }
}

/// External APM telemetry destination
public struct ExternalAPMTelemetryDestination: TelemetryDestination {
    private let endpoint: URL
    private let apiKey: String
    private let session = URLSession.shared
    
    public init(endpoint: URL, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }
    
    public func send(_ data: TelemetryData) async {
        guard await isAvailable() else { return }
        
        do {
            let payload = try createAPMPayload(data)
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = payload
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                print("APM telemetry failed with status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to send APM telemetry: \(error.localizedDescription)")
        }
    }
    
    public func isAvailable() async -> Bool {
        // Simple connectivity check
        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5.0
            
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func createAPMPayload(_ data: TelemetryData) throws -> Data {
        let payload: [String: Any] = [
            "event": [
                "id": data.event.id.uuidString,
                "type": data.event.type.rawValue,
                "name": data.event.name,
                "data": data.event.data,
                "timestamp": ISO8601DateFormatter().string(from: data.event.timestamp)
            ],
            "device": [
                "platform": data.deviceContext.platform,
                "model": data.deviceContext.deviceModel,
                "memory_pressure": data.deviceContext.memoryPressure,
                "thermal_state": data.deviceContext.thermalState,
                "battery_level": data.deviceContext.batteryLevel,
                "low_power_mode": data.deviceContext.isLowPowerMode
            ]
        ]
        
        return try JSONSerialization.data(withJSONObject: payload)
    }
}

// MARK: - Core Telemetry Actor

/// Main telemetry system actor providing centralized telemetry management
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
public actor Telemetry {
    /// Shared telemetry instance
    public static let shared = Telemetry()
    
    private let logger = os.Logger(subsystem: "com.axiom.framework", category: "telemetry")
    private var destinations: [any TelemetryDestination] = []
    private var isEnabled: Bool = true
    private var failureCount: Int = 0
    private let maxFailures: Int = 10
    
    private init() {
        // Initialize with default destinations
        destinations = [
            ConsoleTelemetryDestination(),
            SystemLogTelemetryDestination()
        ]
    }
    
    /// Send a telemetry event
    public func send(_ event: TelemetryEvent) async {
        guard isEnabled && failureCount < maxFailures else { 
            logger.debug("Telemetry disabled or max failures reached")
            return 
        }
        
        do {
            let telemetryData = try await enrichTelemetryEvent(event)
            await sendToDestinations(telemetryData)
        } catch {
            logger.error("Failed to send telemetry: \(error.localizedDescription)")
            recordFailure()
        }
    }
    
    /// Convenience method for error telemetry
    public func send(_ errorData: ErrorTelemetryData) async {
        let event = TelemetryEvent(
            type: .error,
            name: "error_occurred",
            data: [
                "error_type": String(describing: type(of: errorData.error)),
                "context": errorData.context,
                "severity": errorData.severity,
                "description": errorData.error.localizedDescription
            ]
        )
        await send(event)
    }
    
    /// Convenience method for performance alerts
    public func send(_ alert: TelemetryPerformanceAlert) async {
        var data: [String: String] = [
            "alert_type": alert.type.rawValue,
            "message": alert.message
        ]
        
        if let value = alert.value {
            data["value"] = String(value)
        }
        
        if let threshold = alert.threshold {
            data["threshold"] = String(threshold)
        }
        
        let event = TelemetryEvent(
            type: .performance,
            name: "performance_alert",
            data: data
        )
        await send(event)
    }
    
    /// Convenience method for error recovery events
    public func send(_ recoveryEvent: ErrorRecoveryEvent) async {
        let event = TelemetryEvent(
            type: .error,
            name: "error_recovery",
            data: [
                "error_type": String(describing: type(of: recoveryEvent.error)),
                "recovery_option": recoveryEvent.option.rawValue,
                "success": String(recoveryEvent.success),
                "error_description": recoveryEvent.error.localizedDescription,
                "timestamp": ISO8601DateFormatter().string(from: recoveryEvent.timestamp)
            ]
        )
        await send(event)
    }
    
    /// Add a telemetry destination
    public func addDestination(_ destination: any TelemetryDestination) {
        destinations.append(destination)
        logger.info("Added telemetry destination: \(String(describing: type(of: destination)))")
    }
    
    /// Remove all destinations of a specific type
    public func removeDestination<T: TelemetryDestination>(ofType type: T.Type) {
        destinations.removeAll { destination in
            return destination is T
        }
        logger.info("Removed telemetry destinations of type: \(String(describing: type))")
    }
    
    /// Enable or disable telemetry
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("Telemetry \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get current telemetry status
    public func getStatus() async -> TelemetryStatus {
        let availableDestinations = await getAvailableDestinations()
        
        return TelemetryStatus(
            isEnabled: isEnabled,
            destinationCount: destinations.count,
            availableDestinations: availableDestinations,
            failureCount: failureCount,
            maxFailures: maxFailures
        )
    }
    
    // MARK: - Private Methods
    
    private func enrichTelemetryEvent(_ event: TelemetryEvent) async throws -> TelemetryData {
        let deviceMonitor = DeviceInfoMonitor.current
        
        let deviceContext = DeviceContext(
            platform: await detectPlatform(),
            deviceModel: await deviceMonitor.model,
            memoryPressure: await deviceMonitor.currentMemoryPressure,
            thermalState: (await deviceMonitor.thermalState).rawValue,
            batteryLevel: await getBatteryLevel(),
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        
        return TelemetryData(event: event, deviceContext: deviceContext)
    }
    
    private func detectPlatform() async -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return "Unknown"
        #endif
    }
    
    private func sendToDestinations(_ data: TelemetryData) async {
        await withTaskGroup(of: Void.self) { group in
            for destination in destinations {
                group.addTask {
                    await destination.send(data)
                }
            }
        }
    }
    
    private func getAvailableDestinations() async -> Int {
        var availableCount = 0
        
        for destination in destinations {
            if await destination.isAvailable() {
                availableCount += 1
            }
        }
        
        return availableCount
    }
    
    private func recordFailure() {
        failureCount += 1
        
        if failureCount >= maxFailures {
            logger.error("Telemetry disabled due to excessive failures (\(self.failureCount))")
            isEnabled = false
        }
    }
    
    private func getBatteryLevel() async -> Float {
        #if canImport(UIKit)
        return await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            return UIDevice.current.batteryLevel
        }
        #else
        return 1.0 // Default for non-iOS platforms
        #endif
    }
}

// MARK: - Status and Health

/// Telemetry system status
public struct TelemetryStatus: Sendable {
    public let isEnabled: Bool
    public let destinationCount: Int
    public let availableDestinations: Int
    public let failureCount: Int
    public let maxFailures: Int
    
    public var healthScore: Double {
        guard isEnabled else { return 0.0 }
        let destinationHealth = destinationCount > 0 ? Double(availableDestinations) / Double(destinationCount) : 0.0
        let failureHealth = failureCount < maxFailures ? 1.0 - (Double(failureCount) / Double(maxFailures)) : 0.0
        return (destinationHealth + failureHealth) / 2.0
    }
    
    public init(isEnabled: Bool, destinationCount: Int, availableDestinations: Int, failureCount: Int, maxFailures: Int) {
        self.isEnabled = isEnabled
        self.destinationCount = destinationCount
        self.availableDestinations = availableDestinations
        self.failureCount = failureCount
        self.maxFailures = maxFailures
    }
}

// MARK: - Convenience Extensions

public extension ProcessInfo.ThermalState {
    var rawValue: String {
        switch self {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}