# @APPROVE.md - Axiom Application Proposal Approval Command

Application proposal approval command that accepts proposals and prepares development cycles

## Automated Mode Trigger

**When human sends**: `@APPROVE [optional-args]`
**Action**: Enter ultrathink mode and execute application proposal approval workflow

### Usage Modes
- **`@APPROVE`** → Approve available application proposals in AxiomExampleApp/Proposals/WaitingApproval/
- **`@APPROVE proposal`** → Approve specific application proposal by name
- **`@APPROVE review`** → Review and approve application proposals after validation
- **`@APPROVE batch`** → Approve multiple application proposals in sequence

### Application Approval Scope
**Approval Focus**: Application proposal acceptance and development cycle preparation
**Branch Independence**: Works on current branch - no git operations performed
**Proposal Processing**: Processes application proposals from WaitingApproval/ directory
**Development Integration**: Prepares approved proposals for ApplicationProtocols/DEVELOP.md implementation

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: APPROVE commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: APPROVE accepts proposals → Updates TRACKING.md priorities → DEVELOP implements → @CHECKPOINT commits

Work commands operate on current branch without version control:
1. **Proposal Analysis**: Read available proposals from AxiomExampleApp/Proposals/WaitingApproval/
2. **Approval Processing**: Accept proposals and prepare for implementation
3. **TRACKING.md Updates**: Update application development priorities and next actions
4. **Development Preparation**: Prepare approved proposals for implementation workflow
**No Git Operations**: APPROVE commands never commit, push, or merge

## Application Proposal Approval Philosophy

**Core Principle**: Application proposal approval provides structured acceptance of completed proposals, updating development tracking to prepare for systematic implementation cycles. Approval focuses exclusively on proposal acceptance and development preparation.

**Approval Workflow**: @APPROVE processes WaitingApproval/ proposals → Updates TRACKING.md priorities → ApplicationProtocols/DEVELOP.md implements → Progress tracked through development cycle

### 🎯 **Clear Separation of Concerns**
- **APPROVE**: Accepts proposals → Updates TRACKING.md → NO implementation
- **PLAN**: Creates proposals → NO approval decisions
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO approval
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO approval
- **TRACKING**: Central progress store → Updated by APPROVE and other commands → NO command execution

**Quality Standards**: Application proposal approval includes proposal validation, priority assignment, and systematic development preparation

**Technical Focus Only**: Approval strictly focuses on technical proposal acceptance and development preparation. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Application Proposal Approval Methodology

### Phase 1: Application Proposal Analysis
1. **WaitingApproval/ Directory Scan** → Identify available application proposals ready for approval
2. **Proposal Validation** → Validate proposal completeness and technical specification quality
3. **Priority Assessment** → Analyze proposal priority and application development impact
4. **Implementation Readiness** → Assess proposal readiness for application development implementation
5. **Framework Integration Analysis** → Understand framework integration requirements and dependencies
6. **User Experience Assessment** → Evaluate user experience impact and implementation requirements

### Phase 2: Application Proposal Approval
1. **Proposal Acceptance** → Accept application proposals for implementation
2. **Priority Assignment** → Assign implementation priorities based on proposal analysis
3. **TRACKING.md Integration** → Update application development tracking with approved proposals
4. **Development Planning** → Prepare approved proposals for application development cycle execution
5. **Implementation Coordination** → Coordinate proposal implementation with application development workflow

### Phase 3: Application Development Preparation
1. **Development Cycle Setup** → Prepare application development cycle for approved proposals
2. **Progress Tracking Integration** → Integrate approved proposals into application tracking system
3. **Implementation Roadmap** → Create implementation roadmap for application development execution
4. **Quality Gate Preparation** → Prepare quality validation for proposal implementation
5. **Coordination Updates** → Update application development coordination for approved proposals

## Application Proposal Approval Process

### Application Proposals Processing (AxiomExampleApp/Proposals/)
**Source Directory**: WaitingApproval/ → Application proposals ready for approval
**Target Integration**: TRACKING.md → Application development priority and progress tracking
**Implementation Flow**: Approved proposals → ApplicationProtocols/DEVELOP.md execution
**Archive Management**: Completed proposals → Archive/ directory for reference

### Application Proposal Lifecycle Management

#### Application Proposal Approval States
- **WaitingApproval**: Application proposals ready for approval review
- **Under Review**: Proposals being analyzed for approval decision
- **Approved**: Proposals accepted and integrated into application development tracking
- **In Development Queue**: Approved proposals prepared for implementation
- **Development Ready**: Proposals ready for ApplicationProtocols/DEVELOP.md execution

