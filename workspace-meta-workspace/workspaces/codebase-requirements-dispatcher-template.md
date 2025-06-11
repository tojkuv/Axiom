# CODEBASE-REQUIREMENTS-DISPATCHER

*Complete Codebase Requirements Generation and Distribution System*

## PROTOCOL INPUTS

**Required Inputs for Dispatcher Execution:**
- **Codebase Directory**: [CODEBASE_DIRECTORY_PATH] (containing source code for analysis)
- **Analyses Directory**: [ANALYSES_DIRECTORY_PATH] (containing analysis artifacts to integrate)
- **Output Directory**: [OUTPUT_DIRECTORY_PATH] (where requirement folders will be created)
- **Dispatcher Template**: [This template file that drives the generation process]

**Directory Structure:**
- Reads analysis artifacts from: [ANALYSES_DIRECTORY_PATH]/
- Reads source code from: [CODEBASE_DIRECTORY_PATH]/
- Generates worker folders in: [OUTPUT_DIRECTORY_PATH]/
- Creates output directory structure as needed

## CRITICAL: DEEP CODE ANALYSIS REQUIREMENT

**MANDATORY: Read Code Content, Not Just File Structure**

This protocol MUST perform deep code content analysis, not superficial file/folder scanning:

**❌ WRONG APPROACH - Structural Analysis Only:**
- Reading file and folder names
- Counting directories
- Looking at import statements only
- Analyzing package structure
- Making assumptions from naming conventions

**✅ CORRECT APPROACH - Deep Code Content Analysis:**
- **Read ALL source file contents** (.swift, .kt, .java, .ts, .js, .py, etc.)
- **Extract and analyze ALL public APIs** from actual function/method signatures
- **Analyze ALL dependencies** from actual import/use statements in code
- **Identify ALL code patterns** from actual implementation details
- **Calculate complexity** from actual code metrics (cyclomatic complexity, lines of code, etc.)
- **Understand actual functionality** from reading method implementations and business logic
- **Discover real architecture** from analyzing how components actually interact in code

**Why Deep Code Analysis is Critical:**
- File structure can be misleading or inconsistent with actual functionality
- Framework purpose can only be understood by analyzing what the code actually does
- Responsibility areas emerge from actual API boundaries and implementation coupling
- Requirements must address real code complexity and improvement opportunities
- Worker allocation must be based on actual separable functionality, not assumed domains

**Generated Outputs:**
- **Codebase Purpose**: [Discovered codebase purpose from technical analysis]
- **Worker Count**: [3-9 workers based on technical complexity and separable areas]
- **Total Requirements Generated**: [Count of all requirements across all workers]
- **ARTIFACTS Structure**: [Complete folder hierarchy generated in ARTIFACTS/REQUIREMENTS/]
- **Dispatch Date**: YYYY-MM-DD
- **Source Analyses**: [All analysis files from ARTIFACTS/ANALYSES/ that contributed evidence]
- **Technical Areas**: [List of discovered technical responsibility areas from codebase]
- **Coverage Validation**: [Verification that all technical improvement needs are addressed]

## COMPREHENSIVE REQUIREMENTS GENERATION PROTOCOL

### Phase 1: Codebase Technical Analysis  
**MANDATORY BEFORE ANY REQUIREMENT GENERATION**

**1.1 Deep Codebase Content Analysis (Read All Code, Not Just Structure)**
**CRITICAL: Must read actual code content, not just file/folder names**

