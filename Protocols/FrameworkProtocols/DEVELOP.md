# @DEVELOP.md

**Trigger**: `@DEVELOP [command] [RFC-XXX]`

## Commands

- `status` → Show RFC implementation status
- `build [RFC-XXX]` → Execute TDD implementation using RFC checklist
- `test [RFC-XXX]` → Run tests for RFC implementation  
- `resume [RFC-XXX]` → Continue from checklist's current focus

## Core Process

Red → Green → Refactor → Checklist Update

**Philosophy**: Test-driven development with RFC requirement tracking.
**Constraint**: All tests must pass before checklist updates.

## CRITICAL SAFETY RULES

1. **NEVER** modify files in `/Protocols/FrameworkProtocols/` directory
2. **ALWAYS** operate in framework workspace: `/Users/tojkuv/Documents/GitHub/axiom-apple/framework-workspace`
3. **VERIFY** working directory before any file operations
4. **ABORT** if not in framework workspace

## Workflow

### TDD Implementation
1. Review RFC's TDD checklist current state
2. Extract requirement (4 parts: requirement, acceptance, boundary, refactor)
3. **RED**: Write failing test from acceptance criteria
4. **GREEN**: Minimal code to pass test
5. **REFACTOR**: Apply RFC's refactoring notes
6. Update checklist [x] with file:line references
7. Commit via @CHECKPOINT when session complete

### Session Management
**Start**: Check RFC in Proposed/ and review checklist
**Execute**: Follow TDD cycle for each requirement  
**Track**: Update checklist with implementation details
**End**: Update session metadata for continuity

## Technical Details

**Protocol Dependencies**:
- Requires framework workspace setup via `@WORKSPACE framework setup`
- Integrations committed via `@CHECKPOINT framework` or `@CHECKPOINT`
- All protocols can be invoked from any directory

**Input Requirements**:
- RFC in `Proposed/` directory
- Valid RFC_FORMAT.md structure
- TDD Implementation Checklist present

**Test Requirements**:
- MANDATORY: All tests pass before proceeding
- BLOCKING: Failures stop all work
- Run `swift test` before any checklist update

**Refactoring Patterns**:
- Three Strikes Rule: Refactor on third duplication
- Common: Extract Method, Rename, Remove Duplication
- Small steps with tests after each change

## Execution Process

```bash
# Determine framework workspace path
FRAMEWORK_WORKSPACE="/Users/tojkuv/Documents/GitHub/axiom-apple/framework-workspace"

# Validate framework workspace exists
if [[ ! -d "$FRAMEWORK_WORKSPACE" ]]; then
    echo "ERROR: Framework workspace not found at $FRAMEWORK_WORKSPACE"
    echo "Run '@WORKSPACE framework setup' first"
    exit 1
fi

# Validate RFC exists in Proposed/
RFC_PATH="$FRAMEWORK_WORKSPACE/AxiomFramework/RFCs/Proposed/${RFC_NUMBER}*.md"
if ! ls $RFC_PATH 1> /dev/null 2>&1; then
    echo "RFC not found in Proposed/"
    echo "Use '@PLAN propose' first"
    exit 1
fi

# Enter framework workspace
cd "$FRAMEWORK_WORKSPACE/AxiomFramework" || exit 1

# SAFETY CHECK: Verify we're in the correct workspace
CURRENT_DIR=$(pwd)
if [[ ! "$CURRENT_DIR" == "$FRAMEWORK_WORKSPACE/AxiomFramework" ]]; then
    echo "ERROR: Not in framework workspace!"
    echo "Expected: $FRAMEWORK_WORKSPACE/AxiomFramework"
    echo "Current: $CURRENT_DIR"
    exit 1
fi

# SAFETY CHECK: Ensure we're NOT in protocols directory
if [[ "$CURRENT_DIR" == *"/Protocols/"* ]]; then
    echo "ERROR: Operating in Protocols directory is forbidden!"
    echo "Must work in framework workspace only"
    exit 1
fi

# MANDATORY: Run test suite
if ! swift test; then
    echo "BLOCKING: Tests failing"
    echo "Fix tests before proceeding"
    exit 1
fi

echo "Ready for TDD implementation in: $CURRENT_DIR"
```

## Examples

**Start Implementation**:
```
@DEVELOP build RFC-001
# Opens RFC, shows checklist state
# Begins with first unchecked item
```

**Resume Session**:
```
@DEVELOP resume RFC-001  
# Continues from "Current Focus" in checklist
# Shows last completed item for context
```

**Run Tests**:
```
@DEVELOP test RFC-001
# Runs swift test
# Shows coverage for RFC requirements
```

Transforms RFC requirements into tested code using TDD cycles with checklist tracking.