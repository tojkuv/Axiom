# @APPROVE.md - Axiom Framework Proposal Approval Command

Framework proposal approval command that accepts proposals and prepares development cycles

## Automated Mode Trigger

**When human sends**: `@APPROVE [optional-args]`
**Action**: Enter ultrathink mode and execute framework proposal approval workflow

### Usage Modes
- **`@APPROVE`** → Approve available framework proposals in AxiomFramework/Proposals/WaitingApproval/
- **`@APPROVE proposal`** → Approve specific framework proposal by name
- **`@APPROVE review`** → Review and approve framework proposals after validation
- **`@APPROVE batch`** → Approve multiple framework proposals in sequence

### Framework Approval Scope
**Approval Focus**: Framework proposal acceptance and development cycle preparation
**Branch Independence**: Works on current branch - no git operations performed
**Proposal Processing**: Processes framework proposals from WaitingApproval/ directory
**Development Integration**: Prepares approved proposals for FrameworkProtocols/DEVELOP.md implementation

### 🔄 **Development Workflow Architecture**
**IMPORTANT**: APPROVE commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: APPROVE accepts proposals → Updates TRACKING.md priorities → DEVELOP implements → @CHECKPOINT commits

Work commands operate on current branch without version control:
1. **Proposal Analysis**: Read available proposals from AxiomFramework/Proposals/WaitingApproval/
2. **Approval Processing**: Accept proposals and prepare for implementation
3. **TRACKING.md Updates**: Update framework development priorities and next actions
4. **Development Preparation**: Prepare approved proposals for implementation workflow
**No Git Operations**: APPROVE commands never commit, push, or merge

## Framework Proposal Approval Philosophy

**Core Principle**: Framework proposal approval provides structured acceptance of completed proposals, updating development tracking to prepare for systematic implementation cycles. Approval focuses exclusively on proposal acceptance and development preparation.

**Approval Workflow**: @APPROVE processes WaitingApproval/ proposals → Updates TRACKING.md priorities → FrameworkProtocols/DEVELOP.md implements → Progress tracked through development cycle

### 🎯 **Clear Separation of Concerns**
- **APPROVE**: Accepts proposals → Updates TRACKING.md → NO implementation
- **PLAN**: Creates proposals → NO approval decisions
- **DEVELOP**: Implements approved proposals → Updates TRACKING.md progress → NO approval
- **CHECKPOINT**: Git workflow → Updates TRACKING.md completion → NO approval
- **TRACKING**: Central progress store → Updated by APPROVE and other commands → NO command execution

**Quality Standards**: Framework proposal approval includes proposal validation, priority assignment, and systematic development preparation

**Technical Focus Only**: Approval strictly focuses on technical proposal acceptance and development preparation. No consideration of non-technical aspects (community involvement, adoption, marketing, business strategy, user engagement, etc.)

## Framework Proposal Approval Methodology

### Phase 1: Framework Proposal Analysis
1. **WaitingApproval/ Directory Scan** → Identify available framework proposals ready for approval
2. **Proposal Validation** → Validate proposal completeness and technical specification quality
3. **Priority Assessment** → Analyze proposal priority and development impact
4. **Implementation Readiness** → Assess proposal readiness for development implementation
5. **Dependency Analysis** → Understand proposal dependencies and implementation order
6. **Resource Assessment** → Evaluate development resource requirements and timeline

### Phase 2: Framework Proposal Approval
1. **Proposal Acceptance** → Accept framework proposals for implementation
2. **Priority Assignment** → Assign implementation priorities based on proposal analysis
3. **TRACKING.md Integration** → Update framework development tracking with approved proposals
4. **Development Planning** → Prepare approved proposals for development cycle execution
5. **Implementation Coordination** → Coordinate proposal implementation with development workflow

### Phase 3: Framework Development Preparation
1. **Development Cycle Setup** → Prepare framework development cycle for approved proposals
2. **Progress Tracking Integration** → Integrate approved proposals into tracking system
3. **Implementation Roadmap** → Create implementation roadmap for development execution
4. **Quality Gate Preparation** → Prepare quality validation for proposal implementation
5. **Coordination Updates** → Update development coordination for approved proposals

## Framework Proposal Approval Process

### Framework Proposals Processing (AxiomFramework/Proposals/)
**Source Directory**: WaitingApproval/ → Framework proposals ready for approval
**Target Integration**: TRACKING.md → Development priority and progress tracking
**Implementation Flow**: Approved proposals → FrameworkProtocols/DEVELOP.md execution
**Archive Management**: Completed proposals → Archive/ directory for reference

### Framework Proposal Lifecycle Management

