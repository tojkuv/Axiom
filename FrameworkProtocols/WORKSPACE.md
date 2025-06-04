# @WORKSPACE.md - Axiom Framework Workspace Management Command

Framework workspace management command that creates and manages git worktree for framework development

## Automated Mode Trigger

**When human sends**: `@WORKSPACE [optional-args]`
**Action**: Enter ultrathink mode and execute framework workspace management workflow

### Usage Modes
- **`@WORKSPACE`** → Show current workspace status and configuration
- **`@WORKSPACE setup`** → Initialize framework worktree with latest main branch changes
- **`@WORKSPACE reset`** → Reset and recreate worktree with clean state from main
- **`@WORKSPACE status`** → Show detailed worktree status and branch information
- **`@WORKSPACE cleanup`** → Remove and cleanup framework development worktree

### Framework Workspace Scope
**Workspace Focus**: Git worktree creation and management for framework development
**Branch Synchronization**: Ensures framework branch stays up to date with main
**Development Isolation**: Creates isolated development environment on framework branch
**Main Integration**: Framework branch regularly synchronized with main branch changes

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: WORKSPACE commands perform git worktree operations for development setup
**Version Control**: WORKSPACE creates isolated development environment, @CHECKPOINT handles commits
**Work Philosophy**: WORKSPACE creates development environment → Development in worktree → @CHECKPOINT integrates

Workspace commands manage development infrastructure:
1. **Worktree Creation**: Create framework-workspace/ directory
2. **Branch Synchronization**: Update framework branch with latest main changes
3. **Branch Assignment**: Permanent framework branch assignment to worktree
4. **Environment Validation**: Verify worktree functionality and development readiness
**Git Operations**: WORKSPACE commands create worktree and manage development infrastructure

## Framework Workspace Management Philosophy

**Core Principle**: Framework workspace management eliminates branch switching friction by creating a permanent development environment for framework development. The workspace maintains complete development context synchronized with main branch.

**Workspace Workflow**: @WORKSPACE creates worktree → Developers work in isolated environment → @CHECKPOINT integrates changes → @WORKSPACE syncs with main

### 🎯 **Clear Separation of Concerns**
- **WORKSPACE**: Creates and manages worktree infrastructure → NO development work
- **PLAN/DEVELOP/etc**: Work within designated worktrees → NO worktree management
- **CHECKPOINT**: Commits and integrates from worktrees → NO worktree creation
- **Development**: Occurs entirely within worktree boundaries → NO branch switching

**Quality Standards**: Workspace management ensures clean development isolation, real-time integration, and parallel development capability

**Technical Focus Only**: Workspace management strictly focuses on development infrastructure setup. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Framework Workspace Management Methodology

### Phase 1: Workspace Environment Analysis
1. **Current State Assessment** → Analyze existing git repository and branch structure
2. **Worktree Validation** → Check for existing framework worktree and potential conflicts
3. **Branch Status Review** → Understand framework branch state and sync with main
4. **Infrastructure Requirements** → Assess workspace requirements and setup prerequisites
5. **Synchronization Planning** → Plan framework branch update from main branch

### Phase 2: Worktree Infrastructure Creation
1. **Cleanup Existing Worktree** → Remove any existing framework worktree configuration
2. **Branch Synchronization** → Update framework branch with latest main changes
3. **Framework Workspace Creation** → Create framework-workspace/ with synchronized branch
4. **Environment Validation** → Verify worktree functionality and development readiness
5. **Status Tracking** → Create workspace status file for monitoring

### Phase 3: Workspace Configuration and Documentation
1. **Development Environment Setup** → Configure workspace for optimal framework development
2. **Synchronization Verification** → Validate framework branch is up to date with main
3. **Workspace Documentation** → Document workspace usage and development procedures
4. **Development Preparation** → Prepare workspace for framework development workflow
5. **Status Monitoring** → Establish workspace status monitoring and validation

## Framework Workspace Management Process

### Workspace Structure Creation
**Target Structure**:
```
Axiom/ (main repository - coordination hub)
├── .git/                           # Main git repository
├── FrameworkProtocols/             # Protocol coordination (main branch)
├── ApplicationProtocols/           # Protocol coordination (main branch)
├── AxiomFramework/                 # Framework package (main branch)
├── AxiomExampleApp/                # Example application (main branch)
└── framework-workspace/            # Framework development worktree
    ├── AxiomFramework/            # Active framework development
    ├── FrameworkProtocols/        # Framework protocol access
    └── .workspace-status          # Development state tracking
```

### Workspace Integration Strategy
- **Framework Workspace** → Permanent framework branch, synchronized with main
- **Branch Synchronization** → Framework branch regularly updated from main
- **Protocol Access** → Workspace has access to framework protocols
- **Development Isolation** → Clean development environment for framework work

