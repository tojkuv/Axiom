# @WORKSPACE.md - Axiom Application Workspace Management Command

Application workspace management command that creates and manages git worktrees for development

## Automated Mode Trigger

**When human sends**: `@WORKSPACE [optional-args]`
**Action**: Enter ultrathink mode and execute application workspace management workflow

### Usage Modes
- **`@WORKSPACE`** → Show current workspace status and configuration
- **`@WORKSPACE setup`** → Initialize framework and application worktrees for parallel development
- **`@WORKSPACE reset`** → Reset and recreate worktrees with clean state
- **`@WORKSPACE status`** → Show detailed worktree status and branch information
- **`@WORKSPACE cleanup`** → Remove and cleanup all development worktrees

### Application Workspace Scope
**Workspace Focus**: Git worktree creation and management for parallel framework and application development
**Branch Independence**: Creates isolated development environments on permanent branches
**Development Integration**: Enables simultaneous framework and application development with real-time integration
**Framework Access**: Real-time access to framework changes through symlink integration

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

## Application Workspace Management Philosophy

**Core Principle**: Application workspace management enables real-time framework integration by creating permanent development environments that eliminate branch switching friction and provide immediate access to framework changes through symlink connections.

**Workspace Workflow**: @WORKSPACE creates worktrees → Application development in isolated environment → Real-time framework access via symlinks → @CHECKPOINT integrates changes

### 🎯 **Clear Separation of Concerns**
- **WORKSPACE**: Creates and manages worktree infrastructure → NO development work
- **PLAN/DEVELOP/etc**: Work within designated worktrees → NO worktree management
- **CHECKPOINT**: Commits and integrates from worktrees → NO worktree creation
- **Development**: Occurs entirely within worktree boundaries → NO branch switching

**Quality Standards**: Workspace management ensures clean development isolation, real-time framework integration, and parallel development capability

**Technical Focus Only**: Workspace management strictly focuses on development infrastructure setup. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Application Workspace Management Methodology

### Phase 1: Application Workspace Environment Analysis
1. **Current State Assessment** → Analyze existing git repository and application development context
2. **Worktree Validation** → Check for existing worktrees and potential integration conflicts
3. **Framework Integration Review** → Understand framework dependency requirements and integration needs
4. **Infrastructure Requirements** → Assess application workspace requirements and setup prerequisites
5. **Real-time Integration Planning** → Plan framework access and real-time synchronization approach

### Phase 2: Application Worktree Infrastructure Creation
1. **Cleanup Existing Worktrees** → Remove any existing worktree configurations
2. **Framework Workspace Creation** → Create framework-workspace/ with framework branch
3. **Application Workspace Creation** → Create application-workspace/ with application branch
4. **Framework Integration Setup** → Create symlinks for real-time framework access
5. **Environment Validation** → Verify application worktree functionality and framework integration

### Phase 3: Application Workspace Configuration and Integration
1. **Development Environment Setup** → Configure application workspace for optimal development
2. **Framework Integration Testing** → Validate real-time framework access and synchronization
3. **Application Development Preparation** → Prepare workspace for application development workflows
4. **Integration Documentation** → Document workspace usage and framework integration procedures
5. **Development Coordination** → Establish application development coordination with framework changes

## Application Workspace Management Process

### Application Workspace Structure Creation
**Target Structure**:
```
Axiom/ (main repository - coordination hub)
├── .git/                           # Main git repository
├── FrameworkProtocols/             # Protocol coordination (main branch)
├── ApplicationProtocols/           # Protocol coordination (main branch)
├── framework-workspace/            # Framework development worktree
│   ├── AxiomFramework/            # Active framework development
│   └── .workspace-status          # Development state tracking
└── application-workspace/          # Application development worktree
    ├── AxiomExampleApp/           # Active application development
    ├── ApplicationProtocols/      # Application protocol access
    ├── AxiomFramework-dev@        # Symlink to framework-workspace/AxiomFramework
    └── .workspace-status          # Development state tracking
```

### Application Integration Strategy
- **Application Workspace** → Permanent application branch, complete application development context
- **Framework Access** → Real-time framework access via AxiomFramework-dev symlink
- **Protocol Access** → Direct access to ApplicationProtocols within workspace
- **Integration Testing** → Immediate framework change testing within application context

## Application Workspace Command Execution

**Command**: `@WORKSPACE [setup|reset|status|cleanup]`
**Action**: Execute comprehensive workspace management workflow with application development preparation

