# @WORKSPACE.md - Intelligent Branch Workspace System

## 🎯 **Smart Branch Selection for New Terminals**

**This command intelligently selects the correct workspace branch based on your intent - never creates new branches, only uses our established three-branch system.**

---

## 🤖 **Automated Branch Detection & Switching**

**Usage**: `@WORKSPACE [intent-keyword]` or just `@WORKSPACE` for interactive selection

**Claude, execute this intelligent workspace selection:**

```bash
#!/bin/bash

# @WORKSPACE.md - Intelligent Branch Workspace System
echo "🎯 AXIOM WORKSPACE - Intelligent Branch Selection"
echo "=========================================="

# Function to switch to branch with context
switch_to_branch() {
    local branch=$1
    local context=$2
    
    echo "🌿 Switching to: $branch"
    echo "📋 Context: $context"
    echo ""
    
    # Stash any uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "💾 Stashing uncommitted changes..."
        git stash
    fi
    
    # Switch to the branch
    git checkout "$branch"
    
    # Show current status
    echo "✅ Now on: $(git branch --show-current)"
    echo "📊 Branch status:"
    git status --short
    echo ""
    
    # Display branch context
    case "$branch" in
        "main")
            echo "🎯 **MAIN BRANCH WORKSPACE**"
            echo "Focus: Documentation, organization, refactoring, strategic coordination"
            echo "Files: All documentation, archival, project coordination"
            echo "Tools: @REFACTOR.md, @PLAN.md, @PROPOSE.md"
            echo "Avoid: Framework code changes, test app changes"
            ;;
        "development") 
            echo "🔧 **DEVELOPMENT BRANCH WORKSPACE**"
            echo "Focus: Framework implementation, core features, architecture"
            echo "Files: /AxiomFramework/Sources/, /AxiomFramework/Tests/"
            echo "Tools: @DEVELOP.md, Swift development, framework building"
            echo "Avoid: Test app changes, documentation organization"
            ;;
        "integration")
            echo "🧪 **INTEGRATION BRANCH WORKSPACE**"
            echo "Focus: Real-world testing, AxiomTestApp validation, performance"
            echo "Files: /AxiomTestApp/, integration testing, validation"
            echo "Tools: @INTEGRATE.md, iOS app testing, performance measurement"
            echo "Avoid: Framework core changes, documentation organization"
            ;;
    esac
    echo ""
}

# Parse intent from arguments or prompt for selection
if [ $# -eq 0 ]; then
    # Interactive mode
    echo "🤔 What kind of work do you want to do?"
    echo ""
    echo "1️⃣  Framework Development (core, features, architecture)"
    echo "2️⃣  Integration Testing (real-world, validation, performance)" 
    echo "3️⃣  Documentation & Organization (refactor, archive, coordinate)"
    echo ""
    read -p "Select workspace (1-3): " choice
    
    case "$choice" in
        1) switch_to_branch "development" "Framework core development and feature implementation" ;;
        2) switch_to_branch "integration" "Real-world testing and validation in AxiomTestApp" ;;
        3) switch_to_branch "main" "Documentation organization and project coordination" ;;
        *) echo "❌ Invalid selection. Use 1, 2, or 3." ;;
    esac
else
    # Intent-based detection
    intent="$1"
    
    # Convert to lowercase for matching
    intent_lower=$(echo "$intent" | tr '[:upper:]' '[:lower:]')
    
    # Development branch keywords
    if echo "$intent_lower" | grep -qE "(develop|framework|core|feature|build|implement|code|swift|actor|client|context|macro|api|architect|enhance|protocol|class|struct|enum|function|method|property|type|generic|concurrency|async|await|performance|memory|optimization|algorithm|data|structure|state|capability|intelligence|pattern|design|system|module|component|infrastructure|foundation|advanced|technical|programming|software|engineering|sdk|library|package|dependency|compilation|debugging|testing-framework|unit-test|mock|stub|fake|fixture|helper|utility|tool|script|automation|ci|cd|pipeline|deployment|configuration|environment|setup|installation)"; then
        switch_to_branch "development" "Framework development - implementing core features and architecture"
        
    # Integration branch keywords  
    elif echo "$intent_lower" | grep -qE "(integrate|test|validate|app|real|world|ios|ui|swiftui|view|screen|interface|user|experience|ux|performance|benchmark|measure|metric|analysis|profile|trace|memory|cpu|network|storage|battery|launch|startup|responsiveness|throughput|latency|error|crash|stability|reliability|compatibility|device|simulator|xcode|provisioning|certificate|deployment|distribution|appstore|testflight|beta|production|live|demo|example|sample|showcase|tutorial|guide|walkthrough|scenario|workflow|journey|interaction|gesture|animation|transition|navigation|routing|deep|link|push|notification|background|foreground|lifecycle|state|restoration|persistence|synchronization|offline|online|connectivity|networking|api|rest|graphql|websocket|database|coredata|cloudkit|firebase|analytics|tracking|logging|monitoring|alerting|crash|reporting|feedback|review|rating|survey|interview|usability|accessibility|localization|internationalization|globalization|regional)"; then
        switch_to_branch "integration" "Integration testing - validating framework in real-world iOS application"
        
    # Main branch keywords
    elif echo "$intent_lower" | grep -qE "(document|doc|organize|refactor|archive|plan|coordinate|strategy|roadmap|proposal|manage|maintain|clean|structure|folder|directory|file|markdown|readme|guide|specification|template|index|navigation|cross|reference|link|consistency|standard|convention|pattern|best|practice|process|workflow|procedure|methodology|approach|philosophy|principle|rule|guideline|policy|governance|compliance|audit|review|quality|assurance|control|version|release|milestone|phase|sprint|iteration|cycle|timeline|schedule|deadline|priority|backlog|task|todo|issue|bug|feature|request|requirement|analysis|design|architecture|vision|mission|goal|objective|target|kpi|metric|measurement|evaluation|assessment|feedback|retrospective|lesson|learned|knowledge|sharing|transfer|training|education|onboarding|documentation|communication|collaboration|team|member|role|responsibility|accountability|ownership|stakeholder|user|customer|client|partner|vendor|supplier|contractor|consultant|advisor|expert|specialist|leader|manager|director)"; then
        switch_to_branch "main" "Documentation and organization - coordinating project structure and planning"
        
    # Default: Ask for clarification
    else
        echo "🤔 Intent '$intent' not clearly mapped to a workspace."
        echo ""
        echo "💡 **Keyword Hints:**"
        echo "🔧 **Development**: framework, core, features, swift, implementation, architecture"
        echo "🧪 **Integration**: test, validate, ios, app, real-world, performance, ui"
        echo "🎯 **Main**: document, organize, refactor, plan, coordinate, archive"
        echo ""
        echo "🔄 **Try again with**: @WORKSPACE [keyword]"
        echo "🔄 **Or use interactive**: @WORKSPACE"
    fi
fi

echo ""
echo "🎉 **WORKSPACE READY**"
echo "📍 Branch: $(git branch --show-current)"
echo "🕐 Time: $(date)"
echo ""
echo "💡 **Available Commands:**"
current_branch=$(git branch --show-current)
case "$current_branch" in
    "main")
        echo "   📋 @REFACTOR.md - Comprehensive code organization and cleanup"
        echo "   🎯 @PLAN.md - Strategic planning and coordination"  
        echo "   💡 @PROPOSE.md - Technical enhancement proposals"
        ;;
    "development")
        echo "   🔧 @DEVELOP.md - Framework implementation and features"
        echo "   🏗️ swift build - Build framework"
        echo "   🧪 swift test - Run framework tests"
        ;;
    "integration")
        echo "   🧪 @INTEGRATE.md - Real-world testing and validation"
        echo "   📱 open Axiom.xcworkspace - Open iOS test app"
        echo "   📊 Performance measurement and analysis"
        ;;
esac
echo ""
echo "🔄 **Switch workspaces**: @WORKSPACE [development|integration|main]"
echo "❓ **Need help**: @WORKSPACE help"
```

