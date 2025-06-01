# @CHECKPOINT.md - Framework Development Checkpoint System

## ⚡ Framework-Focused Checkpoint Management

This command provides intelligent checkpoint management for framework development workflows, focusing on core framework implementation and development branch management.

### 🎯 **Usage Modes**
- **`@CHECKPOINT.md`** → Auto-detect current branch and execute appropriate workflow
- **`@CHECKPOINT.md m`** → Force main branch checkpoint workflow (regardless of current branch)
- **`@CHECKPOINT.md f`** → Force framework branch checkpoint workflow (regardless of current branch)

### 🧠 **Branch Focus**
**Framework Development Context**: Primarily works with framework branch for framework core implementation
**Framework Branch**: Framework development, core feature implementation, architecture evolution
**Main Branch**: Strategic coordination and documentation updates

### 🔄 **Standardized Git Workflow**
All FrameworkProtocols commands follow this workflow:
1. **Branch Setup**: Switch to `framework` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `framework` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `framework` branch with descriptive messages
5. **Integration**: Merge `framework` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `framework` branch and create fresh one for next cycle

### 🛡️ Safety Features
- **Safe Merge Operations**: Uses --no-ff for clean merge history
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Branch Cleanup**: Automatically removes old branches after successful merge
- **Fresh Branch Creation**: Creates clean branches for next development cycle

### 🔍 Branch Detection & Smart Actions

**Framework Branch (`framework`):**
- 🔄 Switch to framework branch (if using forced mode)
- ✅ Commit framework changes with intelligent commit message (framework work only, no ROADMAP.md)
- 🔄 Merge completed work into `main`
- 🌱 Create fresh `framework` branch for next cycle

**Main Branch (`main`):**
- ✅ Commit current progress (including ROADMAP.md updates from @PLAN.md)
- 📤 Push changes to main
- 🔧 Update framework branch with latest main
- 🔄 Synchronize all branches with main changes

---

## 🤖 Execution

