# RFC Format Standards

RFC specifications for TDD-driven framework development through agent-user collaboration.

## RFC Structure

### Metadata Header
```markdown
# RFC-XXX: [Title]

**RFC Number**: XXX  
**Title**: [Descriptive title]  
**Status**: Draft | Proposed | Active | Deprecated | Superseded  
**Type**: Architecture | Feature | Process | Standards  
**Created**: YYYY-MM-DD  
**Updated**: YYYY-MM-DD  
**Supersedes**: RFC-XXX (if applicable)  
**Superseded-By**: RFC-XXX (if applicable)
```

### Required Sections

1. **Abstract**: 2-3 paragraph summary of the proposal
2. **Motivation**: Problem statement and why this change is needed
3. **Specification**: Technical requirements with TDD criteria (see specification format below)
4. **Rationale**: Design decisions and rejected alternatives
5. **Backwards Compatibility**: Impact on existing code
6. **Security Considerations**: Threat model and mitigations
7. **Test Strategy**: Testing categories and validation approach
8. **References**: Related RFCs and documentation
9. **TDD Implementation Checklist**: Progress tracking for agent development sessions (REQUIRED)

### Framework-Specific Sections

10. **API Design**: Public interface contracts and evolution strategy
11. **Performance Constraints**: Framework overhead limits and benchmarks

### Optional Appendices
- **Dependency Matrix**: Constraint relationships
- **Version History**: Change log
- **MVP Guide**: Phased implementation approach
- **Migration Guide**: Upgrade path for breaking changes
- **Performance Benchmarks**: Baseline measurements

## Specification Format for TDD

Each requirement must include:
- **Requirement**: What must be true
- **Acceptance**: How to verify it's working (measurable)
- **Test Boundary**: Scope of testing
- **Refactoring Notes**: Optimization opportunities

### Example Format
```markdown
### Component Requirements
- Thread-Safe State Access:
  - Requirement: All state mutations via concurrency control
  - Acceptance: Race condition test with 1000 concurrent operations shows no data corruption
  - Boundary: Public API exposes only async methods
  - Refactoring: Consider read-write lock if performance bottleneck
  
- Observable State Changes:
  - Requirement: State changes trigger observer notifications
  - Acceptance: Observer receives notification within 10ms of state change
  - Boundary: Test with mock observers only
  - Refactoring: Batch notifications if frequency > 100/sec
  
- Memory Efficiency:
  - Requirement: Component overhead < 1KB per instance
  - Acceptance: Memory profiler shows allocation within limit
  - Boundary: Test with 10,000 instances
  - Refactoring: Pool frequently allocated objects
```

## Writing Guidelines

### Focus Areas
- **Specifications over prose**: Use bullet points for all technical requirements
- **Testability first**: Every requirement must have clear acceptance criteria
- **No implementation**: Define WHAT, not HOW
- **Measurable outcomes**: Quantify performance, size, and behavior constraints

### TDD Implementation Checklist Format

**Purpose**: Track development progress between agent sessions. The agent updates this checklist after each TDD cycle to maintain continuity.

```markdown
## TDD Implementation Checklist

**Last Updated**: YYYY-MM-DD HH:MM
**Current Focus**: [Active component/requirement]
**Session Notes**: [Any blockers or decisions needed]

### Component A: [Name]
- [ ] Interface Definition
  - [x] Red: Test interface contract requirements
  - [x] Green: Define minimal interface  
  - [ ] Refactor: Add default implementations
- [ ] Concurrency Safety
  - [ ] Red: Test concurrent access patterns
  - [ ] Green: Implement thread-safe access
  - [ ] Refactor: Optimize for common usage
  
### Component B: [Name]
- [ ] Error Handling
  - [ ] Red: Test error propagation and recovery
  - [ ] Green: Implement error types and handlers
  - [ ] Refactor: Consolidate error patterns
- [ ] Performance Optimization
  - [ ] Red: Test performance benchmarks
  - [ ] Green: Meet minimum performance targets
  - [ ] Refactor: Cache expensive operations
```

**Checklist Guidelines**:
- Mark items with [x] when complete
- Include test file names and line numbers
- Note any deferred refactorings
- Update "Last Updated" timestamp each session
- Record blockers in "Session Notes"

## Agent-User Collaboration Notes

### For the Coding Agent
- Use specifications as test-writing guide
- Follow red-green-refactor cycle for each requirement
- **Update TDD checklist after each development step**
- **Review checklist at start of each session to resume work**
- Request clarification on ambiguous acceptance criteria

### For the User
- Review agent's test interpretations
- Validate acceptance criteria match intent
- Approve major refactoring decisions
- Guide priority when multiple approaches exist

## Key Principles

1. **Test-First Design**: Every requirement starts with a failing test
2. **Incremental Development**: Small, verifiable steps through TDD cycles
3. **Continuous Refactoring**: Improve design after each green test
4. **Clear Boundaries**: Define what to test and what not to test
5. **Measurable Success**: Quantifiable acceptance criteria for all requirements
6. **Session Continuity**: TDD checklist maintains progress between agent sessions

## Framework Development Guidelines

- **API Stability**: Design for backwards compatibility
- **Performance**: Measure and minimize framework overhead
- **Extensibility**: Enable user customization without modification
- **Testing**: Comprehensive unit and integration test coverage
- **Documentation**: Clear contracts for all public interfaces

---

**This format enables systematic TDD-driven framework development through agent-user collaboration.**