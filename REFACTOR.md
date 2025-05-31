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
**Primary Focus**: AxiomTestApp organization, structure optimization, and production-ready app code
**File Scope**: `/AxiomTestApp/ExampleApp/`, `/AxiomTestApp/Scripts/`, project organization
**Purpose**: Clean, maintainable test app with standardized naming and optimal file organization

**What Integration Branch REFACTOR Works On**:
- ✅ **Script Organization**: Create `/AxiomTestApp/Scripts/` and consolidate Python utilities
- ✅ **File Cleanup**: Remove backup files and unused artifacts (ContentView_Backup.swift)
- ✅ **Naming Standardization**: Implement concise, semantic naming conventions across all files
- ✅ **Folder Structure Optimization**: Ensure logical organization of domains, views, and utilities
- ✅ **Macro Demonstration Clarity**: Clear separation between production code and macro examples
- ✅ **Project File Management**: Optimize Xcode project structure and build organization
- ✅ **Integration Pattern Standards**: Consistent framework usage patterns across domains
- ✅ **View Architecture**: Optimize SwiftUI view hierarchy and composition patterns
- ✅ **Domain Organization**: Standardize domain structure (Client, Context, State, View patterns)
- ✅ **Example vs Production**: Clear distinction between example/demo code and production patterns

**What Integration Branch REFACTOR Avoids**:
- ❌ **Framework Source Code**: No changes to `/AxiomFramework/Sources/` (development branch scope)
- ❌ **Documentation Organization**: No changes to documentation structure (main branch scope)
- ❌ **Macro Implementation**: Focus on organization, not macro feature development
- ❌ **API Design Changes**: Work within existing framework capabilities

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

#### **Project Organization & Scripts (`/AxiomTestApp/`)**
- **Scripts Folder Creation**: Create `/AxiomTestApp/Scripts/` directory for Python utilities
- **Script Consolidation**: Move all `.py` files to Scripts/ folder:
  - `sync_files_to_xcode.py` → `Scripts/sync_files_to_xcode.py`
  - `add_files_to_project.py` → `Scripts/add_files_to_project.py`
  - `create_clean_project.py` → `Scripts/create_clean_project.py`
  - `fix_file_paths.py` → `Scripts/fix_file_paths.py`
- **Script Evaluation**: Assess which scripts are actively needed vs redundant
- **Script Documentation**: Add README.md in Scripts/ explaining each utility

#### **File Cleanup & Naming Standards (`/AxiomTestApp/ExampleApp/`)**
- **Backup File Removal**: Delete `ContentView_Backup.swift` and similar artifacts
- **Semantic Naming**: Standardize file names to be concise and descriptive:
  - Clear purpose indication in names
  - Consistent suffixes (Client, Context, State, View)
  - Remove ambiguous or temporary naming
- **Folder Structure**: Optimize directory organization for logical navigation
- **Build Artifact Cleanup**: Remove files not included in Xcode project build

#### **Domain Structure Standardization**
- **Consistent Domain Pattern**: Ensure all domains follow Client/Context/State/View structure
- **Macro Example Clarity**: Clear naming distinction between production and macro demonstration files:
  - Production files: `UserClient.swift`, `UserContext.swift`
  - Macro examples: `UserClient_MacroEnabled.swift` (clearly marked as demonstrations)
- **Import Optimization**: Clean up unnecessary imports and dependencies
- **File Location Logic**: Ensure files are in appropriate folders based on responsibility

#### **Integration Pattern Optimization**
- **Framework Usage Standards**: Consistent patterns for using Axiom framework across domains
- **View Architecture**: Optimize SwiftUI view composition and reusability
- **Navigation Patterns**: Standardize routing and navigation approaches
- **State Management**: Consistent context and client coordination patterns
- **Error Handling**: Standardized error handling patterns in UI and business logic

#### **Project File Management**
- **Xcode Project Optimization**: Ensure all source files are properly included in build
- **Asset Organization**: Optimize asset and resource file structure
- **Build Configuration**: Clean build settings and remove unused configurations
- **Dependency Management**: Optimize framework dependency resolution

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
1. **Script Organization**: Create Scripts/ folder and consolidate Python utilities for maintainability
2. **File Cleanup**: Remove backup files and unused artifacts to clean up project structure
3. **Naming Standardization**: Implement concise, semantic naming conventions across all files and folders
4. **Domain Structure**: Ensure consistent Client/Context/State/View patterns across all domains
5. **Project Organization**: Optimize Xcode project structure and build configuration for efficiency
6. **Example Clarity**: Clear separation between production code and macro demonstration files
7. **Integration Patterns**: Standardize framework usage and SwiftUI architecture patterns

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
- ✅ Scripts are organized in dedicated `/AxiomTestApp/Scripts/` folder with clear documentation
- ✅ All backup files and build artifacts are removed from project
- ✅ File and folder names follow concise, semantic naming conventions throughout
- ✅ Domain structure is consistent with clear Client/Context/State/View patterns
- ✅ Production code is clearly separated from macro demonstration examples
- ✅ Xcode project structure is optimized with all necessary files included in build
- ✅ Framework integration patterns are standardized across all domains
- ✅ SwiftUI architecture follows consistent composition and state management patterns

## 🔧 Refactoring Guidelines

### **Integration Branch Naming Conventions**

#### **File Naming Standards**
- **Domain Files**: `{Domain}{Type}.swift` (e.g., `UserClient.swift`, `DataContext.swift`)
- **Macro Examples**: `{Domain}{Type}_MacroEnabled.swift` (clearly marked as demonstrations)
- **Views**: `{Purpose}View.swift` (e.g., `CounterView.swift`, `LoadingView.swift`)
- **Utilities**: `{Purpose}{Type}.swift` (e.g., `ApplicationCoordinator.swift`)
- **No Underscores**: Avoid except for macro examples (e.g., no `user_client.swift`)
- **No Abbreviations**: Use full words for clarity (e.g., `NavigationController`, not `NavController`)

#### **Folder Naming Standards**
- **Domains**: Single word, PascalCase (e.g., `User/`, `Data/`, `Analytics/`)
- **Feature Groups**: Descriptive, PascalCase (e.g., `Integration/`, `Examples/`, `Utils/`)
- **Scripts**: Dedicated `Scripts/` folder at `/AxiomTestApp/Scripts/`
- **No Plurals**: Use singular names (e.g., `Model/`, not `Models/`)

#### **Scripts Organization**
- **Location**: `/AxiomTestApp/Scripts/` (dedicated folder)
- **Naming**: Descriptive, snake_case for Python files (e.g., `sync_files_to_xcode.py`)
- **Documentation**: `Scripts/README.md` explaining each utility's purpose
- **Consolidation**: Remove redundant or unused scripts

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
**INTEGRATION SCOPE**: `/AxiomTestApp/ExampleApp/`, `/AxiomTestApp/Scripts/`, project organization  
**AUTOMATION READY**: Supports `@REFACTOR . ultrathink` for branch-aware organization  
**INTEGRATION FOCUS**: Script consolidation, naming standards, file cleanup, and structure optimization

**Integration Branch Refactoring Priorities:**
1. 🗂️ **Script Organization** - Create `/AxiomTestApp/Scripts/` and consolidate Python utilities
2. 🧹 **File Cleanup** - Remove backup files and unused artifacts  
3. 📝 **Naming Standards** - Implement concise, semantic naming conventions
4. 🏗️ **Structure Optimization** - Ensure logical organization and clear domain patterns
5. 📱 **Project Organization** - Optimize Xcode project and build configuration

**Use this system for AxiomTestApp organization and structure improvements while maintaining framework integration quality.**