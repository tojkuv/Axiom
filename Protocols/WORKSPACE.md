# @WORKSPACE.md

**Trigger**: `@WORKSPACE [workspace] [command]`

## Commands

- `setup` → Create workspace worktree
- `reset` → Recreate worktree with clean state
- `status` → Show worktree details and health
- `cleanup` → Remove workspace worktree

## Workspaces

- `framework` → AxiomFramework development (with FrameworkProtocols symlink)
- `application` → AxiomExampleApp development (with ApplicationProtocols symlink)
- `protocols` → Protocols management (entire Protocols directory)

## Core Process

Create worktree → Configure sparse-checkout → Create protocol symlink → Track status

**Philosophy**: Isolated development environments for each component.
**Constraint**: Each workspace contains only its specific directory and protocol symlink.
**Safety**: Automatically navigates to Axiom directory regardless of invocation location.

## Workspace Structure

```
axiom-apple/                        # Top-level directory
├── Axiom/                          # Main repository
│   ├── AxiomFramework/            # Framework code
│   ├── AxiomExampleApp/           # Application code
│   └── Protocols/                 # All protocols
│       ├── CHECKPOINT.md
│       ├── WORKSPACE.md
│       ├── PROTOCOL_FORMAT.md
│       ├── FrameworkProtocols/
│       └── ApplicationProtocols/
├── framework-workspace/           # Framework branch worktree
│   ├── AxiomFramework/           # Active development
│   └── FrameworkProtocols@       # Symlink to ../Axiom/Protocols/FrameworkProtocols/
├── application-workspace/         # Application branch worktree
│   ├── AxiomExampleApp/          # Active development
│   └── ApplicationProtocols@     # Symlink to ../Axiom/Protocols/ApplicationProtocols/
└── protocols-workspace/           # Protocols branch worktree
    └── Protocols/                # Active protocol management
```

## Workflow

### Initial Setup
1. Navigate to Axiom directory
2. Validate git repository root
3. Create workspace worktree at ../[workspace]-workspace
4. Configure cone sparse-checkout for specific directory
5. Reapply sparse-checkout to clean workspace
6. Create protocol symlinks (for framework/application workspaces)
7. Initialize status tracking

### Key Features
- **Minimal**: Only specified directory and protocol symlink
- **Isolated**: Each workspace on its own branch
- **Clean**: Sparse-checkout enforced
- **Tracked**: Status file monitors health

## Technical Details

**Sparse-Checkout Configuration**:
```
# Framework workspace
/AxiomFramework/

# Application workspace
/AxiomExampleApp/

# Protocols workspace
/Protocols/
```

**Branch Management**:
- Framework workspace → framework branch only
- Application workspace → application branch only
- Protocols workspace → protocols branch only
- Main repository → coordination and integration

**File Exclusion**:
- All root files excluded (README, etc.)
- All other directories excluded
- Only specified directory tracked by git

## Execution Process

