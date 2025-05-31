# @CHECKPOINT.md - Branch-Aware Checkpoint System

## ⚡ Intelligent Branch-Aware Checkpoint Management

This command provides intelligent checkpoint management that adapts to your current branch context or explicit branch targeting:

### 🎯 **Usage Modes**
- **`@CHECKPOINT.md`** → Auto-detect current branch and execute appropriate workflow
- **`@CHECKPOINT.md m`** → Force main branch checkpoint workflow (regardless of current branch)
- **`@CHECKPOINT.md d`** → Force development branch checkpoint workflow (regardless of current branch)  
- **`@CHECKPOINT.md i`** → Force integration branch checkpoint workflow (regardless of current branch)

### 🧠 **Branch Flag Intelligence**
**Auto-Detection Mode** (no flags): Detects current git branch and executes appropriate workflow
**Forced Mode** (with flags): Executes specific branch workflow regardless of current branch context
**Safety Override**: Forced mode useful for cross-branch operations and explicit workflow control

### 🛡️ Safety Features
- **Safe Merge Operations**: Uses --no-ff for clean merge history
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Merge Conflict Detection**: Stops automation and consults human if conflicts occur
- **Branch Cleanup**: Automatically removes old branches after successful merge
- **Fresh Branch Creation**: Creates clean branches for next development cycle
### 🔍 Branch Detection & Smart Actions

**Development Branch (`development`):**
- ✅ Commit all changes with intelligent commit message
- 🔄 Merge completed work into `main`
- 🧪 Update integration branch with latest main
- 🌱 Create fresh `development` branch for next cycle

**Integration Branch (`integration`):**  
- ✅ Commit integration validation results
- 🔄 Merge validated work into `main`
- 🔧 Update development branch with latest main
- 🌱 Create fresh `integration` branch for next cycle

**Main Branch (`main`):**
- ✅ Commit current progress
- 📤 Push changes to main
- 🔧 Update development branch with latest main
- 🧪 Update integration branch with latest main
- 🔄 Synchronize all branches with main changes

---

## 🤖 Execution

**Claude, execute this intelligent checkpoint process:**

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
        "d"|"development")
            TARGET_WORKFLOW="development"
            echo "🎯 Forced development branch checkpoint workflow"
            ;;
        "i"|"integration")
            TARGET_WORKFLOW="integration"
            echo "🎯 Forced integration branch checkpoint workflow"
            ;;
        *)
            echo "❌ Invalid branch flag: $BRANCH_FLAG"
            echo "💡 Valid flags: m (main), d (development), i (integration)"
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
echo "📋 Current changes:"
git status --short

# Early exit if no changes and target is development/integration
if [ -z "$(git status --porcelain)" ] && [ "$TARGET_WORKFLOW" != "main" ]; then
    echo "✅ No changes detected on $TARGET_WORKFLOW branch"
    echo "🤖 Skipping checkpoint - no work to commit or merge"
    exit 0
fi

# 4. Execute workflow based on target (auto-detected or forced)
case "$TARGET_WORKFLOW" in
  "development")
    echo "🔧 DEVELOPMENT BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Check for uncommitted changes first
    if [ -n "$(git status --porcelain)" ]; then
        # Commit changes with intelligent message
        echo "✅ Committing development progress..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "🔧 Development checkpoint: $CURRENT_DATE

📦 Framework enhancements and feature development
🎯 Ready for main branch merge

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "✅ No uncommitted changes to commit"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Check if development has changes to merge (avoid empty merges)
    git checkout main
    git pull origin main
    
    echo "🔍 Checking if development has new changes..."
    if git merge-tree $(git merge-base main development) main development | grep -q "^"; then
        echo "📝 Changes detected - proceeding with merge"
    else
        echo "✅ No changes to merge - development already integrated"
        echo "🌱 Creating fresh development branch..."
        git branch -D development 2>/dev/null || true
        git push origin --delete development 2>/dev/null || true
        git checkout -b development
        git push origin development -u
        echo "✅ Development cycle complete (no merge needed)!"
        exit 0
    fi
    
    echo "🚀 Merging development into main..."
    MERGE_DATE=$(date '+%Y-%m-%d')
    if ! git merge development --no-ff -m "🔧 Merge development cycle: $MERGE_DATE

