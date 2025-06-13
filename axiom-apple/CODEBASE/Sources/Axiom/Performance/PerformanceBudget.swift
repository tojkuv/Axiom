import Foundation

// MARK: - Performance Budget Types

public enum BudgetError: Error, Sendable {
    case noBudgetAllocated(String)
    case insufficientBudget(String)
    case subBudgetsExceedTotal
    case budgetExceeded(String, allocated: TimeInterval, consumed: TimeInterval)
    
    public var localizedDescription: String {
        switch self {
        case .noBudgetAllocated(let operation):
            return "No budget allocated for operation: \(operation)"
        case .insufficientBudget(let operation):
            return "Insufficient budget remaining for operation: \(operation)"
        case .subBudgetsExceedTotal:
            return "Sub-budgets exceed total allocated budget"
        case .budgetExceeded(let operation, let allocated, let consumed):
            return "Budget exceeded for \(operation): allocated \(String(format: "%.2f", allocated * 1000))ms, consumed \(String(format: "%.2f", consumed * 1000))ms"
        }
    }
}

public struct BudgetAlert: Sendable {
    public let operation: String
    public let allocated: TimeInterval
    public let consumed: TimeInterval
    public let excess: TimeInterval
    public let timestamp: Date
    
    public init(operation: String, allocated: TimeInterval, consumed: TimeInterval, excess: TimeInterval) {
        self.operation = operation
        self.allocated = allocated
        self.consumed = consumed
        self.excess = excess
        self.timestamp = Date()
    }
}

public struct PerformanceBudget: Sendable {
    public let operation: String
    public let allocatedTime: TimeInterval
    public var consumedTime: TimeInterval
    public let subBudgets: [String: TimeInterval]
    public let createdAt: Date
    
    public var remainingTime: TimeInterval {
        max(0, allocatedTime - consumedTime)
    }
    
    public var isExceeded: Bool {
        consumedTime > allocatedTime
    }
    
    public var utilizationPercentage: Double {
        guard allocatedTime > 0 else { return 0 }
        return (consumedTime / allocatedTime) * 100
    }
    
    public var isNearingLimit: Bool {
        utilizationPercentage > 80.0
    }
    
    public init(operation: String, allocatedTime: TimeInterval, subBudgets: [String: TimeInterval] = [:]) {
        self.operation = operation
        self.allocatedTime = allocatedTime
        self.consumedTime = 0
        self.subBudgets = subBudgets
        self.createdAt = Date()
    }
}

// MARK: - Performance Budget Manager

