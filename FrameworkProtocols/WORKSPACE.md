# @WORKSPACE.md - Axiom Framework Workspace Management Command

Framework workspace management command that creates and manages git worktrees for development

## Automated Mode Trigger

**When human sends**: `@WORKSPACE [optional-args]`
**Action**: Enter ultrathink mode and execute framework workspace management workflow

### Usage Modes
- **`@WORKSPACE`** → Show current workspace status and configuration
- **`@WORKSPACE setup`** → Initialize framework and application worktrees for parallel development
- **`@WORKSPACE reset`** → Reset and recreate worktrees with clean state
- **`@WORKSPACE status`** → Show detailed worktree status and branch information
- **`@WORKSPACE cleanup`** → Remove and cleanup all development worktrees

### Framework Workspace Scope
**Workspace Focus**: Git worktree creation and management for parallel framework and application development
**Branch Independence**: Creates isolated development environments on permanent branches
**Development Integration**: Enables simultaneous framework and application development
**Real-time Sync**: Framework changes immediately available to application workspace

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: WORKSPACE commands perform git worktree operations for development setup
**Version Control**: WORKSPACE creates isolated development environments, @CHECKPOINT handles commits
**Work Philosophy**: WORKSPACE creates development environments → Parallel development in worktrees → @CHECKPOINT integrates

Workspace commands manage development infrastructure:
1. **Worktree Creation**: Create framework-workspace/ and application-workspace/ directories
2. **Branch Assignment**: Permanent branch assignment (framework, application) to each worktree
3. **Integration Setup**: Real-time framework-application connection via symlinks
4. **Environment Validation**: Verify worktree functionality and development readiness
**Git Operations**: WORKSPACE commands create worktrees and manage development infrastructure

## Framework Workspace Management Philosophy

**Core Principle**: Framework workspace management eliminates branch switching friction by creating permanent development environments for parallel framework and application development. Each workspace maintains complete development context.

**Workspace Workflow**: @WORKSPACE creates worktrees → Developers work in isolated environments → Real-time integration via symlinks → @CHECKPOINT integrates changes

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
2. **Worktree Validation** → Check for existing worktrees and potential conflicts
3. **Branch Status Review** → Understand current branch state and development context
4. **Infrastructure Requirements** → Assess workspace requirements and setup prerequisites
5. **Integration Planning** → Plan real-time framework-application integration approach

### Phase 2: Worktree Infrastructure Creation
1. **Cleanup Existing Worktrees** → Remove any existing worktree configurations
2. **Framework Workspace Creation** → Create framework-workspace/ with framework branch
3. **Application Workspace Creation** → Create application-workspace/ with application branch
4. **Real-time Integration Setup** → Create symlinks for framework-application connection
5. **Environment Validation** → Verify worktree functionality and development readiness

### Phase 3: Workspace Configuration and Documentation
1. **Development Environment Setup** → Configure each workspace for optimal development
2. **Integration Testing** → Validate real-time framework-application synchronization
3. **Workspace Documentation** → Document workspace usage and development procedures
4. **Development Coordination** → Prepare workspaces for parallel development workflows
5. **Status Monitoring** → Establish workspace status monitoring and validation

## Framework Workspace Management Process

### Workspace Structure Creation
**Target Structure**:
```
Axiom/ (main repository - coordination hub)
├── .git/                           # Main git repository
├── FrameworkProtocols/             # Protocol coordination (main branch)
├── ApplicationProtocols/           # Protocol coordination (main branch)
├── framework-workspace/            # Framework development worktree
│   ├── AxiomFramework/            # Active framework development
│   ├── FrameworkProtocols/        # Framework protocol access
│   └── .workspace-status          # Development state tracking
└── application-workspace/          # Application development worktree
    ├── AxiomExampleApp/           # Active application development
    ├── ApplicationProtocols/      # Application protocol access
    ├── AxiomFramework-dev@        # Symlink to framework-workspace/AxiomFramework
    └── .workspace-status          # Development state tracking
```

