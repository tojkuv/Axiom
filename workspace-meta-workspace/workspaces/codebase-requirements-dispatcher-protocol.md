# CODEBASE-REQUIREMENTS-DISPATCHER-PROTOCOL

Comprehensive adaptive distribution protocol to transform technical analysis findings and codebase insights into organized requirement sets for sequential and parallel development. Analyzes codebase content and existing analysis artifacts to distribute requirements across specialized worker folders based on technical complexity and separable areas.

## Protocol Activation

```text
@CODEBASE_REQUIREMENTS_DISPATCHER execute <source_directory> <analyses_directory> <provisioner_directory> <workers_directory> <dispatcher_template>
```

**Parameters:**
- `<source_directory>`: SOURCE/ directory containing codebase to analyze (READ-ONLY)
- `<analyses_directory>`: Directory containing analysis artifacts to integrate (READ-ONLY)
- `<provisioner_directory>`: PROVISIONER/ directory where provisioner requirements will be generated
- `<workers_directory>`: WORKERS/ directory where worker structure and requirements will be generated
- `<dispatcher_template>`: Requirements template for each generated artifact

**Explicit Input/Output Structure:**
- **INPUT**: `<source_directory>/` - Source codebase to analyze (READ-ONLY)
- **INPUT**: `<analyses_directory>/` - Analysis artifacts to integrate (READ-ONLY)
- **OUTPUT**: `<provisioner_directory>/ARTIFACTS/` - Generated provisioner requirements and development cycle
- **OUTPUT**: `<workers_directory>/WORKER-XX/ARTIFACTS/` - Generated worker requirements and development cycles

**Generated Requirements Structure:**
```
<provisioner_directory>/
└── ARTIFACTS/                        # Generated provisioner requirements
    ├── DEVELOPMENT-CYCLE-INDEX.md
    └── REQUIREMENTS-P-*.md

<workers_directory>/
├── WORKER-01/
│   └── ARTIFACTS/                    # Generated worker-01 requirements
│       ├── DEVELOPMENT-CYCLE-INDEX.md
│       └── REQUIREMENTS-W-01-*.md
├── WORKER-02/
│   └── ARTIFACTS/                    # Generated worker-02 requirements
│       ├── DEVELOPMENT-CYCLE-INDEX.md
│       └── REQUIREMENTS-W-02-*.md
└── WORKER-XX/                        # Additional workers as needed
    └── ARTIFACTS/                    # Generated worker-XX requirements
        ├── DEVELOPMENT-CYCLE-INDEX.md
        └── REQUIREMENTS-W-XX-*.md
```

**Adaptive Sequential and Parallel Distribution Model**: Runs once to extract ALL technical improvement opportunities from codebase analysis and existing artifacts, then distributes them across specialized worker folders based on technical impact and workload assessment.

**Directory Integration:**
- Reads analysis artifacts from: `<analyses_directory>/`
- Reads source code from: `<source_directory>/`
- Generates provisioner requirements in: `<provisioner_directory>/ARTIFACTS/`
- Generates worker structure and requirements in: `<workers_directory>/WORKER-XX/ARTIFACTS/`
- Creates provisioner and worker directory structures as needed

**Outputs Generated:**
- Workspace-isolated requirement artifacts (adapts to technical complexity):
  - `<provisioner_directory>/ARTIFACTS/` (foundational requirements - executes first)
  - `<workers_directory>/WORKER-01/ARTIFACTS/` through `<workers_directory>/WORKER-XX/ARTIFACTS/` (parallel technical area requirements)
  - Each worker artifacts folder contains: requirements addressing specific technical improvements from analysis
  - Each worker artifacts folder contains: independent development cycle coordination
- Execution order enforced: PROVISIONER → PARALLEL WORKERS → STABILIZER
- Note: Stabilizer requirements are handled dynamically during stabilization phase

**Workload-Adaptive Distribution**: Protocol determines optimal number of parallel workers (1-7) based on technical complexity and separable technical areas discovered through codebase analysis.

## Command

### Execute - Requirements Distribution

The execute command transforms technical analysis insights into actionable requirements:
- Analyzes codebase and integrates analysis findings
- Distributes requirements across provisioner and workers
- Creates optimal worker allocation based on technical complexity

