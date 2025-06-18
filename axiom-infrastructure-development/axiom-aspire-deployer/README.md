# Axiom Aspire Deployer MCP

A standalone Rust-based MCP (Model Context Protocol) server that bridges .NET Aspire applications with Claude Code, enabling intelligent development environment awareness and workflow automation.

## Overview

The Axiom Aspire Deployer MCP observes and interacts with .NET Aspire applications through external APIs, providing Claude Code with real-time insights into your development environment without requiring any modifications to existing Aspire packages.

## Features

### Phase 1: Core Development Workflow
- **Aspire Lifecycle Management**: Start, stop, and restart Aspire AppHost and services
- **Service Status Monitoring**: Real-time health checks and service discovery
- **Process Detection**: Automatic detection of running Aspire processes

### Phase 2: Service Interaction & Testing
- **HTTP/REST Endpoint Testing**: Call and test API endpoints with configurable parameters
- **Service Health Monitoring**: Deep health checks with system resource monitoring
- **gRPC Service Testing**: Mock gRPC client for testing streaming services

### Phase 3: Network Management
- **Local Network Configuration**: Configure services for cross-device testing
- **Device Configuration Generation**: Generate config files for iOS, Android, and web clients
- **Network URL Discovery**: Automatic detection of service URLs for local network access

### Phase 4: Automation & Monitoring
- **Comprehensive Logging**: Stream and search logs across all services
- **Service Discovery**: Automatic discovery and monitoring of Aspire services
- **Error Handling**: Robust error handling with detailed reporting

## Installation

### Prerequisites
- Rust 1.70+ 
- .NET 8+ with Aspire workload
- Running .NET Aspire application

### Build from Source
```bash
git clone <repository-url>
cd axiom-aspire-deployer
cargo build --release
```

## Configuration

Create a `config.toml` file (or use the default configuration):

```toml
[server]
name = "axiom-aspire-deployer"
version = "1.0.0"
port = 3001
host = "127.0.0.1"

[aspire]
auto_discovery = true
dashboard_url = "https://localhost:15888"
polling_interval_ms = 1000
api_timeout_ms = 5000

[monitoring]
monitor_processes = true
watch_config_files = true
health_check_interval_ms = 5000

[network]
local_interface = "0.0.0.0"
network_scan_enabled = true
port_scan_range = "7000-8000"

[logging]
level = "info"
file = "axiom-aspire-mcp.log"
structured = true
```

## Usage

### Starting the MCP Server

```bash
# With default configuration
cargo run

# With custom configuration
cargo run -- --config custom-config.toml --port 3002

# With verbose logging
cargo run -- --verbose
```

### Available MCP Tools

The server provides the following tools for Claude Code:

#### Aspire Management
- `axiom_aspire_start` - Start Aspire AppHost with specified profile
- `axiom_aspire_stop` - Stop Aspire AppHost and all services  
- `axiom_aspire_restart` - Restart specific service or entire stack
- `axiom_aspire_status` - Get comprehensive status of all services
- `axiom_aspire_health` - Detailed health check of all services

#### Service Interaction
- `axiom_get_service_urls` - Get current service URLs from Aspire dashboard
- `axiom_call_endpoint` - Call API endpoints for testing
- `axiom_configure_local_network` - Configure services for local network access
- `axiom_get_network_urls` - Get network-accessible URLs for cross-device testing

### Example Usage with Claude Code

Once the MCP server is running, Claude Code can use these tools:

```
Start the Aspire application in Development mode:
→ Claude Code calls: axiom_aspire_start({"profile": "Development", "watch": true})

Check service status:
→ Claude Code calls: axiom_aspire_status({})

Test an API endpoint:
→ Claude Code calls: axiom_call_endpoint({
    "service": "api",
    "endpoint": "/health",
    "method": "GET"
})

Configure for mobile testing:
→ Claude Code calls: axiom_configure_local_network({
    "expose_services": ["api", "notifications"],
    "bind_mode": "local_network"
})
```

## Architecture

### Core Components

- **MCP Server**: Handles protocol communication with Claude Code
- **Service Discovery**: Monitors Aspire dashboard and detects running services
- **Orchestrator**: Manages Aspire process lifecycle and service interactions
- **Health Monitor**: Performs comprehensive health checks and monitoring
- **Network Manager**: Configures local network access and generates device configs
- **HTTP/gRPC Clients**: Enable endpoint testing and service interaction

### Technology Stack

- **Runtime**: Tokio async runtime
- **HTTP Client**: reqwest with TLS support
- **gRPC**: tonic for future gRPC service integration
- **Configuration**: TOML-based configuration management
- **Logging**: structured logging with tracing
- **Process Monitoring**: sysinfo for system process detection
- **Network**: local-ip-address for network configuration

## Development

### Running Tests
```bash
# Run all tests
cargo test

# Run specific test
cargo test test_default_settings

# Run with verbose output
cargo test -- --nocapture
```

### Performance Benchmarks
```bash
cargo bench
```

### Code Coverage
```bash
cargo tarpaulin --out Html
```

## Security Considerations

- **Local Development Only**: Designed for local development environments
- **No External Exposure**: Services bind only to local interfaces by default
- **Certificate Trust**: Supports self-signed certificates for local HTTPS
- **Process Isolation**: Runs independently without modifying existing applications

## Troubleshooting

### Common Issues

1. **Aspire Dashboard Not Found**
   - Ensure Aspire AppHost is running
   - Check dashboard URL in configuration
   - Verify dashboard is accessible at `https://localhost:15888`

2. **Service Discovery Failing**
   - Check if Aspire dashboard API is responding
   - Verify network connectivity
   - Review polling interval configuration

3. **Network Configuration Issues**
   - Ensure proper firewall settings for local network access
   - Verify network interface configuration
   - Check port availability in specified range

### Debug Mode

Run with verbose logging to troubleshoot issues:

```bash
cargo run -- --verbose
```

Check the log file for detailed information:
```bash
tail -f axiom-aspire-mcp.log
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

[License information]

## Support

For issues and questions:
- Create an issue in the repository
- Review the troubleshooting section
- Check the logs for detailed error information

---

Generated by Claude Code - Bridging .NET Aspire with AI-powered development workflows.