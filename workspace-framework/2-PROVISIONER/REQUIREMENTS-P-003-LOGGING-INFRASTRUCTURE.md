# REQUIREMENTS-P-003: Logging Infrastructure

## Executive Summary

### Problem Statement
The AxiomFramework currently uses print statements and lacks a structured logging system. Without proper logging infrastructure, parallel development teams cannot effectively debug issues, monitor performance, or track system behavior. The framework needs a foundational logging system that supports structured logging, performance tracking, and production-safe operation.

### Proposed Solution
Implement a lightweight, performant logging infrastructure that provides:
- Structured logging with levels and categories
- Compile-time optimization for release builds
- Privacy-safe logging with redaction
- Performance metrics collection
- Integration with system logging (OSLog)

### Expected Impact
- Enable effective debugging across all framework components
- Support production monitoring and diagnostics
- Facilitate performance optimization
- Ensure privacy compliance
- Reduce debugging time for parallel teams

## Current State Analysis

Based on code analysis, the framework currently:

### Logging Gaps
1. **No structured logging** - Only print statements found
2. **No log levels** - Cannot filter by severity
3. **No categories** - Cannot filter by component
4. **No performance tracking** - Manual measurements only
5. **No privacy controls** - Risk of logging sensitive data

### Current Debug Output
- ErrorHandling.swift: Uses print for silent errors
- Capability.swift: Print for initialization failures
- Various tests: Print statements for debugging

### Requirements from Components
- Contexts need lifecycle logging
- Clients need action/state change logging
- Capabilities need state transition logging
- Error boundaries need failure logging
- Performance monitoring needs metric logging

## Requirement Details

### R-003.1: Core Logging API
- Simple, intuitive logging interface
- Multiple log levels (debug, info, warning, error)
- Categorized logging by component
- Structured data support
- Compile-time optimization

### R-003.2: Privacy and Security
- Automatic PII redaction
- Configurable privacy levels
- Safe logging in production
- Audit trail support
- GDPR compliance helpers

### R-003.3: Performance Logging
- Automatic operation timing
- Memory usage tracking
- Throughput metrics
- Latency measurements
- Resource utilization

### R-003.4: System Integration
- OSLog integration on Apple platforms
- Console output for development
- File logging option
- Remote logging hooks
- Crash report integration

### R-003.5: Developer Experience
- SwiftUI preview support
- XCTest integration
- Conditional compilation
- Log filtering/searching
- Documentation generation

## API Design

### Core Logger Interface

```swift
// Main logger protocol
public protocol Logger: Sendable {
    func log(_ level: LogLevel, _ message: @autoclosure () -> String, metadata: LogMetadata?)
    func log<T: LoggableValue>(_ level: LogLevel, _ value: T, metadata: LogMetadata?)
}

// Log levels
public enum LogLevel: Int, Comparable {
    case trace = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// Log metadata
public struct LogMetadata: ExpressibleByDictionaryLiteral {
    public let values: [String: LoggableValue]
    
    public init(dictionaryLiteral elements: (String, LoggableValue)...) {
        self.values = Dictionary(uniqueKeysWithValues: elements)
    }
}

// Loggable value protocol
public protocol LoggableValue: CustomStringConvertible, Sendable {
    var isPrivate: Bool { get }
}
```

### Category-Based Logging

```swift
// Log categories for filtering
public struct LogCategory: RawRepresentable, Hashable {
    public let rawValue: String
    
    // Standard categories
    public static let context = LogCategory(rawValue: "axiom.context")
    public static let client = LogCategory(rawValue: "axiom.client")
    public static let capability = LogCategory(rawValue: "axiom.capability")
    public static let navigation = LogCategory(rawValue: "axiom.navigation")
    public static let performance = LogCategory(rawValue: "axiom.performance")
}

// Category logger
public struct CategoryLogger: Logger {
    public let category: LogCategory
    public let subsystem: String
    
    public static func logger(for category: LogCategory) -> CategoryLogger {
        CategoryLogger(category: category, subsystem: "com.axiom.framework")
    }
}
```

### Performance Logging