```bash
# Phase 1A: Comprehensive Code Content Reading
read_all_source_files(CODEBASE_DIRECTORY) {
    
    # Read all source code files (.swift, .kt, .java, .ts, .js, .py, etc.)
    SOURCE_FILES = find_all_source_files(CODEBASE_DIRECTORY)
    for file in SOURCE_FILES:
        CONTENT[file] = read_file_content(file)
        APIS[file] = extract_public_apis(CONTENT[file])
        DEPENDENCIES[file] = extract_dependencies(CONTENT[file])
        PATTERNS[file] = identify_code_patterns(CONTENT[file])
        COMPLEXITY[file] = calculate_code_complexity(CONTENT[file])
    done
    
    # Read configuration and build files
    CONFIG_FILES = find_config_files(CODEBASE_DIRECTORY) # Package.swift, build.gradle, package.json, etc.
    for config in CONFIG_FILES:
        BUILD_INFO[config] = read_file_content(config)
        EXTERNAL_DEPS[config] = extract_external_dependencies(BUILD_INFO[config])
    done
    
    # Read existing analysis artifacts from ARTIFACTS folder
    ANALYSIS_FILES = find_analysis_artifacts("${CODEBASE_DIRECTORY}/ARTIFACTS/ANALYSES/")
    for analysis in ANALYSIS_FILES:
        ANALYSIS_CONTENT[analysis] = read_file_content(analysis)
        TECHNICAL_FINDINGS[analysis] = extract_technical_findings(ANALYSIS_CONTENT[analysis])
        IMPROVEMENT_OPPORTUNITIES[analysis] = extract_improvements(ANALYSIS_CONTENT[analysis])
    done
}

# Phase 1B: Codebase Purpose Discovery from Code Content and Analysis
analyze_codebase_purpose_from_code_and_analysis(CONTENT, APIS, DEPENDENCIES, PATTERNS, TECHNICAL_FINDINGS) {
    
    # Analyze what the code actually does
    PRIMARY_FUNCTIONALITY = identify_main_capabilities(APIS, CONTENT)
    PROBLEM_DOMAIN = infer_problem_domain(PRIMARY_FUNCTIONALITY, EXTERNAL_DEPS)
    CODEBASE_TYPE = classify_codebase_type(PROBLEM_DOMAIN, PATTERNS)
    
    # Examples of codebase types discovered from analysis:
    # - Application: User-facing software with business logic and UI
    # - Library: Reusable components for other software
    # - Framework: Infrastructure for building applications
    # - Service: Server-side processing and API endpoints
    # - Tool: Utility software for development or automation
    # - System: Low-level software interfacing with hardware/OS
    
    # Incorporate analysis findings
    COMPETITIVE_POSITION = extract_competitive_insights(TECHNICAL_FINDINGS)
    MATURITY_GAPS = extract_maturity_improvements(TECHNICAL_FINDINGS)
    
    CODEBASE_PURPOSE = synthesize_purpose(PRIMARY_FUNCTIONALITY, PROBLEM_DOMAIN, CODEBASE_TYPE, COMPETITIVE_POSITION)
}

# Phase 1C: Technical Responsibility Area Extraction from Implementation Analysis
extract_technical_areas_from_implementation(CONTENT, APIS, PATTERNS, TECHNICAL_FINDINGS) {
    
    # Group related functionality based on code analysis and technical findings
    FUNCTIONAL_CLUSTERS = cluster_related_code(APIS, DEPENDENCIES, PATTERNS)
    TECHNICAL_IMPROVEMENTS = cluster_technical_improvements(TECHNICAL_FINDINGS, IMPROVEMENT_OPPORTUNITIES)
    
    for cluster in FUNCTIONAL_CLUSTERS:
        area_name = derive_area_name_from_code(cluster.apis, cluster.patterns)
        area_scope = define_scope_from_implementation(cluster.content)
        area_boundaries = identify_boundaries_from_dependencies(cluster.dependencies)
        area_complexity = calculate_cluster_complexity(cluster.content)
        area_improvements = map_improvements_to_area(area_name, TECHNICAL_IMPROVEMENTS)
        
        TECHNICAL_AREAS[area_name] = {
            scope: area_scope,
            boundaries: area_boundaries, 
            complexity: area_complexity,
            apis: cluster.apis,
            implementation_files: cluster.files,
            technical_improvements: area_improvements
        }
    done
}

# Execute complete codebase content and analysis integration
CODEBASE_PURPOSE = analyze_codebase_purpose_from_code_and_analysis(CODEBASE_DIRECTORY)
TECHNICAL_AREAS = extract_technical_areas_from_implementation(CODEBASE_DIRECTORY)
COMPLEXITY_DISTRIBUTION = map_complexity_from_code_analysis(TECHNICAL_AREAS)
NATURAL_BOUNDARIES = identify_boundaries_from_dependencies(TECHNICAL_AREAS)
FOUNDATIONAL_NEEDS = extract_infrastructure_needs_from_code(CODEBASE_PURPOSE, TECHNICAL_AREAS)
```

**1.2 Worker Allocation Calculation**
```bash
SEPARABLE_AREAS = count_independent_technical_areas(TECHNICAL_AREAS)
OPTIMAL_WORKERS = MIN(9, MAX(3, SEPARABLE_AREAS + 2))
WORKER_ASSIGNMENTS = assign_areas_to_workers(TECHNICAL_AREAS, OPTIMAL_WORKERS)
```

**1.3 ARTIFACTS Requirements Structure Generation (Generate in ARTIFACTS Folder)**
```bash
# Create complete worker folder structure in ARTIFACTS/REQUIREMENTS
create_requirements_structure(CODEBASE_DIRECTORY) {
    
    # Create ARTIFACTS structure
    artifacts_dir = "${CODEBASE_DIRECTORY}/ARTIFACTS"
    requirements_dir = "${artifacts_dir}/REQUIREMENTS"
    mkdir -p "${requirements_dir}"
    
    # Create main worker directories
    mkdir -p "${requirements_dir}/PROVISIONER"
    mkdir -p "${requirements_dir}/WORKER-01"
    mkdir -p "${requirements_dir}/WORKER-02" 
    mkdir -p "${requirements_dir}/WORKER-03"
    
    # Create additional worker directories as needed
    for worker_id in range(4, OPTIMAL_WORKERS-1):
        mkdir -p "${requirements_dir}/WORKER-${worker_id:02d}"
    done
    
    mkdir -p "${requirements_dir}/STABILIZER"
    
    # Create coordination directory for execution management
    mkdir -p "${requirements_dir}/COORDINATION"
}
```

