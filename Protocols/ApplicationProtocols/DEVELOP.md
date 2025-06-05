# @DEVELOP.md

**Trigger**: `@DEVELOP [command] [args]`

## Commands

- `status` → Show application development status
- `build` → Build application project
- `test` → Run application tests
- `run` → Launch application

## Core Process

Build → Test → Run → Debug

**Philosophy**: Iterative application development with testing.
**Context**: All operations occur within application-workspace only.

## Execution Process

```bash
# Detect workspace context
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

# Set working directory to application
APP_DIR="$WORKSPACE_ROOT/AxiomExampleApp"
cd "$APP_DIR" || exit 1

echo "Ready for application development in workspace: $WORKSPACE_ROOT"
```

## Examples

**Build Application**:
```
@DEVELOP build
# Builds AxiomExampleApp in workspace
```

**Run Tests**:
```
@DEVELOP test
# Runs application test suite
```

Manages application development lifecycle within isolated workspace.