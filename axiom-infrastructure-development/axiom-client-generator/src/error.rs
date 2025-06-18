use thiserror::Error;

/// Result type for the axiom universal client generator
pub type Result<T> = std::result::Result<T, Error>;

/// Type alias for backward compatibility with tests
pub type GeneratorError = Error;

/// Error categories for organizing different types of errors
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorCategory {
    ProtoProcessing,
    CodeGeneration,
    FileSystem,
    Configuration,
    Validation,
    Network,
    Internal,
    Client,
    State,
    Action,
    Framework,
}

/// Error types for the axiom universal client generator
#[derive(Error, Debug)]
pub enum Error {

    /// File I/O errors
    #[error("File I/O error: {0}")]
    IoError(#[from] std::io::Error),

    /// Template rendering errors
    #[error("Template rendering error: {0}")]
    TemplateError(String),

    /// Code generation errors
    #[error("Code generation error: {0}")]
    CodeGenerationError(String),

    /// Configuration errors
    #[error("Configuration error: {0}")]
    ConfigError(String),

    /// MCP protocol errors
    #[error("MCP protocol error: {0}")]
    McpError(String),

    /// Validation errors
    #[error("Validation error: {0}")]
    ValidationError(String),

    /// File-specific validation errors
    #[error("File validation error: {0}")]
    FileValidation(String),

    /// Compilation validation errors  
    #[error("Compilation validation error: {0}")]
    Validation(String),

    /// Serialization/deserialization errors
    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),

