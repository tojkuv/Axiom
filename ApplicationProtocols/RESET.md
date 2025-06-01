# @RESET.md - Axiom Application Development Reset Command

Application development reset command that creates fresh development environment for application implementation

## Automated Mode Trigger

**When human sends**: `@RESET [optional-args]`
**Action**: Enter ultrathink mode and execute application development reset workflow

### Usage Modes
- **`@RESET`** → Reset application development environment and create fresh application branch
- **`@RESET clean`** → Clean reset with complete application branch deletion and recreation
- **`@RESET fresh`** → Fresh application development start with clean environment
- **`@RESET restart`** → Restart application development cycle with fresh branch

### Application Reset Scope
**Reset Focus**: Application development environment reset and fresh branch creation
**Branch Management**: Complete application branch cleanup and fresh branch creation
**Environment Reset**: Clean development environment for application implementation
**Development Integration**: Prepares clean environment for ApplicationProtocols/PLAN.md and DEVELOP.md workflows

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: RESET commands perform git operations for branch management only
**Version Control**: RESET handles branch reset operations, @CHECKPOINT handles development commits
**Work Philosophy**: RESET creates clean environment → PLAN/DEVELOP/REFACTOR cycles → @CHECKPOINT commits

Reset workflow operations:
1. **Environment Analysis**: Assess current application development state
2. **Branch Cleanup**: Delete existing application branch and clean environment
3. **Fresh Branch Creation**: Create clean application branch for new development cycle
4. **Environment Preparation**: Prepare clean application development environment
5. **Reset Coordination**: Update application development tracking and coordination
**Git Operations**: RESET commands handle branch cleanup and fresh branch creation only

## Application Development Reset Philosophy

**Core Principle**: Application reset creates clean development environments that eliminate development conflicts, provide fresh starting points, and ensure clean application development cycles.

**Reset Purpose**: Application reset provides clean development environment initialization for application development teams working on complex feature implementations and framework integration validation.

**Environment Standards**: Application reset ensures clean development environments with proper branch isolation, eliminated development conflicts, and fresh application development foundation.

**Technical Focus Only**: Reset operations focus exclusively on technical environment preparation. No consideration of non-technical aspects (business strategy, user engagement, marketing considerations, etc.)

## Application Reset Methodology

### Phase 1: Application Environment Analysis
1. **Current State Assessment** → Analyze current application development environment and branch state
2. **Branch State Analysis** → Assess existing application branch state and development conflicts
3. **Development Context Review** → Understand current application development context and requirements
4. **Reset Requirements Analysis** → Understand reset scope and clean environment requirements
5. **Environment Planning** → Plan clean application development environment setup

### Phase 2: Application Environment Reset
1. **Branch Cleanup** → Delete existing application branch and clean development state
2. **Environment Preparation** → Prepare clean application development environment
3. **Fresh Branch Creation** → Create fresh application branch for clean development cycle
4. **Development Setup** → Setup clean application development environment and tools
5. **Reset Validation** → Validate clean application development environment setup

### Phase 3: Application Reset Documentation
1. **Reset Documentation** → Document application reset operation and clean environment setup
2. **Development Coordination** → Coordinate application reset with development team workflows
3. **Environment Status** → Update application development environment status and coordination
4. **Reset Preparation** → Prepare clean application development environment for development workflows
5. **Integration Readiness** → Ensure clean environment integration with ApplicationProtocols workflows

## Application Reset Process

### Application Environment Reset
**Focus**: Clean application development environment creation and branch management
**Scope**: Application branch cleanup, fresh branch creation, development environment reset
**Integration**: Seamless integration with ApplicationProtocols/PLAN.md and DEVELOP.md workflows
**Coordination**: Application reset coordination with development team workflows

### Application Reset Benefits
- **Clean Environment**: Eliminates development conflicts and provides fresh application development foundation
- **Branch Isolation**: Creates isolated application development environment for complex feature implementations
- **Development Velocity**: Accelerates application development through clean environment initialization
- **Conflict Resolution**: Resolves application development conflicts through complete environment reset
- **Team Coordination**: Enables coordinated application development with clean environment synchronization

## Application Reset Command Execution