## Framework Workspace Command Execution

**Command**: `@WORKSPACE [setup|reset|status|cleanup]`
**Action**: Execute comprehensive workspace management workflow with development environment preparation

### 🔄 **Workspace Setup Process**

**CRITICAL**: WORKSPACE commands manage git worktree infrastructure

```bash
# Workspace management execution
echo "🏗️ Framework Workspace Management"
echo "📍 Repository: $(pwd)"
echo "🌿 Current branch: $(git branch --show-current)"

# Validate repository state
if [ ! -d ".git" ]; then
    echo "❌ Must be run from git repository root"
    exit 1
fi
```

**Automated Workspace Setup Process**:
1. **Repository Validation** → Ensure execution from git repository root
2. **Existing Worktree Cleanup** → Remove any existing framework worktree
3. **Branch Synchronization** → Update framework branch with latest main changes
4. **Framework Worktree Creation** → Create framework-workspace/ with updated branch
5. **Environment Validation** → Verify worktree functionality and development capabilities
6. **Development Preparation** → Prepare workspace for immediate development use
**Git Operations**: WORKSPACE commands create and manage worktree infrastructure

```bash
# Workspace setup implementation
echo "🧹 Cleaning existing framework worktree..."
git worktree remove framework-workspace 2>/dev/null || true

echo "🔄 Synchronizing framework branch with main..."
# Ensure framework branch exists
if ! git show-ref --verify --quiet refs/heads/framework; then
    echo "📝 Creating framework branch from main..."
    git checkout -b framework main
    git push -u origin framework
    git checkout main
else
    echo "📝 Updating framework branch with latest main changes..."
    git checkout framework
    git merge main --no-edit -m "Sync framework branch with main" || {
        echo "⚠️ Merge conflict detected - resolving by accepting main changes"
        git reset --hard main
    }
    git push origin framework --force-with-lease
    git checkout main
fi

echo "🏗️ Creating framework development workspace..."
git worktree add framework-workspace framework

echo "📊 Creating workspace status tracking..."
echo "Framework workspace created: $(date)" > framework-workspace/.workspace-status
echo "Synchronized with main: $(git rev-parse --short main)" >> framework-workspace/.workspace-status

echo "✅ Framework workspace ready for development"
echo "📍 Framework workspace: framework-workspace/"
echo "🔄 Branch synchronized with main: $(git rev-parse --short main)"
echo "💡 Use '@CHECKPOINT' to integrate changes back to main"
```

**Framework Workspace Execution Examples**:
- `@WORKSPACE setup` → Create framework worktree synchronized with main
- `@WORKSPACE reset` → Reset framework worktree with latest main changes
- `@WORKSPACE status` → Show framework worktree status and synchronization info
- `@WORKSPACE cleanup` → Remove framework development worktree

## Framework Workspace Standards

### Workspace Creation Standards
- **Clean Environment**: Complete removal of existing framework worktree before creation
- **Branch Synchronization**: Framework branch updated with latest main changes
- **Branch Isolation**: Worktree permanently assigned to framework branch
- **Development Readiness**: Workspace configured for immediate development use
- **Status Tracking**: Workspace creation and synchronization status monitoring

### Workspace Quality Standards
- **Infrastructure Reliability**: Robust worktree creation with error handling
- **Synchronization Verification**: Validated framework branch is current with main
- **Development Efficiency**: Optimized workspace configuration for development velocity
- **Clean State**: Framework branch reset to main when conflicts arise
- **Documentation**: Clear workspace usage and synchronization procedures

## Framework Workspace Workflow Integration

**Workspace Purpose**: Create development infrastructure for framework development
**Development Integration**: Workspace provides isolated environment for FrameworkProtocols
**Main Synchronization**: Framework branch stays synchronized with main branch changes
**Protocol Access**: Workspace has access to framework development protocols
**Infrastructure Management**: Workspace lifecycle management independent of development workflows

## Framework Workspace Coordination

**Infrastructure Creation**: Creates isolated development environment for framework work
**Branch Management**: Maintains framework branch synchronized with main
**Development Integration**: Workspace integrates with existing FrameworkProtocols
**Environment Management**: Workspace lifecycle management with setup, reset, and cleanup capabilities
**Main Integration**: Regular synchronization ensures framework branch stays current

---

**FRAMEWORK WORKSPACE COMMAND STATUS**: Framework workspace management command for isolated development
**CORE FOCUS**: Git worktree infrastructure for framework development with main synchronization
**WORKSPACE CREATION**: Creates framework-workspace/ with synchronized framework branch
**BRANCH SYNCHRONIZATION**: Framework branch regularly updated from main branch
**DEVELOPMENT VELOCITY**: Eliminates branch switching while maintaining main integration

**Use FrameworkProtocols/@WORKSPACE for framework development infrastructure management.**