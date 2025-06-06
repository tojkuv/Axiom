# RFC Format Standards

RFC specifications for TDD-driven test application development.

## RFC Structure

### Metadata Header
```markdown
# RFC-XXX: [Title]

**RFC Number**: XXX  
**Title**: [Test application name]  
**Status**: Draft | Proposed | Active  
**Type**: Test App | Integration Test | Performance Test  
**Created**: YYYY-MM-DD  
**Updated**: YYYY-MM-DD  
**Purpose**: [Framework aspects being tested]
```

### 1. Abstract
```markdown
## Abstract

[1-2 paragraphs, max 200 words]
[Paragraph 1: What test app this RFC creates and which Axiom patterns it validates]
[Paragraph 2: Key user stories and expected test outcomes]
```

### 2. Motivation
```markdown
## Motivation

### Framework Testing Goals
[What aspects of Axiom need validation through this test app]

### Test Scenarios
1. [Scenario 1]: [What framework behavior to verify]
2. [Scenario 2]: [What edge case to test]
```

### 3. Specification
```markdown
## Specification

### Requirements

#### Domain Model
- [Client Name]:
  - Requirement: Actor-based Client with [State] management
  - Acceptance: Client initializes and processes actions within 50ms
  - Boundary: Single State type ownership, actor-isolated mutations
  - Refactoring: Extract common Client patterns if multiple similar Clients

- [State Type]:
  - Requirement: Immutable value type with Equatable conformance
  - Acceptance: State updates create new instances, equality checks work
  - Boundary: All properties are let-declared
  - Refactoring: Consider Codable for persistence scenarios

#### User Story 1: [Story Name]
- [Feature Name]:
  - Requirement: [What the user can do]
  - Acceptance: [Measurable user-observable behavior]
  - Boundary: [UI constraints and edge cases]
  - Refactoring: [Future enhancements]

#### User Story 2: [Story Name]
- [Feature Name]:
  - Requirement: [What the user can do]
  - Acceptance: [Measurable user-observable behavior]
  - Boundary: [UI constraints and edge cases]
  - Refactoring: [Future enhancements]

#### Navigation
- Route Handling:
  - Requirement: Type-safe navigation through Orchestrator
  - Acceptance: All navigation completes within 250ms
  - Boundary: Context mediates all navigation requests
  - Refactoring: Add deep linking if testing URL handling

#### Performance
- State Propagation:
  - Requirement: State changes reflect in UI within one frame
  - Acceptance: Updates complete in < 16ms on iPhone 12
  - Boundary: Test with up to 1000 state items
  - Refactoring: Implement batching if updates exceed 16ms
```

### 4. Test Strategy
```markdown
## Test Strategy

### Unit Tests
- [Client]: Test actor isolation and state mutations
- [Context]: Test lifecycle and Client observation

### UI Tests  
- [Story 1]: End-to-end user flow validation
- [Story 2]: Cross-story state consistency

### Performance Tests
- State propagation: Measure update latency
- Memory usage: Profile component overhead
- Concurrent operations: Stress test actor system
```

### 5. API Design
```markdown
## API Design

### Domain Interfaces
```swift
actor [ClientName]: Client {
    typealias StateType = [StateName]
    typealias ActionType = [ActionEnum]
    
    var stateStream: AsyncStream<StateType> { get }
    func process(_ action: ActionType) async throws
}

struct [StateName]: State, Equatable {
    // Immutable properties
}

enum [ActionEnum] {
    case action1(param: Type)
    case action2
}
```

### Navigation Routes
```swift
enum AppRoute {
    case story1Home
    case story1Detail(id: String)
    case story2Screen
}
```

### 6. TDD Implementation Checklist
```markdown
## TDD Implementation Checklist

**Last Updated**: YYYY-MM-DD HH:MM
**Current Focus**: [Active requirement]
**Session Notes**: [Current blockers or decisions]

### Domain Model
- [ ] [Client Name] (from Specification)
  - [ ] Red: Test Client actor initialization fails
  - [ ] Green: Implement minimal Client conforming to protocol
  - [ ] Refactor: Extract common actor patterns
- [ ] [State Type] (from Specification)
  - [ ] Red: Test state mutability fails
  - [ ] Green: Implement immutable State struct
  - [ ] Refactor: Optimize Equatable performance

### User Story 1: [Story Name]
- [ ] [Feature Name] (from Specification)
  - [ ] Red: Test acceptance criteria fails
  - [ ] Green: Implement minimal working feature
  - [ ] Refactor: Improve code organization
- [ ] Context-Client Integration
  - [ ] Red: Test Context cannot observe Client
  - [ ] Green: Wire up AsyncStream observation
  - [ ] Refactor: Optimize memory usage

### User Story 2: [Story Name]
- [ ] [Feature Name] (from Specification)
  - [ ] Red: Test cross-story state fails
  - [ ] Green: Implement using shared Client
  - [ ] Refactor: Consolidate patterns

### Performance Requirements
- [ ] State Propagation (from Specification)
  - [ ] Red: Test exceeds 16ms threshold
  - [ ] Green: Optimize update path
  - [ ] Refactor: Implement batching if needed
```

## Key Principles

1. **Test-First Design**: Every requirement starts with a failing test
2. **Specification-Driven**: All features defined in Specification section
3. **Measurable Acceptance**: Quantifiable criteria for each requirement
4. **Framework Validation**: Focus on testing Axiom patterns
5. **Rapid Implementation**: Minimal code to validate framework behavior

---

**This format enables systematic TDD-driven test application development.**