# @REFACTOR.md - Axiom Application Refactoring Command

Application refactoring command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@REFACTOR [optional-args]`
**Action**: Enter ultrathink mode and execute application refactoring workflow

### Usage Modes
- **`@REFACTOR`** → Auto-detect current context and execute application refactoring workflow
- **`@REFACTOR plan`** → Plan application refactoring tasks and priorities
- **`@REFACTOR organize`** → Execute application organization and cleanup cycle
- **`@REFACTOR cleanup`** → Remove application technical debt and improve code quality
- **`@REFACTOR optimize`** → Application performance optimization and structural improvements

### Application Refactoring Scope
**Refactoring Focus**: Application code organization, structural improvements, and technical debt elimination
**Quality Standards**: Structural integrity with zero functionality changes
**Integration**: Integration with @PLAN, @CHECKPOINT, and application development workflows

### 🔄 **Refactoring Workflow Architecture**
**IMPORTANT**: REFACTOR commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: REFACTOR improves structure → Multiple REFACTOR cycles → @CHECKPOINT commits and merges

Refactoring workflow (NO git operations):
1. **Analysis**: Analyze existing application structure and identify improvement opportunities
2. **Refactoring**: Execute structural improvements and organization
3. **Validation**: Ensure 100% functionality preservation
4. **Documentation**: Update application structure documentation and refactoring reports
5. **TRACKING.md Quality Update**: Update structural improvements tracking
**No Git Operations**: REFACTOR commands never commit, push, or merge

## Application Refactoring Philosophy

**Core Principle**: Application refactoring improves application code structure, organization, and maintainability without changing functionality, creating a clean foundation that accelerates application development and prevents technical debt accumulation.

**Quality Standards**: Application refactoring operations preserve existing functionality while improving application code organization, reducing complexity, and enhancing maintainability.

**Integrity Requirements**: Application refactoring maintains functionality preservation with zero behavioral changes. See `AxiomTestApp/Documentation/Refactoring/REFACTORING_STRATEGY.md` for refactoring requirements and standards.

**Structural Excellence**: Application refactoring focuses on creating optimal application code organization that supports long-term development velocity and user experience evolution.

## Application Refactoring Principles

### Structural Integrity
- **Functionality Preservation**: Zero behavioral changes during application refactoring operations
- **Framework Integration**: Maintain adherence to framework integration patterns
- **User Experience Stability**: Preserve user interface behavior and interaction patterns
- **Performance Neutrality**: Ensure application refactoring does not degrade performance
- **Framework Pattern Consistency**: Maintain existing framework usage patterns and safety characteristics

### Organization Excellence
- **Application Structure**: Improve file organization, feature structure, and directory hierarchy
- **Component Organization**: Standardize component naming and improve clarity
- **Framework Integration**: Optimize framework usage patterns and integration relationships
- **User Interface Organization**: Ensure UI organization matches user experience structure
- **Pattern Consistency**: Apply consistent application patterns and framework integration approaches

### Technical Debt Elimination
- **Code Duplication**: Identify and eliminate redundant application code through proper abstraction
- **Complexity Reduction**: Simplify complex application structures while maintaining functionality
- **Unused Code Removal**: Remove dead code, unused components, and obsolete application features
- **Standard Compliance**: Ensure application code follows established standards and conventions
- **User Experience Metrics**: Improve maintainability, readability, and application complexity

### Application Refactoring Standards
**Requirements**: Functionality preservation, comprehensive testing validation, structural improvement measurement
**Standards**: See `AxiomTestApp/Documentation/Refactoring/REFACTORING_STRATEGY.md` for detailed refactoring methodology and requirements

## Application Refactoring Methodology

### Phase 1: Analysis and Planning
1. **Current State Assessment** → Analyze existing application structure and identify improvement opportunities
2. **Refactoring Planning** → Design application structural improvements that align with framework integration goals
3. **Risk Analysis** → Identify potential risks and develop mitigation strategies
4. **Success Metrics** → Define measurable criteria for application refactoring success
5. **Execution Planning** → Plan application refactoring sequence and dependencies

### Phase 2: Structure and Organization
1. **Application Organization** → Improve application file structure, directory hierarchy, and feature organization
2. **Component Standardization** → Apply consistent naming conventions across application components
3. **Framework Integration Optimization** → Optimize framework usage patterns and integration relationships
4. **Feature Grouping** → Organize related application functionality into cohesive modules
5. **User Interface Alignment** → Ensure interfaces match application architectural intentions

### Phase 3: Quality and Cleanup
**Requirements**: Comprehensive cleanup with functionality preservation
**Cleanup Strategy**: Dead code removal, duplication elimination, complexity reduction, standard compliance
**Standards**: Detailed refactoring requirements in `AxiomTestApp/Documentation/Refactoring/REFACTORING_STRATEGY.md`
**Development Rule**: Any functionality change blocks refactoring progress until corrected

### Phase 4: Validation and Documentation
1. **Functionality Verification** → Validate that all existing application functionality remains intact
2. **Performance Validation** → Ensure application refactoring maintains or improves performance
3. **Documentation Updates** → Update application documentation to reflect structural changes
4. **Integration Testing** → Verify refactored application integrates properly with framework
5. **Quality Review** → Final review to ensure application refactoring meets standards

## Application Refactoring Categories

### Application Structure Refactoring
- **Feature Organization** → Optimal application feature structure and directory hierarchy
- **Component Structure** → Clear component boundaries and responsibilities
- **Framework Integration** → Clean framework usage patterns and integration optimization
- **User Interface Grouping** → Logical organization of related UI functionality
- **Navigation Structure** → Clean and consistent navigation structures

### Quality Enhancement Refactoring
- **Complexity Reduction** → Simplify complex application structures while preserving functionality
- **Duplication Elimination** → Remove redundant application code through proper abstraction
- **Component Naming** → Enhance clarity through better naming conventions
- **Standard Compliance** → Ensure adherence to application coding standards and conventions
- **Documentation Alignment** → Align application structure with documentation organization

### Technical Debt Elimination
- **Dead Code Removal** → Remove unused application code, components, and obsolete features
- **Performance Optimization** → Structural improvements that enhance application performance
- **User Experience Optimization** → Optimize user interface patterns and interaction management
- **Framework Pattern Cleanup** → Improve framework integration patterns and usage
- **Error Handling** → Enhance application error management and recovery patterns

## Validation Integration

**Validation Framework**: Comprehensive functionality preservation validation and structural improvement measurement
**Validation Categories**: Functionality verification, performance validation, integration testing, quality measurement
**Validation Standards**: Detailed validation specifications available in `AxiomTestApp/Documentation/Refactoring/REFACTORING_STRATEGY.md`
**Integration**: Validation requirements integrated into application refactoring workflow

## Integrity Requirements

**Testing Standards**: Functionality preservation required for application development progress
**Development Process**: Functionality changes require resolution before continuing refactoring
**Resolution Process**: Stop → identify change → correct issue → verify preservation → continue
**Standards**: Integrity requirements in `AxiomTestApp/Documentation/Refactoring/REFACTORING_STRATEGY.md`

## Application Refactoring Success Criteria

**Structural Excellence**: Improved application organization, reduced complexity, enhanced maintainability, optimal feature structure
**Quality Enhancement**: Eliminated technical debt, consistent patterns, standard compliance, documentation alignment
**Performance Neutrality**: Maintained or improved performance, optimal user experience, efficient structure
**Functionality Preservation**: Behavioral preservation, interface stability, zero regression
**Standards**: Success criteria in `AxiomTestApp/Documentation/Refactoring/REFACTORING_STANDARDS.md`

## Application Refactoring Execution Loop

**Command**: `@REFACTOR [plan|organize|cleanup|optimize]`
**Action**: Execute comprehensive application refactoring workflow with methodology enforcement

### 🔄 **Refactoring Execution Process**

**CRITICAL**: REFACTOR commands work on current branch state - NO git operations

```bash
# Branch switching - Switch to application branch before starting work
echo "🔄 Switching to application branch..."
ORIGINAL_BRANCH=$(git branch --show-current)
if [ "$ORIGINAL_BRANCH" != "application" ]; then
    if git show-ref --verify --quiet refs/heads/application; then
        git checkout application
    else
        git checkout -b application
    fi
    echo "✅ Switched to application branch"