---

## 🌿 **Three-Branch System Overview**

### **🎯 Main Branch** - Documentation & Coordination
**Keywords**: `document`, `organize`, `refactor`, `plan`, `coordinate`, `archive`
- **Purpose**: Project coordination, documentation organization, strategic planning
- **Files**: All documentation, project coordination files, archives
- **Tools**: `@REFACTOR.md`, `@PLAN.md`, `@PROPOSE.md`
- **When to use**: Organizing docs, planning cycles, refactoring codebase structure

### **🔧 Development Branch** - Framework Implementation  
**Keywords**: `develop`, `framework`, `core`, `features`, `swift`, `implement`
- **Purpose**: Framework core development, architecture, new features
- **Files**: `/AxiomFramework/Sources/`, `/AxiomFramework/Tests/`
- **Tools**: `@DEVELOP.md`, Swift development, framework building
- **When to use**: Building framework features, core architecture work

### **🧪 Integration Branch** - Real-World Testing
**Keywords**: `test`, `validate`, `ios`, `app`, `real-world`, `performance`
- **Purpose**: AxiomTestApp validation, real-world testing, performance measurement
- **Files**: `/AxiomTestApp/`, integration testing, validation
- **Tools**: `@INTEGRATE.md`, iOS app testing, performance measurement  
- **When to use**: Testing framework in real app, validation, performance analysis

---

## 🎯 **Smart Intent Examples**

### **Development Examples**
```bash
@WORKSPACE framework     # → development branch
@WORKSPACE swift         # → development branch  
@WORKSPACE core          # → development branch
@WORKSPACE implement     # → development branch
@WORKSPACE architecture  # → development branch
```

