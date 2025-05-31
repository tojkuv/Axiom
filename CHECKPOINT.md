# @CHECKPOINT.md - Branch-Aware Checkpoint System

## ⚡ Intelligent Branch-Aware Checkpoint Management

This command provides intelligent checkpoint management that adapts to your current branch context:

### 🛡️ Safety Features
- **No Automatic Rebasing**: Prevents data loss from conflicts
- **Uncommitted Change Detection**: Only commits when there are actual changes
- **Safe Update Mode**: Fetches and reports status without dangerous operations
- **User Control**: Provides manual options for updating branches
### 🔍 Branch Detection & Smart Actions

**Development Branch (`development`):**
- ✅ Commit all changes with intelligent commit message
- 🔄 Update from latest `main` via rebase
- 🚀 Create pull request to `main`
- 📊 Performance validation

**Integration Branch (`integration`):**  
- ✅ Commit integration validation results
- 🔄 Update from latest `main` via rebase
- 🚀 Create pull request to `main`
- 🧪 Integration test verification

**Main Branch (`main`):**
- ✅ Commit current progress
- 📋 Update project status  
- 🔧 Coordinate with development branch (fetch/create)
- 🧪 Coordinate with integration branch (fetch/create)
- 🔄 Return to main for continued work

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
    echo "🔧 DEVELOPMENT BRANCH CHECKPOINT"
    
    # Check for uncommitted changes first
    if [ -n "$(git status --porcelain)" ]; then
        # Commit changes with intelligent message
        echo "✅ Committing development progress..."
        git add .
        git commit -m "🔧 Development checkpoint: $(date '+%Y-%m-%d %H:%M')

    📦 Framework enhancements and feature development
    🎯 Preparing for integration validation
    
    🤖 Generated with Claude Code
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "✅ No uncommitted changes to commit"
    fi
    
    # Update from main (SAFE MODE)
    echo "🔄 Fetching latest from main..."
    git fetch origin main
    
    # Check if rebase is needed and safe
    BEHIND_COUNT=$(git rev-list --count HEAD..origin/main)
    if [ "$BEHIND_COUNT" -eq 0 ]; then
        echo "✅ Development branch is up to date with main"
    else
        echo "⚠️  Development branch is $BEHIND_COUNT commits behind main"
        echo "🛑 SAFETY: Skipping automatic rebase to prevent conflicts"
        echo "💡 To update manually: git rebase origin/main"
        echo "💡 Or merge instead: git merge origin/main"
    fi
    
    # Push and create PR
    echo "🚀 Creating pull request..."
    git push origin development -u
    gh pr create --title "🔧 Development Progress: $(date '+%Y-%m-%d')" --body "$(cat <<'EOF'
## 🔧 Development Progress Summary

### ✅ Completed Development Work
- Framework feature enhancements
- Core functionality improvements
- Developer experience optimizations

### 🎯 Ready for Integration
- All development targets met
- Framework builds cleanly
- Ready for real-world validation

### 🧪 Next Steps
- Integration testing in AxiomTestApp
- Performance validation
- Real-world usage verification

🤖 Generated with Claude Code
EOF
)"
    ;;
    
  "integration")
    echo "🧪 INTEGRATION BRANCH CHECKPOINT"
    
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
    
    # Update from main (SAFE MODE)
    echo "🔄 Fetching latest from main..."
    git fetch origin main
    
    # Check if rebase is needed and safe
    BEHIND_COUNT=$(git rev-list --count HEAD..origin/main)
    if [ "$BEHIND_COUNT" -eq 0 ]; then
        echo "✅ Integration branch is up to date with main"
    else
        echo "⚠️  Integration branch is $BEHIND_COUNT commits behind main"
        echo "🛑 SAFETY: Skipping automatic rebase to prevent conflicts"
        echo "💡 To update manually: git rebase origin/main"
        echo "💡 Or merge instead: git merge origin/main"
    fi
    
    # Push and create PR
    echo "🚀 Creating pull request..."
    git push origin integration -u
    gh pr create --title "🧪 Integration Validation: $(date '+%Y-%m-%d')" --body "$(cat <<'EOF'
## 🧪 Integration Validation Complete

### ✅ Validation Results
- Real-world iOS app testing
- Performance benchmarking
- Feature integration verification

### 📊 Metrics & Performance
- All performance targets met
- Clean integration with AxiomTestApp
- Zero integration issues

### 🎯 Production Readiness
- Framework validated in real application
- All tests passing
- Ready for production merge

🤖 Generated with Claude Code
EOF
)"
    ;;
    
  "main")
    echo "🎯 MAIN BRANCH CHECKPOINT - WITH BRANCH COORDINATION"
    
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
    
    # Coordinate with development branch
    echo "🔧 Coordinating with development branch..."
    if git show-ref --verify --quiet refs/remotes/origin/development; then
        echo "📡 Development branch exists - fetching updates..."
        git checkout development
        git fetch origin development
        git pull origin development
        echo "✅ Development branch updated"
    else
        echo "🌱 Creating fresh development branch..."
        git checkout -b development
        git push origin development -u
        echo "✅ Fresh development branch created"
    fi
    
    # Coordinate with integration branch  
    echo "🧪 Coordinating with integration branch..."
    if git show-ref --verify --quiet refs/remotes/origin/integration; then
        echo "📡 Integration branch exists - fetching updates..."
        git checkout integration
        git fetch origin integration
        git pull origin integration
        echo "✅ Integration branch updated"
    else
        echo "🌱 Creating fresh integration branch..."
        git checkout -b integration
        git push origin integration -u
        echo "✅ Fresh integration branch created"
    fi
    
    # Return to main
    echo "🔄 Returning to main branch..."
    git checkout main
    
    echo "✅ Main branch checkpoint complete with branch coordination"
    echo "📋 All branches synchronized and ready"
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
                # → Commits, updates, creates PR
```

### **Integration Workflow**  
```bash
# After validation testing
@CHECKPOINT.md  # Auto-detects integration branch
                # → Commits results, updates, creates PR
```

### **Main Branch Coordination**
```bash
# Strategic planning and coordination
@CHECKPOINT.md  # Auto-detects main branch
                # → Commits, pushes main, coordinates with dev/integration branches
```

---

## ⚡ Intelligence Features

- **🤖 Branch Auto-Detection**: Automatically adapts to current context
- **📝 Intelligent Commit Messages**: Context-aware commit descriptions  
- **🔄 Smart Updates**: Rebase from main to keep history clean
- **🚀 Automated PRs**: Creates appropriate pull requests with detailed descriptions
- **🌐 Branch Coordination**: Main branch automatically coordinates with dev/integration
- **📊 Status Tracking**: Maintains project coordination across branches

**Perfect for the Axiom development workflow with seamless human-AI collaboration!**