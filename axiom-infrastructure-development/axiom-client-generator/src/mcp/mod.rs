//! MCP (Model Context Protocol) integration module
//!
//! This module provides the MCP server implementation that integrates
//! with Claude Code to expose the client generation functionality.
//! Enhanced with real-time validation, progress reporting, and improved
//! Claude Code integration.

pub mod handlers;
pub mod protocol;
pub mod realtime_validator;
pub mod server;

pub use realtime_validator::{RealtimeValidator, ValidationIssue, IssueSeverity};
pub use server::{AxiomMcpServer, ProgressUpdate};