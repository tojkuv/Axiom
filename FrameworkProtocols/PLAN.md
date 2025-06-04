# @PLAN.md - Axiom Framework Proposal Lifecycle Management

Framework proposal lifecycle management - concise, bullet-point focused RFC creation with TDD-oriented requirements

## Automated Mode Trigger

**When human sends**: `@PLAN [optional-args]`
**Action**: Enter ultrathink mode and execute framework proposal lifecycle workflow

### Usage Modes
- **`@PLAN`** → Show current RFC status across all directories
- **`@PLAN create [title]`** → Create new RFC in AxiomFramework/RFCs/Draft/ with sequential RFC number
- **`@PLAN propose [RFC-XXX]`** → Move RFC from Draft/ to Proposed/
- **`@PLAN activate [RFC-XXX]`** → Move RFC from Proposed/ to Active/ after implementation
- **`@PLAN deprecate [RFC-XXX] [RFC-YYY]`** → Deprecate RFC-XXX in favor of RFC-YYY
- **`@PLAN status`** → Display RFCs in each lifecycle stage
- **`@PLAN suggest [RFC-XXX]`** → Analyze RFC and provide actionable suggestions with solutions


### Development Workflow Architecture
**IMPORTANT**: PLAN commands NEVER perform git operations or touch code
**Scope**: Requirements engineering and RFC lifecycle management only
**RFC Philosophy**: Each RFC contains testable requirements with acceptance criteria
**Workflow**: PLAN creates requirements → DEVELOP implements → PLAN activates
**Integration Points**: 
  - Output: RFCs with acceptance criteria for DEVELOP
  - Input: Implementation status from DEVELOP for activation
  - Never: Direct code interaction or test execution


**Core Principle**: Requirements engineering and RFC lifecycle management. Creates specifications with testable acceptance criteria. Never touches code.

### Protocol Boundaries and Responsibilities

**PLAN Protocol (Requirements & Lifecycle)**:
- **Purpose**: Define WHAT to build through testable requirements
- **Focus**: Requirements, constraints, acceptance criteria, performance targets
- **Output**: RFCs with specifications ready for TDD implementation
- **Never**: Write code, suggest implementation approaches, or handle testing

**DEVELOP Protocol (Implementation & Testing)**:
- **Purpose**: Build HOW requirements are satisfied through TDD
- **Focus**: Code implementation, testing, refactoring, performance optimization
- **Input**: RFCs from PLAN with acceptance criteria and test boundaries
- **Never**: Modify RFC specifications or change requirements

### Clear Separation of Concerns
- **PLAN**: RFC lifecycle (create→propose→activate→deprecate) + requirements engineering
- **DEVELOP**: TDD implementation (red→green→refactor) + code quality
- **CHECKPOINT**: Version control operations only
- **REFACTOR**: Code reorganization only
- **DOCUMENT**: Documentation updates only

**Quality Standards**: 
- Requirements must be testable with clear acceptance criteria
- Specifications in bullet points, no prose
- Performance targets with measurable outcomes
- No code examples or implementation details

**Suggestion Philosophy**: 
- Provide complete requirement text for additions
- Include technical rationale for impossibilities  
- Focus on stabilization over features
- Always check for duplication and format compliance



## RFC Lifecycle States

| State | Location | Status | Next Action |
|-------|----------|--------|-------------|
| Draft | `Draft/` | Creating/editing | `@PLAN propose` |
| Proposed | `Proposed/` | Ready to implement | `@DEVELOP` |
| Active | `Active/` | Implemented | `@PLAN deprecate` |
| Deprecated | `Deprecated/` | Superseded | Archive |
| Archived | `Archive/` | Historical | None |


## Framework Planning Command Execution

**Command**: `@PLAN [create|propose|activate|deprecate|status|suggest]`
**Action**: Execute framework proposal lifecycle management


### Create Mode (`@PLAN create [title]`)
- Assign next RFC number
- Scan existing RFCs for context
- Generate RFC-XXX-[TITLE].md in Draft/
- Populate metadata (status: Draft)
- Include standard appendices
- Focus on:
  - Testable technical requirements
  - Constraints and invariants
  - Acceptance criteria for each requirement
  - Interface contracts with clear test boundaries
  - Performance targets with measurable metrics
  - TDD-ready implementation checklist

### Propose Mode (`@PLAN propose [RFC-XXX]`)
- Locate RFC in Draft/
- Validate:
  - Requirements are testable
  - Each requirement has acceptance criteria
  - No code examples
  - Complete interfaces with test boundaries
  - Measurable criteria enabling test assertions
  - Implementation checklist supports TDD cycles
  - Requirements enable refactoring opportunities
