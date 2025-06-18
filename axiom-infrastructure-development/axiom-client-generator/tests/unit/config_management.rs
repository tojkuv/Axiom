//! Unit tests for configuration management

use axiom_universal_client_generator::utils::config::*;
use axiom_universal_client_generator::GenerationOptions;
use std::collections::HashMap;
use tempfile::TempDir;
use serde_json;

#[test]
fn test_default_swift_config() {
    let config = SwiftGenerationConfig::default();
    
    assert_eq!(config.axiom_version, "latest");
    assert_eq!(config.client_suffix, "Client");
    assert!(config.generate_tests);
    assert!(config.generate_contracts);
    assert!(config.generate_clients);
    assert!(!config.force_overwrite);
    assert!(config.include_documentation);
    assert_eq!(config.style_guide, StyleGuide::Axiom);
    assert_eq!(config.module_imports, vec!["AxiomCore", "AxiomArchitecture"]);
}

#[test]
fn test_swift_config_from_json() {
    let json_config = r#"
    {
        "axiom_version": "1.0.0",
        "client_suffix": "Manager",
        "generate_tests": false,
        "package_name": "CustomPackage",
        "module_imports": ["Foundation", "Combine"],
        "style_guide": "swift-standard"
    }
    "#;
    
    let config: SwiftGenerationConfig = serde_json::from_str(json_config).unwrap();
    
    assert_eq!(config.axiom_version, "1.0.0");
    assert_eq!(config.client_suffix, "Manager");
    assert!(!config.generate_tests);
    assert_eq!(config.package_name, Some("CustomPackage".to_string()));
    assert_eq!(config.module_imports, vec!["Foundation", "Combine"]);
    assert_eq!(config.style_guide, StyleGuide::SwiftStandard);
}

#[test]
fn test_generation_options() {
    let mut options = GenerationOptions::default();
    
    assert_eq!(options.generate_contracts, Some(true));
    assert_eq!(options.generate_clients, Some(true));
    assert_eq!(options.generate_tests, Some(true));
    assert_eq!(options.force_overwrite, Some(false));
    assert_eq!(options.include_documentation, Some(true));
    
    // Test modification
    options.generate_tests = Some(false);
    options.force_overwrite = Some(true);
    
    assert_eq!(options.generate_tests, Some(false));
    assert_eq!(options.force_overwrite, Some(true));
}

#[test]
fn test_validation_config() {
    let config = ValidationConfig {
        max_file_size: 1024 * 1024,
        max_lines_per_file: 10000,
        validate_syntax: true,
        validate_imports: true,
        validate_compilation: true,
        swift_version: Some("5.9".to_string()),
        additional_flags: vec!["--enable-testing".to_string()],
        forbidden_patterns: vec!["TODO".to_string()],
    };
    
    assert!(config.validate_syntax);
    assert!(config.validate_compilation);
    assert_eq!(config.swift_version, Some("5.9".to_string()));
    assert_eq!(config.additional_flags, vec!["--enable-testing"]);
}

#[test]
fn test_output_config() {
    let config = OutputConfig {
        base_path: "/tmp/generated".to_string(),
        sources_dir: "Sources".to_string(),
        tests_dir: "Tests".to_string(),
        create_package_swift: true,
        organize_by_service: true,
    };
    
    assert_eq!(config.base_path, "/tmp/generated");
    assert_eq!(config.sources_dir, "Sources");
    assert_eq!(config.tests_dir, "Tests");
    assert!(config.create_package_swift);
    assert!(config.organize_by_service);
}

#[test]
fn test_complete_config_structure() {
    let config = AxiomGeneratorConfig {
        swift: SwiftGenerationConfig::default(),
        generation: GenerationOptions::default(),
        validation: ValidationConfig::default(),
        output: OutputConfig::default(),
        proto_paths: vec!["/path/to/protos".to_string()],
        services: None,
    };
    
    assert_eq!(config.proto_paths, vec!["/path/to/protos"]);
    assert!(config.services.is_none());
}

