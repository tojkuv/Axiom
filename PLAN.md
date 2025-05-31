# Axiom Framework: Multi-Terminal Development Planning Command

**Central planning coordination for three simultaneous Claude Code terminals**

## 🤖 Automated Mode Trigger

**When human sends**: `@PLAN`
**Action**: Automatically enter ultrathink mode and execute terminal-aware planning

**Enhanced Process**:
1. **Detect Terminal Context** → Determine which terminal: main (refactor), development (framework), integration (test app)
2. **Read PLAN.md** → Load this complete planning guide with multi-terminal coordination protocols
3. **Check ROADMAP.md** → Assess current status, completed work, and cross-terminal coordination
4. **Terminal Coordination** → Coordinate with other active terminals through ROADMAP.md
5. **Plan Terminal Work** → Identify tasks for current terminal based on context and other terminal states
6. **Update ROADMAP.md** → Update terminal-specific priorities and coordination status for other terminals to see

## 🎯 PLAN Mode Mission

**Primary Focus**: Coordinate three simultaneous Claude Code terminals with real-time parallel work coordination.

**Enhanced Responsibility**: PLAN.md is the **Multi-Terminal Coordination Manager** - maintaining roadmap health, coordinating parallel work across terminals, and ensuring conflict-free development through real-time status updates.

**Philosophy**: Multi-terminal planning enables true parallel development and integration while maintaining code quality and avoiding merge conflicts through intelligent coordination via ROADMAP.md as the central communication hub.

## 🖥️ Three-Terminal Planning System

### **Terminal 1: Main Branch** → Comprehensive Refactoring Context
**When Active**: ONLY when Terminal 2 (development) and Terminal 3 (integration) are both inactive/not committing
**Purpose**: Comprehensive refactoring across entire codebase - framework, test app, and documentation
**Focus**: 
- Refactor framework code structure and organization in `/AxiomFramework/`
- Refactor test app code structure and organization in `/AxiomTestApp/`
- Improve cross-system consistency and architectural alignment
- Archive completed development phases and organize documentation
- Enhance code quality, maintainability, and performance patterns
**Coordination**: Must check ROADMAP.md for other terminal activity before starting work

### **Terminal 2: Development Branch** → Framework Planning Context  
**When Active**: Can run parallel with Terminal 3 (integration), must coordinate with Terminal 1 (main)
**Purpose**: Framework core enhancement and new capabilities
**Focus**:
- Implement framework limitations discovered through integration
- Build new protocol implementations and capabilities
- Design enhanced capability system features
- Improve intelligence system accuracy and performance
**Coordination**: Updates ROADMAP.md status for other terminals, coordinates file changes with Terminal 3

### **Terminal 3: Integration Branch** → Test App Planning Context
**When Active**: Can run parallel with Terminal 2 (development), must coordinate with Terminal 1 (main)
**Purpose**: Real-world validation and API refinement in AxiomTestApp
**Focus**:
- Validate new framework features in real-world scenarios
- Test API ergonomics and developer experience improvements
- Discover usage patterns and optimization opportunities
- Measure performance against established targets
**Coordination**: Updates ROADMAP.md status for other terminals, coordinates file changes with Terminal 2

## 🔄 Multi-Terminal Coordination Principles

### **Terminal Activity Rules**
- **Terminal 2 + Terminal 3**: Can work simultaneously on different file scopes
- **Terminal 1 Exclusivity**: Refactor work ONLY when Terminal 2 and Terminal 3 are both completely inactive and not working on commits
- **Real-Time Coordination**: All terminals use ROADMAP.md as central communication hub
- **Manual Merge Control**: User decides when and how to merge branches from any terminal

