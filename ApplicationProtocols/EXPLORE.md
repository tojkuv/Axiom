# @EXPLORE.md - Axiom Application Exploration Command

Application exploration command that analyzes, explains, and reasons about application components

## Automated Mode Trigger

**When human sends**: `@EXPLORE [optional-args]`
**Action**: Enter ultrathink mode and execute application exploration workflow

### Usage Modes
- **`@EXPLORE`** → Explore current application context and provide comprehensive analysis
- **`@EXPLORE analyze`** → Deep analysis of specific application components or integration patterns
- **`@EXPLORE explain`** → Explain application features, user experience, and framework integration
- **`@EXPLORE reason`** → Reason about application design decisions and user experience choices
- **`@EXPLORE validate`** → Explore and validate application framework integration and functionality

### Application Exploration Scope
**Exploration Focus**: Application component analysis, framework integration reasoning, user experience explanation
**Branch Independence**: Works on current branch - no git operations performed
**Analysis Creation**: Provides detailed application analysis and explanations for user understanding
**Integration Focus**: Analyzes framework integration patterns and application architecture

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: EXPLORE commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: EXPLORE analyzes and explains → Understanding gained → Other workflows implement changes

Work commands operate on current branch without version control:
1. **Analysis**: Read application components and framework integration implementation
2. **Exploration**: Deep dive into application patterns and integration decisions
3. **Explanation**: Provide comprehensive explanations of application behavior
4. **Reasoning**: Analyze integration choices and user experience decisions
**No Git Operations**: EXPLORE commands never commit, push, or merge

## Application Exploration Philosophy

**Core Principle**: Application exploration provides deep analysis and understanding of application components, framework integration patterns, and user experience implementation to support informed development decisions and knowledge transfer.

**Exploration Workflow**: @EXPLORE analyzes application components → Provides detailed explanations → Supports informed development decisions → Knowledge documented for team understanding

### 🎯 **Clear Separation of Concerns**
- **EXPLORE**: Analyzes and explains application components → NO implementation changes
- **PLAN**: Creates proposals based on exploration insights → NO direct analysis
- **DEVELOP**: Implements based on understanding → NO exploratory analysis
- **CHECKPOINT**: Git workflow → NO exploration or analysis
- **TRACKING**: Progress tracking → NO component analysis

**Quality Standards**: Application exploration provides comprehensive technical analysis, integration reasoning, and implementation explanations

**Technical Focus Only**: Exploration strictly focuses on technical analysis and understanding. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Application Exploration Methodology

### Phase 1: Application Component Analysis
1. **Component Identification** → Identify specific application components and their framework integration
2. **Integration Assessment** → Analyze application framework integration patterns and implementation
3. **User Experience Review** → Examine application user interface and interaction patterns
4. **Feature Analysis** → Understand application features and their technical implementation
5. **Pattern Recognition** → Identify recurring application patterns and integration approaches
6. **Framework Usage Validation** → Validate proper framework usage and integration patterns

### Phase 2: Application Deep Analysis
1. **Technical Implementation Review** → Analyze application technical implementation and architecture
2. **Integration Pattern Analysis** → Examine framework integration patterns and usage approaches
3. **User Interface Assessment** → Understand SwiftUI integration and user experience implementation
4. **Performance Analysis** → Analyze application performance characteristics and optimization
5. **Testing Integration Analysis** → Examine application testing patterns and validation approaches

### Phase 3: Application Explanation and Reasoning
1. **Feature Explanation** → Provide clear explanations of application features and functionality
2. **Integration Reasoning** → Explain framework integration decisions and implementation choices
3. **User Experience Details** → Detail user interface implementation and interaction patterns
4. **Usage Patterns** → Explain application usage patterns and best practices
5. **Knowledge Documentation** → Document analysis findings for team understanding

## Application Exploration Categories

### Application Architecture Exploration
**Focus**: Application architecture, framework integration, component organization
**Components**: 
- AxiomExampleApp → Main application structure and organization
- Domains → Domain-specific application components and models
- Views → SwiftUI view implementation and framework integration
- Contexts → Application context usage and framework integration patterns
**Analysis**: Application structure, framework integration patterns, component relationships

### Framework Integration Exploration
**Focus**: Framework usage patterns, integration approaches, best practices
**Components**:
- Client Integration → AxiomClient usage patterns and implementation
- Context Usage → AxiomContext integration and state management
- View Binding → AxiomView integration and SwiftUI patterns
- Capability Usage → Framework capability integration and validation
**Analysis**: Integration patterns, framework usage, best practice compliance