#[test]
fn test_config_validation() {
    let valid_config = SwiftGenerationConfig {
        axiom_version: "1.0.0".to_string(),
        client_suffix: "Client".to_string(),
        package_name: Some("ValidPackage".to_string()),
        ..Default::default()
    };
    
    assert!(valid_config.validate().is_ok());
    
    // Test invalid package name
    let invalid_config = SwiftGenerationConfig {
        package_name: Some("123InvalidPackage".to_string()),
        ..Default::default()
    };
    
    assert!(invalid_config.validate().is_err());
    
    // Test empty client suffix
    let invalid_suffix_config = SwiftGenerationConfig {
        client_suffix: "".to_string(),
        ..Default::default()
    };
    
    assert!(invalid_suffix_config.validate().is_err());
}

#[test]
fn test_config_file_loading() {
    let temp_dir = TempDir::new().unwrap();
    let config_path = temp_dir.path().join("axiom-config.json");
    
    let config_content = r#"
    {
        "swift": {
            "axiom_version": "2.0.0",
            "client_suffix": "Actor",
            "generate_tests": true,
            "package_name": "TestPackage"
        },
        "generation": {
            "generate_contracts": true,
            "generate_clients": true,
            "force_overwrite": false,
            "include_documentation": true
        },
        "output": {
            "base_path": "./Generated",
            "sources_dir": "Sources",
            "tests_dir": "Tests"
        },
        "proto_paths": ["./proto/services/"]
    }
    "#;
    
    std::fs::write(&config_path, config_content).unwrap();
    
    let loaded_config = AxiomGeneratorConfig::load_from_file(&config_path).unwrap();
    
    assert_eq!(loaded_config.swift.axiom_version, "2.0.0");
    assert_eq!(loaded_config.swift.client_suffix, "Actor");
    assert_eq!(loaded_config.swift.package_name, Some("TestPackage".to_string()));
    assert_eq!(loaded_config.output.base_path, "./Generated");
    assert_eq!(loaded_config.proto_paths, vec!["./proto/services/"]);
}

#[test]
fn test_config_merging() {
    let base_config = SwiftGenerationConfig {
        axiom_version: "1.0.0".to_string(),
        client_suffix: "Client".to_string(),
        generate_tests: true,
        package_name: Some("BasePackage".to_string()),
        ..Default::default()
    };
    
    let override_config = SwiftGenerationConfig {
        axiom_version: "2.0.0".to_string(),
        generate_tests: false,
        package_name: Some("OverridePackage".to_string()),
        ..Default::default()
    };
    
    let merged = base_config.merge_with(&override_config);
    
    assert_eq!(merged.axiom_version, "2.0.0"); // Overridden
    assert_eq!(merged.client_suffix, "Client"); // From base (not overridden)
    assert!(!merged.generate_tests); // Overridden
    assert_eq!(merged.package_name, Some("OverridePackage".to_string())); // Overridden
}

#[test]
fn test_environment_variable_config() {
    std::env::set_var("AXIOM_VERSION", "env-1.0.0");
    std::env::set_var("AXIOM_CLIENT_SUFFIX", "EnvClient");
    std::env::set_var("AXIOM_GENERATE_TESTS", "false");
    
    let config = SwiftGenerationConfig::from_environment();
    
    assert_eq!(config.axiom_version, "env-1.0.0");
    assert_eq!(config.client_suffix, "EnvClient");
    assert!(!config.generate_tests);
    
    // Cleanup
    std::env::remove_var("AXIOM_VERSION");
    std::env::remove_var("AXIOM_CLIENT_SUFFIX");
    std::env::remove_var("AXIOM_GENERATE_TESTS");
}

#[test]
fn test_config_override_precedence() {
    // Environment variables should override file config
    std::env::set_var("AXIOM_VERSION", "env-override");
    
    let file_config = SwiftGenerationConfig {
        axiom_version: "file-version".to_string(),
        ..Default::default()
    };
    
    let final_config = file_config.apply_environment_overrides();
    
    assert_eq!(final_config.axiom_version, "env-override");
    
    std::env::remove_var("AXIOM_VERSION");
}

