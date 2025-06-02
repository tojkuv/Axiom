# @PLAN.md - Axiom Framework Development Planning Command

Framework development planning command that creates proposals for type-safe, concurrency-safe, performant, deterministic, actor-based framework with low boilerplate and capabilities permissions

## Automated Mode Trigger

**When human sends**: `@PLAN [optional-args]`
**Action**: Enter ultrathink mode and execute framework development planning workflow

### Usage Modes
- **`@PLAN`** → Create framework development proposal in AxiomFramework/Proposals/Active/
- **`@PLAN plan`** → Plan framework development tasks and create proposal
- **`@PLAN analyze`** → Analyze framework needs and create implementation proposal
- **`@PLAN enhance`** → Plan framework enhancements and capability improvements

### Framework Planning Scope
**Planning Focus**: Framework development proposal creation and strategic planning
**Branch Requirement**: Must be executed from framework branch for framework development
**Proposal Creation**: Creates structured framework proposals for user review and revision
**Development Integration**: Proposals are approved through FrameworkProtocols/APPROVE.md and implemented through FrameworkProtocols/DEVELOP.md

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: PLAN commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: PLAN creates proposals → @APPROVE accepts proposals → DEVELOP implements → Multiple DEVELOP/REFACTOR cycles → @CHECKPOINT commits and merges

Work commands operate on current branch without version control:
1. **Analysis**: Read current TRACKING.md priorities and framework status
2. **Planning**: Create framework development proposals
3. **Proposal Management**: Move proposals through lifecycle stages
**No Git Operations**: PLAN commands never commit, push, or merge

## Framework Development Planning Philosophy

**Core Principle**: Framework planning creates detailed technical proposals for a type-safe, concurrency-safe, performant, deterministic framework designed for AI agent coding. The framework emphasizes actor-based isolation, low boilerplate through code generation, capabilities permissions safety, and consistent patterns throughout.

**Proposal Workflow**: @PLAN creates framework proposals → User reviews/revises → FrameworkProtocols/@APPROVE accepts proposals → FrameworkProtocols/DEVELOP.md implements → Progress tracked in FrameworkProtocols/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO approval or implementation
- **APPROVE**: Accepts proposals → Updates TRACKING.md priorities → NO creation or implementation
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO planning or approval
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Framework proposals ensure type safety, concurrency safety through actors, performance optimization, deterministic behavior, minimal boilerplate, capabilities permissions enforcement, and consistent patterns

**Technical Focus Only**: Proposals strictly focus on technical implementation for AI agent coding. Framework design prioritizes machine readability, consistent patterns, and deterministic behavior optimized for automated development workflows.

## Framework Planning Methodology

### Phase 1: Framework Analysis
1. **TRACKING.md Review** → Read current priorities, progress, and next actions from FrameworkProtocols/TRACKING.md
2. **Type Safety Assessment** → Analyze compile-time type safety guarantees and validation
3. **Concurrency Safety Analysis** → Evaluate actor-based isolation and thread safety patterns
4. **Performance Requirements** → Define performance targets and optimization strategies
5. **Determinism Validation** → Ensure predictable, reproducible behavior without side effects
6. **Boilerplate Reduction Planning** → Identify code generation opportunities to minimize repetitive code
7. **Capabilities Permissions** → Plan runtime capability validation with compile-time hints
8. **Pattern Consistency** → Ensure uniform patterns across framework components

### Phase 2: Framework Proposal Creation
1. **Type-Safe Architecture** → Design compile-time type validation and safety guarantees
2. **Actor-Based Concurrency** → Plan actor isolation patterns for thread-safe state management
3. **Performance Optimization** → Define performance targets and measurement strategies
4. **Deterministic Implementation** → Ensure predictable behavior without hidden state
5. **Code Generation Strategy** → Plan macros and builders to reduce boilerplate
6. **Capabilities System** → Design permissions validation with graceful degradation
7. **Testing Strategy** → Define comprehensive testing for all safety guarantees

### Phase 3: Framework Proposal Finalization
1. **Structured Format** → Create framework proposal using established format and sections
2. **Technical Details** → Include comprehensive framework technical specifications and approaches
3. **Implementation Roadmap** → Provide clear framework implementation steps and phases
4. **Success Metrics** → Define measurable framework success criteria and validation approaches
5. **Review Preparation** → Prepare framework proposal for user review and potential revision

## Framework Proposal Creation Process

### Framework Proposals (AxiomFramework/Proposals/)
**Focus**: Type-safe architecture, actor-based concurrency, performance optimization, deterministic behavior, boilerplate reduction, capabilities permissions
**Directories**: 
- Active/: Framework proposals under development
- WaitingApproval/: Framework proposals ready for user review
- Archive/: Completed framework proposals
**Implementation**: Implemented through FrameworkProtocols/DEVELOP.md
**Progress Tracking**: Tracked in FrameworkProtocols/TRACKING.md

## Framework Proposal Lifecycle Management

### Framework Proposal States
- **Active**: Framework proposal created in Active/ directory, under development by @PLAN
- **Waiting Approval**: Framework proposal moved to WaitingApproval/ directory, ready for @APPROVE processing
- **Under Revision**: User requests changes, framework proposal updated in Active/ directory by @PLAN
- **Approved**: FrameworkProtocols/@APPROVE accepts proposal, ready for FrameworkProtocols/DEVELOP.md implementation
- **In Development**: FrameworkProtocols/DEVELOP.md implementing proposal, progress tracked in TRACKING.md
- **Completed**: Framework implementation complete, proposal archived to Archive/ directory