- Update status → "Proposed"
- Update metadata:
  - Updated date
  - Version history entry
- Move to Proposed/

### Activate Mode (`@PLAN activate [RFC-XXX]`)
- Locate RFC in Proposed/
- Verify implementation complete:
  - Check implementation checklist
  - Confirm all items completed
- Update status → "Active"
- Update metadata:
  - Updated date
  - Version history entry
- Move to Active/

### Deprecate Mode (`@PLAN deprecate [RFC-XXX] [RFC-YYY]`)
- Validate RFC-YYY supersedes RFC-XXX
- Update RFC-XXX:
  - Status → "Deprecated"
  - Add "Superseded-By: RFC-YYY"
  - Version history entry
- Update RFC-YYY:
  - Add "Supersedes: RFC-XXX"
  - Version history entry
- Move RFC-XXX to Deprecated/

### Suggest Mode (`@PLAN suggest [RFC-XXX]`)
- Locate RFC (any directory)
- Analyze without modifying
- **MANDATORY CHECKS** (performed first):
  - Format compliance with RFC_FORMAT.md
  - Duplicate requirements across sections
  - Inconsistent terminology or naming
  - Missing acceptance criteria
  - Untestable specifications
- **Priority System**:
  - **High Priority**: Requirements stabilization only
    - Missing acceptance criteria
    - Untestable specifications
    - Technical impossibilities
    - Ambiguous requirements
    - Inconsistent constraints
  - **Medium Priority**: Feature completeness only
    - Missing capability specifications
    - Incomplete interface definitions
    - Missing error handling requirements
    - Incomplete performance targets
  - **Low Priority**: Quality improvements only
    - Structure reorganization
    - Terminology standardization
    - Section consolidation
    - Clarity enhancements
- **Output Format**:
  - Problem → Solution with exact requirement text
  - Group by priority, then by category
  - Technical impossibilities with platform rationale
  - No implementation suggestions ever
- **Quality Gate**: Suggestions stop when RFC has:
  - All requirements with acceptance criteria
  - No duplicate specifications
  - Consistent terminology throughout
  - Clear test boundaries for all interfaces
  - Measurable performance targets
- No file changes

### Status Mode (`@PLAN status`)
- Scan all RFC directories
- Extract from each RFC:
  - Status from metadata
  - Type from metadata
  - Latest update date
- Display summary table:
  - RFC number and title
  - Current status
  - Type
  - Last updated




## Framework Proposal Format Standards

All RFCs must follow the standard format defined in [RFC_FORMAT.md](./RFC_FORMAT.md).

**Key Format Requirements**:
- Standard metadata header with status tracking
- Required sections for comprehensive specification
- Bullet-point specifications with acceptance criteria
- TDD-oriented implementation checklists
- No code examples or implementation details

**See [RFC_FORMAT.md](./RFC_FORMAT.md) for**:
- Complete RFC metadata header format
- Required document structure and sections
- Content guidelines and writing style
- Appendices guide and examples
- Specification writing patterns

### Suggestion Quality Standards (`@PLAN suggest`)

**Solution Requirements**:
- Every suggestion must include actionable solution
- Provide complete requirement text for additions
- Show exact reorganization for structure changes
- Supply specific acceptance criteria for untestable requirements
- State "Not technically achievable because..." for impossible requirements

**Requirements Priority System** (focused on WHAT, never HOW):
- **High Priority**: Requirements that block implementation
  - Missing acceptance criteria for testability
  - Ambiguous specifications needing clarification
  - Technical impossibilities requiring revision
  - Inconsistent constraints across sections
- **Medium Priority**: Requirements for feature completeness
  - Missing capability specifications
  - Incomplete interface contracts
  - Undefined error scenarios
  - Missing performance boundaries
- **Low Priority**: Requirements quality improvements
  - Structure and organization
  - Terminology consistency
  - Duplicate consolidation
  - Readability enhancements

**Priority-Grouped Output Format**:
- Problem → Solution format
- Group by priority (High/Medium/Low) then by development category
- Include ready-to-add requirement text for immediate implementation
- Mark technical impossibilities with platform-specific rationale  
- Present High Priority (stabilization) suggestions first for immediate action
- Present Medium Priority (feature expansions) suggestions second for planning
- Present Low Priority (general considerations) suggestions third for future improvement



## Framework Planning Coordination