**1.4 Complete Requirement Inventory Planning**
- **PROVISIONER Requirements**: [Count] foundational requirements → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/`
- **WORKER-01 Requirements**: [Count] requirements for [Technical Area 1] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-01/`
- **WORKER-02 Requirements**: [Count] requirements for [Technical Area 2] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-02/`
- **WORKER-03 Requirements**: [Count] requirements for [Technical Area 3] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-03/`
- **WORKER-04 Requirements**: [Count] requirements for [Technical Area 4] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-04/` (if needed)
- **WORKER-05 Requirements**: [Count] requirements for [Technical Area 5] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-05/` (if needed)
- **WORKER-06 Requirements**: [Count] requirements for [Technical Area 6] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-06/` (if needed)
- **WORKER-07 Requirements**: [Count] requirements for [Technical Area 7] → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-07/` (if needed)
- **STABILIZER Requirements**: [Count] integration and validation requirements → `${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/`

### Phase 2: Complete Requirements Generation Matrix

**2.1 PROVISIONER Requirements Generation (MANDATORY)**
**Must generate ALL foundational requirements in ARTIFACTS PROVISIONER folder:**

```bash
FOR EACH foundational_need IN FOUNDATIONAL_NEEDS:
    # Extract foundational need details from actual code analysis and technical findings
    need_details = analyze_foundational_need_from_code(foundational_need, CONTENT, APIS, PATTERNS)
    current_implementation = find_existing_implementation(foundational_need, CODEBASE_DIRECTORY)
    gaps = identify_implementation_gaps(need_details, current_implementation)
    technical_improvements = extract_foundational_improvements(foundational_need, TECHNICAL_FINDINGS)
    
    requirement_file = "${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-[ID]-[FOUNDATIONAL_NEED_NAME].md"
    CREATE requirement_file WITH {
        purpose: need_details.purpose,
        current_state: current_implementation,
        gaps_identified: gaps,
        technical_improvements: technical_improvements,
        code_examples: extract_relevant_code_snippets(foundational_need, CONTENT),
        api_impact: analyze_api_impact(foundational_need, APIS),
        competitive_advantage: extract_competitive_benefits(foundational_need, COMPETITIVE_POSITION),
        maturity_advancement: extract_maturity_benefits(foundational_need, MATURITY_GAPS)
    }
    ASSIGN TO PROVISIONER
    SET PRIORITY = CRITICAL
    SET DEPENDENCIES = []
    VALIDATE infrastructure_enables_codebase_purpose_from_code()
END FOR

PROVISIONER_REQUIREMENTS_GENERATED = [
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-001-CORE-ABSTRACTIONS.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-002-ERROR-HANDLING.md  
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-003-LOGGING-INFRASTRUCTURE.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-004-BUILD-SYSTEM.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/PROVISIONER/REQUIREMENTS-P-005-BASE-TESTING.md
    // Additional foundational requirements based on codebase purpose and technical analysis
]
```

**2.2 PARALLEL WORKER Requirements Generation (MANDATORY)**
**Must generate ALL requirements for each technical area in respective ARTIFACTS worker folders:**

```bash
FOR EACH worker IN PARALLEL_WORKERS:
    worker_folder = "${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/${worker}"
    technical_area = WORKER_ASSIGNMENTS[worker]
    
    # Deep analysis of technical area from code content and technical findings
    area_code_files = TECHNICAL_AREAS[technical_area].implementation_files
    area_apis = TECHNICAL_AREAS[technical_area].apis
    area_patterns = extract_patterns_from_files(area_code_files, CONTENT)
    area_dependencies = extract_dependencies_from_files(area_code_files, DEPENDENCIES)
    area_improvements = TECHNICAL_AREAS[technical_area].technical_improvements
    
    requirements_for_area = extract_requirements_from_code_analysis(
        area_code_files, area_apis, area_patterns, area_dependencies, area_improvements, CONTENT
    )
    
    FOR EACH requirement IN requirements_for_area:
        # Generate requirement based on actual code analysis and technical findings
        requirement_details = analyze_requirement_from_code(requirement, CONTENT, APIS, PATTERNS)
        current_implementation = find_current_implementation(requirement, area_code_files, CONTENT)
        improvement_opportunities = identify_improvements_from_code(requirement, current_implementation)
        technical_enhancements = extract_technical_enhancements(requirement, area_improvements)
        competitive_benefits = extract_competitive_benefits(requirement, COMPETITIVE_POSITION)
        
        requirement_file = "${worker_folder}/REQUIREMENTS-W-[WORKER_NUM]-[ID]-[REQUIREMENT_NAME].md"
        CREATE requirement_file WITH {
            purpose: requirement_details.purpose,
            current_state: current_implementation,
            improvement_opportunities: improvement_opportunities,
            technical_enhancements: technical_enhancements,
            competitive_benefits: competitive_benefits,
            code_examples: extract_relevant_code_snippets(requirement, CONTENT),
            api_impact: analyze_api_impact(requirement, area_apis),
            implementation_guidance: derive_implementation_guidance_from_patterns(requirement, area_patterns),
            maturity_advancement: extract_maturity_benefits(requirement, MATURITY_GAPS)
        }
        ASSIGN TO worker
        SET technical_area = technical_area
        SET dependencies = calculate_dependencies_from_code_analysis(requirement, PROVISIONER_REQUIREMENTS_GENERATED)
        VALIDATE serves_codebase_purpose_from_code()
    END FOR
END FOR

WORKER_REQUIREMENTS_GENERATED = [
    // WORKER-01 (Technical Area 1)
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-01/REQUIREMENTS-W-01-001-[AREA1_FEATURE1].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-01/REQUIREMENTS-W-01-002-[AREA1_FEATURE2].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-01/REQUIREMENTS-W-01-003-[AREA1_FEATURE3].md
    
    // WORKER-02 (Technical Area 2)  
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-02/REQUIREMENTS-W-02-001-[AREA2_FEATURE1].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-02/REQUIREMENTS-W-02-002-[AREA2_FEATURE2].md
    
    // WORKER-03 (Technical Area 3)
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-03/REQUIREMENTS-W-03-001-[AREA3_FEATURE1].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-03/REQUIREMENTS-W-03-002-[AREA3_FEATURE2].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-03/REQUIREMENTS-W-03-003-[AREA3_FEATURE3].md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/WORKER-03/REQUIREMENTS-W-03-004-[AREA3_FEATURE4].md
    
    // Continue for all allocated workers...
]
```

