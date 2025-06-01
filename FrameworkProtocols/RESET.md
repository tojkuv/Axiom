# @RESET.md - Axiom Framework Development Reset Command

Framework development reset command that creates fresh development environment for framework implementation

## Automated Mode Trigger

**When human sends**: `@RESET [optional-args]`
**Action**: Enter ultrathink mode and execute framework development reset workflow

### Usage Modes
- **`@RESET`** → Reset framework development environment and create fresh framework branch
- **`@RESET clean`** → Clean reset with complete framework branch deletion and recreation
- **`@RESET fresh`** → Fresh framework development start with clean environment
- **`@RESET restart`** → Restart framework development cycle with fresh branch

### Framework Reset Scope
**Reset Focus**: Framework development environment reset and fresh branch creation
**Branch Management**: Complete framework branch cleanup and fresh branch creation
**Environment Reset**: Clean development environment for framework implementation
**Development Integration**: Prepares clean environment for FrameworkProtocols/PLAN.md and DEVELOP.md workflows

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: RESET commands perform git operations for branch management only
**Version Control**: RESET handles branch reset operations, @CHECKPOINT handles development commits
**Work Philosophy**: RESET creates clean environment → PLAN/DEVELOP/REFACTOR cycles → @CHECKPOINT commits

Reset workflow operations:
1. **Environment Analysis**: Assess current framework development state
2. **Branch Cleanup**: Delete existing framework branch and clean environment
3. **Fresh Branch Creation**: Create clean framework branch for new development cycle
4. **Environment Preparation**: Prepare clean framework development environment
5. **Reset Coordination**: Update framework development tracking and coordination
**Git Operations**: RESET commands handle branch cleanup and fresh branch creation only

## Framework Development Reset Philosophy

**Core Principle**: Framework reset creates clean development environments that eliminate development conflicts, provide fresh starting points, and ensure clean framework development cycles.

**Reset Purpose**: Framework reset provides clean development environment initialization for framework development teams working on complex architectural changes.

**Environment Standards**: Framework reset ensures clean development environments with proper branch isolation, eliminated development conflicts, and fresh framework development foundation.

**Technical Focus Only**: Reset operations focus exclusively on technical environment preparation. No consideration of non-technical aspects (business strategy, adoption planning, community coordination, etc.)

## Framework Reset Methodology

### Phase 1: Framework Environment Analysis
1. **Current State Assessment** → Analyze current framework development environment and branch state
2. **Branch State Analysis** → Assess existing framework branch state and development conflicts
3. **Development Context Review** → Understand current framework development context and requirements
4. **Reset Requirements Analysis** → Understand reset scope and clean environment requirements
5. **Environment Planning** → Plan clean framework development environment setup

### Phase 2: Framework Environment Reset
1. **Branch Cleanup** → Delete existing framework branch and clean development state
2. **Environment Preparation** → Prepare clean framework development environment
3. **Fresh Branch Creation** → Create fresh framework branch for clean development cycle
4. **Development Setup** → Setup clean framework development environment and tools
5. **Reset Validation** → Validate clean framework development environment setup

### Phase 3: Framework Reset Documentation
1. **Reset Documentation** → Document framework reset operation and clean environment setup
2. **Development Coordination** → Coordinate framework reset with development team workflows
3. **Environment Status** → Update framework development environment status and coordination
4. **Reset Preparation** → Prepare clean framework development environment for development workflows
5. **Integration Readiness** → Ensure clean environment integration with FrameworkProtocols workflows

## Framework Reset Process

### Framework Environment Reset
**Focus**: Clean framework development environment creation and branch management
**Scope**: Framework branch cleanup, fresh branch creation, development environment reset
**Integration**: Seamless integration with FrameworkProtocols/PLAN.md and DEVELOP.md workflows
**Coordination**: Framework reset coordination with development team workflows

### Framework Reset Benefits
- **Clean Environment**: Eliminates development conflicts and provides fresh framework development foundation
- **Branch Isolation**: Creates isolated framework development environment for complex architectural changes
- **Development Velocity**: Accelerates framework development through clean environment initialization
- **Conflict Resolution**: Resolves framework development conflicts through complete environment reset
- **Team Coordination**: Enables coordinated framework development with clean environment synchronization

## Framework Reset Command Execution