### Framework Workflow Integration
1. **FrameworkProtocols/@PLAN** → Creates framework proposal in AxiomFramework/Proposals/Active/
2. **Proposal Completion** → Framework proposal moved to AxiomFramework/Proposals/WaitingApproval/
3. **User Review** → User reviews and optionally revises framework proposal
4. **FrameworkProtocols/@APPROVE** → Accepts framework proposal and updates TRACKING.md priorities
5. **FrameworkProtocols/@DEVELOP** → Implements approved proposal, tracks progress in TRACKING.md
6. **FrameworkProtocols/@CHECKPOINT** → Completes framework implementation, archives proposal

## Framework Planning Command Execution

**Command**: `@PLAN [plan|analyze|enhance]`
**Action**: Execute comprehensive framework planning workflow with proposal creation

### 🔄 **Planning Execution Process**

**CRITICAL**: PLAN commands work on current branch state - NO git operations

```bash
# Navigate to framework workspace
echo "🔄 Entering framework development workspace..."
cd framework-workspace/ || {
    echo "❌ Framework workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Planning workflow (NO git operations)
echo "🎯 Framework Planning Execution"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "🎯 Planning ready - proceeding in framework workspace"
```

**Automated Execution Process**:
1. **TRACKING.md Priority Analysis** → Read current priorities and status from FrameworkProtocols/TRACKING.md
2. **Framework Context Analysis** → Analyze existing framework implementation and identify development needs
3. **Requirements Assessment** → Understand framework development objectives and constraints
4. **Technical Planning** → Design framework technical approach and implementation strategy
5. **Framework Proposal Creation** → Create structured framework proposal in AxiomFramework/Proposals/Active/
6. **Review Preparation** → Prepare framework proposal for user review and potential revision
**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Framework Planning Execution Examples**:
- `@PLAN` → Create framework development proposal
- `@PLAN plan` → Plan framework development tasks and create proposal
- `@PLAN analyze` → Analyze framework needs and create implementation proposal
- `@PLAN enhance` → Plan framework enhancements and capability improvements

## Framework Proposal Format Standards

### Framework Proposal Structure
- **Title**: Clear, descriptive framework proposal title
- **Summary**: Brief overview of framework proposal objectives and approach
- **Technical Specification**: Detailed framework technical approach and architecture
- **Implementation Plan**: Step-by-step framework implementation phases and procedures
- **Testing Strategy**: Comprehensive framework testing approach and validation procedures
- **Success Criteria**: Measurable framework outcomes and validation criteria
- **Integration Notes**: Framework integration considerations and dependencies

### Framework Quality Standards
- **Type Safety**: Compile-time type validation and runtime safety guarantees
- **Concurrency Safety**: Actor-based isolation preventing data races and ensuring thread safety
- **Performance Targets**: Measurable performance goals and optimization strategies
- **Deterministic Behavior**: Predictable, reproducible operations without hidden state
- **Minimal Boilerplate**: Code generation reducing repetitive patterns
- **Capabilities Enforcement**: Runtime permissions validation with compile-time optimization
- **Pattern Consistency**: Uniform patterns enabling reliable AI agent coding

## Framework Planning Workflow Integration

**Planning Purpose**: Strategic framework proposal creation for structured development
**Approval Separation**: FrameworkProtocols/APPROVE.md handles proposal acceptance, never creates proposals
**Implementation Separation**: FrameworkProtocols/DEVELOP.md implements approved proposals, never creates or approves them
**Progress Tracking**: FrameworkProtocols/TRACKING.md monitors framework proposal implementation progress
**Archive Management**: Completed framework proposals archived for reference and documentation
**User Control**: Users review and revise framework proposals before @APPROVE processing

## Framework Planning Coordination

**Proposal Creation**: Creates framework proposals in AxiomFramework/Proposals/Active/ directory, moves to WaitingApproval/ when ready for review
**User Interaction**: Framework proposals designed for user review and revision
**Approval Integration**: Framework proposals processed through FrameworkProtocols/@APPROVE for acceptance
**Development Integration**: Approved framework proposals implemented through FrameworkProtocols/DEVELOP.md
**Progress Monitoring**: Framework implementation progress tracked through FrameworkProtocols/TRACKING.md
**Archive Management**: Completed framework proposals archived for future reference

---

**FRAMEWORK PLANNING COMMAND STATUS**: Framework development planning for type-safe, concurrency-safe, performant, deterministic framework
**CORE FOCUS**: Actor-based architecture with minimal boilerplate and capabilities permissions for AI agent coding
**TECHNICAL ATTRIBUTES**: Type safety, concurrency safety, performance, determinism, low boilerplate, capabilities permissions, consistent patterns
**PROPOSAL CREATION**: Creates structured framework proposals in AxiomFramework/Proposals/Active/
**INTEGRATION**: Workflow integration with FrameworkProtocols/@APPROVE, DEVELOP.md and TRACKING progress monitoring

**Use FrameworkProtocols/@PLAN for strategic framework development planning with structured proposal creation and @APPROVE workflow integration.**