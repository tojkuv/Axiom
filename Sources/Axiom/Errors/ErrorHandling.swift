import Foundation

// MARK: - Error Handler

/// A centralized error handler for the Axiom framework
public actor ErrorHandler {
    private var errorHandlers: [ErrorCategory: (any AxiomError) async -> Void] = [:]
    private var errorHistory: [ErrorRecord] = []
    private let maxHistorySize: Int
    
    public init(maxHistorySize: Int = 1000) {
        self.maxHistorySize = maxHistorySize
    }
    
    /// Records an error and optionally handles it
    public func handle(_ error: any AxiomError) async {
        // Record the error
        await recordError(error)
        
        // Execute category-specific handler if available
        if let handler = errorHandlers[error.category] {
            await handler(error)
        }
        
        // Execute recovery actions if severity is high enough
        if error.severity >= .error {
            await executeRecoveryActions(for: error)
        }
    }
    
    /// Registers a handler for a specific error category
    public func registerHandler(
        for category: ErrorCategory,
        handler: @escaping (any AxiomError) async -> Void
    ) {
        errorHandlers[category] = handler
    }
    
    /// Records an error in the history
    private func recordError(_ error: any AxiomError) async {
        let record = ErrorRecord(
            error: error,
            timestamp: Date(),
            handled: errorHandlers[error.category] != nil
        )
        
        errorHistory.append(record)
        
        // Maintain history size limit
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
    }
    
    /// Executes recovery actions for an error
    private func executeRecoveryActions(for error: any AxiomError) async {
        for action in error.recoveryActions {
            switch action {
            case .retry(let interval):
                // Log retry recommendation
                print("[Axiom] Recovery: Retry recommended after \(interval)s for \(error)")
                
            case .reconfigure(let message):
                // Log reconfiguration requirement
                print("[Axiom] Recovery: Reconfiguration needed - \(message)")
                
            case .fallback(let message):
                // Log fallback action
                print("[Axiom] Recovery: Fallback to - \(message)")
                
            case .ignore:
                // Log that error can be ignored
                print("[Axiom] Recovery: Error can be safely ignored")
                
            case .escalate:
                // Log escalation requirement
                print("[Axiom] Recovery: Error requires escalation to administrator")
                
            case .custom(let message, let action):
                // Execute custom action
                print("[Axiom] Recovery: Executing custom action - \(message)")
                action()
            }
        }
    }
    
    /// Gets error statistics for a given time period
    public func getErrorStatistics(
        since date: Date,
        category: ErrorCategory? = nil
    ) -> ErrorStatistics {
        let relevantErrors = errorHistory.filter { record in
            record.timestamp >= date &&
            (category == nil || record.error.category == category)
        }
        
        let severityCounts = Dictionary(
            grouping: relevantErrors,
            by: { $0.error.severity }
        ).mapValues { $0.count }
        
        return ErrorStatistics(
            totalCount: relevantErrors.count,
            severityCounts: severityCounts,
            mostCommonCategory: findMostCommonCategory(in: relevantErrors),
            handledPercentage: calculateHandledPercentage(in: relevantErrors)
        )
    }
    
    private func findMostCommonCategory(in records: [ErrorRecord]) -> ErrorCategory? {
        let categoryCounts = Dictionary(
            grouping: records,
            by: { $0.error.category }
        ).mapValues { $0.count }
        
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func calculateHandledPercentage(in records: [ErrorRecord]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let handledCount = records.filter { $0.handled }.count
        return Double(handledCount) / Double(records.count) * 100.0
    }
}

// MARK: - Error Record

/// A record of an error that occurred
private struct ErrorRecord {
    let error: any AxiomError
    let timestamp: Date
    let handled: Bool
}

// MARK: - Error Statistics

/// Statistics about errors over a time period
public struct ErrorStatistics: Sendable {
    public let totalCount: Int
    public let severityCounts: [ErrorSeverity: Int]
    public let mostCommonCategory: ErrorCategory?
    public let handledPercentage: Double
}

// MARK: - Error Context Extensions

public extension ErrorContext {
    /// Creates an error context with additional debugging information
    static func withDebugInfo(
        component: ComponentID,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> ErrorContext {
        ErrorContext(
            component: component,
            additionalInfo: [
                "file": file,
                "function": function,
                "line": String(line)
            ]
        )
    }
}

// MARK: - Result Extensions

public extension Result where Failure: AxiomError {
    /// Maps the error to include additional context
    func mapErrorContext(_ transform: (Failure) -> ErrorContext) -> Result<Success, Failure> {
        self // Context is already part of the error
    }
    
    /// Logs the error if present and returns the result unchanged
    func logError(to handler: ErrorHandler) async -> Result<Success, Failure> {
        if case .failure(let error) = self {
            await handler.handle(error)
        }
        return self
    }
}