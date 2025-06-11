# CODEBASE-ANALYSIS-ACTOR-PROTOCOL

Post-development comprehensive codebase analysis protocol for technical assessment, competitive positioning, and maturity evaluation. Operates after provisioning and parallel development completion, analyzing both the final codebase state and development artifacts to provide comprehensive technical insights based on actual development work performed.

## Protocol Activation

```
@CODEBASE_ANALYSIS_ACTOR execute <codebase_directory> <provisioner_directory> <workers_directory> <stabilizer_directory> <analysis_template>
```

**Parameters:**
- `<codebase_directory>`: Path to directory containing developed source code
- `<provisioner_directory>`: Path to directory containing provisioner session artifacts
- `<workers_directory>`: Path to directory containing all worker directories with their session artifacts
- `<stabilizer_directory>`: Path to directory containing stabilizer session artifacts
- `<analysis_template>`: Path to the analysis actor template for structuring assessment

**Prerequisites:**
- Provisioner development must be completed with session artifacts
- All parallel worker development must be completed with session artifacts
- Stabilizer integration must be completed with session artifacts
- Codebase must be in final stabilized state

## Command

### Execute - Post-Development Codebase Analysis

The execute command performs comprehensive technical analysis of the completed codebase by integrating both the final code state and the complete development history captured in session artifacts from provisioner, workers, and stabilizer.

**Analysis Integration Approach:**
- Reads developed codebase from: `<codebase_directory>/`
- Reads provisioner decisions from: `<provisioner_directory>/CB-PROVISIONER-SESSION-*.md`
- Reads worker implementations from: `<workers_directory>/*/CB-SESSION-*.md`
- Reads stabilizer integration from: `<stabilizer_directory>/CB-STABILIZER-SESSION-*.md`
- Generates analysis in: `<stabilizer_directory>/CODEBASE-ANALYSIS-*.md`

**Development-Informed Analysis Philosophy:**
- Analyzes final codebase state informed by development journey
- Incorporates actual implementation decisions from session artifacts
- Evaluates technical foundations established through real development work
- Assesses competitive positioning based on delivered capabilities
- Reviews maturity achieved through actual development process
- Identifies improvement opportunities based on development insights

```bash
@CODEBASE_ANALYSIS_ACTOR execute \
  /path/to/developed-codebase \
  /path/to/provisioner-directory \
  /path/to/workers-directory \
  /path/to/stabilizer-directory \
  /path/to/codebase-analysis-actor-template.md
```

## Analysis Integration Process

### Phase 1: Development Artifact Analysis

**Provisioner Foundation Review:**
```bash
analyze_provisioner_foundation(provisioner_directory) {
    PROVISIONER_SESSIONS = find_all_files("${provisioner_directory}/CB-PROVISIONER-SESSION-*.md")
    
    for session in PROVISIONER_SESSIONS:
        SESSION_CONTENT = read_file_content(session)
        FOUNDATION_DECISIONS[session] = extract_architectural_decisions(SESSION_CONTENT)
        INFRASTRUCTURE_ESTABLISHED[session] = extract_infrastructure_work(SESSION_CONTENT)
        PATTERNS_DEFINED[session] = extract_foundational_patterns(SESSION_CONTENT)
        QUALITY_BASELINES[session] = extract_quality_metrics(SESSION_CONTENT)
    done
    
    PROVISIONER_IMPACT = synthesize_foundational_impact(
        FOUNDATION_DECISIONS, INFRASTRUCTURE_ESTABLISHED, PATTERNS_DEFINED
    )
}
```

**Parallel Worker Development Review:**
```bash
analyze_worker_development(workers_directory) {
    WORKER_DIRECTORIES = find_worker_directories(workers_directory)
    
    for worker_dir in WORKER_DIRECTORIES:
        WORKER_SESSIONS = find_all_files("${worker_dir}/CB-SESSION-*.md")
        
        for session in WORKER_SESSIONS:
            SESSION_CONTENT = read_file_content(session)
            FEATURES_IMPLEMENTED[worker_dir][session] = extract_feature_work(SESSION_CONTENT)
            API_CHANGES[worker_dir][session] = extract_api_developments(SESSION_CONTENT)
            TECHNICAL_DECISIONS[worker_dir][session] = extract_technical_choices(SESSION_CONTENT)
            INTEGRATION_POINTS[worker_dir][session] = extract_integration_documentation(SESSION_CONTENT)
        done
    done
    
    PARALLEL_WORK_IMPACT = synthesize_parallel_development_impact(
        FEATURES_IMPLEMENTED, API_CHANGES, TECHNICAL_DECISIONS, INTEGRATION_POINTS
    )
}
```

