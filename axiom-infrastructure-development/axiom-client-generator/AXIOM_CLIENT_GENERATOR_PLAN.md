# Axiom Swift Client Generator - Revised Plan

## Executive Summary

This document outlines the focused development plan for the **Axiom Swift Client Generator**, a Rust-based MCP tool that generates Swift client code compatible with the existing Axiom Apple framework from gRPC proto definitions.

### Project Vision
Generate Swift clients that seamlessly integrate with the existing Axiom Apple framework, following established patterns for actor-based state management, reactive streams, and type-safe action processing.

### Core Value Propositions
1. **Proto-First Architecture**: gRPC proto as the single source of truth for Swift client generation
2. **Axiom Framework Integration**: Generate clients that perfectly integrate with the existing Axiom Apple framework
3. **Actor-Based Clients**: Generate Swift actors conforming to `AxiomClient` protocol
4. **Type-Safe Actions**: Generate action enums and state structs following Axiom patterns
5. **Performance**: Fast parsing and generation optimized for the Swift development workflow

### Success Metrics
- **Generation Speed**: <2 seconds for typical proto packages
- **Code Quality**: 100% compilation success for all generated Swift code
- **Framework Compatibility**: Perfect integration with existing Axiom Apple framework patterns
- **Developer Experience**: 90% reduction in boilerplate for Swift client implementation

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                             │
│  ┌─────────────────────────────────────────────────────────────┤
│  │ Developer: "Generate Swift client for TaskService proto"   │
│  │ Claude: Calls generate_axiom_swift_clients MCP tool        │
│  └─────────────────────────────────────────────────────────────┤
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼ MCP Protocol (JSON-RPC over stdio)
┌─────────────────────────────────────────────────────────────────┐
│         Axiom Swift Client Generator (Rust MCP Server)         │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Proto Parser    │  │ Swift Generator │  │ Template        │  │
│  │                 │  │                 │  │ Engine          │  │
│  │ • prost/tonic   │──│ • Actor gen     │──│                 │  │
│  │ • Schema parse  │  │ • State gen     │  │ • Client actors │  │
│  │ • Metadata ext  │  │ • Action gen    │  │ • Action enums  │  │
│  │ • Type analysis │  │ • Axiom compat │  │ • State structs │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐           │                   │            │
│  │ File Manager    │           ▼                   ▼            │
│  │                 │  ┌─────────────────┐  ┌─────────────────┐  │
│  │ • Swift output  │──│ Code Validator  │  │ Framework       │  │
│  │ • Path mgmt     │  │                 │  │ Integration     │  │
│  │ • Atomic writes │  │ • Swift compile │  │                 │  │
│  │ • Package.swift │  │ • Syntax check  │  │ • Axiom compat  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Generated Swift Files                      │
│                                                                 │
│ TaskManager/                                                    │
│ ├── Sources/                                                    │
│ │   ├── TaskService.swift          // Proto contracts          │
│ │   ├── TaskModels.swift           // Message types            │
│ │   ├── TaskClient.swift           // Axiom actor client       │
│ │   ├── TaskAction.swift           // Action enum              │
│ │   ├── TaskState.swift            // State struct             │
│ │   └── Package.swift              // Swift package            │
│ └── Tests/                                                      │
│     └── TaskClientTests.swift      // Unit tests               │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
gRPC Proto Files → Proto Parser → Swift Analysis → Axiom Integration → Swift Client Files
       ↓              ↓             ↓                ↓                    ↓
  service Task {   Service AST   Actor Mapping    Client Templates    TaskClient.swift
  rpc Create...    Message AST   Action Mapping   Action Templates    TaskAction.swift
  }               Type Analysis   State Design     State Templates     TaskState.swift
  message Task{}   Metadata Ext   Framework Logic  Validation         Tests
