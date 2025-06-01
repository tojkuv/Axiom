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
**Development Integration**: Proposals are implemented through FrameworkDevelopment/DEVELOP.md after user approval

### 🔄 **Standardized Git Workflow**
All FrameworkDevelopment commands follow this workflow:
1. **Branch Setup**: Switch to `framework` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `framework` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `framework` branch with descriptive messages
5. **Integration**: Merge `framework` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `framework` branch and create fresh one for next cycle

## Framework Development Planning Philosophy

**Core Principle**: Framework planning creates detailed proposals for framework development that can be reviewed, revised, and approved by users before implementation begins.

**Proposal Workflow**: @PLAN creates framework proposals → User reviews/revises → FrameworkDevelopment/DEVELOP.md implements → Progress tracked in FrameworkDevelopment/TRACKING.md

### 🎯 **Clear Separation of Concerns**
- **PLAN**: Reads TRACKING.md priorities → Creates proposals → NO implementation
- **DEVELOP**: Implements proposals → Updates TRACKING.md progress → NO planning
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO development
- **REFACTOR**: Code organization → Updates TRACKING.md quality → NO functionality changes
- **TRACKING**: Central progress store → Updated by all commands → NO command execution

**Quality Standards**: Framework proposals include comprehensive technical specifications, implementation approaches, and success criteria

## Framework Planning Methodology

### Phase 1: Framework Analysis
1. **TRACKING.md Review** → Read current priorities, progress, and next actions from FrameworkDevelopment/TRACKING.md
2. **Current Framework Assessment** → Analyze current framework implementation status and needs
3. **Requirements Analysis** → Understand framework development objectives and constraints
4. **Technical Assessment** → Evaluate framework technical approaches and implementation strategies
5. **Architecture Planning** → Assess framework architecture changes and resource requirements
6. **Success Criteria Definition** → Define measurable framework outcomes and validation criteria

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

### Framework Proposals (AxiomFramework/Proposals/Active/)
**Focus**: Core framework development, architecture enhancements, capability implementation
**Directory**: `/Users/tojkuv/Documents/GitHub/Axiom/AxiomFramework/Proposals/Active/`
**Implementation**: Implemented through FrameworkDevelopment/DEVELOP.md
**Progress Tracking**: Tracked in FrameworkDevelopment/TRACKING.md

## Framework Proposal Lifecycle Management

### Framework Proposal States
- **Active**: Framework proposal created in Active/ directory, ready for user review
- **Under Revision**: User requests changes, framework proposal updated in Active/ directory
- **Approved**: User approves framework proposal, ready for FrameworkDevelopment/DEVELOP.md implementation
- **In Development**: FrameworkDevelopment/DEVELOP.md implementing proposal, progress tracked in TRACKING.md
- **Completed**: Framework implementation complete, proposal archived to Archive/ directory

### Framework Workflow Integration
1. **FrameworkDevelopment/@PLAN** → Creates framework proposal in AxiomFramework/Proposals/Active/
2. **User Review** → User reviews and optionally revises framework proposal
3. **User Approval** → User approves framework proposal for implementation
4. **FrameworkDevelopment/@DEVELOP** → Implements framework proposal, tracks progress in TRACKING.md
5. **FrameworkDevelopment/@CHECKPOINT** → Completes framework implementation, archives proposal

## Framework Planning Command Execution

**Command**: `@PLAN [plan|analyze|enhance]`
**Action**: Execute comprehensive framework planning workflow with proposal creation

**Automated Execution Process**:
1. **Branch Validation** → Ensure current branch is framework branch (required for framework development)
2. **TRACKING.md Priority Analysis** → Read current priorities and status from FrameworkDevelopment/TRACKING.md
3. **Framework Context Analysis** → Analyze existing framework implementation and identify development needs
4. **Requirements Assessment** → Understand framework development objectives and constraints
5. **Technical Planning** → Design framework technical approach and implementation strategy
6. **Framework Proposal Creation** → Create structured framework proposal in AxiomFramework/Proposals/Active/
7. **Review Preparation** → Prepare framework proposal for user review and potential revision

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
- **Comprehensive Coverage**: All aspects of framework development approach covered
- **Technical Depth**: Sufficient technical detail for framework implementation
- **Clear Implementation Steps**: Actionable framework implementation procedures
- **Validation Approach**: Clear framework testing and validation strategy
- **Measurable Outcomes**: Specific framework success criteria and metrics

## Framework Planning Workflow Integration

**Planning Purpose**: Strategic framework proposal creation for structured development
**Implementation Separation**: FrameworkDevelopment/DEVELOP.md implements proposals, never edits them
**Progress Tracking**: FrameworkDevelopment/TRACKING.md monitors framework proposal implementation progress
**Archive Management**: Completed framework proposals archived for reference and documentation
**User Control**: Users review, revise, and approve framework proposals before implementation

## Framework Planning Coordination

**Proposal Creation**: Creates framework proposals in AxiomFramework/Proposals/Active/ directory
**User Interaction**: Framework proposals designed for user review, revision, and approval
**Development Integration**: Framework proposals implemented through FrameworkDevelopment/DEVELOP.md
**Progress Monitoring**: Framework implementation progress tracked through FrameworkDevelopment/TRACKING.md
**Archive Management**: Completed framework proposals archived for future reference

---

**FRAMEWORK PLANNING COMMAND STATUS**: Framework development planning command with proposal creation and management
**CORE FOCUS**: Strategic framework proposal creation for framework development  
**PROPOSAL CREATION**: Creates structured framework proposals in AxiomFramework/Proposals/Active/
**USER WORKFLOW**: Framework proposals for user review, revision, and approval before implementation
**INTEGRATION**: Workflow integration with FrameworkDevelopment/DEVELOP.md and TRACKING progress monitoring

**Use FrameworkDevelopment/@PLAN for strategic framework development planning with structured proposal creation and user approval workflow.**