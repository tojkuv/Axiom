# Axiom Framework: Development Planning Command

**Central planning coordination for the three-cycle development system**

## 🤖 Automated Mode Trigger

**When human sends**: `@PLAN d` | `@PLAN i` | `@PLAN r`
**Action**: Automatically enter ultrathink mode and execute planning for next cycle

**Enhanced Process**:
1. **Read PLAN.md** → Load this complete planning guide with roadmap health management protocols
2. **Check ROADMAP.md** → Assess current status, completed work, and roadmap health (size, clutter, navigation)
3. **Archive Management** → Move completed phases/cycles to archives, preserve all detail, maintain <300 line target
4. **Update Progress** → Mark completed tasks as ✅ and optimize current priority visibility
5. **Plan Next Cycle** → Identify tasks for next development cycle based on clean, focused roadmap
6. **Update ROADMAP.md** → Update active priorities, maintain health targets, ensure forward-looking focus

## 🎯 PLAN Mode Mission

**Primary Focus**: Coordinate three-cycle development system and maintain unified roadmap as single source of truth.

**Enhanced Responsibility**: PLAN.md is the **Roadmap Health Manager** - maintaining roadmap cleanliness, archiving completed work, and ensuring current/future priorities remain prominently visible.

**Philosophy**: Systematic planning prevents development drift, ensures progress tracking, maintains strategic focus, AND keeps the roadmap clean and forward-looking rather than accumulating historical clutter.

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

### **Integration with PROPOSE.md**
**Strategic Improvement Coordination**: PROPOSE.md provides comprehensive strategic analysis and improvement proposals that can influence PLAN.md decisions.

**When to Use PROPOSE**:
- Major milestone completion requiring strategic assessment
- Innovation opportunity identification and evaluation  
- Architectural rethinking and optimization needs
- Process improvement and development velocity enhancement

**PROPOSE → PLAN Flow**:
1. **PROPOSE.md** → Generates strategic improvement proposals
2. **User Selection** → User chooses which proposals to implement
3. **PLAN.md Integration** → Approved proposals influence next sprint planning and priority adjustments
4. **Implementation Coordination** → PLAN.md coordinates proposal implementation across DEVELOP/INTEGRATE/REFACTOR cycles

## 🧹 ROADMAP HEALTH MANAGEMENT

**PLAN.md Enhanced Responsibility**: As the Roadmap Health Manager, PLAN.md maintains a clean, forward-looking roadmap focused on current and upcoming work, not historical accumulation.

### **Roadmap Health Targets**
- **Active Content**: <300 lines total roadmap size
- **Navigation Speed**: <30 seconds to find current sprint status  
- **Decision Efficiency**: <2 minutes to plan next cycle from clean roadmap
- **Historical Access**: All completed work preserved but archived, not cluttering active planning

### **Core Roadmap Maintenance Operations**

#### **Phase A: Roadmap Health Assessment**
1. **Size Analysis** → Check if ROADMAP.md exceeds 300 lines or clutters current priorities
2. **Historical Content Review** → Identify completed phases/cycles ready for archival
3. **Navigation Efficiency Check** → Ensure current sprint and priorities are immediately visible
4. **Cleanup Opportunity Identification** → Find redundant, outdated, or overly detailed historical content

#### **Phase B: Archive Management** 
1. **Create Archive Documents** → Move completed phases to `/Documentation/Archive/` with comprehensive detail preservation
2. **Archive Navigation Updates** → Ensure archived content remains accessible through clear links
3. **Historical Summarization** → Replace detailed completed sections with concise summaries + archive links
4. **Learning Preservation** → Maintain important discoveries and patterns in accessible archive format

#### **Phase C: Current Priority Optimization**
1. **Prominent Current Sprint** → Ensure active work is the first thing users see
2. **Clear Priority Queue** → Make next 2-3 priorities immediately obvious for rapid planning
3. **Completed Priority Removal** → Archive achieved priorities, advance priority queue
4. **Decision-Making Optimization** → Structure roadmap for rapid cycle coordination

