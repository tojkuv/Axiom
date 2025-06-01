# @PLAN.md - Axiom Application Development Planning Command

Application development planning command that creates proposals for application implementation

## Automated Mode Trigger

**When human sends**: `@PLAN [optional-args]`
**Action**: Enter ultrathink mode and execute application development planning workflow

### Usage Modes
- **`@PLAN`** → Create application development proposal in AxiomExampleApp/Proposals/Active/
- **`@PLAN plan`** → Plan application development tasks and create proposal
- **`@PLAN validate`** → Plan application validation and create testing proposal
- **`@PLAN enhance`** → Plan application enhancements and user experience improvements

### Application Planning Scope
**Planning Focus**: Application development proposal creation and strategic planning
**Branch Independence**: Works on current branch - no git operations performed
**Proposal Creation**: Creates structured application proposals for user review and revision
**Development Integration**: Proposals are implemented through ApplicationProtocols/DEVELOP.md after user approval

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: PLAN commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: PLAN creates proposals → Multiple PLAN/DEVELOP/REFACTOR cycles → @CHECKPOINT commits and merges

Work commands operate on current branch without version control:
1. **Analysis**: Read current TRACKING.md priorities and application status
2. **Planning**: Create application development proposals
3. **Proposal Management**: Move proposals through lifecycle stages
4. **Documentation**: Update proposal status and planning coordination
**No Git Operations**: PLAN commands never commit, push, or merge

## Application Development Planning Philosophy

**Core Principle**: Application planning creates detailed technical proposals for application development that can be reviewed, revised, and approved by users before implementation begins. Proposals focus exclusively on technical implementation details.

**Proposal Workflow**: @PLAN creates application proposals → User reviews/revises → ApplicationProtocols/DEVELOP.md implements → Progress tracked in ApplicationProtocols/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO implementation
- **DEVELOP**: Implements proposals → Updates TRACKING.md progress → NO planning
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Application proposals include comprehensive technical specifications, implementation approaches, and success criteria

**Technical Focus Only**: Proposals strictly focus on technical implementation details. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Application Planning Methodology

### Phase 1: Application Analysis
1. **TRACKING.md Review** → Read current priorities, progress, and next actions from ApplicationProtocols/TRACKING.md
2. **Current Application Assessment** → Analyze current application implementation status and needs
3. **Technical Requirements Analysis** → Understand technical objectives and implementation constraints only
4. **Technical Assessment** → Evaluate application technical approaches and implementation strategies
5. **Technical User Interface Planning** → Assess technical implementation of user interface components and interactions
6. **Technical Success Criteria Definition** → Define measurable technical outcomes and validation criteria (performance, functionality, architecture compliance)

### Phase 2: Application Proposal Creation
1. **Technical Specification** → Create detailed application technical approach and architecture
2. **Implementation Planning** → Plan application development phases and implementation steps
3. **Testing Strategy** → Define application testing approach and validation procedures
4. **Documentation Planning** → Plan application documentation updates and requirements
5. **Integration Strategy** → Define integration with existing application codebase and framework

### Phase 3: Application Proposal Documentation
1. **Structured Format** → Create application proposal using established format and sections
2. **Technical Details** → Include comprehensive application technical specifications and approaches
3. **Implementation Roadmap** → Provide clear application implementation steps and phases
4. **Success Metrics** → Define measurable application success criteria and validation approaches
5. **Review Preparation** → Prepare application proposal for user review and potential revision

## Application Proposal Creation Process

### Application Proposals (AxiomExampleApp/Proposals/)
**Focus**: Test application development, framework integration validation, user experience implementation
**Directories**: 
- Active/: Application proposals under development
- WaitingApproval/: Application proposals ready for user review
- Archive/: Completed application proposals
**Implementation**: Implemented through ApplicationProtocols/DEVELOP.md
**Progress Tracking**: Tracked in ApplicationProtocols/TRACKING.md

## Application Proposal Lifecycle Management

### Application Proposal States
- **Active**: Application proposal created in Active/ directory, under development
- **Waiting Approval**: Application proposal moved to WaitingApproval/ directory, ready for user review
- **Under Revision**: User requests changes, application proposal updated in Active/ directory
- **Approved**: User approves application proposal, ready for ApplicationProtocols/DEVELOP.md implementation
- **In Development**: ApplicationProtocols/DEVELOP.md implementing proposal, progress tracked in TRACKING.md
- **Completed**: Application implementation complete, proposal archived to Archive/ directory