### Workspace Integration Strategy
- **Framework Workspace** → Permanent framework branch, complete framework development context
- **Application Workspace** → Permanent application branch, real-time framework access via symlink
- **Protocol Access** → Each workspace has access to relevant protocols
- **Real-time Sync** → Framework changes immediately available to application development

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
2. **Existing Worktree Cleanup** → Remove any existing development worktrees
3. **Branch Preparation** → Ensure framework and application branches exist
4. **Framework Worktree Creation** → Create framework-workspace/ with framework branch
5. **Application Worktree Creation** → Create application-workspace/ with application branch
6. **Real-time Integration Setup** → Create symlinks for framework-application connection
7. **Environment Validation** → Verify worktree functionality and development capabilities
8. **Development Preparation** → Prepare workspaces for immediate development use
**Git Operations**: WORKSPACE commands create and manage worktree infrastructure

```bash
# Workspace setup implementation
echo "🧹 Cleaning existing worktrees..."
git worktree remove framework-workspace 2>/dev/null || true
git worktree remove application-workspace 2>/dev/null || true

echo "🏗️ Creating framework development workspace..."
git worktree add framework-workspace framework || {
    echo "📝 Creating framework branch..."
    git checkout -b framework
    git push origin framework
    git worktree add framework-workspace framework
}

echo "🏗️ Creating application development workspace..."
git worktree add application-workspace application || {
    echo "📝 Creating application branch..."
    git checkout -b application
    git push origin application
    git worktree add application-workspace application
}

echo "🔗 Setting up real-time framework integration..."
cd application-workspace/
ln -sf ../framework-workspace/AxiomFramework AxiomFramework-dev
cd ..

echo "📊 Creating workspace status tracking..."
echo "Framework workspace created: $(date)" > framework-workspace/.workspace-status
echo "Application workspace created: $(date)" > application-workspace/.workspace-status

echo "✅ Development workspaces ready for parallel development"
echo "📍 Framework workspace: framework-workspace/"
echo "📍 Application workspace: application-workspace/"
echo "🔗 Real-time integration: application-workspace/AxiomFramework-dev → framework-workspace/AxiomFramework"
```

**Framework Workspace Execution Examples**:
- `@WORKSPACE setup` → Create development worktrees for parallel development
- `@WORKSPACE reset` → Reset worktrees with clean state
- `@WORKSPACE status` → Show worktree status and branch information
- `@WORKSPACE cleanup` → Remove all development worktrees

## Framework Workspace Standards

### Workspace Creation Standards
- **Clean Environment**: Complete removal of existing worktrees before creation
- **Branch Isolation**: Each worktree permanently assigned to specific development branch
- **Real-time Integration**: Framework changes immediately accessible to application workspace
- **Development Readiness**: Workspaces configured for immediate development use
- **Status Tracking**: Workspace creation and status monitoring

### Workspace Quality Standards
- **Infrastructure Reliability**: Robust worktree creation with error handling
- **Integration Verification**: Validated real-time framework-application connection
- **Development Efficiency**: Optimized workspace configuration for development velocity
- **Clean Separation**: Clear workspace boundaries with proper isolation
- **Documentation**: Clear workspace usage and development procedures

## Framework Workspace Workflow Integration

**Workspace Purpose**: Create development infrastructure for parallel framework and application development
**Development Integration**: Workspaces provide isolated environments for FrameworkProtocols and ApplicationProtocols
**Real-time Sync**: Framework changes immediately available to application development
**Protocol Access**: Each workspace has access to relevant development protocols
**Infrastructure Management**: Workspace lifecycle management independent of development workflows

## Framework Workspace Coordination

**Infrastructure Creation**: Creates isolated development environments with parallel development capability
**Development Integration**: Workspaces integrate with existing FrameworkProtocols and ApplicationProtocols
**Real-time Synchronization**: Framework-application integration via symlink connections
**Environment Management**: Workspace lifecycle management with setup, reset, and cleanup capabilities
**Development Coordination**: Enables coordinated parallel development across framework and application teams

---

**FRAMEWORK WORKSPACE COMMAND STATUS**: Framework workspace management command with parallel development infrastructure
**CORE FOCUS**: Git worktree infrastructure for simultaneous framework and application development  
**WORKSPACE CREATION**: Creates framework-workspace/ and application-workspace/ with permanent branch assignment
**REAL-TIME INTEGRATION**: Framework changes immediately available to application workspace via symlinks
**DEVELOPMENT VELOCITY**: Eliminates branch switching and enables true parallel development

**Use FrameworkProtocols/@WORKSPACE for development infrastructure management and parallel development setup.**