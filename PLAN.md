# Axiom Framework: Intelligent Branch-Aware Planning Engine

**Contextual planning that automatically adapts to current branch focus**

## 🤖 Automated Mode Trigger

**When human sends**: `@PLAN`
**Action**: Automatically enter ultrathink mode and execute branch-aware planning

**Branch-Aware Process**:
1. **Detect Current Branch** → Determine planning context (main, development, integration)
2. **Read PLAN.md** → Load this complete branch-aware planning guide
3. **Check ROADMAP.md** → Assess current status, completed work, and branch coordination
4. **Branch Coordination** → Plan work within branch scope and coordinate with other branches
5. **Plan Branch Work** → Identify tasks for current branch based on context and priorities
6. **Update ROADMAP.md** → Update branch-specific priorities and coordination status

## 🎯 PLAN Mode Mission

**Primary Focus**: Intelligent branch-aware planning that automatically adjusts planning scope and priorities based on current branch context.

**Enhanced Responsibility**: PLAN.md is the **Branch-Aware Planning Engine** - detecting current branch and executing specialized planning for framework development, integration testing, or strategic coordination.

**Philosophy**: Planning should be contextual and intelligent. When called in development branch, plan framework work. When called in integration branch, plan integration work. When called in main branch, plan strategic work.

## 🌿 Branch-Aware Planning Execution

### **When Called in Development Branch**
**Automatic Behavior**: Plan framework development, enhancement, and testing work
**Planning Focus**: Framework capabilities, APIs, performance optimization, architecture evolution
**Work Details**: Stored in `/AxiomFramework/Documentation/` and tracked in `ROADMAP.md`
**Methodology Reference**: General development approaches available in `@DEVELOP.md`

**Development Branch Planning Priorities**:
- 🔧 **Framework Features**: Plan new capabilities, protocols, and architectural improvements
- ⚡ **Performance Work**: Plan optimization strategies and performance improvements
- 🏗️ **API Development**: Plan interface improvements and developer experience enhancements
- 🧪 **Testing Infrastructure**: Plan framework testing and validation capabilities
- 📊 **Intelligence Features**: Plan AI and ML capability development
- 🔄 **Code Quality**: Plan refactoring and structural improvements

### **When Called in Integration Branch**
**Automatic Behavior**: Plan integration testing, validation, and test app development work
**Planning Focus**: Framework validation, developer experience testing, integration patterns
**Work Details**: Stored in `/AxiomTestApp/Documentation/` and tracked in `ROADMAP.md`
**Methodology Reference**: General integration approaches available in `@INTEGRATE.md`

**Integration Branch Planning Priorities**:
- ✅ **Framework Validation**: Plan comprehensive testing of framework capabilities
- 👥 **Developer Experience**: Plan API ergonomics testing and usability improvements
- 🔗 **Integration Patterns**: Plan optimal framework usage patterns and examples
- 📈 **Performance Validation**: Plan real-world performance testing and measurement
- 📱 **Test App Development**: Plan test application features and validation scenarios
- 🎯 **Usage Examples**: Plan integration documentation and usage patterns

### **When Called in Main Branch**
**Automatic Behavior**: Plan strategic coordination, generate technical enhancement proposals, and organize documentation
**Planning Focus**: Strategic direction, proposal generation and management, documentation structure, roadmap coordination
**Work Details**: Managed in `/Proposals/`, documentation folders, and `ROADMAP.md`
**Methodology Reference**: Strategic planning approaches and technical enhancement proposal generation

**Main Branch Planning Priorities**:
- 🔧 **Technical Proposal Generation**: Generate enhancement proposals for framework capabilities, performance, and developer experience
- 📋 **Proposal Management**: Plan proposal review, approval workflows, and implementation coordination
- 📚 **Documentation Organization**: Plan structure improvements and archive management
- 🗺️ **ROADMAP Coordination**: Plan cross-branch coordination and strategic alignment
- 📦 **Archive Management**: Plan historical work organization and accessibility
- 🎯 **Strategic Direction**: Plan long-term framework development and vision coordination

