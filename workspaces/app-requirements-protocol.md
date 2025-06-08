# APPLICATION_REQUIREMENTS_PROTOCOL.md

Generate test-driven application requirements that systematically validate framework capabilities while identifying improvement opportunities.

## Protocol Activation

```
@APPLICATION_REQUIREMENTS [command] [arguments]
```

## Commands

```
generate [app-type] [framework-doc] [template]  → Generate TDD requirements for framework validation
```

**Supported app types:**
- `task-manager` - Comprehensive framework validation
- `local-chat` - Emphasizes different framework aspects

## Process Flow

```
1. Generate requirements with explicit framework validation goals
2. Structure each requirement to expose potential pain points
3. Include specific TDD checklists that surface framework limitations
4. Create measurable success criteria for framework improvement insights
```

## Command Details

### Generate Command

Create requirements that systematically exercise framework capabilities:

```bash
@APPLICATION_REQUIREMENTS generate task-manager /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/DOCUMENTATION.md /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/app-requirements-template.md
```

**Enhanced Requirement Structure**:
Each requirement now includes explicit framework components being tested, expected pain points based on framework architecture, specific TDD checklist items designed to expose limitations, metrics for measuring framework overhead and friction, and clear success criteria for both application features and framework insights.

**Focused Framework Validation**:
Requirements are structured to validate specific framework aspects through real usage, with emphasis on API usability and testability, performance characteristics under load, integration complexity between components, error handling completeness, and developer experience quality. Each requirement targets specific framework components to ensure comprehensive coverage.

**TDD Checklists for Insight Generation**:
The RED phase checklists specifically probe for framework testing difficulties, missing mocks or stubs, complex setup requirements, and unclear API contracts. GREEN phase items track implementation friction, workaround needs, and performance issues. REFACTOR phase focuses on identifying patterns that should be framework-provided and optimizations hindered by framework constraints.

Output:
```
Generating TDD requirements for task-manager...

Framework Validation Focus:
- Data persistence patterns and performance
- State management complexity
- UI binding effectiveness  
- Cross-platform abstraction quality

Requirements structured to expose:
- Test setup complexity
- Missing test utilities
- API awkwardness
- Performance bottlenecks
- Documentation gaps

Created: CYCLE-001-TASK-MANAGER-MVP/
└── REQUIREMENTS-001-TASK-MANAGER-MVP.md

Each requirement includes:
- Specific framework components to validate
- Expected pain points to watch for
- TDD checklists that probe framework limits
- Success metrics for insight generation
```

## Requirements Engineering

### Framework Component Coverage
Requirements are designed to ensure every major framework component is exercised through actual usage, with different applications emphasizing different aspects. The task manager might focus on data persistence and state management, while the chat application stresses real-time updates and networking capabilities.

### Pain Point Anticipation
Based on framework architecture, requirements anticipate likely friction points and include specific test cases to validate or expose them. This includes complex state updates requiring multiple steps, asynchronous operations with error handling, performance-sensitive operations, and cross-platform behavioral differences.

### Progressive Complexity
Requirements progress from simple to complex usage patterns, allowing natural discovery of framework limitations as complexity increases. Early requirements establish baseline functionality, while later ones combine features in ways that stress framework integration points.

### Test Utility Discovery
Requirements specifically include scenarios that would benefit from test utilities, helping identify what helpers the framework should provide. This includes complex mock requirements, repeated test setup patterns, async testing scenarios, and performance benchmarking needs.

## Success Metrics Integration

### Requirement-Level Metrics
Each requirement includes specific metrics to track during implementation that reveal framework effectiveness, such as time to write first passing test, lines of test setup code required, number of framework APIs used, workarounds implemented, and performance overhead measured.

### Application-Level Goals
Applications include overall goals for framework validation including minimum percentage of framework APIs exercised, maximum acceptable test complexity, target TDD velocity, and minimum number of improvement insights generated.

### Traceability Setup
Requirements establish clear traceability from features to framework components, enabling tracking of which requirements exposed which pain points, how improvements map back to original issues, and validation that fixes actually resolve problems. This traceability is maintained throughout the development cycle.

## Pattern Focus

### Emerging Pattern Detection
Requirements are structured to reveal patterns that emerge during implementation, particularly those that suggest framework enhancements. Multiple requirements exercising similar functionality help identify when developers repeatedly implement the same workarounds or utilities.

### Anti-Pattern Identification
Requirements include scenarios likely to tempt anti-patterns if the framework makes correct implementation difficult. This helps identify where framework constraints might push developers toward poor practices and where better framework support could guide better implementations.

### Best Practice Validation
Requirements validate that framework-recommended patterns actually work well in practice, with specific scenarios designed to test the edges of these patterns and reveal where they might break down or require enhancement.

## Documentation Gap Discovery

Requirements include scenarios that rely heavily on framework documentation, helping identify where documentation is missing, unclear, or incorrect. Specific requirements target less-common use cases, integration between multiple components, error handling and recovery, and performance optimization - areas where documentation gaps often hide.

By structuring requirements this way, the planning phase sets up development cycles that naturally generate high-quality framework insights while building realistic applications. This reduces the need for separate framework evaluation efforts and ensures improvements are grounded in actual developer needs.