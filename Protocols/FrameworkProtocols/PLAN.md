# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show RFC status across all directories
- `create [title]` → New RFC in Draft/ (validates against RFC_FORMAT.md)
- `propose [RFC-XXX]` → Move to Proposed/ (requires format compliance)
- `activate [RFC-XXX]` → Move to Active/ (final format check)
- `deprecate [RFC-XXX] [RFC-YYY]` → Replace with new
- `revise [RFC-XXX]` → Fix unstable requirements (format-aware)
- `explore [RFC-XXX]` → Suggest changes (requires STABLE & format compliance)
- `accept [RFC-XXX] [selections]` → Apply suggestions (maintains format)
- `ready [RFC-XXX]` → Verify ready for development (includes format validation)

## Core Process

Draft/ → Proposed/ → Active/ → Deprecated/ → Archive/

**Philosophy**: Stabilization before expansion with strict format compliance.
**Constraint**: Minimum 3-5 stable requirements before propose.
**Requirement**: Every command validates against current RFC_FORMAT.md.

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
- Checks all 11 required sections present
- Validates requirement/acceptance/boundary/refactoring format
- Ensures TDD Implementation Checklist exists
- Verifies metadata header completeness

**Revise Command**:
- Loads RFC_FORMAT.md before analysis
- Provides numbered fixes [R1], [R2]...
- Technical impossibilities → achievable versions
- Missing acceptance criteria → complete criteria
- Untestable specs → testable versions
- Format violations → compliant versions

**Explore Command**:
- Requires format compliance before suggestions
- Provides numbered changes [E1], [E2]...
- Removals → requirements to delete
- Simplifications → consolidated versions
- Additions → new requirements with criteria
- All changes maintain format compliance

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
- "Missing required section X" → Add section per RFC_FORMAT.md
- "Invalid requirement format" → Use requirement/acceptance/boundary/refactoring
- "No TDD checklist" → Add checklist with red-green-refactor items

**Recovery**:
1. Run `@PLAN status` to identify non-compliant RFCs
2. Use `@PLAN revise` to get format fixes
3. Apply with `@PLAN accept` to restore compliance

## Examples

**Create and Stabilize**:
```
# RFC_FORMAT.md automatically loaded
@PLAN create awesome-feature
# Creates RFC with all 11 required sections
@PLAN revise RFC-001
# Shows: [R1] "Zero-latency" → "<2ms propagation"
#        [R2] Missing TDD checklist → Add checklist template
@PLAN accept RFC-001 R1,R2
@PLAN ready RFC-001
# Verifies format compliance and stability
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

**Format Update Workflow**:
```
# After RFC_FORMAT.md changes
@PLAN status
# Shows: 3 RFCs need format updates
@PLAN revise RFC-001
# Shows: [R1] Add Performance Constraints section
@PLAN accept RFC-001 R1
```

Format: [RFC_FORMAT.md](./RFC_FORMAT.md) - REQUIRED REFERENCE

Manages RFC lifecycle with requirement stabilization, scope control, and mandatory format compliance.