//! Code generation module for Swift Axiom clients
//!
//! This module provides the core code generation functionality for
//! generating Axiom-compatible Swift clients from proto definitions.

pub mod registry;
pub mod swift;

pub use registry::GeneratorRegistry;