**RFC Directories** (located at `AxiomFramework/RFCs/`):
- `Draft/` - New RFCs with status "Draft"
- `Proposed/` - RFCs with status "Proposed" ready for implementation
- `Active/` - Implemented RFCs with status "Active"
- `Deprecated/` - Superseded RFCs with status "Deprecated"
- `Archive/` - Historical record of all RFCs

**RFC Self-Containment**:
- Each RFC is fully self-contained
- Progress tracked via implementation checklists
- History tracked via version appendix
- No external tracking dependencies

---

### RFC Examples

**For complete RFC examples and patterns, see [RFC_FORMAT.md](./RFC_FORMAT.md)**

**Quick Reference**:
- Specification examples with bullet points
- Appendix patterns (dependency matrix, TDD checklist, version history)
- TDD-oriented requirement examples with acceptance criteria

### Priority-Grouped Suggest Mode Output Examples

**Example Output Format**:
```markdown
## MANDATORY CHECKS COMPLETED
✓ RFC format compliance verified
✓ Duplicate requirements: Found 3 instances
✓ Inconsistent terminology: 2 conflicts identified
✓ Missing acceptance criteria: 5 requirements
✓ Untestable specifications: 2 found

## HIGH PRIORITY (Requirements Stabilization)

### Missing Acceptance Criteria

**Problem**: "Framework must handle errors gracefully" lacks testable criteria
**Solution**: Replace with:
```
"Error Handling: Framework propagates all errors to nearest Context boundary"
- Acceptance: Error injection at any component reaches Context within 10ms
- Test Boundary: Mock error generation at Client, Capability, and State levels
```

**Problem**: "Performance must be optimal" is not measurable
**Solution**: Replace with:
```
"State Update Performance: State mutations complete within 8ms"
- Acceptance: 95th percentile of 1000 state updates measures <8ms
- Test Boundary: Performance test harness with timing measurements
```

### Technical Impossibilities

**Problem**: "Zero-latency state propagation" requirement
**Platform Limitation**: Swift actor message passing has minimum 1ms overhead
**Solution**: Revise to "State propagation completes within 2ms"

### Requirement Conflicts

**Problem**: Section 3 requires "synchronous state access" while Section 5 mandates "all state access via actors"
**Solution**: Remove synchronous requirement, maintain actor-based async access throughout

---

## MEDIUM PRIORITY (Feature Completeness)

### Missing Capability Requirements

**Problem**: Capability lifecycle transitions not specified
**Solution**: Add requirement:
```
"Capability State Transitions: Available → Degraded → Unavailable with notifications"
- Acceptance: State machine test validates all transition paths
- Test Boundary: Mock capability with controllable state changes
```

### Incomplete Interface Definitions

**Problem**: Error recovery protocol lacks required methods
**Solution**: Add requirement:
```
"Recovery Protocol: All errors must include recoveryStrategies: [RecoveryStrategy] property"
- Acceptance: Compiler enforces recovery strategies on all AxiomError types
- Test Boundary: Protocol conformance validation
```

### Missing Performance Boundaries

**Problem**: Memory usage limits not defined
**Solution**: Add requirement:
```
"Memory Constraints: Context overhead <1KB, Client overhead <512B excluding state"
- Acceptance: Memory profiler validates limits across 100 component instances
- Test Boundary: Instruments memory measurement
```

---

## LOW PRIORITY (Quality Improvements)

### Duplicate Consolidation

**Problem**: Performance requirements scattered across 5 sections
**Solution**: Consolidate into single "Performance Requirements" section with subsections for each component

**Problem**: Error handling requirements duplicated in Protocols and Implementation sections
**Solution**: Create single "Error Handling Requirements" section, reference from others

### Terminology Standardization

**Problem**: "Client" vs "Actor" used interchangeably
**Solution**: Standardize on "Client" throughout, note actor as implementation detail

**Problem**: "State" vs "Model" inconsistency
**Solution**: Use "State" for mutable data, "Model" for domain value objects

### Structure Optimization

**Problem**: Implementation checklist mixed with requirements
**Solution**: Move checklist to Appendix B, keep requirements in main sections

**Problem**: Test boundaries scattered throughout
**Solution**: Collect all test boundaries in dedicated subsection per component

---

## SUGGESTION SUMMARY
- High Priority: 4 issues blocking implementation
- Medium Priority: 3 issues for feature completeness  
- Low Priority: 6 quality improvements
- RFC Ready for Implementation: NO - resolve High priority issues first
```

### TDD-Oriented RFC Example

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

---

**Use FrameworkProtocols/@PLAN for complete RFC lifecycle management with TDD-ready proposals.**