```

---

## Integration with Existing Frameworks

### Axiom Endpoints Framework Integration

The generator works as part of a complete workflow:

1. **C# Endpoints** → AxiomEndpoints.ProtoGen → **Proto Files**
2. **Proto Files** → Axiom Swift Client Generator → **Swift Clients**
3. **Swift Clients** → Integrate with **Axiom Apple Framework**

### Axiom Apple Framework Patterns

Generated clients must conform to existing patterns:

#### Client Pattern
```swift
public actor TaskClient: AxiomClient {
    public typealias StateType = TaskState
    public typealias ActionType = TaskAction
    
    // Conform to AxiomClient protocol
    public var stateStream: AsyncStream<TaskState> { }
    public func process(_ action: TaskAction) async throws { }
}
```

#### State Pattern
```swift
public struct TaskState: AxiomState {
    public let tasks: [Task]
    public let isLoading: Bool
    public let error: Error?
    
    // Immutable state updates
    public func withNewTask(_ task: Task) -> TaskState { }
}
```

#### Action Pattern
```swift
public enum TaskAction: Sendable {
    case createTask(CreateTaskRequest)
    case updateTask(String, UpdateTaskRequest)
    case deleteTask(String)
    case loadTasks
}
```

---

## Technical Specifications

### Project Structure

```
axiom-swift-client-generator/
├── Cargo.toml                      # Rust project configuration
├── README.md
├── AXIOM_SWIFT_CLIENT_GENERATOR_PLAN.md
├── proto/                          # Example proto files
│   ├── examples/
│   │   ├── task_service.proto
│   │   └── user_service.proto
│   └── axiom_options.proto         # Custom proto options for Axiom
├── src/
│   ├── main.rs                     # Binary entry point
│   ├── lib.rs                      # Library entry point
│   ├── mcp/
│   │   ├── mod.rs                  # MCP module
│   │   ├── server.rs               # MCP server implementation
│   │   ├── protocol.rs             # MCP protocol types
│   │   └── handlers.rs             # Tool request handlers
│   ├── proto/
│   │   ├── mod.rs                  # Proto parsing module
│   │   ├── parser.rs               # Proto file parser using prost
│   │   ├── analyzer.rs             # Proto schema analysis
│   │   ├── metadata.rs             # Custom option extraction
│   │   └── types.rs                # Internal type representation
│   ├── generators/
│   │   ├── mod.rs                  # Generator registry
│   │   ├── registry.rs             # Language generator registry
│   │   └── swift/
│   │       ├── mod.rs              # Swift generator module
│   │       ├── contracts.rs        # Swift contract generation
│   │       ├── clients.rs          # Swift client generation
│   │       ├── naming.rs           # Swift naming conventions
│   │       └── templates.rs        # Swift template management
│   ├── templates/
│   │   └── swift/
│   │       ├── contracts/
│   │       │   ├── service.swift.tera
│   │       │   ├── message.swift.tera
│   │       │   └── enum.swift.tera
│   │       └── clients/
│   │           ├── client_actor.swift.tera
│   │           ├── action_enum.swift.tera
│   │           ├── state_struct.swift.tera
│   │           └── test_file.swift.tera
│   ├── utils/
│   │   ├── mod.rs                  # Utilities module
│   │   ├── file_manager.rs         # Swift file I/O
│   │   ├── naming.rs               # Swift naming utilities
│   │   ├── validation.rs           # Code validation utilities
│   │   └── config.rs               # Configuration management
│   ├── validation/
│   │   └── swift.rs                # Swift code validation
│   ├── testing/
│   │   └── runner.rs               # Swift test runner
│   └── error.rs                    # Error types and handling
├── tests/
│   ├── integration/
│   │   ├── swift_generation.rs     # Swift-specific tests
│   │   └── axiom_compatibility.rs  # Framework integration tests
│   ├── fixtures/
│   │   ├── proto/                  # Test proto schemas
│   │   ├── expected_swift/         # Expected Swift output
│   │   └── config/                 # Test configurations
│   └── unit/
│       ├── proto_parser.rs         # Proto parsing unit tests
│       ├── template_engine.rs      # Template engine tests
│       └── swift_naming.rs         # Swift naming convention tests
├── examples/
│   ├── task_manager/               # Complete example project
│   │   ├── proto/
│   │   └── generated/
│   │       └── swift/
│   └── user_service/               # Another example project
└── docs/
    ├── architecture.md             # Detailed architecture docs
    ├── proto_conventions.md        # Proto schema conventions
    ├── axiom_integration.md        # Axiom framework integration
    └── development.md              # Development setup guide
