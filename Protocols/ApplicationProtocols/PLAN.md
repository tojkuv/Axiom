# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show application feature status
- `feature [name]` → Plan new application feature
- `list` → List all planned features
- `implement [name]` → Mark feature as ready for implementation

## Core Process

Plan → Design → Review → Implement

**Philosophy**: Feature-driven application planning.
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

echo "Ready for application planning in workspace: $WORKSPACE_ROOT"
```

## Examples

**Plan New Feature**:
```
@PLAN feature user-authentication
# Creates feature plan in workspace
```

**Check Status**:
```
@PLAN status
# Shows all planned features
```

Manages application feature planning within isolated workspace.