**Stabilizer Integration Review:**
```bash
analyze_stabilizer_integration(stabilizer_directory) {
    STABILIZER_SESSIONS = find_all_files("${stabilizer_directory}/CB-STABILIZER-SESSION-*.md")
    
    for session in STABILIZER_SESSIONS:
        SESSION_CONTENT = read_file_content(session)
        INTEGRATION_RESOLUTIONS[session] = extract_conflict_resolutions(SESSION_CONTENT)
        API_STABILIZATION[session] = extract_api_stabilization_work(SESSION_CONTENT)
        PERFORMANCE_OPTIMIZATION[session] = extract_performance_improvements(SESSION_CONTENT)
        APPLICATION_READINESS[session] = extract_readiness_validation(SESSION_CONTENT)
    done
    
    STABILIZATION_IMPACT = synthesize_stabilization_impact(
        INTEGRATION_RESOLUTIONS, API_STABILIZATION, PERFORMANCE_OPTIMIZATION
    )
}
```

### Phase 2: Final Codebase State Analysis

**Comprehensive Code Content Analysis:**
```bash
analyze_final_codebase_state(codebase_directory) {
    SOURCE_FILES = find_all_source_files(codebase_directory)
    CONFIG_FILES = find_configuration_files(codebase_directory)
    TEST_FILES = find_test_files(codebase_directory)
    BUILD_FILES = find_build_files(codebase_directory)
    
    for file in ALL_FILES:
        CONTENT[file] = read_file_content(file)
        APIS[file] = extract_public_apis(CONTENT[file])
        DEPENDENCIES[file] = extract_dependencies(CONTENT[file])
        PATTERNS[file] = identify_code_patterns(CONTENT[file])
        COMPLEXITY[file] = calculate_complexity_metrics(CONTENT[file])
    done
    
    FINAL_CODEBASE_ASSESSMENT = synthesize_codebase_state(
        CONTENT, APIS, DEPENDENCIES, PATTERNS, COMPLEXITY
    )
}
```

### Phase 3: Development-Informed Technical Assessment

**Integrated Foundation Analysis:**
```bash
assess_technical_foundations_with_development_context(
    FINAL_CODEBASE_ASSESSMENT, PROVISIONER_IMPACT, PARALLEL_WORK_IMPACT, STABILIZATION_IMPACT
) {
    # Analyze how provisioner decisions shaped final architecture
    ARCHITECTURE_EVOLUTION = trace_architectural_evolution(
        PROVISIONER_IMPACT.foundation_decisions, FINAL_CODEBASE_ASSESSMENT.architecture
    )
    
    # Assess how parallel work contributed to final capabilities
    CAPABILITY_DEVELOPMENT = assess_capability_implementation(
        PARALLEL_WORK_IMPACT.features_implemented, FINAL_CODEBASE_ASSESSMENT.capabilities
    )
    
    # Evaluate how stabilization affected final technical quality
    QUALITY_ACHIEVEMENT = evaluate_quality_progression(
        STABILIZATION_IMPACT.performance_optimization, FINAL_CODEBASE_ASSESSMENT.quality
    )
    
    TECHNICAL_FOUNDATIONS = synthesize_development_informed_assessment(
        ARCHITECTURE_EVOLUTION, CAPABILITY_DEVELOPMENT, QUALITY_ACHIEVEMENT
    )
}
```

### Phase 4: Development-Context Competitive Analysis