#### Framework Proposal Approval States
- **WaitingApproval**: Framework proposals ready for approval review
- **Under Review**: Proposals being analyzed for approval decision
- **Approved**: Proposals accepted and integrated into development tracking
- **In Development Queue**: Approved proposals prepared for implementation
- **Development Ready**: Proposals ready for FrameworkProtocols/DEVELOP.md execution

#### Framework Approval Workflow Integration
1. **FrameworkProtocols/@APPROVE** → Processes framework proposals from AxiomFramework/Proposals/WaitingApproval/
2. **Proposal Validation** → Validates proposal quality and implementation readiness
3. **TRACKING.md Updates** → Updates FrameworkProtocols/TRACKING.md with approved proposal priorities
4. **Development Preparation** → Prepares approved proposals for development cycle execution
5. **FrameworkProtocols/@DEVELOP** → Implements approved proposals using updated tracking priorities
6. **FrameworkProtocols/@CHECKPOINT** → Completes implementation and archives completed proposals

## Framework Approval Command Execution

**Command**: `@APPROVE [proposal|review|batch]`
**Action**: Execute comprehensive framework proposal approval workflow with development preparation

### 🔄 **Approval Execution Process**

**CRITICAL**: APPROVE commands work on current branch state - NO git operations

```bash
# Navigate to framework workspace
echo "🔄 Entering framework development workspace..."
cd framework-workspace/ || {
    echo "❌ Framework workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Approval workflow (NO git operations)
echo "✅ Framework Proposal Approval Execution"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
echo "✅ Approval ready - proceeding in framework workspace"
```

**Automated Approval Process**:
1. **WaitingApproval/ Analysis** → Scan AxiomFramework/Proposals/WaitingApproval/ for available proposals
2. **Proposal Validation** → Validate proposal completeness and technical specification quality
3. **Priority Assessment** → Analyze proposal priorities and implementation dependencies
4. **Approval Processing** → Accept proposals for development implementation
5. **TRACKING.md Updates** → Update FrameworkProtocols/TRACKING.md with approved proposal priorities
6. **Development Preparation** → Prepare approved proposals for development cycle execution
7. **Implementation Coordination** → Coordinate proposal implementation with development workflow
**No Git Operations**: All version control handled by @CHECKPOINT commands only


**Framework Approval Execution Examples**:
- `@APPROVE` → Approve available framework proposals and update development tracking
- `@APPROVE proposal` → Approve specific framework proposal by name
- `@APPROVE review` → Review and approve framework proposals after validation
- `@APPROVE batch` → Approve multiple framework proposals in sequence

## Framework Approval Standards

### Framework Proposal Validation Standards
- **Technical Completeness**: Comprehensive technical specifications and implementation approaches
- **Implementation Readiness**: Clear implementation steps and success criteria
- **Quality Standards**: Proposal meets framework quality and documentation requirements
- **Architecture Compliance**: Adherence to framework architectural constraints and patterns
- **Testing Strategy**: Comprehensive testing approach and validation procedures
- **Integration Requirements**: Clear integration with existing framework components

### Framework Development Preparation Standards
- **Priority Assignment**: Clear development priorities based on proposal analysis
- **Implementation Planning**: Systematic implementation approach with defined phases
- **Resource Assessment**: Development resource requirements and timeline estimation
- **Dependency Management**: Implementation order and dependency coordination
- **Quality Gates**: Validation checkpoints and success criteria definition
- **Progress Tracking**: Integration with TRACKING.md for development monitoring

## Framework Approval Workflow Integration

**Approval Purpose**: Systematic framework proposal acceptance and development cycle preparation
**Development Integration**: Approved proposals integrated into FrameworkProtocols/DEVELOP.md workflow
**Progress Tracking**: Proposal implementation progress tracked through FrameworkProtocols/TRACKING.md
**Archive Management**: Completed proposals archived for reference and documentation
**Quality Assurance**: Proposal validation ensures implementation readiness and quality standards

## Framework Approval Coordination

**Proposal Processing**: Processes framework proposals from AxiomFramework/Proposals/WaitingApproval/ directory
**Development Integration**: Approved proposals integrated into framework development workflow
**Tracking Updates**: TRACKING.md updates prepare development cycle with approved proposal priorities
**Implementation Coordination**: Coordination with FrameworkProtocols/DEVELOP.md for systematic implementation
**Archive Management**: Completed proposal lifecycle management with archive coordination

---

**FRAMEWORK APPROVAL COMMAND STATUS**: Framework proposal approval command with development preparation capabilities
**CORE FOCUS**: Systematic framework proposal acceptance and development cycle preparation  
**APPROVAL SCOPE**: Framework proposal processing, validation, and development integration
**TRACKING INTEGRATION**: TRACKING.md updates for development cycle preparation and progress monitoring
**WORKFLOW INTEGRATION**: Approval integration with planning, development, and completion workflows

**Use FrameworkProtocols/@APPROVE for systematic framework proposal approval and development cycle preparation.**