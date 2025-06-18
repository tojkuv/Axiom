import Foundation
import AxiomCore

// MARK: - Unified Performance Alert System

/// Unified performance alert system consolidating alerts from all framework workers
public enum PerformanceAlert: Equatable, Sendable {
    // State propagation alerts (from WORKER-01)
    case slaViolation(streamId: UUID, latency: TimeInterval, timestamp: Date)
    case highObserverCount(streamId: UUID, count: Int)
    case propagationDelay(expected: TimeInterval, actual: TimeInterval)
    
    // Task cancellation alerts (from WORKER-02)  
    case slowCancellation(taskId: UUID, duration: TimeInterval, timestamp: Date)
    case priorityInversion(taskId: UUID, expectedPriority: TaskPriority, actualPriority: TaskPriority)
    case timeoutViolation(operation: String, timeout: TimeInterval, actual: TimeInterval)
    
    // State optimization alerts (from Enhanced StateOptimization)
    case slowOperation(count: Int)
    case excessiveMemoryGrowth(bytes: Int)
    case frameDropDetected(droppedFrames: Int)
    
    public var severity: AlertSeverity {
        switch self {
        case .slaViolation, .slowCancellation, .timeoutViolation:
            return .critical
        case .highObserverCount, .priorityInversion, .frameDropDetected:
            return .warning
        case .propagationDelay, .slowOperation, .excessiveMemoryGrowth:
            return .info
        }
    }
    
    public var description: String {
        switch self {
        case .slaViolation(let streamId, let latency, let timestamp):
            return "SLA violation on stream \(streamId): \(latency)ms at \(timestamp)"
        case .highObserverCount(let streamId, let count):
            return "High observer count on stream \(streamId): \(count) observers"
        case .propagationDelay(let expected, let actual):
            return "Propagation delay: expected \(expected)ms, actual \(actual)ms"
        case .slowCancellation(let taskId, let duration, let timestamp):
            return "Slow cancellation for task \(taskId): \(duration)ms at \(timestamp)"
        case .priorityInversion(let taskId, let expected, let actual):
            return "Priority inversion for task \(taskId): expected \(expected), actual \(actual)"
        case .timeoutViolation(let operation, let timeout, let actual):
            return "Timeout violation in \(operation): timeout \(timeout)ms, actual \(actual)ms"
        case .slowOperation(let count):
            return "Slow operations detected: \(count) operations"
        case .excessiveMemoryGrowth(let bytes):
            return "Excessive memory growth: \(bytes) bytes"
        case .frameDropDetected(let frames):
            return "Frame drops detected: \(frames) frames"
        }
    }
}

public enum AlertSeverity: String, CaseIterable, Sendable {
    case critical = "critical"
    case warning = "warning" 
    case info = "info"
    
    public var priority: Int {
        switch self {
        case .critical: return 3
        case .warning: return 2
        case .info: return 1
        }
    }
}

// MARK: - Performance Monitor

/// Unified performance monitoring system for the framework
public final class PerformanceMonitor: @unchecked Sendable {
    private var alerts: [PerformanceAlert] = []
    private var isTrackingEnabled = false
    private let alertQueue = DispatchQueue(label: "com.axiom.performance.alerts")
    
    public init() {}
    
    public func enableTracking() {
        alertQueue.async {
            self.isTrackingEnabled = true
        }
    }
    
    public func disableTracking() {
        alertQueue.async {
            self.isTrackingEnabled = false
        }
    }
    
    public var isTracking: Bool {
        return alertQueue.sync {
            return isTrackingEnabled
        }
    }
    
    public func addAlert(_ alert: PerformanceAlert) {
        guard isTracking else { return }
        
        alertQueue.async {
            self.alerts.append(alert)
            // Keep only the last 100 alerts to prevent memory growth
            if self.alerts.count > 100 {
                self.alerts.removeFirst(self.alerts.count - 100)
            }
        }
    }
    
    public func getCurrentAlerts() -> [PerformanceAlert] {
        return alertQueue.sync {
            return Array(self.alerts)
        }
    }
    
    public func clearAlerts() {
        alertQueue.async {
            self.alerts.removeAll()
        }
    }
    
    public func getAlertsBySeverity(_ severity: AlertSeverity) -> [PerformanceAlert] {
        return alertQueue.sync {
            return self.alerts.filter { $0.severity == severity }
        }
    }
    
    public func enableApplicationMetrics() {
        enableTracking()
        // Add any application-specific monitoring setup here
    }
    
    // MARK: - SLA Monitoring
    
    /// Record an SLA violation for state propagation
    public func recordSLAViolation(streamId: UUID, latency: TimeInterval) {
        let alert = PerformanceAlert.slaViolation(
            streamId: streamId,
            latency: latency,
            timestamp: Date()
        )
        addAlert(alert)
    }
}