# Axiom Framework Refactor Guide

You are Claude Code organizing and preparing the Axiom framework for new development cycles through documentation restructuring and code organization.

## 🤖 Automated Mode Trigger

**When human sends**: `@REFACTOR`
**Action**: Automatically enter ultrathink mode and execute next roadmap task

**Process**:
1. **Read REFACTOR.md** → Load this complete guide
2. **Check ROADMAP.md** → Identify organizational needs or phase completion triggers
3. **Execute Reorganization** → Archive, organize, and prepare documentation structure
4. **Update Progress** → Mark task complete (✅) in ROADMAP.md

## 🎯 REFACTOR Mode Mission

**Focus**: Organize documentation, restructure for development efficiency, prepare for new phases, and maintain clean development environment.

**Philosophy**: Well-organized foundation enables rapid development. Clean structure prevents technical debt and accelerates innovation.

## 🗂️ Dual Documentation Architecture

### **Documentation System Roles** 🎯

#### **AxiomFramework/Documentation/** - Technical Foundation
- **Purpose**: Framework internals, technical specifications, implementation guides
- **Audience**: Framework developers working on core capabilities
- **Focus**: Protocols, architecture, technical implementation details

#### **AxiomTestApp/Documentation/** - Integration & Validation  
- **Purpose**: Real-world usage, integration testing, performance validation
- **Audience**: Framework users and integration developers
- **Focus**: Usage patterns, testing methodologies, practical application

### **Consistent Organizational Principles** 📋

#### **Single Source of Truth Pattern**
- **ONLY top-level README.md** → Comprehensive project overview (like STATUS.md)
- **NO subdirectory READMEs** → Eliminates all duplication and confusion
- **Single authoritative source** → All project information in one place