#### **Phase D: Roadmap Quality Validation**
1. **Size Compliance** → Verify roadmap remains <300 lines and navigable
2. **Content Focus** → Confirm roadmap emphasizes current/future work over historical achievements
3. **Archive Integrity** → Validate all archived content is properly linked and accessible
4. **Planning Efficiency** → Test that clean roadmap enables faster cycle selection

### **Archive Strategy and Organization**

#### **Archive File Structure**
```
/Documentation/Archive/
├── PHASE_1_2_FOUNDATION_ARCHIVE.md          # Detailed Phase 1-2 achievements
├── DEVELOP_DELIVERABLES_ARCHIVE.md          # Historical development achievements  
├── INTEGRATE_DELIVERABLES_ARCHIVE.md        # Historical integration results
├── REFACTOR_DELIVERABLES_ARCHIVE.md         # Historical organization work
├── QUARTERLY_ROADMAP_SNAPSHOTS/             # Periodic roadmap state preservation
└── ARCHIVE_NAVIGATION.md                    # Master index for all archived content
```

#### **Archive Content Principles**
- **Complete Preservation**: All historical detail maintained in archives
- **Enhanced Organization**: Archived content better organized than original
- **Searchable Structure**: Archives organized for easy reference and discovery
- **Living Documents**: Archives updated when relevant to current work

#### **Roadmap Summary Replacement Pattern**
```markdown
## Instead of 50+ lines of detailed historical deliverables:

**DEVELOP Phases 1-2** ✅ COMPLETED (Archived)
- Foundation infrastructure and enhanced APIs implemented  
- [Complete Development History](../Documentation/Archive/DEVELOP_DELIVERABLES_ARCHIVE.md)

**Current Phase**: Phase 3 Advanced Framework Patterns 🔄
- ContextFactory implementation in progress
- AxiomIntelligence concrete actor development  
- Comprehensive test suite establishment
```

### **Command Mode Separation of Concerns**

#### **What PLAN.md DOES (Roadmap Health Manager)**
- ✅ **Current Sprint Management**: Updates CURRENT SPRINT STATUS with new cycle coordination
- ✅ **Priority Queue Management**: Maintains UPCOMING PRIORITIES based on cycle completions
- ✅ **Roadmap Cleanup**: Archives completed work, maintains <300 line target
- ✅ **Historical Organization**: Ensures completed work is preserved but not cluttering
- ✅ **Planning Coordination**: Traditional cycle planning based on clean, focused roadmap

