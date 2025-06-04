# @WORKSPACE.md

**Trigger**: `@WORKSPACE [command]`

## Commands

- `setup` → Create framework and application worktrees
- `reset` → Recreate worktrees with clean state
- `status` → Show worktree details and health
- `cleanup` → Remove all worktrees

## Core Process

Create worktrees → Setup symlinks → Track status

**Philosophy**: Isolated development environments for parallel work.
**Constraint**: Permanent branch assignment per workspace.

## Workspace Structure

```
Axiom/                              # Main repository
├── framework-workspace/            # Framework branch worktree
│   ├── AxiomFramework/            # Active development
│   └── .workspace-status          # State tracking
└── application-workspace/          # Application branch worktree  
    ├── AxiomExampleApp/           # Active development
    ├── AxiomFramework-dev@        # Symlink to framework
    └── .workspace-status          # State tracking
```

## Workflow

### Initial Setup
1. Validate git repository root
2. Remove any existing worktrees
3. Create framework worktree on `framework` branch
4. Create application worktree on `application` branch
5. Symlink framework into application workspace
6. Create status tracking files

### Key Features
- **Isolation**: Each workspace locked to its branch
- **Integration**: Real-time framework access via symlinks
- **Persistence**: No branch switching required
- **Tracking**: Status files monitor workspace health

## Technical Details

**Branch Assignment**:
- `framework-workspace/` → framework branch only
- `application-workspace/` → application branch only
- Main repository → coordination and merging

**Symlink Structure**:
```bash
# In application-workspace/
ln -sf ../framework-workspace/AxiomFramework AxiomFramework-dev
```

**Status Tracking**:
- `.workspace-status` files in each workspace
- Records creation time and last update
- Used by other protocols for validation

## Execution Process

```bash
# Setup worktrees
git worktree add framework-workspace framework || {
    git checkout -b framework
    git push origin framework  
    git worktree add framework-workspace framework
}

git worktree add application-workspace application || {
    git checkout -b application
    git push origin application
    git worktree add application-workspace application  
}

# Create integration symlink
cd application-workspace/
ln -sf ../framework-workspace/AxiomFramework AxiomFramework-dev
cd ..

# Initialize status tracking
echo "Created: $(date)" > framework-workspace/.workspace-status
echo "Created: $(date)" > application-workspace/.workspace-status
```

## Examples

**First Time Setup**:
```
@WORKSPACE setup
# Creates both worktrees
# Sets up symlinks
# Shows success status
```

**Check Health**:
```
@WORKSPACE status
# framework-workspace: healthy (framework branch)
# application-workspace: healthy (application branch)
# Symlink: active
```

**Clean Restart**:
```
@WORKSPACE reset
# Removes existing worktrees
# Recreates with clean state
# Preserves uncommitted work warning
```

Creates isolated worktrees for parallel framework and application development.