# Axiom Framework: Unified Planning, Revision & Approval System

**Intelligent, branch-aware proposal lifecycle management with integrated planning, revision, and approval capabilities**

## 🤖 Automated Mode Trigger

**When human sends**: `@PLAN [mode] [options]`
**Action**: Automatically enter ultrathink mode and execute unified proposal lifecycle management

**Workstation Guidelines**: All command executions follow workstation standards defined in `@Commands/WORKSPACE.md`

## 🎯 Unified Command Modes

### **📋 Planning Mode** (Default)
- **`@PLAN [d|i|m]`** → Generate branch-aware proposals and plans
- **`@PLAN`** → Auto-detect branch context and execute planning

### **✏️ Revision Mode** 
- **`@PLAN revise [proposal-file] [instructions]`** → Revise proposals based on feedback
- **`@PLAN revise [proposal-file]`** → Interactive revision with guided feedback
- **`@PLAN revise list`** → Show all active proposals available for revision

### **✅ Approval Mode**
- **`@PLAN approve [proposal-file]`** → Approve and integrate proposals into roadmap
- **`@PLAN approve list`** → Show all proposals ready for approval

### **📊 Status Mode**
- **`@PLAN status [proposal-file]`** → Show proposal status and revision history
- **`@PLAN status`** → Show overall proposal pipeline status

## 🧠 Core Mission

**Primary Focus**: Complete proposal lifecycle management from initial planning through revision to final approval and integration

**Revolutionary Integration**: Single command handles entire proposal workflow, eliminating command switching and improving developer experience

**Core Capabilities**:
- **Branch-Aware Planning**: Automatic branch detection and context-aware proposal generation
- **Intelligent Revision**: Feedback integration and proposal refinement with quality assurance
- **Seamless Approval**: One-step proposal integration into roadmap and documentation
- **Dual-Scope Intelligence**: Framework and integration proposal handling with auto-detection
- **Workflow Continuity**: Unified command maintains context across entire proposal lifecycle

## 🌿 Branch-Aware Execution

### **Development Branch Context (d)**
**Planning Focus**: Framework development and enhancement proposals
**Work Storage**: Plans and proposals in `/AxiomFramework/Documentation/` and `/AxiomFramework/Proposals/`
**Methodology**: References @DEVELOP.md for development approaches and testing standards

### **Integration Branch Context (i)**
**Planning Focus**: Integration testing and validation proposals
**Work Storage**: Plans and proposals in `/AxiomTestApp/Documentation/` and `/AxiomTestApp/Proposals/`
**Methodology**: References @INTEGRATE.md for integration approaches and validation standards

### **Main Branch Context (m)**
**Planning Focus**: Strategic coordination and dual-scope proposal management
**Work Storage**: Proposals in both framework and integration scopes, tracked in `ROADMAP.md`
**Methodology**: Strategic planning with repository intelligence analysis

## 🔄 Unified Workflow Execution

### **Phase 1: Planning & Generation**
1. **Branch Detection** → Auto-detect or use specified branch context
2. **Repository Analysis** → Analyze current project state and progress
3. **Methodology Integration** → Reference appropriate methodology guides (@DEVELOP.md/@INTEGRATE.md)
4. **Proposal Generation** → Create structured proposals in appropriate `/Proposals/Active/` directories
5. **User Presentation** → Present proposal and request feedback or approval

### **Phase 2: Revision & Refinement**
1. **Feedback Analysis** → Analyze revision instructions and feedback requirements
2. **Content Revision** → Apply revisions to proposal content with quality validation
3. **Structure Optimization** → Improve proposal organization, clarity, and completeness
4. **Change Documentation** → Track all changes with rationale and impact analysis
5. **Quality Assurance** → Ensure revised proposal meets standards before approval consideration

### **Phase 3: Approval & Integration**
1. **Proposal Validation** → Verify proposal exists, format correct, completeness check
2. **ROADMAP Integration** → Replace appropriate section (Development/Integration/Refactoring) with proposal content
3. **Documentation Archive** → Move proposal to Documentation/Archive with implementation notes
4. **Proposal Management** → Clean up Active directory and update tracking
5. **Coordination Update** → Confirm integration and provide implementation guidance

## 🎯 Command Examples

### **Planning Examples**
```bash
@PLAN                           # Auto-detect branch and generate proposals
@PLAN d                         # Force development branch planning
@PLAN i                         # Force integration branch planning
@PLAN m                         # Force main branch strategic planning
```

### **Revision Examples**
```bash
@PLAN revise enterprise-proposal.md "reduce timeline from 12 to 8 weeks"
@PLAN revise framework-enhancement.md "add more technical implementation details"
@PLAN revise integration-plan.md      # Interactive revision mode
@PLAN revise list                     # Show all proposals available for revision
```

### **Approval Examples**
```bash
@PLAN approve framework-proposal.md   # Approve framework enhancement proposal
@PLAN approve integration-proposal.md # Approve integration improvement proposal
@PLAN approve list                    # Show all proposals ready for approval
```

### **Status Examples**
```bash
@PLAN status proposal.md              # Show specific proposal status and history
@PLAN status                          # Show overall proposal pipeline status
```

## 🔧 Proposal Types & Categories

### **Planning Categories**
- **Framework Architecture**: Core framework design and implementation proposals
- **Performance Optimization**: Performance improvement and monitoring proposals
- **API Design**: Developer experience and API enhancement proposals
- **Testing Infrastructure**: Test framework and validation system proposals
- **AI Features**: Intelligence system and capability enhancement proposals

