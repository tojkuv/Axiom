# @DEVELOP.md

**Trigger**: `@DEVELOP [command] [RFC-XXX]`

## Commands

- `status` → Show test app implementation status
- `build [RFC-XXX]` → Execute TDD implementation using RFC checklist
- `test [RFC-XXX]` → Run test app's test suite
- `validate [RFC-XXX]` → Verify framework patterns work correctly
- `resume [RFC-XXX]` → Continue from checklist's current focus

## Core Process

Red → Green → Refactor → Checklist Update

**Philosophy**: Test-driven development of minimal apps to validate framework.
**Constraint**: All tests must pass before checklist updates.

## Workflow

### Workspace Requirement
**MANDATORY**: DEVELOP protocol only runs in application workspace
- Automatically navigates to application workspace if available
- Errors if workspace not found

**Usage**:
```bash
# From anywhere
@DEVELOP build RFC-001  # Auto-navigates to application-workspace/TestApp001
```

### TDD Implementation
1. Review RFC's TDD checklist current state
2. Extract requirement (4 parts: requirement, acceptance, boundary, refactor)
3. **RED**: Write failing test from acceptance criteria
4. **GREEN**: Minimal code to pass test
5. **REFACTOR**: Apply RFC's refactoring notes
6. Update checklist [x] with file:line references
7. Validate framework behavior works as expected

### Session Management
**Start**: Check RFC in Proposed/ and review checklist
**Execute**: Follow TDD cycle for each requirement  
**Track**: Update checklist with implementation details
**Validate**: Ensure framework patterns work correctly
**End**: Update session metadata for continuity

## Technical Details

**Input Requirements**:
- RFC in `Proposed/` directory (RFCs/Proposed/ in application workspace)
- Valid RFC_FORMAT.md structure
- TDD Implementation Checklist present

**Execution Context**:
- ONLY runs in application workspace: `application-workspace/`
- Creates test app in subdirectory named after RFC
- Requires application workspace to be set up

**Test Requirements**:
- MANDATORY: All tests pass before proceeding
- BLOCKING: Failures stop all work
- Run test suite before any checklist update
- Focus on framework validation tests

**Refactoring Patterns**:
- Keep test apps minimal
- Extract patterns only if testing requires it
- Small steps with tests after each change

## Execution Process

```bash
# DEVELOP only works in application workspace
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

# Set working directory to test app
APP_NAME=$(echo "$RFC_NUMBER" | sed 's/RFC-/TestApp/')
APP_DIR="$WORKSPACE_ROOT/$APP_NAME"

if [[ ! -d "$APP_DIR" ]]; then
    echo "Creating test app: $APP_NAME"
    mkdir -p "$APP_DIR"
    # Initialize as Swift package
    cd "$APP_DIR"
    swift package init --type executable
    # Add Axiom framework dependency
fi

cd "$APP_DIR" || exit 1

# Validate RFC exists in Proposed/
RFC_PATH="$WORKSPACE_ROOT/RFCs/Proposed/${RFC_NUMBER}*.md"
if ! ls $RFC_PATH 1> /dev/null 2>&1; then
    echo "RFC not found in Proposed/"
    echo "Use '@PLAN propose' first"
    exit 1
fi

# MANDATORY: Run test suite if exists
if [ -f "Package.swift" ]; then
    if ! swift test; then
        echo "BLOCKING: Tests failing"
        echo "Fix tests before proceeding"
        exit 1
    fi
fi

echo "Ready for test app TDD implementation"
```

## Framework Validation Focus

**Key Areas to Validate**:
1. **Actor Isolation**: Verify no data races
2. **State Propagation**: Measure < 16ms updates
3. **Context Lifecycle**: Test proper cleanup
4. **Navigation Flow**: Verify Context mediation
5. **Error Boundaries**: Test error propagation
6. **Memory Management**: Check for leaks

## Examples

**Start Test App Implementation**:
```
@DEVELOP build RFC-001
# Creates TestApp001/
# Opens RFC, shows checklist state
# Begins with Domain Model requirements
```

**Resume Session**:
```
@DEVELOP resume RFC-001  
# Continues from "Current Focus" in checklist
# Shows last completed item for context
```

**Run Validation**:
```
@DEVELOP validate RFC-001
# Runs framework-specific validation tests
# Measures performance metrics
# Verifies Axiom patterns work correctly
```

**Run Tests**:
```
@DEVELOP test RFC-001
# Runs swift test in TestApp001/
# Shows coverage for RFC requirements
```

## Validation Criteria

Each test app must validate:
- Axiom component relationships enforced
- Performance requirements met (16ms/50ms/1KB)
- No memory leaks or retain cycles
- Proper error handling through Context
- Navigation state consistency
- Actor concurrency safety

Transforms test app RFCs into working validation apps using TDD cycles with framework validation focus.