#### Application Approval Workflow Integration
1. **ApplicationProtocols/@APPROVE** → Processes application proposals from AxiomExampleApp/Proposals/WaitingApproval/
2. **Proposal Validation** → Validates proposal quality and implementation readiness
3. **TRACKING.md Updates** → Updates ApplicationProtocols/TRACKING.md with approved proposal priorities
4. **Development Preparation** → Prepares approved proposals for application development cycle execution
5. **ApplicationProtocols/@DEVELOP** → Implements approved proposals using updated tracking priorities
6. **ApplicationProtocols/@CHECKPOINT** → Completes implementation and archives completed proposals

## Application Approval Command Execution

**Command**: `@APPROVE [proposal|review|batch]`
**Action**: Execute comprehensive application proposal approval workflow with development preparation

### 🔄 **Approval Execution Process**

**CRITICAL**: APPROVE commands work on current branch state - NO git operations

```bash
# Navigate to application workspace
echo "🔄 Entering application development workspace..."
cd application-workspace/ || {
    echo "❌ Application workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Approval workflow (NO git operations)
echo "✅ Application Proposal Approval Execution"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "🔗 Framework access: AxiomFramework-dev → ../framework-workspace/AxiomFramework"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "✅ Approval ready - proceeding in application workspace"
```

**Automated Approval Process**:
1. **WaitingApproval/ Analysis** → Scan AxiomExampleApp/Proposals/WaitingApproval/ for available proposals
2. **Proposal Validation** → Validate proposal completeness and technical specification quality
3. **Priority Assessment** → Analyze proposal priorities and implementation dependencies
4. **Approval Processing** → Accept proposals for application development implementation
5. **TRACKING.md Updates** → Update ApplicationProtocols/TRACKING.md with approved proposal priorities
6. **Development Preparation** → Prepare approved proposals for application development cycle execution
7. **Implementation Coordination** → Coordinate proposal implementation with application development workflow
**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Application Approval Execution Examples**:
- `@APPROVE` → Approve available application proposals and update development tracking
- `@APPROVE proposal` → Approve specific application proposal by name
- `@APPROVE review` → Review and approve application proposals after validation
- `@APPROVE batch` → Approve multiple application proposals in sequence

## Application Approval Standards

### Application Proposal Validation Standards
- **Technical Completeness**: Comprehensive technical specifications and implementation approaches
- **Implementation Readiness**: Clear implementation steps and success criteria
- **Quality Standards**: Proposal meets application quality and documentation requirements
- **Framework Integration**: Proper framework usage and integration patterns
- **User Experience Design**: Clear user interface and interaction specifications
- **Testing Strategy**: Comprehensive testing approach and validation procedures

### Application Development Preparation Standards
- **Priority Assignment**: Clear development priorities based on proposal analysis
- **Implementation Planning**: Systematic implementation approach with defined phases
- **Resource Assessment**: Development resource requirements and timeline estimation
- **Framework Dependency**: Framework integration requirements and dependency coordination
- **User Experience Validation**: User interface and interaction validation requirements
- **Progress Tracking**: Integration with TRACKING.md for development monitoring

## Application Approval Workflow Integration

**Approval Purpose**: Systematic application proposal acceptance and development cycle preparation
**Development Integration**: Approved proposals integrated into ApplicationProtocols/DEVELOP.md workflow
**Progress Tracking**: Proposal implementation progress tracked through ApplicationProtocols/TRACKING.md
**Archive Management**: Completed proposals archived for reference and documentation
**Quality Assurance**: Proposal validation ensures implementation readiness and quality standards

## Application Approval Coordination

**Proposal Processing**: Processes application proposals from AxiomExampleApp/Proposals/WaitingApproval/ directory
**Development Integration**: Approved proposals integrated into application development workflow
**Tracking Updates**: TRACKING.md updates prepare development cycle with approved proposal priorities
**Implementation Coordination**: Coordination with ApplicationProtocols/DEVELOP.md for systematic implementation
**Archive Management**: Completed proposal lifecycle management with archive coordination

---

**APPLICATION APPROVAL COMMAND STATUS**: Application proposal approval command with development preparation capabilities
**CORE FOCUS**: Systematic application proposal acceptance and development cycle preparation  
**APPROVAL SCOPE**: Application proposal processing, validation, and development integration
**TRACKING INTEGRATION**: TRACKING.md updates for development cycle preparation and progress monitoring
**WORKFLOW INTEGRATION**: Approval integration with planning, development, and completion workflows

**Use ApplicationProtocols/@APPROVE for systematic application proposal approval and development cycle preparation.**