#### **Standard Directory Categories**
1. **Technical/** → Core technical specifications and API documentation
2. **Implementation/** → Implementation guides, roadmaps, development workflows
3. **Testing/** → Testing approaches, validation methodologies
4. **Performance/** → Performance measurement, optimization, benchmarking
5. **Usage/** → Usage patterns, examples, best practices
6. **Integration/** → How components work together or with external systems
7. **Troubleshooting/** → Common issues, debugging, problem resolution
8. **Archive/** → Historical documents, completed phases

#### **Standard File Naming Patterns**
- **Project Overview**: ONLY top-level `README.md` (comprehensive, authoritative)
- **Guides**: `[TOPIC]_GUIDE.md` (e.g., `INTEGRATION_GUIDE.md`)
- **Specifications**: `[SYSTEM]_SPECIFICATION.md` (e.g., `API_SPECIFICATION.md`)
- **Workflows**: `[PROCESS]_WORKFLOW.md` (e.g., `TESTING_WORKFLOW.md`)
- **Analysis**: `[AREA]_ANALYSIS.md` (e.g., `PERFORMANCE_ANALYSIS.md`)

### **Current Documentation Status** 📊

#### **AxiomFramework/Documentation/** (Needs Reorganization)
```
Current State:
├── [Multiple files at root] ⚠️ NEEDS ORGANIZATION
├── Technical/ ✅ WELL ORGANIZED
└── Archive/ ✅ WELL ORGANIZED

Target Structure:
├── README.md                           # Overview & navigation
├── Technical/                          # Core technical specs ✅
│   ├── API_DESIGN_SPECIFICATION.md
│   ├── INTELLIGENCE_SYSTEM_SPECIFICATION.md
│   ├── CAPABILITY_SYSTEM_SPECIFICATION.md
│   ├── DOMAIN_MODEL_DESIGN_PATTERNS.md
│   └── MACRO_SYSTEM_SPECIFICATION.md
├── Implementation/                     # Implementation guides
│   ├── IMPLEMENTATION_ROADMAP.md
│   ├── DEVELOPMENT_GUIDELINES.md
│   └── IMPLEMENTATION_INDEX.md
├── Testing/                           # Framework testing strategy
│   └── TESTING_STRATEGY.md
├── Performance/                       # Framework performance specs
│   └── PERFORMANCE_TARGETS.md
└── Archive/                           # Historical documents ✅
```

#### **AxiomTestApp/Documentation/** (Well Organized) ✅
```
Current State:
├── README.md                           # Overview & navigation ✅
├── Integration/                        # Framework integration ✅
├── Testing/                           # Testing methodologies ✅
├── Usage/                             # Real-world patterns ✅
├── Performance/                       # Performance measurement ✅
├── Troubleshooting/                   # Problem resolution ✅
└── Examples/                          # Example documentation ✅
```

### **Cross-Reference Management** 🔗
- **Framework → App**: Technical specs reference real-world usage examples
- **App → Framework**: Integration guides reference technical specifications
- **Consistent Linking**: Use relative paths for maintainable cross-references
- **Unified Glossary**: Shared terminology across both documentation systems

## 🔄 Refactor Workflow

### **Phase 1: Assessment**
1. **Review Current State** → Read ROADMAP.md and identify completed phases
2. **Analyze Documentation** → Find outdated, redundant, or missing content
3. **Identify Patterns** → Look for recurring organizational needs
4. **Plan Restructuring** → Design improved organization for next development cycle

### **Phase 2: Reorganization** 
1. **Archive Completed** → Move finished phase documentation to Archive/
2. **Update Active Docs** → Refresh current documentation with latest patterns
3. **Consolidate Duplicates** → Merge redundant information into authoritative sources
4. **Create New Structure** → Build organization for next development phase

### **Phase 3: Preparation**
1. **Prepare New Guides** → Create documentation for upcoming work
2. **Update References** → Ensure all links and references are correct
3. **Validate Structure** → Confirm organization supports efficient development
4. **Document Changes** → Update ROADMAP.md with new organization and next phase planning

### **Phase 4: Maintenance**
1. **Monitor Usage** → Track which documentation is actively used
2. **Iterate Organization** → Improve structure based on actual usage patterns
3. **Keep Current** → Regular updates to prevent documentation drift
4. **Plan Next Cycle** → Prepare for future reorganization needs

## 📋 Refactor Priorities

### **Documentation Health**
- **Remove Redundancy** → Consolidate duplicate information
- **Update Currency** → Ensure all content reflects current state
- **Improve Navigation** → Make it easy to find relevant information
- **Enhance Clarity** → Clear, actionable content with concrete examples

### **Code Organization**
- **Clean Dependencies** → Remove unused imports and dependencies
- **Consistent Patterns** → Align code structure with documented patterns
- **Performance Optimization** → Profile and optimize based on real usage
- **Test Organization** → Ensure test structure matches code organization

### **Development Environment**
- **Workspace Optimization** → Ensure efficient development setup
- **Build Performance** → Optimize for fast development cycles
- **Tool Integration** → Streamline development workflow tools
- **CI/CD Updates** → Keep automation current with project structure

## 🎯 Current Refactor Needs

### **Immediate Opportunities**
1. **Unified Planning Document** → Create ROADMAP.md combining status and roadmap ✅ COMPLETED
2. **Organize Prompts** → Split PROMPT.md into focused guides ✅ COMPLETED
3. **AxiomTestApp Documentation** → Comprehensive app-specific documentation ✅ COMPLETED
4. **Clean Archive** → Move completed phase docs to proper archive structure
5. **Update References** → Fix links and references to reflect new organization

### **Structural Improvements**
1. **Example Organization** → Better structure for AxiomTestApp examples ✅ COMPLETED
2. **API Documentation** → Consolidate API reference with usage examples
3. **Performance Tracking** → Organize performance metrics and benchmarks ✅ COMPLETED
4. **Integration Guides** → Better organization of integration patterns ✅ COMPLETED

## 🎯 AxiomTestApp Documentation Achievement

### **Comprehensive Structure Created** ✅
```
AxiomTestApp/Documentation/
├── README.md                           # Overview and navigation
├── Integration/                        # Framework integration guides
│   ├── INTEGRATION_WORKFLOW.md         # Step-by-step integration testing ✅
│   ├── API_VALIDATION_PATTERNS.md      # Validating framework APIs
│   ├── MODULAR_TESTING_GUIDE.md        # Using modular structure for testing
│   └── WORKSPACE_DEVELOPMENT.md        # Workspace-based development workflow
├── Testing/                            # Testing methodologies and patterns
│   ├── TESTING_METHODOLOGIES.md        # How to test framework features ✅
│   ├── PERFORMANCE_MEASUREMENT.md      # Measuring framework performance ✅
│   ├── COMPARISON_TESTING.md           # Before/after API comparisons
│   └── REGRESSION_TESTING.md           # Ensuring stability across changes
├── Usage/                              # Real-world usage patterns
│   ├── USAGE_PATTERNS.md               # Discovered patterns from real app ✅
│   ├── API_ERGONOMICS.md               # API usability insights
│   ├── DEVELOPER_EXPERIENCE.md         # DX insights from real usage
│   └── COMMON_SCENARIOS.md             # Typical integration scenarios
├── Performance/                        # Performance analysis and optimization
│   ├── PERFORMANCE_ANALYSIS.md         # Framework performance measurement
│   ├── OPTIMIZATION_OPPORTUNITIES.md   # Identified optimization areas
│   ├── BENCHMARKING_GUIDE.md           # How to benchmark framework changes
│   └── METRICS_COLLECTION.md           # Collecting and analyzing metrics
├── Troubleshooting/                    # Common issues and solutions
│   ├── COMMON_ISSUES.md                # Frequently encountered problems ✅
│   ├── DEBUGGING_GUIDE.md              # How to debug framework integration
│   ├── BUILD_ISSUES.md                 # Workspace and build troubleshooting
│   └── PERFORMANCE_ISSUES.md           # Performance problem diagnosis
└── Examples/                           # Detailed example documentation
    ├── BASIC_EXAMPLE_GUIDE.md          # Manual implementation patterns
    ├── STREAMLINED_EXAMPLE_GUIDE.md    # Streamlined API usage
    ├── COMPARISON_EXAMPLE_GUIDE.md     # Side-by-side comparisons
    └── CUSTOM_EXAMPLE_CREATION.md      # Creating new test examples
```

### **Documentation Benefits Achieved**
- **Clear Separation** → App-specific docs separate from framework technical specs
- **Focused Guidance** → Each doc addresses specific development needs
- **Real-World Focus** → All content based on actual AxiomTestApp usage
- **Easy Navigation** → Structured for quick access to needed information
- **Comprehensive Coverage** → Integration, testing, performance, troubleshooting

## 🔧 Refactor Operations

### **Documentation Consolidation & Consistency**

#### **AxiomFramework/Documentation Reorganization**
```bash
# Organize scattered root-level files
mkdir -p AxiomFramework/Documentation/Implementation/
mv AxiomFramework/Documentation/IMPLEMENTATION_*.md AxiomFramework/Documentation/Implementation/
mv AxiomFramework/Documentation/DEVELOPMENT_GUIDELINES.md AxiomFramework/Documentation/Implementation/

mkdir -p AxiomFramework/Documentation/Testing/
mv AxiomFramework/Documentation/TESTING_STRATEGY.md AxiomFramework/Documentation/Testing/

mkdir -p AxiomFramework/Documentation/Performance/
# Create PERFORMANCE_TARGETS.md from existing specifications

# Create overview README
touch AxiomFramework/Documentation/README.md
```

#### **Cross-Reference Validation**
```bash
# Check for broken links across both documentation systems
grep -r "\.\./\.\./AxiomFramework" AxiomTestApp/Documentation/
grep -r "\.\./\.\./AxiomTestApp" AxiomFramework/Documentation/

# Validate consistent terminology
grep -r "AxiomClient\|AxiomContext\|AxiomView" */Documentation/ | # Ensure consistent usage