#[test]
fn test_style_guide_enum() {
    assert_eq!(StyleGuide::from_string("axiom"), StyleGuide::Axiom);
    assert_eq!(StyleGuide::from_string("swift-standard"), StyleGuide::SwiftStandard);
    assert_eq!(StyleGuide::from_string("custom"), StyleGuide::Custom);
    assert_eq!(StyleGuide::from_string("unknown"), StyleGuide::Axiom); // Default fallback
    
    assert_eq!(StyleGuide::Axiom.to_string(), "axiom");
    assert_eq!(StyleGuide::SwiftStandard.to_string(), "swift-standard");
    assert_eq!(StyleGuide::Custom.to_string(), "custom");
}

#[test]
fn test_template_config() {
    let config = TemplateConfig {
        custom_template_path: Some("/custom/templates".to_string()),
        enable_custom_filters: true,
        template_cache_size: 100,
        additional_context: {
            let mut context = HashMap::new();
            context.insert("custom_var".to_string(), "custom_value".to_string());
            context
        },
    };
    
    assert_eq!(config.custom_template_path, Some("/custom/templates".to_string()));
    assert!(config.enable_custom_filters);
    assert_eq!(config.template_cache_size, 100);
    assert_eq!(config.additional_context.get("custom_var"), Some(&"custom_value".to_string()));
}

#[test]
fn test_proto_config() {
    let config = ProtoConfig {
        include_paths: vec!["/usr/include".to_string(), "./proto".to_string()],
        import_paths: vec!["./proto/common".to_string()],
        file_descriptor_set_path: Some("./proto/descriptors.pb".to_string()),
        preserve_proto_names: false,
        enable_custom_options: true,
    };
    
    assert_eq!(config.include_paths, vec!["/usr/include", "./proto"]);
    assert_eq!(config.import_paths, vec!["./proto/common"]);
    assert_eq!(config.file_descriptor_set_path, Some("./proto/descriptors.pb".to_string()));
    assert!(!config.preserve_proto_names);
    assert!(config.enable_custom_options);
}

#[test]
fn test_mcp_tool_config() {
    let config = McpToolConfig {
        tool_name: "axiom_swift_generator".to_string(),
        description: "Generates Swift clients for Axiom".to_string(),
        timeout_seconds: 300,
        max_concurrent_requests: 5,
        enable_progress_reporting: true,
    };
    
    assert_eq!(config.tool_name, "axiom_swift_generator");
    assert_eq!(config.description, "Generates Swift clients for Axiom");
    assert_eq!(config.timeout_seconds, 300);
    assert_eq!(config.max_concurrent_requests, 5);
    assert!(config.enable_progress_reporting);
}

#[test]
fn test_config_serialization() {
    let config = SwiftGenerationConfig {
        axiom_version: "1.0.0".to_string(),
        client_suffix: "Manager".to_string(),
        generate_tests: false,
        generate_contracts: true,
        generate_clients: true,
        force_overwrite: false,
        include_documentation: true,
        package_name: Some("TestPackage".to_string()),
        module_imports: vec!["Foundation".to_string(), "Combine".to_string()],
        style_guide: StyleGuide::SwiftStandard,
    };
    
    // Test JSON serialization
    let json = serde_json::to_string(&config).unwrap();
    let deserialized: SwiftGenerationConfig = serde_json::from_str(&json).unwrap();
    
    assert_eq!(config.axiom_version, deserialized.axiom_version);
    assert_eq!(config.client_suffix, deserialized.client_suffix);
    assert_eq!(config.generate_tests, deserialized.generate_tests);
    assert_eq!(config.package_name, deserialized.package_name);
    assert_eq!(config.module_imports, deserialized.module_imports);
    assert_eq!(config.style_guide, deserialized.style_guide);
}

#[test]
fn test_config_error_handling() {
    // Test loading non-existent file
    let result = AxiomGeneratorConfig::load_from_file("non-existent-file.json");
    assert!(result.is_err());
    
    // Test loading invalid JSON
    let temp_dir = TempDir::new().unwrap();
    let invalid_config_path = temp_dir.path().join("invalid.json");
    std::fs::write(&invalid_config_path, "invalid json content").unwrap();
    
    let result = AxiomGeneratorConfig::load_from_file(&invalid_config_path);
    assert!(result.is_err());
}