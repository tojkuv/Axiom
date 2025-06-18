//! Utility modules for file management, validation, and configuration
//!
//! This module provides common utilities used throughout the client generator.

pub mod config;
pub mod file_manager;
pub mod naming;
pub mod validation;

pub use file_manager::FileManager;