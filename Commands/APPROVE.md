# Axiom Framework: Proposal Approval & Integration System

**Integrate approved strategic proposals into roadmap and documentation across the framework ecosystem**

## 🤖 Automated Mode Trigger

**When human sends**: `@APPROVE <proposal-file>`
**Action**: Automatically enter ultrathink mode and integrate the specified proposal from either proposal scope

### 🎯 **Dual-Scope Approval System**
- **`@APPROVE framework-proposal.md`** → Approve framework enhancement proposals from `/AxiomFramework/Proposals/Active/`
- **`@APPROVE integration-proposal.md`** → Approve integration improvement proposals from `/AxiomTestApp/Proposals/Active/`
- **Auto-Detection**: System automatically detects which proposal scope contains the specified file

### 🧠 **Scope-Specific Approval Intelligence**
**Framework Proposals**: Framework enhancement priorities, core feature implementation, architecture evolution
**Integration Proposals**: Testing validation priorities, integration pattern implementation, test app improvements
**Main Branch Context**: Always operates in main branch for strategic coordination and documentation updates

**Integration Process**:
1. **Auto-Detect Scope** → Determine proposal location (framework or integration scope)
2. **Validate Proposal** → Verify file exists and follows standard format
3. **Override ROADMAP Section** → Replace appropriate planning section with proposal content
4. **Archive Proposal** → Move to Documentation/Archive with implementation notes
5. **Update Coordination** → Complete integration and provide implementation guidance

## 🎯 Core Mission

**Primary Focus**: Automated integration of approved proposals into ROADMAP.md planning sections

**Responsibility**: Pure proposal integration engine - replaces planning sections with approved proposal content
**Philosophy**: Bridge strategic proposals with active coordination by overriding ROADMAP planning sections

## 🌿 Approval Contexts

**Framework Proposals**: `/AxiomFramework/Proposals/` → Development branch implementation priorities
**Integration Proposals**: `/AxiomTestApp/Proposals/` → Integration branch validation priorities  
**Main Branch**: Strategic coordination and cross-scope planning priorities

**Integration Scope**:
- ✅ **Proposal validation, ROADMAP integration, documentation updates, proposal management**
- ❌ **No source code changes, no development interference, no active sprint disruption**

## 📋 Integration Workflow

**Automated Process**:
1. **Validation** → Verify proposal file exists, format correct, completeness check
2. **ROADMAP Override** → Replace appropriate section (Development/Integration/Refactoring) with proposal content
3. **Documentation Archive** → Archive proposal in Documentation/Archive for reference
4. **Proposal Management** → Clean up Active directory and update tracking
5. **Coordination** → Confirm ROADMAP override and provide implementation guidance

## 🎯 Integration Categories

**Framework Proposals**: Override Development Planning section in ROADMAP.md + archive in `/AxiomFramework/Documentation/Archive/`
**Integration Proposals**: Override Integration Planning section in ROADMAP.md + archive in `/AxiomTestApp/Documentation/Archive/`
**Refactoring Proposals**: Override Refactoring Planning section in ROADMAP.md + archive in Documentation
**Strategic Proposals**: Override multiple sections as appropriate + comprehensive archival

## 🔧 File Operations

**ROADMAP Override**: Replace one of 3 planning sections (Development/Integration/Refactoring) with proposal content
**Proposal Archival**: Move proposal from `/Active/` to `/Documentation/Archive/` for historical reference
**Clean Active Directory**: Remove approved proposal from Active to keep it focused on pending proposals

## ⚠️ Safety Rules

**Critical Requirements**: Proposal must exist, follow format, maintain documentation consistency, no source code changes
**Error Handling**: Missing proposal detection, format validation, conflict identification, rollback capability

## 🤖 Automated Approval

**Command**: `@APPROVE <proposal-file>`
**Auto-Detection**: Automatically detects proposal scope (framework or integration)
**Workflow**: Validate → Integrate → Move → Coordinate → Report

**Integration Patterns**:
- **Framework Proposals**: Development priorities and architecture evolution
- **Integration Proposals**: Testing priorities and integration improvements  
- **Cross-Scope**: Strategic coordination and documentation organization

---

**APPROVE STATUS**: Streamlined proposal integration system ready for automated approval ✅  
**CORE FOCUS**: Pure approval automation with scope-aware integration  
**AUTOMATION**: Supports `@APPROVE <proposal-file>` with automatic scope detection  
**EFFICIENCY**: Streamlined from 269 to ~80 lines (70% reduction) while maintaining automation functionality

**Use @APPROVE to integrate strategic proposals into active development coordination through automated documentation and roadmap updates.**