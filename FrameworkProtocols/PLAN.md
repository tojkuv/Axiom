# @PLAN.md - Axiom Framework Proposal Lifecycle Management

Framework proposal lifecycle management command that creates, approves, and resolves proposals

## Automated Mode Trigger

**When human sends**: `@PLAN [optional-args]`
**Action**: Enter ultrathink mode and execute framework proposal lifecycle workflow

### Usage Modes
- **`@PLAN`** → Show current proposal status across all directories
- **`@PLAN create`** → Create new proposal in AxiomFramework/Proposals/Unapproved/
- **`@PLAN approve`** → Move proposal from Unapproved/ to Approved/ and update TRACKING.md
- **`@PLAN resolve`** → Archive completed proposal from Approved/ to Archive/
- **`@PLAN status`** → Display detailed proposal status in each lifecycle stage

### Framework Planning Scope
**Lifecycle Management**: Complete proposal lifecycle from creation to resolution
**Branch Requirement**: Must be executed from framework branch for framework development
**Proposal Management**: Creates, approves, and resolves framework proposals
**Development Integration**: Approved proposals implemented through FrameworkProtocols/DEVELOP.md

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: PLAN commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: PLAN manages full lifecycle → Creates proposals → Approves proposals → DEVELOP implements → PLAN resolves completed work → @CHECKPOINT commits and merges

Work commands operate on current branch without version control:
1. **Creation**: Create new proposals directly in Unapproved/
2. **Approval**: Move proposals to Approved/ and update TRACKING.md priorities
3. **Resolution**: Archive completed proposals from Approved/ to Archive/
4. **Status Tracking**: Update TRACKING.md at approval and resolution stages
**No Git Operations**: PLAN commands never commit, push, or merge

## Framework Development Planning Philosophy

**Core Principle**: Framework planning manages the complete lifecycle of technical proposals - from creation through approval to resolution. This protocol handles proposal workflow management, not framework architecture decisions.

**Proposal Workflow**: @PLAN create (Unapproved/) → User reviews → @PLAN approve (to Approved/) → DEVELOP implements → @PLAN resolve (to Archive/)

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Manages complete proposal lifecycle (create/approve/resolve) → Updates TRACKING.md
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO planning
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **DOCUMENT**: Documentation operations → NO implementation or planning
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
5. **Ready for Review** → Save proposal in Unapproved/ for user review

## Framework Proposal Creation Process

### Framework Proposals (AxiomFramework/Proposals/)
**Focus**: Core framework development, architecture enhancements, capability implementation
**Directories**: 
- Unapproved/: New proposals awaiting approval
- Approved/: Approved proposals ready for development
- Archive/: Completed proposals
**Implementation**: Implemented through FrameworkProtocols/DEVELOP.md
**Progress Tracking**: Updated in TRACKING.md at approval and resolution

## Framework Proposal Lifecycle Management

### Framework Proposal States
- **Unapproved**: New proposal in Unapproved/ directory awaiting review
- **Under Review**: User reviewing proposal in Unapproved/
- **Approved**: Proposal moved to Approved/, TRACKING.md updated with priorities
- **In Development**: @DEVELOP implementing from Approved/ directory
- **Completed**: Implementation done, ready for resolution
- **Archived**: @PLAN resolve moves from Approved/ to Archive/

### Framework Workflow Integration
1. **@PLAN create** → Creates proposal in AxiomFramework/Proposals/Unapproved/
2. **User Review** → User reviews proposal in Unapproved/
3. **@PLAN approve** → Move to Approved/, update TRACKING.md priorities
4. **@DEVELOP** → Implement from Approved/ with progress tracking
5. **@PLAN resolve** → Archive from Approved/ to Archive/, update TRACKING.md
6. **@CHECKPOINT** → Commit completed work to version control

## Framework Planning Command Execution

**Command**: `@PLAN [create|approve|resolve|status]`
**Action**: Execute comprehensive framework proposal lifecycle management

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

### Create Mode (`@PLAN create`)
1. **TRACKING.md Analysis** → Read current priorities from FrameworkProtocols/TRACKING.md
2. **Requirements Assessment** → Analyze framework development needs
3. **Proposal Creation** → Create structured proposal in AxiomFramework/Proposals/Unapproved/
4. **Ready for Review** → Proposal immediately available for user review