# Update cross-references for new structure
find */Documentation/ -name "*.md" -exec grep -l "old-path" {} \; | # Fix relocated files
```

#### **Unified Documentation Templates**
```bash
# Create consistent README templates
cat > doc_template_README.md << 'EOF'
# [Directory Name]

## 🎯 Purpose
Brief description of what this documentation covers.

## 📁 Contents
- **File1.md** → Description
- **File2.md** → Description

## 🔗 Related Documentation
- [Framework Technical Specs](../AxiomFramework/Documentation/Technical/)
- [App Integration Guides](../AxiomTestApp/Documentation/Integration/)

## 📊 Quick Navigation
- **For Framework Development** → Use framework technical docs
- **For Integration Testing** → Use app integration guides
EOF
```

### **Consistency Validation Workflow**
```bash
# Check naming pattern consistency
find */Documentation/ -name "*.md" | grep -E "(GUIDE|SPECIFICATION|WORKFLOW|ANALYSIS)" | sort

# Validate directory structure consistency
ls -la AxiomFramework/Documentation/
ls -la AxiomTestApp/Documentation/

# Check for orphaned files
find */Documentation/ -name "*.md" -exec basename {} \; | sort | uniq -d | # Find duplicates
```

### **Code Organization**
```bash
# Analyze dependencies
swift package show-dependencies

