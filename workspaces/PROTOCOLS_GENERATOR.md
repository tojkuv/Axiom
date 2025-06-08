# PROTOCOLS_GENERATOR.md

Protocol generator specification for Axiom architectural development cycles.

## Overview

The protocol generator is the single source of truth for creating all Axiom development protocols. It ensures consistent, comprehensive protocol generation through a structured multi-step process with dedicated refinement phases.

## Generation Principles

- **Deterministic**: Each protocol type generates consistent output from the same specifications
- **Hierarchical**: Maintains clear separation between workspace artifacts and codebase implementations
- **Cyclic**: Protocols follow the development cycle flow with proper input/output dependencies
- **Template-Driven**: All paths and patterns use resolvable template variables for portability
- **Comprehensive**: Each section receives focused attention to ensure thorough coverage
- **Quality-Assured**: Final revision phase ensures consistency and fixes minor issues
- **Step-by-Step**: Protocol generation follows four discrete steps for thoroughness
- **Refinement-Focused**: Dedicated final step for refactoring and small fixes

## Protocol Specifications

- **framework-plan**: Creates FRAMEWORK_PLAN_PROTOCOL.md for requirements gathering and cycle initiation
- **framework-develop**: Creates FRAMEWORK_DEVELOP_PROTOCOL.md for TDD implementation with session tracking
- **framework-document**: Creates FRAMEWORK_DOCUMENT_PROTOCOL.md for comprehensive architectural documentation
- **framework-analyze**: Creates FRAMEWORK_ANALYZE_PROTOCOL.md for framework improvement insights
- **application-plan**: Creates APPLICATION_PLAN_PROTOCOL.md for application requirements (task-manager or local-chat)
- **application-develop**: Creates APPLICATION_DEVELOP_PROTOCOL.md for application TDD implementation with framework documentation reference
- **application-analyze**: Creates APPLICATION_ANALYZE_PROTOCOL.md for framework validation through application implementation

## Protocol Naming Convention

All generated protocol files follow the standardized naming pattern:
```text
[FRAMEWORK/APPLICATION]_[PLAN/DEVELOP/DOCUMENT/ANALYZE]_PROTOCOL.md
```

Examples:
- `FRAMEWORK_PLAN_PROTOCOL.md`
- `APPLICATION_DEVELOP_PROTOCOL.md`
- `FRAMEWORK_ANALYZE_PROTOCOL.md`

## Protocol Structure Requirements

### Required Sections (All Protocols)

1. **Header**: Protocol name and trigger pattern
2. **Commands**: All available commands with syntax and outputs
3. **Core Process**: Linear flow with philosophy and workflow rule
4. **Format Specifications**: Complete templates (artifact protocols only)
5. **Workflow**: Detailed procedures and state management
6. **Technical Details**: Paths, validation, persistence requirements
7. **Error Handling**: Error types and recovery procedures

## Generation Processes

### Protocol Generation Process (4 Steps)

Used when generating the protocol files themselves:

#### Step 1: Structure Analysis
**Objective**: Define the complete structure and purpose of the protocol
- Analyze the protocol's role in the development cycle
- Map relationships with other protocols (inputs/outputs)
- Identify all required sections and their purposes
- Define command patterns and argument structures
- Establish validation and error handling requirements
- Document state management needs
- Create section outline with dependencies

#### Step 2: Content Generation
**Objective**: Generate comprehensive protocol content
- Generate protocol header with trigger patterns
- Create detailed command specifications
- Develop complete artifact format templates
- Write workflow procedures with state tracking
- Define technical requirements and paths
- Create error handling specifications
- Generate example usage patterns

#### Step 3: Integration Validation
**Objective**: Ensure protocol integrates seamlessly
- Verify all cross-protocol references
- Validate template variable usage
- Check path resolution accuracy
- Ensure command output matches next protocol's input
- Validate artifact naming conventions
- Confirm cycle flow integrity
- Test example commands for correctness

#### Step 4: Final Refinement
**Objective**: Refactor and apply finishing touches
- Refactor repetitive patterns into templates
- Consolidate similar command structures
- Fix formatting inconsistencies
- Correct typos and grammar
- Optimize section organization
- Add missing cross-references
- Enhance code example clarity
- Simplify complex explanations
- Ensure consistent terminology
- Validate all markdown formatting

## Development Cycle Flow

The development cycle follows a continuous loop of framework improvement validated through application development:

1. **Framework PLAN**
   - Type: Artifact-generating protocol (creates cycle folder)
   - Input: Optional Framework ANALYSIS from previous cycle
   - Output: `{{FRAMEWORK_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md`
   - Features: Interactive exploration and final revision phases

