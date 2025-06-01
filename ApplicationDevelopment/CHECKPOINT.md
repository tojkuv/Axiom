# @CHECKPOINT.md - Application Development Checkpoint System

## ⚡ Application-Focused Checkpoint Management

This command provides intelligent checkpoint management for application development workflows, focusing on integration testing and application branch management.

### 🎯 **Usage Modes**
- **`@CHECKPOINT.md`** → Auto-detect current branch and execute appropriate workflow
- **`@CHECKPOINT.md m`** → Force main branch checkpoint workflow (regardless of current branch)
- **`@CHECKPOINT.md i`** → Force integration branch checkpoint workflow (regardless of current branch)

### 🧠 **Branch Focus**
**Application Development Context**: Primarily works with integration branch for application testing and validation
**Integration Branch**: Application development, test app improvements, real-world validation
**Main Branch**: Strategic coordination and documentation updates

### 🛡️ Safety Features
- **Safe Merge Operations**: Uses --no-ff for clean merge history
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Branch Cleanup**: Automatically removes old branches after successful merge
- **Fresh Branch Creation**: Creates clean branches for next development cycle

### 🔍 Branch Detection & Smart Actions

**Integration Branch (`integration`):**  
- 🔄 Switch to integration branch (if using forced mode)
- ✅ Commit integration validation results (application testing work, no ROADMAP.md)
- 🔄 Merge validated work into `main`
- 🌱 Create fresh `integration` branch for next cycle

**Main Branch (`main`):**
- ✅ Commit current progress (including ROADMAP.md updates from @PLAN.md)
- 📤 Push changes to main
- 🧪 Update integration branch with latest main
- 🔄 Synchronize all branches with main changes

---

## 🤖 Execution

**Claude, execute this application-focused checkpoint process:**

1. **Parse Branch Flag & Execute Appropriate Workflow**

