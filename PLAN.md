# Axiom Framework: Development Planning Command

**Central planning coordination for the three-cycle development system**

## 🤖 Automated Mode Trigger

**When human sends**: `@PLAN d` | `@PLAN i` | `@PLAN r`
**Action**: Automatically enter ultrathink mode and execute planning for next cycle

**Process**:
1. **Read PLAN.md** → Load this complete planning guide
2. **Check ROADMAP.md** → Assess current status and completed work
3. **Update Progress** → Mark completed tasks as ✅ in ROADMAP.md
4. **Plan Next Cycle** → Identify tasks for next development cycle
5. **Update ROADMAP.md** → Update active priorities and task matrix

## 🎯 PLAN Mode Mission

**Focus**: Coordinate three-cycle development system and maintain unified roadmap as single source of truth.

**Philosophy**: Systematic planning prevents development drift, ensures progress tracking, and maintains strategic focus.

## 🔄 Three-Cycle Planning System

### **PLAN d** → Plan for DEVELOP Cycle
**When Called**: After INTEGRATE or REFACTOR completion
**Purpose**: Plan framework core enhancement and new capabilities
**Focus**: 
- Identify framework limitations discovered through integration
- Plan new protocol implementations
- Design capability system enhancements
- Plan intelligence system improvements

### **PLAN i** → Plan for INTEGRATE Cycle  
**When Called**: After DEVELOP or REFACTOR completion
**Purpose**: Plan real-world validation and API refinement
**Focus**:
- Validate new framework features in AxiomTestApp
- Test API ergonomics and developer experience
- Discover usage patterns and improvement opportunities
- Measure performance and identify optimization needs

### **PLAN r** → Plan for REFACTOR Cycle
**When Called**: After INTEGRATE or DEVELOP completion  
**Purpose**: Plan documentation organization and structural improvements
**Focus**:
- Archive completed development phases
- Reorganize documentation for efficiency
- Prepare structure for next development phases
- Validate cross-system consistency

## 📋 Planning Workflow

### **Phase 1: Progress Assessment**
1. **Read Current ROADMAP.md** → Understand current priorities and status
2. **Identify Completed Work** → Mark tasks that were finished in last cycle
3. **Analyze Discoveries** → Capture learnings and new requirements from completed work
4. **Assess Blockers** → Identify any issues preventing progress

### **Phase 2: Task Planning**
1. **Select Next Cycle Focus** → Choose appropriate development cycle (d/i/r)
2. **Identify Priority Tasks** → Select high-impact tasks for next cycle
3. **Plan Dependencies** → Ensure prerequisite work is complete
4. **Estimate Effort** → Gauge complexity and time requirements

### **Phase 3: Roadmap Updates**
1. **Mark Completed Tasks** → Update ROADMAP.md with ✅ for finished work
2. **Update Active Priorities** → Refresh Priority 1-4 matrix with current focus
3. **Add New Tasks** → Include newly discovered requirements
4. **Update Status** → Reflect current development phase and achievements

### **Phase 4: Next Cycle Preparation**
1. **Document Planning Results** → Record decisions and rationale
2. **Prepare Mode Transition** → Ready for next cycle execution
3. **Validate Roadmap** → Ensure ROADMAP.md accurately reflects current state
4. **Set Success Criteria** → Define what success looks like for next cycle

## 🎯 Planning Priorities by Mode

### **PLAN d** - Development Planning
**Primary Focus**: Framework core enhancement

**Typical Tasks**:
- Implement missing framework APIs discovered in integration
- Enhance performance of critical framework components
- Add new capability types and validation patterns
- Improve intelligence system accuracy and speed
- Implement advanced architectural constraints

**Success Criteria**:
- New framework capabilities implemented and tested
- Performance targets maintained or improved
- API consistency and type safety preserved
- No breaking changes to existing functionality

### **PLAN i** - Integration Planning  
**Primary Focus**: Real-world validation

**Typical Tasks**:
- Test new framework features in AxiomTestApp
- Validate API ergonomics and developer experience
- Measure performance against established targets
- Discover usage patterns and common scenarios
- Identify framework limitations and improvement opportunities

**Success Criteria**:
- AxiomTestApp successfully uses new framework features
- Performance targets validated in real scenarios
- Developer experience improvements documented
- New requirements identified for future development