2. **Framework DEVELOP**
   - Type: Code-generating protocol (produces implementation + metrics)
   - Input: Framework REQUIREMENTS from cycle folder
   - Output: Updated implementation in `{{FRAMEWORK_CODEBASE}}/`
   - Metrics: `FW-SESSION-*.md` in SESSIONS folder
   - Features: Multi-session support, TDD approach, progress tracking

3. **Framework DOCUMENT**
   - Type: Artifact-generating protocol (one per cycle)
   - Input: Current framework implementation
   - Output: `DOCUMENTATION-XXX.md` in cycle folder
   - Features: Complete architectural specification

4. **Application PLAN**
   - Type: Artifact-generating protocol (creates cycle folder)
   - Input: Framework DOCUMENTATION from cycle folder
   - Output: `{{APPLICATION_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md`
   - Features: Application requirements with framework integration focus

5. **Application DEVELOP**
   - Type: Code-generating protocol (produces implementation + metrics)
   - Input: Application REQUIREMENTS from cycle folder + Framework DOCUMENTATION from cycle folder
   - Output: Application in `{{APPLICATION_CODEBASE}}/[ApplicationType]-XXX-[TITLE]/`
   - Metrics: `APP-SESSION-*.md` in SESSIONS folder
   - Features: Multi-session support, TDD approach, progress tracking

6. **Application ANALYZE**
   - Type: Artifact-generating protocol
   - Input: Application implementation + REQUIREMENTS + Documentation + session metrics
   - Output: `ANALYSIS-XXX.md` in Application cycle folder
   - Features: Aggregates session insights, identifies friction points

7. **Framework ANALYZE**
   - Type: Artifact-generating protocol
   - Input: Application ANALYSIS + current framework + session metrics
   - Output: `ANALYSIS-XXX.md` in Framework cycle folder
   - Features: Aggregates insights for next cycle

The cycle returns to step 1 with analysis insights driving continuous improvement.

## Protocol Generation Commands

### Individual Protocol Generation
```text
@PROTOCOLS_GENERATOR generate framework-plan      → Generate FRAMEWORK_PLAN_PROTOCOL.md
  - Step 1: Analyze requirements gathering needs
  - Step 2: Generate comprehensive protocol content
  - Step 3: Validate cycle integration
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate framework-develop   → Generate FRAMEWORK_DEVELOP_PROTOCOL.md
  - Step 1: Analyze TDD implementation needs
  - Step 2: Generate session tracking protocol
  - Step 3: Validate metrics integration
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate framework-document  → Generate FRAMEWORK_DOCUMENT_PROTOCOL.md
  - Step 1: Analyze documentation requirements
  - Step 2: Generate comprehensive doc protocol
  - Step 3: Validate codebase scanning approach
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate framework-analyze   → Generate FRAMEWORK_ANALYZE_PROTOCOL.md
  - Step 1: Analyze improvement tracking needs
  - Step 2: Generate analysis protocol
  - Step 3: Validate metrics aggregation
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate application-plan    → Generate APPLICATION_PLAN_PROTOCOL.md
  - Step 1: Analyze application requirements needs
  - Step 2: Generate app-specific protocols
  - Step 3: Validate framework integration
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate application-develop → Generate APPLICATION_DEVELOP_PROTOCOL.md
  - Step 1: Analyze app development needs
  - Step 2: Generate implementation protocol
  - Step 3: Validate framework usage tracking
  - Step 4: Refine and finalize

@PROTOCOLS_GENERATOR generate application-analyze → Generate APPLICATION_ANALYZE_PROTOCOL.md
  - Step 1: Analyze validation requirements
  - Step 2: Generate analysis protocol
  - Step 3: Validate feedback mechanisms
  - Step 4: Refine and finalize
```

### Batch Protocol Generation
```text
@PROTOCOLS_GENERATOR generate all-framework   → Generate all Framework protocols
  - Executes all four steps for each framework protocol
  - Performs cross-protocol consistency check
  - Final refinement pass across all protocols

@PROTOCOLS_GENERATOR generate all-application → Generate all Application protocols
  - Executes all four steps for each application protocol
  - Performs cross-protocol consistency check
  - Final refinement pass across all protocols

@PROTOCOLS_GENERATOR generate all             → Generate all protocols (7 files total)
  - Executes complete generation process for all protocols
  - Performs comprehensive cross-protocol validation
  - Final refinement and consistency pass
```

## Command Pattern Specifications

### Basic Command Pattern
```text
{{COMMAND}} {{ARGUMENTS}} → {{ACTION_DESCRIPTION}}
```

