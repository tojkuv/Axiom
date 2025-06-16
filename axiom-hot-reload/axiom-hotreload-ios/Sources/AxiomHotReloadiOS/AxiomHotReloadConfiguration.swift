import SwiftUI
import NetworkClient
import SwiftUIRenderer

public struct AxiomHotReloadConfiguration {
    
    // MARK: - Core Settings
    
    /// Enable/disable hot reload functionality
    public var enableHotReload: Bool
    
    /// Automatically connect on appear
    public var autoConnect: Bool
    
    /// Clear rendered content when disconnected
    public var clearOnDisconnect: Bool
    
    /// Enable state logging for debugging
    public var enableStateLogging: Bool
    
    /// Enable debug mode with additional features
    public var enableDebugMode: Bool
    
    // MARK: - UI Settings
    
    /// Show connection status indicator
    public var showStatusIndicator: Bool
    
    /// Show debug information overlay
    public var showDebugInfo: Bool
    
    /// Status indicator bottom padding
    public var statusIndicatorPadding: CGFloat
    
    /// Status indicator size
    public var statusIndicatorSize: CGSize
    
    /// Status indicator colors
    public var statusIndicatorColors: StatusIndicatorColors
    
    // MARK: - Component Configurations
    
    /// Network client configuration
    public var networkConfiguration: ConnectionConfiguration
    
    /// SwiftUI renderer configuration
    public var renderConfiguration: SwiftUIRenderConfiguration
    
    /// State manager configuration
    public var stateConfiguration: SwiftUIStateConfiguration
    
    // MARK: - Initializers
    
    public init(
        enableHotReload: Bool = true,
        autoConnect: Bool = true,
        clearOnDisconnect: Bool = true,
        enableStateLogging: Bool = false,
        enableDebugMode: Bool = false,
        showStatusIndicator: Bool = true,
        showDebugInfo: Bool = false,
        statusIndicatorPadding: CGFloat = 20,
        statusIndicatorSize: CGSize = CGSize(width: 12, height: 12),
        statusIndicatorColors: StatusIndicatorColors = StatusIndicatorColors(),
        networkConfiguration: ConnectionConfiguration = ConnectionConfiguration(),
        renderConfiguration: SwiftUIRenderConfiguration = SwiftUIRenderConfiguration(),
        stateConfiguration: SwiftUIStateConfiguration = SwiftUIStateConfiguration()
    ) {
        self.enableHotReload = enableHotReload
        self.autoConnect = autoConnect
        self.clearOnDisconnect = clearOnDisconnect
        self.enableStateLogging = enableStateLogging
        self.enableDebugMode = enableDebugMode
        self.showStatusIndicator = showStatusIndicator
        self.showDebugInfo = showDebugInfo
        self.statusIndicatorPadding = statusIndicatorPadding
        self.statusIndicatorSize = statusIndicatorSize
        self.statusIndicatorColors = statusIndicatorColors
        self.networkConfiguration = networkConfiguration
        self.renderConfiguration = renderConfiguration
        self.stateConfiguration = stateConfiguration
    }
    
    // MARK: - Preset Configurations
    
    /// Development configuration with debugging enabled
    public static func development(
        host: String = "localhost", 
        port: Int = 8080
    ) -> AxiomHotReloadConfiguration {
        var networkConfig = ConnectionConfiguration()
        networkConfig.host = host
        networkConfig.port = port
        networkConfig.enableAutoReconnect = true
        networkConfig.reconnectDelay = 2.0
        
        return AxiomHotReloadConfiguration(
            enableHotReload: true,
            autoConnect: true,
            clearOnDisconnect: false,
            enableStateLogging: true,
            enableDebugMode: true,
            showStatusIndicator: true,
            showDebugInfo: false,
            networkConfiguration: networkConfig,
            renderConfiguration: .development(),
            stateConfiguration: .development()
        )
    }
    
    /// Production configuration with minimal overhead
    public static func production() -> AxiomHotReloadConfiguration {
        return AxiomHotReloadConfiguration(
            enableHotReload: false, // Disabled in production by default
            autoConnect: false,
            clearOnDisconnect: true,
            enableStateLogging: false,
            enableDebugMode: false,
            showStatusIndicator: false,
            showDebugInfo: false,
            networkConfiguration: ConnectionConfiguration(),
            renderConfiguration: .production(),
            stateConfiguration: .production()
        )
    }
    
    /// Hot reload optimized configuration
    public static func hotReload(
        host: String = "localhost",
        port: Int = 8080
    ) -> AxiomHotReloadConfiguration {
        var networkConfig = ConnectionConfiguration()
        networkConfig.host = host
        networkConfig.port = port
        networkConfig.enableAutoReconnect = true
        networkConfig.reconnectDelay = 1.0
        networkConfig.maxReconnectAttempts = 999 // Unlimited for development
        
        return AxiomHotReloadConfiguration(
            enableHotReload: true,
            autoConnect: true,
            clearOnDisconnect: false,
            enableStateLogging: false,
            enableDebugMode: false,
            showStatusIndicator: true,
            showDebugInfo: false,
            networkConfiguration: networkConfig,
            renderConfiguration: .hotReload(),
            stateConfiguration: .hotReload()
        )
    }
    