**Command**: `@RESET [clean|fresh|restart]`
**Action**: Execute comprehensive application development reset workflow with fresh environment creation

### 🔄 **Reset Execution Process**

**CRITICAL**: RESET commands handle branch management operations for clean environment creation

```bash
# Application environment analysis
echo "🔍 Analyzing current application development environment..."
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Application branch cleanup
echo "🧹 Application environment cleanup..."
if [ "$CURRENT_BRANCH" = "application" ]; then
    echo "🔄 Switching from application branch to main..."
    git checkout main
fi

# Delete existing application branch
if git show-ref --verify --quiet refs/heads/application; then
    echo "🗑️ Deleting existing application branch..."
    git branch -D application 2>/dev/null || true
    echo "✅ Local application branch deleted"
fi

# Delete remote application branch
if git show-ref --verify --quiet refs/remotes/origin/application; then
    echo "🗑️ Deleting remote application branch..."
    git push origin --delete application 2>/dev/null || true
    echo "✅ Remote application branch deleted"
fi

# Create fresh application branch
echo "🌱 Creating fresh application branch..."
git checkout -b application
echo "✅ Fresh application branch created and active"

# Application reset validation
echo "🔍 Validating application reset environment..."
echo "📍 Active branch: $(git branch --show-current)"
echo "✅ Application development environment reset complete"
```

**Automated Reset Execution Process**:
1. **Environment Analysis** → Analyze current application development state and branch configuration
2. **Branch Cleanup** → Delete existing application branch (local and remote) for clean environment
3. **Fresh Branch Creation** → Create clean application branch for new development cycle
4. **Environment Validation** → Validate clean application development environment setup
5. **Reset Coordination** → Update application development coordination and team synchronization
6. **Integration Preparation** → Prepare clean environment for ApplicationProtocols workflow integration
**Git Operations**: RESET commands handle branch cleanup and fresh branch creation only

**Application Reset Execution Examples**:
- `@RESET` → Standard application environment reset with fresh branch creation
- `@RESET clean` → Complete application environment cleanup and fresh development setup
- `@RESET fresh` → Fresh application development environment for new development cycle
- `@RESET restart` → Restart application development with clean environment and fresh branch

## Application Reset Integration

### Application Development Workflow Integration
**Reset Purpose**: Clean application development environment creation for structured development
**Development Preparation**: Prepares clean environment for ApplicationProtocols/PLAN.md and DEVELOP.md
**Environment Management**: Application reset provides clean development foundation for development team
**Workflow Integration**: Seamless integration with application development, planning, and implementation workflows

### Application Reset Coordination
**Environment Preparation**: Creates clean application development environment in fresh application branch
**Development Integration**: Application reset prepares environment for development team workflows
**Team Coordination**: Application reset enables coordinated development with clean environment synchronization
**Progress Management**: Application reset maintains clean development environment throughout development cycles

## Application Reset Standards

### Application Environment Standards
- **Clean Environment**: Complete application development environment cleanup and fresh foundation
- **Branch Isolation**: Isolated application development environment for complex feature implementations
- **Development Setup**: Proper application development environment configuration and tool setup
- **Integration Readiness**: Clean environment integration with ApplicationProtocols workflows
- **Team Coordination**: Coordinated application development with clean environment synchronization

### Application Reset Quality Standards
- **Complete Cleanup**: Comprehensive application environment cleanup with no development conflicts
- **Fresh Foundation**: Clean application development foundation for new development cycles
- **Environment Validation**: Validated clean application development environment setup
- **Integration Testing**: Tested application reset integration with development workflows
- **Team Synchronization**: Coordinated application reset with development team workflows

---

**APPLICATION RESET COMMAND STATUS**: Application development reset command with clean environment creation and branch management
**CORE FOCUS**: Clean application development environment creation for structured development
**ENVIRONMENT MANAGEMENT**: Creates fresh application branch and clean development environment
**WORKFLOW INTEGRATION**: Seamless integration with ApplicationProtocols/PLAN.md and DEVELOP.md workflows
**TEAM COORDINATION**: Coordinated application reset with development team synchronization

**Use ApplicationProtocols/@RESET for clean application development environment creation with fresh branch management and development workflow integration.**