# FRAMEWORK-CONTEXT-ARTIFACT

**Framework**: AxiomFramework
**Type**: Swift architectural framework for Apple platforms
**Purpose**: Opinionated 6-component architecture with unidirectional data flow and comprehensive testing

## Technical Context

**Stack**: Swift 5.9+, SwiftUI, Swift Concurrency, iOS 17+, macOS 14+
**Architecture**: Capability→State→Client→Context→Orchestrator→Presentation hierarchy
**Constraints**: Actor-based concurrency, unidirectional flow, no external dependencies beyond SwiftSyntax
**Performance**: <5ms state updates, 60fps UI, memory stability, zero architectural violations

## Competitive Context

**Primary Competitors**: TCA (The Composable Architecture), VIPER
**Differentiation**: Stricter architectural guarantees, comprehensive testing framework, performance guarantees, compile-time validation

## Core Principles

- Opinionated constraints over flexibility
- Compile-time safety over runtime flexibility
- Actor isolation for thread safety
- Value semantics for state management
- Protocol-oriented design with macro support

## Analysis Focus Areas

**Critical**: Core component protocols, unidirectional flow validation, state management performance
**Important**: Testing framework completeness, memory leak prevention, actor safety guarantees
**Enhancement**: Developer experience, API ergonomics

## MVP Focus - Explicitly Excluded

Framework analysis deliberately excludes:
- Version control integration
- Database schema concerns
- Migration pathway planning
- Deprecation management
- Legacy code preservation
- Backward compatibility
- Breaking change mitigation
- Semantic versioning
- API stability preservation across versions
- Configuration migration
- Deployment versioning
- Release management
- Rollback procedures
- Multi-version API support

## Analysis Guidance

**Maintain**: 6-component hierarchy, unidirectional flow, actor boundaries, performance guarantees
**Improve**: Code clarity, test coverage, API consistency, developer experience
**Evaluate**: Performance over convenience, safety over flexibility, compile-time over runtime validation