✅ Development work completed and validated
📦 Framework enhancements integrated
🎯 Ready for next development cycle

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"; then
        echo ""
        echo "🚨 MERGE CONFLICT DETECTED!"
        echo "❌ Automatic checkpoint halted - this should not happen with our workflows"
        echo ""
        echo "🤔 Possible causes:"
        echo "   • Unexpected changes made directly to main branch"
        echo "   • Manual modifications to development branch history"
        echo "   • External changes not following Axiom workflow"
        echo ""
        echo "🆘 HUMAN CONSULTATION REQUIRED"
        echo "📋 Current status:"
        echo "   • Development branch has been committed"
        echo "   • Main branch is checked out"
        echo "   • Merge conflict exists between development and main"
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
    
    # Update integration branch with latest main
    echo "🧪 Updating integration branch..."
    if git show-ref --verify --quiet refs/remotes/origin/integration; then
        git checkout integration
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING INTEGRATION BRANCH!"
            echo "❌ Cross-branch update failed - this should not happen with our workflows"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Development work has been merged to main"
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
        echo "🌱 Integration branch doesn't exist, will be created fresh"
    fi
    
    # Switch back to main
    echo "🔄 Returning to main..."
    git checkout main
    
    # Delete old development branch
    echo "🗑️ Cleaning up old development branch..."
    git branch -D development
    git push origin --delete development
    
    # Create fresh development branch
    echo "🌱 Creating fresh development branch..."
    git checkout -b development
    git push origin development -u
    
    echo "✅ Development cycle complete!"
    echo "🎯 Fresh development branch ready for next cycle"
    ;;
    
  "integration")
    echo "🧪 INTEGRATION BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Check for uncommitted changes first
    if [ -n "$(git status --porcelain)" ]; then
        # Commit integration results
        echo "✅ Committing integration validation..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "🧪 Integration checkpoint: $CURRENT_DATE

✅ Real-world validation completed
📊 Performance metrics captured
🎯 Ready for main branch merge

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "✅ No uncommitted changes to commit"
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
    if ! git merge integration --no-ff -m "🧪 Merge integration cycle: $MERGE_DATE

✅ Integration validation completed
📊 Performance metrics validated
🎯 Ready for next integration cycle

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"; then
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
    
    # Update development branch with latest main
    echo "🔧 Updating development branch..."
    if git show-ref --verify --quiet refs/remotes/origin/development; then
        git checkout development
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING DEVELOPMENT BRANCH!"
            echo "❌ Cross-branch update failed - this should not happen with our workflows"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Integration work has been merged to main"
            echo "   • Development branch is checked out"
            echo "   • Conflict exists when pulling main into development"
            echo ""
            echo "💡 Manual resolution steps:"
            echo "   1. Run: git status (to see conflicted files)"
            echo "   2. Edit conflicted files to resolve conflicts"
            echo "   3. Run: git add <resolved-files>"
            echo "   4. Run: git commit (to complete the merge)"
            echo "   5. Run: git push origin development"
            echo "   6. Then re-run: @CHECKPOINT.md (to continue automation)"
            echo ""
            echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
            exit 1
        fi
        git push origin development
        echo "✅ Development branch updated with latest main"
    else
        echo "🌱 Development branch doesn't exist, will be created fresh"
    fi
    
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
    echo "🎯 MAIN BRANCH CHECKPOINT - UPDATE ALL BRANCHES"
    
    # Check for uncommitted changes first
    CHANGES_COUNT=$(git status --porcelain | wc -l)
    if [ "$CHANGES_COUNT" -gt 0 ]; then
        # Commit progress on main
        echo "✅ Committing main branch progress ($CHANGES_COUNT files changed)..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "🎯 Main branch checkpoint: $CURRENT_DATE

