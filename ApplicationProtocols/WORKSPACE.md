# @WORKSPACE.md

**Trigger**: `@WORKSPACE [command]`

## Commands

- `setup` → Create application workspace with protocol access
- `reset` → Recreate workspace with clean state
- `status` → Show workspace health and dependencies
- `cleanup` → Remove application workspace

## Core Process

Create workspace → Setup protocol symlinks → Validate dependencies

**Philosophy**: Isolated application development with framework integration.
**Constraint**: Application workspace depends on framework availability.

## Workspace Structure

```
Axiom/                              # Main repository
├── ApplicationProtocols/           # Protocol files (root only)
├── FrameworkProtocols/            # Protocol files (root only)
├── AxiomFramework/                # Framework package
└── application-workspace/          # Application branch worktree
    ├── AxiomExampleApp/           # iOS application development
    ├── ApplicationProtocols@      # Symlink to ../ApplicationProtocols/
    └── .workspace-status          # State tracking
```

## Workflow

### Application Setup
1. Validate framework package exists
2. Create application worktree on `application` branch
3. Symlink to ApplicationProtocols for workflow access
4. Configure workspace dependencies
5. Create status tracking files

### Key Features
- **Application Focus**: Dedicated iOS application development
- **Protocol Access**: Direct access to application workflows
- **Framework Integration**: Uses framework as external dependency
- **Isolation**: Cannot modify framework code directly

## Technical Details

**Branch Assignment**:
- `application-workspace/` → application branch only
- Framework access → via workspace dependency or published package

**Symlink Structure**:
```bash
# In application-workspace/
ln -s ../ApplicationProtocols ApplicationProtocols
```

**Dependencies**:
- Framework package must exist (AxiomFramework/)
- ApplicationProtocols must be present at root
- Xcode project must be properly configured

## Execution Process

```bash
# Create application workspace
git worktree add application-workspace application || {
    git checkout -b application
    git push origin application
    git worktree add application-workspace application
}

# Create protocol symlink
cd application-workspace/
ln -s ../ApplicationProtocols ApplicationProtocols
cd ..

# Initialize status tracking
echo "Created: $(date)" > application-workspace/.workspace-status
echo "Framework dependency: AxiomFramework" >> application-workspace/.workspace-status
```

## Examples

**Application Development Setup**:
```
@WORKSPACE setup
# Creates application workspace
# Links to ApplicationProtocols
# Validates framework dependency
```

**Health Check**:
```
@WORKSPACE status
# application-workspace: healthy (application branch)
# ApplicationProtocols: symlinked
# Framework dependency: available
```

**Clean Development Start**:
```
@WORKSPACE reset
# Removes existing workspace
# Recreates with clean state
# Preserves framework integration
```

Creates isolated application workspace with protocol access and framework integration.