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

#### UI Components
- [Context Name]:
  - Requirement: @MainActor class mediating Client-Presentation interaction
  - Acceptance: Context observes Client state changes within 16ms
  - Boundary: Single Client ownership, manages presentation lifecycle
  - Refactoring: Extract common Context patterns if multiple similar Contexts

- [Presentation Name]:
  - Requirement: SwiftUI View bound to Context for state display
  - Acceptance: UI updates reflect state changes within one frame
  - Boundary: Read-only state access, actions dispatched through Context
  - Refactoring: Extract reusable view components

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

#### Navigation & Orchestration
- Orchestrator:
  - Requirement: MainActor-bound coordinator managing app-wide navigation
  - Acceptance: Creates and manages Context lifecycle properly
  - Boundary: Single source of truth for navigation state
  - Refactoring: Add coordinator pattern if complex navigation

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
- [Orchestrator]: Test navigation flow and Context management
- [State]: Test immutability and Equatable conformance

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

### UI Interfaces
```swift
@MainActor
class [ContextName]: Context<[ClientName]> {
    // Context manages Client lifecycle and state observation
    override func observeClient() {
        // Set up AsyncStream observation
    }
}

struct [PresentationName]: View {
    @ObservedObject var context: [ContextName]
    
    var body: some View {
        // UI bound to context.currentState
    }
}
```

### Navigation Routes
```swift
enum AppRoute {
    case story1Home
    case story1Detail(id: String)
    case story2Screen
}

@MainActor
class AppOrchestrator: Orchestrator {
    func navigate(to route: AppRoute) {
        // Handle navigation and Context creation
    }
}
```

### 6. TDD Implementation Checklist
```markdown
## TDD Implementation Checklist

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
- [ ] [Context Name] (from UI Components)
  - [ ] Red: Test Context cannot observe Client
  - [ ] Green: Wire up AsyncStream observation
  - [ ] Refactor: Optimize memory usage
- [ ] [Presentation Name] (from UI Components)
  - [ ] Red: Test View cannot display state
  - [ ] Green: Bind View to Context
  - [ ] Refactor: Extract reusable components

### User Story 2: [Story Name]
- [ ] [Feature Name] (from Specification)
  - [ ] Red: Test cross-story state fails
  - [ ] Green: Implement using shared Client
  - [ ] Refactor: Consolidate patterns
- [ ] Navigation Integration
  - [ ] Red: Test orchestrator navigation fails
  - [ ] Green: Implement route handling
  - [ ] Refactor: Optimize Context lifecycle

### Performance Requirements
- [ ] State Propagation (from Specification)
  - [ ] Red: Test exceeds 16ms threshold
  - [ ] Green: Optimize update path
  - [ ] Refactor: Implement batching if needed

### Orchestration
- [ ] AppOrchestrator (from Navigation)
  - [ ] Red: Test app startup fails
  - [ ] Green: Implement basic orchestrator
  - [ ] Refactor: Add proper error handling
- [ ] Context Lifecycle
  - [ ] Red: Test Context memory leaks
  - [ ] Green: Proper cleanup on navigation
  - [ ] Refactor: Optimize Context reuse
```

### 7. Session Notes
```markdown
## Session Notes

### Session Log
[Reverse chronological order - newest first]

#### YYYY-MM-DD HH:MM
- **Progress**: [What was completed this session]
- **Decisions**: [Key decisions made]
- **Blockers**: [Issues encountered]
- **Next Steps**: [What to tackle next session]

#### YYYY-MM-DD HH:MM
- **Progress**: [Previous session work]
- **Decisions**: [Previous decisions]
- **Blockers**: [Previous issues]
- **Next Steps**: [Previous plans]

### Technical Discoveries
- [Discovery 1]: [Impact on implementation]
- [Discovery 2]: [How it changes approach]

### Deferred Items
- [Item 1]: [Why deferred and when to revisit]
- [Item 2]: [Dependencies before addressing]
```

## Key Principles

1. **Test-First Design**: Every requirement starts with a failing test
2. **Specification-Driven**: All features defined in Specification section
3. **Measurable Acceptance**: Quantifiable criteria for each requirement
4. **Framework Validation**: Focus on testing Axiom patterns
5. **Rapid Implementation**: Minimal code to validate framework behavior

---

**This format enables systematic TDD-driven test application development.**