**Technical Enhancement Proposal Areas**:
- **🏗️ Framework Architecture**: New patterns, module optimization, protocol design, error handling
- **⚡ Performance & Optimization**: Advanced techniques, caching, concurrency, memory optimization
- **🔧 Developer Experience**: API improvements, macro enhancements, debugging, type safety
- **🧠 Intelligence & AI Features**: Pattern detection, predictive analysis, ML integration
- **🔐 Capabilities & Validation**: New capability types, runtime detection, graceful degradation
- **🧪 Testing & Quality**: Testing infrastructure, benchmarking, automated validation

## 🔄 Command System Architecture

### **PLAN.md: Branch-Aware Planning Engine**
- **Intelligent Detection**: Automatically detects current branch and adjusts planning behavior
- **Development Branch**: Plans framework development work using @DEVELOP.md methodology
- **Integration Branch**: Plans integration testing work using @INTEGRATE.md methodology  
- **Main Branch**: Plans strategic coordination, proposals, and documentation organization
- **Work Storage**: Specific plans stored in appropriate Documentation/ folders and ROADMAP.md

### **DEVELOP.md: General Development Methodology**
- **Purpose**: Contains general development principles, approaches, and best practices
- **Scope**: Framework development methodology and guidance
- **Coordination**: Works with PLAN.md when called in development branch
- **Specifics**: Detailed development work tracked in `/AxiomFramework/Documentation/` and `ROADMAP.md`

### **INTEGRATE.md: General Integration Methodology**
- **Purpose**: Contains general integration principles, testing approaches, and validation methods
- **Scope**: Integration testing methodology and guidance
- **Coordination**: Works with PLAN.md when called in integration branch
- **Specifics**: Detailed integration work tracked in `/AxiomTestApp/Documentation/` and `ROADMAP.md`

