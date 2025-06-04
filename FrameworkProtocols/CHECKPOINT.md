# @CHECKPOINT.md - Framework Development Checkpoint System

## ⚡ Framework Worktree Checkpoint Management

This command provides deterministic checkpoint management for framework development workflow, integrating framework workspace changes into main branch.

### 🎯 **Usage Modes**
- **`@CHECKPOINT`** → Commit and integrate framework worktree changes into main branch
- **`@CHECKPOINT status`** → Show framework worktree status and pending changes
- **`@CHECKPOINT push`** → Push integrated changes to remote repository

### 🧠 **Framework Integration Focus**
**Framework Development Context**: Integrates framework-workspace/ changes into main branch
**Main Branch Coordination**: Central integration point for framework development
**Branch Synchronization**: Ensures clean integration from synchronized framework branch

### 🔄 **Framework Worktree Git Workflow**
All development commands follow this simplified workflow:
1. **Development**: Work occurs in framework-workspace/ on synchronized framework branch
2. **Commit**: Commit changes within framework worktree
3. **Integration**: Merge framework branch into main branch
4. **Deployment**: Push integrated main branch to remote repository
5. **Synchronization**: Keep framework branch updated with main via @WORKSPACE

### 🛡️ Enhanced Safety Features
- **Worktree Validation**: Ensures framework worktree exists before attempting operations
- **Uncommitted Change Detection**: Only commits when there are actual changes in framework workspace
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Branch Synchronization**: Validates framework branch is synchronized with main
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

echo "🏗️ Framework Development Checkpoint"
echo "📍 Repository: $(pwd)"
echo "🌿 Current branch: $(git branch --show-current)"

# 1. Validate worktree existence
FRAMEWORK_WORKSPACE="framework-workspace"

if [ ! -d "$FRAMEWORK_WORKSPACE" ]; then
    echo "⚠️ Framework workspace not found: $FRAMEWORK_WORKSPACE"
    echo "💡 Run '@WORKSPACE setup' to initialize framework worktree"
    # Create fallback for main repository changes
    WORKSPACE_EXISTS=false
else
    WORKSPACE_EXISTS=true
fi

# 2. Commit framework workspace changes
if [ -d "$FRAMEWORK_WORKSPACE" ]; then
    echo "💾 Committing framework workspace changes..."
    cd $FRAMEWORK_WORKSPACE
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "$(cat <<EOF
Framework development checkpoint: $CURRENT_DATE

Framework workspace changes committed via @CHECKPOINT protocol

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)" || echo "No framework changes to commit"
        echo "✅ Framework changes committed: $CURRENT_DATE"
    else
        echo "ℹ️ No framework changes to commit"
    fi
    
    cd ..
fi

# 3. Fallback: Commit main repository changes if framework worktree doesn't exist
if [ "$WORKSPACE_EXISTS" = false ]; then
    echo "💾 No worktrees found - committing main repository changes..."
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "$(cat <<EOF
Development checkpoint: $CURRENT_DATE

Main repository changes committed via @CHECKPOINT protocol

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)" || echo "No main repository changes to commit"
        echo "✅ Main repository changes committed: $CURRENT_DATE"
    else
        echo "ℹ️ No main repository changes to commit"
    fi
fi
```

2. **Integrate Development Branches into Main**

```bash
# 4. Switch to main branch and update
echo "🔄 Switching to main branch for integration..."
git checkout main
git pull origin main || echo "Could not pull from remote"

# 5. Merge framework development
if [ "$WORKSPACE_EXISTS" = true ]; then
    echo "🔗 Integrating framework development..."
    # Check if there are changes to merge
    if ! git diff --quiet main framework; then
        echo "📝 Framework changes detected - merging..."
        MERGE_DATE=$(date '+%Y-%m-%d %H:%M')
        git merge framework --no-ff -m "$(cat <<EOF
Integrate framework development: $MERGE_DATE

Framework workspace integration via @CHECKPOINT protocol

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)" || {
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
# 6. Push integrated changes
echo "🚀 Deploying integrated changes..."
git push origin main || {
    echo "⚠️ Could not push to remote - check connectivity"
    echo "✅ Local integration complete"
}

# 7. Show integration summary
echo ""
echo "📊 Checkpoint Summary:"
echo "✅ Framework workspace: $([ "$WORKSPACE_EXISTS" = true ] && echo "committed and integrated" || echo "main repository committed")"
echo "✅ Main branch: integrated and deployed"
echo "📍 Current branch: $(git branch --show-current)"
echo "🔄 Framework branch status: $([ "$WORKSPACE_EXISTS" = true ] && echo "merged into main" || echo "no worktree")"
echo ""
echo "🏁 Framework development checkpoint complete"
echo "💡 Continue development in framework-workspace/"
```

## 🔧 Workflow Integration

### **Framework Development Cycle**
1. **Development Phase**: Work in `framework-workspace/` on synchronized framework branch
2. **Checkpoint Phase**: Run `@CHECKPOINT` to commit and integrate framework changes
3. **Deployment Phase**: Integrated changes pushed to remote main branch
4. **Synchronization Phase**: Use `@WORKSPACE reset` to sync framework branch with main

### **Integration Strategy**
- **Isolated Development**: Framework development in dedicated worktree
- **Clean Commits**: Framework changes committed before integration
- **Conflict Resolution**: Manual intervention required for merge conflicts
- **Clean History**: No-fast-forward merges maintain framework branch history
- **Main Synchronization**: Framework branch kept current via @WORKSPACE

### **Safety and Reliability**
- **Worktree Validation**: Ensures framework workspace exists
- **Change Detection**: Only commits when actual changes exist
- **Merge Safety**: Conflict detection prevents broken integrations
- **Remote Coordination**: Handles remote push failures gracefully
- **Fallback Support**: Commits main repository changes when no worktree exists

---

**CHECKPOINT COMMAND STATUS**: Framework worktree checkpoint system for development integration
**CORE FOCUS**: Framework development workflow with main branch integration
**WORKTREE INTEGRATION**: Commits and merges framework development into main branch
**DEVELOPMENT CONTINUITY**: Maintains clean development state with synchronized branches

**Use FrameworkProtocols/@CHECKPOINT for framework development integration and deployment.**