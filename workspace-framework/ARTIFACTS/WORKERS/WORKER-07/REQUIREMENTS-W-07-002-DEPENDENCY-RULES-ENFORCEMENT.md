# REQUIREMENTS-W-07-002: Dependency Rules Enforcement

## Purpose

Define and enforce component-specific dependency rules that ensure architectural isolation, prevent coupling, and maintain the integrity of the Axiom framework's component model through compile-time and runtime validation.

## Core Requirements

### 1. Component-Specific Rules

#### 1.1 Capability Rules
- **Allowed**: Other Capabilities only
- **Prohibited**: All other component types
- **Rationale**: Capabilities are foundational and must remain decoupled

#### 1.2 State Rules
- **Allowed**: No dependencies (pure value types)
- **Prohibited**: All component types
- **Rationale**: States must be immutable data containers

#### 1.3 Client Rules
- **Allowed**: Capabilities only
- **Prohibited**: Other Clients, Contexts, Orchestrators
- **Rationale**: Clients must be isolated from each other

#### 1.4 Context Rules
- **Allowed**: Clients, downstream Contexts
- **Prohibited**: Capabilities, upstream Contexts, Orchestrators
- **Rationale**: Contexts bridge UI and business logic

#### 1.5 Orchestrator Rules
- **Allowed**: Contexts only
- **Prohibited**: Clients, Capabilities, States
- **Rationale**: Orchestrators coordinate at the highest level

#### 1.6 Presentation Rules
- **Allowed**: Contexts only (through binding)
- **Prohibited**: Direct dependencies on any component
- **Rationale**: Presentations are pure UI components

### 2. Validation Infrastructure

#### 2.1 Rule Matrix
```swift
// Pre-computed validation matrix for O(1) lookup
private static let validationMatrix: [[Bool]]
```

#### 2.2 Dependency Map
```swift
private static let dependencyMap: [ComponentType: Set<ComponentType>]
```

#### 2.3 Performance Requirements
- O(1) dependency validation
- Compile-time rule generation
- Zero runtime allocation for validation

### 3. DAG Composition Validation

#### 3.1 Acyclic Graph Enforcement
- Validate Capability → Capability dependencies form DAG
- Validate Context → Context dependencies form DAG
- Detect and report cycles with full path information

#### 3.2 Cycle Detection
- Use Kahn's algorithm for topological sort
- Track recursion stack for cycle path detection
- Cache validation results for performance

#### 3.3 Self-Dependency Prevention
- Explicitly check for self-references
- Provide specific error messages for self-dependencies
- Validate at both compile and runtime

### 4. Error Reporting

#### 4.1 Error Message Format
```
"[Component] cannot depend on [Target]: [Specific Reason]"
```

#### 4.2 Component-Specific Messages
- Capability: "Capabilities can only depend on other Capabilities"
- State: "States must be pure value types with no dependencies"
- Client: "Clients must be isolated from each other"
- Context: "Contexts can only depend on Clients and downstream Contexts"
- Orchestrator: "Orchestrator can only depend on Contexts"
- Presentation: "Presentations can only depend on Contexts"

### 5. Build-Time Enforcement

#### 5.1 Compile-Time Assertions
```swift
#if canImport(Component) && canImport(InvalidDependency)
#error("Dependency violation: [specific error]")
#endif
```

#### 5.2 Code Generation
- Generate validation assertions for CI/CD
- Create dependency validation tests automatically
- Produce architectural documentation from rules

### 6. Runtime Enforcement

#### 6.1 Dynamic Validation
- Validate dependencies during component registration
- Check dependency rules before initialization
- Prevent runtime violations through early detection

#### 6.2 Debug Mode Features
- Dependency graph visualization
- Rule violation highlighting
- Suggested refactoring paths

### 7. Integration Requirements

#### 7.1 Macro Integration
- Validate dependencies in macro-generated code
- Enforce rules during macro expansion
- Generate rule-compliant boilerplate

#### 7.2 Testing Integration
- Validate test doubles follow rules
- Generate rule compliance tests
- Ensure mocks maintain isolation

## Success Criteria

1. **100% Rule Coverage**: All component dependencies validated
2. **Zero False Positives**: No valid dependencies rejected
3. **Clear Diagnostics**: Actionable error messages for violations
4. **Performance**: < 0.1ms per validation check
5. **Build Integration**: Seamless CI/CD pipeline integration

## Implementation Priority

1. Core validation matrix and dependency map
2. Component-specific rule enforcement
3. DAG composition validation
4. Error message generation
5. Build-time assertion generation
6. Runtime validation hooks

## Dependencies

- ComponentType system (PROVISIONER)
- UnidirectionalFlow validation (WORKER-07-001)
- Error handling framework (PROVISIONER)
- Macro system (WORKER-07-004)

## Validation Examples

### Valid Patterns
```swift
// Capability depending on Capability
NetworkCapability → StorageCapability ✓

// Context depending on Client
TaskListContext → TaskClient ✓

// Client depending on Capability
TaskClient → PersistenceCapability ✓
```

### Invalid Patterns
```swift
// Client depending on Client
TaskClient → UserClient ✗

// Capability depending on Client
NetworkCapability → TaskClient ✗

// State depending on anything
TaskState → TaskClient ✗

// Circular Context dependency
ParentContext → ChildContext → ParentContext ✗
```