```bash
# 1. Parse branch flag argument
BRANCH_FLAG="$1"
CURRENT_BRANCH=$(git branch --show-current)

# 2. Determine target workflow based on flag or auto-detection
if [ -n "$BRANCH_FLAG" ]; then
    case "$BRANCH_FLAG" in
        "m"|"main")
            TARGET_WORKFLOW="main"
            echo "🎯 Forced main branch checkpoint workflow"
            ;;
        "i"|"integration")
            TARGET_WORKFLOW="integration"
            echo "🎯 Forced integration branch checkpoint workflow"
            ;;
        *)
            echo "❌ Invalid branch flag: $BRANCH_FLAG"
            echo "💡 Valid flags: m (main), i (integration)"
            echo "📋 Or use @CHECKPOINT.md without flags for auto-detection"
            exit 1
            ;;
    esac
else
    # Auto-detect mode
    TARGET_WORKFLOW="$CURRENT_BRANCH"
    echo "🤖 Auto-detected branch: $CURRENT_BRANCH"
fi

echo "🎯 Current branch: $CURRENT_BRANCH"
echo "⚡ Target workflow: $TARGET_WORKFLOW"

# 3. Check git status and show what will be committed
echo "📋 Current changes on $CURRENT_BRANCH:"
git status --short

# 4. Execute workflow based on target (auto-detected or forced)
case "$TARGET_WORKFLOW" in
  "integration")
    echo "🧪 INTEGRATION BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Switch to integration branch first to check for its changes
    if [ "$CURRENT_BRANCH" != "integration" ]; then
        echo "🔄 Switching to integration branch to check for changes..."
        git checkout integration
    fi
    
    # Check for uncommitted changes on integration branch
    if [ -n "$(git status --porcelain)" ]; then
        # Commit integration results
        echo "✅ Committing integration validation..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        
        # Use heredoc for proper multiline commit message
        COMMIT_MESSAGE=$(cat <<EOF
🧪 Integration checkpoint: $CURRENT_DATE

✅ Application testing and validation completed
📊 Performance metrics captured
🎯 Ready for main branch merge

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
        git commit -m "$COMMIT_MESSAGE"
    else
        echo "✅ No uncommitted changes to commit on integration branch"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Check if integration has changes to merge (avoid empty merges)
    git checkout main
    git pull origin main
    
    echo "🔍 Checking if integration has new changes..."
    if git merge-tree $(git merge-base main integration) main integration | grep -q "^"; then
        echo "📝 Changes detected - proceeding with merge"
    else
        echo "✅ No changes to merge - integration already integrated"
        echo "🌱 Creating fresh integration branch..."
        git branch -D integration 2>/dev/null || true
        git push origin --delete integration 2>/dev/null || true
        git checkout -b integration
        git push origin integration -u
        echo "✅ Integration cycle complete (no merge needed)!"
        exit 0
    fi
    
    echo "🚀 Merging integration into main..."
    MERGE_DATE=$(date '+%Y-%m-%d')
    
    # Use heredoc for proper multiline commit message
    MERGE_MESSAGE=$(cat <<EOF
🧪 Merge integration cycle: $MERGE_DATE

✅ Application validation completed
📊 Performance metrics validated
🎯 Ready for next integration cycle

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
    
    # Perform merge with proper error handling
    if ! git merge integration --no-ff -m "$MERGE_MESSAGE"; then
        echo ""
        echo "🚨 MERGE CONFLICT DETECTED!"
        echo "❌ Automatic checkpoint halted - this should not happen with our workflows"
        echo ""
        echo "🤔 Possible causes:"
        echo "   • Unexpected changes made directly to main branch"
        echo "   • Manual modifications to integration branch history"
        echo "   • External changes not following Axiom workflow"
        echo ""
        echo "🆘 HUMAN CONSULTATION REQUIRED"
        echo "📋 Current status:"
        echo "   • Integration branch has been committed"
        echo "   • Main branch is checked out"
        echo "   • Merge conflict exists between integration and main"
        echo ""
        echo "💡 Manual resolution steps:"
        echo "   1. Run: git status (to see conflicted files)"
        echo "   2. Edit conflicted files to resolve conflicts"
        echo "   3. Run: git add <resolved-files>"
        echo "   4. Run: git commit (to complete the merge)"
        echo "   5. Then re-run: @CHECKPOINT.md (to continue automation)"
        echo ""
        echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
        exit 1
    fi
    
    # Push updated main
    echo "📤 Pushing updated main..."
    git push origin main
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    # Delete old integration branch
    echo "🗑️ Cleaning up old integration branch..."
    git branch -D integration
    git push origin --delete integration
    
    # Create fresh integration branch
    echo "🌱 Creating fresh integration branch..."
    git checkout -b integration
    git push origin integration -u
    
    echo "✅ Integration cycle complete!"
    echo "🎯 Fresh integration branch ready for next cycle"
    ;;
    
  "main")
    echo "🎯 MAIN BRANCH CHECKPOINT - UPDATE BRANCHES"
    
    # Check for uncommitted changes first
    CHANGES_COUNT=$(git status --porcelain | wc -l)
    if [ "$CHANGES_COUNT" -gt 0 ]; then
        # Commit progress on main
        echo "✅ Committing main branch progress ($CHANGES_COUNT files changed)..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        
        # Use heredoc for proper multiline commit message
        COMMIT_MESSAGE=$(cat <<EOF
🎯 Main branch checkpoint: $CURRENT_DATE

📋 Application development coordination
🚀 Strategic planning and documentation

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
        git commit -m "$COMMIT_MESSAGE"
        
        # Push to main
        echo "🚀 Pushing to main..."
        git push origin main
    else
        echo "✅ No uncommitted changes to commit"
        echo "📋 Proceeding with branch synchronization only..."
    fi
    
    # Update integration branch with latest main  
    echo "🧪 Updating integration branch with latest main..."
    if git show-ref --verify --quiet refs/remotes/origin/integration; then
        git fetch origin integration
        git checkout integration
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING INTEGRATION BRANCH!"
            echo "❌ Cross-branch update failed - manual resolution required"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Main branch changes have been committed and pushed"
            echo "   • Integration branch is checked out"
            echo "   • Conflict exists when pulling main into integration"
            echo ""
            echo "💡 Manual resolution steps:"
            echo "   1. Run: git status (to see conflicted files)"
            echo "   2. Edit conflicted files to resolve conflicts"
            echo "   3. Run: git add <resolved-files>"
            echo "   4. Run: git commit (to complete the merge)"
            echo "   5. Run: git push origin integration"
            echo "   6. Then re-run: @CHECKPOINT.md (to continue automation)"
            echo ""
            echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
            exit 1
        fi
        git push origin integration
        echo "✅ Integration branch updated with latest main"
    else
        echo "🌱 Integration branch doesn't exist remotely"
    fi
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    echo "✅ Main branch checkpoint complete"
    echo "🔄 Integration branch synchronized with latest main changes"
    echo "📋 No PR needed (already on main)"
    ;;
    
  *)
    echo "❓ Unknown branch: $CURRENT_BRANCH"
    
    # Only checkpoint if there are changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "🎯 Creating standard checkpoint..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        
        # Use heredoc for proper multiline commit message
        COMMIT_MESSAGE=$(cat <<EOF
📌 Checkpoint on $CURRENT_BRANCH: $CURRENT_DATE

🔄 Application development progress update

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
        git commit -m "$COMMIT_MESSAGE"
        
        git push origin "$CURRENT_BRANCH" -u
        echo "✅ Standard checkpoint complete"
    else
        echo "✅ No changes detected on $CURRENT_BRANCH"
        echo "🤖 Skipping checkpoint - no work to commit"
    fi
    ;;
esac

echo ""
echo "🎉 CHECKPOINT COMPLETE"
echo "📍 Branch: $CURRENT_BRANCH"
echo "🕐 Time: $(date)"
```

---

## 🎯 Usage Patterns

### **Auto-Detection Mode** (Recommended)
```bash
# From any branch - automatically adapts
@CHECKPOINT.md  # Auto-detects current branch and executes appropriate workflow
```

### **Integration Workflow** (Auto or Forced)
```bash
# After application testing and validation
@CHECKPOINT.md     # Auto-detects integration branch
@CHECKPOINT.md i   # Forces integration workflow from any branch
                   # → Commits results, merges to main, creates fresh integration
```

### **Main Branch Coordination** (Auto or Forced)
```bash
# Strategic planning and coordination
@CHECKPOINT.md     # Auto-detects main branch
@CHECKPOINT.md m   # Forces main workflow from any branch
                   # → Commits status, pushes to main, updates integration branch
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context (default mode)
- **🎯 Forced Workflow Execution**: Execute specific branch workflows regardless of current branch
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Merge & Restart**: Merges completed work to main and creates fresh branches
- **🔄 Integration Synchronization**: Integration branch automatically synchronizes with latest main changes
- **🚨 Conflict Detection & Human Consultation**: Halts automation and provides guidance for conflicts
- **🌱 Automated Branch Cycling**: Complete cycle automation for integration testing
- **📊 Status Tracking**: Maintains project coordination across branches
- **⚡ Application-Focused Operation**: Optimized for application development and testing workflows

**Perfect for Axiom application development workflow with seamless integration testing and validation!**