```

### Core Dependencies

```toml
[dependencies]
# MCP Protocol and Async Runtime
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
tokio-util = { version = "0.7", features = ["codec"] }

# Proto Parsing and gRPC
prost = "0.12"
prost-types = "0.12"
tonic = { version = "0.10", features = ["prost"] }

# Command Line Interface
clap = { version = "4.4", features = ["derive", "env"] }

# Code Generation and Templates
tera = { version = "1.19", default-features = false }
regex = "1.10"
heck = "0.4"                      # Case conversion utilities

# File System Operations
walkdir = "2.4"
tempfile = "3.8"

# Configuration and Validation
config = "0.13"
validator = { version = "0.16", features = ["derive"] }

# Logging and Diagnostics
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# Error Handling
anyhow = "1.0"
thiserror = "1.0"

[build-dependencies]
tonic-build = "0.10"
prost-build = "0.12"

[dev-dependencies]
tokio-test = "0.4"
tempfile = "3.0"
pretty_assertions = "1.4"
```

### MCP Tool Interface

```json
{
  "name": "generate_axiom_swift_clients",
  "description": "Generates Axiom-compatible Swift clients from gRPC proto definitions",
  "inputSchema": {
    "type": "object",
    "properties": {
      "proto_path": {
        "type": "string",
        "description": "Path to proto file or directory containing proto files",
        "examples": [
          "./proto/task_service.proto",
          "./proto/services/",
          "./Generated/Proto"
        ]
      },
      "output_path": {
        "type": "string", 
        "description": "Base directory to write generated Swift files",
        "examples": [
          "./Generated/Swift",
          "./Sources/Generated",
          "./TaskManager/Sources"
        ]
      },
      "services": {
        "type": "array",
        "items": {"type": "string"},
        "description": "Specific services to generate (if not specified, generates all)",
        "examples": [["TaskService", "UserService"]]
      },
      "swift_config": {
        "type": "object",
        "properties": {
          "axiom_version": {
            "type": "string",
            "description": "Target Axiom Swift framework version",
            "default": "latest"
          },
          "client_suffix": {
            "type": "string", 
            "description": "Suffix for generated client classes",
            "default": "Client"
          },
          "generate_tests": {
            "type": "boolean",
            "description": "Generate XCTest files",
            "default": true
          },
          "package_name": {
            "type": "string",
            "description": "Swift package name for imports"
          },
          "module_imports": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Additional module imports",
            "default": ["AxiomCore", "AxiomArchitecture"]
          }
        }
      },
      "generation_options": {
        "type": "object",
        "properties": {
          "generate_contracts": {
            "type": "boolean",
            "description": "Generate contract/model files",
            "default": true
          },
          "generate_clients": {
            "type": "boolean", 
            "description": "Generate Axiom client actors",
            "default": true
          },
          "force_overwrite": {
            "type": "boolean",
            "description": "Overwrite existing files without confirmation",
            "default": false
          },
          "include_documentation": {
            "type": "boolean",
            "description": "Include comprehensive code documentation",
            "default": true
          },
          "style_guide": {
            "type": "string",
            "enum": ["axiom", "swift-standard", "custom"],
            "description": "Code style guide to follow",
            "default": "axiom"
          }
        }
      }
    },
    "required": ["proto_path", "output_path"]
  }
}
```

---

## Implementation Plan

### Phase 1: Foundation & Enhanced Swift Generation (Week 1)

#### 1.1 Framework Analysis & Template Updates
**Duration**: 2 days
**Deliverables**:
- [x] Complete analysis of existing Axiom Apple framework patterns
- [ ] Update Swift templates to match existing framework conventions
- [ ] Align client actor generation with `AxiomClient` protocol
- [ ] Update state generation to follow `AxiomState` patterns

**Acceptance Criteria**:
- Generated clients conform to existing Axiom Apple framework patterns
- Templates generate code that compiles with existing framework
- Actor isolation and concurrency patterns match framework expectations

#### 1.2 Enhanced Proto Integration
**Duration**: 3 days
**Deliverables**:
- [ ] Custom proto options for Axiom-specific metadata
- [ ] Enhanced proto parsing for Axiom conventions
- [ ] State update strategy extraction from proto annotations
- [ ] Action mapping optimization for Axiom patterns

**Acceptance Criteria**:
- Proto parser extracts Axiom-specific options correctly
- State update strategies are properly mapped to generated code
- Action generation follows Axiom naming and structure conventions

### Phase 2: Advanced Axiom Integration (Week 2)

#### 2.1 Client Actor Generation
**Duration**: 3 days
**Deliverables**:
- [ ] Actor-based client generation with proper isolation
- [ ] `AsyncStream` state streaming implementation
- [ ] Lifecycle hook integration (`stateWillUpdate`, `stateDidUpdate`)
- [ ] Error handling with `AxiomError` types

**Acceptance Criteria**:
- Generated actors properly implement `AxiomClient` protocol
- State streaming works with multiple observers
- Error handling integrates with existing error types
- Performance meets Axiom framework requirements (<5ms state updates)

#### 2.2 State Management Integration
**Duration**: 2 days
**Deliverables**:
- [ ] Immutable state struct generation
- [ ] State update methods following functional patterns
- [ ] Computed properties for derived state
- [ ] Equatable and Hashable conformance

**Acceptance Criteria**:
- All state structs conform to `AxiomState` protocol
- State updates are immutable and type-safe
- Generated code follows Swift value semantics
- Performance optimizations for large state objects

### Phase 3: Testing & Quality Assurance (Week 3)

#### 3.1 Comprehensive Testing Framework
**Duration**: 2 days
**Deliverables**:
- [x] **Test Infrastructure Setup**: Complete test organization with unit, integration, and fixtures
- [x] **Unit Test Suite**: 8 comprehensive test modules covering all core components
- [x] **Test Fixtures**: Proto files, expected Swift outputs, and configuration files  
- [x] **Test Helpers**: Utilities for consistent test setup and data management
- [ ] Integration tests with real Axiom Apple framework
- [ ] Generated code compilation verification
- [ ] End-to-end workflow testing (proto → Swift → framework)
- [ ] Performance benchmarking

**Acceptance Criteria**:
- [x] Comprehensive unit test coverage for all core components
- [x] Test fixtures provide realistic test data scenarios
- [x] Test helpers enable consistent and maintainable testing
- [ ] All generated code compiles without errors
- [ ] Integration tests pass with existing framework
- [ ] Performance meets established benchmarks
- [ ] Memory usage is optimized for iOS/macOS deployment

**Test Infrastructure Completed**:
✅ **Unit Tests**: Proto parsing, Swift generation, template engine, naming conventions, config management, error handling, validation, file management  
✅ **Fixtures**: Task service proto, user service proto, expected Swift client/state/action files, test configurations  
✅ **Helpers**: Mock data generators, test utilities, assertion helpers  
✅ **Organization**: Clear separation of unit, integration, and fixture testing

#### 3.2 Developer Experience Optimization
**Duration**: 3 days
**Deliverables**:
- [ ] Enhanced error messages and validation
- [ ] Improved CLI interface for development workflow
- [ ] Documentation generation for generated code
- [ ] Example projects and tutorials

**Acceptance Criteria**:
- Error messages are actionable and helpful
- CLI provides clear feedback on generation process
- Generated documentation is comprehensive
- Examples demonstrate best practices

### Phase 4: Polish & Production Readiness (Week 4)

#### 4.1 MCP Integration Refinement
**Duration**: 2 days
**Deliverables**:
- [ ] Optimized MCP protocol handling
- [ ] Enhanced Claude Code integration
- [ ] Improved progress reporting
- [ ] Configuration validation

**Acceptance Criteria**:
- MCP tool works seamlessly in Claude Code
- Progress reporting provides meaningful feedback
- Configuration errors are caught early
- Tool integration feels native to Claude Code workflow

#### 4.2 Release Preparation
**Duration**: 2 days
**Deliverables**:
- [ ] Complete documentation suite
- [ ] Release packaging and distribution
- [ ] Version management system
- [ ] Migration guides from previous versions

**Acceptance Criteria**:
- Documentation enables rapid adoption
- Release artifacts are properly packaged
- Version compatibility is maintained
- Migration path is clear for existing users

---

## Swift Code Generation Examples

### Generated Client Actor

```swift
// Generated from TaskService proto
import Foundation
import AxiomCore
import AxiomArchitecture

