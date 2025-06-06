# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show test app RFC status across all directories
- `create [title]` → New test app RFC in Draft/ with all sections from templates
- `propose [RFC-XXX]` → Move to Proposed/ (requires format compliance)
- `activate [RFC-XXX]` → Move to Active/ (final format check)
- `archive [RFC-XXX]` → Move completed test to Archive/
- `revise [RFC-XXX]` → Fix unstable requirements if any (format-aware)
- `explore [RFC-XXX]` → Suggest meaningful improvements if any (requires STABLE)
- `accept [RFC-XXX] [selections]` → Apply suggestions (maintains format)
- `ready [RFC-XXX]` → Verify ready for development (includes format validation)

## Core Process

Draft/ → Proposed/ → Active/ → Archive/

**Philosophy**: Create minimal test apps to validate framework stability with strict format compliance.
**Principle**: Quality over quantity - focus on targeted framework validation.
**Constraint**: Each RFC must test specific Axiom patterns.
**Requirement**: Every command validates against current RFC_FORMAT.md.
**Guidance**: Test apps should be minimal but comprehensive for their testing goals.

## Dependencies

**Required Before Any Command**:
- Current RFC_FORMAT.md must be loaded and validated
- All test app RFCs must comply with format standards
- Format changes require re-validation of existing RFCs

## Workflow

### Workspace Requirement
**MANDATORY**: PLAN protocol only runs in application workspace
- Automatically navigates to application workspace if available
- Errors if workspace not found

**Usage**:
```bash
# From anywhere
@PLAN create actor-concurrency-test  # Auto-navigates to application-workspace
```

### Test App Planning Process
1. Load current RFC_FORMAT.md requirements
2. `create` → Generate RFC with all 6 sections using templates
3. Define framework testing goals and scenarios
4. `revise` → Get fixes for unstable requirements
5. `accept` → Apply selected fixes
6. `ready` → Final verification (includes format check)
7. `propose` → Move to implementation

### Enhancement Process (Optional)
1. Verify RFC_FORMAT.md compliance
2. `explore` → Get enhancement suggestions (requires STABLE)
3. `accept` → Apply selected changes
4. `revise` → Verify stability and format maintained

## Technical Details

**Execution Context**:
- ONLY runs in application workspace: `application-workspace/`
- Auto-navigates to workspace from any location
- Requires application workspace to be set up

**Format Validation**:
- Checks all 6 required sections present with proper structure:
  - Abstract: 1-2 paragraphs, max 200 words
  - Motivation: Framework Testing Goals, Test Scenarios subsections
  - Specification: Requirements with 4-part format
  - Test Strategy: Unit, UI, Performance test categories
  - API Design: Swift code interfaces
  - TDD Checklist: Metadata header and Red-Green-Refactor tracking
- Verifies metadata header completeness (7 fields)

**Revise Command**:
- Loads RFC_FORMAT.md before analysis
- Analyzes for actual instabilities only
- Returns "No revisions needed" if RFC is stable
- When issues found, provides numbered fixes [R1], [R2]...
  - Technical impossibilities → achievable versions
  - Missing acceptance criteria → complete criteria
  - Untestable specs → testable versions
  - Format violations → compliant versions
- Focus on framework testing relevance

**Explore Command**:
- Requires STABLE RFC with format compliance
- Evaluates for meaningful test improvements only
- Returns "No enhancements recommended" if RFC is optimal
- When improvements exist, provides numbered changes [E1], [E2]...
  - Better framework coverage
  - Additional edge cases
  - Performance stress tests
- All changes must maintain minimal test app focus

**Accept Command**:
- `accept RFC-001 R1,R3` → Apply specific revisions
- `accept RFC-001 E2,E4-6` → Apply explorations
- `accept RFC-001 all-revisions` → Apply all
- Post-accept format validation always runs

## Execution Process

```bash
# PLAN only works in application workspace
if [[ -L "$0" ]]; then
    # Called via symlink from workspace
    WORKSPACE_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
    while [[ ! -f "$WORKSPACE_ROOT/.workspace-status" && "$WORKSPACE_ROOT" != "/" ]]; do
        WORKSPACE_ROOT="$(dirname "$WORKSPACE_ROOT")"
    done
else
    # Called directly - find application-workspace
    WORKSPACE_ROOT="$(cd "$(dirname "$0")/../../../../application-workspace" 2>/dev/null && pwd)"
fi

# Verify we're in application workspace
if [[ ! -f "$WORKSPACE_ROOT/.workspace-status" ]] || ! grep -q "Type: application" "$WORKSPACE_ROOT/.workspace-status"; then
    echo "Error: Must be run from application-workspace"
    exit 1
fi

cd "$WORKSPACE_ROOT" || exit 1

# Load RFC_FORMAT.md for validation
RFC_FORMAT="ApplicationProtocols/RFC_FORMAT.md"
if [ ! -f "$RFC_FORMAT" ]; then
    echo "ERROR: RFC_FORMAT.md not found"
    exit 1
fi

echo "Ready for test app RFC planning"
```

## Known Framework Testing Areas

- Actor isolation and concurrency
- State propagation timing
- Context-Client observation patterns
- Navigation flow and cancellation
- Error boundary propagation
- Memory management and leaks
- Performance under stress

## Error Handling

**Format Violations**:
- "Missing required section X" → Add section per RFC_FORMAT.md template
- "Invalid requirement format" → Use requirement/acceptance/boundary/refactoring
- "No TDD checklist" → Add checklist with metadata and Red-Green-Refactor
- "Abstract too long" → Reduce to 1-2 paragraphs, max 200 words
- "Missing Framework Testing Goals" → Add specific Axiom patterns to test

**Recovery**:
1. Run `@PLAN status` to identify non-compliant RFCs
2. Use `@PLAN revise` to get format fixes
3. Apply with `@PLAN accept` to restore compliance

## Examples

**Create and Stabilize Test App**:
```
# RFC_FORMAT.md automatically loaded
@PLAN create actor-concurrency-test
# Creates RFC with all 6 sections for testing actor patterns
@PLAN revise RFC-001
# Shows: [R1] "Zero-latency" → "<16ms state propagation"
#        [R2] Missing Test Scenarios → Add concurrency edge cases
@PLAN accept RFC-001 R1,R2
@PLAN ready RFC-001
# Verifies ready for test app development
@PLAN propose RFC-001
```

**Explore Test Enhancements**:
```
@PLAN explore RFC-001
# Shows: [E1] ADD: Stress test with 1000 actors
#        [E2] ADD: Memory leak detection scenario
@PLAN accept RFC-001 E1,E2
```

**No Changes Needed**:
```
@PLAN revise RFC-002
# Shows: No revisions needed - RFC is stable

@PLAN explore RFC-003
# Shows: No enhancements recommended - Test coverage is comprehensive
```

Format: [RFC_FORMAT.md](./RFC_FORMAT.md) - REQUIRED REFERENCE

Manages test app RFC lifecycle with framework validation focus and mandatory format compliance.