### **PLAN r** - Refactor Planning
**Primary Focus**: Organization and preparation

**Typical Tasks**:
- Archive completed development phase documentation
- Reorganize code structure for better maintainability
- Update documentation for clarity and consistency
- Prepare development environment for next phase
- Validate cross-system consistency and references

**Success Criteria**:
- Documentation well-organized and navigable
- Code structure supports efficient development
- Development environment optimized
- Historical work properly archived

## 📊 Planning Decision Matrix

### **Coming from DEVELOP → Choose Next**
- **High integration needs** → PLAN i (validate new framework features)
- **Documentation debt** → PLAN r (organize and archive)
- **Continued development** → PLAN d (build on momentum)

### **Coming from INTEGRATE → Choose Next**
- **Framework limitations found** → PLAN d (address discovered issues)
- **Phase completion** → PLAN r (organize and archive)  
- **More validation needed** → PLAN i (continue testing)

### **Coming from REFACTOR → Choose Next**
- **Clean structure ready** → PLAN d (leverage organized foundation)
- **Need validation** → PLAN i (test in real scenarios)
- **More organization needed** → PLAN r (continue cleanup)

## 🔄 ROADMAP.md Update Patterns

### **Progress Tracking Updates**
```markdown
# Mark completed work
- ✅ **Task Name**: Description of completed work
- 🔄 **Task Name**: Work in progress → ✅ **Task Name**: Completed description

# Update priority status  
### **Priority 1: Current Focus** ✅ COMPLETED
### **Priority 2: Next Focus** 🔄 ACTIVE
```

### **Cycle Results Documentation**
```markdown
## 📚 [CYCLE] CYCLE RESULTS

### **[CYCLE] Cycle [N] Completed** ✅ (Brief Description)
**[Context]**: What was discovered or achieved
**Solutions Implemented**:
- ✅ **Achievement 1**: Description
- ✅ **Achievement 2**: Description

**Results**:
- ✅ Specific measurable outcome
- ✅ Validation or proof of success
```

### **Active Priority Matrix Updates**
```markdown
### **Priority 1: [Current Focus]** 🔄 ACTIVE
**Target Cycle**: [DEVELOP/INTEGRATE/REFACTOR]
- 🔄 **Active Task**: Current work description
- ⏳ **Queued Task**: Planned follow-up work

### **Priority 2: [Next Focus]** ⏳ QUEUED
**Target Cycle**: [DEVELOP/INTEGRATE/REFACTOR]
- ⏳ **Planned Task**: Future work description
```

## 🎯 Planning Templates

### **PLAN d** Template
```markdown
## DEVELOP Cycle Planning

### Framework Enhancement Focus
- **Core Systems**: [Capabilities/Intelligence/State/SwiftUI]
- **Performance**: [Targets to achieve]
- **API Design**: [New protocols or improvements]

### Implementation Tasks
1. **High Priority**: [Critical framework needs]
2. **Medium Priority**: [Important enhancements]
3. **Nice to Have**: [Optional improvements]

### Success Criteria
- [ ] Framework builds successfully
- [ ] New features implemented and tested
- [ ] Performance targets maintained
- [ ] No breaking changes introduced
```

### **PLAN i** Template  
```markdown
## INTEGRATE Cycle Planning

### Validation Focus
- **New Features**: [Framework capabilities to test]
- **Performance**: [Metrics to measure]
- **Developer Experience**: [Usability to assess]

### Integration Tasks
1. **Feature Testing**: [Test new framework capabilities]
2. **Performance Validation**: [Measure against targets]
3. **Pattern Discovery**: [Find usage patterns]

### Success Criteria
- [ ] AxiomTestApp successfully integrates new features
- [ ] Performance validated in real scenarios
- [ ] Developer experience improvements documented
- [ ] Framework limitations identified
```

### **PLAN r** Template
```markdown
## REFACTOR Cycle Planning

### Organization Focus
- **Documentation**: [Areas needing cleanup]
- **Code Structure**: [Refactoring needs]
- **Archive**: [Completed work to archive]

### Refactor Tasks
1. **Archive**: [Move completed documentation]
2. **Organize**: [Restructure for efficiency]  
3. **Prepare**: [Ready for next development]

### Success Criteria
- [ ] Documentation well-organized
- [ ] Completed work properly archived
- [ ] Structure supports next development phase
- [ ] Cross-references validated
```