@globalActor
public actor TaskClient: AxiomClient {
    public typealias StateType = TaskState
    public typealias ActionType = TaskAction
    
    private var _state: TaskState
    private let apiClient: TaskServiceClient
    private var streamContinuations: [UUID: AsyncStream<TaskState>.Continuation] = [:]
    
    public init(apiClient: TaskServiceClient, initialState: TaskState = TaskState()) {
        self._state = initialState
        self.apiClient = apiClient
    }
    
    public var stateStream: AsyncStream<TaskState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
                continuation.onTermination = { [weak self, id] _ in
                    Task { await self?.removeContinuation(id: id) }
                }
            }
        }
    }
    
    public func process(_ action: TaskAction) async throws {
        let oldState = _state
        
        let newState = try await processAction(action, currentState: _state)
        
        guard newState != oldState else { return }
        
        await stateWillUpdate(from: oldState, to: newState)
        _state = newState
        
        // Notify observers
        for (_, continuation) in streamContinuations {
            continuation.yield(newState)
        }
        
        await stateDidUpdate(from: oldState, to: newState)
    }
    
    private func processAction(_ action: TaskAction, currentState: TaskState) async throws -> TaskState {
        switch action {
        case .createTask(let request):
            let task = try await apiClient.createTask(request)
            return currentState.addingTask(task)
            
        case .loadTasks:
            let response = try await apiClient.getTasks(.init())
            return currentState.withTasks(response.tasks)
            
        case .updateTask(let taskId, let request):
            let updatedTask = try await apiClient.updateTask(request)
            return currentState.updatingTask(updatedTask)
            
        case .deleteTask(let taskId):
            try await apiClient.deleteTask(.init(id: taskId))
            return currentState.removingTask(withId: taskId)
        }
    }
    
    public func getCurrentState() async -> TaskState {
        return _state
    }
    
    public func rollbackToState(_ state: TaskState) async {
        _state = state
        for (_, continuation) in streamContinuations {
            continuation.yield(state)
        }
    }
}
```

### Generated State Struct

```swift
// Generated from proto messages
import Foundation
import AxiomCore

