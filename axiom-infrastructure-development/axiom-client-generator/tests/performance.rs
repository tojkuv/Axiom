//! Performance tests for the Axiom Swift Client Generator

use axiom_universal_client_generator::generators::swift::SwiftGenerator;
use axiom_universal_client_generator::proto::parser::ProtoParser;
use std::time::Instant;
use tempfile::TempDir;

#[tokio::test]
async fn test_generation_performance() {
    let temp_dir = TempDir::new().unwrap();
    let proto_content = r#"
syntax = "proto3";

package test.v1;

service TestService {
    rpc GetItems(GetItemsRequest) returns (GetItemsResponse);
}

message GetItemsRequest {
    string query = 1;
}

message GetItemsResponse {
    repeated Item items = 1;
}

message Item {
    string id = 1;
    string name = 2;
    string description = 3;
}
"#;

    let proto_file = temp_dir.path().join("test.proto");
    std::fs::write(&proto_file, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let schema = parser.parse_proto_file(&proto_file).await.unwrap();

    let generator = SwiftGenerator::new().await.unwrap();
    
    let start = Instant::now();
    let _result = generator.generate_all(&schema, temp_dir.path().to_path_buf(), None).await;
    let duration = start.elapsed();

    // Generation should complete within reasonable time
    assert!(duration.as_secs() < 10, "Generation took too long: {:?}", duration);
}

#[tokio::test]
async fn test_large_schema_performance() {
    let temp_dir = TempDir::new().unwrap();
    
    // Generate a large proto file with many services and messages
    let mut proto_content = String::from("syntax = \"proto3\";\npackage large.v1;\n\n");
    
    for i in 0..10 {
        proto_content.push_str(&format!(
            "service Service{} {{\n    rpc GetItems(GetItemsRequest{}) returns (GetItemsResponse{});\n}}\n\n",
            i, i, i
        ));
        
        proto_content.push_str(&format!(
            "message GetItemsRequest{} {{\n    string query = 1;\n    int32 limit = 2;\n}}\n\n", i
        ));
        
        proto_content.push_str(&format!(
            "message GetItemsResponse{} {{\n    repeated Item{} items = 1;\n}}\n\n", i, i
        ));
        
        proto_content.push_str(&format!(
            "message Item{} {{\n    string id = 1;\n    string name = 2;\n    string description = 3;\n    int64 timestamp = 4;\n}}\n\n", i
        ));
    }

    let proto_file = temp_dir.path().join("large.proto");
    std::fs::write(&proto_file, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let schema = parser.parse_proto_file(&proto_file).await.unwrap();

    let generator = SwiftGenerator::new().await.unwrap();
    
    let start = Instant::now();
    let result = generator.generate_all(&schema, temp_dir.path().to_path_buf(), None).await;
    let duration = start.elapsed();

    assert!(result.is_ok(), "Large schema generation failed");
    
    // Even large schemas should complete within reasonable time
    assert!(duration.as_secs() < 30, "Large schema generation took too long: {:?}", duration);
}