### **Terminal File Coordination Strategy**
- **Terminal 2 (Development)**: New feature development in `/AxiomFramework/Sources/`, `/AxiomFramework/Tests/`, `/AxiomFramework/Package.swift`
- **Terminal 3 (Integration)**: New integration testing in `/AxiomTestApp/`, integration documentation  
- **Terminal 1 (Main)**: **COMPREHENSIVE REFACTORING** across entire codebase `/AxiomFramework/`, `/AxiomTestApp/`, `/Documentation/` - but ONLY when Terminal 2 and Terminal 3 are IDLE
- **Coordination Principle**: Terminal 1 can refactor any code, but must wait for Terminal 2 and Terminal 3 to be completely inactive to avoid conflicts
- **Shared Communication**: ROADMAP.md Terminal Status section used for real-time coordination

### **Terminal Status Communication**
- **ROADMAP.md Terminal Status Section**: Each terminal updates its current activity status
- **Commit/Push Notifications**: Terminals announce when they're actively committing/pushing
- **Quiet Period Detection**: Terminal 1 monitors for Terminal 2 and Terminal 3 inactivity
- **Cross-Terminal Awareness**: Each terminal checks other terminal status before major operations

### **Integration with PROPOSE.md**
**Strategic Improvement Coordination**: PROPOSE.md provides comprehensive strategic analysis and improvement proposals that can influence PLAN.md decisions across all branches.

**When to Use PROPOSE**:
- Major milestone completion requiring strategic assessment
- Innovation opportunity identification and evaluation  
- Architectural rethinking and optimization needs
- Process improvement and development velocity enhancement

**PROPOSE → PLAN Flow**:
1. **PROPOSE.md** → Generates strategic improvement proposals
2. **User Selection** → User chooses which proposals to implement
3. **PLAN.md Integration** → Approved proposals influence branch planning and priority adjustments
4. **Implementation Coordination** → PLAN.md coordinates proposal implementation across development/integration/main branches

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

## 📋 Multi-Terminal Planning Workflow

### **Phase 1: Terminal Context Detection & Coordination Check**
1. **Detect Current Terminal** → Determine planning context (Terminal 1: main, Terminal 2: development, Terminal 3: integration)
2. **Check Other Terminal Status** → Read ROADMAP.md to assess what other terminals are actively working on
3. **Assess Terminal Compatibility** → Determine if current terminal can work alongside other active terminals
4. **Read CURRENT SPRINT STATUS** → Understand current multi-terminal development state
5. **Identify Terminal Blockers** → Check if other terminals prevent current terminal work (especially Terminal 1)

### **Phase 2: Terminal-Specific Planning**
1. **Identify Terminal Priorities** → Select high-impact tasks for current terminal's file scope
2. **Coordinate File Isolation** → Ensure current terminal work doesn't conflict with other terminals
3. **Plan Parallel Work Strategy** → Enable Terminal 2 and Terminal 3 to work simultaneously
4. **Estimate Terminal Effort** → Gauge complexity and time requirements for terminal-specific work

### **Phase 3: Roadmap Health Management** (Multi-Terminal Aware)
1. **Execute Roadmap Health Assessment** → Check roadmap coordination status across all terminals
2. **Update Terminal Status** → Announce current terminal's planned work to other terminals
3. **Coordinate Priority Updates** → Ensure terminal priorities don't conflict with other terminal work
4. **Maintain Terminal Communication** → Keep ROADMAP.md as effective coordination hub

### **Phase 4: Cross-Terminal Coordination**
1. **Update TERMINAL STATUS** → Define current terminal work and announce to other terminals
2. **Coordinate With Active Terminals** → Ensure Terminal 2 and Terminal 3 can work together, Terminal 1 waits for quiet
3. **Plan Multi-Terminal Strategy** → Coordinate how multiple terminals work together without conflicts
4. **Document Terminal Rationale** → Record why specific terminal work was planned and how it coordinates

### **Phase 5: Terminal Work Preparation & Cross-Terminal Validation**
1. **Validate Cross-Terminal Coordination** → Confirm terminals can work together without conflicts
2. **Prepare Terminal Execution** → Ready for terminal-specific work with clear file scope boundaries
3. **Set Terminal Status Monitoring** → Establish how terminals will monitor each other's activity
4. **Define Terminal Success Criteria** → Set measurable goals for current terminal work with coordination requirements