### 🔄 **Application Workspace Setup Process**

**CRITICAL**: WORKSPACE commands manage git worktree infrastructure for application development

```bash
# Application workspace management execution
echo "🏗️ Application Workspace Management"
echo "📍 Repository: $(pwd)"
echo "🌿 Current branch: $(git branch --show-current)"

# Validate repository state
if [ ! -d ".git" ]; then
    echo "❌ Must be run from git repository root"
    exit 1
fi
```

**Automated Application Workspace Setup Process**:
1. **Repository Validation** → Ensure execution from git repository root
2. **Existing Worktree Cleanup** → Remove any existing development worktrees
3. **Branch Preparation** → Ensure framework and application branches exist
4. **Framework Worktree Creation** → Create framework-workspace/ for framework access
5. **Application Worktree Creation** → Create application-workspace/ with application branch
6. **Framework Integration Setup** → Create symlinks for real-time framework access
7. **Application Environment Validation** → Verify application development capabilities and framework integration
8. **Development Preparation** → Prepare application workspace for immediate development use
**Git Operations**: WORKSPACE commands create and manage worktree infrastructure

```bash
# Application workspace setup implementation
echo "🧹 Cleaning existing worktrees..."
git worktree remove framework-workspace 2>/dev/null || true
git worktree remove application-workspace 2>/dev/null || true

echo "🏗️ Creating framework workspace for integration..."
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

echo "🔗 Setting up real-time framework access..."
cd application-workspace/
ln -sf ../framework-workspace/AxiomFramework AxiomFramework-dev
cd ..

echo "📊 Creating workspace status tracking..."
echo "Framework workspace created: $(date)" > framework-workspace/.workspace-status
echo "Application workspace created: $(date)" > application-workspace/.workspace-status

echo "✅ Application development workspace ready"
echo "📍 Application workspace: application-workspace/"
echo "🔗 Framework access: application-workspace/AxiomFramework-dev → framework-workspace/AxiomFramework"
echo "🚀 Ready for application development with real-time framework integration"
```

**Application Workspace Execution Examples**:
- `@WORKSPACE setup` → Create development worktrees with application focus
- `@WORKSPACE reset` → Reset application workspace with clean state
- `@WORKSPACE status` → Show application workspace status and framework integration
- `@WORKSPACE cleanup` → Remove application and framework worktrees

## Application Workspace Standards

### Application Workspace Creation Standards
- **Clean Environment**: Complete removal of existing worktrees before creation
- **Framework Integration**: Real-time framework access through symlink connections
- **Development Readiness**: Application workspace configured for immediate development use
- **Integration Verification**: Validated framework access and synchronization
- **Status Tracking**: Application workspace creation and integration monitoring

### Application Workspace Quality Standards
- **Infrastructure Reliability**: Robust application worktree creation with error handling
- **Framework Integration**: Verified real-time framework access and change synchronization
- **Development Efficiency**: Optimized application workspace for development velocity
- **Integration Testing**: Framework changes immediately available for application testing
- **Documentation**: Clear application workspace usage and framework integration procedures

## Application Workspace Workflow Integration

**Workspace Purpose**: Create application development infrastructure with real-time framework integration
**Development Integration**: Application workspace provides isolated environment for ApplicationProtocols
**Framework Access**: Real-time framework changes accessible through symlink integration
**Protocol Access**: Application workspace has direct access to ApplicationProtocols
**Integration Testing**: Framework changes immediately testable within application context

## Application Workspace Coordination

**Infrastructure Creation**: Creates isolated application development environment with framework integration
**Development Integration**: Application workspace integrates with existing ApplicationProtocols
**Framework Synchronization**: Real-time framework access via symlink connections
**Environment Management**: Application workspace lifecycle management with setup, reset, and cleanup
**Development Coordination**: Enables coordinated application development with real-time framework integration

---

**APPLICATION WORKSPACE COMMAND STATUS**: Application workspace management command with framework integration
**CORE FOCUS**: Git worktree infrastructure for application development with real-time framework access  
**WORKSPACE CREATION**: Creates application-workspace/ with permanent application branch assignment
**FRAMEWORK INTEGRATION**: Real-time framework access via AxiomFramework-dev symlink
**DEVELOPMENT VELOCITY**: Eliminates branch switching and enables immediate framework change testing

**Use ApplicationProtocols/@WORKSPACE for application development infrastructure and framework integration setup.**