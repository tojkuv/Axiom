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
**Branch Requirement**: Must be executed from application branch for application development
**Proposal Creation**: Creates structured application proposals for user review and revision
**Development Integration**: Proposals are implemented through ApplicationDevelopment/DEVELOP.md after user approval

### 🔄 **Standardized Git Workflow**
All ApplicationDevelopment commands follow this workflow:
1. **Branch Setup**: Switch to `application` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `application` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `application` branch with descriptive messages
5. **Integration**: Merge `application` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `application` branch and create fresh one for next cycle

## Application Development Planning Philosophy

**Core Principle**: Application planning creates detailed proposals for application development that can be reviewed, revised, and approved by users before implementation begins.

**Proposal Workflow**: @PLAN creates application proposals → User reviews/revises → ApplicationDevelopment/DEVELOP.md implements → Progress tracked in ApplicationDevelopment/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO implementation
- **DEVELOP**: Implements proposals → Updates TRACKING.md progress → NO planning
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Application proposals include comprehensive technical specifications, implementation approaches, and success criteria

## Application Planning Methodology

### Phase 1: Application Analysis
1. **TRACKING.md Review** → Read current priorities, progress, and next actions from ApplicationDevelopment/TRACKING.md
2. **Current Application Assessment** → Analyze current application implementation status and needs
3. **Requirements Analysis** → Understand application development objectives and constraints
4. **Technical Assessment** → Evaluate application technical approaches and implementation strategies
5. **User Experience Planning** → Assess application user experience changes and resource requirements
6. **Success Criteria Definition** → Define measurable application outcomes and validation criteria

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
**Implementation**: Implemented through ApplicationDevelopment/DEVELOP.md
**Progress Tracking**: Tracked in ApplicationDevelopment/TRACKING.md

## Application Proposal Lifecycle Management

### Application Proposal States
- **Active**: Application proposal created in Active/ directory, under development
- **Waiting Approval**: Application proposal moved to WaitingApproval/ directory, ready for user review
- **Under Revision**: User requests changes, application proposal updated in Active/ directory
- **Approved**: User approves application proposal, ready for ApplicationDevelopment/DEVELOP.md implementation
- **In Development**: ApplicationDevelopment/DEVELOP.md implementing proposal, progress tracked in TRACKING.md
- **Completed**: Application implementation complete, proposal archived to Archive/ directory

### Application Workflow Integration
1. **ApplicationDevelopment/@PLAN** → Creates application proposal in AxiomExampleApp/Proposals/Active/
2. **Proposal Completion** → Application proposal moved to AxiomExampleApp/Proposals/WaitingApproval/
3. **User Review** → User reviews and optionally revises application proposal
4. **User Approval** → User approves application proposal for implementation
5. **ApplicationDevelopment/@DEVELOP** → Implements application proposal, tracks progress in TRACKING.md
6. **ApplicationDevelopment/@CHECKPOINT** → Completes application implementation, archives proposal

## Application Planning Command Execution

**Command**: `@PLAN [plan|validate|enhance]`
**Action**: Execute comprehensive application planning workflow with proposal creation

### 🔄 **Branch Verification and Setup**

**Before executing any planning work, execute this branch verification:**

```bash
# 1. Check current branch and switch to application branch if needed
CURRENT_BRANCH=$(git branch --show-current)
echo "🎯 Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "application" ]; then
    echo "🔄 Switching from $CURRENT_BRANCH to application branch..."
    
    # Check if application branch exists
    if git show-ref --verify --quiet refs/heads/application; then
        echo "📍 Application branch exists locally, switching..."
        git checkout application
    elif git show-ref --verify --quiet refs/remotes/origin/application; then
        echo "📍 Application branch exists remotely, checking out..."
        git checkout -b application origin/application
    else
        echo "🌱 Creating new application branch..."
        git checkout -b application
        git push origin application -u
    fi
    
    echo "✅ Now on application branch"
else
    echo "✅ Already on application branch"
fi

# 2. Update application branch with latest changes
echo "🔄 Updating application branch..."
git fetch origin application 2>/dev/null || true
git pull origin application 2>/dev/null || echo "📍 No remote updates available"

echo "🎯 Branch verification complete - ready for application planning"
```

**Automated Execution Process**:
1. **Branch Verification** → Switch to `application` branch and update with latest changes
2. **TRACKING.md Priority Analysis** → Read current priorities and status from ApplicationDevelopment/TRACKING.md
3. **Application Context Analysis** → Analyze existing application implementation and identify development needs
4. **Requirements Assessment** → Understand application development objectives and constraints
5. **Technical Planning** → Design application technical approach and implementation strategy
6. **Application Proposal Creation** → Create structured application proposal in AxiomExampleApp/Proposals/Active/
7. **Review Preparation** → Prepare application proposal for user review and potential revision

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
- **Comprehensive Coverage**: All aspects of application development approach covered
- **Technical Depth**: Sufficient technical detail for application implementation
- **Clear Implementation Steps**: Actionable application implementation procedures
- **Validation Approach**: Clear application testing and validation strategy
- **Measurable Outcomes**: Specific application success criteria and metrics

## Application Planning Workflow Integration

**Planning Purpose**: Strategic application proposal creation for structured development
**Implementation Separation**: ApplicationDevelopment/DEVELOP.md implements proposals, never edits them
**Progress Tracking**: ApplicationDevelopment/TRACKING.md monitors application proposal implementation progress
**Archive Management**: Completed application proposals archived for reference and documentation
**User Control**: Users review, revise, and approve application proposals before implementation

## Application Planning Coordination

**Proposal Creation**: Creates application proposals in AxiomExampleApp/Proposals/Active/ directory, moves to WaitingApproval/ when ready for review
**User Interaction**: Application proposals designed for user review, revision, and approval
**Development Integration**: Application proposals implemented through ApplicationDevelopment/DEVELOP.md
**Progress Monitoring**: Application implementation progress tracked through ApplicationDevelopment/TRACKING.md
**Archive Management**: Completed application proposals archived for future reference

---

**APPLICATION PLANNING COMMAND STATUS**: Application development planning command with proposal creation and management
**CORE FOCUS**: Strategic application proposal creation for application development  
**PROPOSAL CREATION**: Creates structured application proposals in AxiomExampleApp/Proposals/Active/
**USER WORKFLOW**: Application proposals for user review, revision, and approval before implementation
**INTEGRATION**: Workflow integration with ApplicationDevelopment/DEVELOP.md and TRACKING progress monitoring

**Use ApplicationDevelopment/@PLAN for strategic application development planning with structured proposal creation and user approval workflow.**