    /// Generic errors
    #[error("Generic error: {0}")]
    GenericError(#[from] anyhow::Error),

    /// Path validation errors
    #[error("Invalid path: {0}")]
    InvalidPath(String),

    /// Language not supported
    #[error("Language not supported: {0}")]
    UnsupportedLanguage(String),

    /// Service not found
    #[error("Service not found: {0}")]
    ServiceNotFound(String),

    /// Template not found
    #[error("Template not found: {0}")]
    TemplateNotFound(String),

    /// Proto file not found
    #[error("Proto file not found: {0}")]
    ProtoFileNotFound(String),

    /// Framework integration error
    #[error("Framework integration error: {0}")]
    FrameworkIntegrationError(String),

    /// Concurrent operation error
    #[error("Concurrent operation error: {0}")]
    ConcurrencyError(String),
    
    /// System time error
    #[error("System time error: {0}")]
    SystemTimeError(#[from] std::time::SystemTimeError),
    
    /// Axiom client errors (compatible with AxiomError from framework)
    #[error("Axiom client error: {0}")]
    AxiomClientError(String),
    
    /// Axiom state errors
    #[error("Axiom state error: {0}")]
    AxiomStateError(String),
    
    /// Axiom action errors  
    #[error("Axiom action error: {0}")]
    AxiomActionError(String),

    /// Structured error variants for tests
    /// Proto parsing error with file path
    #[error("Proto parsing error in {file_path:?}: {message}")]
    ProtoParsingError {
        file_path: std::path::PathBuf,
        message: String,
    },

    /// Swift generation error with service context
    #[error("Swift generation error for service '{service_name}': {reason}")]
    SwiftGenerationError {
        service_name: String,
        reason: String,
    },

    /// File operation error with context
    #[error("File operation '{operation}' failed on {path:?}: {source}")]
    FileOperationError {
        path: std::path::PathBuf,
        operation: String,
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },

    /// Configuration error with field context
    #[error("Configuration error in field '{field}': {message}")]
    ConfigurationError {
        field: String,
        message: String,
    },
}

impl Error {
    /// Get error category for organizing different types of errors
    pub fn category(&self) -> ErrorCategory {
        match self {
            Error::ProtoParsingError { .. } | Error::ProtoFileNotFound(_) => ErrorCategory::ProtoProcessing,
            Error::SwiftGenerationError { .. } | Error::CodeGenerationError(_) | Error::TemplateError(_) | Error::TemplateNotFound(_) => ErrorCategory::CodeGeneration,
            Error::FileOperationError { .. } | Error::IoError(_) | Error::FileValidation(_) | Error::InvalidPath(_) => ErrorCategory::FileSystem,
            Error::ConfigurationError { .. } | Error::ConfigError(_) => ErrorCategory::Configuration,
            Error::ValidationError(_) | Error::Validation(_) => ErrorCategory::Validation,
            Error::McpError(_) => ErrorCategory::Network,
            Error::SystemTimeError(_) => ErrorCategory::Internal,
            _ => ErrorCategory::Internal,
        }
    }
}

/// Axiom-specific error types that map to Swift AxiomError
#[derive(Error, Debug, Clone)]
pub enum AxiomError {
    /// Client-related errors
    #[error("Client error: {0}")]
    ClientError(AxiomClientErrorKind),
    
    /// Network-related errors
    #[error("Network error: {0}")]
    NetworkError(String),
    
    /// State management errors
    #[error("State error: {0}")]
    StateError(String),
    
    /// Action processing errors
    #[error("Action error: {0}")]
    ActionError(String),
    
    /// Validation errors
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    /// Framework integration errors
    #[error("Framework error: {0}")]
    FrameworkError(String),
}

/// Client error kinds that map to Swift AxiomClientError
#[derive(Error, Debug, Clone)]
pub enum AxiomClientErrorKind {
    /// Invalid action provided
    #[error("Invalid action: {0}")]
    InvalidAction(String),
    
    /// State update failed
    #[error("State update failed: {0}")]
    StateUpdateFailed(String),
    
    /// Stream error
    #[error("Stream error: {0}")]
    StreamError(String),
    
    /// Initialization error
    #[error("Initialization error: {0}")]
    InitializationError(String),
    
    /// Concurrency error
    #[error("Concurrency error: {0}")]
    ConcurrencyError(String),
    
    /// Configuration error
    #[error("Configuration error: {0}")]
    ConfigurationError(String),
}

impl From<tera::Error> for Error {
    fn from(err: tera::Error) -> Self {
        Error::TemplateError(err.to_string())
    }
}

impl From<handlebars::RenderError> for Error {
    fn from(err: handlebars::RenderError) -> Self {
        Error::TemplateError(err.to_string())
    }
}

impl From<prost::DecodeError> for Error {
    fn from(err: prost::DecodeError) -> Self {
        Error::ProtoParsingError {
            file_path: std::path::PathBuf::from("unknown"),
            message: err.to_string(),
        }
    }
}

impl From<walkdir::Error> for Error {
    fn from(err: walkdir::Error) -> Self {
        Error::IoError(std::io::Error::new(
            std::io::ErrorKind::Other,
            err.to_string(),
        ))
    }
}

impl From<AxiomError> for Error {
    fn from(err: AxiomError) -> Self {
        match err {
            AxiomError::ClientError(client_err) => Error::AxiomClientError(client_err.to_string()),
            AxiomError::StateError(msg) => Error::AxiomStateError(msg),
            AxiomError::ActionError(msg) => Error::AxiomActionError(msg),
            AxiomError::NetworkError(msg) => Error::ConfigError(format!("Network: {}", msg)),
            AxiomError::ValidationError(msg) => Error::ValidationError(msg),
            AxiomError::FrameworkError(msg) => Error::FrameworkIntegrationError(msg),
        }
    }
}

impl From<AxiomClientErrorKind> for AxiomError {
    fn from(err: AxiomClientErrorKind) -> Self {
        AxiomError::ClientError(err)
    }
}

impl AxiomError {
    /// Create a client error for invalid actions
    pub fn invalid_action(message: impl Into<String>) -> Self {
        AxiomError::ClientError(AxiomClientErrorKind::InvalidAction(message.into()))
    }
    
    /// Create a client error for state update failures
    pub fn state_update_failed(message: impl Into<String>) -> Self {
        AxiomError::ClientError(AxiomClientErrorKind::StateUpdateFailed(message.into()))
    }
    
    /// Create a client error for stream issues
    pub fn stream_error(message: impl Into<String>) -> Self {
        AxiomError::ClientError(AxiomClientErrorKind::StreamError(message.into()))
    }
    
    /// Create a validation error
    pub fn validation_error(message: impl Into<String>) -> Self {
        AxiomError::ValidationError(message.into())
    }
    
    /// Create a network error
    pub fn network_error(message: impl Into<String>) -> Self {
        AxiomError::NetworkError(message.into())
    }
    
    /// Create a framework integration error
    pub fn framework_error(message: impl Into<String>) -> Self {
        AxiomError::FrameworkError(message.into())
    }
    
    /// Check if this error is recoverable
    pub fn is_recoverable(&self) -> bool {
        match self {
            AxiomError::NetworkError(_) => true,
            AxiomError::ValidationError(_) => true,
            AxiomError::ClientError(AxiomClientErrorKind::StateUpdateFailed(_)) => true,
            AxiomError::ClientError(AxiomClientErrorKind::StreamError(_)) => true,
            _ => false,
        }
    }
    
    /// Get error category for grouping similar errors
    pub fn category(&self) -> ErrorCategory {
        match self {
            AxiomError::ClientError(_) => ErrorCategory::Client,
            AxiomError::NetworkError(_) => ErrorCategory::Network,
            AxiomError::StateError(_) => ErrorCategory::State,
            AxiomError::ActionError(_) => ErrorCategory::Action,
            AxiomError::ValidationError(_) => ErrorCategory::Validation,
            AxiomError::FrameworkError(_) => ErrorCategory::Framework,
        }
    }
    
    /// Get suggested resolution for this error
    pub fn suggested_resolution(&self) -> String {
        match self {
            AxiomError::ClientError(AxiomClientErrorKind::InvalidAction(_)) => 
                "Verify the action conforms to the expected protocol and includes required fields.".to_string(),
            AxiomError::ClientError(AxiomClientErrorKind::StateUpdateFailed(_)) => 
                "Check state update logic and ensure immutable state patterns are followed.".to_string(),
            AxiomError::ClientError(AxiomClientErrorKind::StreamError(_)) => 
                "Verify AsyncStream setup and ensure proper continuation management.".to_string(),
            AxiomError::ClientError(AxiomClientErrorKind::InitializationError(_)) => 
                "Check client initialization parameters and ensure required dependencies are available.".to_string(),
            AxiomError::ClientError(AxiomClientErrorKind::ConfigurationError(_)) => 
                "Review configuration settings and ensure all required options are properly set.".to_string(),
            AxiomError::NetworkError(_) => 
                "Check network connectivity and API endpoint configuration.".to_string(),
            AxiomError::ValidationError(_) => 
                "Review input validation rules and ensure all required fields are provided.".to_string(),
            AxiomError::FrameworkError(_) => 
                "Verify Axiom framework integration and ensure all required imports are present.".to_string(),
            _ => "Consult documentation or contact support for assistance.".to_string(),
        }
    }
}


/// Enhanced error context for better debugging
#[derive(Debug, Clone)]
pub struct ErrorContext {
    pub file_path: Option<String>,
    pub line_number: Option<usize>,
    pub function_name: Option<String>,
    pub additional_info: std::collections::HashMap<String, String>,
}

impl ErrorContext {
    pub fn new() -> Self {
        Self {
            file_path: None,
            line_number: None,
            function_name: None,
            additional_info: std::collections::HashMap::new(),
        }
    }
    
    pub fn with_file(mut self, path: impl Into<String>) -> Self {
        self.file_path = Some(path.into());
        self
    }
    
    pub fn with_line(mut self, line: usize) -> Self {
        self.line_number = Some(line);
        self
    }
    
    pub fn with_function(mut self, function: impl Into<String>) -> Self {
        self.function_name = Some(function.into());
        self
    }
    
    pub fn with_info(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.additional_info.insert(key.into(), value.into());
        self
    }
}