# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show RFC status across all directories
- `create [title]` → New RFC in Draft/ with all sections/subsections from templates
- `propose [RFC-XXX]` → Move to Proposed/ (requires format compliance)
- `activate [RFC-XXX]` → Move to Active/ (final format check)
- `deprecate [RFC-XXX] [RFC-YYY]` → Replace with new
- `revise [RFC-XXX]` → Fix unstable requirements if any (format-aware)
- `explore [RFC-XXX]` → Suggest meaningful improvements if any (requires STABLE)
- `accept [RFC-XXX] [selections]` → Apply suggestions (maintains format)
- `ready [RFC-XXX]` → Verify ready for development (includes format validation)

## Core Process

Draft/ → Proposed/ → Active/ → Deprecated/ → Archive/

**Philosophy**: Stabilization before expansion with strict format compliance.
**Principle**: Quality over quantity - no suggestions is better than forced suggestions.
**Constraint**: Minimum 3-5 stable requirements before propose.
**Requirement**: Every command validates against current RFC_FORMAT.md.
**Guidance**: Commands should report "no issues found" when appropriate rather than inventing problems.

## Dependencies

**Required Before Any Command**:
- Current RFC_FORMAT.md must be loaded and validated
- All RFCs must comply with latest format standards
- Format changes require re-validation of existing RFCs

## Workflow

### Stabilization Process
1. Load current RFC_FORMAT.md requirements
2. `revise` → Get fixes for unstable requirements
3. `accept` → Apply selected fixes
4. Verify format compliance maintained
5. Repeat until RFC marked STABLE
6. `ready` → Final verification (includes format check)
7. `propose` → Move to implementation

### Enhancement Process (Optional)
1. Verify RFC_FORMAT.md compliance
2. `explore` → Get enhancement suggestions (requires STABLE)
3. `accept` → Apply selected changes
4. `revise` → Verify stability and format maintained

## Technical Details

**Format Validation**:
- Checks all 11 required sections present with proper structure
- Validates each section follows its template format:
  - Abstract: 3 paragraphs, max 300 words
  - Motivation: Problem Statement, Current Limitations, Use Cases subsections
  - Specification: Requirements with component headers and 4-part format
  - Rationale: Design Decisions and Alternatives Considered subsections
  - Backwards Compatibility: Breaking Changes, Deprecations, Migration Strategy
  - Security: Threat Model, Mitigations, Security Boundaries subsections
  - Test Strategy: Unit, Integration, Performance test categories
  - References: Normative and Informative subsections
  - TDD Checklist: Metadata header and component tracking
  - API Design: Interfaces, Contract Guarantees, Evolution Strategy
  - Performance: Latency, Memory, Throughput constraints
- Verifies metadata header completeness (8 fields)

**Revise Command**:
- Loads RFC_FORMAT.md before analysis
- Analyzes for actual instabilities only
- Returns "No revisions needed" if RFC is stable
- When issues found, provides numbered fixes [R1], [R2]...
  - Technical impossibilities → achievable versions
  - Missing acceptance criteria → complete criteria
  - Untestable specs → testable versions
  - Format violations → compliant versions:
    - Missing required subsections (e.g., "Add Problem Statement to Motivation")
    - Incorrect section structure (e.g., "Use 3-paragraph format for Abstract")
    - Missing metadata fields (e.g., "Add Type field to header")
    - Improper requirement format (e.g., "Add Refactoring field to requirement")
- Quality over quantity: 0-8 critical fixes better than 20 minor ones

**Explore Command**:
- Requires STABLE RFC with format compliance
- Evaluates for meaningful improvements only
- Returns "No enhancements recommended" if RFC is optimal
- When improvements exist, provides numbered changes [E1], [E2]...
  - Removals → requirements that add complexity without value
  - Simplifications → only if significantly reduce complexity
  - Additions → only if critical gap identified
- All changes must maintain format compliance
- Fewer high-impact suggestions preferred over many trivial ones

**Accept Command**:
- `accept RFC-001 R1,R3` → Apply specific revisions
- `accept RFC-001 E2,E4-6` → Apply explorations
- `accept RFC-001 all-revisions` → Apply all
- Post-accept format validation always runs

## Known Impossibilities

- Synchronous actor calls (always async)
- Zero-latency operations (minimum overhead)
- UI updates from background (main thread only)
- Runtime generic resolution (compile-time only)
- Mutable shared state without sync (memory unsafe)
- Synchronous cross-actor access (async required)

## Error Handling

**Format Violations**:
- "Missing required section X" → Add section per RFC_FORMAT.md template
- "Invalid requirement format" → Use requirement/acceptance/boundary/refactoring
- "No TDD checklist" → Add checklist with metadata and component tracking
- "Missing subsection in Motivation" → Add Problem Statement/Current Limitations/Use Cases
- "Abstract too long" → Reduce to 3 paragraphs, max 300 words
- "Security section incomplete" → Add Threat Model/Mitigations/Boundaries subsections
- "Performance constraints missing units" → Add latency (ms), memory (MB/KB), throughput (ops/sec)

**Recovery**:
1. Run `@PLAN status` to identify non-compliant RFCs
2. Use `@PLAN revise` to get format fixes
3. Apply with `@PLAN accept` to restore compliance

## Examples

**Create and Stabilize**:
```
# RFC_FORMAT.md automatically loaded
@PLAN create awesome-feature
# Creates RFC with all 11 sections using templates
# Including subsections like Problem Statement, Threat Model, etc.
@PLAN revise RFC-001
# Shows: [R1] "Zero-latency" → "<2ms propagation @ P99"
#        [R2] Missing Use Cases in Motivation → Add 2 use cases
#        [R3] Abstract missing 3rd paragraph → Add benefits
@PLAN accept RFC-001 R1,R2,R3
@PLAN ready RFC-001
# Verifies all sections follow templates and requirements stable
@PLAN propose RFC-001
```

**Explore Enhancements**:
```
# RFC_FORMAT.md checked for any changes
@PLAN explore RFC-001
# Shows: [E1] REMOVE: Custom serialization (-500 LOC)
#        [E2] ADD: Batch updates (70% fewer calls)
# All suggestions maintain format compliance
@PLAN accept RFC-001 E2
# Post-accept validation ensures format intact
```

**No Changes Needed**:
```
@PLAN revise RFC-002
# Shows: No revisions needed - RFC is stable

@PLAN explore RFC-003
# Shows: No enhancements recommended - RFC is optimal
```

**Format Update Workflow**:
```
# After RFC_FORMAT.md changes
@PLAN status
# Shows: 3 RFCs need format updates
@PLAN revise RFC-001
# Shows: [R1] Add Performance Constraints section with Latency/Memory/Throughput
#        [R2] Update Security section → Add Security Boundaries subsection
#        [R3] API Design missing Evolution Strategy → Add versioning approach
@PLAN accept RFC-001 R1,R2,R3
```

Format: [RFC_FORMAT.md](./RFC_FORMAT.md) - REQUIRED REFERENCE

Manages RFC lifecycle with requirement stabilization, scope control, and mandatory format compliance.