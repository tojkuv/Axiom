# Codebaase Context

## MVP Focus - Explicitly Excluded
This protocol focuses on current state integration and deliberately excludes:
- Version control integration concerns (this includes git)
- Database schema integration
- Migration pathway integration
- Deprecation management during integration
- Legacy code preservation during integration
- Backward compatibility preservation
- Breaking change mitigation
- Semantic versioning enforcement
- API stability preservation across versions
- Configuration migration support
- Deployment versioning concerns
- Release management integration
- Rollback procedure preservation
- Multi-version API support
- Codebase Documentation

## Legacy Implementation Policy
**REQUIREMENT**: Legacy implementations must be replaced, not preserved. This protocol mandates:
- Replace outdated patterns with modern equivalents
- Modernize APIs and interfaces without backward compatibility
- Remove deprecated code and obsolete implementations
- Focus on optimal current solutions rather than legacy support
- Prioritize clean, modern architecture over preservation of old code

## api facing components
These compoents should not exists as concrete implementations in the framework codebase. applications use the framework's public facing APIs to create these componets for their needs:
- Presentaiton views
- Contexts
- Clients
- Orchestrator

## codebase conformances
- ensure we always use modern swift syntax, swift 6.2 or latest

## protocol-specific considerations

### stabilization analysis

### exploration analysis
- implement alart kit as a domain capability

### meta-analysis
- macro system expansions are not violations of the architectural foundation . we ecourage the expansion of the macro system