## 📋 Multi-Terminal ROADMAP.md Management Protocol

**PLAN.md is the ONLY mode that updates CURRENT SPRINT STATUS and UPCOMING PRIORITIES**

**ENHANCED RESPONSIBILITY**: PLAN.md is the **Multi-Terminal Coordination Manager** - the only mode that maintains roadmap health AND coordinates real-time status between three simultaneous terminals.

### **ROADMAP.md Terminal Status Section** (NEW)

Each terminal must update its status in ROADMAP.md for cross-terminal coordination:

```markdown
## 🖥️ TERMINAL STATUS (Real-Time Coordination)

### **Terminal 1 (Main Branch)** 
**Status**: [ACTIVE/WAITING/IDLE] 
**Current Work**: [Description of current refactor/organization work]
**Blocking For**: [Waiting for Terminal 2 and/or Terminal 3 to go idle]
**Last Updated**: [Timestamp]

### **Terminal 2 (Development Branch)**
**Status**: [ACTIVE/COMMITTING/PUSHING/IDLE]
**Current Work**: [Description of current framework development work] 
**File Scope**: [Specific files being modified]
**Coordination**: [How this work coordinates with Terminal 3]
**Last Updated**: [Timestamp]

### **Terminal 3 (Integration Branch)**
**Status**: [ACTIVE/COMMITTING/PUSHING/IDLE] 
**Current Work**: [Description of current integration/testing work]
**File Scope**: [Specific files being modified]
**Coordination**: [How this work coordinates with Terminal 2]
**Last Updated**: [Timestamp]
```

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

### **Multi-Terminal Coordination Decision Matrix**

**Terminal 2 (Development) Can Work When:**
- Framework limitations need code changes (independent of Terminal 3)
- New framework features needed for strategic goals
- Performance targets need framework-level optimization
- Core architecture needs enhancement or new capabilities
- **Coordination**: Can work simultaneously with Terminal 3, must avoid shared files

**Terminal 3 (Integration) Can Work When:**
- Framework features ready for real-world validation in AxiomTestApp
- Developer experience needs measurement and refinement
- Performance needs validation in complex test scenarios
- Usage patterns need discovery and documentation
- **Coordination**: Can work simultaneously with Terminal 2, must avoid shared files

**Terminal 1 (Main) Can ONLY Work When:**
- **BOTH Terminal 2 AND Terminal 3 are completely IDLE** (not committing, not pushing, not actively working)
- Framework code needs structural refactoring and organization
- Test app code needs refactoring and consistency improvements
- Cross-system refactoring needed for architectural alignment
- Major development phase completion needs archival
- Documentation organization needs improvement
- **Critical**: Must check ROADMAP.md Terminal Status before starting ANY work

### **Critical Rules for PLAN.md Updates**
- ✅ **Only PLAN.md updates CURRENT SPRINT** and UPCOMING PRIORITIES
- ✅ **Read ALL deliverable sections** before making planning decisions
- ✅ **Base decisions on concrete deliverables** not assumptions
- ✅ **Define measurable success criteria** for every sprint
- ✅ **Document planning rationale** for future reference

## 🎯 Planning Priorities by Branch Context

### **Development Branch Planning**
**Primary Focus**: Framework core enhancement
**File Scope**: `/AxiomFramework/Sources/` and related framework code

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

### **Integration Branch Planning**  
**Primary Focus**: Real-world validation in AxiomTestApp
**File Scope**: `/AxiomTestApp/` and test application code

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

### **Main Branch Planning**
**Primary Focus**: Comprehensive refactoring and organizational improvements
**File Scope**: **ENTIRE CODEBASE** - `/AxiomFramework/`, `/AxiomTestApp/`, `/Documentation/`

**Typical Tasks**:
- Refactor framework code structure and organization
- Refactor test app code structure and consistency
- Improve cross-system architectural alignment
- Archive completed development phase documentation
- Reorganize code and documentation for better maintainability
- Enhance code quality and eliminate duplication
- Standardize patterns across framework and test app
- Optimize performance patterns and memory management

