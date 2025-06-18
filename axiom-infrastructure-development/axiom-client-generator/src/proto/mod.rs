//! Proto parsing and analysis module
//!
//! This module provides functionality for parsing gRPC proto files,
//! extracting service definitions, messages, and custom options.

pub mod analyzer;
pub mod metadata;
pub mod parser;
pub mod types;

pub use analyzer::ProtoAnalyzer;
pub use parser::ProtoParser;
pub use types::*;