**2.3 STABILIZER Requirements Generation (MANDATORY)**
**Must generate ALL integration and validation requirements in ARTIFACTS STABILIZER folder:**

```bash
stabilizer_folder = "${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER"

# Analyze integration needs from actual code interfaces, dependencies, and technical findings
cross_area_apis = analyze_cross_area_api_interactions(TECHNICAL_AREAS, APIS, DEPENDENCIES)
integration_points = identify_integration_points_from_code(cross_area_apis, PATTERNS)
validation_needs = extract_validation_requirements_from_code(CODEBASE_PURPOSE, CONTENT)
consistency_requirements = identify_api_consistency_needs(APIS, PATTERNS)
competitive_validation = extract_competitive_validation_needs(COMPETITIVE_POSITION)
maturity_validation = extract_maturity_validation_needs(MATURITY_GAPS)

FOR EACH integration_point IN integration_points:
    # Generate integration requirement based on actual code analysis and technical findings
    integration_details = analyze_integration_from_code(integration_point, cross_area_apis, CONTENT)
    current_integration_state = find_existing_integration_code(integration_point, CODEBASE_DIRECTORY, CONTENT)
    integration_gaps = identify_integration_gaps_from_code(integration_details, current_integration_state)
    competitive_integration = extract_competitive_integration_benefits(integration_point, COMPETITIVE_POSITION)
    
    requirement_file = "${stabilizer_folder}/REQUIREMENTS-S-[ID]-[INTEGRATION_NAME].md"
    CREATE requirement_file WITH {
        purpose: integration_details.purpose,
        current_state: current_integration_state,
        integration_gaps: integration_gaps,
        competitive_integration: competitive_integration,
        api_coordination: analyze_api_coordination_needs(integration_point, cross_area_apis),
        code_examples: extract_integration_code_snippets(integration_point, CONTENT),
        validation_approach: derive_validation_approach_from_code(integration_point, PATTERNS),
        maturity_advancement: extract_maturity_benefits(integration_point, MATURITY_GAPS)
    }
    ASSIGN TO STABILIZER
    SET dependencies = WORKER_REQUIREMENTS_GENERATED
    VALIDATE ensures_codebase_purpose_fulfillment_from_code()
END FOR

STABILIZER_REQUIREMENTS_GENERATED = [
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-001-API-CONSISTENCY.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-002-CROSS-AREA-INTEGRATION.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-003-PERFORMANCE-VALIDATION.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-004-PURPOSE-FULFILLMENT.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-005-FINAL-TESTING.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-006-COMPETITIVE-VALIDATION.md
    ${CODEBASE_DIRECTORY}/ARTIFACTS/REQUIREMENTS/STABILIZER/REQUIREMENTS-S-007-MATURITY-VALIDATION.md
    // Additional stabilization requirements based on integration analysis and technical findings
]
```

### Phase 3: Requirements Distribution Validation

**3.1 Code-Based Coverage Matrix Validation**
```bash
# Validate that all code analysis findings are addressed by requirements
VALIDATE FOR EACH code_analysis_finding IN COMPREHENSIVE_CODE_ANALYSIS:
    # Check if code-based finding is addressed by generated requirements
    requirement_assigned = find_requirement_addressing_code_finding(code_analysis_finding, ALL_GENERATED_REQUIREMENTS)
    
    IF requirement_assigned == NULL:
        # Generate missing requirement based on specific code analysis
        missing_requirement_details = analyze_missing_requirement_from_code(code_analysis_finding, CONTENT, APIS, PATTERNS)
        appropriate_worker = determine_worker_from_code_analysis(code_analysis_finding, RESPONSIBILITY_AREAS)
        GENERATE missing_requirement WITH code_analysis_evidence
        ASSIGN TO appropriate_worker
    END IF
END FOR

# Validate that requirements address actual code implementation needs
VALIDATE FOR EACH requirement IN ALL_GENERATED_REQUIREMENTS:
    code_evidence = find_supporting_code_evidence(requirement, CONTENT, APIS, PATTERNS)
    IF code_evidence == INSUFFICIENT:
        ENHANCE requirement WITH additional_code_analysis
    END IF
END FOR
```

