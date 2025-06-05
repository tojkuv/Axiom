# @RFC_FORMAT.md

**Purpose**: Define feature specification format for application development.

## Required Sections

1. **Metadata Header**
   - Feature ID
   - Title
   - Status (Draft/Active/Implemented)
   - Created/Updated dates

2. **Overview**
   - Feature description
   - User value proposition
   - Success criteria

3. **Technical Specification**
   - Implementation approach
   - Dependencies
   - API changes
   - Data model changes

4. **User Interface**
   - UI/UX requirements
   - Mockups or wireframes
   - User flow diagrams

5. **Testing Strategy**
   - Unit test requirements
   - Integration test scenarios
   - User acceptance criteria

## Workspace Context

All feature specifications must be created and managed within the application-workspace to ensure proper isolation and version control.

```bash
# Feature specs location within workspace
SPECS_DIR="$WORKSPACE_ROOT/AxiomExampleApp/Features/"
```

Defines standard format for application feature specifications.