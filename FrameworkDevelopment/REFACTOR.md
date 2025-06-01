# @REFACTOR.md - Axiom Framework Refactoring Command

Framework refactoring command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@REFACTOR [optional-args]`
**Action**: Enter ultrathink mode and execute framework refactoring workflow

### Usage Modes
- **`@REFACTOR`** → Auto-detect current context and execute framework refactoring workflow
- **`@REFACTOR plan`** → Plan framework refactoring tasks and priorities
- **`@REFACTOR organize`** → Execute framework organization and cleanup cycle
- **`@REFACTOR cleanup`** → Remove framework technical debt and improve code quality
- **`@REFACTOR optimize`** → Framework performance optimization and structural improvements

### Framework Refactoring Scope
**Refactoring Focus**: Framework code organization, structural improvements, and technical debt elimination
**Quality Standards**: Structural integrity with zero functionality changes
**Integration**: Integration with @PLAN, @CHECKPOINT, and framework development workflows

### 🔄 **Standardized Git Workflow**
All FrameworkDevelopment commands follow this workflow:
1. **Branch Setup**: Switch to `framework` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `framework` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `framework` branch with descriptive messages
5. **Integration**: Merge `framework` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `framework` branch and create fresh one for next cycle

## Framework Refactoring Philosophy

**Core Principle**: Framework refactoring improves framework code structure, organization, and maintainability without changing functionality, creating a clean foundation that accelerates framework development and prevents technical debt accumulation.

**Quality Standards**: Framework refactoring operations preserve existing functionality while improving framework code organization, reducing complexity, and enhancing maintainability.

**Integrity Requirements**: Framework refactoring maintains functionality preservation with zero behavioral changes. See `AxiomFramework/Documentation/Refactoring/REFACTORING_STRATEGY.md` for refactoring requirements and standards.

**Structural Excellence**: Framework refactoring focuses on creating optimal framework code organization that supports long-term development velocity and architectural evolution.

## 🏗️ Refactoring Principles

### **Structural Integrity**
- **Functionality Preservation**: Zero behavioral changes during refactoring operations
- **Architecture Consistency**: Maintain adherence to established architectural patterns
- **Interface Stability**: Preserve public APIs and interface contracts
- **Performance Neutrality**: Ensure refactoring does not degrade performance
- **Thread Safety**: Maintain existing concurrency and thread safety characteristics

### **Organization Excellence**
- **Code Structure**: Improve file organization, module structure, and directory hierarchy
- **Naming Consistency**: Standardize naming conventions and improve clarity
- **Dependency Management**: Optimize imports, dependencies, and module relationships
- **Documentation Alignment**: Ensure code organization matches documentation structure
- **Pattern Consistency**: Apply consistent patterns and architectural approaches

### **Technical Debt Elimination**
- **Code Duplication**: Identify and eliminate redundant code through proper abstraction
- **Complexity Reduction**: Simplify complex structures while maintaining functionality
- **Unused Code Removal**: Remove dead code, unused imports, and obsolete components
- **Standard Compliance**: Ensure code follows established standards and conventions
- **Quality Metrics**: Improve maintainability, readability, and cognitive complexity

### **Refactoring Standards**
**Requirements**: 100% functionality preservation, comprehensive testing validation, structural improvement measurement
**Standards**: See `Documentation/Refactoring/REFACTORING_STRATEGY.md` for detailed refactoring methodology and requirements

## 🔧 Refactoring Methodology

### **Phase 1: Analysis and Planning**
1. **Current State Assessment** → Analyze existing code structure and identify improvement opportunities
2. **Refactoring Planning** → Design structural improvements that align with architectural goals
3. **Risk Analysis** → Identify potential risks and develop mitigation strategies
4. **Success Metrics** → Define measurable criteria for refactoring success
5. **Execution Planning** → Plan refactoring sequence and dependencies

### **Phase 2: Structure and Organization**
1. **File Organization** → Improve file structure, directory hierarchy, and module organization
2. **Naming Standardization** → Apply consistent naming conventions across the codebase
3. **Import Optimization** → Optimize dependencies, imports, and module relationships
4. **Code Grouping** → Organize related functionality into cohesive modules
5. **Interface Alignment** → Ensure interfaces match architectural intentions

### **Phase 3: Quality and Cleanup**
**Critical Requirement**: Comprehensive cleanup with 100% functionality preservation
**Cleanup Strategy**: Dead code removal, duplication elimination, complexity reduction, standard compliance
**Standards**: Detailed refactoring requirements in `Documentation/Refactoring/REFACTORING_STRATEGY.md`
**Blocking Rule**: Any functionality change blocks refactoring progress until corrected

### **Phase 4: Validation and Documentation**
1. **Functionality Verification** → Validate that all existing functionality remains intact
2. **Performance Validation** → Ensure refactoring maintains or improves performance
3. **Documentation Updates** → Update documentation to reflect structural changes
4. **Integration Testing** → Verify refactored code integrates properly with existing systems
5. **Quality Review** → Final review to ensure refactoring meets excellence standards

## 📊 Refactoring Categories

### **Code Structure Refactoring**
- **File Organization** → Optimal file structure and directory hierarchy
- **Module Structure** → Clear module boundaries and responsibilities
- **Import Management** → Clean dependency structure and import optimization
- **Code Grouping** → Logical organization of related functionality
- **Interface Design** → Clean and consistent interface structures

### **Quality Enhancement Refactoring**
- **Complexity Reduction** → Simplify complex structures while preserving functionality
- **Duplication Elimination** → Remove redundant code through proper abstraction
- **Naming Improvement** → Enhance clarity through better naming conventions
- **Standard Compliance** → Ensure adherence to coding standards and conventions
- **Documentation Alignment** → Align code structure with documentation organization

### **Technical Debt Elimination**
- **Dead Code Removal** → Remove unused code, imports, and obsolete components
- **Performance Optimization** → Structural improvements that enhance performance
- **Memory Management** → Optimize memory usage patterns and lifecycle management
- **Concurrency Cleanup** → Improve thread safety and async patterns
- **Error Handling** → Enhance error management and recovery patterns

## 🧪 Validation Integration

**Validation Framework**: Comprehensive functionality preservation validation and structural improvement measurement
**Validation Categories**: Functionality verification, performance validation, integration testing, quality measurement
**Validation Standards**: Detailed validation specifications available in `Documentation/Refactoring/REFACTORING_STRATEGY.md`
**Integration**: Validation requirements seamlessly integrated into refactoring workflow

## 🚫 Integrity Requirements

**Zero Tolerance**: 100% functionality preservation required - any behavioral change blocks all refactoring work
**No Exceptions**: No bypassing, skipping, or temporary workarounds for functionality changes
**Resolution Process**: Immediate stop → identify change → correct issue → verify preservation → continue
**Standards**: Complete integrity requirements in `Documentation/Refactoring/REFACTORING_STRATEGY.md`

## 🎯 Refactoring Success Criteria

**Structural Excellence**: Improved code organization, reduced complexity, enhanced maintainability, optimal file structure
**Quality Enhancement**: Eliminated technical debt, consistent patterns, standard compliance, documentation alignment
**Performance Neutrality**: Maintained or improved performance, optimal memory usage, efficient structure
**Functionality Preservation**: 100% behavioral preservation, complete interface stability, zero regression
**Standards**: Complete success criteria in `Documentation/Refactoring/REFACTORING_STANDARDS.md`

## 🤖 Refactoring Execution Loop

**Command**: `@REFACTOR [plan|organize|cleanup|optimize]`
**Action**: Execute comprehensive refactoring workflow with methodology enforcement

### 🔄 **Branch Verification and Setup**

**Before executing any refactoring work, execute this branch verification:**

```bash
# 1. Check current branch and switch to framework branch if needed
CURRENT_BRANCH=$(git branch --show-current)
echo "🎯 Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "framework" ]; then
    echo "🔄 Switching from $CURRENT_BRANCH to framework branch..."
    
    # Check if framework branch exists
    if git show-ref --verify --quiet refs/heads/framework; then
        echo "📍 Framework branch exists locally, switching..."
        git checkout framework
    elif git show-ref --verify --quiet refs/remotes/origin/framework; then
        echo "📍 Framework branch exists remotely, checking out..."
        git checkout -b framework origin/framework
    else
        echo "🌱 Creating new framework branch..."
        git checkout -b framework
        git push origin framework -u
    fi
    
    echo "✅ Now on framework branch"