**3.2 Worker Load Balancing Validation**
```
FOR EACH worker IN ALL_WORKERS:
    complexity_total = sum_complexity(worker.requirements)
    IF complexity_total > THRESHOLD_OVERLOAD:
        redistribute_requirements(worker, least_loaded_worker)
    END IF
END FOR
```

**3.3 Dependency Chain Validation**
```
VALIDATE dependency_chain_completeness():
    PROVISIONER requirements have no external dependencies
    WORKER requirements depend only on PROVISIONER outputs
    STABILIZER requirements depend on all WORKER outputs
    No circular dependencies exist
END VALIDATE
```

## Complete Requirements Generation and Validation Protocol

### Phase 4: Requirement File Generation Execution

**4.1 Automated Generation Pipeline**
```bash
# Execute complete requirements generation in workspace
execute_requirements_generation_pipeline(WORKSPACE_FOLDER, CODEBASE_FOLDER, DISPATCHER_TEMPLATE) {
    
    # Phase 0: Create workspace structure
    create_workspace_structure(WORKSPACE_FOLDER)
    
    # Phase 1: Generate all PROVISIONER requirements in workspace based on deep code analysis
    provisioner_folder = "${WORKSPACE_FOLDER}/PROVISIONER"
    for foundational_requirement in FOUNDATIONAL_NEEDS:
        # Analyze foundational requirement from actual code content
        code_analysis = perform_deep_code_analysis_for_requirement(foundational_requirement, CONTENT, APIS, PATTERNS)
        current_implementation = find_existing_implementation_in_code(foundational_requirement, CONTENT)
        gaps = identify_gaps_from_code_analysis(foundational_requirement, current_implementation)
        
        requirement_file = "${provisioner_folder}/REQUIREMENTS-P-[sequential_id]-[name].md"
        generate_requirement_file(
            file_path=requirement_file,
            type="PROVISIONER",
            id="P-[sequential_id]",
            title=foundational_requirement.name,
            worker="PROVISIONER",
            dependencies=[],
            priority="CRITICAL",
            codebase_source=CODEBASE_FOLDER,
            code_analysis_evidence=code_analysis,
            current_implementation=current_implementation,
            implementation_gaps=gaps,
            code_examples=extract_relevant_code_examples(foundational_requirement, CONTENT)
        )
    done
    
    # Phase 2: Generate all WORKER requirements in workspace
    for worker_id in range(1, ALLOCATED_WORKER_COUNT):
        worker_folder = "${WORKSPACE_FOLDER}/WORKER-${worker_id:02d}"
        responsibility_area = WORKER_ASSIGNMENTS[worker_id]
        requirements_list = extract_requirements_for_area(responsibility_area, CODEBASE_FOLDER)
        
        for requirement in requirements_list:
            requirement_file = "${worker_folder}/REQUIREMENTS-W-${worker_id:02d}-[sequential_id]-[name].md"
            generate_requirement_file(
                file_path=requirement_file,
                type="WORKER",
                id="W-${worker_id:02d}-[sequential_id]",
                title=requirement.name,
                worker="WORKER-${worker_id:02d}",
                responsibility_area=responsibility_area,
                dependencies=requirement.dependencies,
                priority=requirement.priority,
                codebase_source=CODEBASE_FOLDER
            )
        done
    done
    
    # Phase 3: Generate all STABILIZER requirements in workspace
    stabilizer_folder = "${WORKSPACE_FOLDER}/STABILIZER"
    for integration_requirement in INTEGRATION_NEEDS:
        requirement_file = "${stabilizer_folder}/REQUIREMENTS-S-[sequential_id]-[name].md"
        generate_requirement_file(
            file_path=requirement_file,
            type="STABILIZER", 
            id="S-[sequential_id]",
            title=integration_requirement.name,
            worker="STABILIZER",
            dependencies=ALL_WORKER_REQUIREMENTS_GENERATED,
            priority="HIGH",
            codebase_source=CODEBASE_FOLDER
        )
    done
}
```

**4.2 Requirement File Validation Matrix**
```bash
validate_complete_generation() {
    
    # Validate PROVISIONER completeness
    assert count(PROVISIONER_REQUIREMENTS) >= count(FOUNDATIONAL_NEEDS)
    assert all_foundational_areas_covered(PROVISIONER_REQUIREMENTS)
    
    # Validate WORKER completeness  
    for worker in PARALLEL_WORKERS:
        area = WORKER_ASSIGNMENTS[worker]
        assert count(worker.requirements) >= minimum_area_coverage(area)
        assert all_area_needs_covered(worker.requirements, area)
    done
    
    # Validate STABILIZER completeness
    assert count(STABILIZER_REQUIREMENTS) >= count(INTEGRATION_POINTS)
    assert all_integration_points_covered(STABILIZER_REQUIREMENTS)
    
    # Validate total coverage
    assert all_analysis_findings_addressed(ALL_REQUIREMENTS)
    assert no_requirement_gaps_exist()
}
```