### Artifact-Generating Command Pattern
```text
{{COMMAND}} {{ARGUMENTS}} → {{ACTION}} + Generates {{ARTIFACT_TYPE}}
  - Uses: {{FORMAT_SPECIFICATION}}
  - Output: {{OUTPUT_PATH_PATTERN}}
```

### State-Tracking Command Pattern
```text
{{COMMAND}} {{IDENTIFIER}} → {{CONTINUATION_ACTION}}
  - Tracks: {{PROGRESS_LOCATION}}
  - Updates: {{STATE_REFERENCE}}
```

## Protocol Command References

### Framework PLAN Protocol Commands
```text
generate → Generate comprehensive framework requirements through multi-phase process
  - Phase 1: Analyze previous cycle insights and current framework state
  - Phase 2: Generate structured requirements with TDD focus
  - Phase 3: Review and revise for consistency and completeness
  - Output: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md
```

### Framework DEVELOP Protocol Commands
```text
start {{REQUIREMENTS_ID}} → Begin test-driven framework implementation
  - Creates: First framework session metrics file FW-SESSION-XXX.md
  - Tracks: Framework requirement checklist initialization

resume {{REQUIREMENTS_ID}} → Continue framework implementation
  - Creates: New framework session metrics file
  - Updates: Framework progress tracking

finalize {{REQUIREMENTS_ID}} → Optimize and complete framework
  - Updates: Final framework cleanup and optimization

test {{REQUIREMENTS_ID}} → Run complete framework test suite
  - Validates: All framework requirements met
```

### Framework DOCUMENT Protocol Commands
```text
generate → Create comprehensive framework documentation
  - Scans: Entire framework codebase at {{FRAMEWORK_CODEBASE}}
  - Output: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX/DOCUMENTATION-XXX.md
  - Rule: One documentation artifact per framework cycle
```

### Framework ANALYZE Protocol Commands
```text
generate → Create framework improvement analysis
  - Aggregates: Application analysis + framework session metrics
  - Output: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX/ANALYSIS-XXX.md

compare {{ID1}} {{ID2}} → Compare framework analysis reports
  - Output: Framework evolution between cycles
```

### Application PLAN Protocol Commands
```text
generate {{APPLICATION_TYPE}} → Generate comprehensive application requirements through multi-phase process
  - Phase 1: Analyze framework documentation and previous implementations
  - Phase 2: Generate structured application requirements with framework integration focus
  - Phase 3: Review and revise for consistency and framework alignment
  - Application Types: task-manager | local-chat
  - Input: Framework documentation from current cycle
  - Output: {{APPLICATION_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md

@APPLICATION_PLAN generate task-manager    → Generate task management app requirements
@APPLICATION_PLAN generate local-chat      → Generate local chat app requirements
```

### Application DEVELOP Protocol Commands
```text
start {{REQUIREMENTS_ID}} → Begin test-driven application implementation
  - Creates: First application session metrics file APP-SESSION-XXX.md
  - Tracks: Application requirement checklist initialization
  - References: Framework documentation from current cycle

resume {{REQUIREMENTS_ID}} → Continue application implementation
  - Creates: New application session metrics file
  - Updates: Application progress tracking
  - References: Framework documentation for API usage

finalize {{REQUIREMENTS_ID}} → Optimize and complete application
  - Updates: Final application cleanup and optimization

test {{REQUIREMENTS_ID}} → Run complete application test suite
  - Validates: All application requirements met
```

### Application ANALYZE Protocol Commands
```text
generate {{APPLICATION_PATH}} → Create application analysis report
  - Aggregates: Implementation + requirements + session metrics
  - Output: {{APPLICATION_WORKSPACE}}/CYCLE-XXX/ANALYSIS-XXX.md

compare {{ID1}} {{ID2}} → Compare application analysis reports
  - Output: Application evolution between cycles
```

## Path Resolution Reference

### Template Variable Resolutions
- `{{FRAMEWORK}}` → Framework
- `{{APPLICATION}}` → Application
- `{{FRAMEWORK_CODEBASE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework`
- `{{APPLICATION_CODEBASE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplications`
- `{{FRAMEWORK_WORKSPACE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace`
- `{{APPLICATION_WORKSPACE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/ApplicationWorkspace`

### File System Structure

#### Workflow Artifacts Structure
```text
{{FRAMEWORK_WORKSPACE}}/
└── CYCLE-XXX-[TITLE]/
    ├── REQUIREMENTS-XXX-[TITLE].md
    ├── DOCUMENTATION-XXX.md
    ├── ANALYSIS-XXX.md
    └── SESSIONS/
        └── FW-SESSION-XXX.md

{{APPLICATION_WORKSPACE}}/
└── CYCLE-XXX-[TITLE]/
    ├── REQUIREMENTS-XXX-[TITLE].md
    ├── ANALYSIS-XXX.md
    └── SESSIONS/
        └── APP-SESSION-XXX.md
```