```bash
# Determine correct Axiom directory
AXIOM_DIR="/Users/tojkuv/Documents/GitHub/axiom-apple/Axiom"

# Validate Axiom directory exists
if [[ ! -d "$AXIOM_DIR" ]]; then
    echo "ERROR: Axiom directory not found at $AXIOM_DIR"
    echo "Cannot perform workspace operations"
    exit 1
fi

# Change to Axiom directory for all operations
cd "$AXIOM_DIR" || exit 1

# Validate we're in Axiom git root
[[ -d .git ]] || { echo "Not in Axiom git root"; exit 1; }

# Safety check: Verify expected directory structure
if [[ ! -d "AxiomFramework" ]] || [[ ! -d "AxiomExampleApp" ]] || [[ ! -d "Protocols" ]]; then
    echo "ERROR: Expected Axiom directory structure not found"
    echo "Missing AxiomFramework, AxiomExampleApp, or Protocols directories"
    exit 1
fi

# Parse arguments
WORKSPACE_TYPE="$1"
COMMAND="$2"

# Validate workspace type
if [[ ! "$WORKSPACE_TYPE" =~ ^(framework|application|protocols)$ ]]; then
    echo "Usage: @WORKSPACE [framework|application|protocols] [setup|reset|status|cleanup]"
    exit 1
fi

# Set workspace-specific variables
case "$WORKSPACE_TYPE" in
    framework)
        WORKSPACE_DIR="../framework-workspace"
        BRANCH_NAME="framework"
        SPARSE_PATH="AxiomFramework"
        PROTOCOL_SOURCE="../Axiom/Protocols/FrameworkProtocols"
        PROTOCOL_LINK="FrameworkProtocols"
        ;;
    application)
        WORKSPACE_DIR="../application-workspace"
        BRANCH_NAME="application"
        SPARSE_PATH="AxiomExampleApp"
        PROTOCOL_SOURCE="../Axiom/Protocols/ApplicationProtocols"
        PROTOCOL_LINK="ApplicationProtocols"
        ;;
    protocols)
        WORKSPACE_DIR="../protocols-workspace"
        BRANCH_NAME="protocols"
        SPARSE_PATH="Protocols"
        PROTOCOL_SOURCE=""
        PROTOCOL_LINK=""
        ;;
esac

# Setup command
if [[ "$COMMAND" == "setup" ]]; then
    # Create worktree at parent level
    if ! git worktree list | grep -q "$WORKSPACE_DIR"; then
        # Ensure branch exists
        if ! git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
            git checkout -b "$BRANCH_NAME"
            git push -u origin "$BRANCH_NAME" || true
            git checkout main
        fi
        git worktree add "$WORKSPACE_DIR" "$BRANCH_NAME"
    fi
    
    # Configure precise sparse-checkout
    cd "$WORKSPACE_DIR"
    git sparse-checkout init --cone
    git sparse-checkout set "$SPARSE_PATH"
    
    # Clean workspace by reapplying sparse-checkout
    git read-tree -m -u HEAD
    
    # Create protocol symlink (not for protocols workspace)
    if [[ -n "$PROTOCOL_LINK" ]]; then
        ln -sf "$PROTOCOL_SOURCE" "$PROTOCOL_LINK"
    fi
    
    # Initialize status
    echo "Created: $(date)" > .workspace-status
    echo "Branch: $BRANCH_NAME" >> .workspace-status
    echo "Type: $WORKSPACE_TYPE" >> .workspace-status
    
    cd ../Axiom
    echo "$WORKSPACE_TYPE workspace ready at $WORKSPACE_DIR"
fi

# Reset command
if [[ "$COMMAND" == "reset" ]]; then
    git worktree remove "$WORKSPACE_DIR" --force 2>/dev/null || true
    exec "$0" "$WORKSPACE_TYPE" setup
fi

# Status command
if [[ "$COMMAND" == "status" ]]; then
    if [[ -d "$WORKSPACE_DIR" ]]; then
        echo "$WORKSPACE_TYPE-workspace: active"
        echo "Branch: $(cd "$WORKSPACE_DIR" && git branch --show-current)"
        echo "Contents:"
        (cd "$WORKSPACE_DIR" && ls -la | grep -E "^d|^l" | grep -v "^\.")
        [[ -f "$WORKSPACE_DIR/.workspace-status" ]] && echo "---" && cat "$WORKSPACE_DIR/.workspace-status"
    else
        echo "$WORKSPACE_TYPE-workspace: not found"
    fi
fi

# Cleanup command
if [[ "$COMMAND" == "cleanup" ]]; then
    git worktree remove "$WORKSPACE_DIR" --force 2>/dev/null || true
    echo "$WORKSPACE_TYPE workspace removed"
fi
```

## Error Handling

**Common Issues**:
- "Not in Axiom git root" → Navigate to Axiom directory
- "Worktree already exists" → Use reset command
- "Extra files in workspace" → Sparse-checkout misconfigured
- "Invalid workspace type" → Use framework, application, or protocols

**Recovery Procedures**:
1. Extra files → `git sparse-checkout reapply`
2. Broken symlink → Recreate with correct path
3. Full reset → `@WORKSPACE [workspace] reset`

## Examples

**Framework Setup**:
```
@WORKSPACE framework setup
# Creating framework worktree...
# Configuring sparse-checkout...
# framework workspace ready at ../framework-workspace
```

**Application Status**:
```
@WORKSPACE application status
# application-workspace: active
# Branch: application
# Contents:
# drwxr-xr-x  4 user  staff  128 date time AxiomExampleApp
# lrwxr-xr-x  1 user  staff   32 date time ApplicationProtocols -> ../Axiom/Protocols/ApplicationProtocols
# ---
# Created: <timestamp>
# Branch: application
# Type: application
```

**Protocols Workspace**:
```
@WORKSPACE protocols setup
# Creating protocols worktree...
# Configuring sparse-checkout...
# protocols workspace ready at ../protocols-workspace

@WORKSPACE protocols status
# protocols-workspace: active
# Branch: protocols
# Contents:
# drwxr-xr-x  5 user  staff  160 date time Protocols
```

**Clean Restart**:
```
@WORKSPACE framework reset
# Removing existing workspace...
# Setting up fresh workspace...
# framework workspace ready at ../framework-workspace
```

Manages isolated development workspaces for framework, application, and protocols.