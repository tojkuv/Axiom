# @CHECKPOINT.md - Branch-Aware Checkpoint System

## ⚡ Intelligent Branch-Aware Checkpoint Management

This command provides intelligent checkpoint management that adapts to your current branch context:

### 🛡️ Safety Features
- **Safe Merge Operations**: Uses --no-ff for clean merge history
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Branch Cleanup**: Automatically removes old branches after successful merge
- **Fresh Branch Creation**: Creates clean branches for next development cycle
### 🔍 Branch Detection & Smart Actions

**Development Branch (`development`):**
- ✅ Commit all changes with intelligent commit message
- 🔄 Merge completed work into `main`
- 🌱 Create fresh `development` branch for next cycle
- 📊 Performance validation complete

**Integration Branch (`integration`):**  
- ✅ Commit integration validation results
- 🔄 Merge validated work into `main`
- 🌱 Create fresh `integration` branch for next cycle
- 🧪 Integration test verification complete

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
    git merge development --no-ff -m "🔧 Merge development cycle: $(date '+%Y-%m-%d')

✅ Development work completed and validated
📦 Framework enhancements integrated
🎯 Ready for next development cycle

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push updated main
    echo "📤 Pushing updated main..."
    git push origin main
    
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
    git merge integration --no-ff -m "🧪 Merge integration cycle: $(date '+%Y-%m-%d')

✅ Integration validation completed
📊 Performance metrics validated
🎯 Ready for next integration cycle

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push updated main
    echo "📤 Pushing updated main..."
    git push origin main
    
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
                # → Commits, merges to main, creates fresh development branch
```

### **Integration Workflow**  
```bash
# After validation testing
@CHECKPOINT.md  # Auto-detects integration branch
                # → Commits results, merges to main, creates fresh integration branch
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
- **🌱 Automated Branch Cycling**: Complete cycle automation for development and integration
- **📊 Status Tracking**: Maintains project coordination across branches

**Perfect for the Axiom development workflow with seamless human-AI collaboration!**