# Profile build times
swift build --verbose | # Identify slow compilation

# Clean unused code
grep -r "unused-pattern" Sources/ | # Find potential cleanup opportunities
```

### **Testing Structure**
```bash
# Organize test files
find Tests/ -name "*.swift" | # Ensure tests match code structure

# Validate test coverage
swift test --enable-code-coverage | # Check coverage metrics
```

## 📊 Refactor Success Metrics

### **Documentation Quality**
- **Navigation Time** → How quickly can needed information be found?
- **Currency** → How up-to-date is the documentation?
- **Clarity** → How clear and actionable is the content?
- **Usage** → Which documents are actually being used?

### **Code Quality**
- **Build Time** → How fast is the development cycle?
- **Test Coverage** → How comprehensive is the test suite?
- **Performance** → How efficient is the framework?
- **Maintainability** → How easy is it to make changes?

### **Development Efficiency**
- **Setup Time** → How quickly can development begin?
- **Iteration Speed** → How fast can changes be tested?
- **Error Prevention** → How well does structure prevent mistakes?
- **Knowledge Transfer** → How easy is it to understand the codebase?

## 🎯 Refactor Phases

### **Phase 1: Foundation Organization** ✅ COMPLETED
- ✅ Global STATUS.md consolidation
- ✅ Split PROMPT.md into focused guides (DEVELOP, INTEGRATE, REFACTOR)
- ✅ Modular AxiomTestApp structure organization
- ✅ Comprehensive AI agent context guides

### **Phase 2: AxiomTestApp Documentation Structure** ✅ COMPLETED
- ✅ Created comprehensive `/AxiomTestApp/Documentation/` structure
- ✅ Integration workflow and testing methodologies documented
- ✅ Performance measurement and troubleshooting guides
- ✅ Usage patterns and real-world validation approaches
- ✅ Separated app-specific docs from framework technical specs

### **Phase 3: Dual Documentation System Consistency** ✅ COMPLETED
- ✅ Established consistent organizational principles across both systems
- ✅ Defined clear roles for framework vs app documentation
- ✅ Created unified maintenance workflows and cross-reference management
- ✅ Implemented context management principles for easier navigation
- ✅ Documented standardized naming patterns and terminology
- ✅ Consolidated to ONLY top-level README.md (like STATUS.md) - removed all subdirectory READMEs

### **Phase 4: Archive and Cleanup** (Current)
- Execute AxiomFramework/Documentation reorganization
- Archive completed development phase documentation  
- Clean up redundant or outdated content
- Validate cross-system consistency and fix broken references

### **Phase 5: Next Phase Preparation** (Upcoming)
- Prepare documentation structure for advanced features
- Design organization for expanded example applications
- Plan structure for community contributions
- Create templates for new development phases

### **Phase 6: Continuous Improvement** (Ongoing)
- Monitor documentation usage patterns
- Iterate organization based on actual development needs
- Maintain clean, current, and useful documentation
- Prepare for scaling and team development

## 📚 Refactor Resources

### **Organization Templates**
- **Feature Documentation**: Standard template for new features
- **API Reference**: Consistent format for protocol documentation
- **Example Structure**: Pattern for new example applications
- **Testing Guide**: Standard approach for test organization

### **Maintenance Checklists**
- **Weekly Review**: Check for outdated content and broken links
- **Phase Completion**: Archive and reorganize for next phase
- **Performance Check**: Profile and optimize development workflow
- **Tool Updates**: Keep development environment current

## 🎯 Refactor Goals

### **Organizational Excellence**
- **Intuitive Structure** → Information is where developers expect to find it
- **Minimal Redundancy** → Single source of truth for all information
- **Easy Maintenance** → Structure supports keeping content current
- **Scalable Design** → Organization grows cleanly with project complexity

### **Development Velocity**
- **Fast Navigation** → Quick access to needed information
- **Clear Patterns** → Consistent organization reduces cognitive load
- **Efficient Workflow** → Tools and structure optimize development speed
- **Error Prevention** → Organization prevents common mistakes

### **Quality Assurance**
- **Documentation Health** → All content is current, accurate, and useful
- **Code Quality** → Structure supports best practices and maintainability
- **Test Coverage** → Comprehensive testing aligned with code organization
- **Performance Optimization** → Regular profiling and optimization

## 🔄 Unified Maintenance Workflow

### **Regular Consistency Checks**
```bash
# Weekly consistency validation
./scripts/validate_documentation_consistency.sh