**Command**: `@RESET [clean|fresh|restart]`
**Action**: Execute comprehensive framework development reset workflow with fresh environment creation

### 🔄 **Reset Execution Process**

**CRITICAL**: RESET commands handle branch management operations for clean environment creation

```bash
# Framework environment analysis
echo "🔍 Analyzing current framework development environment..."
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Framework branch cleanup
echo "🧹 Framework environment cleanup..."
if [ "$CURRENT_BRANCH" = "framework" ]; then
    echo "🔄 Switching from framework branch to main..."
    git checkout main
fi

# Delete existing framework branch
if git show-ref --verify --quiet refs/heads/framework; then
    echo "🗑️ Deleting existing framework branch..."
    git branch -D framework 2>/dev/null || true
    echo "✅ Local framework branch deleted"
fi

# Delete remote framework branch
if git show-ref --verify --quiet refs/remotes/origin/framework; then
    echo "🗑️ Deleting remote framework branch..."
    git push origin --delete framework 2>/dev/null || true
    echo "✅ Remote framework branch deleted"
fi

# Create fresh framework branch
echo "🌱 Creating fresh framework branch..."
git checkout -b framework
echo "✅ Fresh framework branch created and active"

# Framework reset validation
echo "🔍 Validating framework reset environment..."
echo "📍 Active branch: $(git branch --show-current)"
echo "✅ Framework development environment reset complete"
```

**Automated Reset Execution Process**:
1. **Environment Analysis** → Analyze current framework development state and branch configuration
2. **Branch Cleanup** → Delete existing framework branch (local and remote) for clean environment
3. **Fresh Branch Creation** → Create clean framework branch for new development cycle
4. **Environment Validation** → Validate clean framework development environment setup
5. **Reset Coordination** → Update framework development coordination and team synchronization
6. **Integration Preparation** → Prepare clean environment for FrameworkProtocols workflow integration
**Git Operations**: RESET commands handle branch cleanup and fresh branch creation only

**Framework Reset Execution Examples**:
- `@RESET` → Standard framework environment reset with fresh branch creation
- `@RESET clean` → Complete framework environment cleanup and fresh development setup
- `@RESET fresh` → Fresh framework development environment for new development cycle
- `@RESET restart` → Restart framework development with clean environment and fresh branch

## Framework Reset Integration

### Framework Development Workflow Integration
**Reset Purpose**: Clean framework development environment creation for structured development
**Development Preparation**: Prepares clean environment for FrameworkProtocols/PLAN.md and DEVELOP.md
**Environment Management**: Framework reset provides clean development foundation for development team
**Workflow Integration**: Seamless integration with framework development, planning, and implementation workflows

### Framework Reset Coordination
**Environment Preparation**: Creates clean framework development environment in fresh framework branch
**Development Integration**: Framework reset prepares environment for development team workflows
**Team Coordination**: Framework reset enables coordinated development with clean environment synchronization
**Progress Management**: Framework reset maintains clean development environment throughout development cycles

## Framework Reset Standards

### Framework Environment Standards
- **Clean Environment**: Complete framework development environment cleanup and fresh foundation
- **Branch Isolation**: Isolated framework development environment for complex architectural changes
- **Development Setup**: Proper framework development environment configuration and tool setup
- **Integration Readiness**: Clean environment integration with FrameworkProtocols workflows
- **Team Coordination**: Coordinated framework development with clean environment synchronization

### Framework Reset Quality Standards
- **Complete Cleanup**: Comprehensive framework environment cleanup with no development conflicts
- **Fresh Foundation**: Clean framework development foundation for new development cycles
- **Environment Validation**: Validated clean framework development environment setup
- **Integration Testing**: Tested framework reset integration with development workflows
- **Team Synchronization**: Coordinated framework reset with development team workflows

---

**FRAMEWORK RESET COMMAND STATUS**: Framework development reset command with clean environment creation and branch management
**CORE FOCUS**: Clean framework development environment creation for structured development
**ENVIRONMENT MANAGEMENT**: Creates fresh framework branch and clean development environment
**WORKFLOW INTEGRATION**: Seamless integration with FrameworkProtocols/PLAN.md and DEVELOP.md workflows
**TEAM COORDINATION**: Coordinated framework reset with development team synchronization

**Use FrameworkProtocols/@RESET for clean framework development environment creation with fresh branch management and development workflow integration.**