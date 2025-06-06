# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show test app RFC status in AxiomApplicationTests/RFCs/
- `propose [request]` → Create new RFC based on user request
  - Can reference analysis report: "Based on ANLS-XXX, create RFC for..."
  - Can request new app: "Create a task manager to test actor concurrency"
  - Can update existing: "Update TestApp002 to fix issues from ANLS-XXX"
- `activate [RFC-XXX]` → Move RFC from Draft/ to Active/ for development
- `archive [RFC-XXX]` → Move completed RFC to Archive/
- `revise [RFC-XXX]` → Fix unstable requirements if any
- `explore [RFC-XXX]` → Suggest meaningful improvements if any (requires STABLE)
- `accept [RFC-XXX] [selections]` → Apply suggestions

## Core Process

Draft/ → Active/ → Archive/

**RFC Storage**: `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/RFCs/`

**Philosophy**: Create minimal test apps to validate framework stability.
**Principle**: Quality over quantity - focus on targeted framework validation.
**Constraint**: Each RFC must test specific Axiom patterns.
**Guidance**: Test apps should be minimal but comprehensive for their testing goals.

## Dependencies

**Required Before Any Command**:
- RFC_FORMAT.md defines the standard structure
- All test app RFCs should follow format standards

## Workflow

### Workspace Requirement
**MANDATORY**: PLAN protocol only runs in application workspace
- Automatically navigates to application workspace if available
- Errors if workspace not found

**Usage**:
```bash
# From anywhere
@PLAN propose "Create actor concurrency test app"  # Auto-navigates to workspace-application
```

### Test App Planning Process
1. `propose` → Generate RFC from user request
   - Analyzes request to determine app type and testing goals
   - References analysis reports if provided
   - Creates RFC with all sections from RFC_FORMAT.md
2. Define framework testing goals and scenarios
3. `revise` → Get fixes for unstable requirements
4. `accept` → Apply selected fixes
5. `activate` → Move to Active/ for development

### Enhancement Process (Optional)
1. `explore` → Get enhancement suggestions (requires STABLE)
2. `accept` → Apply selected changes
3. `revise` → Verify stability maintained

## Technical Details

**Execution Context**:
- ONLY runs in application workspace: `workspace-application/`
- Auto-navigates to workspace from any location
- Requires application workspace to be set up

**Propose Command**:
- Accepts natural language request from user
- Can reference ANLS-XXX analysis reports
- Determines if creating new app or updating existing
- Generates RFC following RFC_FORMAT.md structure
- Creates RFCs in: `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/RFCs/`
- Places new RFC in Draft/ subdirectory with next available RFC number

**Revise Command**:
- Analyzes for actual instabilities only
- Returns "No revisions needed" if RFC is stable
- When issues found, provides numbered fixes [R1], [R2]...
  - Technical impossibilities → achievable versions
  - Missing acceptance criteria → complete criteria
  - Untestable specs → testable versions
- Focus on framework testing relevance

**Explore Command**:
- Requires STABLE RFC
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
    # Called directly - find workspace-application
    WORKSPACE_ROOT="$(cd "$(dirname "$0")/../../../../workspace-application" 2>/dev/null && pwd)"
fi

# Verify we're in application workspace
if [[ ! -f "$WORKSPACE_ROOT/.workspace-status" ]] || ! grep -q "Type: application" "$WORKSPACE_ROOT/.workspace-status"; then
    echo "Error: Must be run from workspace-application"
    exit 1
fi

cd "$WORKSPACE_ROOT" || exit 1

# Set up RFCs directory structure
RFCS_DIR="/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/RFCs"
mkdir -p "$RFCS_DIR/Draft" "$RFCS_DIR/Active" "$RFCS_DIR/Archive"

echo "Ready for test app RFC planning"
echo "RFCs location: $RFCS_DIR"
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

**Common Issues**:
- "Missing sections" → Refer to RFC_FORMAT.md for structure
- "Unclear requirements" → Use requirement/acceptance/boundary/refactoring format
- "Incomplete test coverage" → Add all component tests

**Recovery**:
1. Run `@PLAN status` to check RFC status
2. Use `@PLAN revise` to improve requirements
3. Apply with `@PLAN accept` to update

## Examples

**Create New Test App**:
```
@PLAN propose "Create a task manager app to test actor concurrency and state propagation"
# Creates RFC-001 in /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/RFCs/Draft/
@PLAN revise RFC-001
# Shows: [R1] "Zero-latency" → "<16ms state propagation"
#        [R2] Missing Test Scenarios → Add concurrency edge cases
@PLAN accept RFC-001 R1,R2
@PLAN activate RFC-001
# Moves to AxiomApplicationTests/RFCs/Active/ for development
```

**Create RFC from Analysis**:
```
@PLAN propose "Based on ANLS-20250606-144034, create RFC to fix TaskClient complexity"
# Creates RFC-002 in AxiomApplicationTests/RFCs/Draft/ addressing issues from analysis report
@PLAN activate RFC-002
# Moves to AxiomApplicationTests/RFCs/Active/
```

**Update Existing App**:
```
@PLAN propose "Update TestApp002 to decompose TaskClient based on ANLS-20250606-144034"
# Creates RFC-003 in AxiomApplicationTests/RFCs/Draft/ for refactoring existing application
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

Manages test app RFC lifecycle from user requests to active development plans.