else
    echo "✅ Already on application branch"
fi

# Refactoring workflow (NO git operations)
echo "🎯 Application Refactoring Execution"
echo "📍 Working on current branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "🎯 Refactoring ready - proceeding on application branch"
```

**Automated Execution Process**:
1. **Planning Integration** → Reference current application refactoring priorities and @PLAN outputs
2. **Methodology Enforcement** → Apply application refactoring principles and structural integrity requirements
3. **Organization and Cleanup Cycle** → Execute application structural improvements, cleanup, and optimization
4. **Quality Validation** → Ensure functionality preservation, structural improvement verification
5. **Documentation Updates** → Update application structure documentation and refactoring reports
6. **TRACKING.md Quality Update** → Update structural improvements in ApplicationProtocols/TRACKING.md
7. **Coordination Updates** → Provide application refactoring results and structural improvement assessment
8. **Branch Cleanup** → Switch back to main branch after completing all tasks
**No Git Operations**: All version control handled by @CHECKPOINT commands only

```bash
# Switch back to main branch after completing all tasks
echo "🔄 Switching back to main branch..."
git checkout main
echo "✅ Returned to main branch"
```

**Application Refactoring Execution Examples**:
- `@REFACTOR plan` → Plan application refactoring priorities and structural improvement strategy
- `@REFACTOR organize` → Execute comprehensive application organization and structure improvements
- `@REFACTOR cleanup` → Remove application technical debt and improve code quality
- `@REFACTOR optimize` → Application performance optimization and structural enhancement

## Application Refactoring Workflow Integration

**Planning**: Integrates with @PLAN for application refactoring task planning and priority coordination
**Execution**: Complete analysis → organization → cleanup → validation → documentation cycle
**Development Rule**: Functionality changes require resolution before application refactoring progress
**Documentation**: Work details tracked in `/AxiomTestApp/Documentation/Refactoring/` only
**TRACKING Updates**: NO - TRACKING.md updates handled by @CHECKPOINT.md when merging to main
**Coordination**: Integration with @CHECKPOINT for application refactoring cycle completion

## Application Refactoring Resources

**Application Structure**: Framework integration patterns, user experience guidelines, performance requirements, quality standards
**Refactoring Infrastructure**: Validation tools, quality measurement, structural analysis, improvement tracking
**Resources**: Complete application refactoring resources in `AxiomTestApp/Documentation/Refactoring/`

## Application Refactoring Coordination

**Branch Focus**: Application-aware refactoring with framework integration optimization
**Work Storage**: Application refactoring work tracked in `/AxiomTestApp/Documentation/Refactoring/` only
**TRACKING Updates**: NO - TRACKING.md updates handled by @CHECKPOINT.md when merging to main
**Planning Integration**: @PLAN command provides contextual application refactoring planning
**Coordination**: Application refactoring operation with cross-branch progress sharing

---

**APPLICATION REFACTORING COMMAND STATUS**: Application refactoring command with methodology, requirements, and execution procedures
**CORE FOCUS**: Application refactoring with automated workflow implementation  
**AUTOMATION**: Supports `@REFACTOR [plan|organize|cleanup|optimize]` with execution procedures  
**INTEGRITY REQUIREMENTS**: Functionality preservation with zero behavioral changes required  
**INTEGRATION**: Workflow integration with @PLAN, @CHECKPOINT, and application refactoring coordination

**Use @REFACTOR for application structural improvement with automated methodology implementation and execution.**