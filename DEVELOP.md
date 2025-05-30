# Axiom Framework Development Guide

You are Claude Code developing the Axiom framework core - the world's first intelligent, predictive architectural framework for iOS.

## 🎯 DEVELOP Mode Mission

**Focus**: Build robust framework internals, implement new protocols, add capabilities, and enhance core architecture.

**Philosophy**: Every line of framework code contributes to revolutionizing iOS development through perfect human-AI collaboration.

## 🏗️ Framework Architecture

### **Core Components**
- **AxiomClient**: Actor-based state management with single ownership
- **AxiomContext**: Orchestrates clients, provides SwiftUI integration
- **AxiomView**: 1:1 relationship with contexts
- **Intelligence System**: DNA, predictions, patterns, natural language
- **Capability System**: Hybrid compile-time + runtime validation
- **Domain Models**: 1:1 client ownership, immutable value objects

### **8 Architectural Constraints**
1. **View-Context Relationship** (1:1 bidirectional binding)
2. **Context-Client Orchestration** (read-only state + cross-cutting concerns)
3. **Client Isolation** (single ownership with actor safety)
4. **Hybrid Capability System** (compile-time hints + 1-3% runtime validation)
5. **Domain Model Architecture** (1:1 client ownership with value objects)
6. **Cross-Domain Coordination** (context orchestration only)
7. **Unidirectional Flow** (Views → Contexts → Clients → Capabilities → System)
8. **Revolutionary Intelligence System** (8 breakthrough AI capabilities)

### **8 Intelligence Systems**
1. **Architectural DNA** - Complete component introspection and self-documentation
2. **Intent-Driven Evolution** - Predictive architecture evolution based on business intent
3. **Natural Language Queries** - Explore architecture in plain English
4. **Self-Optimizing Performance** - Continuous learning and automatic optimization
5. **Constraint Propagation** - Automatic business rule compliance (GDPR, PCI, etc.)
6. **Emergent Pattern Detection** - Learning and codifying new patterns
7. **Temporal Development Workflows** - Sophisticated experiment management
8. **Predictive Architecture Intelligence** - Problem prevention before occurrence

## 🔄 Development Workflow

### **Core Development Process**
1. **Check STATUS.md** → Understand current state and priorities
2. **Reference Technical Specs** → Use `/Documentation/Technical/` for implementation details
3. **Implement Features** → Build new protocols, capabilities, intelligence systems
4. **Validate Architecture** → Ensure zero constraint violations
5. **Write Tests** → >95% coverage required for all new functionality
6. **Update Documentation** → 100% API documentation required

### **Critical Locations**
- **Framework Code**: `/AxiomFramework/Sources/Axiom/`
- **Technical Specs**: `/AxiomFramework/Documentation/Technical/`
- **Implementation Guide**: `/AxiomFramework/Documentation/Implementation/IMPLEMENTATION_ROADMAP.md`
- **API Reference**: `/AxiomFramework/Documentation/Technical/API_DESIGN_SPECIFICATION.md`

## 🛠️ Development Standards

### **Type Safety Requirements**
- All types must be Sendable
- Use actors for all concurrent state management
- Compile-time validation preferred over runtime checks
- Zero tolerance for data races or thread safety issues

### **Performance Requirements**
- **State Access**: 50x faster than TCA (Tier 1), 120x faster (Tier 3)
- **Memory Usage**: 30% reduction vs baseline
- **Capability Overhead**: <3% runtime cost
- **Intelligence Overhead**: <5% with full features

### **Code Quality Standards**
- **Test Coverage**: >95% for all core functionality
- **Documentation**: 100% API documentation with examples
- **Architecture**: Zero constraint violations allowed
- **Performance**: All targets measurable and validated

## 🚀 Implementation Phases

### **Current Focus Areas**
1. **Performance Validation**: Measure and optimize framework overhead
2. **Intelligence Enhancement**: Advanced pattern detection and predictive capabilities
3. **Capability Expansion**: New capability types and validation patterns
4. **API Maturation**: Polish core protocols based on real usage

### **Development Priorities**
1. **Stability First**: No breaking changes to working functionality
2. **Performance Targets**: Meet or exceed all benchmark requirements
3. **Type Safety**: Enhance compile-time validation wherever possible
4. **Intelligence Features**: Build advanced AI capabilities on proven foundation

## 🔧 Technical Implementation

### **Adding New Features**
1. **Design Protocol** → Define clean, minimal interface
2. **Implement Core** → Actor-based, thread-safe implementation
3. **Add Tests** → Comprehensive test coverage including edge cases
4. **Document API** → Complete documentation with usage examples
5. **Validate Performance** → Ensure meets framework performance targets

### **Capability System Extension**
```swift
// Define new capability
enum NewCapability: String, CaseIterable, Capability {
    case featureName = "feature_name"
    
    var description: String { "Description of capability" }
    var dependencies: [Capability] { [] }
}

// Implement validation
extension CapabilityValidator {
    func validateNewCapability() async -> ValidationResult {
        // Implementation
    }
}
```

### **Intelligence System Extension**
```swift
// Extend AxiomIntelligence
extension AxiomIntelligence {
    func newIntelligenceFeature(_ input: String) async throws -> IntelligenceResponse {
        // Implementation following intelligence patterns
    }
}
```

## 📚 Key References

### **Technical Documentation**
- **API Design**: `/Documentation/Technical/API_DESIGN_SPECIFICATION.md`
- **Intelligence Systems**: `/Documentation/Technical/INTELLIGENCE_SYSTEM_SPECIFICATION.md`
- **Capability System**: `/Documentation/Technical/CAPABILITY_SYSTEM_SPECIFICATION.md`
- **Domain Models**: `/Documentation/Technical/DOMAIN_MODEL_DESIGN_PATTERNS.md`
- **Macro System**: `/Documentation/Technical/MACRO_SYSTEM_SPECIFICATION.md`

### **Implementation Guides**
- **Roadmap**: `/AxiomFramework/Documentation/Implementation/IMPLEMENTATION_ROADMAP.md` (150+ tasks)
- **Guidelines**: `/AxiomFramework/Documentation/Implementation/DEVELOPMENT_GUIDELINES.md`
- **Testing**: `/AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`

## ✅ Definition of Done

### **Feature Complete When**
1. **Protocol Implemented** → Clean, minimal interface
2. **Actor Safety** → Thread-safe with proper isolation
3. **Tests Written** → >95% coverage with edge cases
4. **Documentation** → 100% API docs with examples
5. **Performance Validated** → Meets framework targets
6. **Integration Ready** → Works with existing architecture

### **Architecture Validation**
- Zero constraint violations
- Proper separation of concerns
- Unidirectional data flow maintained
- Intelligence system integration points defined
- Capability system validation implemented

## 🎯 Revolutionary Goals

**Build the world's first intelligent, predictive architectural framework that:**
- Prevents problems before they occur
- Evolves based on usage patterns
- Explains itself in plain English
- Optimizes performance automatically
- Enables perfect human-AI collaboration

**Next Actions**: Check STATUS.md priorities → Implement next framework feature → Validate and test → Update progress