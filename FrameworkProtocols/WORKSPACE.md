# @WORKSPACE.md

**Trigger**: `@WORKSPACE [command]`

## Commands

- `setup` → Create framework worktree
- `reset` → Recreate worktree with clean state
- `status` → Show worktree details and health
- `cleanup` → Remove framework worktree

## Core Process

Create worktree → Configure sparse-checkout → Create protocol symlink → Track status

**Philosophy**: Isolated framework development environment.
**Constraint**: Workspace contains only AxiomFramework and protocol symlink.

## Workspace Structure

```
axiom-apple/                        # Top-level directory
├── Axiom/                          # Main repository
│   ├── FrameworkProtocols/         # Protocol definitions
│   └── AxiomFramework/            # Framework code
└── framework-workspace/            # Framework branch worktree
    ├── .git                       # Worktree git directory
    ├── .gitignore                 # Sparse-checkout aware
    ├── AxiomFramework/            # Active development
    ├── FrameworkProtocols@        # Symlink to ../Axiom/FrameworkProtocols/
    └── .workspace-status          # State tracking
```

## Workflow

### Initial Setup
1. Navigate to Axiom directory
2. Validate git repository root
3. Create framework worktree at ../framework-workspace
4. Configure cone sparse-checkout
5. Set sparse-checkout to only include AxiomFramework
6. Reapply sparse-checkout to clean workspace
7. Create symlink to FrameworkProtocols
8. Initialize status tracking

### Key Features
- **Minimal**: Only AxiomFramework and protocol symlink
- **Isolated**: Framework branch locked
- **Clean**: Sparse-checkout enforced
- **Tracked**: Status file monitors health

## Technical Details

**Sparse-Checkout Configuration**:
```
# Cone mode enabled
# Only AxiomFramework tracked
/AxiomFramework/
```

**Branch Management**:
- Framework workspace → framework branch only
- Main repository → coordination and integration

**File Exclusion**:
- All root files excluded (README, CLAUDE, etc.)
- All other directories excluded
- Only AxiomFramework tracked by git

## Execution Process

```bash
# Validate we're in Axiom git root
[[ -d .git ]] || { echo "Not in Axiom git root"; exit 1; }

# Setup command
if [[ "$1" == "setup" ]]; then
    # Create framework worktree at parent level
    if ! git worktree list | grep -q framework-workspace; then
        # Ensure framework branch exists
        if ! git show-ref --verify --quiet refs/heads/framework; then
            git checkout -b framework
            git push -u origin framework || true
            git checkout main
        fi
        git worktree add ../framework-workspace framework
    fi
    
    # Configure precise sparse-checkout
    cd ../framework-workspace/
    git sparse-checkout init --cone
    git sparse-checkout set AxiomFramework
    
    # Clean workspace by reapplying sparse-checkout
    git read-tree -m -u HEAD
    
    # Create protocol symlink
    ln -sf ../Axiom/FrameworkProtocols FrameworkProtocols
    
    # Initialize status
    echo "Created: $(date)" > .workspace-status
    echo "Branch: framework" >> .workspace-status
    echo "Type: framework-only" >> .workspace-status
    
    cd ../Axiom
    echo "Framework workspace ready at ../framework-workspace"
fi

# Reset command
if [[ "$1" == "reset" ]]; then
    git worktree remove ../framework-workspace --force 2>/dev/null || true
    exec "$0" setup
fi

# Status command
if [[ "$1" == "status" ]]; then
    if [[ -d ../framework-workspace ]]; then
        echo "framework-workspace: active"
        echo "Branch: $(cd ../framework-workspace && git branch --show-current)"
        echo "Contents:"
        (cd ../framework-workspace && ls -la | grep -E "^d|^l" | grep -v "^\.")
        [[ -f ../framework-workspace/.workspace-status ]] && echo "---" && cat ../framework-workspace/.workspace-status
    else
        echo "framework-workspace: not found"
    fi
fi

# Cleanup command
if [[ "$1" == "cleanup" ]]; then
    git worktree remove ../framework-workspace --force 2>/dev/null || true
    echo "Framework workspace removed"
fi
```

## Error Handling

**Common Issues**:
- "Not in Axiom git root" → Navigate to Axiom directory
- "Worktree already exists" → Use reset command
- "Extra files in workspace" → Sparse-checkout misconfigured

**Recovery Procedures**:
1. Extra files → `git sparse-checkout reapply`
2. Broken symlink → Recreate with correct path
3. Full reset → `@WORKSPACE reset`

## Examples

**First Time Setup**:
```
cd Axiom
@WORKSPACE setup
# Creating framework worktree...
# Configuring sparse-checkout...
# Framework workspace ready at ../framework-workspace
```

**Check Contents**:
```
@WORKSPACE status
# framework-workspace: active
# Branch: framework
# Contents:
# drwxr-xr-x  5 user  staff  160 date time AxiomFramework
# lrwxr-xr-x  1 user  staff   27 date time FrameworkProtocols -> ../Axiom/FrameworkProtocols
# ---
# Created: <timestamp>
# Branch: framework
# Type: framework-only
```

**Clean Restart**:
```
@WORKSPACE reset
# Removing existing workspace...
# Setting up fresh workspace...
# Framework workspace ready at ../framework-workspace
```

Manages minimal framework-only development workspace.