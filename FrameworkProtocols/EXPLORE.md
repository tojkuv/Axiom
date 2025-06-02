# @EXPLORE.md - Axiom Framework Exploration Command

Framework exploration command that analyzes, explains, and reasons about framework components

## Automated Mode Trigger

**When human sends**: `@EXPLORE [optional-args]`
**Action**: Enter ultrathink mode and execute framework exploration workflow

### Usage Modes
- **`@EXPLORE`** → Explore current framework context and provide comprehensive analysis
- **`@EXPLORE analyze`** → Deep analysis of specific framework components or architecture
- **`@EXPLORE explain`** → Explain framework concepts, patterns, and implementation details
- **`@EXPLORE reason`** → Reason about framework design decisions and architectural choices
- **`@EXPLORE validate`** → Explore and validate framework implementation against design constraints

### Framework Exploration Scope
**Exploration Focus**: Framework component analysis, architectural reasoning, implementation explanation
**Branch Independence**: Works on current branch - no git operations performed
**Analysis Creation**: Provides detailed framework analysis and explanations for user understanding
**Knowledge Integration**: Integrates with framework documentation and implementation patterns

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: EXPLORE commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: EXPLORE analyzes and explains → Understanding gained → Other workflows implement changes

Work commands operate on current branch without version control:
1. **Analysis**: Read framework components and architectural implementation
2. **Exploration**: Deep dive into framework patterns and design decisions
3. **Explanation**: Provide comprehensive explanations of framework behavior
4. **Reasoning**: Analyze architectural choices and constraint compliance
**No Git Operations**: EXPLORE commands never commit, push, or merge

## Framework Exploration Philosophy

**Core Principle**: Framework exploration provides deep analysis and understanding of framework components, architectural patterns, and implementation details to support informed development decisions and knowledge transfer.

**Exploration Workflow**: @EXPLORE analyzes framework components → Provides detailed explanations → Supports informed development decisions → Knowledge documented for team understanding

### 🎯 **Clear Separation of Concerns**
- **EXPLORE**: Analyzes and explains framework components → NO implementation changes
- **PLAN**: Creates proposals based on exploration insights → NO direct analysis
- **DEVELOP**: Implements based on understanding → NO exploratory analysis
- **CHECKPOINT**: Git workflow → NO exploration or analysis
- **TRACKING**: Progress tracking → NO component analysis

**Quality Standards**: Framework exploration provides comprehensive technical analysis, architectural reasoning, and implementation explanations

**Technical Focus Only**: Exploration strictly focuses on technical analysis and understanding. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Framework Exploration Methodology

### Phase 1: Framework Component Analysis
1. **Component Identification** → Identify specific framework components and their relationships
2. **Architecture Assessment** → Analyze framework architectural patterns and constraint compliance
3. **Implementation Review** → Examine framework implementation details and design patterns
4. **Dependency Analysis** → Understand component dependencies and integration points
5. **Pattern Recognition** → Identify recurring patterns and architectural decisions
6. **Constraint Validation** → Validate adherence to 8 architectural constraints

### Phase 2: Framework Deep Analysis
1. **Technical Specification Review** → Analyze framework technical specifications and design documents
2. **Code Pattern Analysis** → Examine code patterns, conventions, and implementation approaches
3. **Integration Assessment** → Understand framework integration points and external dependencies
4. **Performance Analysis** → Analyze performance characteristics and optimization strategies
5. **Intelligence System Analysis** → Examine AI integration and intelligent system components

### Phase 3: Framework Explanation and Reasoning
1. **Concept Explanation** → Provide clear explanations of framework concepts and patterns
2. **Design Reasoning** → Explain architectural decisions and design trade-offs
3. **Implementation Details** → Detail implementation approaches and technical choices
4. **Usage Patterns** → Explain proper framework usage and integration patterns
5. **Knowledge Documentation** → Document analysis findings for team understanding

## Framework Exploration Categories

### Framework Architecture Exploration
**Focus**: Core framework architecture, 8 architectural constraints, design patterns
**Components**: 
- AxiomClient → Actor-based state management analysis
- AxiomContext → Client orchestration pattern exploration
- AxiomView → SwiftUI integration pattern analysis
- Capability System → Runtime validation architecture exploration
**Analysis**: Component relationships, constraint compliance, pattern consistency

