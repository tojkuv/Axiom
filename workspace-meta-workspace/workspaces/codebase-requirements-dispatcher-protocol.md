# CODEBASE-REQUIREMENTS-DISPATCHER-PROTOCOL

Comprehensive adaptive distribution protocol to transform technical analysis findings and codebase insights into organized requirement sets for sequential and parallel development. Analyzes codebase content and existing analysis artifacts to distribute requirements across specialized worker folders based on technical complexity and separable areas.

## Protocol Activation

```text
@CODEBASE_REQUIREMENTS_DISPATCHER execute <codebase_directory> <analyses_directory> <output_directory> <dispatcher_template>
```

**Parameters:**
- `<codebase_directory>`: Path to directory containing source code for analysis
- `<analyses_directory>`: Path to directory containing analysis artifacts to integrate
- `<output_directory>`: Path to directory where requirement folders will be created
- `<dispatcher_template>`: Requirements template for each generated artifact

**Adaptive Sequential and Parallel Distribution Model**: Runs once to extract ALL technical improvement opportunities from codebase analysis and existing artifacts, then distributes them across specialized worker folders based on technical impact and workload assessment.

**Directory Integration:**
- Reads analysis artifacts from: `<analyses_directory>/`
- Reads source code from: `<codebase_directory>/`
- Generates requirements in: `<output_directory>/`
- Creates output directory structure as needed

**Outputs Generated:**
- 3-9 specialized requirement folders created in output directory (adapts to technical complexity):
  - provisioner-directory/ (foundational requirements - executes first)
  - worker-01-directory/ through worker-07-directory/ (parallel technical area requirements - execute in parallel)
  - stabilizer-directory/ (integration requirements - executes last)
  - coordination-directory/ (execution management and tracking)
- Each folder contains: requirements addressing specific technical improvements from analysis
- Each folder contains: independent development cycle coordination
- Execution order enforced: PROVISIONER → PARALLEL WORKERS → STABILIZER

**Workload-Adaptive Distribution**: Protocol determines optimal number of parallel workers (1-7) based on technical complexity and separable technical areas discovered through codebase analysis.

## Command

### Execute - Comprehensive Requirements Distribution

The execute command transforms technical analysis insights into actionable requirements distributed across optimal worker allocation. It integrates deep codebase content analysis with existing technical assessments to create a complete requirements distribution for technical excellence advancement.

**Core Distribution Process:**
1. **Deep Codebase Content Analysis**: Read ALL source files, APIs, dependencies, patterns
2. **Analysis Integration**: Incorporate findings from analyses directory artifacts
3. **Technical Area Discovery**: Identify separable technical responsibility areas from code structure and analysis insights
4. **Worker Optimization**: Calculate optimal worker count (3-9) based on technical complexity
5. **Requirements Generation**: Create complete requirements for ALL workers in output directory
6. **Coverage Validation**: Ensure zero gaps between analysis findings and generated requirements

```bash
@CODEBASE_REQUIREMENTS_DISPATCHER execute \
  /path/to/codebase-source \
  /path/to/analyses-directory \
  /path/to/output-directory \
  /path/to/codebase-requirements-dispatcher-template.md
```

## Distribution Protocol

### Phase 1: Comprehensive Technical Analysis Integration

**Codebase Content and Analysis Integration:**
```bash
integrate_codebase_and_analysis(codebase_directory, analyses_directory) {
    
    # Deep codebase content analysis
    SOURCE_FILES = find_all_source_files(codebase_directory)
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
OPTIMAL_WORKERS = MIN(9, MAX(3, SEPARABLE_AREAS + 2)) # +2 for PROVISIONER and STABILIZER
WORKER_ASSIGNMENTS = assign_technical_areas_to_workers(TECHNICAL_AREAS, OPTIMAL_WORKERS)
```

### Phase 3: Output Directory Structure Generation

**Requirements Directory Creation:**
```bash
create_requirements_structure(output_directory, optimal_workers) {
    
    # Create output directory structure
    mkdir -p "${output_directory}"
    
    # Create worker directories
    mkdir -p "${output_directory}/provisioner-directory"
    for worker_id in range(1, optimal_workers-1):
        mkdir -p "${output_directory}/worker-${worker_id:02d}-directory"
    done
    mkdir -p "${output_directory}/stabilizer-directory"
    mkdir -p "${output_directory}/coordination-directory"
}
```

### Phase 4: Comprehensive Requirements Generation