**Core Distribution Process:**
1. **Deep Codebase Content Analysis**: Read ALL source files from `<source_directory>/`, APIs, dependencies, patterns
2. **Analysis Integration**: Incorporate findings from `<analyses_directory>/` artifacts
3. **Technical Area Discovery**: Identify separable technical responsibility areas from code structure and analysis insights
4. **Worker Optimization**: Calculate optimal worker count (2-8) based on technical complexity
5. **Workspace Structure Creation**: Create `<provisioner_directory>/ARTIFACTS/` and `<workers_directory>/WORKER-XX/ARTIFACTS/` directories
6. **Requirements Generation**: Create complete requirements for PROVISIONER and ALL workers
7. **Coverage Validation**: Ensure zero gaps between analysis findings and generated requirements

```bash
@CODEBASE_REQUIREMENTS_DISPATCHER execute \
  /path/to/source-directory \
  /path/to/analyses-directory \
  /path/to/provisioner-directory \
  /path/to/workers-directory \
  /path/to/codebase-requirements-dispatcher-template.md
```

## Distribution Protocol

### Phase 1: Comprehensive Technical Analysis Integration

**Codebase Content and Analysis Integration:**
```bash
integrate_codebase_and_analysis(source_directory, analyses_directory) {
    
    # Deep codebase content analysis from source directory
    SOURCE_FILES = find_all_source_files("${source_directory}/")
    for file in SOURCE_FILES:
        CONTENT[file] = read_file_content(file)
        APIS[file] = extract_public_apis(CONTENT[file])
        DEPENDENCIES[file] = extract_dependencies(CONTENT[file])
        PATTERNS[file] = identify_code_patterns(CONTENT[file])
        COMPLEXITY[file] = calculate_code_complexity(CONTENT[file])
    done
    
    # Existing analysis integration
    ANALYSIS_FILES = find_analysis_artifacts(analyses_directory)
    for analysis in ANALYSIS_FILES:
        ANALYSIS_CONTENT[analysis] = read_file_content(analysis)
        TECHNICAL_FINDINGS[analysis] = extract_technical_findings(ANALYSIS_CONTENT[analysis])
        COMPETITIVE_INSIGHTS[analysis] = extract_competitive_insights(ANALYSIS_CONTENT[analysis])
        MATURITY_GAPS[analysis] = extract_maturity_gaps(ANALYSIS_CONTENT[analysis])
        IMPROVEMENT_OPPORTUNITIES[analysis] = extract_improvements(ANALYSIS_CONTENT[analysis])
    done
    
    # Synthesize comprehensive technical picture
    CODEBASE_PURPOSE = synthesize_codebase_purpose(CONTENT, APIS, TECHNICAL_FINDINGS)
    COMPETITIVE_POSITION = consolidate_competitive_insights(COMPETITIVE_INSIGHTS)
    MATURITY_ASSESSMENT = consolidate_maturity_gaps(MATURITY_GAPS)
    TECHNICAL_IMPROVEMENTS = consolidate_improvements(IMPROVEMENT_OPPORTUNITIES)
}
```

### Phase 2: Technical Area Discovery and Worker Allocation

**Technical Responsibility Area Extraction:**
```bash
discover_technical_areas(CONTENT, APIS, PATTERNS, TECHNICAL_FINDINGS) {
    
    # Code-based functional clustering
    CODE_CLUSTERS = cluster_related_code(APIS, DEPENDENCIES, PATTERNS)
    
    # Analysis-based improvement clustering  
    IMPROVEMENT_CLUSTERS = cluster_technical_improvements(TECHNICAL_FINDINGS, IMPROVEMENT_OPPORTUNITIES)
    
    # Synthesize technical areas from both code and analysis
    for code_cluster in CODE_CLUSTERS:
        area_name = derive_area_name_from_code(code_cluster.apis, code_cluster.patterns)
        area_improvements = map_improvements_to_code_area(area_name, IMPROVEMENT_CLUSTERS)
        area_competitive_benefits = map_competitive_benefits(area_name, COMPETITIVE_POSITION)
        area_maturity_needs = map_maturity_needs(area_name, MATURITY_ASSESSMENT)
        
        TECHNICAL_AREAS[area_name] = {
            scope: code_cluster.scope,
            boundaries: code_cluster.boundaries,
            complexity: code_cluster.complexity,
            apis: code_cluster.apis,
            implementation_files: code_cluster.files,
            technical_improvements: area_improvements,
            competitive_benefits: area_competitive_benefits,
            maturity_advancement: area_maturity_needs
        }
    done
}

# Optimal worker allocation based on separable technical areas
SEPARABLE_AREAS = count_independent_technical_areas(TECHNICAL_AREAS)
OPTIMAL_WORKERS = MIN(8, MAX(2, SEPARABLE_AREAS + 1)) # +1 for PROVISIONER
WORKER_ASSIGNMENTS = assign_technical_areas_to_workers(TECHNICAL_AREAS, OPTIMAL_WORKERS)
```