public struct TaskState: AxiomState {
    public let tasks: [Task]
    public let isLoading: Bool
    public let error: Error?
    public let lastUpdated: Date
    
    public init(
        tasks: [Task] = [],
        isLoading: Bool = false,
        error: Error? = nil,
        lastUpdated: Date = Date()
    ) {
        self.tasks = tasks
        self.isLoading = isLoading
        self.error = error
        self.lastUpdated = lastUpdated
    }
    
    // Immutable update methods
    public func addingTask(_ task: Task) -> TaskState {
        TaskState(
            tasks: tasks + [task],
            isLoading: false,
            error: nil,
            lastUpdated: Date()
        )
    }
    
    public func withTasks(_ newTasks: [Task]) -> TaskState {
        TaskState(
            tasks: newTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date()
        )
    }
    
    public func updatingTask(_ updatedTask: Task) -> TaskState {
        let updatedTasks = tasks.map { task in
            task.id == updatedTask.id ? updatedTask : task
        }
        return TaskState(
            tasks: updatedTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date()
        )
    }
    
    public func removingTask(withId taskId: String) -> TaskState {
        TaskState(
            tasks: tasks.filter { $0.id != taskId },
            isLoading: false,
            error: nil,
            lastUpdated: Date()
        )
    }
    
    public func withLoading(_ loading: Bool) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: loading,
            error: error,
            lastUpdated: lastUpdated
        )
    }
    
    public func withError(_ error: Error?) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: false,
            error: error,
            lastUpdated: Date()
        )
    }
    
    // Computed properties
    public var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    public var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    public var taskCount: Int {
        tasks.count
    }
    
    public var hasError: Bool {
        error != nil
    }
}

