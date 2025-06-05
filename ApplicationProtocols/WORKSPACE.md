# @WORKSPACE.md

**Trigger**: `@WORKSPACE [command]`

## Commands

- `setup` → Create application worktree
- `reset` → Recreate worktree with clean state
- `status` → Show worktree details and health
- `cleanup` → Remove application worktree

## Core Process

Create worktree → Configure sparse-checkout → Create protocol symlink → Track status

**Philosophy**: Isolated application development environment.
**Constraint**: Workspace contains only AxiomExampleApp and protocol symlink.

## Workspace Structure

```
axiom-apple/                        # Top-level directory
├── Axiom/                          # Main repository
│   ├── ApplicationProtocols/       # Protocol definitions
│   └── AxiomExampleApp/           # Application code
└── application-workspace/          # Application branch worktree
    ├── .git                       # Worktree git directory
    ├── .gitignore                 # Sparse-checkout aware
    ├── AxiomExampleApp/           # Active development
    ├── ApplicationProtocols@      # Symlink to ../Axiom/ApplicationProtocols/
    └── .workspace-status          # State tracking
```

## Workflow

### Initial Setup
1. Navigate to Axiom directory
2. Validate git repository root
3. Create application worktree at ../application-workspace
4. Configure cone sparse-checkout
5. Set sparse-checkout to only include AxiomExampleApp
6. Reapply sparse-checkout to clean workspace
7. Create symlink to ApplicationProtocols
8. Initialize status tracking

### Key Features
- **Minimal**: Only AxiomExampleApp and protocol symlink
- **Isolated**: Application branch locked
- **Clean**: Sparse-checkout enforced
- **Tracked**: Status file monitors health

## Technical Details

**Sparse-Checkout Configuration**:
```
# Cone mode enabled
# Only AxiomExampleApp tracked
/AxiomExampleApp/
```

**Branch Management**:
- Application workspace → application branch only
- Main repository → coordination and integration

**File Exclusion**:
- All root files excluded (README, CLAUDE, etc.)
- All other directories excluded
- Only AxiomExampleApp tracked by git

## Execution Process

```bash
# Validate we're in Axiom git root
[[ -d .git ]] || { echo "Not in Axiom git root"; exit 1; }

# Setup command
if [[ "$1" == "setup" ]]; then
    # Create application worktree at parent level
    if ! git worktree list | grep -q application-workspace; then
        # Ensure application branch exists
        if ! git show-ref --verify --quiet refs/heads/application; then
            git checkout -b application
            git push -u origin application || true
            git checkout main
        fi
        git worktree add ../application-workspace application
    fi
    
    # Configure precise sparse-checkout
    cd ../application-workspace/
    git sparse-checkout init --cone
    git sparse-checkout set AxiomExampleApp
    
    # Clean workspace by reapplying sparse-checkout
    git read-tree -m -u HEAD
    
    # Create protocol symlink
    ln -sf ../Axiom/ApplicationProtocols ApplicationProtocols
    
    # Initialize status
    echo "Created: $(date)" > .workspace-status
    echo "Branch: application" >> .workspace-status
    echo "Type: application-only" >> .workspace-status
    
    cd ../Axiom
    echo "Application workspace ready at ../application-workspace"
fi

# Reset command
if [[ "$1" == "reset" ]]; then
    git worktree remove ../application-workspace --force 2>/dev/null || true
    exec "$0" setup
fi

# Status command
if [[ "$1" == "status" ]]; then
    if [[ -d ../application-workspace ]]; then
        echo "application-workspace: active"
        echo "Branch: $(cd ../application-workspace && git branch --show-current)"
        echo "Contents:"
        (cd ../application-workspace && ls -la | grep -E "^d|^l" | grep -v "^\.")
        [[ -f ../application-workspace/.workspace-status ]] && echo "---" && cat ../application-workspace/.workspace-status
    else
        echo "application-workspace: not found"
    fi
fi

# Cleanup command
if [[ "$1" == "cleanup" ]]; then
    git worktree remove ../application-workspace --force 2>/dev/null || true
    echo "Application workspace removed"
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
# Creating application worktree...
# Configuring sparse-checkout...
# Application workspace ready at ../application-workspace
```

**Check Contents**:
```
@WORKSPACE status
# application-workspace: active
# Branch: application
# Contents:
# drwxr-xr-x  4 user  staff  128 date time AxiomExampleApp
# lrwxr-xr-x  1 user  staff   29 date time ApplicationProtocols -> ../Axiom/ApplicationProtocols
# ---
# Created: <timestamp>
# Branch: application
# Type: application-only
```

**Clean Restart**:
```
@WORKSPACE reset
# Removing existing workspace...
# Setting up fresh workspace...
# Application workspace ready at ../application-workspace
```

Manages minimal application-only development workspace.