#### Implementation Codebase Structure
```text
{{FRAMEWORK_CODEBASE}}/
└── [Framework implementation files]

{{APPLICATION_CODEBASE}}/
└── [ApplicationType]-XXX-[TITLE]/
    └── [Application implementation files]
```

## Application Types

The protocol generator supports two application types for framework validation:

### task-manager
- **Description**: Offline multiplatform task management application (iOS and macOS) with no online or sync capabilities
- **Framework Validation Focus**:
  - State management and persistence
  - CRUD operations and data modeling
  - UI component integration
  - Cross-platform compatibility
  - Offline-first architecture
- **Key Features**: Task creation, status management, categorization, filtering, local storage

### local-chat  
- **Description**: Local network realtime messaging application
- **Framework Validation Focus**:
  - Network service discovery (Bonjour/mDNS)
  - Real-time communication patterns
  - Concurrent connection management
  - Security and encryption
  - Background processing
- **Key Features**: Peer discovery, instant messaging, group chats, media sharing

Each application type exercises different aspects of the framework, ensuring comprehensive validation across various use cases and technical requirements.

## Artifact Generation Process (3 Phases)

Used within each protocol for generating artifacts:

### Phase 1: Deep Analysis
- Thoroughly analyze context and requirements
- Identify all stakeholders and use cases
- Map dependencies and relationships
- Document assumptions and constraints

### Phase 2: Structured Generation
- Generate each section with deliberate focus
- Ensure internal consistency
- Apply domain-specific knowledge
- Validate against protocol requirements

### Phase 3: Final Revision
- Review for completeness and accuracy
- Fix inconsistencies and formatting
- Enhance clarity and readability
- Validate all cross-references

## Artifact Format Templates

Each protocol generates specific artifact formats. The templates follow a three-phase generation process:

### Phase 1: Deep Analysis
- Analyze context and previous artifacts
- Identify patterns and opportunities
- Map dependencies and requirements
- Define success criteria

### Phase 2: Structured Generation
- Generate comprehensive content following templates
- Apply domain-specific knowledge
- Ensure internal consistency
- Create all required sections

### Phase 3: Final Revision
- Review for completeness
- Fix inconsistencies
- Enhance clarity
- Validate cross-references

### Key Template Sections

#### Requirements Artifacts
- Metadata Section (identifier, status, version, dependencies)
- Abstract Section (purpose, scope, impact, success criteria)
- Motivation Section (problem statement, solution approach, benefits)
- Requirement Specifications (numbered requirements with acceptance criteria)
- TDD Development Checklist (RED-GREEN-REFACTOR cycles)
- Test Strategy Section (architecture, data management, CI/CD)
- Transition Section (migration, compatibility, rollout)
- Alternatives Section (evaluated approaches, decision matrix)
- Open Items Section (pending decisions, research items)
- References Section (internal/external docs, tools)

#### Analysis Artifacts
- Metadata Section (cycle info, metrics summary)
- Executive Summary (overview, achievements, findings, actions)
- Test Metrics Sections (coverage, quality, TDD compliance)
- Implementation Metrics (code quality, architecture, performance)
- Findings Sections (practice analysis, gaps, quality issues)
- Session Aggregation (patterns, friction points, learning curve)
- Recommendations (immediate actions, improvements, investments)
- Appendices (detailed metrics, logs, code quality reports)

#### Documentation Artifacts
- Metadata Section (version, platforms, languages)
- Overview Section (summary, architecture, principles, capabilities)
- Architecture Sections (principles, layers, patterns, components)
- API Reference Sections (public APIs with examples)
- Implementation Sections (guidelines, performance, testing)
- Appendices (migration guide, performance tuning, troubleshooting, examples)

#### Session Metrics Artifacts
- Session Overview (ID, timing, focus area)
- TDD Metrics (cycle tracking, coverage progress, test quality)
- Implementation Progress (requirements completion, code evolution)
- Technical Decisions (architecture, testing, tools)
- Testing Challenges (complex scenarios, stability, integration)
- Quality Evolution (improvements, coverage trends, maintenance)
- Session Summary (quantitative metrics, productivity, quality)
- Next Steps (immediate actions, technical debt, learning)
- Session Reflection (insights and improvements)

The complete template specifications are maintained within each protocol to ensure artifacts are generated with full context and proper three-phase processing.