### **Revision Categories**
- **Content Revisions**: Scope, technical approach, priority, and resource modifications
- **Structure Revisions**: Format improvements, detail enhancement, section reorganization
- **Strategic Revisions**: Objective refinement, timeline adjustments, risk assessment updates

### **Approval Categories**
- **Framework Proposals**: Override Development Planning section in ROADMAP.md
- **Integration Proposals**: Override Integration Planning section in ROADMAP.md
- **Refactoring Proposals**: Override Refactoring Planning section in ROADMAP.md
- **Strategic Proposals**: Override multiple sections with comprehensive archival

## 🧹 ROADMAP Integration

**PLAN Updates ROADMAP.md**: All proposal lifecycle phases update the live coordination dashboard

**Integration Process**:
- **Planning Phase**: Initial proposal tracking and priority assignment
- **Revision Phase**: Updated proposal status and change tracking
- **Approval Phase**: Section replacement and archive management

**Coordination Benefits**: Single command maintains ROADMAP.md consistency throughout entire proposal lifecycle

## 🛡️ Safety & Quality Features

### **Proposal Protection**
- **Original Preservation**: Original proposal content preserved during revision process
- **Change Tracking**: All changes documented with rationale and impact analysis
- **Rollback Capability**: Ability to rollback to previous proposal versions
- **Approval Gateway**: All proposals require explicit user approval before integration

### **Quality Assurance**
- **Format Validation**: Ensure proposals maintain proper format and structure
- **Content Completeness**: Verify all required sections and information are present
- **Consistency Checking**: Ensure proposals maintain consistency with existing documentation
- **Standards Compliance**: Validate compliance with organizational and technical standards

### **Error Handling**
- **Missing Proposal Detection**: Clear error messages for non-existent proposals
- **Format Validation**: Comprehensive proposal format checking
- **Conflict Identification**: Detect and resolve proposal conflicts
- **Rollback Capability**: Safe rollback for failed operations

## 📊 Proposal Lifecycle Tracking

### **Status Progression**
```markdown
Draft → Active → Under Revision → Ready for Approval → Approved → Integrated → Archived
```

### **Revision History Format**
```markdown
## Revision History
- **v1.0** (2025-05-31): Initial proposal creation
- **v1.1** (2025-05-31): Timeline reduced from 12 to 8 weeks per user feedback
- **v1.2** (2025-05-31): Added technical implementation details section
- **v2.0** (2025-05-31): Major restructure focusing on developer experience
```

### **Integration Documentation**
```markdown
## Integration Record
- **Approved**: 2025-05-31 14:30 UTC
- **Integrated**: ROADMAP.md Development Planning section
- **Archived**: /AxiomFramework/Documentation/Archive/proposal-v2.0.md
- **Implementation Status**: Ready for development cycle initiation
```

## 🔄 System Integration

**Command Coordination**:
- **@PLAN.md**: Unified proposal lifecycle management (this file)
- **@DEVELOP.md**: Development methodology reference
- **@INTEGRATE.md**: Integration methodology reference  
- **@WORKSPACE.md**: Workstation guidelines and command coordination
- **ROADMAP.md**: Live coordination dashboard

**Workstation Integration**: All operations follow workstation standards defined in `@Commands/WORKSPACE.md` for consistency and reliability

## 🎯 Success Criteria

### **Planning Excellence**
- [ ] **Clear Objectives**: Generated proposals have clear, specific, and measurable objectives
- [ ] **Technical Completeness**: All technical details are comprehensive and accurate
- [ ] **Resource Specification**: Resource requirements are clearly defined and realistic
- [ ] **Timeline Realism**: Proposed timelines are realistic and achievable

### **Revision Quality**
- [ ] **Feedback Integration**: User feedback is comprehensively incorporated
- [ ] **Quality Improvement**: Revisions significantly improve proposal quality
- [ ] **Change Documentation**: All changes are clearly documented with rationale
- [ ] **Standards Compliance**: Revised proposals meet all quality standards

### **Approval Efficiency**
- [ ] **Seamless Integration**: Approved proposals integrate smoothly into ROADMAP.md
- [ ] **Documentation Quality**: Archive documentation is complete and well-organized
- [ ] **Coordination Update**: ROADMAP.md accurately reflects approved changes
- [ ] **Implementation Readiness**: Approved proposals are ready for development initiation

## 🤖 Automated Execution Flow

**Command**: `@PLAN [mode] [arguments]`
**Workstation Compliance**: All executions follow `@Commands/WORKSPACE.md` guidelines
**Action**: Intelligent proposal lifecycle management with unified workflow

**Execution Process**:
1. **Mode Detection** → Determine operation type (planning/revision/approval/status)
2. **Context Analysis** → Analyze branch context and repository state
3. **Operation Execution** → Execute specified operation with quality assurance
4. **Documentation Update** → Update ROADMAP.md and maintain proposal tracking
5. **User Communication** → Provide clear status and next step recommendations

---

**PLAN STATUS**: Revolutionary unified proposal lifecycle management system ready for production use ✅  
**CORE FOCUS**: Single command for complete proposal workflow from planning through approval  
**AUTOMATION**: Supports all proposal lifecycle phases with intelligent automation  
**INTEGRATION**: Seamlessly integrates with @DEVELOP.md, @INTEGRATE.md, and @WORKSPACE.md  
**EFFICIENCY**: Unified command eliminates workflow complexity while maintaining full functionality  

**Use @PLAN for comprehensive proposal lifecycle management with branch-aware intelligence and seamless workflow integration.**