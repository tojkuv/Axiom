# Comprehensive Testing Plan - Axiom Swift Client Generator

## 🎯 Testing Strategy Overview

This document outlines the comprehensive testing strategy for the Axiom Swift Client Generator, implementing Phase 3.1 of the development plan.

## 📊 Test Coverage Requirements

### 1. Unit Tests (Target: >95% coverage)
- **Proto Parser Tests**: Verify proto file parsing accuracy
- **Template Engine Tests**: Validate Swift code generation
- **MCP Protocol Tests**: Ensure MCP compliance
- **Error Handling Tests**: Validate error scenarios
- **Naming Convention Tests**: Verify Swift naming standards

### 2. Integration Tests (Target: >90% coverage)
- **Axiom Framework Integration**: Real framework compatibility
- **End-to-End Workflows**: Proto → Swift → Compilation
- **Generated Code Validation**: Syntax and semantics
- **Performance Testing**: Speed and memory benchmarks

### 3. System Tests
- **MCP Server Testing**: Full protocol compliance
- **CLI Interface Testing**: Command-line functionality
- **Configuration Testing**: Various setup scenarios
- **Error Recovery Testing**: Graceful failure handling

## 🏗️ Test Infrastructure

### Test Environment Setup
```rust
// Test infrastructure components
pub struct TestEnvironment {
    temp_dir: TempDir,
    proto_dir: PathBuf,
    output_dir: PathBuf,
}

pub struct PerformanceMetrics {
    generation_time: Duration,
    memory_usage: u64,
    files_generated: usize,
    lines_of_code: usize,
}

pub struct SwiftCompiler {
    swift_path: String,
}
```

### Test Data Generation
- **Simple Protos**: Basic service definitions
- **Complex Protos**: Multiple services with advanced features
- **Edge Case Protos**: Unusual naming, nested messages
- **Stress Test Protos**: Large schemas for performance testing

## 🧪 Test Categories

### 1. Proto Parsing Tests
```rust
#[test]
fn test_basic_proto_parsing() {
    // Test parsing of simple proto files
}

#[test]
fn test_axiom_options_extraction() {
    // Test extraction of custom Axiom options
}

#[test]
fn test_complex_message_parsing() {
    // Test nested messages and complex types
}
```

### 2. Swift Generation Tests
```rust
#[test]
fn test_client_actor_generation() {
    // Verify generated actors conform to AxiomClient
}

#[test]
fn test_state_struct_generation() {
    // Verify immutable state patterns
}

#[test]
fn test_action_enum_generation() {
    // Verify Sendable action enums
}
```

### 3. Framework Integration Tests
```rust
#[tokio::test]
async fn test_axiom_framework_compatibility() {
    // Test with real Axiom Apple framework
}

#[tokio::test]
async fn test_async_stream_integration() {
    // Test state streaming functionality
}
```

### 4. Performance Tests
```rust
#[tokio::test]
async fn test_generation_performance() {
    // Benchmark generation speed
}

#[test]
fn test_memory_usage() {
    // Monitor memory consumption
}
```

### 5. MCP Protocol Tests
```rust
#[tokio::test]
async fn test_mcp_tool_discovery() {
    // Test tool registration and discovery
}

#[tokio::test]
async fn test_mcp_request_handling() {
    // Test request/response cycle
}
```

## ⚡ Performance Benchmarks

### Generation Speed Targets
- **Simple Service** (1 service, 3 methods): <500ms
- **Medium Project** (3 services, 10 methods each): <2s
- **Large Project** (10 services, 20 methods each): <5s
- **Stress Test** (50 services, 100 methods each): <30s

### Memory Usage Targets
- **Base Memory**: <50MB
- **During Generation**: <200MB peak
- **With Caching**: <250MB steady state

### Quality Metrics
- **Compilation Success Rate**: 100%
- **Framework Compatibility**: 100%
- **Test Coverage**: >95% unit, >90% integration

## 🔍 Test Scenarios

### Scenario 1: Basic CRUD Service
```proto
service TaskService {
  rpc CreateTask(CreateTaskRequest) returns (Task);
  rpc GetTasks(GetTasksRequest) returns (GetTasksResponse);
  rpc UpdateTask(UpdateTaskRequest) returns (Task);
  rpc DeleteTask(DeleteTaskRequest) returns (Empty);
}
```

**Expected Outputs**:
- TaskManagerClient.swift (Actor with AxiomClient conformance)
- TaskManagerState.swift (Immutable state struct)
- TaskManagerAction.swift (Sendable action enum)