**PROVISIONER Requirements (Foundational Infrastructure):**
```bash
generate_provisioner_requirements(output_directory, technical_areas, competitive_position, maturity_assessment) {
    
    provisioner_folder = "${output_directory}/provisioner-directory"
    foundational_needs = extract_infrastructure_needs_from_code_and_analysis(
        CODEBASE_PURPOSE, TECHNICAL_AREAS, COMPETITIVE_POSITION, MATURITY_ASSESSMENT
    )
    
    for need in foundational_needs:
        requirement_details = analyze_foundational_need_comprehensively(
            need, CONTENT, APIS, PATTERNS, TECHNICAL_FINDINGS
        )
        
        requirement_file = "${provisioner_folder}/REQUIREMENTS-P-[ID]-[NEED_NAME].md"
        create_requirement_with_comprehensive_analysis(requirement_file, requirement_details)
    done
}
```

**PARALLEL WORKER Requirements (Technical Area Specific):**
```bash
generate_worker_requirements(output_directory, worker_assignments, technical_areas) {
    
    for worker in PARALLEL_WORKERS:
        worker_folder = "${output_directory}/${worker}-directory"
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
            
            requirement_file = "${worker_folder}/REQUIREMENTS-W-[WORKER_NUM]-[ID]-[REQ_NAME].md"
            create_requirement_with_comprehensive_analysis(requirement_file, requirement_details)
        done
    done
}
```

**STABILIZER Requirements (Integration and Validation):**
```bash
generate_stabilizer_requirements(output_directory, technical_areas, competitive_position, maturity_assessment) {
    
    stabilizer_folder = "${output_directory}/stabilizer-directory"
    
    # Integration requirements from cross-area analysis
    integration_needs = identify_integration_requirements(TECHNICAL_AREAS, APIS, DEPENDENCIES)
    
    # Competitive validation requirements
    competitive_validation = extract_competitive_validation_requirements(COMPETITIVE_POSITION)
    
    # Maturity validation requirements  
    maturity_validation = extract_maturity_validation_requirements(MATURITY_ASSESSMENT)
    
    all_stabilizer_requirements = merge_stabilizer_requirements(
        integration_needs, competitive_validation, maturity_validation
    )
    
    for requirement in all_stabilizer_requirements:
        requirement_details = analyze_stabilizer_requirement_comprehensively(
            requirement, TECHNICAL_AREAS, COMPETITIVE_POSITION, MATURITY_ASSESSMENT
        )
        
        requirement_file = "${stabilizer_folder}/REQUIREMENTS-S-[ID]-[REQ_NAME].md"
        create_requirement_with_comprehensive_analysis(requirement_file, requirement_details)
    done
}
```

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
    
    # Validate all code improvement opportunities are addressed
    all_code_opportunities = extract_all_code_improvement_opportunities(CONTENT, APIS, PATTERNS)
    for opportunity in all_code_opportunities:
        addressing_requirement = find_requirement_addressing_opportunity(opportunity, all_generated_requirements)
        if addressing_requirement == NULL:
            generate_missing_requirement_for_opportunity(opportunity, codebase_directory)
        endif
    done
    
    # Validate execution readiness
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

### Complete Requirements Coverage
- [ ] ALL foundational infrastructure requirements generated in PROVISIONER/
- [ ] ALL technical area requirements generated for each WORKER/
- [ ] ALL integration and validation requirements generated in STABILIZER/
- [ ] ALL technical findings and improvement opportunities addressed by requirements

### ARTIFACTS Structure Integrity
- [ ] Clean ARTIFACTS folder organization with ANALYSES/ and REQUIREMENTS/ separation
- [ ] Complete worker folder structure generated in ARTIFACTS/REQUIREMENTS/
- [ ] Coordination artifacts generated for execution management
- [ ] No interference with source code or version control

### Execution Readiness Validation
- [ ] Zero gaps between analysis findings and generated requirements
- [ ] Clear dependency chains: PROVISIONER → WORKERS → STABILIZER
- [ ] Balanced workload distribution across parallel workers
- [ ] Technical area coverage validated for completeness

## Protocol Guarantees

**Comprehensive Technical Analysis Integration:**
- Deep code content analysis combined with existing technical analysis insights
- Technical responsibility areas discovered from actual implementation and improvement analysis
- Worker allocation optimized for separable technical complexity and competitive advantage
- Requirements generation driven by evidence from code analysis and technical findings

**Complete Requirements Coverage:**
- Zero-gap coverage validation ensures no technical finding goes unaddressed
- All code improvement opportunities translated into actionable requirements
- Competitive advantages and maturity improvements integrated into requirements
- Complete execution readiness with clear dependency management

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

**Clean ARTIFACTS Management:**
- All generated artifacts contained within ARTIFACTS folder structure
- Clear separation between analysis inputs and requirements outputs
- No impact on source code organization
- Scalable structure supports additional analysis and requirements cycles