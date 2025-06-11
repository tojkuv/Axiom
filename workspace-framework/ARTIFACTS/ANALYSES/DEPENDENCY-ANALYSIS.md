# Axiom Framework Dependency Analysis

## Architecture Overview

The Axiom Framework follows a strict unidirectional flow architecture with clear dependency boundaries:

```
Orchestrator → Context → Client → Capability → System
```

## Component Layers

### 1. FOUNDATIONAL LAYER (PROVISIONER)
These components must exist first as they form the core infrastructure:

#### Core Protocols & Types
- **State Protocol** (`StateOwnership.swift`)
  - Foundational protocol for all state types
  - No dependencies on other Axiom components
  - Required by: Client, Context

- **ComponentType Enum** (`ComponentType.swift`)
  - Defines the six core component types
  - No dependencies
  - Used throughout the framework for validation

- **Lifecycle Protocol** (`Context.swift`)
  - Universal lifecycle management
  - No dependencies
  - Implemented by: Context, Capability

#### Actor-Based Components
- **Capability Protocol** (`Capability.swift`)
  - Manages external system access
  - Dependencies: Foundation only
  - Required by: Client (for external operations)

- **Client Protocol** (`Client.swift`)
  - Core state management protocol
  - Dependencies: State protocol
  - Required by: Context

#### Error Infrastructure
- **AxiomError Hierarchy** (`ErrorHandling.swift`)
  - Unified error system
  - Dependencies: Foundation only
  - Used by: All components for error propagation

### 2. INTEGRATION LAYER (PROVISIONER/WORKER)
Components that connect foundational elements:

#### Context System
- **Context Protocol** (`Context.swift`)
  - MainActor-bound coordinator
  - Dependencies: Client, State, Lifecycle
  - Required by: Presentation, Orchestrator

- **AutoObservingContext** (`AutoObservingContext.swift`)
  - Automatic state observation
  - Dependencies: Context, Client
  - Provides: Simplified context implementation

#### Presentation System
- **PresentationProtocol** (`PresentationProtocol.swift`)
  - View-Context binding protocol
  - Dependencies: Context, SwiftUI
  - Required by: All UI components

### 3. FEATURE LAYER (WORKER)
Independent features that can be developed in parallel:

#### Navigation System
- **NavigationCore** (`NavigationCore.swift`)
- **NavigationService** (`NavigationService.swift`)
- **NavigationFlowManager** (`NavigationFlowManager.swift`)
- **TypeSafeRoute** (`TypeSafeRoute.swift`)
- Dependencies: Context, Orchestrator protocols
- Can be developed independently

#### State Management Features
- **UnidirectionalFlow** (`UnidirectionalFlow.swift`)
- **StateOptimization** (`StateOptimization.swift`)
- **StateImmutability** (`StateImmutability.swift`)
- **MutationDSL** (`MutationDSL.swift`)
- Dependencies: State, Client protocols
- Can be developed independently

#### Persistence System
- **PersistenceCapability** (`PersistenceCapability.swift`)
- **StorageAdapter** (`StorageAdapter.swift`)
- Dependencies: Capability protocol
- Can be developed independently

#### Error Handling Features
- **ErrorBoundaries** (`ErrorBoundaries.swift`)
- **ErrorPropagation** (`ErrorPropagation.swift`)
- Dependencies: Error infrastructure, Context
- Can be developed independently

#### Form Utilities
- **FormBindingUtilities** (`FormBindingUtilities.swift`)
- Dependencies: Context, SwiftUI
- Can be developed independently

### 4. ORCHESTRATION LAYER (STABILIZER)
High-level coordination requiring all components:

#### Core Orchestration
- **Orchestrator Protocol** (`Orchestrator.swift`)
- Dependencies: All foundational components
- Requires: Context, Client, Capability, Navigation

#### Advanced Patterns
- **DAGComposition** (`DAGComposition.swift`)
- **DependencyRules** (`DependencyRules.swift`)
- **ContextLifecycleManagement** (`ContextLifecycleManagement.swift`)
- Dependencies: Full framework
- Requires: Complete integration

#### Capability Patterns
- **CapabilityCompositionPatterns** (`CapabilityCompositionPatterns.swift`)
- **ExtendedCapabilityPatterns** (`ExtendedCapabilityPatterns.swift`)
- Dependencies: Capability + specific system frameworks
- Requires: Platform integration

### 5. MACRO LAYER (PROVISIONER)
Build-time code generation:

#### Macro Definitions
- **Macros** (`Macros.swift`)
- **AxiomMacros** (separate module)
- Dependencies: SwiftSyntax
- Required by: Enhanced developer experience

## Testing Infrastructure

### Core Testing Support
- **AxiomTesting** (separate module)
- Dependencies: Axiom framework
- Provides: Test helpers, mocks, assertions

### Test Categories
1. **Unit Tests** - Component isolation
2. **Integration Tests** - Component interaction
3. **Performance Tests** - Benchmarking
4. **API Consistency Tests** - Naming validation

## Dependency Rules

1. **No Circular Dependencies**: Enforced by `UnidirectionalFlow`
2. **Actor Isolation**: Client and Capability are actors
3. **MainActor Binding**: Context and UI components
4. **Protocol-Based**: All core components are protocols
5. **Value Types**: State must be structs
6. **Sendable Conformance**: Required for concurrency

## Development Priorities

### Phase 1: PROVISIONER (Foundational)
1. Core protocols (State, Client, Capability)
2. Error infrastructure
3. Component type definitions
4. Basic Context implementation

### Phase 2: WORKER (Features)
1. Navigation system
2. State management utilities
3. Persistence capability
4. Form bindings

### Phase 3: STABILIZER (Integration)
1. Orchestrator implementation
2. Dependency resolution
3. Lifecycle management
4. Advanced patterns

## Key Insights

1. **Clean Separation**: Each layer has clear dependencies
2. **Parallel Development**: Feature layer components can be developed independently
3. **Type Safety**: Enforced through protocols and generics
4. **Concurrency Safe**: Actor-based design throughout
5. **Testable**: Protocol-based design enables mocking