### Phase 5: Zero-Gap Requirements Coverage

**5.1 Analysis Finding Coverage Matrix**
```
COVERAGE_MATRIX = {
    analysis_file_1: {
        finding_1: REQUIREMENTS-P-001,
        finding_2: REQUIREMENTS-W-01-003,
        finding_3: REQUIREMENTS-S-002,
        // ALL findings must map to requirements
    },
    analysis_file_2: {
        finding_1: REQUIREMENTS-W-02-001,
        finding_2: REQUIREMENTS-W-03-002,
        // Continue until ALL findings covered
    }
    // Continue for ALL analysis files
}
```

**5.2 Worker Assignment Completeness Check**
```bash
verify_worker_assignment_completeness() {
    
    # Check PROVISIONER has infrastructure for framework purpose
    required_infrastructure = extract_infrastructure_needs(FRAMEWORK_PURPOSE)
    provisioner_coverage = map_requirements_to_infrastructure(PROVISIONER_REQUIREMENTS)
    assert provisioner_coverage.covers_all(required_infrastructure)
    
    # Check each WORKER has complete responsibility area coverage
    for worker in PARALLEL_WORKERS:
        area_requirements = extract_area_needs(worker.responsibility_area)
        worker_coverage = map_requirements_to_area(worker.requirements)
        assert worker_coverage.covers_all(area_requirements)
    done
    
    # Check STABILIZER has complete integration coverage
    integration_requirements = extract_integration_needs(ALL_WORKER_OUTPUTS)
    stabilizer_coverage = map_requirements_to_integration(STABILIZER_REQUIREMENTS)
    assert stabilizer_coverage.covers_all(integration_requirements)
}

## Complete Requirements Generation Output

### Expected ARTIFACTS Structure Output

**Complete Generated ARTIFACTS Structure:**

```
${CODEBASE_DIRECTORY}/
├── [source code files...]
├── ARTIFACTS/
│   ├── ANALYSES/
│   │   ├── CODEBASE-ANALYSIS-YYYYMMDD-HHMMSS-SSSSSS-XXXXX-RND.md
│   │   └── [Additional analysis artifacts...]
│   │
│   └── REQUIREMENTS/
│       ├── PROVISIONER/
│       │   ├── REQUIREMENTS-P-001-CORE-ABSTRACTIONS.md
│       │   ├── REQUIREMENTS-P-002-ERROR-HANDLING.md
│       │   ├── REQUIREMENTS-P-003-LOGGING-INFRASTRUCTURE.md
│       │   ├── REQUIREMENTS-P-004-BUILD-SYSTEM.md
│       │   ├── REQUIREMENTS-P-005-BASE-TESTING.md
│       │   └── [Additional foundational requirements based on codebase purpose]
│       │
│       ├── WORKER-01/
│       │   ├── REQUIREMENTS-W-01-001-[AREA1_CORE_FEATURE].md
│       │   ├── REQUIREMENTS-W-01-002-[AREA1_SECONDARY_FEATURE].md
│       │   ├── REQUIREMENTS-W-01-003-[AREA1_UTILITIES].md
│       │   └── [Additional requirements for Technical Area 1]
│       │
│       ├── WORKER-02/
│       │   ├── REQUIREMENTS-W-02-001-[AREA2_CORE_FEATURE].md
│       │   ├── REQUIREMENTS-W-02-002-[AREA2_SECONDARY_FEATURE].md
│       │   └── [Additional requirements for Technical Area 2]
│       │
│       ├── WORKER-03/
│       │   ├── REQUIREMENTS-W-03-001-[AREA3_CORE_FEATURE].md
│       │   ├── REQUIREMENTS-W-03-002-[AREA3_SECONDARY_FEATURE].md
│       │   ├── REQUIREMENTS-W-03-003-[AREA3_UTILITIES].md
│       │   └── [Additional requirements for Technical Area 3]
│       │
│       ├── [WORKER-04/ through WORKER-07/ as needed based on codebase complexity]
│       │
│       ├── STABILIZER/
│       │   ├── REQUIREMENTS-S-001-API-CONSISTENCY.md
│       │   ├── REQUIREMENTS-S-002-CROSS-AREA-INTEGRATION.md
│       │   ├── REQUIREMENTS-S-003-PERFORMANCE-VALIDATION.md
│       │   ├── REQUIREMENTS-S-004-PURPOSE-FULFILLMENT.md
│       │   ├── REQUIREMENTS-S-005-FINAL-TESTING.md
│       │   ├── REQUIREMENTS-S-006-COMPETITIVE-VALIDATION.md
│       │   ├── REQUIREMENTS-S-007-MATURITY-VALIDATION.md
│       │   └── [Additional integration requirements based on technical findings]
│       │
│       └── COORDINATION/
│           ├── WORKER-ALLOCATION-SUMMARY.md
│           ├── TECHNICAL-AREA-MAPPING.md
│           └── REQUIREMENTS-COVERAGE-MATRIX.md
```

### Protocol Execution Command

**Complete Dispatcher Execution:**

```bash
# Execute the complete requirements dispatcher protocol
execute_codebase_requirements_dispatcher(
    codebase_directory="/path/to/codebase",
    dispatcher_template="/path/to/this/template.md"
)