## 🤖 Automated Planning Process

**Planning Command Selection**:
- `@PLAN d` → Plan for framework development cycle
- `@PLAN i` → Plan for integration and validation cycle  
- `@PLAN r` → Plan for refactor and organization cycle

**Automated Workflow**:
1. **Assess Current State** → Read ROADMAP.md and evaluate completed work
2. **Update Progress** → Mark completed tasks as ✅ in roadmap
3. **Plan Next Cycle** → Identify tasks and priorities for chosen cycle
4. **Update Roadmap** → Refresh active priorities and task matrix
5. **Document Results** → Record planning decisions and next steps

**Integration with Development Cycles**:
- **After DEVELOP** → Call `@PLAN i` or `@PLAN r` 
- **After INTEGRATE** → Call `@PLAN d` or `@PLAN r`
- **After REFACTOR** → Call `@PLAN d` or `@PLAN i`

**ROADMAP.md as Single Source of Truth**:
- ONLY PLAN.md updates ROADMAP.md
- All three cycles reference ROADMAP.md for current priorities
- Planning decisions flow through unified roadmap system
- Progress tracking maintained in central location

## 📈 Planning Success Metrics

### **Planning Quality**
- **Task Alignment**: Chosen tasks address current priorities
- **Dependency Management**: Prerequisites satisfied before planning
- **Realistic Scope**: Tasks achievable within cycle timeframe
- **Strategic Focus**: Planning supports long-term framework goals

### **Roadmap Accuracy**
- **Current Status**: ROADMAP.md reflects actual development state
- **Progress Tracking**: Completed work properly marked as ✅
- **Priority Organization**: Active tasks clearly identified
- **Future Planning**: Queued work logically sequenced

### **Cycle Coordination**
- **Smooth Transitions**: Cycles flow naturally from planning
- **Context Preservation**: Important information carries forward
- **Learning Integration**: Discoveries influence future planning
- **Development Velocity**: Planning accelerates rather than slows progress

## 🔄 Example Planning Flows

### **Development → Integration Flow**
```
1. Complete DEVELOP cycle (implement framework features)
2. Call @PLAN i (plan integration testing)
3. Update ROADMAP.md with development achievements
4. Plan integration tasks for new framework features
5. Execute INTEGRATE cycle with focused validation
```

### **Integration → Refactor Flow**  
```
1. Complete INTEGRATE cycle (discover framework usage patterns)
2. Call @PLAN r (plan organization and archival)
3. Update ROADMAP.md with integration discoveries
4. Plan refactor tasks for documentation and structure
5. Execute REFACTOR cycle with efficient organization
```

### **Refactor → Development Flow**
```
1. Complete REFACTOR cycle (organize and archive)
2. Call @PLAN d (plan next framework development)
3. Update ROADMAP.md with organizational achievements  
4. Plan development tasks leveraging clean structure
5. Execute DEVELOP cycle with enhanced foundation
```

## 🎯 Strategic Planning Considerations

### **Framework Maturity Phases**
- **Foundation Phase** ✅ COMPLETE → Focus on stability and validation
- **Enhancement Phase** 🔄 CURRENT → Focus on developer experience and advanced features
- **Maturity Phase** ⏳ FUTURE → Focus on community and ecosystem

### **Long-term Strategic Alignment**
- **Performance Targets**: Ensure all planning supports performance goals
- **Developer Experience**: Prioritize usability and API ergonomics
- **Intelligence Features**: Build toward predictive architecture capabilities
- **Community Readiness**: Prepare for external developer adoption

### **Risk Management in Planning**
- **Technical Debt**: Balance new features with code quality
- **Scope Creep**: Maintain focus on core framework value
- **Integration Complexity**: Ensure real-world usage stays simple
- **Performance Regression**: Validate performance with each cycle

---

**PLANNING STATUS**: Comprehensive three-cycle coordination system  
**ROADMAP INTEGRATION**: Single source of truth for all development planning  
**AUTOMATED EXECUTION**: Ready for `@PLAN d|i|r` command with ultrathink  
**CYCLE COORDINATION**: Seamless workflow between DEVELOP, INTEGRATE, and REFACTOR