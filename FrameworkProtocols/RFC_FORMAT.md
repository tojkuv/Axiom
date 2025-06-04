# RFC Format Standards

Shared RFC format specifications for Axiom Framework proposals.

## RFC Metadata Header

```markdown
# RFC-XXX: [Title]

**RFC Number**: XXX  
**Title**: [Descriptive title]  
**Status**: Draft | Proposed | Active | Deprecated | Superseded  
**Type**: Architecture | Feature | Process | Standards  
**Created**: YYYY-MM-DD  
**Updated**: YYYY-MM-DD  
**Authors**: [Author names]  
**Supersedes**: RFC-XXX (if applicable)  
**Superseded-By**: RFC-XXX (if applicable)
```

## RFC Document Structure

**Required Sections**:
- **Abstract**: 2-3 paragraph summary
- **Motivation**: Problem statement and need
- **Specification**: Technical requirements (bullet points preferred)
  - Constraints and invariants
  - Interface definitions
  - Performance targets
  - Acceptance criteria for each requirement
  - Test boundaries and validation approach
  - NO implementation examples
- **Rationale**: Design decisions vs alternatives
- **Backwards Compatibility**: Breaking changes impact
- **Security Considerations**: Threat model and mitigations
- **Test Strategy**: High-level testing approach (categories, not specifics)
- **References**: Related RFCs and docs
- **Appendices**: Context-specific (TDD implementation checklist, version history, etc.)

## RFC Content Guidelines

**Writing Style**:
- Use bullet points for specifications
- Keep sections concise and scannable  
- Focus on WHAT, not HOW
- Define measurable criteria

**Content Rules**:
- NO code examples
- NO implementation details
- YES to constraints and invariants
- YES to interface contracts
- YES to performance targets
- YES to acceptance criteria
- YES to test boundaries
- YES to refactoring considerations

## RFC Appendices Guide

**Common Appendices**:
- **TDD Implementation Checklist**: Task list aligned with test-driven cycles
- **Dependency Matrix**: Constraint relationships (if many constraints)
- **Version History**: Single-line entries per version
- **MVP Guide**: Phased implementation approach (if needed)
- **Acceptance Test Matrix**: Requirement-to-test mapping (if complex)

**Appendix Flexibility**:
- Each RFC determines its own appendices
- No fixed appendix structure required
- Content driven by RFC complexity and scope

## RFC Specification Writing Guide

**Use Bullet Points For**:
- Component requirements with acceptance criteria
- Constraint definitions with test assertions
- Interface contracts with test boundaries
- Performance targets with measurable metrics
- Error conditions with expected behaviors
- Test criteria and validation approaches
- Refactoring opportunities

**Example Specification Format**:
```markdown
### Component Requirements
- Must be thread-safe
  - Acceptance: Concurrent access test with 100 threads passes
- Singleton lifetime
  - Acceptance: Multiple initialization attempts return same instance
- < 50ms initialization
  - Acceptance: Performance test measures init time < 50ms
- Handles these errors:
  - NetworkUnavailable → Returns cached data or default
  - PermissionDenied → Degrades gracefully with limited features
  - ResourceExhausted → Implements backoff and retry strategy
```

**Avoid Natural Language For**:
- Technical specifications
- Measurable criteria
- Interface definitions
- Constraint lists

## TDD-Oriented RFC Example

**Specification with Acceptance Criteria**:
```markdown
### State Management Requirements
- Thread-Safe State Access:
  - Requirement: All state mutations via actor isolation
  - Acceptance: Race condition test with 1000 concurrent operations shows no data corruption
  - Boundary: Public API exposes only async methods
  
- Observable State Changes:
  - Requirement: State changes trigger observer notifications
  - Acceptance: Observer receives notification within 10ms of state change
  - Test: Mock observer validates notification timing and content
  
- State Snapshot Performance:
  - Requirement: State snapshots complete in < 5ms
  - Acceptance: Performance test measures 1000 snapshots all under 5ms
  - Refactoring: Consider copy-on-write optimization if needed
```

## RFC Examples

**Specification Example (Bullet Points)**:
```markdown
### Client Protocol Requirements
- Thread Safety:
  - Actor isolation required
  - No @MainActor methods
  - Async state mutations only
- Performance:
  - State access < 1ms
  - Memory < 512 bytes overhead
  - Concurrent operations supported
```

**Appendix Example**:
```markdown
### Appendix A: Constraint Dependency Matrix
| Constraint | Requires | Enables | Validation |
|------------|----------|---------|------------|
| Rule 1 | - | Rules 5, 6 | Type system |
| Rule 2 | Rule 1 | Rules 5, 8 | Type system |

### Appendix B: TDD Implementation Checklist
- [ ] AxiomError protocol with recovery strategies
  - [ ] Write failing test for error recovery
  - [ ] Implement minimal error handling
  - [ ] Refactor for clarity and reusability
- [ ] Capability protocol with degradation levels
  - [ ] Write test for capability checking
  - [ ] Implement capability validation
  - [ ] Refactor to eliminate duplication

### Appendix C: Version History
- **v1.5** (2025-01-13): Enhanced error recovery, added dependency matrix
- **v1.4** (2025-01-09): Added Rules 17-19, constraint enforcement
- **v1.3** (2025-01-08): Enhanced protocol specifications
```

---

**This document defines the standard RFC format for all Axiom Framework proposals.**