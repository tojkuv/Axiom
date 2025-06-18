import Testing
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomCore

@Test("DomainCapability protocol with configuration management")
func testDomainCapabilityConfiguration() async throws {
    let networkCapability = MockNetworkCapability()
    
    // Test configuration access
    let config = await networkCapability.configuration
    #expect(config.isValid == true)
    
    // Test configuration update
    let newConfig = MockNetworkConfiguration(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 30.0,
        maxRetries: 3,
        enableLogging: true
    )
    
    try await networkCapability.updateConfiguration(newConfig)
    
    let updatedConfig = await networkCapability.configuration
    #expect(updatedConfig.timeout == 30.0)
}

@Test("CapabilityResource usage tracking")
func testCapabilityResourceUsage() async throws {
    let resource = MockNetworkResource()
    
    // Test initial usage
    let initialUsage = await resource.currentUsage
    #expect(initialUsage.memoryBytes == 0)
    #expect(initialUsage.cpuPercentage == 0.0)
    
    // Test resource allocation
    try await resource.allocate()
    
    let usageAfterAllocation = await resource.currentUsage
    #expect(usageAfterAllocation.memoryBytes > 0)
}

@Test("CapabilityEnvironment adaptation")
func testEnvironmentAdaptation() async throws {
    let capability = MockNetworkCapability()
    
    // Test development environment adjustment
    await capability.handleEnvironmentChange(.development)
    let devConfig = await capability.configuration
    #expect(devConfig.enableLogging == true)
    
    // Test production environment adjustment  
    await capability.handleEnvironmentChange(.production)
    let prodConfig = await capability.configuration
    #expect(prodConfig.enableLogging == false)
}

@Test("CapabilityConfiguration validation and merging")
func testConfigurationValidationMerging() async throws {
    let config1 = MockNetworkConfiguration(
        baseURL: URL(string: "https://api1.example.com")!,
        timeout: 15.0,
        maxRetries: 2,
        enableLogging: true
    )
    
    let config2 = MockNetworkConfiguration(
        baseURL: URL(string: "https://api2.example.com")!,
        timeout: 25.0,
        maxRetries: 5,
        enableLogging: false
    )
    
    // Test configuration validation
    #expect(config1.isValid == true)
    #expect(config2.isValid == true)
    
    // Test configuration merging
    let merged = config1.merged(with: config2)
    #expect(merged.timeout == 25.0) // Should use latest value
    #expect(merged.maxRetries == 5)
}

@Test("NetworkCapability domain implementation")
func testNetworkCapabilityDomain() async throws {
    let networkCapability = MockNetworkCapability()
    
    // Test activation with configuration
    try await networkCapability.activate()
    let state = await networkCapability.state
    #expect(state == .available)
    
    // Test resource management
    let resources = await networkCapability.resources
    let usage = await resources.currentUsage
    #expect(usage.networkBytesPerSecond >= 0)
    
    // Test environment awareness
    let environment = await networkCapability.environment
    #expect(environment == .development) // Default for testing
}

@Test("CapabilityEnvironment properties")
func testCapabilityEnvironmentProperties() async throws {
    // Test debug enabled environments
    #expect(CapabilityEnvironment.development.debugEnabled == true)
    #expect(CapabilityEnvironment.testing.debugEnabled == true)
    #expect(CapabilityEnvironment.preview.debugEnabled == true)
    
    // Test production environments
    #expect(CapabilityEnvironment.production.debugEnabled == false)
    #expect(CapabilityEnvironment.staging.debugEnabled == false)
    
    // Test strict limits
    #expect(CapabilityEnvironment.production.strictLimits == true)
    #expect(CapabilityEnvironment.staging.strictLimits == true)
    #expect(CapabilityEnvironment.development.strictLimits == false)
}

@Test("ResourceUsage struct functionality")
func testResourceUsageStruct() async throws {
    let usage = ResourceUsage(
        memory: 1_000_000,
        cpu: 15.5,
        network: 50_000,
        disk: 2_000_000
    )
    
    #expect(usage.memoryBytes == 1_000_000)
    #expect(usage.cpuPercentage == 15.5)
    #expect(usage.networkBytesPerSecond == 50_000)
    #expect(usage.diskBytes == 2_000_000)
    
    // Test zero usage
    let zeroUsage = ResourceUsage.zero
    #expect(zeroUsage.memoryBytes == 0)
    #expect(zeroUsage.cpuPercentage == 0.0)
    #expect(zeroUsage.networkBytesPerSecond == 0)
    #expect(zeroUsage.diskBytes == 0)
}

