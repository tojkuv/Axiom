# @DEVELOP.md - Axiom Framework Development Command

Framework development command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@DEVELOP [optional-args]`
**Action**: Enter ultrathink mode and execute framework development workflow

### Usage Modes
- **`@DEVELOP`** → Auto-detect current context and execute development workflow
- **`@DEVELOP plan`** → Plan development tasks and priorities
- **`@DEVELOP build`** → Execute development build and testing cycle
- **`@DEVELOP test`** → Run testing suite
- **`@DEVELOP optimize`** → Performance optimization and analysis

### Development Command Scope
**Framework Focus**: Core framework development, architecture enhancement, capability implementation
**Quality Standards**: High test coverage with comprehensive success rates
**Integration**: Integration with @PLAN, @CHECKPOINT, and @REFACTOR workflows

### 🔄 **Standardized Git Workflow**
All FrameworkDevelopment commands follow this workflow:
1. **Branch Setup**: Switch to `framework` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `framework` branch
3. **Development**: Execute command-specific development work
4. **Commit**: Commit changes to `framework` branch with descriptive messages
5. **Integration**: Merge `framework` branch into `main` branch
6. **Deployment**: Push `main` branch to remote repository
7. **Cycle Reset**: Delete old `framework` branch and create fresh one for next cycle

## Framework Development Philosophy

**Core Principle**: Framework development focuses on building iOS development capabilities that integrate architectural analysis with intelligent system features.

**Quality Standards**: Framework components maintain architectural integrity, meet performance targets, provide good developer experience, and integrate with framework capabilities.

**Testing Requirements**: Framework development targets high test coverage with comprehensive test success rates. See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for testing requirements and standards.

**Development Focus**: Framework development implements capabilities that enhance iOS development through AI integration, predictive analysis, and intelligent automation features.

## Framework Development Principles

### Architectural Integrity
- **Architectural Constraints**: Maintain adherence to foundational architectural patterns
- **Design Consistency**: Ensure consistent patterns and approaches across framework components
- **API Design**: Design intuitive and type-safe interfaces for framework consumers
- **Performance Focus**: Achieve performance targets while maintaining feature functionality
- **Thread Safety**: Implement actor-based isolation and concurrency patterns

### Intelligence Capability Development
- **AI Integration**: Build artificial intelligence capabilities into framework core
- **Predictive Analysis**: Develop features that identify and prevent issues
- **Optimization Systems**: Create analysis-driven optimization and improvement systems
- **Natural Language Processing**: Enable architectural queries and analysis through text interface
- **Pattern Detection**: Implement pattern recognition and standardization capabilities

### Developer Experience
- **API Design**: Design framework interfaces that are intuitive and functional
- **Code Generation**: Minimize repetitive code through automation
- **Type Safety**: Provide compile-time guarantees and runtime safety
- **Error Handling**: Implement graceful degradation and error management
- **Documentation**: Ensure framework capabilities are documented and accessible

### Testing Standards
**Requirements**: High test coverage, comprehensive test success rates, multiple test categories
**Standards**: See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for detailed testing methodology and requirements

## Framework Development Methodology

### Phase 1: Architecture and Design
1. **Requirement Analysis** → Understand framework enhancement needs and architectural goals
2. **Design Planning** → Design new capabilities that align with architectural constraints
3. **API Design** → Create intuitive interfaces for framework consumers
4. **Performance Planning** → Establish performance targets and optimization strategies
5. **Integration Planning** → Ensure new capabilities integrate with existing framework

### Phase 2: Implementation and Development
1. **Core Implementation** → Build framework capabilities using established patterns and principles
2. **Actor Integration** → Implement thread-safe patterns using actor-based isolation
3. **Protocol Design** → Create protocol hierarchies that support framework goals
4. **Capability Development** → Build runtime capability validation and management systems
5. **Intelligence Integration** → Integrate AI and ML capabilities into framework operations

### Phase 3: Testing and Validation
**Testing Requirements**: Comprehensive testing with high test success rates
**Testing Strategy**: Multi-layered validation including unit, integration, performance, AI/ML, security, and concurrency testing
**Standards**: Detailed testing requirements in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
**Development Rule**: Test failures require resolution before development progress

### **Phase 4: Documentation and Polish**
1. **API Documentation** → Document all public interfaces with comprehensive examples
2. **Architecture Documentation** → Update technical specifications with new capabilities
3. **Performance Documentation** → Document performance characteristics and optimization strategies
4. **Integration Guides** → Create guidance for framework consumers using new capabilities
5. **Quality Review** → Final review to ensure framework meets excellence standards

## 📊 Framework Development Categories

### **Core Framework Components**
- **AxiomClient** → Actor-based state management with single ownership patterns
- **AxiomContext** → Client orchestration and SwiftUI integration layer
- **AxiomView** → 1:1 view-context relationships with reactive binding
- **Capability System** → Runtime validation with compile-time optimization
- **Domain Models** → Immutable value objects with business logic integration
- **Intelligence System** → AI-powered architectural analysis and optimization

### Intelligence Capability Areas
- **Component Introspection** → Component analysis and documentation generation systems
- **Predictive Analysis** → Issue identification and architectural analysis
- **Natural Language Queries** → Text-based architectural exploration interface
- **Performance Optimization** → Analysis-driven optimization recommendations
- **Pattern Detection** → Pattern recognition and standardization capabilities
- **Architecture Evolution** → Requirements-based architecture adaptation

### **Performance and Quality Systems**
- **Memory Management** → Efficient memory usage patterns and optimization
- **Concurrency Patterns** → Actor-based isolation and async/await integration
- **Error Handling** → Comprehensive error management and recovery
- **Type Safety** → Compile-time and runtime type validation
- **API Consistency** → Uniform interface design across framework components

## Testing Integration

**Testing Framework**: Multi-layered testing strategy covering framework components
**Testing Categories**: Unit, integration, performance, AI/ML, security, concurrency, and regression testing
**Testing Standards**: Testing specifications available in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
**Integration**: Testing requirements integrated into development workflow

## Test Requirements

**Testing Standards**: High test success rates required for development progress
**Development Process**: Test failures require resolution before continuing development
**Resolution Process**: Stop → identify cause → fix failure → verify tests pass → continue
**Standards**: Testing requirements in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`

