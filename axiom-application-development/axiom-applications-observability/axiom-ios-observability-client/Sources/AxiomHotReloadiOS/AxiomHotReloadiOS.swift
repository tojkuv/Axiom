// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// The main module for Axiom Hot Reload iOS integration.
/// 
/// This module provides a simple SwiftUI integration for hot reload functionality
/// that allows real-time preview of SwiftUI code changes without recompiling.
///
/// ## Usage
///
/// ### Basic Integration (3-line setup):
/// ```swift
/// import AxiomHotReloadiOS
/// 
/// AxiomHotReload {
///     MyContentView()
/// }
/// ```
///
/// ### Custom Configuration:
/// ```swift
/// AxiomHotReload(host: "192.168.1.100", port: 8080) {
///     MyContentView()
/// }
/// ```
///
/// ### Development Configuration:
/// ```swift
/// AxiomHotReload.development(host: "localhost") {
///     MyContentView()
/// }
/// ```
///
/// ## Features
///
/// - **Real-time SwiftUI Rendering**: See changes instantly without recompilation
/// - **State Preservation**: Maintain app state during hot reload sessions
/// - **Auto-reconnection**: Automatically reconnects when server becomes available
/// - **Debug Tools**: Built-in debugging overlay with connection and render statistics
/// - **Fallback UI**: Gracefully falls back to original content when not connected
/// - **Production Ready**: Designed to be safely disabled in production builds
///
/// ## Configuration
///
/// The module supports various configuration options:
/// - Network settings (host, port, timeouts)
/// - UI settings (status indicators, debug overlays)
/// - Rendering settings (caching, fallback behavior)
/// - State management settings (persistence, logging)
///
/// ## Debug Features
///
/// When debug mode is enabled:
/// - Connection status indicator
/// - Debug overlay with detailed statistics
/// - State inspection and manipulation
/// - Render performance metrics
/// - Error reporting and diagnostics
///
public enum AxiomHotReloadiOS {
    
    /// Current version of the AxiomHotReloadiOS framework
    public static let version = "1.0.0"
    
    /// Build number for this release
    public static let buildNumber = 1
    
    /// Framework information
    public static let info = FrameworkInfo(
        name: "AxiomHotReloadiOS",
        version: version,
        buildNumber: buildNumber,
        description: "SwiftUI Hot Reload Client for Axiom Framework"
    )
}

/// Framework information structure
public struct FrameworkInfo {
    public let name: String
    public let version: String
    public let buildNumber: Int
    public let description: String
    
    public var fullVersionString: String {
        return "\(version) (build \(buildNumber))"
    }
    
    public var userAgentString: String {
        return "\(name)/\(version)"
    }
}

// MARK: - Public API Exports

// Re-export module dependencies
@_exported import NetworkClient
@_exported import SwiftUIRenderer

// Public API is available through the individual Swift files in this module
// No need for circular imports since this file IS part of AxiomHotReloadiOS

// Protocol Types (for advanced usage)
@_exported import HotReloadProtocol