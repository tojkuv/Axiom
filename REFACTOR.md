# Axiom Framework: Branch-Aware Refactoring System

**Comprehensive code organization and structural improvements across development branches**

## 🤖 Automated Mode Trigger

**When human sends**: `@REFACTOR`
**Action**: Automatically enter ultrathink mode and execute branch-specific refactoring

**Branch-Aware Process**:
1. **Detect Current Branch** → Determine refactoring scope (main, development, integration)
2. **Read REFACTOR.md** → Load this complete branch-aware guide
3. **Check Branch Context** → Understand current work and refactoring needs
4. **Execute Branch-Specific Refactoring** → Organize and improve code within branch scope
5. **Update Progress** → Mark refactoring tasks complete in appropriate documentation
6. **Prepare for Next Work** → Ready clean environment for continued development

## 🎯 REFACTOR Mode Mission

**Primary Focus**: Branch-specific code organization, structural improvements, and quality enhancements to maintain clean, maintainable, and efficient codebase without changing functionality.

**Enhanced Responsibility**: REFACTOR.md is the **Branch-Aware Organization Engine** - providing different refactoring scopes based on current branch context while maintaining code quality and structural integrity.

**Philosophy**: Well-organized code enables rapid development. Clean structure prevents technical debt and accelerates innovation. Branch-specific refactoring ensures focused improvements without cross-branch conflicts.

## 🌿 Branch-Aware Refactoring Contexts

### **Main Branch Refactoring Context**
**Primary Focus**: Stable version tracking, proposal exploration, and documentation organization
**File Scope**: `/Proposals/`, `/AxiomTestApp/Documentation/`, `/AxiomFramework/Documentation/`
**Purpose**: Documentation organization, proposal management, and roadmap maintenance

**What Main Branch REFACTOR Works On**:
- ✅ **Proposal Organization**: Structure and organize `/Proposals/` directory
- ✅ **Framework Documentation**: Organize `/AxiomFramework/Documentation/` structure
- ✅ **Test App Documentation**: Organize `/AxiomTestApp/Documentation/` structure
- ✅ **Documentation Cross-References**: Maintain links and navigation between docs
- ✅ **Archive Management**: Organize completed work into archives
- ✅ **ROADMAP.md Updates**: Coordinate roadmap organization and status updates

**What Main Branch REFACTOR Avoids**:
- ❌ **Framework Source Code**: No changes to `/AxiomFramework/Sources/` (development branch scope)
- ❌ **Test App Source Code**: No changes to `/AxiomTestApp/ExampleApp/` (integration branch scope)
- ❌ **New Feature Implementation**: Focus on organization, not new capabilities
- ❌ **Active Development Work**: No interference with ongoing development/integration

### **Development Branch Refactoring Context**
**Primary Focus**: Framework code organization and structural improvements
**File Scope**: `/AxiomFramework/Sources/`, `/AxiomFramework/Tests/`, framework-related files
**Purpose**: Framework code quality, structure, and maintainability improvements

**What Development Branch REFACTOR Works On**:
- ✅ **Framework Code Organization**: Improve structure in `/AxiomFramework/Sources/`
- ✅ **Module Boundaries**: Optimize module separation and dependencies
- ✅ **Protocol Refactoring**: Consolidate and improve protocol design
- ✅ **API Consistency**: Standardize naming and patterns across framework APIs
- ✅ **Performance Patterns**: Optimize memory management and concurrency patterns
- ✅ **Framework Test Organization**: Improve test structure in `/AxiomFramework/Tests/`
- ✅ **Code Quality**: Remove duplication, improve naming, enhance maintainability
- ✅ **Type Safety**: Enhance type safety and generic usage patterns

**What Development Branch REFACTOR Avoids**:
- ❌ **Test App Code**: No changes to `/AxiomTestApp/ExampleApp/` (integration branch scope)
- ❌ **Documentation Files**: No changes to documentation (main branch scope)
- ❌ **New Framework Features**: Focus on organization, not new capabilities
- ❌ **Breaking API Changes**: Maintain compatibility while improving structure

### **Integration Branch Refactoring Context**
**Primary Focus**: Test app code organization and integration pattern improvements
**File Scope**: `/AxiomTestApp/ExampleApp/`, integration-related files
**Purpose**: Test app code quality, structure, and framework integration optimization

**What Integration Branch REFACTOR Works On**:
- ✅ **Test App Code Organization**: Improve structure in `/AxiomTestApp/ExampleApp/`
- ✅ **Feature Modularization**: Organize features into cohesive modules
- ✅ **View Hierarchy**: Improve SwiftUI view organization and composition
- ✅ **Integration Patterns**: Optimize how test app uses framework capabilities
- ✅ **Macro Usage Consistency**: Ensure consistent macro patterns across domains
- ✅ **Navigation Patterns**: Standardize navigation and routing approaches
- ✅ **State Management**: Optimize context and client usage patterns
- ✅ **Performance Optimization**: Improve app performance and memory usage
- ✅ **Business Logic Separation**: Move logic to appropriate clients/contexts