📋 Project status update and coordination
🚀 Strategic planning and documentation

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        # Push to main
        echo "🚀 Pushing to main..."
        git push origin main
    else
        echo "✅ No uncommitted changes to commit"
        echo "📋 Proceeding with branch synchronization only..."
    fi
    
    # Update development branch with latest main
    echo "🔧 Updating development branch with latest main..."
    if git show-ref --verify --quiet refs/remotes/origin/development; then
        git fetch origin development
        git checkout development
        if ! git pull origin main; then
            echo ""
            echo "🚨 CONFLICT UPDATING DEVELOPMENT BRANCH!"
            echo "❌ Cross-branch update failed - manual resolution required"
            echo ""
            echo "🆘 HUMAN CONSULTATION REQUIRED"
            echo "📋 Current status:"
            echo "   • Main branch changes have been committed and pushed"
            echo "   • Development branch is checked out"
            echo "   • Conflict exists when pulling main into development"
            echo ""
            echo "💡 Manual resolution steps:"
            echo "   1. Run: git status (to see conflicted files)"
            echo "   2. Edit conflicted files to resolve conflicts"
            echo "   3. Run: git add <resolved-files>"
            echo "   4. Run: git commit (to complete the merge)"
            echo "   5. Run: git push origin development"
            echo "   6. Then re-run: @CHECKPOINT.md (to continue automation)"
            echo ""
            echo "🛑 Checkpoint process stopped. Please resolve conflicts and retry."
            exit 1
        fi
        git push origin development
        echo "✅ Development branch updated with latest main"
    else
        echo "🌱 Development branch doesn't exist remotely"
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
    echo "🔄 All branches synchronized with latest main changes"
    echo "📋 No PR needed (already on main)"
    ;;
    
  *)
    echo "❓ Unknown branch: $CURRENT_BRANCH"
    
    # Only checkpoint if there are changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "🎯 Creating standard checkpoint..."
        git add .
        CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
        git commit -m "📌 Checkpoint on $CURRENT_BRANCH: $CURRENT_DATE

🔄 Branch-specific progress update

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
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

### **Development Workflow** (Auto or Forced)
```bash
# While working on framework features
@CHECKPOINT.md     # Auto-detects development branch
@CHECKPOINT.md d   # Forces development workflow from any branch
                   # → Commits, merges to main, updates integration, creates fresh development
```

### **Integration Workflow** (Auto or Forced)
```bash
# After validation testing  
@CHECKPOINT.md     # Auto-detects integration branch
@CHECKPOINT.md i   # Forces integration workflow from any branch
                   # → Commits results, merges to main, updates development, creates fresh integration
```

### **Main Branch Coordination** (Auto or Forced)
```bash
# Strategic planning and coordination
@CHECKPOINT.md     # Auto-detects main branch
@CHECKPOINT.md m   # Forces main workflow from any branch
                   # → Commits status, pushes to main, updates all branches with latest main
```

### **Cross-Branch Operations** (Advanced)
```bash
# Force specific workflow regardless of current branch
@CHECKPOINT.md d   # Execute development checkpoint from main/integration branch
@CHECKPOINT.md i   # Execute integration checkpoint from main/development branch  
@CHECKPOINT.md m   # Execute main checkpoint from development/integration branch
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context (default mode)
- **🎯 Forced Workflow Execution**: Execute specific branch workflows regardless of current branch
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Merge & Restart**: Merges completed work to main and creates fresh branches
- **🔄 Cross-Branch Synchronization**: All branches automatically synchronize with latest main changes
- **🚨 Conflict Detection & Human Consultation**: Halts automation and provides guidance for conflicts
- **🌱 Automated Branch Cycling**: Complete cycle automation for development and integration
- **📊 Status Tracking**: Maintains project coordination across branches
- **⚡ Flexible Operation Modes**: Both auto-detection and explicit branch targeting supported
- **🛡️ Safety Validation**: Validates branch flags and provides clear error messages for invalid usage

**Perfect for the Axiom development workflow with seamless human-AI collaboration and flexible branch management!**