### User Experience Exploration
**Focus**: User interface implementation, interaction patterns, experience design
**Components**:
- ContentView → Main application interface and navigation
- Feature Views → Specific feature implementation and user interaction
- Validation Views → Framework integration demonstration and testing
- Supporting Views → Utility views and user experience components
**Analysis**: User experience implementation, interface patterns, interaction design

## Application Exploration Command Execution

**Command**: `@EXPLORE [analyze|explain|reason|validate]`
**Action**: Execute comprehensive application exploration workflow with detailed analysis

### 🔄 **Exploration Execution Process**

**CRITICAL**: EXPLORE commands work on current branch state - NO git operations

```bash
# Navigate to application workspace
echo "🔄 Entering application development workspace..."
cd application-workspace/ || {
    echo "❌ Application workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Exploration workflow (NO git operations)
echo "🔍 Application Exploration Execution"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "🔗 Framework access: AxiomFramework-dev → ../framework-workspace/AxiomFramework"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "🔍 Exploration ready - proceeding in application workspace"
```

**Automated Exploration Process**:
1. **Application Context Analysis** → Analyze current application implementation and component state
2. **Component Deep Dive** → Examine specific application components and their framework integration
3. **Integration Analysis** → Analyze framework integration patterns and usage approaches
4. **User Experience Assessment** → Analyze user interface implementation and interaction patterns
5. **Feature Reasoning** → Analyze application features and implementation decisions
6. **Implementation Explanation** → Provide detailed explanations of application behavior
7. **Knowledge Synthesis** → Synthesize analysis findings into comprehensive understanding
**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Application Exploration Execution Examples**:
- `@EXPLORE` → Comprehensive application analysis and explanation
- `@EXPLORE analyze` → Deep analysis of specific application components
- `@EXPLORE explain` → Explain application features and framework integration
- `@EXPLORE reason` → Reason about integration decisions and user experience choices
- `@EXPLORE validate` → Validate application framework integration and functionality

## Application Exploration Output Standards

### Application Analysis Structure
- **Component Overview**: Clear identification of application components and framework integration
- **Integration Analysis**: Detailed analysis of framework integration patterns and usage
- **Feature Implementation**: Comprehensive explanation of application features and functionality
- **User Experience Reasoning**: Clear reasoning behind user interface and interaction decisions
- **Pattern Identification**: Recognition of recurring application and integration patterns
- **Framework Usage Analysis**: Understanding of framework usage patterns and best practices

### Application Quality Standards
- **Technical Accuracy**: All analysis accurately reflects application implementation
- **Comprehensive Coverage**: Complete analysis of relevant application components
- **Clear Explanations**: Understandable explanations of complex integration concepts
- **Reasoning Clarity**: Clear reasoning about integration decisions and user experience choices
- **Pattern Recognition**: Identification of application patterns and framework usage approaches
- **Integration Validation**: Verification of proper framework usage and integration patterns

## Application Exploration Workflow Integration

**Exploration Purpose**: Provide deep analysis and understanding of application components for informed development
**Development Support**: Exploration insights support PLAN proposal creation and DEVELOP implementation decisions
**Knowledge Transfer**: Exploration provides application understanding for team knowledge sharing
**Documentation Integration**: Exploration findings complement integration documentation and guides
**Decision Support**: Analysis supports informed application and integration decisions

## Application Exploration Coordination

**Analysis Focus**: Application component analysis and framework integration understanding on application branch
**Knowledge Creation**: Generate comprehensive understanding of application implementation and patterns
**Development Integration**: Exploration insights support planning and development workflows
**Documentation Complement**: Analysis complements existing integration documentation and guides
**Decision Support**: Provide informed analysis for application and integration decisions

---

**APPLICATION EXPLORATION COMMAND STATUS**: Application exploration command with analysis, explanation, and reasoning capabilities
**CORE FOCUS**: Deep application component analysis and framework integration understanding  
**EXPLORATION SCOPE**: Comprehensive application analysis, integration pattern recognition, and feature explanation
**KNOWLEDGE INTEGRATION**: Application understanding and analysis for informed development decisions
**WORKFLOW INTEGRATION**: Analysis integration with planning, development, and documentation workflows

**Use ApplicationProtocols/@EXPLORE for comprehensive application analysis, explanation, and framework integration reasoning.**