/// Manages performance budgets across operations with proactive enforcement
public actor PerformanceBudgetManager {
    public static let shared = PerformanceBudgetManager()
    
    private var budgets: [String: PerformanceBudget] = [:]
    private let totalBudget: TimeInterval = 0.005 // 5ms total
    private var totalAllocated: TimeInterval = 0
    private let logger = CategoryLogger.logger(for: .performance)
    
    private init() {}
    
    /// Allocate budget for an operation with optional sub-budgets
    public func allocateBudget(
        for operation: String,
        time: TimeInterval,
        subBudgets: [String: TimeInterval] = [:]
    ) throws {
        // Validate sub-budgets don't exceed total
        let subBudgetTotal = subBudgets.values.reduce(0, +)
        guard subBudgetTotal <= time else {
            throw BudgetError.subBudgetsExceedTotal
        }
        
        // Check if allocation would exceed total budget
        let newTotalAllocated = totalAllocated - (budgets[operation]?.allocatedTime ?? 0) + time
        guard newTotalAllocated <= totalBudget else {
            logger.warning("Budget allocation for \(operation) would exceed total budget: \(String(format: "%.2f", newTotalAllocated * 1000))ms > \(String(format: "%.2f", totalBudget * 1000))ms")
            return
        }
        
        // Update total allocated
        totalAllocated = newTotalAllocated
        
        budgets[operation] = PerformanceBudget(
            operation: operation,
            allocatedTime: time,
            subBudgets: subBudgets
        )
        
        logger.info("Budget allocated for \(operation): \(String(format: "%.2f", time * 1000))ms")
    }
    
    /// Consume budget for an operation
    public func consumeBudget(
        for operation: String,
        time: TimeInterval
    ) async throws {
        guard var budget = budgets[operation] else {
            throw BudgetError.noBudgetAllocated(operation)
        }
        
        budget.consumedTime += time
        budgets[operation] = budget
        
        // Check for warnings before exceeding
        if budget.isNearingLimit && !budget.isExceeded {
            logger.warning("Budget warning for \(operation): \(String(format: "%.1f", budget.utilizationPercentage))% utilized")
        }
        
        if budget.isExceeded {
            await handleBudgetExceeded(budget)
        }
    }
    
    /// Execute operation within budget constraints
    public func withBudget<T: Sendable>(
        _ operation: String,
        execute: () async throws -> T
    ) async throws -> T {
        guard let budget = budgets[operation] else {
            throw BudgetError.noBudgetAllocated(operation)
        }
        
        // Check if we have budget remaining
        if budget.remainingTime <= 0 {
            throw BudgetError.insufficientBudget(operation)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try await execute()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        try await consumeBudget(for: operation, time: duration)
        
        return result
    }
    
    /// Execute synchronous operation within budget constraints
    public func withBudgetSync<T>(
        _ operation: String,
        execute: () throws -> T
    ) async throws -> T {
        guard let budget = budgets[operation] else {
            throw BudgetError.noBudgetAllocated(operation)
        }
        
        // Check if we have budget remaining
        if budget.remainingTime <= 0 {
            throw BudgetError.insufficientBudget(operation)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try execute()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        try await consumeBudget(for: operation, time: duration)
        
        return result
    }
    
    /// Handle budget exceeded scenario
    private func handleBudgetExceeded(_ budget: PerformanceBudget) async {
        let alert = BudgetAlert(
            operation: budget.operation,
            allocated: budget.allocatedTime,
            consumed: budget.consumedTime,
            excess: budget.consumedTime - budget.allocatedTime
        )
        
        let message = """
        💸 Budget Exceeded: \(alert.operation)
        Allocated: \(String(format: "%.2f", alert.allocated * 1000))ms
        Consumed: \(String(format: "%.2f", alert.consumed * 1000))ms
        Excess: \(String(format: "%.2f", alert.excess * 1000))ms (\(String(format: "%.1f", budget.utilizationPercentage))% utilization)
        """
        
        logger.error(message)
        await Telemetry.shared.send(TelemetryPerformanceAlert(
            type: .memoryPressure,
            message: message,
            value: alert.excess * 1000,
            threshold: budget.allocatedTime * 1000
        ))
    }
    
    /// Get budget status for an operation
    public func getBudgetStatus(for operation: String) -> (allocated: TimeInterval, consumed: TimeInterval, remaining: TimeInterval, utilization: Double)? {
        guard let budget = budgets[operation] else { return nil }
        return (budget.allocatedTime, budget.consumedTime, budget.remainingTime, budget.utilizationPercentage)
    }
    
    /// Get all budget statuses
    public func getAllBudgetStatuses() -> [String: (allocated: TimeInterval, consumed: TimeInterval, remaining: TimeInterval, utilization: Double)] {
        var statuses: [String: (allocated: TimeInterval, consumed: TimeInterval, remaining: TimeInterval, utilization: Double)] = [:]
        
        for (operation, budget) in budgets {
            statuses[operation] = (budget.allocatedTime, budget.consumedTime, budget.remainingTime, budget.utilizationPercentage)
        }
        
        return statuses
    }
    
    /// Reset budget consumption for an operation
    public func resetBudget(for operation: String) {
        if var budget = budgets[operation] {
            budget.consumedTime = 0
            budgets[operation] = budget
            logger.info("Budget reset for \(operation)")
        }
    }
    
    /// Reset all budget consumption
    public func resetAllBudgets() {
        for operation in budgets.keys {
            resetBudget(for: operation)
        }
        logger.info("All budgets reset")
    }
    
    /// Generate budget utilization report
    public func generateBudgetReport() -> String {
        var report = "=== Performance Budget Report ===\n"
        report += "Total Budget: \(String(format: "%.2f", totalBudget * 1000))ms\n"
        report += "Total Allocated: \(String(format: "%.2f", totalAllocated * 1000))ms (\(String(format: "%.1f", (totalAllocated / totalBudget) * 100))%)\n\n"
        
        for (operation, budget) in budgets.sorted(by: { $0.key < $1.key }) {
            let status = budget.isExceeded ? "⚠️ EXCEEDED" : budget.isNearingLimit ? "⚡ WARNING" : "✅ OK"
            
            report += "Operation: \(operation) [\(status)]\n"
            report += "  Allocated: \(String(format: "%.2f", budget.allocatedTime * 1000))ms\n"
            report += "  Consumed: \(String(format: "%.2f", budget.consumedTime * 1000))ms\n"
            report += "  Remaining: \(String(format: "%.2f", budget.remainingTime * 1000))ms\n"
            report += "  Utilization: \(String(format: "%.1f", budget.utilizationPercentage))%\n"
            
            if !budget.subBudgets.isEmpty {
                report += "  Sub-budgets:\n"
                for (subOperation, subBudget) in budget.subBudgets.sorted(by: { $0.key < $1.key }) {
                    report += "    \(subOperation): \(String(format: "%.2f", subBudget * 1000))ms\n"
                }
            }
            
            report += "\n"
        }
        
        return report
    }
}

// MARK: - Default Budget Configuration

extension PerformanceBudgetManager {
    /// Configure default budgets for common operations
    public func configureDefaultBudgets() async throws {
        logger.info("Configuring default performance budgets")
        
        // Navigation operations - 1ms total
        try allocateBudget(
            for: "navigation",
            time: 0.001, // 1ms
            subBudgets: [
                "routeValidation": 0.0003,  // 0.3ms
                "viewCreation": 0.0005,    // 0.5ms
                "transition": 0.0002       // 0.2ms
            ]
        )
        
        // State updates - 1.5ms total
        try allocateBudget(
            for: "stateUpdate",
            time: 0.0015, // 1.5ms
            subBudgets: [
                "validation": 0.0003,     // 0.3ms
                "mutation": 0.0007,       // 0.7ms
                "propagation": 0.0005     // 0.5ms
            ]
        )
        
        // Rendering operations - 2.5ms total
        try allocateBudget(
            for: "rendering",
            time: 0.0025 // 2.5ms
        )
        
        // Context operations - 0.5ms total
        try allocateBudget(
            for: "context",
            time: 0.0005, // 0.5ms
            subBudgets: [
                "setup": 0.0002,          // 0.2ms
                "teardown": 0.0001,       // 0.1ms
                "dependency": 0.0002      // 0.2ms
            ]
        )
        
        logger.info("Default performance budgets configured successfully")
    }
    
    /// Configure budgets for specific performance class
    public func configureBudgetsForPerformanceClass(_ performanceClass: PerformanceClass) async throws {
        let multiplier = performanceClass.budgetMultiplier
        
        try allocateBudget(
            for: "navigation",
            time: 0.001 * multiplier,
            subBudgets: [
                "routeValidation": 0.0003 * multiplier,
                "viewCreation": 0.0005 * multiplier,
                "transition": 0.0002 * multiplier
            ]
        )
        
        try allocateBudget(
            for: "stateUpdate",
            time: 0.0015 * multiplier,
            subBudgets: [
                "validation": 0.0003 * multiplier,
                "mutation": 0.0007 * multiplier,
                "propagation": 0.0005 * multiplier
            ]
        )
        
        try allocateBudget(
            for: "rendering",
            time: 0.0025 * multiplier
        )
        
        try allocateBudget(
            for: "context",
            time: 0.0005 * multiplier,
            subBudgets: [
                "setup": 0.0002 * multiplier,
                "teardown": 0.0001 * multiplier,
                "dependency": 0.0002 * multiplier
            ]
        )
        
        logger.info("Performance budgets configured for \(performanceClass) class (multiplier: \(multiplier))")
    }
}

// MARK: - Performance Class Support

public enum PerformanceClass: Sendable {
    case high, medium, low
    
    var budgetMultiplier: Double {
        switch self {
        case .high: return 1.0
        case .medium: return 1.5
        case .low: return 2.0
        }
    }
}