    /// Disabled configuration (for production builds)
    public static func disabled() -> AxiomHotReloadConfiguration {
        return AxiomHotReloadConfiguration(
            enableHotReload: false,
            autoConnect: false,
            clearOnDisconnect: true,
            enableStateLogging: false,
            enableDebugMode: false,
            showStatusIndicator: false,
            showDebugInfo: false
        )
    }
}

// MARK: - Supporting Types

public struct StatusIndicatorColors {
    public let connected: Color
    public let connecting: Color
    public let disconnected: Color
    public let error: Color
    
    public init(
        connected: Color = .green,
        connecting: Color = .yellow,
        disconnected: Color = .gray,
        error: Color = .red
    ) {
        self.connected = connected
        self.connecting = connecting
        self.disconnected = disconnected
        self.error = error
    }
    
    public static func monochrome() -> StatusIndicatorColors {
        return StatusIndicatorColors(
            connected: .primary,
            connecting: .secondary,
            disconnected: .secondary,
            error: .primary
        )
    }
    
    public static func subtle() -> StatusIndicatorColors {
        return StatusIndicatorColors(
            connected: .green.opacity(0.7),
            connecting: .yellow.opacity(0.7),
            disconnected: .gray.opacity(0.5),
            error: .red.opacity(0.7)
        )
    }
}

// MARK: - Configuration Builder

public final class AxiomHotReloadConfigurationBuilder {
    private var configuration = AxiomHotReloadConfiguration()
    
    public init() {}
    
    public func host(_ host: String) -> Self {
        configuration.networkConfiguration.host = host
        return self
    }
    
    public func port(_ port: Int) -> Self {
        configuration.networkConfiguration.port = port
        return self
    }
    
    public func autoConnect(_ enabled: Bool) -> Self {
        configuration.autoConnect = enabled
        return self
    }
    
    public func enableDebugMode(_ enabled: Bool) -> Self {
        configuration.enableDebugMode = enabled
        return self
    }
    
    public func showStatusIndicator(_ show: Bool) -> Self {
        configuration.showStatusIndicator = show
        return self
    }
    
    public func enableStateLogging(_ enabled: Bool) -> Self {
        configuration.enableStateLogging = enabled
        return self
    }
    
    public func statusIndicatorColors(_ colors: StatusIndicatorColors) -> Self {
        configuration.statusIndicatorColors = colors
        return self
    }
    
    public func renderConfiguration(_ config: SwiftUIRenderConfiguration) -> Self {
        configuration.renderConfiguration = config
        return self
    }
    
    public func stateConfiguration(_ config: SwiftUIStateConfiguration) -> Self {
        configuration.stateConfiguration = config
        return self
    }
    
    public func networkConfiguration(_ config: ConnectionConfiguration) -> Self {
        configuration.networkConfiguration = config
        return self
    }
    
    public func build() -> AxiomHotReloadConfiguration {
        return configuration
    }
}

// MARK: - Configuration Extensions

public extension AxiomHotReloadConfiguration {
    
    /// Create a builder for custom configuration
    static func builder() -> AxiomHotReloadConfigurationBuilder {
        return AxiomHotReloadConfigurationBuilder()
    }
    
    /// Create configuration from environment variables
    static func fromEnvironment() -> AxiomHotReloadConfiguration {
        let host = ProcessInfo.processInfo.environment["AXIOM_HOST"] ?? "localhost"
        let portString = ProcessInfo.processInfo.environment["AXIOM_PORT"] ?? "8080"
        let port = Int(portString) ?? 8080
        let enableDebug = ProcessInfo.processInfo.environment["AXIOM_DEBUG"] == "true"
        
        var config = AxiomHotReloadConfiguration()
        config.networkConfiguration.host = host
        config.networkConfiguration.port = port
        config.enableDebugMode = enableDebug
        config.enableStateLogging = enableDebug
        
        return config
    }
    
    /// Check if configuration is suitable for development
    var isDevelopmentConfiguration: Bool {
        return enableDebugMode || enableStateLogging || showDebugInfo
    }
    
    /// Check if configuration is suitable for production
    var isProductionConfiguration: Bool {
        return !enableDebugMode && !enableStateLogging && !showDebugInfo
    }
    
    /// Validate configuration settings
    func validate() throws {
        // Validate network configuration
        if networkConfiguration.host.isEmpty {
            throw ConfigurationError.invalidHost("Host cannot be empty")
        }
        
        if networkConfiguration.port <= 0 || networkConfiguration.port > 65535 {
            throw ConfigurationError.invalidPort("Port must be between 1 and 65535")
        }
        
        // Validate timeouts
        if networkConfiguration.connectionTimeout <= 0 {
            throw ConfigurationError.invalidTimeout("Connection timeout must be positive")
        }
        
        if networkConfiguration.reconnectDelay < 0 {
            throw ConfigurationError.invalidTimeout("Reconnect delay cannot be negative")
        }
    }
}

// MARK: - Configuration Errors

public enum ConfigurationError: Error, LocalizedError {
    case invalidHost(String)
    case invalidPort(String)
    case invalidTimeout(String)
    case invalidConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidHost(let message):
            return "Invalid host: \(message)"
        case .invalidPort(let message):
            return "Invalid port: \(message)"
        case .invalidTimeout(let message):
            return "Invalid timeout: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}