else
    echo "✅ Already on framework branch"
fi

# 2. Update framework branch with latest changes
echo "🔄 Updating framework branch..."
git fetch origin framework 2>/dev/null || true
git pull origin framework 2>/dev/null || echo "📍 No remote updates available"

echo "🎯 Branch verification complete - ready for framework refactoring"
```

**Automated Execution Process**:
1. **Branch Verification** → Switch to `framework` branch and update with latest changes
2. **Environment Validation** → Verify clean working tree, backup current state, validate dependencies
3. **Planning Integration** → Reference current refactoring priorities and @PLAN outputs
4. **Methodology Enforcement** → Apply refactoring principles and structural integrity requirements
5. **Organization and Cleanup Cycle** → Execute structural improvements, cleanup, and optimization
6. **Quality Validation** → Ensure 100% functionality preservation, structural improvement verification
7. **Documentation Updates** → Update structure documentation and refactoring reports
8. **TRACKING.md Quality Update** → Update structural improvements in FrameworkDevelopment/TRACKING.md
9. **Coordination Updates** → Provide refactoring results and structural improvement assessment

**Refactoring Execution Examples**:
- `@REFACTOR plan` → Plan refactoring priorities and structural improvement strategy
- `@REFACTOR organize` → Execute comprehensive organization and structure improvements
- `@REFACTOR cleanup` → Remove technical debt and improve code quality
- `@REFACTOR optimize` → Performance optimization and structural enhancement

## 🔄 Refactoring Workflow Integration

**Planning**: Integrates with @PLAN for refactoring task planning and priority coordination
**Execution**: Complete analysis → organization → cleanup → validation → documentation cycle
**Critical Rule**: Any functionality change immediately blocks all refactoring work until corrected
**Documentation**: Work details tracked in `/Documentation/Refactoring/` only
**ROADMAP Updates**: ROADMAP.md updates handled by @CHECKPOINT.md when merging to main
**Coordination**: Seamless integration with @CHECKPOINT for refactoring cycle completion

## 📚 Refactoring Resources

**Framework Structure**: 8 architectural constraints, established patterns, performance requirements, quality standards
**Refactoring Infrastructure**: Validation tools, quality measurement, structural analysis, improvement tracking
**Resources**: Complete refactoring resources in `Documentation/Refactoring/`

## 🤖 Refactoring Coordination

**Branch Focus**: Intelligent branch-aware refactoring with context-specific optimization
**Work Storage**: Framework refactoring work tracked in `/AxiomFramework/Documentation/Refactoring/` only
**TRACKING Updates**: NO - TRACKING.md updates handled by @CHECKPOINT.md when merging to main
**Planning Integration**: @PLAN command provides contextual framework refactoring planning
**Coordination**: Framework refactoring operation with cross-branch progress sharing

---

**FRAMEWORK REFACTORING COMMAND STATUS**: Framework refactoring command with methodology, requirements, and execution procedures
**CORE FOCUS**: Framework refactoring with automated workflow implementation  
**AUTOMATION**: Supports `@REFACTOR [plan|organize|cleanup|optimize]` with execution procedures  
**INTEGRITY REQUIREMENTS**: Functionality preservation with zero behavioral changes required  
**INTEGRATION**: Workflow integration with @PLAN, @CHECKPOINT, and framework refactoring coordination

**Use @REFACTOR for framework structural improvement with automated methodology implementation and execution.**