### Phase 3: Workspace Structure Generation

**Requirements Workspace Creation:**
```bash
create_workspace_structure(provisioner_directory, workers_directory, optimal_workers) {
    
    # Create provisioner artifacts directory
    mkdir -p "${provisioner_directory}/ARTIFACTS"
    
    # Create worker directories with artifacts folders
    for worker_id in range(1, optimal_workers):
        mkdir -p "${workers_directory}/WORKER-${worker_id:02d}/ARTIFACTS"
    done
    
    # Note: CODEBASE directories will be created by protocols during execution
    # PROVISIONER/CODEBASE/ created by provisioner protocol
    # WORKERS/WORKER-XX/CODEBASE/ created by worker protocols
}
```

### Phase 4: Comprehensive Requirements Generation

**PROVISIONER Requirements (Foundational Infrastructure):**
```bash
generate_provisioner_requirements(provisioner_directory, technical_areas, competitive_position, maturity_assessment) {
    
    provisioner_artifacts = "${provisioner_directory}/ARTIFACTS"
    foundational_needs = extract_infrastructure_needs_from_code_and_analysis(
        CODEBASE_PURPOSE, TECHNICAL_AREAS, COMPETITIVE_POSITION, MATURITY_ASSESSMENT
    )
    
    for need in foundational_needs:
        requirement_details = analyze_foundational_need_comprehensively(
            need, CONTENT, APIS, PATTERNS, TECHNICAL_FINDINGS
        )
        
        requirement_file = "${provisioner_artifacts}/REQUIREMENTS-P-[ID]-[NEED_NAME].md"
        create_requirement_with_comprehensive_analysis(requirement_file, requirement_details)
    done
    
    # Generate provisioner development cycle index
    cycle_index_file = "${provisioner_artifacts}/DEVELOPMENT-CYCLE-INDEX.md"
    create_provisioner_cycle_index(cycle_index_file, foundational_needs)
}
```

**PARALLEL WORKER Requirements (Technical Area Specific):**
```bash
generate_worker_requirements(workers_directory, worker_assignments, technical_areas) {
    
    for worker in PARALLEL_WORKERS:
        worker_artifacts = "${workers_directory}/${worker}/ARTIFACTS"
        technical_area = WORKER_ASSIGNMENTS[worker]
        area_data = TECHNICAL_AREAS[technical_area]
        
        # Generate requirements from code analysis + technical findings
        area_requirements = extract_comprehensive_area_requirements(
            area_data.implementation_files,
            area_data.apis,
            area_data.technical_improvements,
            area_data.competitive_benefits,
            area_data.maturity_advancement
        )
        
        for requirement in area_requirements:
            requirement_details = analyze_requirement_comprehensively(
                requirement, CONTENT, APIS, PATTERNS, TECHNICAL_FINDINGS
            )
            
            requirement_file = "${worker_artifacts}/REQUIREMENTS-W-[WORKER_NUM]-[ID]-[REQ_NAME].md"
            create_requirement_with_comprehensive_analysis(requirement_file, requirement_details)
        done
        
        # Generate worker development cycle index
        cycle_index_file = "${worker_artifacts}/DEVELOPMENT-CYCLE-INDEX.md"
        create_worker_cycle_index(cycle_index_file, area_requirements, technical_area)
    done
}
```

**Note on Stabilizer Requirements:**
Stabilizer requirements are no longer generated by the dispatcher. The stabilizer protocol now performs dynamic assessment and opportunity identification during the stabilization phase, adapting to the actual state of the codebase after parallel development completion.

### Phase 5: Coverage Validation and Execution Readiness

