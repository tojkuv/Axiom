use thiserror::Error;

/// Result type for Axiom MCP operations
pub type Result<T> = std::result::Result<T, AxiomMCPError>;

/// Comprehensive error types for the Axiom Applications Observability MCP
#[derive(Error, Debug)]
pub enum AxiomMCPError {
    #[error("MCP initialization failed: {0}")]
    InitializationError(String),
    
    #[error("Tool execution failed: {0}")]
    ToolExecutionError(String),
    
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("Code generation error: {0}")]
    CodeGenerationError(String),
    
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),
    
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    
    #[error("HTTP request error: {0}")]
    HttpError(#[from] reqwest::Error),
    
    #[error("Task join error: {0}")]
    TaskError(#[from] tokio::task::JoinError),
    
    #[error("Generic error: {0}")]
    Other(#[from] anyhow::Error),
}

impl AxiomMCPError {
    pub fn is_recoverable(&self) -> bool {
        match self {
            AxiomMCPError::NetworkError(_) => true,
            AxiomMCPError::HttpError(_) => true,
            AxiomMCPError::TaskError(_) => true,
            _ => false,
        }
    }
}