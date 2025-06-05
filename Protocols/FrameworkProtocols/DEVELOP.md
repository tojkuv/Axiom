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

## Workflow

### Workspace Requirement
**MANDATORY**: DEVELOP protocol only runs in framework workspace
- Automatically navigates to framework workspace if available
- Errors if workspace not found

**Usage**:
```bash
# From anywhere
@DEVELOP build RFC-001  # Auto-navigates to framework-workspace/AxiomFramework
```

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

**Input Requirements**:
- RFC in `Proposed/` directory (RFCs/Proposed/ in framework workspace)
- Valid RFC_FORMAT.md structure
- TDD Implementation Checklist present

**Execution Context**:
- ONLY runs in framework workspace: `framework-workspace/AxiomFramework/`
- Auto-navigates to workspace from any location
- Requires framework workspace to be set up via `@WORKSPACE setup framework`

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
# DEVELOP only works in framework workspace
if [ -f "Package.swift" ] && [ -d "RFCs" ]; then
    # Already in framework workspace AxiomFramework directory
    echo "In framework workspace"
else
    # Search for framework workspace relative to current location
    SEARCH_PATHS=(
        "."
        ".."
        "../.."
        "../../.."
    )
    
    FOUND_WORKSPACE=""
    for path in "${SEARCH_PATHS[@]}"; do
        if [ -d "$path/framework-workspace/AxiomFramework" ]; then
            FOUND_WORKSPACE="$path/framework-workspace/AxiomFramework"
            break
        fi
    done
    
    if [ -n "$FOUND_WORKSPACE" ]; then
        echo "Navigating to framework workspace..."
        cd "$FOUND_WORKSPACE" || exit 1
    else
        echo "ERROR: Framework workspace not found"
        echo "Run '@WORKSPACE setup framework' first"
        exit 1
    fi
fi

# Validate RFC exists in Proposed/
RFC_PATH="RFCs/Proposed/${RFC_NUMBER}*.md"
if ! ls $RFC_PATH 1> /dev/null 2>&1; then
    echo "RFC not found in Proposed/"
    echo "Use '@PLAN propose' first"
    exit 1
fi

# MANDATORY: Run test suite
if ! swift test; then
    echo "BLOCKING: Tests failing"
    echo "Fix tests before proceeding"
    exit 1
fi

echo "Ready for TDD implementation"
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