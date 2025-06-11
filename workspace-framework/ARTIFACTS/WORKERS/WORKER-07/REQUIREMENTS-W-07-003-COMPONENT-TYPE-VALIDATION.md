# REQUIREMENTS-W-07-003: Component Type Validation

## Purpose

Establish a comprehensive validation system for the six immutable component types (Capability, State, Client, Orchestrator, Context, Presentation) ensuring type safety, architectural constraints, and proper component lifecycle management.

## Core Requirements

### 1. Component Type System

#### 1.1 Immutable Component Types
```swift
@frozen
public enum ComponentType: Int, CaseIterable {
    case capability     // Level 3 - External system access
    case state         // Special - Immutable value types
    case client        // Level 2 - Actor-based state containers
    case orchestrator  // Level 0 - Application coordinator
    case context       // Level 1 - MainActor UI bridge
    case presentation  // Special - SwiftUI Views
}
```

#### 1.2 Type Properties
- **Frozen Enumeration**: No new cases can be added
- **Integer Raw Values**: Efficient comparison and storage
- **Case Iterable**: Enable exhaustive validation
- **Custom Description**: Human-readable type names

### 2. Type-Specific Constraints

#### 2.1 Capability Constraints
- Must be actor-isolated or thread-safe
- Must implement resource lifecycle (initialize/terminate)
- Must provide availability status
- Must handle permissions where applicable

#### 2.2 State Constraints
- Must be value types (struct/enum)
- Must be immutable (let properties or controlled mutation)
- Must be Sendable for concurrent access
- No external dependencies allowed

#### 2.3 Client Constraints
- Must be actor-isolated
- Must own and manage State
- Must process Actions asynchronously
- Must provide state observation stream

#### 2.4 Orchestrator Constraints
- Single instance per application
- Must be @MainActor isolated
- Manages Context lifecycle
- Coordinates navigation

#### 2.5 Context Constraints
- Must be @MainActor isolated
- Must observe exactly one Client
- Must be ObservableObject
- Bridges Client state to Presentation

#### 2.6 Presentation Constraints
- Must be SwiftUI View
- Single Context binding
- No business logic
- Pure UI representation

### 3. Compile-Time Validation

#### 3.1 Protocol Conformance
```swift
protocol CapabilityValidatable {
    func initialize() async throws
    func terminate() async
    var isAvailable: Bool { get async }
}

protocol StateValidatable: Sendable {
    // Marker protocol for value type validation
}

protocol ClientValidatable: Actor {
    associatedtype StateType
    associatedtype ActionType
}
```

#### 3.2 Type Checking
- Validate correct protocol conformance
- Ensure proper isolation attributes
- Check required method implementations
- Verify associated type constraints

### 4. Runtime Validation

#### 4.1 Component Registration
- Validate type matches declaration
- Check dependency requirements
- Verify lifecycle methods exist
- Ensure proper initialization order

#### 4.2 Lifecycle Validation
- Track component state transitions
- Prevent invalid state changes
- Validate cleanup on termination
- Detect resource leaks

### 5. Macro-Based Validation

#### 5.1 Component Macros
```swift
@Capability(.network)
@State
@Client(state: TaskState.self, action: TaskAction.self)
@Context(client: TaskClient.self)
@Orchestrator
@Presentation(context: TaskListContext.self)
```

#### 5.2 Macro Validation
- Generate required boilerplate
- Enforce architectural patterns
- Validate macro arguments
- Produce compile-time errors

### 6. Type Safety Features

#### 6.1 Generic Constraints
- Type-safe component references
- Compile-time dependency checking
- Associated type validation
- Protocol witness tables

#### 6.2 Type Inference
- Automatic type detection from usage
- Smart macro parameter inference
- Context-aware validation
- IDE integration support

### 7. Error Reporting

#### 7.1 Validation Errors
- "Component does not conform to required protocol"
- "Invalid isolation for component type"
- "Missing required lifecycle method"
- "Incompatible associated types"

#### 7.2 Diagnostic Information
- Component type and location
- Expected vs actual implementation
- Suggested fixes
- Documentation links

## Success Criteria

1. **Type Safety**: 100% compile-time type validation
2. **Constraint Enforcement**: All architectural rules enforced
3. **Clear Errors**: Actionable error messages
4. **Performance**: Zero runtime overhead for validation
5. **Coverage**: All component types fully validated

## Implementation Priority

1. Core type system with constraints
2. Protocol-based validation
3. Macro integration for type checking
4. Runtime registration validation
5. Lifecycle management
6. Error reporting system

## Dependencies

- ComponentType enumeration (PROVISIONER)
- Macro system (WORKER-07-004)
- Protocol definitions (PROVISIONER)
- Error handling (PROVISIONER)

## Validation Examples

### Valid Components
```swift
// Valid Capability
actor NetworkCapability: CapabilityValidatable {
    func initialize() async throws { }
    func terminate() async { }
    var isAvailable: Bool { true }
}

// Valid State
struct TaskState: StateValidatable {
    let id: UUID
    let title: String
}

// Valid Client
actor TaskClient: ClientValidatable {
    typealias StateType = TaskState
    typealias ActionType = TaskAction
}
```

### Invalid Components
```swift
// Invalid State (reference type)
class TaskState { } ✗

// Invalid Client (not actor)
class TaskClient { } ✗

// Invalid Context (wrong isolation)
struct TaskContext { } ✗

// Invalid Capability (missing lifecycle)
actor NetworkCapability { } ✗
```