# This will:
# 1. Analyze codebase_directory to discover codebase purpose and read existing analysis artifacts
# 2. Generate complete ARTIFACTS/REQUIREMENTS structure in codebase_directory
# 3. Generate ALL requirements for ALL workers in ARTIFACTS/REQUIREMENTS folders
# 4. Validate complete coverage and execution readiness
```

**Input/Output Summary:**
- **INPUT**: Codebase directory + Dispatcher template
- **PROCESS**: Code + analysis integration → Technical area mapping → Complete requirements generation
- **OUTPUT**: Complete ARTIFACTS/REQUIREMENTS structure with ALL worker folders and requirements generated

## Dispatcher Execution Checklist

### Pre-Generation Validation
- [ ] **Framework Purpose Identified**: Clear understanding of what problem this framework solves
- [ ] **Responsibility Areas Mapped**: All distinct functional areas within the purpose identified
- [ ] **Complexity Distribution Calculated**: Understanding of where complexity concentrates
- [ ] **Natural Boundaries Discovered**: Clear separation points between responsibility areas
- [ ] **Worker Count Determined**: Optimal worker allocation (3-9) based on separable areas

### Generation Execution Checklist  
- [ ] **PROVISIONER Requirements Generated**: ALL foundational infrastructure requirements created
- [ ] **WORKER-01 Requirements Generated**: ALL requirements for highest complexity responsibility area
- [ ] **WORKER-02 Requirements Generated**: ALL requirements for second responsibility area  
- [ ] **WORKER-03 Requirements Generated**: ALL requirements for third responsibility area
- [ ] **WORKER-04 Requirements Generated**: Requirements for fourth area (if applicable)
- [ ] **WORKER-05 Requirements Generated**: Requirements for fifth area (if applicable)
- [ ] **WORKER-06 Requirements Generated**: Requirements for sixth area (if applicable)
- [ ] **WORKER-07 Requirements Generated**: Requirements for seventh area (if applicable)
- [ ] **STABILIZER Requirements Generated**: ALL integration and validation requirements created

### Post-Generation Validation
- [ ] **Coverage Matrix Complete**: Every analysis finding maps to a requirement
- [ ] **No Missing Requirements**: All framework purpose needs addressed
- [ ] **Dependency Chain Valid**: PROVISIONER → WORKERS → STABILIZER dependency flow correct
- [ ] **Worker Load Balanced**: No worker overloaded, workload distributed appropriately
- [ ] **Purpose Fulfillment Ensured**: Framework purpose fully achievable with generated requirements

### Final Validation Protocol
```bash
execute_final_validation() {
    
    # Validate complete generation
    assert all_provisioner_requirements_exist()
    assert all_worker_requirements_exist_for_each_area()
    assert all_stabilizer_requirements_exist()
    
    # Validate coverage
    assert all_analysis_findings_covered()
    assert all_framework_purpose_needs_addressed()
    
    # Validate execution readiness
    assert dependency_chains_complete()
    assert worker_assignments_clear()
    assert execution_phases_defined()
    
    return DISPATCHER_VALIDATION_COMPLETE
}
```

## Comprehensive Requirements Dispatcher Summary

**Complete Framework Requirements Generation System**

### Framework Purpose Discovery → Worker Allocation → Requirements Generation

**Deep Code Analysis Approach:**
1. **Comprehensive Code Content Reading**: Read ALL source files, APIs, dependencies, patterns, and configurations
2. **Framework Purpose Discovery from Code**: Analyze what the code actually does, not just file structure
3. **Implementation-Based Responsibility Areas**: Extract areas based on actual code clustering and API boundaries
4. **Code-Driven Worker Optimization**: Calculate optimal workers (3-9) based on code complexity and separable implementations
5. **Complete Requirements Generation from Code**: Generate ALL requirements based on actual code analysis evidence
6. **Zero-Gap Code Validation**: Ensure every code analysis finding is addressed by requirements

**Comprehensive Generation Protocol:**
- **PROVISIONER**: ALL foundational infrastructure requirements (5+ requirements)
- **WORKER-01 through WORKER-07**: ALL responsibility area requirements (varies by area)
- **STABILIZER**: ALL integration and validation requirements (5+ requirements)

**Critical Dispatcher Features:**
- **Zero Missing Requirements**: Automated validation ensures complete coverage
- **Purpose-Driven Allocation**: Workers assigned based on actual framework needs
- **Load Balancing**: Workload distributed across workers optimally
- **Dependency Validation**: Clear PROVISIONER → WORKERS → STABILIZER flow
- **Execution Readiness**: All requirements generated with clear worker assignments

## Dispatcher Validation Protocol

**MANDATORY THREE-INPUT EXECUTION VALIDATION:**

```bash
# Input Validation
validate_inputs(workspace_folder, codebase_folder, dispatcher_template) {
    assert workspace_folder exists and is writable
    assert codebase_folder exists and contains framework code
    assert dispatcher_template exists and is this template
}