### Approve Mode (`@PLAN approve`)
1. **Scan Unapproved/** → List proposals awaiting approval
2. **Validate Proposals** → Ensure technical completeness
3. **Move to Approved/** → Transfer proposal to Approved/ directory
4. **Update TRACKING.md** → Add to development priorities

### Resolve Mode (`@PLAN resolve`)
1. **Scan Approved/** → List completed proposals in Approved/
2. **Validate Completion** → Verify implementation success
3. **Archive Proposal** → Move from Approved/ to Archive/
4. **Update TRACKING.md** → Mark as completed and clear from priorities

**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Framework Planning Execution Examples**:
- `@PLAN` → Show current proposal status across all directories
- `@PLAN create` → Create new proposal in Unapproved/
- `@PLAN approve` → Move proposal from Unapproved/ to Approved/
- `@PLAN resolve` → Archive completed proposal from Approved/
- `@PLAN status` → Display proposals in each lifecycle stage

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
- **Technical Completeness**: All specifications fully defined
- **Implementation Clarity**: Clear development path outlined
- **Testing Coverage**: Comprehensive validation strategy
- **Performance Metrics**: Measurable optimization targets
- **Integration Planning**: Compatible with existing framework

## Framework Proposal Approval Process

### Approval Criteria (`@PLAN approve`)
- **Technical Completeness**: All specifications defined
- **Implementation Readiness**: Clear development path
- **Testing Strategy**: Comprehensive validation approach
- **Performance Requirements**: Defined and measurable
- **Framework Compatibility**: Aligns with framework design

### Approval Workflow
1. **Scan Unapproved/** → List pending proposals
2. **Validate Completeness** → Ensure ready for implementation
3. **Move to Approved/** → Transfer proposal to approved directory
4. **Update TRACKING.md** → Add to development priorities
5. **Set Implementation Order** → Based on dependencies

## Framework Proposal Resolution Process

### Resolution Criteria (`@PLAN resolve`)
- **Implementation Complete**: All phases finished
- **Tests Passing**: Required success rate achieved
- **Performance Met**: Benchmarks satisfied
- **Quality Standards**: Framework requirements met
- **Documentation Current**: Via DOCUMENT.md

### Resolution Workflow
1. **Scan Approved/** → Find completed proposals
2. **Validate Completion** → Check success criteria
3. **Archive Proposal** → Move from Approved/ to Archive/
4. **Update TRACKING.md** → Mark as completed and remove from priorities
5. **Document Outcomes** → Record achievements in archive

## Framework Planning Workflow Integration

**Lifecycle Management**: Complete proposal lifecycle in one command
**Implementation Separation**: FrameworkProtocols/DEVELOP.md implements approved proposals only
**Progress Tracking**: FrameworkProtocols/TRACKING.md monitors all proposal stages
**Archive Management**: Completed proposals archived through resolve operation
**User Control**: Users review proposals before approval processing
**Unified Command**: Single command manages creation, approval, and resolution

## Framework Planning Coordination

**Proposal Directories**:
- `Unapproved/` - New proposals awaiting approval
- `Approved/` - Approved proposals ready for development
- `Archive/` - Completed proposals

**Lifecycle Operations**:
- **Create**: New proposals directly to Unapproved/
- **Review**: User reviews in Unapproved/
- **Approve**: Move to Approved/ and update TRACKING.md
- **Develop**: Implementation from Approved/ via DEVELOP.md
- **Resolve**: Archive from Approved/ and update TRACKING.md

**Proposal Creation**: Creates framework proposals in AxiomFramework/Proposals/Unapproved/ directory
**User Interaction**: Framework proposals designed for user review and revision
**Approval Processing**: Move proposals from Unapproved/ to Approved/ with TRACKING.md update
**Development Integration**: Approved framework proposals implemented through FrameworkProtocols/DEVELOP.md
**Progress Monitoring**: Framework implementation progress tracked through FrameworkProtocols/TRACKING.md
**Archive Management**: Completed framework proposals archived for future reference

---

**FRAMEWORK PLANNING COMMAND STATUS**: Complete proposal lifecycle management (create/approve/resolve)
**CORE FOCUS**: Proposal workflow management - creation, approval, and resolution
**PROPOSAL LIFECYCLE**: Unified command for all proposal states and transitions
**LIFECYCLE MANAGEMENT**: Handles Unapproved/, Approved/, and Archive/ directories
**INTEGRATION**: Direct integration with DEVELOP.md and TRACKING.md for seamless workflow

**Use FrameworkProtocols/@PLAN for complete proposal lifecycle management - creation, approval, and resolution.**