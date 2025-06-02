# @PLAN.md - Axiom Framework Development Planning Command

Framework development planning command that creates proposals for framework implementation

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
4. **Documentation**: Update proposal status and planning coordination
**No Git Operations**: PLAN commands never commit, push, or merge

## Framework Development Planning Philosophy

**Core Principle**: Framework planning creates detailed technical proposals for framework development that can be reviewed, revised, and approved by users before implementation begins. Proposals focus exclusively on technical implementation details.

**Proposal Workflow**: @PLAN creates framework proposals → User reviews/revises → FrameworkProtocols/@APPROVE accepts proposals → FrameworkProtocols/DEVELOP.md implements → Progress tracked in FrameworkProtocols/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO approval or implementation
- **APPROVE**: Accepts proposals → Updates TRACKING.md priorities → NO creation or implementation
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO planning or approval
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Framework proposals include comprehensive technical specifications, implementation approaches, and success criteria

**Technical Focus Only**: Proposals strictly focus on technical implementation details. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Framework Planning Methodology

### Phase 1: Framework Analysis
1. **TRACKING.md Review** → Read current priorities, progress, and next actions from FrameworkProtocols/TRACKING.md
2. **Current Framework Assessment** → Analyze current framework implementation status and needs
3. **Technical Requirements Analysis** → Understand technical objectives and implementation constraints only
4. **Technical Assessment** → Evaluate framework technical approaches and implementation strategies
5. **Technical Architecture Planning** → Assess technical framework architecture changes and implementation requirements
6. **Technical Success Criteria Definition** → Define measurable technical outcomes and validation criteria (performance, functionality, architecture compliance)

### Phase 2: Framework Proposal Creation
1. **Technical Specification** → Create detailed framework technical approach and architecture
2. **Implementation Planning** → Plan framework development phases and implementation steps
3. **Testing Strategy** → Define framework testing approach and validation procedures
4. **Documentation Planning** → Plan framework documentation updates and requirements
5. **Integration Strategy** → Define integration with existing framework codebase and workflows

### Phase 3: Framework Proposal Documentation
1. **Structured Format** → Create framework proposal using established format and sections
2. **Technical Details** → Include comprehensive framework technical specifications and approaches
3. **Implementation Roadmap** → Provide clear framework implementation steps and phases
4. **Success Metrics** → Define measurable framework success criteria and validation approaches
5. **Review Preparation** → Prepare framework proposal for user review and potential revision

## Framework Proposal Creation Process

### Framework Proposals (AxiomFramework/Proposals/)
**Focus**: Core framework development, architecture enhancements, capability implementation
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
- **Technical Coverage Only**: All technical aspects of framework development approach covered (no business, marketing, or adoption considerations)
- **Technical Depth**: Sufficient technical detail for framework implementation
- **Clear Implementation Steps**: Actionable technical implementation procedures only
- **Technical Validation Approach**: Clear technical testing and validation strategy (performance, functionality, integration)
- **Technical Metrics Only**: Specific technical success criteria and metrics (no user engagement, adoption, or business metrics)

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

**FRAMEWORK PLANNING COMMAND STATUS**: Framework development planning command with proposal creation and lifecycle management
**CORE FOCUS**: Strategic framework proposal creation for framework development  
**PROPOSAL CREATION**: Creates structured framework proposals in AxiomFramework/Proposals/Active/
**USER WORKFLOW**: Framework proposals for user review and revision before @APPROVE processing
**INTEGRATION**: Workflow integration with FrameworkProtocols/@APPROVE, DEVELOP.md and TRACKING progress monitoring

**Use FrameworkProtocols/@PLAN for strategic framework development planning with structured proposal creation and @APPROVE workflow integration.**