## Development Success Criteria

**Architectural Compliance**: Adherence to 8 architectural constraints, consistent design patterns, functional API design, performance targets achieved
**Intelligence Capabilities**: AI features providing analysis value, predictive issue identification, optimization recommendations
**Developer Experience**: Intuitive APIs, boilerplate reduction through code generation, type safety, clear error handling
**Testing Standards**: High test coverage, comprehensive test success rates, testing across all categories
**Standards**: Success criteria in `AxiomFramework/Documentation/DEVELOPMENT_STANDARDS.md`

## 🤖 Development Execution Loop

**Command**: `@DEVELOP [plan|build|test|optimize]`
**Action**: Execute comprehensive development workflow with methodology enforcement

**Automated Execution Process**:
1. **Environment Validation** → Verify framework branch, clean working tree, framework dependencies
2. **Planning Integration** → Reference current TRACKING development priorities and @PLAN outputs
3. **Methodology Enforcement** → Apply development principles and architectural constraints
4. **Build and Test Cycle** → Execute swift build, swift test with coverage requirements
5. **Quality Validation** → Ensure high test success rates, performance targets, architectural compliance
6. **Documentation Updates** → Update technical documentation and API references
7. **TRACKING.md Progress Update** → Update implementation progress in FrameworkDevelopment/TRACKING.md
8. **Coordination Updates** → Provide progress updates and next steps

**Development Execution Examples**:
- `@DEVELOP plan` → Plan development priorities and task breakdown
- `@DEVELOP build` → Execute full build, test, and validation cycle
- `@DEVELOP test` → Run comprehensive testing with coverage analysis
- `@DEVELOP optimize` → Performance analysis and optimization cycle

## 🔄 Development Workflow Integration

**Planning**: Integrates with @PLAN for development task planning and priority coordination
**Execution**: Complete implementation → testing → optimization → documentation cycle
**Critical Rule**: Any test failure immediately blocks all development work until resolved
**Documentation**: Work details tracked in `/AxiomFramework/Documentation/` only
**Coordination**: Seamless integration with @CHECKPOINT for development cycle completion

## 📚 Development Resources

**Framework Architecture**: 8 architectural constraints, 8 intelligence systems, performance targets, API design principles
**Development Infrastructure**: Testing framework, performance monitoring, documentation systems, quality tools
**Resources**: Complete development resources in `AxiomFramework/Documentation/Development/`

## 🤖 Development Coordination

**Branch Focus**: Dedicated framework core development and enhancement in development branch
**Work Storage**: Development work tracked in `/AxiomFramework/Documentation/` only
**Planning Integration**: @PLAN command provides contextual development planning
**Coordination**: Independent development operation with cross-branch progress sharing

---

---

**DEVELOPMENT COMMAND STATUS**: Development command with methodology, requirements, and execution procedures
**CORE FOCUS**: Framework development with automated workflow implementation  
**AUTOMATION**: Supports `@DEVELOP [plan|build|test|optimize]` with execution procedures  
**TESTING REQUIREMENTS**: High test coverage and comprehensive test success rates required  
**INTEGRATION**: Workflow integration with @PLAN, @CHECKPOINT, and development coordination

**Use @DEVELOP for framework development with automated methodology implementation and execution.**