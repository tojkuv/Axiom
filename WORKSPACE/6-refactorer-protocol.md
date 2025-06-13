# CODEBASE-REFACTORER-PROTOCOL

Transform source codebase through systematic refactoring to eliminate technical debt and improve maintainability.

## Activation
```
@CODEBASE_REFACTORER execute <refactoring_directory>
```

*Note: The refactoring directory contains the source code to be transformed through systematic refactoring.*

## Process
1. **Assess** - Analyze code quality, technical debt, and organization issues in the refactoring directory
2. **Clean** - Remove dead code, unused imports, obsolete tests from the existing codebase
3. **Reorganize** - Improve folder structure, file locations, naming conventions within the directory
4. **Restructure** - Optimize file composition and break/combine files appropriately
5. **Validate** - Ensure zero functionality loss while improving quality in the refactored codebase

## Refactoring Areas
- **Dead Code Elimination** - Remove unused classes, methods, imports, variables
- **Structural Organization** - Optimize folder hierarchy and file locations
- **Naming Standardization** - Apply consistent naming conventions
- **File Composition** - Balance file sizes and improve code locality

## Outputs
- Clean, well-organized, maintainable codebase
- Eliminated dead code and technical debt
- Consistent naming patterns and structure
- Enhanced developer experience and code clarity

## Success Criteria
- All functionality preserved throughout transformation
- Code quality significantly improved
- Maintainability optimized for future development
- Zero regressions in build or test results

## Artifact Template

*Generated as refactoring session report*

# REFACTORER-SESSION-{TIMESTAMP}

*Codebase Refactoring Report*

## Meta-Data
- **Date**: {DATE}
- **Artifact Type**: Session
- **Refactoring Directory**: {REFACTORING_DIRECTORY}
- **Refactoring Type**: {REFACTORING_TYPE}
- **Areas Addressed**: {REFACTORING_AREAS}

## Refactoring Work
### Dead Code Elimination
{DEAD_CODE_REMOVED}

### Structural Improvements
{STRUCTURAL_CHANGES}

### Naming Standardization
{NAMING_IMPROVEMENTS}

### File Composition
{FILE_COMPOSITION_CHANGES}

## Quality Improvements
### Before/After Metrics
- Dead code: {DEAD_CODE_COUNT} → 0
- File organization: {ORGANIZATION_BEFORE} → {ORGANIZATION_AFTER}
- Naming consistency: {NAMING_BEFORE}% → {NAMING_AFTER}%
- Maintainability: {MAINTAINABILITY_BEFORE} → {MAINTAINABILITY_AFTER}

### Validation Results
- Build status: {BUILD_STATUS}
- Test results: {TEST_RESULTS}
- Functionality preserved: {FUNCTIONALITY_STATUS}

## Developer Experience
{DEVELOPER_EXPERIENCE_IMPROVEMENTS}