import Testing
@testable import Axiom

// MARK: - Test Infrastructure

// Test capability for testing
actor TestComposableCapability: ComposableCapability {
    typealias DependencyType = BasicCapabilityDependency
    typealias ConfigurationType = BasicCapabilityConfiguration
    
    let id: String
    let capabilityType = CapabilityType.custom("test")
    var state: CapabilityState = .inactive
    
    private let _dependencies: [BasicCapabilityDependency]
    private var dependencyStates: [String: CapabilityState] = [:]
    
    init(id: String = "test-composable", dependencies: [BasicCapabilityDependency] = []) {
        self.id = id
        self._dependencies = dependencies
    }
    
    var dependencies: [BasicCapabilityDependency] {
        get async { _dependencies }
    }
    
    func initialize() async throws {
        state = .initializing
        try await validateDependencies()
        state = .active
    }
    
    func configure(with configuration: BasicCapabilityConfiguration) async {
        // Configuration logic
    }
    
    func terminate() async {
        state = .terminating
        state = .inactive
    }
    
    func validateDependencies() async throws {
        for dependency in _dependencies {
            if dependency.type == .required {
                // In a real implementation, check if dependency is available
                guard dependencyStates[dependency.id] == .active else {
                    throw CapabilityError.initializationFailed("Required dependency \(dependency.id) is not active")
                }
            }
        }
    }
    
    func handleDependencyChange(_ dependency: BasicCapabilityDependency, newState: CapabilityState) async {
        dependencyStates[dependency.id] = newState
        
        // Handle state changes based on dependency type
        if dependency.type == .required && newState != .active {
            // Deactivate if required dependency becomes inactive
            state = .inactive
        }
    }
}

// Test resource implementations
actor TestNetworkResource: CapabilityResource {
    var currentUsage: ResourceUsage {
        get async { ResourceUsage(used: 0, total: 100, unit: "connections") }
    }
    
    var isAvailable: Bool {
        get async { true }
    }
    
    func allocate() async throws {
        // Allocation logic
    }
    
    func release() async {
        // Release logic
    }
    
    func checkAvailability() async -> Bool {
        true
    }
}

actor TestLimitedResource: CapabilityResource {
    let maxConcurrent: Int
    private var allocated = 0
    
    init(maxConcurrent: Int) {
        self.maxConcurrent = maxConcurrent
    }
    
    var currentUsage: ResourceUsage {
        get async {
            ResourceUsage(
                used: allocated,
                total: maxConcurrent,
                unit: "slots"
            )
        }
    }
    
    var isAvailable: Bool {
        get async { allocated < maxConcurrent }
    }
    
    func allocate() async throws {
        guard allocated < maxConcurrent else {
            throw CapabilityError.resourceUnavailable("No slots available")
        }
        allocated += 1
    }
    
    func release() async {
        if allocated > 0 {
            allocated -= 1
        }
    }
    
    func checkAvailability() async -> Bool {
        allocated < maxConcurrent
    }
}

// Test hierarchical capability
actor TestHierarchicalCapability: DomainCapability, CapabilityHierarchy {
    typealias ParentCapability = TestHierarchicalCapability
    typealias ChildCapability = TestHierarchicalCapability
    typealias ConfigurationType = BasicCapabilityConfiguration
    
    let id: String
    let capabilityType = CapabilityType.custom("hierarchical")
    var state: CapabilityState = .inactive
    
    private(set) var parent: TestHierarchicalCapability?
    private var _children: [TestHierarchicalCapability] = []
    
    var children: [TestHierarchicalCapability] {
        get async { _children }
    }
    
    init(id: String) {
        self.id = id
    }
    
    func initialize() async throws {
        state = .initializing
        state = .active
    }
    
    func configure(with configuration: BasicCapabilityConfiguration) async {
        // Configuration logic
    }
    
    func terminate() async {
        state = .terminating
        state = .inactive
    }
    
    func addChild(_ child: TestHierarchicalCapability) async throws {
        _children.append(child)
        await child.setParent(self)
    }
    
    func removeChild(_ child: TestHierarchicalCapability) async {
        _children.removeAll { $0.id == child.id }
        await child.setParent(nil)
    }
    
    func propagateStateChange(_ state: CapabilityState) async {
        self.state = state
        for child in _children {
            await child.propagateStateChange(state)
        }
    }
    
    func setParent(_ parent: TestHierarchicalCapability?) async {
        self.parent = parent
    }
}

// MARK: - Tests

struct CapabilityCompositionTests {
    
    @Test("ComposableCapability supports dependency management")
    func testComposableCapabilityDependencyManagement() async throws {
        // Create a test composable capability
        let testCapability = TestComposableCapability(dependencies: [
            BasicCapabilityDependency(id: "required-capability", type: .required),
            BasicCapabilityDependency(id: "optional-capability", type: .optional)
        ])
        
        // Verify dependencies can be retrieved
        let dependencies = await testCapability.dependencies
        #expect(dependencies.count == 2)
        #expect(dependencies[0].id == "required-capability")
        #expect(dependencies[0].type == .required)
        #expect(dependencies[1].id == "optional-capability")
        #expect(dependencies[1].type == .optional)
        
        // Set dependency states
        await testCapability.handleDependencyChange(
            dependencies[0],
            newState: .active
        )
        
        // Verify dependency validation works
        try await testCapability.validateDependencies()
        
        // Verify dependency change handling
        await testCapability.handleDependencyChange(
            dependencies[0],
            newState: .inactive
        )
        
        let state = await testCapability.state
        #expect(state == .inactive)
    }
    