**Zero-Gap Coverage Validation:**
```bash
validate_comprehensive_coverage(codebase_directory) {
    
    # Validate all technical findings are addressed
    all_generated_requirements = find_all_requirements("${codebase_directory}/ARTIFACTS/REQUIREMENTS/")
    all_technical_findings = consolidate_all_technical_findings(TECHNICAL_FINDINGS)
    
    for finding in all_technical_findings:
        addressing_requirement = find_requirement_addressing_finding(finding, all_generated_requirements)
        if addressing_requirement == NULL:
            generate_missing_requirement_for_finding(finding, codebase_directory)
        endif
    done
    
    # Validate all code improvement opportunities are addressed by workers
    all_code_opportunities = extract_all_code_improvement_opportunities(CONTENT, APIS, PATTERNS)
    for opportunity in all_code_opportunities:
        addressing_requirement = find_requirement_addressing_opportunity(opportunity, all_generated_requirements)
        if addressing_requirement == NULL:
            generate_missing_requirement_for_opportunity(opportunity, codebase_directory)
        endif
    done
    
    # Validate execution readiness for parallel workers
    validate_dependency_chains_complete(all_generated_requirements)
    validate_worker_load_balanced(WORKER_ASSIGNMENTS, all_generated_requirements)
    validate_technical_area_coverage_complete(TECHNICAL_AREAS, all_generated_requirements)
}
```

## Success Criteria

### Comprehensive Technical Integration
- [ ] Deep codebase content analysis integrated with existing technical analysis artifacts
- [ ] Codebase purpose and technical position synthesized from all available sources
- [ ] Technical responsibility areas discovered from actual code structure and analysis insights
- [ ] Optimal worker allocation calculated based on separable technical complexity

### Requirements Generation Completion Gates
- Coverage: All analysis findings addressed by requirements ✓
- Structure: Provisioner and worker directories created ✓
- Distribution: Optimal workload allocation achieved ✓
- Readiness: Clear execution dependencies established ✓

## Protocol Guarantees

**Comprehensive Technical Analysis Integration:**
- Deep code content analysis combined with existing technical analysis insights
- Technical responsibility areas discovered from actual implementation and improvement analysis
- Worker allocation optimized for separable technical complexity and competitive advantage
- Requirements generation driven by evidence from code analysis and technical findings

**Complete Requirements Coverage:**
- Zero-gap coverage validation ensures no technical finding goes unaddressed
- All code improvement opportunities translated into actionable provisioner and worker requirements
- Competitive advantages and maturity improvements integrated into requirements
- Complete execution readiness: PROVISIONER → PARALLEL WORKERS → STABILIZER
- Provisioner and worker structures properly organized for protocol consumption

**EXPLICITLY EXCLUDED FROM REQUIREMENTS GENERATION (MVP FOCUS):**
- Version control integration (requirements focus on current codebase state)
- Database versioning requirements (work with current schema)
- Migration pathway requirements (no migration concerns for MVP)
- Deprecation management requirements (we fix problems, don't deprecate)
- Legacy code preservation requirements (transform code, don't preserve)
- Backward compatibility requirements (no compatibility constraints)
- Breaking change mitigation (breaking changes welcomed for MVP clarity)
- Semantic versioning considerations (MVP operates on current iteration)
- API stability preservation (APIs evolve rapidly for MVP optimization)
- Configuration migration requirements (use current configuration)
- Deployment versioning requirements (deploy current state)
- Release management requirements (continuous MVP iteration)
- Documentation versioning (document current state only)
- Rollback procedures (no rollback concerns for MVP)

**Clean Directory Management:**
- All generated provisioner artifacts contained within provisioner directory structure
- All generated worker artifacts contained within workers directory structure
- Clear separation between analysis inputs and requirements outputs
- No impact on source code organization
- Scalable structure supports additional requirements cycles

**Explicit Directory Usage:**
- `<source_directory>/`: Source codebase (READ-ONLY, analyzed for technical areas)
- `<analyses_directory>/`: Analysis artifacts (READ-ONLY, integrated for requirements)
- `<provisioner_directory>/ARTIFACTS/`: Generated provisioner requirements and development cycle
- `<workers_directory>/WORKER-XX/ARTIFACTS/`: Generated worker requirements and development cycles