**Claude, execute this framework-focused checkpoint process:**

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
        "f"|"framework")
            TARGET_WORKFLOW="framework"
            echo "🎯 Forced framework branch checkpoint workflow"
            ;;
        *)
            echo "❌ Invalid branch flag: $BRANCH_FLAG"
            echo "💡 Valid flags: m (main), f (framework)"
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
  "framework")
    echo "🔧 FRAMEWORK BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Switch to framework branch first to check for its changes
    if [ "$CURRENT_BRANCH" != "framework" ]; then
        echo "🔄 Switching to framework branch to check for changes..."
        git checkout framework
    fi
    
    # Check for uncommitted changes on framework branch
    if [ -n "$(git status --porcelain)" ]; then
        # Commit changes with intelligent message
        echo "✅ Committing framework progress..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        
        # Use heredoc for proper multiline commit message
        COMMIT_MESSAGE=$(cat <<EOF
🔧 Framework checkpoint: $CURRENT_DATE

📦 Framework enhancements and feature development
🎯 Ready for main branch merge

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
        git commit -m "$COMMIT_MESSAGE"
    else
        echo "✅ No uncommitted changes to commit on framework branch"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Check if framework has changes to merge (avoid empty merges)
    git checkout main
    git pull origin main
    
    echo "🔍 Checking if framework has new changes..."
    if git merge-tree $(git merge-base main framework) main framework | grep -q "^"; then
        echo "📝 Changes detected - proceeding with merge"
    else
        echo "✅ No changes to merge - framework already integrated"
        echo "🌱 Creating fresh framework branch..."
        git branch -D framework 2>/dev/null || true
        git push origin --delete framework 2>/dev/null || true
        git checkout -b framework
        git push origin framework -u
        echo "✅ Framework cycle complete (no merge needed)!"
        exit 0
    fi
    
    echo "🚀 Merging framework into main..."
    MERGE_DATE=$(date '+%Y-%m-%d')
    
    # Use heredoc for proper multiline commit message
    MERGE_MESSAGE=$(cat <<EOF
🔧 Merge framework cycle: $MERGE_DATE

✅ Framework work completed and validated
📦 Framework enhancements integrated
🎯 Ready for next framework cycle

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)
    
    # Perform merge with proper error handling
    if ! git merge framework --no-ff -m "$MERGE_MESSAGE"; then
        echo ""
        echo "🚨 MERGE CONFLICT DETECTED!"
        echo "❌ Automatic checkpoint halted - this should not happen with our workflows"
        echo ""
        echo "🤔 Possible causes:"
        echo "   • Unexpected changes made directly to main branch"
        echo "   • Manual modifications to framework branch history"
        echo "   • External changes not following Axiom workflow"
        echo ""
        echo "🆘 HUMAN CONSULTATION REQUIRED"
        echo "📋 Current status:"
        echo "   • Framework branch has been committed"
        echo "   • Main branch is checked out"
        echo "   • Merge conflict exists between framework and main"
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
    
    # Validate merge included expected changes
    echo "🔍 Validating merge contents..."
    if [ ! -d "FrameworkProtocols" ] || [ ! -d "ApplicationProtocols" ]; then
        echo ""
        echo "🚨 MERGE VALIDATION FAILED!"
        echo "❌ Expected directory structure missing after merge"
        echo "📋 Expected directories: FrameworkProtocols/, ApplicationProtocols/"
        echo "📋 Current structure:"
        ls -la | grep -E "^d"
        echo ""
        echo "🆘 HUMAN CONSULTATION REQUIRED"
        echo "💡 This indicates the merge didn't properly include development changes"
        echo "💡 Manual investigation and re-merge may be required"
        echo ""
        echo "🛑 Checkpoint process stopped. Manual intervention needed."
        exit 1
    fi
    echo "✅ Merge validation successful - directory structure preserved"
    
    # Push updated main
    echo "📤 Pushing updated main..."
    git push origin main
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    # Delete old framework branch
    echo "🗑️ Cleaning up old framework branch..."
    git branch -D framework
    git push origin --delete framework
    
    # Create fresh framework branch
    echo "🌱 Creating fresh framework branch..."
    git checkout -b framework
    git push origin framework -u
    
    # Update TRACKING.md with completion status
    echo "📊 Updating TRACKING.md with merge completion..."
    COMPLETION_DATE=$(date '+%Y-%m-%d')
    sed -i '' "s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $COMPLETION_DATE | \*\*Status\*\*: Framework cycle completed - merged to main/" FrameworkProtocols/TRACKING.md
    
    echo "✅ Framework cycle complete!"
    echo "🎯 Fresh framework branch ready for next cycle"
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

📋 Framework development coordination
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
    
    # Update framework branch with latest main
    echo "🔧 Updating framework branch with latest main..."
    if git show-ref --verify --quiet refs/remotes/origin/framework; then
        git fetch origin framework
        git checkout framework
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING FRAMEWORK BRANCH!"
            echo "❌ Cross-branch update failed - manual resolution required"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Main branch changes have been committed and pushed"
            echo "   • Framework branch is checked out"
            echo "   • Conflict exists when pulling main into framework"
            echo ""
            echo "💡 Manual resolution steps:"
            echo "   1. Run: git status (to see conflicted files)"
            echo "   2. Edit conflicted files to resolve conflicts"
            echo "   3. Run: git add <resolved-files>"
            echo "   4. Run: git commit (to complete the merge)"
            echo "   5. Run: git push origin framework"
            echo "   6. Then re-run: @CHECKPOINT.md (to continue automation)"
            echo ""
            echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
            exit 1
        fi
        git push origin framework
        echo "✅ Framework branch updated with latest main"
    else
        echo "🌱 Framework branch doesn't exist remotely"
    fi
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    echo "✅ Main branch checkpoint complete"
    echo "🔄 Framework branch synchronized with latest main changes"
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

🔄 Framework development progress update

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

### **Framework Workflow** (Auto or Forced)
```bash
# While working on framework features
@CHECKPOINT.md     # Auto-detects framework branch
@CHECKPOINT.md f   # Forces framework workflow from any branch
                   # → Commits, merges to main, creates fresh framework
```

### **Main Branch Coordination** (Auto or Forced)
```bash
# Strategic planning and coordination
@CHECKPOINT.md     # Auto-detects main branch
@CHECKPOINT.md m   # Forces main workflow from any branch
                   # → Commits status, pushes to main, updates framework branch
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context (default mode)
- **🎯 Forced Workflow Execution**: Execute specific branch workflows regardless of current branch
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Merge & Restart**: Merges completed work to main and creates fresh branches
- **🔄 Framework Synchronization**: Framework branch automatically synchronizes with latest main changes
- **🚨 Conflict Detection & Human Consultation**: Halts automation and provides guidance for conflicts
- **🌱 Automated Branch Cycling**: Complete cycle automation for framework workflow
- **📊 Status Tracking**: Maintains project coordination across branches
- **⚡ Framework-Focused Operation**: Optimized for core framework development and implementation

**Perfect for Axiom framework development workflow with seamless core implementation and testing!**