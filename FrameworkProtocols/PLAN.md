# @PLAN.md - Axiom Framework Proposal Lifecycle Management

Framework proposal lifecycle management - concise, bullet-point focused RFC creation

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
- **`@PLAN suggest [RFC-XXX]`** → Analyze RFC and provide improvement suggestions


### Development Workflow Architecture
**IMPORTANT**: PLAN commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**RFC Philosophy**: Each RFC is self-contained with implementation checklists and version history
**Work Philosophy**: PLAN manages full lifecycle → Creates proposals → Proposes for implementation → DEVELOP implements → PLAN activates completed work → @CHECKPOINT commits and merges


**Core Principle**: Lifecycle management for technical proposals. Requirements focus, no implementation.

### Clear Separation of Concerns
- **PLAN**: Manages complete RFC lifecycle → Updates RFC metadata and version history
- **DEVELOP**: Implements proposed RFCs → Checks off implementation checklist items
- **CHECKPOINT**: Git workflow → NO RFC modifications
- **REFACTOR**: Code organization → NO RFC modifications
- **DOCUMENT**: Documentation operations → NO RFC modifications

**Quality Standards**: Requirements only. Measurable criteria. Bullet points. No code.



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
  - Technical requirements
  - Constraints and invariants
  - Measurable criteria
  - Interface contracts

### Propose Mode (`@PLAN propose [RFC-XXX]`)
- Locate RFC in Draft/
- Validate:
  - Requirements focus
  - No code examples
  - Complete interfaces
  - Measurable criteria
  - Implementation checklist exists
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
- Provide suggestions:
  - Missing requirements
  - Unclear constraints
  - Structure improvements
  - Redundant content
  - Technical gaps
- Output as bullet points
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

### RFC Proposal Format

All proposals must follow standard RFC format with proper metadata and structure:

#### RFC Metadata Header
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

#### RFC Document Structure

**Required Sections**:
- **Abstract**: 2-3 paragraph summary
- **Motivation**: Problem statement and need
- **Specification**: Technical requirements (bullet points preferred)
  - Constraints and invariants
  - Interface definitions
  - Performance targets
  - NO implementation examples
- **Rationale**: Design decisions vs alternatives
- **Backwards Compatibility**: Breaking changes impact
- **Security Considerations**: Threat model and mitigations
- **References**: Related RFCs and docs
- **Appendices**: Context-specific (implementation checklist, version history, etc.)

#### RFC Content Guidelines

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
- YES to test criteria

#### RFC Appendices Guide

**Common Appendices**:
- **Implementation Checklist**: Task list for development (if complex)
- **Dependency Matrix**: Constraint relationships (if many constraints)
- **Version History**: Single-line entries per version
- **MVP Guide**: Phased implementation approach (if needed)

**Appendix Flexibility**:
- Each RFC determines its own appendices
- No fixed appendix structure required
- Content driven by RFC complexity and scope



### RFC Specification Writing Guide

**Use Bullet Points For**:
- Component requirements
- Constraint definitions  
- Interface contracts
- Performance targets
- Error conditions
- Test criteria

**Example Specification Format**:
```markdown
### Component Requirements
- Must be thread-safe
- Singleton lifetime
- < 50ms initialization
- Handles these errors:
  - NetworkUnavailable
  - PermissionDenied
  - ResourceExhausted
```

**Avoid Natural Language For**:
- Technical specifications
- Measurable criteria
- Interface definitions
- Constraint lists

### Suggestion Quality Standards (`@PLAN suggest`)

**Focus Areas**:
- Missing requirements
- Unmeasurable criteria
- Incomplete interfaces
- Redundant content
- Technical gaps
- Structure issues

**Output Format**:
- Use bullet points
- Group by category
- Prioritize by impact
- Mark blockers clearly



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

**Appendix Example (From RFC-001)**:
```markdown
### Appendix A: Constraint Dependency Matrix
| Constraint | Requires | Enables | Validation |
|------------|----------|---------|------------|
| Rule 1 | - | Rules 5, 6 | Type system |
| Rule 2 | Rule 1 | Rules 5, 8 | Type system |

### Appendix B: Implementation Checklist
- [ ] AxiomError protocol with recovery strategies
- [ ] Capability protocol with degradation levels
- [ ] Client protocol with state observation

### Appendix C: Version History
- **v1.5** (2025-01-13): Enhanced error recovery, added dependency matrix
- **v1.4** (2025-01-09): Added Rules 17-19, constraint enforcement
- **v1.3** (2025-01-08): Enhanced protocol specifications
```

---

**Use FrameworkProtocols/@PLAN for complete RFC lifecycle management with self-contained proposals.**