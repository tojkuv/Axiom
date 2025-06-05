# @WORKSPACE.md

**Trigger**: `@WORKSPACE [command] [workspace]`

## Commands

- `setup [workspace|all]` → Create workspace worktree(s)
- `reset [workspace|all]` → Recreate worktree(s) with clean state
- `status [workspace|all]` → Show worktree details and health
- `cleanup [workspace|all]` → Remove workspace worktree(s)

## Workspaces

- `framework` → AxiomFramework development (with FrameworkProtocols symlink)
- `application` → AxiomExampleApp development (with ApplicationProtocols symlink)
- `protocols` → Protocols management (entire Protocols directory)
- `all` → All workspaces

## Core Process

Create worktree → Configure sparse-checkout → Create protocol symlink → Track status

**Philosophy**: Isolated development environments for each component.
**Constraint**: Uses external script to manage workspace complexity and supports batch operations.

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
7. Create workspace-specific .gitignore file
8. Initialize status tracking

### Key Features
- **Minimal**: Only specified directory and protocol symlink
- **Isolated**: Each workspace on its own branch
- **Clean**: Sparse-checkout enforced
- **Tracked**: Status file monitors health

## Technical Details

**Script Location**: `Protocols/workspace.sh`

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

## Gitignore Configuration

Each workspace requires a tailored .gitignore file to prevent committing build artifacts and temporary files:

**Framework Workspace** (.gitignore):
```
# Swift Package Manager
.build/
.swiftpm/
Package.resolved
DerivedData/

# macOS
.DS_Store
```

**Application Workspace** (.gitignore):
```
# Xcode
xcuserdata/
*.xcscmblueprint
*.xccheckout
DerivedData/
build/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store
```

**Protocols Workspace** (.gitignore):
```
# macOS
.DS_Store

# Temporary files
*.tmp
*.swp
```

## Execution Process

```bash
# Execute workspace script with command and workspace
PROTOCOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$PROTOCOL_DIR/workspace.sh" "$1" "$2"
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
3. Full reset → `@WORKSPACE reset [workspace]`

## Examples

**Framework Setup**:
```
@WORKSPACE setup framework
# Setting up framework workspace...
# Creating framework worktree...
# Configuring sparse-checkout...
# framework workspace ready at ../framework-workspace
```

**All Workspaces Status**:
```
@WORKSPACE status all
# === framework workspace ===
# Status: active
# Branch: framework
# === application workspace ===
# Status: active
# Branch: application
# === protocols workspace ===
# Status: active
# Branch: protocols
```

**Setup All Workspaces**:
```
@WORKSPACE setup all
# Setting up framework workspace...
# framework workspace ready at ../framework-workspace
# Setting up application workspace...
# application workspace ready at ../application-workspace
# Setting up protocols workspace...
# protocols workspace ready at ../protocols-workspace
```

**Clean Restart**:
```
@WORKSPACE reset framework
# Removing framework workspace...
# Setting up framework workspace...
# framework workspace ready at ../framework-workspace
```

**Remove All Workspaces**:
```
@WORKSPACE cleanup all
# Removing framework workspace...
# framework workspace removed
# Removing application workspace...
# application workspace removed
# Removing protocols workspace...
# protocols workspace removed
```

Manages isolated development workspaces for framework, application, and protocols.