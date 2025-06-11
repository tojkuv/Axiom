# REQUIREMENTS-W-07-001: Unidirectional Flow Validation

## Purpose

Establish comprehensive compile-time and runtime validation mechanisms for enforcing the Axiom framework's strict unidirectional dependency flow, ensuring architectural integrity across all component types.

## Core Requirements

### 1. Dependency Flow Hierarchy

#### 1.1 Component Hierarchy Levels
- **Level 0**: Orchestrator (highest)
- **Level 1**: Context
- **Level 2**: Client  
- **Level 3**: Capability (lowest)
- **Special Components**: State, Presentation (restricted dependencies)

#### 1.2 Flow Rules
- Dependencies must flow downstream only (higher level → lower level)
- No circular dependencies permitted
- No reverse dependencies allowed
- State components: zero dependencies (pure value types)
- Presentation components: depend only on Context

### 2. Compile-Time Validation

#### 2.1 Protocol-Based Validation
```swift
protocol DependencyValidatable {
    static var componentType: ComponentType { get }
}
```

#### 2.2 Validation Token System
- Generate validation tokens for valid dependencies
- Trigger compile-time errors for invalid dependencies
- Provide clear error messages with architectural guidance

#### 2.3 Build Script Integration
- Generate compile-time assertions for CI/CD pipelines
- Validate module imports match dependency rules
- Prevent compilation of architecturally invalid code

### 3. Runtime Validation

#### 3.1 Dependency Analyzer
- Validate dependency graphs at runtime
- Detect cycles using topological sort
- Provide detailed violation reports

#### 3.2 Graph Analysis Features
- Cycle detection with path visualization
- Topological sorting for initialization order
- Dependency graph visualization for debugging

#### 3.3 Performance Optimization
- O(1) dependency validation lookup
- Cached validation results
- Minimal runtime overhead

### 4. Error Reporting

#### 4.1 Error Message Requirements
- Component-specific error messages
- Architectural guidance in errors
- Suggested fixes for common violations

#### 4.2 Violation Categories
- Reverse dependencies
- Circular dependencies
- Invalid component dependencies
- State/Presentation violations

### 5. Integration Points

#### 5.1 Macro System Integration
- Validate dependencies in generated code
- Enforce rules during macro expansion
- Generate validation code automatically

#### 5.2 Testing Framework Integration
- Validate test doubles follow same rules
- Ensure mock objects maintain flow integrity
- Generate architectural compliance tests

### 6. Special Cases

#### 6.1 Client-State Relationship
- Client owns State (allowed)
- State cannot depend on Client
- Validate ownership semantics

#### 6.2 Context-Presentation Binding
- Context provides data to Presentation
- Presentation cannot directly depend on Context
- Binding validation through protocol conformance

## Success Criteria

1. **Zero Architectural Violations**: No unidirectional flow violations in production code
2. **Compile-Time Detection**: 100% of violations caught at compile time
3. **Clear Error Messages**: Developer can fix violations without documentation lookup
4. **Performance**: < 1ms validation overhead per dependency check
5. **Coverage**: All component types validated consistently

## Implementation Priority

1. Core validation engine with hierarchy rules
2. Compile-time validation protocol
3. Runtime analyzer with cycle detection
4. Macro system integration
5. Build script generation
6. Performance optimization

## Dependencies

- ComponentType enumeration (PROVISIONER)
- DependencyRules system (PROVISIONER)
- Macro infrastructure (WORKER-07-004)
- Error handling framework (PROVISIONER)

## Validation Examples

### Valid Dependencies
```
Orchestrator → Context ✓
Context → Client ✓
Client → Capability ✓
Client → State ✓ (ownership)
Context → Presentation ✓ (binding)
```

### Invalid Dependencies
```
Capability → Client ✗ (reverse flow)
Context → Orchestrator ✗ (reverse flow)
State → Client ✗ (value type restriction)
Presentation → Client ✗ (must go through Context)
Client → Client ✗ (isolation requirement)
```