**Success Criteria**:
- Framework code well-organized and maintainable
- Test app code follows consistent patterns and structure
- Cross-system consistency achieved between framework and test app
- Documentation well-organized and navigable
- Code quality improvements reduce technical debt
- Development environment optimized for parallel work
- Historical work properly archived and accessible

## 📊 Branch Coordination Decision Matrix

### **Current Branch: Development**
- **High integration needs** → Coordinate with integration branch for parallel validation
- **Documentation debt** → Wait for main branch availability or coordinate shared files
- **Continued development** → Continue development branch work with regular commits

### **Current Branch: Integration**
- **Framework limitations found** → Coordinate with development branch for parallel fixes
- **Phase completion** → Prepare for main branch documentation when available
- **More validation needed** → Continue integration branch work and testing

### **Current Branch: Main**
- **Development work needed** → Switch to development branch after completing organization
- **Integration testing needed** → Switch to integration branch after completing organization
- **More organization needed** → Continue main branch cleanup and archival work

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

## 🎯 Branch-Aware Planning Templates

### **Development Branch** Template
```markdown
## Development Branch Planning

### Framework Enhancement Focus
- **Core Systems**: [Capabilities/Intelligence/State/SwiftUI]
- **Performance**: [Targets to achieve]
- **API Design**: [New protocols or improvements]
- **File Scope**: /AxiomFramework/Sources/ and related framework code

### Implementation Tasks
1. **High Priority**: [Critical framework needs]
2. **Medium Priority**: [Important enhancements]
3. **Nice to Have**: [Optional improvements]

### Branch Coordination
- **Parallel Integration**: [How integration branch can test changes]
- **Merge Strategy**: [When and how to merge to main]
- **Conflict Prevention**: [Files to coordinate with other branches]

### Success Criteria
- [ ] Framework builds successfully
- [ ] New features implemented and tested
- [ ] Performance targets maintained
- [ ] No breaking changes introduced
- [ ] Ready for integration branch testing
```

### **Integration Branch** Template  
```markdown
## Integration Branch Planning

### Validation Focus
- **New Features**: [Framework capabilities to test in AxiomTestApp]
- **Performance**: [Metrics to measure in real scenarios]
- **Developer Experience**: [Usability to assess]
- **File Scope**: /AxiomTestApp/ and test application code

### Integration Tasks
1. **Feature Testing**: [Test new framework capabilities]
2. **Performance Validation**: [Measure against targets]
3. **Pattern Discovery**: [Find usage patterns]

### Branch Coordination
- **Parallel Development**: [How development branch changes are incorporated]
- **Merge Strategy**: [When and how to merge to main]
- **Feedback Loop**: [How to communicate findings to development branch]

### Success Criteria
- [ ] AxiomTestApp successfully integrates new features
- [ ] Performance validated in real scenarios
- [ ] Developer experience improvements documented
- [ ] Framework limitations identified and communicated
```

### **Main Branch** Template
```markdown
## Main Branch Planning

### Organization Focus
- **Documentation**: [Areas needing cleanup and archival]
- **Structure**: [Organizational improvements needed]
- **Archive**: [Completed work to archive]
- **File Scope**: /Documentation/ and organizational structure

### Refactor Tasks
1. **Archive**: [Move completed documentation to archives]
2. **Organize**: [Restructure for better navigation]  
3. **Prepare**: [Ready environment for next development phases]

### Branch Coordination
- **Wait for Quiet**: [Ensure development and integration branches are stable]
- **Merge Integration**: [Plan when to merge other branches]
- **Conflict Resolution**: [Handle any merge conflicts]

### Success Criteria
- [ ] Documentation well-organized and navigable
- [ ] Completed work properly archived
- [ ] Structure supports parallel development
- [ ] Cross-references validated
- [ ] Ready for new development/integration work
```

## 🤖 Multi-Terminal Automated Planning Process