### Intelligence System Exploration
**Focus**: AI integration, intelligent system components, analysis capabilities
**Components**:
- Component Introspection → Architectural analysis capabilities
- Pattern Detection → Code pattern recognition systems
- Query Engine → Natural language query processing
- Performance Monitor → Analysis-driven optimization systems
**Analysis**: AI integration patterns, intelligence system architecture, analysis capabilities

### Implementation Pattern Exploration
**Focus**: Code patterns, conventions, implementation approaches
**Components**:
- Macro System → Code generation patterns and conventions
- Type System → Type safety and constraint validation
- Error Handling → Error management and recovery patterns
- Testing Infrastructure → Testing patterns and validation approaches
**Analysis**: Implementation consistency, pattern adherence, quality standards

## Framework Exploration Command Execution

**Command**: `@EXPLORE [analyze|explain|reason|validate]`
**Action**: Execute comprehensive framework exploration workflow with detailed analysis

### 🔄 **Exploration Execution Process**

**CRITICAL**: EXPLORE commands work on current branch state - NO git operations

```bash
# Navigate to framework workspace
echo "🔄 Entering framework development workspace..."
cd framework-workspace/ || {
    echo "❌ Framework workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Exploration workflow (NO git operations)
echo "🔍 Framework Exploration Execution"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "🔍 Exploration ready - proceeding in framework workspace"
```

**Automated Exploration Process**:
1. **Framework Context Analysis** → Analyze current framework implementation and component state
2. **Component Deep Dive** → Examine specific framework components and their implementation
3. **Architecture Analysis** → Analyze framework architecture and constraint compliance
4. **Pattern Assessment** → Identify and analyze implementation patterns and conventions
5. **Design Reasoning** → Analyze architectural decisions and design trade-offs
6. **Implementation Explanation** → Provide detailed explanations of framework behavior
7. **Knowledge Synthesis** → Synthesize analysis findings into comprehensive understanding
**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Framework Exploration Execution Examples**:
- `@EXPLORE` → Comprehensive framework analysis and explanation
- `@EXPLORE analyze` → Deep analysis of specific framework components
- `@EXPLORE explain` → Explain framework concepts and implementation details
- `@EXPLORE reason` → Reason about architectural decisions and design choices
- `@EXPLORE validate` → Validate framework implementation against constraints

## Framework Exploration Output Standards

### Framework Analysis Structure
- **Component Overview**: Clear identification of framework components and relationships
- **Architecture Analysis**: Detailed analysis of architectural patterns and constraints
- **Implementation Details**: Comprehensive explanation of implementation approaches
- **Design Reasoning**: Clear reasoning behind architectural decisions and trade-offs
- **Pattern Identification**: Recognition of recurring patterns and conventions
- **Integration Analysis**: Understanding of component integration and dependencies

### Framework Quality Standards
- **Technical Accuracy**: All analysis accurately reflects framework implementation
- **Comprehensive Coverage**: Complete analysis of relevant framework components
- **Clear Explanations**: Understandable explanations of complex technical concepts
- **Reasoning Clarity**: Clear reasoning about architectural decisions and design choices
- **Pattern Recognition**: Identification of implementation patterns and conventions
- **Constraint Validation**: Verification of adherence to architectural constraints

## Framework Exploration Workflow Integration

**Exploration Purpose**: Provide deep analysis and understanding of framework components for informed development
**Development Support**: Exploration insights support PLAN proposal creation and DEVELOP implementation decisions
**Knowledge Transfer**: Exploration provides framework understanding for team knowledge sharing
**Documentation Integration**: Exploration findings complement technical documentation and specifications
**Decision Support**: Analysis supports informed architectural and implementation decisions

## Framework Exploration Coordination

**Analysis Focus**: Framework component analysis and architectural understanding on framework branch
**Knowledge Creation**: Generate comprehensive understanding of framework implementation and patterns
**Development Integration**: Exploration insights support planning and development workflows
**Documentation Complement**: Analysis complements existing technical documentation and specifications
**Decision Support**: Provide informed analysis for architectural and implementation decisions

---

**FRAMEWORK EXPLORATION COMMAND STATUS**: Framework exploration command with analysis, explanation, and reasoning capabilities
**CORE FOCUS**: Deep framework component analysis and architectural understanding  
**EXPLORATION SCOPE**: Comprehensive framework analysis, pattern recognition, and implementation explanation
**KNOWLEDGE INTEGRATION**: Framework understanding and analysis for informed development decisions
**WORKFLOW INTEGRATION**: Analysis integration with planning, development, and documentation workflows

**Use FrameworkProtocols/@EXPLORE for comprehensive framework analysis, explanation, and architectural reasoning.**