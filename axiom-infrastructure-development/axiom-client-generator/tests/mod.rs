//! Comprehensive test suite for Axiom Swift Client Generator
//!
//! This module contains the complete testing infrastructure including:
//! - Unit tests for core functionality
//! - Integration tests with Axiom Apple framework
//! - End-to-end workflow testing
//! - Performance benchmarking
//! - Generated code compilation verification
//! - MCP protocol compliance testing

pub mod integration;
pub mod performance;
pub mod unit;
pub mod fixtures;
pub mod helpers;
pub mod compilation;
pub mod mcp;

// Re-export test utilities for easy access
pub use helpers::*;
pub use fixtures::*;