    @Test("Capability dependency types are properly defined")
    func testCapabilityDependencyTypes() async throws {
        // Test required dependency
        let requiredDep = BasicCapabilityDependency(
            id: "auth-capability",
            type: .required
        )
        #expect(requiredDep.id == "auth-capability")
        #expect(requiredDep.type == .required)
        #expect(requiredDep.type.isMandatory == true)
        
        // Test optional dependency
        let optionalDep = BasicCapabilityDependency(
            id: "analytics-capability",
            type: .optional
        )
        #expect(optionalDep.type == .optional)
        #expect(optionalDep.type.isMandatory == false)
        
        // Test exclusive dependency
        let exclusiveDep = BasicCapabilityDependency(
            id: "legacy-auth",
            type: .exclusive
        )
        #expect(exclusiveDep.type == .exclusive)
        #expect(exclusiveDep.type.canCoexist == false)
        
        // Test composable dependency
        let composableDep = BasicCapabilityDependency(
            id: "cache-capability",
            type: .composable
        )
        #expect(composableDep.type == .composable)
        #expect(composableDep.type.canCombine == true)
    }
    
    @Test("DependencyResolver resolves capability dependencies correctly")
    func testDependencyResolution() async throws {
        let resolver = DependencyResolver()
        
        // Register capabilities with dependencies
        await resolver.registerCapability("database", dependencies: [])
        await resolver.registerCapability("cache", dependencies: ["database"])
        await resolver.registerCapability("api", dependencies: ["cache", "auth"])
        await resolver.registerCapability("auth", dependencies: ["database"])
        
        // Resolve dependencies for API capability
        let order = try await resolver.resolveDependencies(for: "api")
        
        // Verify correct resolution order
        #expect(order == ["database", "auth", "cache", "api"])
        
        // Verify all dependencies are included
        #expect(order.contains("database"))
        #expect(order.contains("auth"))
        #expect(order.contains("cache"))
    }
    
    @Test("DependencyResolver detects circular dependencies")
    func testCircularDependencyDetection() async throws {
        let resolver = DependencyResolver()
        
        // Create circular dependency: A -> B -> C -> A
        await resolver.registerCapability("A", dependencies: ["B"])
        await resolver.registerCapability("B", dependencies: ["C"])
        await resolver.registerCapability("C", dependencies: ["A"])
        
        // Attempt to resolve should throw
        await #expect(throws: CapabilityError.self) {
            try await resolver.resolveDependencies(for: "A")
        }
    }
    
    @Test("CapabilityResourcePool manages shared resources")
    func testResourcePoolManagement() async throws {
        let resourcePool = CapabilityResourcePool()
        let networkResource = TestNetworkResource()
        
        // Register resource
        await resourcePool.registerResource(
            networkResource,
            withId: "network"
        )
        
        // Request resource with priority
        try await resourcePool.requestResource(
            resourceId: "network",
            capabilityId: "api-capability",
            priority: .high
        )
        
        // Verify resource is allocated
        let isAllocated = await resourcePool.isResourceAllocated(
            resourceId: "network",
            to: "api-capability"
        )
        #expect(isAllocated == true)
        
        // Release resource
        await resourcePool.releaseResource(
            resourceId: "network",
            capabilityId: "api-capability"
        )
        
        // Verify resource is released
        let isAllocatedAfter = await resourcePool.isResourceAllocated(
            resourceId: "network",
            to: "api-capability"
        )
        #expect(isAllocatedAfter == false)
    }
    
    @Test("CapabilityResourcePool handles priority-based allocation")
    func testPriorityBasedResourceAllocation() async throws {
        let resourcePool = CapabilityResourcePool()
        let resource = TestLimitedResource(maxConcurrent: 1)
        
        await resourcePool.registerResource(resource, withId: "limited")
        
        // Low priority request first
        try await resourcePool.requestResource(
            resourceId: "limited",
            capabilityId: "low-priority",
            priority: .low
        )
        
        // High priority request should preempt
        try await resourcePool.requestResource(
            resourceId: "limited",
            capabilityId: "high-priority",
            priority: .high
        )
        
        // Verify high priority capability has the resource
        let highPriorityHasResource = await resourcePool.isResourceAllocated(
            resourceId: "limited",
            to: "high-priority"
        )
        #expect(highPriorityHasResource == true)
        
        let lowPriorityHasResource = await resourcePool.isResourceAllocated(
            resourceId: "limited",
            to: "low-priority"
        )
        #expect(lowPriorityHasResource == false)
    }
    
    @Test("CapabilityHierarchy manages parent-child relationships")
    func testCapabilityHierarchy() async throws {
        // Create parent capability
        let parentCapability = TestHierarchicalCapability(id: "parent")
        
        // Create child capabilities
        let child1 = TestHierarchicalCapability(id: "child1")
        let child2 = TestHierarchicalCapability(id: "child2")
        
        // Add children
        try await parentCapability.addChild(child1)
        try await parentCapability.addChild(child2)
        
        // Verify hierarchy
        let children = await parentCapability.children
        #expect(children.count == 2)
        #expect(children.contains { $0.id == "child1" })
        #expect(children.contains { $0.id == "child2" })
        
        // Verify parent reference
        let child1Parent = await child1.parent
        #expect(child1Parent?.id == "parent")
        
        // Test state propagation
        await parentCapability.propagateStateChange(.active)
        let child1State = await child1.state
        #expect(child1State == .active)
    }
}