**Planning Command**: `@PLAN`
**Action**: Automatically detect current terminal and execute terminal-appropriate planning with cross-terminal coordination

**Automated Workflow**:
1. **Detect Current Terminal** → Determine context (Terminal 1: main, Terminal 2: development, Terminal 3: integration)
2. **Check Other Terminal Status** → Read ROADMAP.md Terminal Status section to assess other terminal activity
3. **Assess Terminal Compatibility** → Determine if current terminal can work alongside other active terminals
4. **Update Progress** → Mark completed tasks as ✅ in roadmap with terminal coordination
5. **Plan Terminal Work** → Identify tasks for current terminal context with file scope isolation
6. **Update Terminal Status** → Announce current terminal work to other terminals via ROADMAP.md
7. **Coordinate Cross-Terminal** → Ensure Terminal 1 waits for quiet, Terminal 2+3 can work in parallel
8. **Document Results** → Record planning decisions and multi-terminal coordination strategy

**Terminal Context Integration**:
- **Terminal 2 (Development)** → Plan framework enhancement work in /AxiomFramework/Sources/
- **Terminal 3 (Integration)** → Plan AxiomTestApp validation work in /AxiomTestApp/
- **Terminal 1 (Main)** → Plan documentation organization ONLY when Terminal 2 and Terminal 3 are both IDLE

**ROADMAP.md as Multi-Terminal Communication Hub**:
- ONLY PLAN.md updates ROADMAP.md sprint status and priorities
- ALL terminals use ROADMAP.md Terminal Status for real-time coordination
- Terminal coordination managed through unified roadmap system
- Progress tracking and terminal status maintained in central location for cross-terminal awareness

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

## 🔄 Example Multi-Terminal Coordination Flows

### **Parallel Terminal 2 + Terminal 3 Flow**
```
1. Terminal 2 (Development) works on framework features in /AxiomFramework/Sources/
2. Terminal 3 (Integration) simultaneously works on AxiomTestApp validation in /AxiomTestApp/
3. Both terminals update ROADMAP.md Terminal Status to show ACTIVE work
4. Both terminals coordinate file scope to avoid conflicts
5. Both terminals work independently until user decides to merge
6. Terminal 1 (Main) remains WAITING until both terminals go IDLE
```

### **Terminal 3 Discovery → Terminal 2 Coordination Flow**  
```
1. Terminal 3 discovers framework limitations in AxiomTestApp testing
2. Terminal 3 updates ROADMAP.md with findings and sets status to communicate with Terminal 2
3. Terminal 2 reads Terminal 3 findings and plans framework fixes
4. Terminal 2 implements fixes while Terminal 3 continues testing in parallel
5. Both terminals coordinate through ROADMAP.md status updates
6. Real-time parallel work until fixes address Terminal 3 needs
```

### **Terminal 1 Refactor Opportunity Flow**
```
1. Terminal 2 and Terminal 3 both complete their work and go IDLE
2. Terminal 1 checks ROADMAP.md Terminal Status to confirm both terminals are IDLE
3. Terminal 1 plans refactor/organization work and updates status to ACTIVE
4. Terminal 1 works on documentation organization and archival
5. Terminal 1 completes work and goes back to WAITING
6. Terminal 2 and Terminal 3 can resume ACTIVE work when needed
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

**PLANNING STATUS**: Comprehensive multi-terminal coordination system for three simultaneous Claude Code terminals  
**ROADMAP INTEGRATION**: Single source of truth for all terminal development planning with real-time Terminal Status coordination  
**AUTOMATED EXECUTION**: Ready for `@PLAN` command with ultrathink and terminal detection across three active terminals  
**STRATEGIC INTEGRATION**: Coordinates with `@PROPOSE` for continuous improvement across all terminals and branches  
**TERMINAL COORDINATION**: Seamless workflow between Terminal 1 (main), Terminal 2 (development), Terminal 3 (integration) with parallel work support, real-time status communication, and conflict prevention through ROADMAP.md coordination hub