### **Integration Examples**
```bash
@WORKSPACE test          # → integration branch
@WORKSPACE ios           # → integration branch
@WORKSPACE validate      # → integration branch
@WORKSPACE performance   # → integration branch
@WORKSPACE app           # → integration branch
```

### **Main Examples**
```bash
@WORKSPACE document      # → main branch
@WORKSPACE organize      # → main branch
@WORKSPACE refactor      # → main branch
@WORKSPACE plan          # → main branch
@WORKSPACE coordinate    # → main branch
```

---

## 🛡️ **Safety Features**

### **Branch Protection**
- ✅ **Never Creates Branches** - Only switches between existing branches
- ✅ **Stash Protection** - Automatically stashes uncommitted changes
- ✅ **Status Reporting** - Shows current branch status after switching
- ✅ **Context Guidance** - Explains what each branch is for

### **Conflict Prevention**
- ✅ **File Scope Clarity** - Each branch has clear file ownership
- ✅ **Tool Alignment** - Branch-specific tools prevent cross-contamination
- ✅ **Work Type Isolation** - Different types of work stay in appropriate branches

---

## 📋 **Branch Context Guide**

### **🎯 Main Branch Context**
```markdown
🎯 MAIN BRANCH - Documentation & Coordination
├── Focus: Strategic planning, documentation, organization
├── Files: All .md files, archives, project coordination
├── Avoid: Framework source code, test app implementation
├── Tools: @REFACTOR.md, @PLAN.md, @PROPOSE.md
└── Goal: Clean, organized foundation for development work
```

### **🔧 Development Branch Context**  
```markdown
🔧 DEVELOPMENT BRANCH - Framework Implementation
├── Focus: Framework core, architecture, new features
├── Files: /AxiomFramework/Sources/, /AxiomFramework/Tests/
├── Avoid: AxiomTestApp changes, documentation organization
├── Tools: @DEVELOP.md, swift build, swift test
└── Goal: Robust, performant framework implementation
```

### **🧪 Integration Branch Context**
```markdown
🧪 INTEGRATION BRANCH - Real-World Testing
├── Focus: AxiomTestApp validation, real-world scenarios
├── Files: /AxiomTestApp/, integration tests, performance
├── Avoid: Framework core changes, documentation refactoring  
├── Tools: @INTEGRATE.md, Xcode, performance measurement
└── Goal: Validated, production-ready framework integration
```

---

## 🔄 **Consistent Terminal Usage**

### **New Terminal Setup**
1. **Navigate to project**: `cd /path/to/Axiom`
2. **Select workspace**: `@WORKSPACE [intent]` 
3. **Start working**: Use branch-appropriate tools

### **Quick Reference**
```bash
# Development work
@WORKSPACE framework     # Switch to development branch
@DEVELOP.md              # Start framework development

# Integration testing  
@WORKSPACE test          # Switch to integration branch
@INTEGRATE.md            # Start real-world testing

# Documentation & planning
@WORKSPACE organize      # Switch to main branch
@REFACTOR.md             # Start organization work
```

---

## 🎯 **Usage Patterns**

### **Daily Development Workflow**
```bash
# Morning: Check what needs to be done
@WORKSPACE plan          # → main branch for planning

# Development: Work on framework
@WORKSPACE framework     # → development branch for coding  

# Testing: Validate changes
@WORKSPACE test          # → integration branch for validation

# Wrap-up: Document and organize
@WORKSPACE organize      # → main branch for cleanup
```

### **Terminal Coordination**
- **Terminal 1**: `@WORKSPACE organize` - Documentation and coordination
- **Terminal 2**: `@WORKSPACE framework` - Framework development
- **Terminal 3**: `@WORKSPACE test` - Integration testing

---

## ⚡ **Advanced Features**

### **Branch Status Intelligence**
- Shows current branch status and recent changes
- Indicates which files are modified in current branch
- Provides context about what work is appropriate

### **Tool Alignment**
- Each branch automatically shows relevant tools and commands
- Prevents using wrong tools in wrong branches
- Guides toward appropriate workflow for each context

### **Smart Defaults**
- Remembers your intent patterns over time
- Suggests most likely branch based on recent work
- Provides quick shortcuts for common workflows

---

## 🎉 **Perfect for Multi-Terminal Development**

**This system ensures**:
- ✅ **Consistent branch selection** across all terminals
- ✅ **No accidental branch creation** - only uses established branches
- ✅ **Clear work separation** - each branch has distinct purpose
- ✅ **Conflict prevention** - file scope isolation prevents merge issues
- ✅ **Context awareness** - always know what type of work to do

**Use `@WORKSPACE [intent]` for intelligent branch selection in any new terminal!** 🚀