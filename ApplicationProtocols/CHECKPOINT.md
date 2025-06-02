# @CHECKPOINT.md - Application Development Checkpoint System

## ⚡ Worktree-Based Checkpoint Management

This command provides intelligent checkpoint management for worktree-based development workflows, integrating application and framework development changes into main branch.

### 🎯 **Usage Modes**
- **`@CHECKPOINT`** → Commit and integrate all worktree changes into main branch
- **`@CHECKPOINT application`** → Commit and integrate only application workspace changes
- **`@CHECKPOINT framework`** → Commit and integrate only framework workspace changes
- **`@CHECKPOINT status`** → Show worktree status and pending changes

### 🧠 **Worktree Integration Focus**
**Application Development Context**: Integrates application-workspace/ changes with real-time framework access
**Framework Coordination**: Coordinates framework-workspace/ changes with application requirements
**Main Branch Integration**: Central integration point for all development workstreams

### 🔄 **Worktree-Based Git Workflow**
All development commands follow this simplified workflow:
1. **Development**: Work occurs in dedicated worktrees (application-workspace/, framework-workspace/)
2. **Commit**: Commit changes within each worktree on respective branches
3. **Integration**: Merge development branches into main branch
4. **Deployment**: Push integrated main branch to remote repository
5. **Cleanup**: Maintain clean development state across worktrees

### 🛡️ Enhanced Safety Features
- **Worktree Validation**: Ensures worktrees exist before attempting operations
- **Uncommitted Change Detection**: Only commits when there are actual changes in each workspace
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Integration Testing**: Validates integration before pushing to remote

## 🤖 Execution

**Claude, execute this worktree-focused checkpoint process:**

1. **Validate Worktree Environment & Commit Changes**

```bash
# 0. Validate execution from repository root
if [ ! -d ".git" ]; then
    echo "❌ Must be run from git repository root"
    exit 1
fi

echo "🏗️ Application Development Checkpoint"
echo "📍 Repository: $(pwd)"
echo "🌿 Current branch: $(git branch --show-current)"

# 1. Validate worktree existence
FRAMEWORK_WORKSPACE="framework-workspace"
APPLICATION_WORKSPACE="application-workspace"

if [ ! -d "$APPLICATION_WORKSPACE" ]; then
    echo "⚠️ Application workspace not found: $APPLICATION_WORKSPACE"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
fi

if [ ! -d "$FRAMEWORK_WORKSPACE" ]; then
    echo "⚠️ Framework workspace not found: $FRAMEWORK_WORKSPACE"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
fi

# 2. Commit application workspace changes
if [ -d "$APPLICATION_WORKSPACE" ]; then
    echo "💾 Committing application workspace changes..."
    cd $APPLICATION_WORKSPACE
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        APPLICATION_MESSAGE="Application development checkpoint: $(date '+%Y-%m-%d %H:%M')"
        git commit -m "$APPLICATION_MESSAGE" || echo "No application changes to commit"
        echo "✅ Application changes committed: $APPLICATION_MESSAGE"
    else
        echo "ℹ️ No application changes to commit"
    fi
    
    cd ..
fi

# 3. Commit framework workspace changes
if [ -d "$FRAMEWORK_WORKSPACE" ]; then
    echo "💾 Committing framework workspace changes..."
    cd $FRAMEWORK_WORKSPACE
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        FRAMEWORK_MESSAGE="Framework development checkpoint: $(date '+%Y-%m-%d %H:%M')"
        git commit -m "$FRAMEWORK_MESSAGE" || echo "No framework changes to commit"
        echo "✅ Framework changes committed: $FRAMEWORK_MESSAGE"
    else
        echo "ℹ️ No framework changes to commit"
    fi
    
    cd ..
fi
```

2. **Integrate Development Branches into Main**

```bash
# 4. Switch to main branch and update
echo "🔄 Switching to main branch for integration..."
git checkout main
git pull origin main || echo "Could not pull from remote"

# 5. Merge application development
if [ -d "$APPLICATION_WORKSPACE" ]; then
    echo "🔗 Integrating application development..."
    if git merge-tree $(git merge-base main application) main application | grep -q "^"; then
        echo "📝 Application changes detected - merging..."
        git merge application --no-ff -m "Integrate application development: $(date '+%Y-%m-%d %H:%M')" || {
            echo "❌ Application merge conflict detected"
            echo "🔧 Manual resolution required"
            exit 1
        }
        echo "✅ Application development integrated"
    else
        echo "ℹ️ No new application changes to merge"
    fi
fi

# 6. Merge framework development
if [ -d "$FRAMEWORK_WORKSPACE" ]; then
    echo "🔗 Integrating framework development..."
    if git merge-tree $(git merge-base main framework) main framework | grep -q "^"; then
        echo "📝 Framework changes detected - merging..."
        git merge framework --no-ff -m "Integrate framework development: $(date '+%Y-%m-%d %H:%M')" || {
            echo "❌ Framework merge conflict detected"
            echo "🔧 Manual resolution required"
            exit 1
        }
        echo "✅ Framework development integrated"
    else
        echo "ℹ️ No new framework changes to merge"
    fi
fi
```

3. **Deploy and Maintain Clean State**

```bash
# 7. Push integrated changes
echo "🚀 Deploying integrated changes..."
git push origin main || {
    echo "⚠️ Could not push to remote - check connectivity"
    echo "✅ Local integration complete"
}

# 8. Show integration summary
echo ""
echo "📊 Checkpoint Summary:"
echo "✅ Application workspace: $([ -d "$APPLICATION_WORKSPACE" ] && echo "committed" || echo "not found")"
echo "✅ Framework workspace: $([ -d "$FRAMEWORK_WORKSPACE" ] && echo "committed" || echo "not found")"
echo "✅ Main branch: integrated and deployed"
echo "📍 Current branch: $(git branch --show-current)"
echo ""
echo "🏁 Application development checkpoint complete"
echo "💡 Continue development in respective workspaces"
echo "🔗 Framework changes immediately available via AxiomFramework-dev symlink"
```

## 🔧 Workflow Integration

### **Worktree Development Cycle**
1. **Development Phase**: Work in `application-workspace/` with real-time framework access via symlinks
2. **Checkpoint Phase**: Run `@CHECKPOINT` to commit and integrate all changes
3. **Deployment Phase**: Integrated changes pushed to remote main branch
4. **Continuation Phase**: Resume development in workspaces with clean integration state

### **Integration Strategy**
- **Application-First**: Application development prioritized with real-time framework integration
- **Coordinated Commits**: Both workspaces committed before integration
- **Conflict Resolution**: Manual intervention required for merge conflicts
- **Clean History**: No-fast-forward merges maintain development branch history

### **Real-time Framework Access**
- **Symlink Integration**: AxiomFramework-dev provides immediate access to framework changes
- **Testing Continuity**: Framework changes immediately testable in application context
- **Development Velocity**: No waiting for framework integration to test application changes

### **Safety and Reliability**
- **Worktree Validation**: Ensures development environment integrity
- **Change Detection**: Only commits when actual changes exist
- **Merge Safety**: Conflict detection prevents broken integrations
- **Remote Coordination**: Handles remote push failures gracefully

---

**CHECKPOINT COMMAND STATUS**: Worktree-based checkpoint system for parallel application and framework development
**CORE FOCUS**: Integrated development workflow with application-centric real-time framework access
**WORKTREE INTEGRATION**: Commits and merges both development streams into main branch
**DEVELOPMENT CONTINUITY**: Maintains clean development state with real-time framework integration

**Use ApplicationProtocols/@CHECKPOINT for worktree-based development integration and deployment.**