**Competitive Positioning with Development Insights:**
```bash
analyze_competitive_position_with_development_context(
    FINAL_CODEBASE_ASSESSMENT, DEVELOPMENT_JOURNEY
) {
    COMPETITORS = identify_primary_competitors(FINAL_CODEBASE_ASSESSMENT.codebase_type)
    
    for competitor in COMPETITORS:
        COMPETITIVE_COMPARISON[competitor] = compare_with_development_context(
            competitor,
            FINAL_CODEBASE_ASSESSMENT.capabilities,
            DEVELOPMENT_JOURNEY.implementation_approaches,
            DEVELOPMENT_JOURNEY.technical_decisions
        )
    done
    
    COMPETITIVE_ADVANTAGES = identify_development_driven_advantages(
        COMPETITIVE_COMPARISON, DEVELOPMENT_JOURNEY.unique_solutions
    )
}
```

### Phase 5: Development-Informed Maturity Assessment

**Maturity Evaluation with Development Process Context:**
```bash
assess_maturity_with_development_context(
    FINAL_CODEBASE_ASSESSMENT, DEVELOPMENT_JOURNEY
) {
    MATURITY_STANDARDS = define_maturity_standards_for_codebase_type(
        FINAL_CODEBASE_ASSESSMENT.codebase_type
    )
    
    CURRENT_MATURITY = evaluate_current_maturity_state(
        FINAL_CODEBASE_ASSESSMENT,
        DEVELOPMENT_JOURNEY.quality_progression,
        DEVELOPMENT_JOURNEY.pattern_establishment
    )
    
    MATURITY_GAPS = identify_maturity_gaps_with_development_insights(
        CURRENT_MATURITY, MATURITY_STANDARDS, DEVELOPMENT_JOURNEY.missed_opportunities
    )
    
    MATURITY_ROADMAP = create_development_informed_advancement_path(
        MATURITY_GAPS, DEVELOPMENT_JOURNEY.successful_patterns
    )
}
```

## Analysis Artifact Generation

### Comprehensive Analysis Document Creation

```bash
generate_comprehensive_analysis(stabilizer_directory, analysis_template) {
    # Create analysis artifact in stabilizer directory
    timestamp = generate_timestamp() # YYYYMMDD-HHMMSS
    analysis_id = "COMPREHENSIVE-${timestamp}"
    
    # Create comprehensive analysis artifact
    artifact_file = "${stabilizer_directory}/CODEBASE-ANALYSIS-${analysis_id}.md"
    
    populate_analysis_template(
        analysis_template, 
        artifact_file, 
        COMPREHENSIVE_ANALYSIS_RESULTS,
        DEVELOPMENT_JOURNEY_INSIGHTS
    )
}
```

### Development Journey Integration

**Session Artifact Processing:**
```bash
synthesize_development_journey(
    PROVISIONER_IMPACT, PARALLEL_WORK_IMPACT, STABILIZATION_IMPACT
) {
    DEVELOPMENT_TIMELINE = create_development_timeline(
        PROVISIONER_IMPACT.foundational_milestones,
        PARALLEL_WORK_IMPACT.feature_milestones,
        STABILIZATION_IMPACT.integration_milestones
    )
    
    TECHNICAL_DECISION_CHAIN = trace_technical_decision_evolution(
        PROVISIONER_IMPACT.foundation_decisions,
        PARALLEL_WORK_IMPACT.implementation_decisions,
        STABILIZATION_IMPACT.integration_decisions
    )
    
    QUALITY_PROGRESSION = analyze_quality_evolution(
        PROVISIONER_IMPACT.quality_baselines,
        PARALLEL_WORK_IMPACT.quality_improvements,
        STABILIZATION_IMPACT.quality_achievements
    )
    
    DEVELOPMENT_JOURNEY = {
        timeline: DEVELOPMENT_TIMELINE,
        decisions: TECHNICAL_DECISION_CHAIN,
        quality: QUALITY_PROGRESSION
    }
}
```

## Analysis Scope and Focus

### Development-Informed Technical Assessment

**Core Analysis Areas:**
- **Final Codebase Architecture**: Assessment of delivered architecture informed by development decisions
- **Implemented Capabilities**: Evaluation of features and functionality actually delivered
- **Technical Quality Achievement**: Analysis of quality standards achieved through development process
- **Integration Success**: Assessment of how parallel work was successfully integrated
- **Performance Characteristics**: Evaluation of performance achieved through optimization work
- **Application Readiness**: Assessment of final application-ready state