// MARK: - Equatable & Hashable
extension TaskState {
    public static func == (lhs: TaskState, rhs: TaskState) -> Bool {
        return lhs.tasks == rhs.tasks &&
               lhs.isLoading == rhs.isLoading &&
               lhs.hasError == rhs.hasError
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tasks)
        hasher.combine(isLoading)
        hasher.combine(hasError)
    }
}
```

### Generated Action Enum

```swift
// Generated from proto service methods
import Foundation

public enum TaskAction: Sendable {
    case createTask(CreateTaskRequest)
    case loadTasks
    case updateTask(String, UpdateTaskRequest)
    case deleteTask(String)
}

// MARK: - Action Validation
extension TaskAction {
    public var isValid: Bool {
        switch self {
        case .createTask(let request):
            return !request.title.isEmpty
        case .updateTask(let taskId, let request):
            return !taskId.isEmpty
        case .deleteTask(let taskId):
            return !taskId.isEmpty
        case .loadTasks:
            return true
        }
    }
    
    public var validationErrors: [String] {
        switch self {
        case .createTask(let request):
            var errors: [String] = []
            if request.title.isEmpty {
                errors.append("Title cannot be empty")
            }
            return errors
        case .updateTask(let taskId, _):
            return taskId.isEmpty ? ["Task ID cannot be empty"] : []
        case .deleteTask(let taskId):
            return taskId.isEmpty ? ["Task ID cannot be empty"] : []
        case .loadTasks:
            return []
        }
    }
}

// MARK: - Action Metadata
extension TaskAction {
    public var requiresNetworkAccess: Bool {
        switch self {
        case .createTask, .loadTasks, .updateTask, .deleteTask:
            return true
        }
    }
    
    public var modifiesState: Bool {
        switch self {
        case .createTask, .updateTask, .deleteTask, .loadTasks:
            return true
        }
    }
    
    public var actionName: String {
        switch self {
        case .createTask:
            return "createTask"
        case .loadTasks:
            return "loadTasks"
        case .updateTask:
            return "updateTask"
        case .deleteTask:
            return "deleteTask"
        }
    }
}
```

---

## Success Metrics & KPIs

### Technical Metrics
- **Generation Success Rate**: >99.5%
- **Average Generation Time**: <2 seconds for typical schemas
- **Memory Usage**: <256MB peak for large schemas
- **Test Coverage**: >95% unit, >90% integration
- **Swift Compilation Success**: 100%

### Developer Experience Metrics
- **Installation Success**: >98%
- **First Generation Success**: >95%
- **Error Resolution Time**: <5 minutes average
- **Framework Integration**: Perfect compatibility with Axiom Apple framework

### Business Impact Metrics
- **Boilerplate Reduction**: >90% for Swift client implementation
- **Development Time Savings**: >70% for client integration
- **Code Quality**: Measured by reduced defect rates
- **Framework Consistency**: 100% pattern compliance

---

## Deployment Strategy

### Primary Deployment: Claude Code MCP Integration

```json
{
  "mcpServers": {
    "axiom-swift-client-generator": {
      "command": "axiom-swift-client-generator",
      "args": ["--mcp-server"],
      "env": {
        "RUST_LOG": "info",
        "AXIOM_TEMPLATE_PATH": "./templates"
      }
    }
  }
}
```

### Secondary Deployment: Standalone CLI

```bash
# Installation
cargo install axiom-swift-client-generator

# Usage
axiom-generate-swift-clients \
  --proto ./proto/task_service.proto \
  --output ./Sources/Generated \
  --axiom-version latest \
  --generate-tests
```

---

## Conclusion

This revised plan focuses the Axiom client generator specifically on Swift integration with the existing Axiom Apple framework. By eliminating multi-language complexity and concentrating on perfect Swift framework integration, we create a more focused and powerful tool.

The Swift-only approach allows for:
- **Deeper Integration**: Perfect compatibility with existing Axiom Apple patterns
- **Better Performance**: Optimized specifically for Swift development workflows
- **Enhanced Developer Experience**: Tailored to Swift and iOS/macOS development practices
- **Simplified Maintenance**: Single language focus reduces complexity and maintenance burden

Success will be measured by seamless integration with the existing Axiom Apple framework, significant reduction in Swift client boilerplate, and enhanced developer productivity for iOS/macOS application development.