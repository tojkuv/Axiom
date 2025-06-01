# @CHECKPOINT.md - Application Development Checkpoint System

## ⚡ Application-Focused Checkpoint Management

This command provides intelligent checkpoint management for application development workflows, focusing on integration testing and application branch management.

### 🎯 **Usage Modes**
- **`@CHECKPOINT.md`** → Auto-detect current branch and execute appropriate workflow
- **`@CHECKPOINT.md m`** → Force main branch checkpoint workflow (regardless of current branch)
- **`@CHECKPOINT.md a`** → Force application branch checkpoint workflow (regardless of current branch)

### 🧠 **Branch Focus**
**Application Development Context**: Primarily works with application branch for application testing and validation
**Application Branch**: Application development, test app improvements, real-world validation
**Main Branch**: Strategic coordination and documentation updates

### 🔄 **Standardized Git Workflow**
All ApplicationDevelopment commands follow this workflow:
1. **Branch Setup**: Switch to `application` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `application` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `application` branch with descriptive messages
5. **Integration**: Merge `application` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `application` branch and create fresh one for next cycle

### 🛡️ Safety Features
- **Safe Merge Operations**: Uses --no-ff for clean merge history
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Branch Cleanup**: Automatically removes old branches after successful merge
- **Fresh Branch Creation**: Creates clean branches for next development cycle

### 🔍 Branch Detection & Smart Actions

**Application Branch (`application`):**  
- 🔄 Switch to application branch (if using forced mode)
- ✅ Commit application validation results (application testing work, no ROADMAP.md)
- 🔄 Merge validated work into `main`
- 🌱 Create fresh `application` branch for next cycle

