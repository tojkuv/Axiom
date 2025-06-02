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

**Core Principle**: Framework planning manages the complete lifecycle of technical proposals - from creation through approval to resolution. This protocol handles proposal workflow management, not framework architecture decisions.

**Proposal Workflow**: @PLAN creates framework proposals → User reviews/revises → FrameworkProtocols/@APPROVE accepts proposals → FrameworkProtocols/DEVELOP.md implements → Progress tracked in FrameworkProtocols/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO approval or implementation
- **APPROVE**: Accepts proposals → Updates TRACKING.md priorities → NO creation or implementation
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO planning or approval
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Framework proposals include comprehensive technical specifications, clear implementation paths, and measurable success criteria

**Technical Focus Only**: Proposals strictly focus on technical implementation for AI agent coding. Framework design prioritizes machine readability, consistent patterns, and deterministic behavior optimized for automated development workflows.

## Framework Planning Methodology

### Phase 1: Framework Analysis
1. **TRACKING.md Review** → Read current priorities and progress
2. **Framework Assessment** → Analyze current implementation state
3. **Requirements Analysis** → Identify development needs and gaps
4. **Technical Planning** → Define implementation approach
5. **Resource Planning** → Estimate development effort
6. **Risk Assessment** → Identify potential challenges

### Phase 2: Framework Proposal Creation
1. **Technical Specification** → Define implementation approach and architecture
2. **Type Safety Design** → Plan compile-time validation and guarantees
3. **Concurrency Strategy** → Design actor-based isolation patterns
4. **Performance Targets** → Set measurable optimization goals
5. **Code Generation** → Plan boilerplate reduction strategies
6. **Testing Approach** → Define comprehensive validation procedures
7. **Integration Planning** → Ensure compatibility with existing framework

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
- **Active**: Proposal created in Active/ directory, under development
- **Waiting Approval**: Proposal in WaitingApproval/ directory, ready for approval
- **Under Revision**: User requests changes, proposal updated in Active/
- **Approved**: @PLAN approve accepts proposal, updates TRACKING.md
- **In Development**: @DEVELOP implementing proposal, progress tracked
- **Completed**: Implementation complete, @PLAN resolve archives to Archive/

### Framework Workflow Integration
1. **@PLAN create** → Creates framework proposal in AxiomFramework/Proposals/Active/
2. **User Review** → User reviews and edits proposal in Active/
3. **Submit for Approval** → Move proposal to WaitingApproval/
4. **@PLAN approve** → Process proposal, update TRACKING.md priorities
5. **@DEVELOP** → Implement approved proposal with progress tracking
6. **@PLAN resolve** → Validate completion and archive to Archive/
7. **@CHECKPOINT** → Commit completed work to version control

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

## Framework Proposal Approval Process

### Approval Criteria (`@PLAN approve`)
- **Technical Completeness**: All specifications defined
- **Implementation Readiness**: Clear development path
- **Testing Strategy**: Comprehensive validation approach
- **Performance Requirements**: Defined and measurable
- **Framework Compatibility**: Aligns with framework design

### Approval Workflow
1. **Scan WaitingApproval/** → List pending proposals
2. **Validate Completeness** → Ensure ready for implementation
3. **Update TRACKING.md** → Add to development priorities
4. **Set Implementation Order** → Based on dependencies
5. **Prepare for Development** → Ready for DEVELOP.md

## Framework Proposal Resolution Process

### Resolution Criteria (`@PLAN resolve`)
- **Implementation Complete**: All phases finished
- **Tests Passing**: Required success rate achieved
- **Performance Met**: Benchmarks satisfied
- **Quality Standards**: Framework requirements met
- **Documentation Current**: Via DOCUMENT.md

### Resolution Workflow
1. **Validate Completion** → Check success criteria
2. **Update TRACKING.md** → Mark as completed
3. **Archive Proposal** → Move to Archive/
4. **Document Outcomes** → Record achievements
5. **Reset for Next Cycle** → Clear active tracking

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

**FRAMEWORK PLANNING COMMAND STATUS**: Complete proposal lifecycle management (create/approve/resolve)
**CORE FOCUS**: Proposal workflow management - creation, approval, and resolution
**PROPOSAL LIFECYCLE**: Unified command for all proposal states and transitions
**LIFECYCLE MANAGEMENT**: Handles Active/, WaitingApproval/, and Archive/ directories
**INTEGRATION**: Direct integration with DEVELOP.md and TRACKING.md for seamless workflow

**Use FrameworkProtocols/@PLAN for complete proposal lifecycle management - creation, approval, and resolution.**