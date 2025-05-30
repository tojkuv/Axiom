# Axiom Framework: Implementation Quick Reference

## 🎯 Essential Implementation Documents

### 📋 Development Workflow
1. **[IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md)** - Task list & timeline
   - 150+ specific implementation tasks
   - Month-by-month development schedule
   - Dependency mapping between tasks

2. **[DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)** - Code standards
   - Type safety requirements
   - Performance optimization patterns
   - Documentation standards

3. **[TESTING_STRATEGY.md](TESTING_STRATEGY.md)** - Testing approach
   - 5-level testing pyramid
   - Test examples for each component type
   - Performance validation tests

### 🔧 Technical Specifications
4. **[Technical/API_DESIGN_SPECIFICATION.md](Technical/API_DESIGN_SPECIFICATION.md)** - All protocols & APIs
   - Core protocols: AxiomClient, AxiomContext, AxiomView
   - Intelligence system APIs
   - Error handling interfaces

5. **[Technical/INTELLIGENCE_SYSTEM_SPECIFICATION.md](Technical/INTELLIGENCE_SYSTEM_SPECIFICATION.md)** - AI features
   - 8 intelligence system implementations
   - AxiomIntelligence protocol details
   - Pattern detection & prediction engines

6. **[Technical/CAPABILITY_SYSTEM_SPECIFICATION.md](Technical/CAPABILITY_SYSTEM_SPECIFICATION.md)** - Capabilities
   - Hybrid validation implementation
   - Capability enumeration & domains
   - Performance optimization strategies

7. **[Technical/DOMAIN_MODEL_DESIGN_PATTERNS.md](Technical/DOMAIN_MODEL_DESIGN_PATTERNS.md)** - Domain architecture
   - Domain model patterns & examples
   - Client classification (Domain vs Infrastructure)
   - Cross-domain coordination patterns

8. **[Technical/MACRO_SYSTEM_SPECIFICATION.md](Technical/MACRO_SYSTEM_SPECIFICATION.md)** - Macro implementations
   - @Client, @Capabilities, @DomainModel macros
   - Code generation patterns
   - Diagnostic message implementations

## 🚀 Quick Implementation Guide

### Starting a New Component
1. Check **API_DESIGN_SPECIFICATION** for protocol definition
2. Follow patterns in **DOMAIN_MODEL_DESIGN_PATTERNS**
3. Apply standards from **DEVELOPMENT_GUIDELINES**
4. Write tests according to **TESTING_STRATEGY**
5. Reference macro patterns in **MACRO_SYSTEM_SPECIFICATION**

### Daily Development Flow
1. **Morning**: Check IMPLEMENTATION_ROADMAP for current tasks
2. **Coding**: Reference technical specs for accurate implementation
3. **Testing**: Follow TESTING_STRATEGY for comprehensive coverage
4. **Standards**: Apply DEVELOPMENT_GUIDELINES throughout

### Common References
- **Protocol signatures**: API_DESIGN_SPECIFICATION
- **Intelligence integration**: INTELLIGENCE_SYSTEM_SPECIFICATION  
- **Domain patterns**: DOMAIN_MODEL_DESIGN_PATTERNS
- **Macro usage**: MACRO_SYSTEM_SPECIFICATION
- **Performance targets**: DEVELOPMENT_GUIDELINES

---

**All archived documents** are in `Archive/` directory for historical reference but not needed for active development.