//! Axiom Applications Observability MCP
//! 
//! A comprehensive Model Context Protocol implementation for iOS development intelligence.
//! Provides code generation, performance monitoring, visual analysis, and complete development loop automation.

pub mod mcp;
pub mod tools;
pub mod types;
pub mod error;
pub mod code_generation;
pub mod complete_development_loop;
pub mod hot_reload;
pub mod intelligence;
pub mod simulator;
pub mod screenshot_matrix_engine;
pub mod advanced_visual_intelligence;
pub mod performance_analysis_integration;
pub mod development_workflow;
pub mod axiom_framework_integration;

// Re-export main types for convenience
pub use mcp::{AxiomApplicationsObservabilityMCP, MCPConfiguration, MCPCapabilities};
pub use tools::{AxiomMCPTool, ToolResult};
pub use error::{AxiomMCPError, Result};
pub use types::*;

/// Initialize the Axiom Applications Observability MCP system
pub async fn init_mcp(config: MCPConfiguration, capabilities: MCPCapabilities) -> Result<AxiomApplicationsObservabilityMCP> {
    tracing::info!("Initializing Axiom Applications Observability MCP");
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    tracing::info!("✅ Axiom Applications Observability MCP initialized successfully");
    Ok(mcp)
}

/// Version information
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
pub const NAME: &str = env!("CARGO_PKG_NAME");

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_mcp_initialization() {
        let config = MCPConfiguration {
            hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
            intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
            simulator_management_enabled: true,
            code_generation_enabled: true,
            visual_analysis_enabled: true,
            performance_monitoring_enabled: true,
        };
        
        let capabilities = MCPCapabilities {
            code_generation: true,
            intelligence_analysis: true,
            hot_reload_integration: true,
            visual_analysis: true,
            simulator_management: true,
            performance_monitoring: true,
        };
        
        let result = init_mcp(config, capabilities).await;
        assert!(result.is_ok(), "MCP initialization should succeed");
    }
}