**What Integration Branch REFACTOR Avoids**:
- ❌ **Framework Source Code**: No changes to `/AxiomFramework/Sources/` (development branch scope)
- ❌ **Documentation Files**: No changes to documentation (main branch scope)
- ❌ **New Integration Features**: Focus on organization, not new test scenarios
- ❌ **Framework API Changes**: Work within existing framework capabilities

## 🔧 Branch-Specific Refactoring Capabilities

### **Main Branch Refactoring Operations**

#### **Proposal Management (`/Proposals/`)**
- **Proposal Organization**: Structure active, approved, and archived proposals
- **Template Maintenance**: Update and organize proposal templates
- **Cross-Reference Updates**: Maintain links between proposals and implementation
- **Archive Cleanup**: Organize completed and deprecated proposals
- **Analysis File Updates**: Maintain supporting analysis and benchmark data

#### **Documentation Organization (`/AxiomFramework/Documentation/`, `/AxiomTestApp/Documentation/`)**
- **Structure Optimization**: Improve documentation navigation and organization
- **Content Consolidation**: Merge duplicates and remove outdated content
- **Cross-Reference Maintenance**: Ensure all internal links work correctly
- **Archive Management**: Move completed phase documentation to archives
- **Index Updates**: Maintain documentation indices and navigation

#### **ROADMAP.md Coordination**
- **Status Updates**: Coordinate roadmap organization and cleanup
- **Archive Integration**: Connect roadmap to archived work
- **Priority Organization**: Structure priorities and upcoming work
- **Cross-Terminal Status**: Maintain terminal coordination information

### **Development Branch Refactoring Operations**

#### **Framework Code Structure (`/AxiomFramework/Sources/`)**
- **File Reorganization**: Move files to logical directory structures
- **Module Separation**: Split large files into focused modules
- **Import Cleanup**: Remove unused imports, organize import statements
- **Naming Consistency**: Improve class, protocol, and method names
- **Code Deduplication**: Extract common patterns into reusable utilities

#### **Protocol & API Refactoring**
- **Protocol Consolidation**: Merge similar protocols or split complex ones
- **API Consistency**: Ensure consistent naming and parameter patterns
- **Extension Organization**: Group related extensions appropriately
- **Access Control**: Optimize public/internal/private access levels
- **Generic Optimization**: Improve generic usage and type safety

#### **Performance & Quality**
- **Memory Management**: Improve weak/strong reference patterns
- **Actor Isolation**: Optimize actor usage and isolation boundaries
- **Error Handling**: Standardize error patterns and propagation
- **Concurrency Patterns**: Improve async/await usage and Task coordination
- **Type Safety**: Enhance type safety through better design

### **Integration Branch Refactoring Operations**

#### **Test App Structure (`/AxiomTestApp/ExampleApp/`)**
- **Feature Modularization**: Organize features into clear modules
- **View Extraction**: Break down large views into reusable components
- **Navigation Standardization**: Improve routing and navigation patterns
- **Resource Organization**: Better asset and resource file organization
- **State Management**: Optimize context and client coordination

#### **Integration Pattern Optimization**
- **Framework Usage**: Optimize how test app uses framework capabilities
- **Macro Consistency**: Ensure consistent macro usage across domains
- **Business Logic Separation**: Move logic to appropriate layers
- **Error Handling**: Standardize error handling in UI layer
- **Performance Patterns**: Improve app responsiveness and memory usage

#### **Code Quality & Consistency**
- **Naming Conventions**: Ensure consistent naming across test app
- **SwiftUI Patterns**: Standardize view composition and state management
- **Test Data Organization**: Improve mock data and scenario organization
- **Integration Documentation**: Align code with usage examples
- **Validation Patterns**: Improve testing and validation approaches

## 🎯 Branch-Specific Refactoring Priorities

### **Main Branch Priorities**
1. **Documentation Structure**: Organize docs for efficient navigation and maintenance
2. **Proposal Management**: Maintain clean proposal workflow and archives
3. **ROADMAP Coordination**: Keep roadmap organized and focused
4. **Archive Organization**: Properly structure completed work archives
5. **Cross-Reference Maintenance**: Ensure all documentation links work correctly

### **Development Branch Priorities**
1. **Framework Code Quality**: Improve structure, naming, and maintainability
2. **API Consistency**: Standardize patterns across framework interfaces
3. **Performance Optimization**: Improve memory management and concurrency
4. **Module Organization**: Optimize boundaries and dependencies
5. **Type Safety**: Enhance type safety and error handling patterns