@Test("NetworkConfiguration environment adjustment")
func testNetworkConfigurationEnvironmentAdjustment() async throws {
    let baseConfig = NetworkConfiguration(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 15.0,
        maxRetries: 3,
        enableLogging: false,
        sslPinningEnabled: true
    )
    
    // Test development adjustment
    let devConfig = baseConfig.adjusted(for: .development)
    #expect(devConfig.timeout == 30.0) // Should be doubled
    #expect(devConfig.enableLogging == true)
    #expect(devConfig.sslPinningEnabled == false)
    
    // Test testing adjustment
    let testConfig = baseConfig.adjusted(for: .testing)
    #expect(testConfig.maxRetries == 1) // Single retry for predictable tests
    #expect(testConfig.enableLogging == false)
    #expect(testConfig.sslPinningEnabled == false)
    
    // Test production adjustment
    let prodConfig = baseConfig.adjusted(for: .production)
    #expect(prodConfig.timeout == 15.0) // Should remain same
    #expect(prodConfig.enableLogging == false)
    #expect(prodConfig.sslPinningEnabled == true)
}

@Test("NetworkResource allocation and release")
func testNetworkResourceAllocationRelease() async throws {
    let resource = NetworkResource(maxConnections: 2)
    
    // Test initial availability
    let initialAvailable = await resource.isAvailable
    #expect(initialAvailable == true)
    
    // Test first allocation
    try await resource.allocate()
    let usageAfterFirst = await resource.currentUsage
    #expect(usageAfterFirst.memoryBytes > 0)
    
    // Test second allocation
    try await resource.allocate()
    let usageAfterSecond = await resource.currentUsage
    #expect(usageAfterSecond.memoryBytes > usageAfterFirst.memoryBytes)
    
    // Test max connections reached
    let availableAfterMax = await resource.isAvailable
    #expect(availableAfterMax == false)
    
    // Should throw when trying to allocate beyond limit
    do {
        try await resource.allocate()
        #expect(Bool(false), "Should have thrown an error")
    } catch {
        #expect(error is CapabilityError)
    }
    
    // Test release
    await resource.release()
    let availableAfterRelease = await resource.isAvailable
    #expect(availableAfterRelease == true)
}

@Test("NetworkCapability activation and resource coordination")
func testNetworkCapabilityActivationResourceCoordination() async throws {
    let capability = NetworkCapability(
        configuration: NetworkConfiguration(
            baseURL: URL(string: "https://test.example.com")!,
            timeout: 10.0,
            maxRetries: 2
        ),
        environment: .testing
    )
    
    // Test initial state
    let initialState = await capability.state
    #expect(initialState == .unknown)
    
    // Test activation
    try await capability.activate()
    let activeState = await capability.state
    #expect(activeState == .available)
    
    // Test resource allocation occurred
    let resources = await capability.resources
    let usage = await resources.currentUsage
    #expect(usage.memoryBytes > 0) // Should have allocated resources
    
    // Test deactivation
    await capability.deactivate()
    let deactivatedState = await capability.state
    #expect(deactivatedState == .unavailable)
}

@Test("DomainCapability configuration update with validation")
func testDomainCapabilityConfigurationUpdateValidation() async throws {
    let capability = NetworkCapability()
    
    // Test valid configuration update
    let validConfig = NetworkConfiguration(
        baseURL: URL(string: "https://new-api.example.com")!,
        timeout: 20.0,
        maxRetries: 5
    )
    
    try await capability.updateConfiguration(validConfig)
    let updatedConfig = await capability.configuration
    #expect(updatedConfig.timeout == 20.0)
    
    // Test invalid configuration (negative timeout)
    let invalidConfig = NetworkConfiguration(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: -5.0, // Invalid
        maxRetries: 3
    )
    
    do {
        try await capability.updateConfiguration(invalidConfig)
        #expect(Bool(false), "Should have thrown an error for invalid configuration")
    } catch {
        #expect(error is CapabilityError)
    }
}