#### **What PLAN.md DOES NOT DO**
- ❌ **Framework Implementation**: No coding, no technical development work
- ❌ **Integration Testing**: No AxiomTestApp validation or performance measurement
- ❌ **Documentation Organization**: No technical docs structure (that's REFACTOR.md)
- ❌ **Strategic Analysis**: No strategic proposals (that's PROPOSE.md)

#### **What Other Modes DO NOT DO**
- **DEVELOP.md**: ❌ No roadmap cleanup, ❌ No priority management, ❌ No cycle planning
- **INTEGRATE.md**: ❌ No roadmap updates, ❌ No sprint coordination, ❌ No historical archival  
- **REFACTOR.md**: ❌ No roadmap maintenance, ❌ No sprint planning, ❌ No priority management
- **PROPOSE.md**: ❌ No direct roadmap changes, ❌ No cycle coordination, ❌ No implementation

## 📋 Enhanced Planning Workflow

### **Phase 1: Deliverables Assessment**
1. **Read CURRENT SPRINT STATUS** → Understand what sprint just completed
2. **Check DEVELOP DELIVERABLES** → Read latest completed framework work and impact metrics
3. **Check INTEGRATE DELIVERABLES** → Read latest validation results and real-world testing
4. **Check REFACTOR DELIVERABLES** → Read latest organizational improvements and efficiency gains
5. **Assess Blockers** → Identify any issues preventing next cycle selection

### **Phase 2: Task Planning**
1. **Select Next Cycle Focus** → Choose appropriate development cycle (d/i/r)
2. **Identify Priority Tasks** → Select high-impact tasks for next cycle
3. **Plan Dependencies** → Ensure prerequisite work is complete
4. **Estimate Effort** → Gauge complexity and time requirements

### **Phase 3: Roadmap Health Management** (NEW - Enhanced PLAN.md Responsibility)
1. **Execute Roadmap Health Assessment** → Check roadmap size, navigation efficiency, historical clutter
2. **Archive Completed Work** → Move finished phases/cycles to organized archives with preservation of all detail
3. **Optimize Current Priority Visibility** → Ensure active sprint and next priorities are prominently featured
4. **Maintain Size Compliance** → Keep ROADMAP.md <300 lines focused on current/future work

### **Phase 4: Sprint Planning & Coordination**
1. **Update CURRENT SPRINT STATUS** → Define new sprint based on deliverables assessment and clean roadmap
2. **Adjust UPCOMING PRIORITIES** → Reorder priority queue based on cycle completions and strategic alignment
3. **Plan Sprint Success Criteria** → Define measurable goals for next cycle with clear validation
4. **Document Sprint Rationale** → Record why this cycle/sprint was selected and planning decisions

### **Phase 5: Next Cycle Preparation & Validation**
1. **Validate Roadmap Health** → Confirm roadmap remains clean, navigable, and decision-optimized
2. **Prepare Mode Transition** → Ready for next cycle execution with clear roadmap state
3. **Archive Integrity Check** → Ensure all archived content is properly linked and accessible  
4. **Set Cycle Success Criteria** → Define what success looks like for next cycle with performance targets

## 📋 Enhanced ROADMAP.md Management Protocol

**PLAN.md is the ONLY mode that updates CURRENT SPRINT STATUS and UPCOMING PRIORITIES**

**ENHANCED RESPONSIBILITY**: PLAN.md is the **Roadmap Health Manager** - the only mode that maintains roadmap cleanliness, archives completed work, and ensures forward-looking focus.

### **Step 1: Read All Deliverables**
Before planning, read the latest updates from each cycle mode:
- **DEVELOP DELIVERABLES** → What framework work was completed
- **INTEGRATE DELIVERABLES** → What validation and testing was completed
- **REFACTOR DELIVERABLES** → What organizational work was completed

### **Step 2: Execute Roadmap Health Management** (NEW - Enhanced Responsibility)
Before updating sprint status, maintain roadmap health:

#### **Roadmap Health Assessment**
- **Size Check** → Does ROADMAP.md exceed 300 lines? Is navigation >30 seconds?
- **Clutter Analysis** → Are completed phases/cycles cluttering current priorities?
- **Priority Visibility** → Is current sprint immediately visible? Are next priorities clear?

#### **Archive Management Operations**
- **Identify Archive Candidates** → Completed phases, extensive historical deliverables, old cycle results
- **Create Archive Documents** → Move completed content to `/Documentation/Archive/` with full detail preservation
- **Update Archive Navigation** → Ensure archived content remains accessible via clear links
- **Summarize for Roadmap** → Replace detailed sections with concise summaries + archive links

#### **Roadmap Optimization**
- **Prioritize Current Content** → Ensure current sprint and next 2-3 priorities are prominently featured
- **Remove Historical Clutter** → Archive completed priorities, streamline deliverable sections
- **Validate Size Target** → Confirm roadmap is <300 lines and decision-optimized

### **Step 3: Update CURRENT SPRINT STATUS**

**Template for new sprint:**
```markdown
## 🎯 CURRENT SPRINT STATUS

**Active Sprint**: [CYCLE TYPE] [Sprint Name]
**Sprint Owner**: [DEVELOP.md/INTEGRATE.md/REFACTOR.md]  
**Sprint Goal**: [Clear, measurable objective for this sprint]
**Sprint Duration**: [Expected timeframe]
**Next Planning**: PLAN.md will assess deliverables and plan next sprint

### **Active Tasks** 🔄
- 🔄 **[Task 1]**: [Description of work to be completed]
- 🔄 **[Task 2]**: [Description of work to be completed]
- 🔄 **[Task 3]**: [Description of work to be completed]

### **Sprint Success Criteria**
- [ ] [Measurable success criterion 1]
- [ ] [Measurable success criterion 2]
- [ ] [Measurable success criterion 3]
- [ ] [Framework integration requirement]
- [ ] [Performance/quality requirement]
```

### **Step 4: Update UPCOMING PRIORITIES**

**Reorder priorities based on:**
- **Completed deliverables** → What was just finished
- **Discovered requirements** → What the completed cycle revealed
- **Strategic alignment** → What supports framework goals
- **Dependency resolution** → What blocks can now be resolved

**Priority Update Template:**
```markdown
### **Priority [N]: [Priority Name]** [STATUS]
**Current Sprint**: [Which cycle is working on this / Next cycle planned]
**Target**: [What this priority aims to achieve]
**Next**: [What happens after current work / dependencies]
```

### **Examples of Sprint Planning**

**Example 1: After DEVELOP Phase 2 Completes**
```markdown
**Active Sprint**: INTEGRATE Phase 2 Validation
**Sprint Owner**: INTEGRATE.md  
**Sprint Goal**: Validate @AxiomClient macro and type-safe patterns in AxiomTestApp
**Sprint Duration**: Week 3-4 of Developer Experience Enhancement
**Next Planning**: PLAN.md will assess integration results and plan Phase 3 or next priority

### **Active Tasks** 🔄
- 🔄 **@AxiomClient Macro Testing**: Validate 75% boilerplate reduction in complex scenarios
- 🔄 **Type-Safe Access Validation**: Confirm error prevention in multi-domain configurations
- 🔄 **Performance Measurement**: Ensure enhanced APIs maintain <5ms targets
```

**Example 2: After Major Integration Discovery**
```markdown
**Active Sprint**: DEVELOP Critical Fix Implementation
**Sprint Owner**: DEVELOP.md
**Sprint Goal**: Address integration limitations discovered in complex scenarios
**Sprint Duration**: Week 1-2 Emergency Enhancement
**Next Planning**: PLAN.md will assess fixes and plan continued integration testing

### **Active Tasks** 🔄
- 🔄 **Memory Leak Fix**: Resolve state binding memory issues in multi-domain scenarios
- 🔄 **Performance Optimization**: Improve client discovery performance in complex configurations
- 🔄 **API Enhancement**: Add missing convenience methods for discovered usage patterns
```

### **Decision Matrix for Next Cycle Selection**

**Choose DEVELOP when:**
- Integration testing reveals framework limitations
- New framework features needed for strategic goals
- Performance targets need framework-level optimization
- Core architecture needs enhancement

**Choose INTEGRATE when:**
- Framework features ready for real-world validation
- Developer experience needs measurement and refinement
- Performance needs validation in complex scenarios
- Usage patterns need discovery and documentation

**Choose REFACTOR when:**
- Major development phase completion needs archival
- Documentation organization needs improvement
- Development environment needs optimization
- Cross-system consistency needs validation

### **Critical Rules for PLAN.md Updates**
- ✅ **Only PLAN.md updates CURRENT SPRINT** and UPCOMING PRIORITIES
- ✅ **Read ALL deliverable sections** before making planning decisions
- ✅ **Base decisions on concrete deliverables** not assumptions
- ✅ **Define measurable success criteria** for every sprint
- ✅ **Document planning rationale** for future reference

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

**PLANNING STATUS**: Comprehensive four-command coordination system  
**ROADMAP INTEGRATION**: Single source of truth for all development planning  
**AUTOMATED EXECUTION**: Ready for `@PLAN d|i|r` command with ultrathink  
**STRATEGIC INTEGRATION**: Coordinates with `@PROPOSE` for continuous improvement  
**CYCLE COORDINATION**: Seamless workflow between DEVELOP, INTEGRATE, REFACTOR, and PROPOSE