# Check for:
# - Consistent naming patterns across both systems
# - Broken cross-references between framework and app docs
# - Orphaned files that should be organized
# - Unwanted README files in subdirectories (should not exist)
```

### **Cross-System Update Workflow**
1. **Framework Changes** → Update both framework technical specs AND app integration guides
2. **App Discoveries** → Update both app usage patterns AND framework enhancement backlog
3. **Performance Updates** → Update both framework targets AND app measurement guides
4. **New Features** → Document in framework specs AND create app integration examples
5. **Major Updates** → Update top-level README.md AND ROADMAP.md to reflect current project state

### **Context Management Principles** 🧠

#### **Predictable Documentation Locations**
- **Technical Question** → `AxiomFramework/Documentation/Technical/`
- **Integration Question** → `AxiomTestApp/Documentation/Integration/`
- **Performance Question** → Both systems have `Performance/` directories
- **Troubleshooting** → `AxiomTestApp/Documentation/Troubleshooting/`

#### **Consistent Cross-References**
```markdown
# Standard cross-reference patterns
[Framework API Spec](../../AxiomFramework/Documentation/Technical/API_DESIGN_SPECIFICATION.md)
[Integration Workflow](../../AxiomTestApp/Documentation/Integration/INTEGRATION_WORKFLOW.md)
[Performance Measurement](../../AxiomTestApp/Documentation/Performance/PERFORMANCE_MEASUREMENT.md)
```

#### **Unified Terminology Management**
- **AxiomClient** → Always refer to actor-based state management
- **AxiomContext** → Always refer to client orchestration + SwiftUI integration
- **AxiomView** → Always refer to 1:1 reactive binding with contexts
- **Framework Integration** → Always refer to real iOS app usage patterns
- **Performance Validation** → Always refer to measurable real-world metrics

### **Documentation Health Metrics** 📊
```bash
# Measure documentation consistency
docs_health_check() {
    echo "📊 Documentation Health Report"
    echo "Framework docs: $(find AxiomFramework/Documentation -name '*.md' | wc -l) files"
    echo "App docs: $(find AxiomTestApp/Documentation -name '*.md' | wc -l) files"
    echo "Broken links: $(find */Documentation -name '*.md' -exec grep -l 'broken' {} \; | wc -l)"
    echo "Unwanted READMEs: $(find */Documentation -name 'README.md' | wc -l) (should be 0)"
}
```

## 🔄 Maintenance Schedule

### **Regular Maintenance** (Enhanced for Dual System)
- **Weekly**: Cross-system consistency validation and broken link checks
- **Monthly**: Terminology alignment and navigation optimization
- **Phase Completion**: Reorganization across both documentation systems
- **Milestone Achievement**: Archive coordination and next phase preparation

### **Trigger Events** (Dual System Aware)
- **Framework Architecture Changes** → Update framework specs AND app integration guides
- **New App Patterns Discovered** → Update app docs AND framework enhancement backlog
- **Performance Optimization** → Update both framework targets AND measurement methodologies
- **Integration Issues** → Update troubleshooting guides AND framework design principles

### **Context Management Success Criteria** ✅
- **Predictable Navigation** → Can find needed info quickly in expected location
- **Consistent Terminology** → Same concepts described same way across both systems
- **Maintained Cross-References** → Links between systems work and provide value
- **Unified Development Flow** → Documentation supports seamless framework → app → framework iteration

## 🚀 Automated Refactor Process

**REFACTOR mode automatically follows unified roadmap priorities:**

1. **Check ROADMAP.md** → Identify phase completion triggers or organizational needs
2. **Assess Current State** → Review documentation health and development environment
3. **Execute Reorganization** → Archive completed work, organize active content, prepare next phase
4. **Validate Structure** → Ensure documentation supports efficient development workflows
5. **Update Planning** → Mark tasks complete (✅) in `/ROADMAP.md` and prepare for next cycle

**Current REFACTOR Priority Order (from ROADMAP.md):**
- **Priority 1**: Archive completed development phase documentation
- **Priority 2**: Organize framework documentation for efficiency
- **Priority 3**: Cross-system consistency validation and maintenance
- **Priority 4**: Prepare structure for advanced features and community expansion

**Three-Cycle Integration:**
- **DEVELOP/INTEGRATE → REFACTOR** → Organize learnings from development cycles
- **REFACTOR → DEVELOP** → Clean structure enables efficient framework development
- **REFACTOR → INTEGRATE** → Well-organized documentation supports testing workflows

**Refactor Triggers:**
- **Phase Completion** → Major development phases finished, need organization
- **Documentation Drift** → Content becomes outdated or poorly organized
- **Development Inefficiency** → Structure is hindering development velocity
- **Cross-System Issues** → Framework and app documentation inconsistencies

**Ready to automatically execute next REFACTOR task from unified roadmap.**

## 🤖 Automated Execution Command

**Trigger**: `@REFACTOR . ultrathink`

**Automated Workflow**:
1. **Read REFACTOR.md** → Load this guide and understand REFACTOR mode mission
2. **Check ROADMAP.md** → Identify phase completion triggers or organizational needs
3. **Assess Current State** → Review documentation health and development environment:
   - Check for completed development phases needing archival
   - Identify outdated, redundant, or poorly organized content
   - Validate dual documentation system consistency
   - Analyze development workflow efficiency
4. **Execute Reorganization** → Archive, organize, and prepare:
   - Move completed phase docs to Archive/ directories
   - Reorganize scattered files into standard categories
   - Validate cross-system consistency and fix broken references
   - Update documentation templates and navigation
5. **Update ROADMAP.md** → Mark completed tasks as ✅ and prepare for next cycle
6. **Validate Structure** → Ensure documentation supports efficient development

**Task Selection Priority**:
- **Priority 1**: Archive completed development phase documentation
- **Priority 2**: Organize framework documentation for efficiency  
- **Priority 3**: Cross-system consistency validation and maintenance
- **Priority 4**: Prepare structure for advanced features and community expansion

**Refactor Operations**:
- **Documentation Consolidation**: Merge duplicates, update currency, improve navigation
- **Code Organization**: Clean dependencies, optimize patterns, align structure
- **Development Environment**: Optimize workspace, improve build performance
- **Cross-System Maintenance**: Validate consistency between framework and app docs

**Success Criteria**:
- ✅ All completed work properly archived and organized
- ✅ Documentation structure supports efficient development workflows
- ✅ Cross-references between framework and app docs work correctly
- ✅ No redundant or outdated content remains
- ✅ Next development phase has clean, prepared structure

**Refactor Triggers**:
- **Phase Completion**: Major development phases finished, need organization
- **Documentation Drift**: Content becomes outdated or poorly organized  
- **Development Inefficiency**: Structure is hindering development velocity
- **Cross-System Issues**: Framework and app documentation inconsistencies

**Ready for automated organization and cleanup on `@REFACTOR . ultrathink` command.**