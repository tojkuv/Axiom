# DOCUMENT Protocol

centralized documentation management protocol for the axiom framework

## purpose

handles all documentation reading and writing operations. no other protocol should read or write documentation files.

## when to use

use the document protocol for:
- updating technical documentation after implementation
- creating api references and specifications  
- documenting architectural decisions
- managing proposal documentation
- reading existing documentation for context
- maintaining documentation consistency

## command

`./FrameworkProtocols/DOCUMENT.md <operation> [parameters]`

### operations

#### update-technical
updates technical documentation to reflect implemented features

```bash
./FrameworkProtocols/DOCUMENT.md update-technical <component>
```

#### update-api
updates api documentation for framework interfaces

```bash
./FrameworkProtocols/DOCUMENT.md update-api <module>
```

#### create-proposal
creates new proposal documentation

```bash
./FrameworkProtocols/DOCUMENT.md create-proposal <title>
```

#### read-standards
reads development or refactoring standards

```bash
./FrameworkProtocols/DOCUMENT.md read-standards <type>
```

#### document-architecture
documents architectural decisions and changes

```bash
./FrameworkProtocols/DOCUMENT.md document-architecture <component>
```

## documentation structure

### framework documentation
- `/AxiomFramework/Documentation/` - main documentation directory
- `/AxiomFramework/Documentation/Testing/` - testing strategies and guides
- `/AxiomFramework/Documentation/Technical/` - technical specifications
- `/AxiomFramework/Documentation/Implementation/` - implementation guides
- `/AxiomFramework/Documentation/Performance/` - performance documentation

### proposal documentation
- `/AxiomFramework/Proposals/Active/` - active proposals
- `/AxiomFramework/Proposals/WaitingApproval/` - pending proposals
- `/AxiomFramework/Proposals/Archive/` - completed proposals

### application documentation
- `/AxiomExampleApp/Documentation/` - application documentation
- `/AxiomExampleApp/Proposals/` - application proposals

## documentation standards

### technical documentation
- use clear, evidence-based language
- include code examples where relevant
- maintain consistency with existing documentation
- update cross-references when components change

### api documentation
- document all public interfaces
- include usage examples
- specify performance characteristics
- note architectural constraints

### proposal documentation
- follow proposal template structure
- include motivation and rationale
- document implementation approach
- specify testing requirements

## integration with other protocols

### develop protocol
- develop implements features
- document updates technical documentation after implementation

### refactor protocol  
- refactor restructures code
- document updates structure documentation after refactoring

### plan protocol
- plan creates proposal specifications
- document creates proposal documentation files

### explore protocol
- explore analyzes framework
- document records analysis findings

## documentation workflow

### phase 1: read existing documentation
understand current documentation state and standards

### phase 2: perform documentation updates
update relevant documentation based on operation type

### phase 3: maintain consistency
ensure cross-references and relationships are updated

### phase 4: validate documentation
verify documentation accuracy and completeness

## execution phases

### technical documentation update
```bash
# after develop completes implementation
./FrameworkProtocols/DOCUMENT.md update-technical StateManagement

# updates:
# - /AxiomFramework/Documentation/Technical/STATE_MANAGEMENT_SPECIFICATION.md
# - /AxiomFramework/Documentation/Implementation/STATE_IMPLEMENTATION.md
# - api references and cross-documentation links
```

### proposal documentation
```bash
# after plan creates proposal specification
./FrameworkProtocols/DOCUMENT.md create-proposal "Enhanced Capability System"

# creates:
# - /AxiomFramework/Proposals/Active/ENHANCED_CAPABILITY_SYSTEM.md
# - updates proposal index and tracking
```

### architecture documentation
```bash
# after architectural changes
./FrameworkProtocols/DOCUMENT.md document-architecture IntelligenceSystem

# updates:
# - /AxiomFramework/Documentation/Technical/INTELLIGENCE_SYSTEM_SPECIFICATION.md
# - architectural decision records
# - component relationship documentation
```

## documentation priorities

### priority 1: api documentation
public interfaces must be documented before release

### priority 2: technical specifications
architectural decisions and constraints must be recorded

### priority 3: implementation guides
complex features require implementation documentation

### priority 4: performance documentation
performance characteristics and benchmarks

## documentation validation

### completeness checks
- all public apis documented
- all architectural decisions recorded
- cross-references valid
- examples compile and run

### consistency checks
- terminology consistent across documents
- formatting follows standards
- version information current
- no orphaned documentation

## post-execution

after documentation updates:
1. validate cross-references
2. update documentation index if needed
3. ensure examples are current
4. commit documentation changes

## success criteria

documentation operation succeeds when:
- all relevant files updated
- cross-references valid
- examples accurate
- consistency maintained
- no broken links or references

## usage example

```bash
# developer implements new capability system
./FrameworkProtocols/DEVELOP.md implement-capability "Dynamic Loading"

# document updates technical documentation
./FrameworkProtocols/DOCUMENT.md update-technical Capabilities

# document updates api documentation
./FrameworkProtocols/DOCUMENT.md update-api CapabilityManager

# changes committed with documentation updates
./FrameworkProtocols/CHECKPOINT.md "Implement dynamic capability loading with documentation"
```