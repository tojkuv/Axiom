# @CHECKPOINT.md - Branch-Aware Checkpoint System

## ⚡ Intelligent Branch-Aware Checkpoint Management

This command provides intelligent checkpoint management that adapts to your current branch context:

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
- 📋 Update project status
- 🎯 No branching needed (already on main)

---

## 🤖 Execution

**Claude, execute this intelligent checkpoint process:**

1. **Detect Current Branch & Execute Appropriate Workflow**

```bash
# 1. Detect current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "🎯 Current branch: $CURRENT_BRANCH"

# 2. Check git status and show what will be committed
echo "📋 Current changes:"
git status --short

# 3. Branch-specific checkpoint logic
case "$CURRENT_BRANCH" in
  "development")
    echo "🔧 DEVELOPMENT BRANCH CHECKPOINT - MERGE & RESTART"
    
    # Check for uncommitted changes first
    if [ -n "$(git status --porcelain)" ]; then
        # Commit changes with intelligent message
        echo "✅ Committing development progress..."
        git add .
        git commit -m "🔧 Development checkpoint: $(date '+%Y-%m-%d %H:%M')

    📦 Framework enhancements and feature development
    🎯 Ready for main branch merge
    
    🤖 Generated with Claude Code
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "✅ No uncommitted changes to commit"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Switch to main and merge development
    echo "🔄 Switching to main..."
    git checkout main
    git pull origin main
    
    echo "🚀 Merging development into main..."
    if ! git merge development --no-ff -m "🔧 Merge development cycle: $(date '+%Y-%m-%d')

✅ Development work completed and validated
📦 Framework enhancements integrated
🎯 Ready for next development cycle

🤖 Generated with Claude Code

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
        git commit -m "🧪 Integration checkpoint: $(date '+%Y-%m-%d %H:%M')

    ✅ Real-world validation completed
    📊 Performance metrics captured
    🎯 Ready for main branch merge
    
    🤖 Generated with Claude Code
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "✅ No uncommitted changes to commit"
    fi
    
    # Fetch latest main
    echo "🔄 Fetching latest main..."
    git fetch origin main
    
    # Switch to main and merge integration
    echo "🔄 Switching to main..."
    git checkout main
    git pull origin main
    
    echo "🚀 Merging integration into main..."
    if ! git merge integration --no-ff -m "🧪 Merge integration cycle: $(date '+%Y-%m-%d')

✅ Integration validation completed
📊 Performance metrics validated
🎯 Ready for next integration cycle

🤖 Generated with Claude Code

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
    echo "🎯 MAIN BRANCH CHECKPOINT"
    
    # Commit progress on main
    echo "✅ Committing main branch progress..."
    git add .
    git commit -m "🎯 Main branch checkpoint: $(date '+%Y-%m-%d %H:%M')

    📋 Project status update and coordination
    🚀 Strategic planning and documentation
    
    🤖 Generated with Claude Code
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push to main
    echo "🚀 Pushing to main..."
    git push origin main
    
    echo "✅ Main branch checkpoint complete"
    echo "📋 No PR needed (already on main)"
    ;;
    
  *)
    echo "❓ Unknown branch: $CURRENT_BRANCH"
    echo "🎯 Creating standard checkpoint..."
    
    # Standard checkpoint for other branches
    git add .
    git commit -m "📌 Checkpoint on $CURRENT_BRANCH: $(date '+%Y-%m-%d %H:%M')

    🔄 Branch-specific progress update
    
    🤖 Generated with Claude Code
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push origin "$CURRENT_BRANCH" -u
    echo "✅ Standard checkpoint complete"
    ;;
esac

echo ""
echo "🎉 CHECKPOINT COMPLETE"
echo "📍 Branch: $CURRENT_BRANCH"
echo "🕐 Time: $(date)"
```

---

## 🎯 Usage Patterns

### **Development Workflow**
```bash
# While working on framework features
@CHECKPOINT.md  # Auto-detects development branch
                # → Commits, merges to main, updates integration, creates fresh development
```

### **Integration Workflow**  
```bash
# After validation testing
@CHECKPOINT.md  # Auto-detects integration branch
                # → Commits results, merges to main, updates development, creates fresh integration
```

### **Main Branch Coordination**
```bash
# Strategic planning and coordination
@CHECKPOINT.md  # Auto-detects main branch
                # → Commits status, pushes to main
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Merge & Restart**: Merges completed work to main and creates fresh branches
- **🔄 Cross-Branch Updates**: Each branch updates the other with latest main changes
- **🚨 Conflict Detection & Human Consultation**: Halts automation and provides guidance for conflicts
- **🌱 Automated Branch Cycling**: Complete cycle automation for development and integration
- **📊 Status Tracking**: Maintains project coordination across branches

**Perfect for the Axiom development workflow with seamless human-AI collaboration!**