### **Integration Branch Priorities**
1. **Test App Structure**: Improve modularization and view organization
2. **Integration Patterns**: Optimize framework usage and macro consistency
3. **Performance**: Improve app responsiveness and memory usage
4. **Code Quality**: Standardize naming and patterns across test app
5. **Business Logic**: Properly separate concerns and improve architecture

## 🔄 Branch-Aware Refactoring Workflow

### **Automated Branch Detection**
```bash
# Main Branch Context
if on main branch:
    scope = ["/Proposals/", "/AxiomTestApp/Documentation/", "/AxiomFramework/Documentation/"]
    focus = "Documentation organization and proposal management"

# Development Branch Context  
elif on development branch:
    scope = ["/AxiomFramework/Sources/", "/AxiomFramework/Tests/"]
    focus = "Framework code organization and quality improvements"

# Integration Branch Context
elif on integration branch:
    scope = ["/AxiomTestApp/ExampleApp/"]
    focus = "Test app code organization and integration optimization"
```

### **Branch-Specific Execution Process**

#### **Phase 1: Context Analysis**
1. **Detect Current Branch** → Determine refactoring scope and priorities
2. **Assess Branch State** → Understand current work and refactoring needs
3. **Review Scope Files** → Analyze files within branch refactoring scope
4. **Identify Improvements** → Find organization and quality opportunities
5. **Plan Refactoring** → Define specific improvements to implement

#### **Phase 2: Refactoring Execution**
1. **Structure Improvements** → File organization and module boundaries
2. **Code Quality** → Naming, deduplication, and pattern standardization
3. **Documentation Sync** → Align code with documentation where applicable
4. **Cross-Reference Updates** → Maintain links and dependencies
5. **Performance Optimization** → Memory and concurrency pattern improvements

#### **Phase 3: Validation & Cleanup**
1. **Build Validation** → Ensure all refactoring maintains functionality
2. **Test Execution** → Verify tests pass after structural changes
3. **Documentation Updates** → Update relevant documentation for changes
4. **Quality Verification** → Confirm improvements meet quality standards
5. **Progress Tracking** → Mark refactoring tasks complete

## 🚀 Refactoring Success Metrics

### **Main Branch Success Criteria**
- ✅ Documentation is well-organized and easily navigable
- ✅ Proposals directory maintains clean workflow and archives
- ✅ All documentation cross-references work correctly
- ✅ ROADMAP.md is organized and focused
- ✅ Archived work is properly structured and accessible

### **Development Branch Success Criteria**
- ✅ Framework code has clear structure and module boundaries
- ✅ API patterns are consistent across framework interfaces
- ✅ Code quality improvements reduce technical debt
- ✅ Performance patterns are optimized for memory and concurrency
- ✅ Type safety and error handling are enhanced

### **Integration Branch Success Criteria**
- ✅ Test app code is well-modularized and organized
- ✅ Framework integration patterns are consistent and optimized
- ✅ SwiftUI views are properly composed and reusable
- ✅ Business logic is properly separated across layers
- ✅ App performance and memory usage are optimized

## 🔧 Refactoring Guidelines

### **Code Organization Principles**
- **Single Responsibility**: Each file and module has clear, focused purpose
- **Logical Grouping**: Related functionality is grouped together
- **Consistent Naming**: Names clearly communicate purpose and usage
- **Minimal Dependencies**: Reduce unnecessary coupling between modules
- **Clear Interfaces**: Public APIs are intuitive and well-designed

### **Quality Improvement Standards**
- **No Functionality Changes**: Refactoring improves structure without changing behavior
- **Maintain Compatibility**: API changes preserve backward compatibility
- **Improve Readability**: Code is easier to understand and maintain
- **Reduce Duplication**: Common patterns are extracted and reused
- **Enhance Performance**: Memory and performance patterns are optimized

### **Branch Coordination Rules**
- **Scope Respect**: Only work within designated branch scope
- **No Cross-Branch Changes**: Avoid changes that affect other branch scopes
- **Documentation Sync**: Keep code aligned with branch-appropriate documentation
- **Quality Focus**: Prioritize quality improvements over new functionality
- **Build Safety**: Ensure all changes maintain working builds and tests

---

**REFACTOR STATUS**: Branch-aware refactoring system with context-specific scopes ✅  
**MAIN SCOPE**: `/Proposals/`, `/AxiomTestApp/Documentation/`, `/AxiomFramework/Documentation/`  
**DEVELOPMENT SCOPE**: `/AxiomFramework/Sources/`, `/AxiomFramework/Tests/`  
**INTEGRATION SCOPE**: `/AxiomTestApp/ExampleApp/`  
**AUTOMATION READY**: Supports `@REFACTOR . ultrathink` for branch-aware organization  
**QUALITY FOCUSED**: Structural improvements and code quality without functionality changes

**Use this system for branch-specific code organization and quality improvements while maintaining focused development workflows.**