### Scenario 2: Complex Authentication Service
```proto
service AuthService {
  option (axiom.service_options) = {
    client_name: "AuthenticationClient"
    state_name: "AuthState"
    action_name: "AuthAction"
    collections: [
      {name: "sessions", item_type: "UserSession"}
    ]
  };
  
  rpc Login(LoginRequest) returns (AuthResponse);
  rpc RefreshToken(RefreshRequest) returns (AuthResponse);
}
```

**Expected Outputs**:
- Full authentication flow implementation
- Session management integration
- Error handling for auth failures

### Scenario 3: Edge Cases
- Empty services
- Services with no options
- Unusual naming conventions
- Deeply nested message types
- Large numbers of methods

## 📋 Test Execution Plan

### Phase 1: Core Unit Tests
1. **Proto Parser Tests**
   - Basic parsing functionality
   - Option extraction
   - Error handling

2. **Template Engine Tests**
   - Swift code generation
   - Template variable substitution
   - Output formatting

### Phase 2: Integration Tests
1. **Framework Integration**
   - Real Axiom framework compatibility
   - Actor protocol conformance
   - State management patterns

2. **Compilation Verification**
   - Swift compiler integration
   - Generated code compilation
   - Framework linking

### Phase 3: System Tests
1. **MCP Protocol Compliance**
   - Tool discovery
   - Request/response handling
   - Progress reporting

2. **End-to-End Workflows**
   - Complete generation cycles
   - Error recovery scenarios
   - Performance validation

## 🚀 Automated Test Execution

### Continuous Integration
```yaml
name: Comprehensive Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Unit Tests
        run: cargo test --lib
      
  integration-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Swift
        run: # Swift installation
      - name: Run Integration Tests
        run: cargo test --test integration

  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Performance Tests
        run: cargo test --test performance
```

### Local Test Commands
```bash
# Run all tests
cargo test

# Run unit tests only
cargo test --lib

# Run integration tests
cargo test --test integration

# Run performance tests with release build
cargo test --release --test performance

# Run MCP protocol tests
cargo test --test mcp

# Generate test coverage report
cargo tarpaulin --out html
```

## 📊 Test Reporting

### Coverage Reports
- Line coverage >95%
- Branch coverage >90%
- Function coverage 100%

### Performance Reports
- Generation time trends
- Memory usage patterns
- Regression detection

### Quality Reports
- Compilation success rates
- Framework compatibility scores
- Error handling effectiveness

## 🔧 Test Environment Requirements

### Dependencies
```toml
[dev-dependencies]
tokio-test = "0.4"
tempfile = "3.8"
pretty_assertions = "1.4"
criterion = "0.5"  # For benchmarking
tarpaulin = "0.27" # For coverage
```

### System Requirements
- **Rust**: Latest stable
- **Swift**: 5.9+ (for compilation tests)
- **Memory**: 4GB+ for performance tests
- **Disk**: 2GB+ for test artifacts

## 💡 Testing Best Practices

### 1. Isolation
- Each test uses isolated temp directories
- No shared state between tests
- Clean environment for each test run

### 2. Determinism
- Consistent test data generation
- Reproducible performance measurements
- Fixed random seeds where applicable

### 3. Comprehensive Coverage
- All code paths tested
- Edge cases explicitly covered
- Error scenarios validated

### 4. Performance Monitoring
- Continuous benchmarking
- Regression detection
- Resource usage tracking

## 🎯 Success Criteria

### Technical Metrics
- ✅ >95% unit test coverage
- ✅ >90% integration test coverage
- ✅ 100% compilation success rate
- ✅ <5s generation time for large projects
- ✅ <250MB memory usage

### Quality Metrics
- ✅ 100% Axiom framework compatibility
- ✅ Zero critical bugs in generated code
- ✅ 100% MCP protocol compliance
- ✅ Comprehensive error handling

### Developer Experience
- ✅ Clear test failure messages
- ✅ Easy test environment setup
- ✅ Fast test execution (<5 minutes total)
- ✅ Automated CI/CD integration

## 🚧 Implementation Status

Due to current disk space constraints, the test implementation is documented but not yet executed. Once space is available, implement in this order:

1. **Test Infrastructure** (helpers.rs, fixtures/)
2. **Unit Tests** (proto parsing, template engine)
3. **Integration Tests** (framework compatibility)
4. **Performance Tests** (benchmarking)
5. **System Tests** (MCP protocol, CLI)

This comprehensive testing strategy ensures the Axiom Swift Client Generator meets all quality, performance, and compatibility requirements outlined in Phase 3.1 of the development plan.