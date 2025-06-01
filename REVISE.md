# @REVISE.md - Axiom Framework Proposal Revision System

## 🔧 **Intelligent Proposal Revision & Refinement**

**Central system for revising and refining proposals based on feedback before final approval**

## 🤖 Automated Mode Trigger

**When human sends**: `@REVISE [proposal-file] [revision-instructions]`
**Action**: Automatically enter ultrathink mode and revise the specified proposal based on feedback

### 🎯 **Usage Modes**
- **`@REVISE proposal.md "feedback here"`** → Revise specific proposal with given feedback
- **`@REVISE proposal.md`** → Interactive revision mode with guided feedback collection
- **`@REVISE list`** → Show all active proposals available for revision
- **`@REVISE status proposal.md`** → Show revision history and current status

### 🧠 **Dual-Scope Revision Intelligence**
**Framework Proposals**: Revise framework enhancement proposals in `/AxiomFramework/Proposals/Active/`
**Integration Proposals**: Revise integration improvement proposals in `/AxiomTestApp/Proposals/Active/`
**Auto-Detection**: System automatically detects which proposal scope contains the specified file

## 🎯 Core Mission

**Primary Focus**: Proposal refinement engine that incorporates feedback and improves proposals before final approval

**Core Capabilities**:
- **Feedback Integration**: Incorporate user feedback and revision requests into proposal content
- **Scope-Aware Revision**: Handle both framework and integration proposal revisions appropriately
- **Revision Tracking**: Maintain revision history and track changes over iterations
- **Quality Assurance**: Ensure revised proposals meet standards before approval consideration

## 🔧 Revision Categories

### **Content Revisions**
- **Scope Changes**: Modify implementation scope, timeline, or deliverables
- **Technical Adjustments**: Revise technical approach, architecture, or implementation details
- **Priority Updates**: Adjust priority levels, dependencies, or scheduling
- **Resource Modifications**: Change resource requirements, team assignments, or budget considerations

### **Structure Revisions**
- **Format Improvements**: Enhance proposal structure, organization, and readability
- **Detail Enhancement**: Add missing details, clarify ambiguous sections, expand explanations
- **Section Reorganization**: Restructure proposal sections for better flow and understanding
- **Documentation Alignment**: Ensure proposal aligns with existing documentation and standards

### **Strategic Revisions**
- **Objective Refinement**: Clarify or modify proposal objectives and success criteria
- **Timeline Adjustments**: Revise implementation timeline, milestones, and delivery schedules
- **Risk Assessment**: Update risk analysis, mitigation strategies, and contingency planning
- **Impact Analysis**: Refine benefit analysis, ROI calculations, and expected outcomes

## 🔄 Revision Workflow

### **Phase 1: Revision Analysis**
1. **Proposal Validation** → Verify proposal exists and is in Active directory
2. **Current State Assessment** → Analyze current proposal content and structure
3. **Feedback Integration** → Incorporate user feedback and revision requirements
4. **Scope Impact Analysis** → Assess impact of revisions on overall project scope

### **Phase 2: Content Revision**
1. **Content Updates** → Apply requested changes to proposal content
2. **Structure Optimization** → Improve proposal organization and clarity
3. **Technical Refinement** → Enhance technical details and implementation approach
4. **Quality Validation** → Ensure revised proposal meets quality standards

### **Phase 3: Revision Documentation**
1. **Change Tracking** → Document all changes made during revision process
2. **Revision History** → Maintain comprehensive revision history and rationale
3. **Impact Assessment** → Document impact of revisions on timeline, resources, and scope
4. **Approval Readiness** → Prepare revised proposal for potential approval consideration

## 🤖 Automated Revision Execution

**Command**: `@REVISE [proposal-file] [revision-instructions]`
**Action**: Intelligent proposal revision with feedback integration

**Execution Flow**:
1. **Proposal Detection** → Auto-detect proposal scope and locate file
2. **Feedback Analysis** → Analyze revision instructions and feedback
3. **Content Revision** → Apply revisions to proposal content
4. **Quality Assurance** → Validate revised proposal quality and completeness
5. **Documentation Update** → Update revision history and prepare for approval

**Revision Examples**:
- `@REVISE enterprise-proposal.md "reduce timeline from 12 to 8 weeks"`
- `@REVISE framework-enhancement.md "add more technical implementation details"`
- `@REVISE integration-plan.md "focus more on developer experience"`
- `@REVISE strategic-proposal.md "clarify success criteria and metrics"`

## 📋 Revision Types

### **Quick Revisions**
**Timeline Adjustments**: Modify implementation schedules and milestone dates
**Priority Changes**: Adjust priority levels and dependency relationships
**Scope Refinements**: Minor scope adjustments and deliverable modifications
**Resource Updates**: Update resource requirements and team assignments