### **Documentation Hierarchy**
- **@PLAN.md**: Branch-aware planning execution (detects branch and plans accordingly, includes proposal generation for main branch)
- **@DEVELOP.md**: General development methodology and principles
- **@INTEGRATE.md**: General integration methodology and principles
- **@REFACTOR.md**: Branch-aware code organization and quality improvements
- **@APPROVE.md**: Proposal review and integration system
- **/AxiomFramework/Documentation/**: Specific development work details and tracking
- **/AxiomTestApp/Documentation/**: Specific integration work details and tracking
- **/Proposals/**: Technical enhancement proposals generated by @PLAN (main branch)
- **ROADMAP.md**: Cross-branch coordination and progress tracking

## 🔧 Technical Proposal Generation (Main Branch)

When @PLAN is called in main branch, it includes technical enhancement proposal generation capabilities in addition to strategic planning.

### **Proposal Generation Process**
1. **Current State Assessment** → Analyze framework capabilities and identify enhancement opportunities
2. **Technical Gap Analysis** → Find areas needing new capabilities or architectural improvements
3. **Performance Review** → Identify optimization opportunities and performance improvements
4. **Developer Experience Evaluation** → Assess API ergonomics and usability enhancements
5. **Enhancement Opportunity Discovery** → Generate specific technical improvement proposals
6. **Proposal File Creation** → Create structured proposal files in `/Proposals/Active/`
7. **User Presentation** → Present enhancement proposals for review and approval

### **Proposal Categories & Focus Areas**
- **Framework Extensions** → New capabilities, protocols, and architectural patterns
- **Performance Improvements** → Optimization techniques and advanced performance features
- **Developer Experience** → API enhancements, tooling improvements, and ease-of-use features
- **Architecture Evolution** → Structural improvements and advanced design patterns
- **Quality & Testing** → Enhanced validation, testing infrastructure, and quality assurance

### **Proposal File Structure**
```markdown
# Proposal: [Title]

**Date**: YYYY-MM-DD
**Category**: [Framework/TestApp/Process/Strategic]
**Priority**: [High/Medium/Low]
**Estimated Effort**: [Small/Medium/Large]
**Impact**: [High/Medium/Low]

## Problem Statement
[What specific issue or opportunity does this address?]

## Proposed Solution
[Detailed description of the proposed improvement]

## Benefits
[Quantified benefits and improvements]

## Implementation Plan
[Step-by-step implementation approach]

## Risk Assessment
[Potential issues and mitigation strategies]

## Success Metrics
[How will success be measured?]

## Dependencies
[What other work must be completed first?]

## Approval Requirements
[What needs to happen to approve this proposal?]
```

### **Proposal Workflow Integration**
- **Generation**: @PLAN (main branch) creates proposals in `/Proposals/Active/`
- **Review**: User reviews generated proposals and selects those for implementation
- **Approval**: @APPROVE command integrates selected proposals into roadmap and documentation
- **Implementation**: Approved proposals become priorities for development and integration branches
- **Tracking**: Proposal implementation tracked through ROADMAP.md and branch-specific documentation

## 🧹 ROADMAP Health Management

**PLAN.md Branch Coordination**: As the Branch Coordination Manager, PLAN.md maintains a healthy roadmap that reflects coordinated work across all branches.

### **Roadmap Health Targets**
- **Active Content**: <300 lines total roadmap size for efficient navigation
- **Navigation Speed**: <30 seconds to find current branch status and priorities
- **Decision Efficiency**: <2 minutes to plan next work from clean roadmap
- **Historical Access**: Completed work preserved in archives, not cluttering active planning
- **Branch Clarity**: Clear separation of branch responsibilities and progress

### **Core Roadmap Maintenance Operations**

#### **Phase A: Branch Status Assessment**
1. **Branch Progress Review** → Check progress across main, development, and integration branches
2. **Priority Alignment** → Ensure branch priorities support overall framework goals
3. **Coordination Needs** → Identify where branches need to coordinate or share information
4. **Roadmap Size Check** → Verify roadmap remains focused and navigable

#### **Phase B: Cross-Branch Planning**
1. **Main Branch Planning** → Strategic planning, proposals, documentation organization
2. **Development Branch Planning** → Framework enhancement and capability development
3. **Integration Branch Planning** → Validation, testing, and developer experience improvement
4. **Coordination Planning** → Plan how branches share progress and coordinate major milestones

#### **Phase C: Priority Organization**
1. **Branch Priority Updates** → Update priorities for each branch based on progress and needs
2. **Cross-Branch Dependencies** → Identify and plan for work that depends on other branches
3. **Timeline Coordination** → Align branch timelines for major releases and milestones
4. **Resource Allocation** → Plan effort distribution across branches

#### **Phase D: Roadmap Optimization**
1. **Content Organization** → Ensure roadmap clearly shows current and upcoming work
2. **Archive Management** → Move completed work to archives while maintaining accessibility
3. **Navigation Improvement** → Optimize roadmap structure for efficient planning
4. **Status Clarity** → Ensure branch status and coordination is clearly visible

## 📋 Branch-Specific Planning Workflow

### **Main Branch Planning Process**

#### **Strategic Planning Assessment**
1. **Proposal Pipeline Review** → Assess active proposals and approval needs
2. **Documentation Status** → Review documentation organization and improvement needs
3. **ROADMAP Health Check** → Evaluate roadmap organization and coordination effectiveness
4. **Archive Management** → Plan historical work organization and accessibility
5. **Cross-Branch Coordination** → Plan how to support development and integration branches

#### **Main Branch Work Planning**
1. **Proposal Management Tasks** → Plan proposal review, organization, and approval workflows
2. **Documentation Projects** → Plan documentation organization and structure improvements
3. **ROADMAP Updates** → Plan roadmap coordination and health maintenance
4. **Strategic Initiatives** → Plan long-term framework direction and vision
5. **Archive Organization** → Plan completed work organization and historical access

### **Development Branch Planning Process**

#### **Framework Enhancement Assessment**
1. **Capability Gaps** → Identify framework capabilities needing development or enhancement
2. **API Improvement Opportunities** → Find API design improvements and developer experience enhancements
3. **Performance Optimization** → Identify performance improvement opportunities
4. **Architecture Evolution** → Plan structural improvements and advanced patterns
5. **Integration Feedback** → Review integration branch feedback for framework improvements

#### **Development Branch Work Planning**
1. **Framework Features** → Plan new capabilities, protocols, and architectural improvements
2. **API Development** → Plan API design improvements and interface enhancements
3. **Performance Work** → Plan optimization strategies and performance improvements
4. **Testing Infrastructure** → Plan framework testing and validation improvements
5. **Code Quality** → Plan refactoring and structural improvements

### **Integration Branch Planning Process**

#### **Validation Assessment**
1. **Framework Testing Needs** → Identify framework capabilities needing validation
2. **Developer Experience Gaps** → Find areas where framework usage could be improved
3. **Integration Patterns** → Assess optimal framework usage patterns and examples
4. **Performance Validation** → Plan real-world performance testing and measurement
5. **Test App Enhancement** → Identify test application improvement opportunities

#### **Integration Branch Work Planning**
1. **Validation Scenarios** → Plan comprehensive framework capability testing
2. **Developer Experience** → Plan API ergonomics testing and usability improvements
3. **Integration Examples** → Plan optimal usage pattern development and documentation
4. **Performance Testing** → Plan real-world performance validation and measurement
5. **Test App Development** → Plan test application features and validation scenarios

## 🎯 Branch Planning Priorities

### **Main Branch Planning Priorities**
1. **Proposal Management** → Maintain efficient proposal workflow and strategic direction
2. **Documentation Organization** → Keep documentation well-structured and accessible
3. **ROADMAP Coordination** → Maintain healthy roadmap and cross-branch coordination
4. **Archive Management** → Properly organize historical work and maintain accessibility
5. **Strategic Planning** → Coordinate long-term framework development direction

### **Development Branch Planning Priorities**
1. **Framework Capabilities** → Plan development of new features and enhancements
2. **API Excellence** → Plan API design improvements and developer experience
3. **Performance Optimization** → Plan optimization strategies and performance improvements
4. **Architecture Quality** → Plan structural improvements and advanced patterns
5. **Testing Infrastructure** → Plan framework testing and validation capabilities

### **Integration Branch Planning Priorities**
1. **Comprehensive Validation** → Plan thorough testing of framework capabilities
2. **Developer Experience** → Plan usability testing and integration pattern development
3. **Real-World Testing** → Plan performance validation and real-world usage scenarios
4. **Integration Examples** → Plan optimal usage pattern development and examples
5. **Test App Quality** → Plan test application improvements and validation scenarios

## 🔧 Branch Coordination Templates

### **Main Branch Planning Template**
```markdown
## Main Branch Planning

### Strategic Priorities
- **Proposals**: [Current proposal status and needs]
- **Documentation**: [Organization and improvement priorities]
- **ROADMAP**: [Coordination and health maintenance needs]
- **Archives**: [Historical work organization priorities]

### Coordination Needs
- **Development Branch**: [Support needed for framework development]
- **Integration Branch**: [Support needed for validation and testing]
- **Cross-Branch**: [Coordination requirements for major milestones]

### Success Criteria
- [ ] Proposal workflow is efficient and strategic
- [ ] Documentation is well-organized and accessible
- [ ] ROADMAP coordinates branches effectively
- [ ] Historical work is properly archived
```

### **Development Branch Planning Template**
```markdown
## Development Branch Planning

### Framework Priorities
- **Capabilities**: [New features and enhancements needed]
- **APIs**: [Interface improvements and developer experience]
- **Performance**: [Optimization opportunities and targets]
- **Architecture**: [Structural improvements and patterns]

### Implementation Tasks
- **High Priority**: [Critical framework development needs]
- **Medium Priority**: [Important enhancements and improvements]
- **Future Work**: [Planned capabilities and enhancements]

### Success Criteria
- [ ] Framework capabilities meet development targets
- [ ] APIs provide excellent developer experience
- [ ] Performance targets are achieved
- [ ] Architecture supports long-term goals
```

### **Integration Branch Planning Template**
```markdown
## Integration Branch Planning

### Validation Priorities
- **Framework Testing**: [Capabilities needing validation]
- **Developer Experience**: [Usability testing and improvement]
- **Integration Patterns**: [Optimal usage pattern development]
- **Performance**: [Real-world performance validation]

### Testing Tasks
- **Validation Scenarios**: [Framework capability testing]
- **Integration Examples**: [Usage pattern development]
- **Performance Testing**: [Real-world performance measurement]
- **Test App Features**: [Application development and validation]

### Success Criteria
- [ ] Framework capabilities are thoroughly validated
- [ ] Developer experience is excellent
- [ ] Integration patterns are optimal
- [ ] Real-world performance meets targets
```

## 🚀 Planning Success Metrics

### **Cross-Branch Coordination**
- **Clear Responsibilities**: Each branch has focused scope without overlap
- **Efficient Communication**: Branches coordinate effectively through ROADMAP.md
- **Independent Progress**: Branches can work simultaneously without conflicts
- **Strategic Alignment**: All branches support overall framework goals
- **Quality Maintenance**: All branches maintain high code and documentation quality

### **Planning Effectiveness**
- **Realistic Scope**: Branch planning creates achievable work plans
- **Priority Alignment**: Branch priorities support framework strategic goals
- **Resource Optimization**: Effort is efficiently distributed across branches
- **Progress Tracking**: Branch progress is clearly visible and coordinated
- **Continuous Improvement**: Planning improves based on branch feedback and results

### **Framework Development Velocity**
- **Parallel Development**: Branches work simultaneously on complementary efforts
- **Focused Expertise**: Each branch develops specialized knowledge and capability
- **Reduced Conflicts**: Clear scope boundaries prevent coordination overhead
- **Quality Assurance**: Specialized refactoring maintains code quality in each branch
- **Strategic Coherence**: All branch work contributes to cohesive framework evolution

## 🤖 Automated Branch-Aware Planning

**Planning Command**: `@PLAN`
**Action**: Automatically detect current branch and execute contextual planning with methodology integration

**Branch Detection & Planning Workflow**:
```bash
# Development Branch Context
if on development branch:
    methodology = @DEVELOP.md  # General development principles and approaches
    work_details = /AxiomFramework/Documentation/  # Specific development tasks and tracking
    focus = "Framework development, APIs, performance, testing infrastructure"

# Integration Branch Context  
elif on integration branch:
    methodology = @INTEGRATE.md  # General integration principles and approaches
    work_details = /AxiomTestApp/Documentation/  # Specific integration tasks and tracking
    focus = "Framework validation, developer experience, integration patterns"

# Main Branch Context
elif on main branch:
    methodology = "Strategic planning and proposal generation"  # Strategic coordination and technical enhancement proposals
    work_details = "/Proposals/, Documentation folders, ROADMAP.md"  # Strategic work and proposal tracking
    focus = "Technical proposal generation, proposal management, documentation organization, roadmap coordination"
```

**Automated Planning Execution**:
1. **Branch Detection** → Determine current git branch (main, development, integration)
2. **Methodology Loading** → Reference appropriate methodology guide (@DEVELOP.md or @INTEGRATE.md)
3. **Work Assessment** → Review current work in branch-specific Documentation/ folders and ROADMAP.md
4. **Priority Planning** → Plan next priorities using methodology guidance and current context
5. **Documentation Updates** → Update work details in appropriate Documentation/ folders
6. **ROADMAP Coordination** → Update ROADMAP.md with branch-specific progress and plans
7. **Cross-Branch Awareness** → Ensure planning coordinates with other branch activities

**Command Integration Model**:
- **@PLAN** (development branch) + **@DEVELOP.md** → Framework development planning with general methodology
- **@PLAN** (integration branch) + **@INTEGRATE.md** → Integration testing planning with general methodology
- **@PLAN** (main branch) → Strategic planning, technical proposal generation, and documentation organization
- **@APPROVE** → Proposal review and integration system (works with proposals generated by @PLAN main branch)
- **Work Details** → Stored in appropriate `/Documentation/` folders and tracked in `ROADMAP.md`
- **Proposals** → Generated by @PLAN (main branch) and managed through @APPROVE workflow
- **Progress Coordination** → All branches update `ROADMAP.md` for cross-branch awareness

---

**PLANNING STATUS**: Intelligent branch-aware planning engine with integrated proposal generation ✅  
**BRANCH INTELLIGENCE**: Automatically detects branch context and adapts planning behavior  
**METHODOLOGY INTEGRATION**: Works with @DEVELOP.md and @INTEGRATE.md for general guidance  
**PROPOSAL GENERATION**: Technical enhancement proposal generation when called in main branch  
**WORK STORAGE**: Specific plans stored in appropriate Documentation/ folders and ROADMAP.md  
**DEVELOPMENT PLANNING**: Framework development planning when called in development branch  
**INTEGRATION PLANNING**: Integration testing planning when called in integration branch  
**STRATEGIC PLANNING**: Proposal generation, coordination, and documentation planning when called in main branch  
**AUTOMATION READY**: Supports `@PLAN` command with intelligent branch detection and contextual execution

**Use @PLAN in any branch for intelligent, contextual planning that automatically adapts to your current development focus and generates technical enhancement proposals when needed.**