**Main Branch (`main`):**
- ✅ Commit current progress (including ROADMAP.md updates from @PLAN.md)
- 📤 Push changes to main
- 🧪 Update application branch with latest main
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
        "a"|"application")
            TARGET_WORKFLOW="application"
            echo "🎯 Forced application branch checkpoint workflow"
            ;;
        *)
            echo "❌ Invalid branch flag: $BRANCH_FLAG"
            echo "💡 Valid flags: m (main), a (application)"
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
  "application")
    echo "🧪 APPLICATION BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Switch to application branch first to check for its changes
    if [ "$CURRENT_BRANCH" != "application" ]; then
        echo "🔄 Switching to application branch to check for changes..."
        git checkout application
    fi
    
    # Check for uncommitted changes on application branch
    if [ -n "$(git status --porcelain)" ]; then
        # Commit application results
        echo "✅ Committing application validation..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        
        # Use heredoc for proper multiline commit message
        COMMIT_MESSAGE=$(cat <<EOF
🧪 Application checkpoint: $CURRENT_DATE

✅ Application testing and validation completed
📊 Performance metrics captured
🎯 Ready for main branch merge

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
        git commit -m "$COMMIT_MESSAGE"
    else
        echo "✅ No uncommitted changes to commit on application branch"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Check if application has changes to merge (avoid empty merges)
    git checkout main
    git pull origin main
    
    echo "🔍 Checking if application has new changes..."
    if git merge-tree $(git merge-base main application) main application | grep -q "^"; then
        echo "📝 Changes detected - proceeding with merge"
    else
        echo "✅ No changes to merge - application already integrated"
        echo "🌱 Creating fresh application branch..."
        git branch -D application 2>/dev/null || true
        git push origin --delete application 2>/dev/null || true
        git checkout -b application
        git push origin application -u
        echo "✅ Application cycle complete (no merge needed)!"
        exit 0
    fi
    
    echo "🚀 Merging application into main..."
    MERGE_DATE=$(date '+%Y-%m-%d')
    
    # Use heredoc for proper multiline commit message
    MERGE_MESSAGE=$(cat <<EOF
🧪 Merge application cycle: $MERGE_DATE

✅ Application validation completed
📊 Performance metrics validated
🎯 Ready for next application cycle

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
    
    # Perform merge with proper error handling
    if ! git merge application --no-ff -m "$MERGE_MESSAGE"; then
        echo ""
        echo "🚨 MERGE CONFLICT DETECTED!"
        echo "❌ Automatic checkpoint halted - this should not happen with our workflows"
        echo ""
        echo "🤔 Possible causes:"
        echo "   • Unexpected changes made directly to main branch"
        echo "   • Manual modifications to application branch history"
        echo "   • External changes not following Axiom workflow"
        echo ""
        echo "🆘 HUMAN CONSULTATION REQUIRED"
        echo "📋 Current status:"
        echo "   • Application branch has been committed"
        echo "   • Main branch is checked out"
        echo "   • Merge conflict exists between application and main"
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
    
    # Delete old application branch
    echo "🗑️ Cleaning up old application branch..."
    git branch -D application
    git push origin --delete application
    
    # Create fresh application branch
    echo "🌱 Creating fresh application branch..."
    git checkout -b application
    git push origin application -u
    
    # Update TRACKING.md with completion status
    echo "📊 Updating TRACKING.md with merge completion..."
    COMPLETION_DATE=$(date '+%Y-%m-%d')
    sed -i '' "s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $COMPLETION_DATE | \*\*Status\*\*: Application cycle completed - merged to main/" ApplicationDevelopment/TRACKING.md
    
    echo "✅ Application cycle complete!"
    echo "🎯 Fresh application branch ready for next cycle"
    echo "📊 TRACKING.md updated with completion status"
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
    
    # Update application branch with latest main  
    echo "🧪 Updating application branch with latest main..."
    if git show-ref --verify --quiet refs/remotes/origin/application; then
        git fetch origin application
        git checkout application
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING APPLICATION BRANCH!"
            echo "❌ Cross-branch update failed - manual resolution required"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Main branch changes have been committed and pushed"
            echo "   • Application branch is checked out"
            echo "   • Conflict exists when pulling main into application"
            echo ""
            echo "💡 Manual resolution steps:"
            echo "   1. Run: git status (to see conflicted files)"
            echo "   2. Edit conflicted files to resolve conflicts"
            echo "   3. Run: git add <resolved-files>"
            echo "   4. Run: git commit (to complete the merge)"
            echo "   5. Run: git push origin application"
            echo "   6. Then re-run: @CHECKPOINT.md (to continue automation)"
            echo ""
            echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
            exit 1
        fi
        git push origin application
        echo "✅ Application branch updated with latest main"
    else
        echo "🌱 Application branch doesn't exist remotely"
    fi
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    echo "✅ Main branch checkpoint complete"
    echo "🔄 Application branch synchronized with latest main changes"
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

### **Application Workflow** (Auto or Forced)
```bash
# After application testing and validation
@CHECKPOINT.md     # Auto-detects application branch
@CHECKPOINT.md a   # Forces application workflow from any branch
                   # → Commits results, merges to main, creates fresh application
```

### **Main Branch Coordination** (Auto or Forced)
```bash
# Strategic planning and coordination
@CHECKPOINT.md     # Auto-detects main branch
@CHECKPOINT.md m   # Forces main workflow from any branch
                   # → Commits status, pushes to main, updates application branch
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context (default mode)
- **🎯 Forced Workflow Execution**: Execute specific branch workflows regardless of current branch
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Merge & Restart**: Merges completed work to main and creates fresh branches
- **🔄 Application Synchronization**: Application branch automatically synchronizes with latest main changes
- **🚨 Conflict Detection & Human Consultation**: Halts automation and provides guidance for conflicts
- **🌱 Automated Branch Cycling**: Complete cycle automation for application testing
- **📊 Status Tracking**: Maintains project coordination across branches
- **⚡ Application-Focused Operation**: Optimized for application development and testing workflows

**Perfect for Axiom application development workflow with seamless integration testing and validation!**