**Development Context Integration:**
- **Foundation Impact**: How provisioner decisions shaped final architecture
- **Parallel Development Success**: How worker isolation and integration affected quality
- **Stabilization Effectiveness**: How stabilizer work improved final codebase quality
- **Technical Decision Quality**: Assessment of technical choices made during development
- **Process Effectiveness**: Evaluation of development approach success

### Competitive Analysis with Development Insights

**Development-Driven Competitive Assessment:**
- **Implementation Approach Advantages**: How development approach creates competitive advantages
- **Technical Solution Uniqueness**: Unique technical solutions developed during parallel work
- **Integration Architecture Benefits**: Competitive advantages from successful parallel integration
- **Quality Achievement Superiority**: Quality standards achieved vs competitors
- **Development Velocity Benefits**: Speed and quality advantages from development approach

### Maturity Assessment with Development Context

**Development-Informed Maturity Evaluation:**
- **Achieved Maturity Level**: Current maturity based on delivered capabilities
- **Development Process Maturity**: Maturity of development approach and outcomes
- **Quality Standards Achievement**: Quality standards reached through development
- **Pattern Establishment Success**: Success in establishing consistent patterns
- **Technical Debt Management**: Effectiveness of technical debt prevention and resolution

## Success Criteria

### Comprehensive Analysis Completeness
- [ ] Final codebase state thoroughly analyzed
- [ ] Development journey completely integrated into analysis
- [ ] Provisioner foundation impact assessed
- [ ] All parallel worker contributions evaluated
- [ ] Stabilizer integration success analyzed
- [ ] Technical foundations assessed with development context

### Development-Context Integration
- [ ] All session artifacts processed and integrated
- [ ] Development decisions traced and evaluated
- [ ] Quality progression analyzed throughout development
- [ ] Technical choice effectiveness assessed
- [ ] Integration success comprehensively evaluated

### Evidence-Based Assessment
- [ ] All findings supported by code analysis and development artifacts
- [ ] Competitive comparisons grounded in delivered capabilities
- [ ] Maturity assessment based on achieved development outcomes
- [ ] Improvement opportunities informed by development insights

## Protocol Guarantees

**Comprehensive Development-Informed Assessment:**
- Complete integration of final codebase state with development journey insights
- Technical foundation evaluation informed by actual development decisions
- Competitive positioning based on delivered capabilities and development approach
- Maturity assessment grounded in achieved development outcomes

**Development Journey Integration:**
- Complete processing of all provisioner, worker, and stabilizer session artifacts
- Technical decision traceability from foundation through final integration
- Quality progression analysis throughout entire development process
- Development approach effectiveness evaluation

**Evidence-Based Analysis:**
- All conclusions supported by combination of code analysis and development artifacts
- Technical assessments grounded in actual implementation and development work
- Competitive advantages identified through development-informed analysis
- Strategic recommendations based on proven development capabilities

**Clean Artifact Management:**
- Analysis artifact generated in stabilizer directory with development context
- Complete development journey documentation integrated into analysis
- No interference with existing development artifacts or source code
- Ready for consumption by downstream processes requiring comprehensive analysis

## EXPLICITLY EXCLUDED FROM ANALYSIS (MVP FOCUS)

This analysis deliberately excludes all MVP-incompatible concerns:
- Version control strategies and migration approaches (focus on current developed state)
- Database versioning and schema migration analysis (work with current delivered schema)
- Deprecation management (development fixed problems, didn't deprecate)
- Legacy code preservation (development transformed code, didn't preserve obsolete patterns)
- Backward compatibility analysis (development used breaking changes for MVP clarity)
- Semantic versioning considerations (MVP operates on current iteration)
- API stability preservation (APIs evolved for MVP optimization during development)
- Configuration migration strategies (use current delivered configuration)
- Deployment versioning (deploy current developed state)
- Release management (continuous MVP iteration approach used)
- Rollback procedures (no rollback concerns for MVP)