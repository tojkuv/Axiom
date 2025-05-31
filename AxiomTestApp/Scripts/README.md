# AxiomTestApp Scripts

This directory contains Python utilities for managing the AxiomTestApp Xcode project structure and file organization.

## 📁 Available Scripts

### 🔄 `sync_files_to_xcode.py`
**Purpose**: Comprehensive synchronization of all Swift files with the Xcode project  
**Function**: Ensures Xcode sees and includes all Swift files in the project automatically  
**Usage**: Run when adding new Swift files or reorganizing project structure  
**Key Features**:
- Recursively finds all Swift files in ExampleApp directory
- Excludes build artifacts and temporary directories
- Automatically generates Xcode project entries with proper UUIDs
- Maintains proper file grouping and organization

### ➕ `add_files_to_project.py` 
**Purpose**: Add missing Swift files to Xcode project configuration  
**Function**: Updates project.pbxproj file to include all Swift files in ExampleApp directory  
**Usage**: Run when Xcode doesn't recognize newly created Swift files  
**Key Features**:
- Discovers Swift files missing from Xcode project
- Generates proper PBXFileReference and PBXBuildFile entries
- Maintains relative path structure for organization
- Updates build phases automatically

### 🆕 `create_clean_project.py`
**Purpose**: Create a clean, properly structured Xcode project from scratch  
**Function**: Removes incorrectly added files and creates proper project structure  
**Usage**: Use when project file becomes corrupted or improperly configured  
**Key Features**:
- Generates clean project.pbxproj with essential files only
- Includes core files like ExampleAppApp.swift, ContentView.swift
- Sets up proper build configuration and targets
- Removes invalid entries and references

### 🔧 `fix_file_paths.py`
**Purpose**: Fix incorrect relative paths in Xcode project file  
**Function**: Corrects path references to ensure proper file organization  
**Usage**: Run when files are moved or project organization changes  
**Key Features**:
- Defines proper relative paths for domain-organized files
- Fixes User domain files: `Domains/User/UserClient.swift`, etc.
- Fixes Data domain files: `Domains/Data/DataClient.swift`, etc.
- Corrects Integration folder references
- Updates file references throughout project configuration

## 🚀 Usage Guidelines

### **When to Use Each Script**

1. **New Swift Files Added**: `add_files_to_project.py`
2. **Project Structure Changed**: `sync_files_to_xcode.py`
3. **Project File Corrupted**: `create_clean_project.py`
4. **Files Moved/Reorganized**: `fix_file_paths.py`

### **Execution Order for Major Reorganization**
```bash
# 1. Create clean foundation
python3 create_clean_project.py

# 2. Fix path references
python3 fix_file_paths.py

# 3. Add all missing files
python3 add_files_to_project.py

# 4. Final synchronization
python3 sync_files_to_xcode.py
```

### **Safety Notes**
- Always backup `project.pbxproj` before running scripts
- Close Xcode before running any project modification scripts
- Run scripts from the AxiomTestApp root directory
- Verify Xcode project loads correctly after script execution

## 🎯 Integration with Refactoring

These scripts support the integration branch refactoring goals:
- **Script Organization**: Centralized in dedicated Scripts/ folder
- **Project Maintenance**: Automated Xcode project file management
- **Structure Optimization**: Proper file organization and references
- **Build Configuration**: Ensures all source files are included in build

## 📋 Maintenance

**Script Evaluation Status**:
- ✅ `sync_files_to_xcode.py` - **Active** (comprehensive synchronization)
- ✅ `add_files_to_project.py` - **Active** (incremental file addition)
- ⚠️ `create_clean_project.py` - **Maintenance** (use for major restructuring only)
- ✅ `fix_file_paths.py` - **Active** (path correction after reorganization)

**Consolidation Notes**:
- All scripts serve distinct purposes and should be retained
- `create_clean_project.py` should be used sparingly for major resets
- Regular workflow uses `add_files_to_project.py` and `sync_files_to_xcode.py`
- `fix_file_paths.py` is essential for maintaining proper organization

---

**For questions or issues with these scripts, refer to the AxiomTestApp documentation or REFACTOR.md guidelines.**