# Axiom Universal Client Generator

A Rust-based MCP (Model Context Protocol) tool that generates framework-compatible client code directly from gRPC proto definitions for multiple target languages.

## Features

- **Proto-First Architecture**: gRPC proto as the single source of truth
- **Multi-Language Support**: Generate Swift, Kotlin, and TypeScript clients
- **Framework Integration**: Perfect integration with Axiom frameworks
- **MCP Integration**: Works seamlessly with Claude Code
- **Fast Generation**: Rust-powered performance for enterprise-scale schemas

## Project Status

### ✅ Phase 1 Complete (Foundation & Proto Parser)
- [x] Rust workspace with multi-language support structure
- [x] Cargo.toml with all dependencies including prost/tonic
- [x] Basic MCP server framework
- [x] Development environment setup
- [x] prost-based proto file parser
- [x] Proto AST representation for services and messages
- [x] Custom option metadata extraction
- [x] Multi-language file management system

### 🚧 In Progress
- Swift contract generation
- Swift client generation
- Kotlin contract generation
- Kotlin client generation

### 📋 Planned
- TypeScript support
- Advanced proto features
- Performance optimization
- Comprehensive testing
- Claude Code integration
- Documentation & examples

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                             │
│  ┌─────────────────────────────────────────────────────────────┤
│  │ Developer: "Generate clients for TaskService proto"        │
│  │ Claude: Calls generate_axiom_clients MCP tool              │
│  └─────────────────────────────────────────────────────────────┤
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼ MCP Protocol (JSON-RPC over stdio)
┌─────────────────────────────────────────────────────────────────┐
│         Axiom Universal Client Generator (Rust MCP Server)     │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Proto Parser    │  │ Language        │  │ Template        │  │
│  │                 │  │ Generator       │  │ Engine          │  │
│  │ • prost/tonic   │──│ Registry        │──│                 │  │
│  │ • Schema parse  │  │                 │  │ • Swift gen     │  │
│  │ • Metadata ext  │  │ • Swift codegen │  │ • Kotlin gen    │  │
│  │ • Type analysis │  │ • Kotlin codegen│  │ • TypeScript    │  │
│  └─────────────────┘  │ • Future langs  │  │ • Custom rules  │  │
│                       └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### As MCP Server (Claude Code Integration)

1. Add to your MCP configuration:
```json
{
  "mcpServers": {
    "axiom-universal-client-generator": {
      "command": "axiom-universal-client-generator",
      "args": ["--mcp-server"],
      "env": {
        "RUST_LOG": "info"
      }
    }
  }
}
```

2. Use in Claude Code:
```
Generate Swift and Kotlin clients for the proto files in ./proto/task_service.proto, 
output to ./Generated/Clients
```

### As CLI Tool

```bash
# Generate Swift clients
axiom-universal-client-generator generate \
  --proto-path ./proto/task_service.proto \
  --output-path ./Generated \
  --languages swift \
  --swift-framework-version latest \
  --generate-tests

# Generate multiple languages
axiom-universal-client-generator generate \
  --proto-path ./proto/ \
  --output-path ./Generated \
  --languages swift,kotlin \
  --force-overwrite
```

## Generated Output Structure

```
Generated/
├── swift/
│   ├── Contracts/
│   │   ├── TaskService.swift     # Proto messages and enums
│   │   └── ...
│   └── Clients/
│       ├── TaskClient.swift      # Axiom client actor
│       ├── TaskAction.swift      # Action enum
│       ├── TaskState.swift       # State struct
│       └── TaskClientTests.swift # XCTest files
└── kotlin/
    ├── Contracts/
    │   ├── TaskService.kt        # Data classes and enums
    │   └── ...
    └── Clients/
        ├── TaskClient.kt         # Axiom client class
        ├── TaskAction.kt         # Sealed action class
        ├── TaskState.kt          # State data class
        └── TaskClientTests.kt    # Test files
```

## Example Generated Swift Client

```swift
@globalActor
public actor TaskClient: AxiomObservableClient<TaskState, TaskAction> {
    private let apiClient: TaskServiceClient
    
    public init(apiClient: TaskServiceClient) {
        self.apiClient = apiClient
        super.init(initialState: TaskState())
    }
    
    public func process(_ action: TaskAction) async throws {
        switch action {
        case .createTask(let request):
            updateState { $0.isLoading = true }
            do {
                let task = try await apiClient.createTask(request)
                updateState { state in
                    state.tasks.append(task)
                    state.isLoading = false
                    state.lastError = nil
                }
            } catch {
                updateState { state in
                    state.isLoading = false
                    state.lastError = error
                }
                throw error
            }
        // ... other actions
        }
    }
}
```

## MCP Tool Schema

The generator exposes the `generate_axiom_clients` tool with the following schema:

```json
{
  "name": "generate_axiom_clients",
  "description": "Generates multi-language Axiom clients from gRPC proto definitions",
  "inputSchema": {
    "type": "object",
    "properties": {
      "proto_path": {
        "type": "string",
        "description": "Path to proto file or directory containing proto files"
      },
      "output_path": {
        "type": "string", 
        "description": "Base directory to write generated files"
      },
      "target_languages": {
        "type": "array",
        "items": {"enum": ["swift", "kotlin", "typescript"]},
        "default": ["swift"]
      },
      "framework_config": {
        "type": "object",
        "properties": {
          "swift": {
            "axiom_version": "string",
            "generate_tests": "boolean"
          },
          "kotlin": {
            "framework_version": "string",
            "use_coroutines": "boolean"
          }
        }
      }
    },
    "required": ["proto_path", "output_path"]
  }
}
```

## Development

### Prerequisites
- Rust 1.70+
- Proto compiler (protoc)

### Building
```bash
cargo build --release
```

### Testing
```bash
cargo test
```

### Running as MCP Server
```bash
cargo run -- mcp-server
```

## Contributing

This project follows the comprehensive development plan outlined in [PLAN.md](PLAN.md). We're currently in Phase 1 implementation.

### Current Development Focus
1. Swift code generation completion
2. Kotlin code generation completion
3. Template system refinement
4. Integration testing

## License

MIT License - see LICENSE file for details.