```swift
// Performance logger
public struct PerformanceLogger {
    private let logger: Logger
    
    // Log operation timing
    public func time<T>(
        _ operation: String,
        metadata: LogMetadata? = nil,
        body: () async throws -> T
    ) async rethrows -> T {
        let start = ContinuousClock.now
        defer {
            let duration = ContinuousClock.now - start
            logger.log(.debug, "Operation '\(operation)' took \(duration)", 
                      metadata: metadata)
        }
        return try await body()
    }
    
    // Log memory usage
    public func memory(
        _ label: String,
        metadata: LogMetadata? = nil
    ) {
        let usage = getMemoryUsage()
        logger.log(.debug, "Memory at '\(label)': \(usage)MB", 
                  metadata: metadata)
    }
}
```

### Privacy-Safe Logging

```swift
// Privacy-safe string
public struct PrivateString: LoggableValue {
    private let value: String
    public let isPrivate = true
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var description: String {
        #if DEBUG
        return value
        #else
        return "<private>"
        #endif
    }
}

// Privacy extensions
public extension Logger {
    func logPrivate(_ level: LogLevel, _ message: String, metadata: LogMetadata? = nil) {
        log(level, PrivateString(message), metadata: metadata)
    }
}
```

### Conditional Compilation

```swift
// Debug-only logging
public struct DebugLogger: Logger {
    public func log(_ level: LogLevel, _ message: @autoclosure () -> String, metadata: LogMetadata?) {
        #if DEBUG
        // Log only in debug builds
        #endif
    }
}

// Log configuration
public struct LogConfiguration {
    public var minimumLevel: LogLevel
    public var enabledCategories: Set<LogCategory>
    public var outputDestination: LogDestination
    
    public static let debug = LogConfiguration(
        minimumLevel: .debug,
        enabledCategories: Set(LogCategory.allCases),
        outputDestination: .console
    )
    
    public static let release = LogConfiguration(
        minimumLevel: .warning,
        enabledCategories: [.error, .performance],
        outputDestination: .oslog
    )
}
```

### Integration Helpers

```swift
// Context logging
public extension Context {
    var logger: CategoryLogger {
        .logger(for: .context)
    }
    
    func logLifecycle(_ event: String) {
        logger.log(.debug, "[\(type(of: self))] \(event)")
    }
}

// Client logging  
public extension Client {
    var logger: CategoryLogger {
        .logger(for: .client)
    }
    
    func logAction(_ action: ActionType) {
        logger.log(.debug, "Processing action: \(action)")
    }
}
```

## Technical Design

### Implementation Approach

1. **Zero-Overhead Abstraction**
   - Use @autoclosure for lazy evaluation
   - Compile out debug logs in release
   - Minimal allocations
   - Efficient string building

2. **Platform Integration**
   - OSLog on Apple platforms
   - Structured logging support
   - Console fallback
   - File output option

3. **Thread Safety**
   - Actor-based log dispatch
   - Lock-free queue for performance
   - Async-safe operations
   - Sendable conformance

4. **Extensibility**
   - Custom log destinations
   - Plugin architecture
   - Metadata transformers
   - Format customization

### Performance Considerations

1. **Compile-Time Optimization**
   - Strip debug logs in release
   - Inline simple operations
   - Const-fold log levels
   - Dead code elimination

2. **Runtime Efficiency**
   - Lazy message evaluation
   - Bounded queue sizes
   - Async dispatch
   - Batched writes

3. **Memory Management**
   - Fixed-size buffers
   - Log rotation
   - Automatic cleanup
   - Weak references

## Success Criteria

### Functional Requirements
- [ ] All log levels work correctly
- [ ] Categories filter as expected
- [ ] Privacy redaction functions
- [ ] Performance metrics accurate
- [ ] OSLog integration works

### Performance Metrics
- [ ] <100ns overhead when disabled
- [ ] <1μs for basic log operation
- [ ] <10μs for structured logging
- [ ] Zero allocations when disabled
- [ ] Bounded memory usage

### Developer Experience
- [ ] Simple API to use
- [ ] Clear documentation
- [ ] Helpful error messages
- [ ] Good IDE support
- [ ] Easy configuration

### Production Readiness
- [ ] Privacy compliant
- [ ] Crash-safe logging
- [ ] Log rotation works
- [ ] Remote logging ready
- [ ] Performance acceptable

### Integration Validation
- [ ] Works with all components
- [ ] SwiftUI preview support
- [ ] XCTest captures logs
- [ ] Instruments integration
- [ ] Console app support