### **Comprehensive Revisions**
**Technical Overhauls**: Major changes to technical approach and implementation strategy
**Structural Reorganization**: Complete reorganization of proposal structure and content
**Objective Redefinition**: Fundamental changes to proposal objectives and success criteria
**Strategic Realignment**: Major strategic changes affecting multiple project areas

### **Quality Improvements**
**Clarity Enhancements**: Improve explanation clarity and reduce ambiguity
**Detail Expansion**: Add missing technical details and implementation specifics
**Documentation Alignment**: Ensure consistency with existing documentation and standards
**Standards Compliance**: Ensure proposal meets all organizational and technical standards

## 🎯 Revision Success Criteria

### **Content Quality**
- [ ] **Clear Objectives**: Proposal objectives are clear, specific, and measurable
- [ ] **Technical Completeness**: All technical details are comprehensive and accurate
- [ ] **Implementation Clarity**: Implementation approach is clear and feasible
- [ ] **Resource Specification**: Resource requirements are clearly defined and realistic

### **Structure Excellence**
- [ ] **Logical Organization**: Proposal is well-organized with logical flow
- [ ] **Comprehensive Coverage**: All necessary topics and sections are covered
- [ ] **Professional Presentation**: Proposal is professionally formatted and presented
- [ ] **Documentation Consistency**: Proposal aligns with existing documentation standards

### **Strategic Alignment**
- [ ] **Objective Alignment**: Proposal objectives align with overall project goals
- [ ] **Priority Consistency**: Proposal priority is appropriate for current project needs
- [ ] **Timeline Realism**: Proposed timeline is realistic and achievable
- [ ] **Impact Clarity**: Expected impact and benefits are clearly articulated

## 🔄 Integration with Approval Process

### **Revision → Approval Workflow**
1. **@PLAN generates proposal** → Initial proposal creation and user presentation
2. **User provides feedback** → Feedback collection and revision requirements
3. **@REVISE refines proposal** → Incorporate feedback and improve proposal quality
4. **User approves revisions** → Confirmation that revisions meet expectations
5. **@APPROVE integrates proposal** → Final approval and integration into roadmap

### **Proper Separation of Concerns**
- **@PLAN**: Initial proposal generation and user approval request
- **@REVISE**: Proposal refinement based on feedback and requirements
- **@APPROVE**: Final confirmation and integration into development coordination

### **Quality Gates**
- **Post-Planning**: User approval required before any implementation
- **Post-Revision**: User confirmation required before approval consideration
- **Post-Approval**: Final confirmation before roadmap integration and documentation updates

## 🛡️ Safety Features

### **Revision Protection**
- **Original Preservation**: Original proposal content preserved during revision process
- **Change Tracking**: All changes documented with rationale and impact analysis
- **Rollback Capability**: Ability to rollback to previous proposal versions
- **Approval Gateway**: Revised proposals require explicit user approval before acceptance

### **Quality Assurance**
- **Format Validation**: Ensure revised proposals maintain proper format and structure
- **Content Completeness**: Verify all required sections and information are present
- **Consistency Checking**: Ensure revisions maintain consistency with existing documentation
- **Standards Compliance**: Validate compliance with organizational and technical standards

## 📊 Revision Tracking

### **Revision History**
```markdown
## Revision History
- **v1.0** (2025-05-31): Initial proposal creation
- **v1.1** (2025-05-31): Timeline reduced from 12 to 8 weeks per user feedback
- **v1.2** (2025-05-31): Added technical implementation details section
- **v2.0** (2025-05-31): Major restructure focusing on developer experience
```

### **Change Documentation**
```markdown
## Changes Made
- **Timeline Adjustment**: Reduced implementation timeline from 12 to 8 weeks
- **Technical Detail Enhancement**: Added comprehensive technical implementation section
- **Focus Refinement**: Shifted primary focus to developer experience optimization
- **Success Criteria Update**: Refined success criteria based on revised objectives
```

### **Impact Assessment**
```markdown
## Revision Impact
- **Timeline Impact**: 4-week reduction improves delivery schedule
- **Resource Impact**: Reduced timeline requires additional resource allocation
- **Scope Impact**: Focused scope improves deliverable quality and clarity
- **Risk Impact**: Accelerated timeline increases implementation risk
```

---

**REVISE STATUS**: Comprehensive proposal revision system ready for feedback integration ✅  
**CORE FOCUS**: Proposal refinement and quality improvement through structured revision process  
**AUTOMATION**: Supports `@REVISE [proposal-file] [revision-instructions]` with intelligent feedback integration  
**INTEGRATION**: Works seamlessly with @PLAN (proposal generation) and @APPROVE (final confirmation) systems  

**Use @REVISE to refine proposals based on feedback before final approval - ensuring quality and alignment with project requirements.**