### Application Workflow Integration
1. **ApplicationProtocols/@PLAN** → Creates application proposal in AxiomExampleApp/Proposals/Active/
2. **Proposal Completion** → Application proposal moved to AxiomExampleApp/Proposals/WaitingApproval/
3. **User Review** → User reviews and optionally revises application proposal
4. **User Approval** → User approves application proposal for implementation
5. **ApplicationProtocols/@DEVELOP** → Implements application proposal, tracks progress in TRACKING.md
6. **ApplicationProtocols/@CHECKPOINT** → Completes application implementation, archives proposal

## Application Planning Command Execution

**Command**: `@PLAN [plan|validate|enhance]`
**Action**: Execute comprehensive application planning workflow with proposal creation

### 🔄 **Planning Execution Process**

**CRITICAL**: PLAN commands work on current branch state - NO git operations

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

# Planning workflow (NO git operations)
echo "🎯 Application Planning Execution"
echo "📍 Working on current branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "🎯 Planning ready - proceeding on application branch"
```

**Automated Execution Process**:
1. **TRACKING.md Priority Analysis** → Read current priorities and status from ApplicationProtocols/TRACKING.md
2. **Application Context Analysis** → Analyze existing application implementation and identify development needs
3. **Requirements Assessment** → Understand application development objectives and constraints
4. **Technical Planning** → Design application technical approach and implementation strategy
5. **Application Proposal Creation** → Create structured application proposal in AxiomExampleApp/Proposals/Active/
6. **Review Preparation** → Prepare application proposal for user review and potential revision
7. **Branch Cleanup** → Switch back to main branch after completing all tasks
**No Git Operations**: All version control handled by @CHECKPOINT commands only

```bash
# Switch back to main branch after completing all tasks
echo "🔄 Switching back to main branch..."
git checkout main
echo "✅ Returned to main branch"
```

**Application Planning Execution Examples**:
- `@PLAN` → Create application development proposal
- `@PLAN plan` → Plan application development tasks and create proposal
- `@PLAN validate` → Plan application validation and create testing proposal
- `@PLAN enhance` → Plan application enhancements and user experience improvements

## Application Proposal Format Standards

### Application Proposal Structure
- **Title**: Clear, descriptive application proposal title
- **Summary**: Brief overview of application proposal objectives and approach
- **Technical Specification**: Detailed application technical approach and architecture
- **Implementation Plan**: Step-by-step application implementation phases and procedures
- **Testing Strategy**: Comprehensive application testing approach and validation procedures
- **Success Criteria**: Measurable application outcomes and validation criteria
- **Integration Notes**: Application integration considerations and dependencies

### Application Quality Standards
- **Technical Coverage Only**: All technical aspects of application development approach covered (no business, marketing, or adoption considerations)
- **Technical Depth**: Sufficient technical detail for application implementation
- **Clear Implementation Steps**: Actionable technical implementation procedures only
- **Technical Validation Approach**: Clear technical testing and validation strategy (performance, functionality, integration)
- **Technical Metrics Only**: Specific technical success criteria and metrics (no user engagement, adoption, or business metrics)

## Application Planning Workflow Integration

**Planning Purpose**: Strategic application proposal creation for structured development
**Implementation Separation**: ApplicationProtocols/DEVELOP.md implements proposals, never edits them
**Progress Tracking**: ApplicationProtocols/TRACKING.md monitors application proposal implementation progress
**Archive Management**: Completed application proposals archived for reference and documentation
**User Control**: Users review, revise, and approve application proposals before implementation

## Application Planning Coordination

**Proposal Creation**: Creates application proposals in AxiomExampleApp/Proposals/Active/ directory, moves to WaitingApproval/ when ready for review
**User Interaction**: Application proposals designed for user review, revision, and approval
**Development Integration**: Application proposals implemented through ApplicationProtocols/DEVELOP.md
**Progress Monitoring**: Application implementation progress tracked through ApplicationProtocols/TRACKING.md
**Archive Management**: Completed application proposals archived for future reference

---

**APPLICATION PLANNING COMMAND STATUS**: Application development planning command with proposal creation and management
**CORE FOCUS**: Strategic application proposal creation for application development  
**PROPOSAL CREATION**: Creates structured application proposals in AxiomExampleApp/Proposals/Active/
**USER WORKFLOW**: Application proposals for user review, revision, and approval before implementation
**INTEGRATION**: Workflow integration with ApplicationProtocols/DEVELOP.md and TRACKING progress monitoring

**Use ApplicationProtocols/@PLAN for strategic application development planning with structured proposal creation and user approval workflow.**