# Phase 1: Codebase Analysis (Read-Only from codebase_folder)
validate_framework_purpose_discovery(codebase_folder)
validate_responsibility_area_mapping(codebase_folder) 
validate_worker_count_optimization(codebase_folder)

# Phase 2: Workspace Generation (Write to workspace_folder)
create_workspace_structure(workspace_folder)
execute_provisioner_requirements_generation(workspace_folder, codebase_folder)
execute_all_worker_requirements_generation(workspace_folder, codebase_folder)
execute_stabilizer_requirements_generation(workspace_folder, codebase_folder)

# Phase 3: Workspace Validation (Validate workspace_folder output)
validate_workspace_structure_complete(workspace_folder)
validate_zero_missing_requirements(workspace_folder)
validate_complete_coverage_matrix(workspace_folder, codebase_folder)
validate_dependency_chain_integrity(workspace_folder)
validate_worker_load_balancing(workspace_folder)

# Final Confirmation
assert WORKSPACE_GENERATION_COMPLETE(workspace_folder)
assert ALL_WORKERS_HAVE_FOLDERS_AND_REQUIREMENTS(workspace_folder)
assert ZERO_ANALYSIS_GAPS(workspace_folder, codebase_folder)
assert FRAMEWORK_PURPOSE_ACHIEVABLE(workspace_folder, codebase_folder)
```

**SUCCESS CRITERIA:**
- [ ] **INPUT VALIDATION**: All three inputs (workspace folder, codebase folder, dispatcher template) validated
- [ ] **CODEBASE ANALYSIS**: Framework purpose clearly identified from codebase_folder exploration
- [ ] **RESPONSIBILITY MAPPING**: Responsibility areas mapped with natural boundaries from codebase_folder
- [ ] **WORKER OPTIMIZATION**: Worker count optimized (3-9) based on separable areas discovered in codebase_folder
- [ ] **WORKSPACE STRUCTURE**: Complete worker folder structure created in workspace_folder
- [ ] **PROVISIONER GENERATION**: ALL foundational requirements generated in workspace_folder/PROVISIONER/
- [ ] **WORKER GENERATION**: ALL responsibility area requirements generated in workspace_folder/WORKER-XX/
- [ ] **STABILIZER GENERATION**: ALL integration requirements generated in workspace_folder/STABILIZER/
- [ ] **DOCUMENTATION GENERATION**: Framework analysis documentation generated in workspace_folder/DOCUMENTATION/
- [ ] **ZERO GAPS**: Every codebase analysis finding addressed in workspace requirements
- [ ] **DEPENDENCY VALIDATION**: Clear execution flow validated across workspace structure
- [ ] **EXECUTION READINESS**: Complete workspace ready for parallel worker execution

**EXPLICITLY EXCLUDED FROM REQUIREMENTS GENERATION (MVP FOCUS):**
This requirements generation deliberately excludes all MVP-incompatible concerns:
- Version control integration requirements (focus on current codebase state)
- Database versioning and migration requirements (work with current schema)
- Deprecation management requirements (we fix problems, don't deprecate)
- Legacy code preservation requirements (transform code, don't preserve)
- Backward compatibility requirements (no compatibility constraints)
- Breaking change mitigation requirements (breaking changes welcomed)
- Semantic versioning requirements (MVP operates on current iteration)
- API stability preservation requirements (APIs evolve for MVP optimization)
- Configuration migration requirements (use current configuration)
- Deployment versioning requirements (deploy current state)
- Release management requirements (continuous MVP iteration)
- Rollback procedure requirements (no rollback concerns for MVP)
- Multi-version support requirements (single current version)

**CRITICAL DEEP CODE ANALYSIS DISPATCHER GUARANTEE:**

**INPUT**: workspace_folder + codebase_folder + dispatcher_template  
**PROCESS**: Deep code content analysis → Purpose discovery from code → Generate ALL requirements from code evidence  
**OUTPUT**: Complete workspace with ALL worker folders and requirements based on actual code analysis  

This system ensures:
- **DEEP CODE READING** - ALL source files, APIs, dependencies, patterns analyzed from content
- **PURPOSE FROM CODE** - Framework purpose discovered from what code actually does, not file structure
- **CODE-BASED REQUIREMENTS** - ALL requirements generated from actual code analysis evidence
- **NO STRUCTURAL ASSUMPTIONS** - Worker allocation based on actual code complexity and API boundaries
- **NO missing requirements** - Complete coverage validated against code analysis findings
- **NO empty worker folders** - Every worker gets full requirements based on actual responsibility areas
- **NO superficial analysis** - Every finding rooted in actual code content, not naming conventions
- **WORKSPACE READY** - Immediate parallel worker execution with code-backed requirements
- **NO VERSION CONCERNS** - All requirements focus on current MVP state optimization
