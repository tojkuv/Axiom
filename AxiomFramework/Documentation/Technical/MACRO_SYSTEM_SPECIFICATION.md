# Axiom Framework: Complete Macro System Specification

## 🎯 Macro System Overview

The Axiom macro system eliminates boilerplate while enforcing architectural constraints through compile-time code generation and validation. Macros provide the developer experience layer that makes Axiom's powerful architecture accessible and ergonomic.

## 📋 Core Macros

### 1. @Client Macro

#### Purpose
Automatically inject and manage client dependencies in contexts with type safety and lifecycle management.

#### Usage
```swift
struct CheckoutContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient
    @Client var paymentClient: PaymentClient
}
```

#### Generated Code
```swift
struct CheckoutContext: AxiomContext {
    private let _userClient: UserClient
    private let _orderClient: OrderClient
    private let _paymentClient: PaymentClient
    
    var userClient: UserClient { _userClient }
    var orderClient: OrderClient { _orderClient }
    var paymentClient: PaymentClient { _paymentClient }
    
    init(userClient: UserClient, orderClient: OrderClient, paymentClient: PaymentClient) {
        self._userClient = userClient
        self._orderClient = orderClient
        self._paymentClient = paymentClient
        
        // Automatic observer registration
        Task {
            await userClient.addObserver(self)
            await orderClient.addObserver(self)
            await paymentClient.addObserver(self)
        }
    }
    
    deinit {
        Task {
            await userClient.removeObserver(self)
            await orderClient.removeObserver(self)
            await paymentClient.removeObserver(self)
        }
    }
}
```

#### Implementation
```swift
public struct ClientMacro: PeerMacro, MemberMacro {
    public static func expansion<Declaration: DeclSyntaxProtocol, Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              structDecl.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "AxiomContext" }) == true else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: ClientMacroDiagnostic.onlyOnAxiomContext
            ))
            return []
        }
        
        let clientProperties = extractClientProperties(from: structDecl)
        return try generateClientManagement(for: clientProperties, in: context)
    }
}
```

### 2. @Capabilities Macro

#### Purpose
Declare and validate capability requirements with compile-time checking and runtime optimization.

#### Usage
```swift
@Capabilities([.network, .keychain, .analytics])
actor NetworkClient: AxiomClient {
    func makeRequest() async throws {
        // Capabilities automatically validated
        try capabilities.validate(.network)
        // Implementation
    }
}
```

#### Generated Code
```swift
actor NetworkClient: AxiomClient {
    private let _capabilityManager: CapabilityManager
    
    var capabilities: CapabilityManager { _capabilityManager }
    
    // Required capabilities metadata
    static var requiredCapabilities: Set<Capability> {
        [.network, .keychain, .analytics]
    }
    
    init(capabilityManager: CapabilityManager) async throws {
        self._capabilityManager = capabilityManager
        
        // Validate all required capabilities at initialization
        for capability in Self.requiredCapabilities {
            try capabilityManager.validate(capability)
        }
    }
    
    func makeRequest() async throws {
        // Optimized capability validation with caching
        try capabilities.validateCached(.network)
        // Original implementation
    }
}
```

#### Implementation
```swift
public struct CapabilitiesMacro: PeerMacro, MemberMacro {
    public static func expansion<Declaration: DeclSyntaxProtocol, Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: CapabilitiesMacroDiagnostic.onlyOnActors
            ))
            return []
        }
        
        let capabilities = try extractCapabilities(from: node, in: context)
        return try generateCapabilityManagement(for: capabilities, in: context)
    }
}
```

### 3. @DomainModel Macro

#### Purpose
Generate domain model boilerplate including validation, business rules, and immutable update methods.

#### Usage
```swift
@DomainModel
struct User {
    let id: User.ID
    let name: String
    let email: EmailAddress
    let status: UserStatus
    
    @BusinessRule("Name must not be empty")
    func validateName() -> Bool {
        !name.isEmpty
    }
    
    @BusinessRule("Email must be valid format")
    func validateEmail() -> Bool {
        email.isValid
    }
}
```

#### Generated Code
```swift
struct User: DomainModel, ArchitecturalDNA {
    let id: User.ID
    let name: String
    let email: EmailAddress
    let status: UserStatus
    
    // Generated validation method
    func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        if !validateName() {
            issues.append(.businessRuleViolation("Name must not be empty"))
        }
        
        if !validateEmail() {
            issues.append(.businessRuleViolation("Email must be valid format"))
        }
        
        return ValidationResult(issues: issues)
    }
    
    // Generated business rules collection
    func businessRules() -> [BusinessRule] {
        [
            BusinessRule(name: "Name must not be empty", validator: validateName),
            BusinessRule(name: "Email must be valid format", validator: validateEmail)
        ]
    }
    
    // Generated immutable update methods
    func withUpdatedName(_ newName: String) -> Result<User, DomainError> {
        let updated = User(id: id, name: newName, email: email, status: status)
        let validation = updated.validate()
        return validation.isValid ? .success(updated) : .failure(.validationFailed(validation))
    }
    
    func withUpdatedEmail(_ newEmail: EmailAddress) -> Result<User, DomainError> {
        let updated = User(id: id, name: name, email: newEmail, status: status)
        let validation = updated.validate()
        return validation.isValid ? .success(updated) : .failure(.validationFailed(validation))
    }
    
    func withUpdatedStatus(_ newStatus: UserStatus) -> Result<User, DomainError> {
        let updated = User(id: id, name: name, email: email, status: newStatus)
        let validation = updated.validate()
        return validation.isValid ? .success(updated) : .failure(.validationFailed(validation))
    }
    
    // Generated Architectural DNA
    var componentId: ComponentID { ComponentID("User-DomainModel") }
    var purpose: ComponentPurpose {
        ComponentPurpose(
            domain: .userManagement,
            responsibility: .identity,
            businessValue: .enablesUserTracking,
            userImpact: .essential
        )
    }
    var constraints: [ArchitecturalConstraint] {
        [.immutableValueObject, .businessLogicEmbedded, .domainValidation]
    }
}
```

### 4. @CrossCutting Macro

#### Purpose
Enable supervised cross-cutting concerns while maintaining architectural isolation.

#### Usage
```swift
@CrossCutting(.analytics, .logging, .errorReporting)
struct UserProfileContext: AxiomContext {
    func updateUserProfile() async throws {
        // Cross-cutting services automatically available
        analytics.track("profile_updated")
        logger.info("User profile update initiated")
        
        do {
            try await performUpdate()
        } catch {
            errorReporting.report(error)
            throw error
        }
    }
}
```

#### Generated Code
```swift
struct UserProfileContext: AxiomContext {
    private let _analytics: AnalyticsService
    private let _logger: LoggingService
    private let _errorReporting: ErrorReportingService
    
    var analytics: AnalyticsService { _analytics }
    var logger: LoggingService { _logger }
    var errorReporting: ErrorReportingService { _errorReporting }
    
    init(
        analytics: AnalyticsService,
        logger: LoggingService,
        errorReporting: ErrorReportingService
    ) {
        self._analytics = analytics
        self._logger = logger
        self._errorReporting = errorReporting
    }
    
    func updateUserProfile() async throws {
        // Generated automatic tracking
        analytics.track("profile_updated", metadata: [
            "context": "UserProfileContext",
            "method": "updateUserProfile"
        ])
        logger.info("User profile update initiated", context: "UserProfileContext")
        
        do {
            try await performUpdate()
            analytics.track("profile_update_success")
        } catch {
            analytics.track("profile_update_error", error: error)
            errorReporting.report(error, context: "UserProfileContext.updateUserProfile")
            throw error
        }
    }
}
```

### 5. @IntelligenceEnabled Macro

#### Purpose
Integrate intelligence features with automatic configuration and performance monitoring.

#### Usage
```swift
@IntelligenceEnabled([.architecturalDNA, .performanceOptimization, .patternDetection])
actor UserClient: AxiomClient {
    func createUser(_ user: User) async throws -> User {
        // Intelligence features automatically applied
        return try await performIntelligentOperation {
            try await performUserCreation(user)
        }
    }
}
```

#### Generated Code
```swift
actor UserClient: AxiomClient, IntelligenceEnabled {
    private let _intelligence: AxiomIntelligence
    
    var intelligence: AxiomIntelligence { _intelligence }
    var enabledFeatures: Set<IntelligenceFeature> {
        get { _intelligence.enabledFeatures }
        set { _intelligence.enabledFeatures = newValue }
    }
    
    init(intelligence: AxiomIntelligence) {
        self._intelligence = intelligence
        self._intelligence.enabledFeatures = [.architecturalDNA, .performanceOptimization, .patternDetection]
    }
    
    func createUser(_ user: User) async throws -> User {
        return try await performIntelligentOperation {
            // Pre-operation intelligence
            if enabledFeatures.contains(.performanceOptimization) {
                await intelligence.optimizeBeforeOperation(self, operation: "createUser")
            }
            
            if enabledFeatures.contains(.patternDetection) {
                await intelligence.recordOperationPattern(self, operation: "createUser", parameters: [user])
            }
            
            // Original operation
            let result = try await performUserCreation(user)
            
            // Post-operation intelligence
            if enabledFeatures.contains(.performanceOptimization) {
                await intelligence.optimizeAfterOperation(self, operation: "createUser", result: result)
            }
            
            return result
        }
    }
    
    private func performIntelligentOperation<T>(_ operation: () async throws -> T) async throws -> T {
        let startTime = Date()
        
        do {
            let result = try await operation()
            
            // Record successful operation for learning
            if enabledFeatures.contains(.architecturalDNA) {
                await intelligence.recordSuccessfulOperation(
                    component: self,
                    duration: Date().timeIntervalSince(startTime),
                    result: result
                )
            }
            
            return result
        } catch {
            // Record failed operation for learning
            if enabledFeatures.contains(.architecturalDNA) {
                await intelligence.recordFailedOperation(
                    component: self,
                    duration: Date().timeIntervalSince(startTime),
                    error: error
                )
            }
            
            throw error
        }
    }
}
```

## 🔧 Macro Utilities and Diagnostics

### Diagnostic Messages
```swift
enum ClientMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnAxiomContext = "@Client can only be used on AxiomContext conforming types"
    case invalidClientType = "Client type must conform to AxiomClient protocol"
    case duplicateClientProperty = "Multiple @Client properties with the same type are not allowed"
    
    var message: String { rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}
```

### Macro Validation Utilities
```swift
struct MacroValidationUtilities {
    static func validateAxiomContextConformance<T: DeclSyntaxProtocol>(
        _ declaration: T,
        in context: MacroExpansionContext
    ) -> Bool {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: MacroValidationError.invalidDeclarationType
            ))
            return false
        }
        
        let conformsToAxiomContext = structDecl.inheritanceClause?.inheritedTypes.contains { inheritedType in
            inheritedType.type.trimmedDescription == "AxiomContext"
        } ?? false
        
        if !conformsToAxiomContext {
            context.diagnose(Diagnostic(
                node: declaration,
                message: MacroValidationError.mustConformToAxiomContext
            ))
            return false
        }
        
        return true
    }
    
    static func extractTypeName(from type: TypeSyntax) -> String {
        type.trimmedDescription
    }
    
    static func generatePropertyWrapper(
        name: String,
        type: String,
        attributes: [AttributeSyntax] = []
    ) -> VariableDeclSyntax {
        // Generate appropriate property wrapper code
    }
}
```

## 📊 Macro Performance Optimization

### Compilation Performance
```swift
// Optimize macro expansion for large projects
public struct OptimizedClientMacro: PeerMacro {
    // Cache macro expansions to avoid recompilation
    private static var expansionCache: [String: [DeclSyntax]] = [:]
    
    public static func expansion<Declaration: DeclSyntaxProtocol, Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        
        let cacheKey = generateCacheKey(from: declaration)
        
        if let cached = expansionCache[cacheKey] {
            return cached
        }
        
        let result = try performExpansion(of: node, providingPeersOf: declaration, in: context)
        expansionCache[cacheKey] = result
        
        return result
    }
}
```

### Generated Code Optimization
```swift
// Generate optimized code with minimal runtime overhead
struct OptimizedCodeGenerator {
    static func generateClientInjection(for clients: [ClientProperty]) -> [DeclSyntax] {
        // Generate lazy initialization where possible
        // Use static dispatch for known types
        // Minimize memory allocations
        // Cache frequently accessed properties
    }
    
    static func generateCapabilityValidation(for capabilities: [Capability]) -> [DeclSyntax] {
        // Generate compile-time capability validation where possible
        // Use capability caching for runtime validation
        // Batch capability requests for efficiency
        // Generate fallback code for capability failures
    }
}
```

## 🧪 Macro Testing Framework

### Macro Unit Testing
```swift
@Test("@Client macro generates correct dependency injection")
func testClientMacroGeneration() throws {
    let source = """
    struct TestContext: AxiomContext {
        @Client var userClient: UserClient
        @Client var orderClient: OrderClient
    }
    """
    
    let expanded = try expandMacro(source, macros: ["Client": ClientMacro.self])
    
    #expect(expanded.contains("private let _userClient: UserClient"))
    #expect(expanded.contains("private let _orderClient: OrderClient"))
    #expect(expanded.contains("var userClient: UserClient { _userClient }"))
    #expect(expanded.contains("await userClient.addObserver(self)"))
}

@Test("@Capabilities macro validates capability requirements")
func testCapabilitiesMacroValidation() throws {
    let source = """
    @Capabilities([.network, .keychain])
    actor TestClient: AxiomClient {
        func operation() async throws { }
    }
    """
    
    let expanded = try expandMacro(source, macros: ["Capabilities": CapabilitiesMacro.self])
    
    #expect(expanded.contains("static var requiredCapabilities: Set<Capability>"))
    #expect(expanded.contains("[.network, .keychain]"))
    #expect(expanded.contains("try capabilityManager.validate(capability)"))
}
```

### Macro Integration Testing
```swift
@Test("Complete macro integration in real context")
func testCompleteMacroIntegration() async throws {
    @Capabilities([.network])
    actor TestClient: AxiomClient {
        struct State: Sendable { var data: String = "" }
        
        func performOperation() async throws {
            try capabilities.validate(.network)
        }
    }
    
    struct TestContext: AxiomContext {
        @Client var testClient: TestClient
        
        func performContextOperation() async throws {
            try await testClient.performOperation()
        }
    }
    
    let client = TestClient(capabilityManager: MockCapabilityManager())
    let context = TestContext(testClient: client)
    
    // Should compile and work without issues
    try await context.performContextOperation()
}
```

## 📋 Macro Development Roadmap

### Phase 1: Core Macros (Month 1-2)
- [ ] **@Client Macro**: Basic dependency injection
- [ ] **@Capabilities Macro**: Capability validation
- [ ] **Basic Testing**: Unit tests for core macros

### Phase 2: Advanced Macros (Month 3-4)
- [ ] **@DomainModel Macro**: Domain model generation
- [ ] **@CrossCutting Macro**: Cross-cutting concern injection
- [ ] **Integration Testing**: Complete macro integration tests

### Phase 3: Intelligence Macros (Month 5-6)
- [ ] **@IntelligenceEnabled Macro**: Intelligence feature integration
- [ ] **Performance Optimization**: Macro compilation optimization
- [ ] **Comprehensive Testing**: Full macro test suite

---

**MACRO SYSTEM STATUS**: Complete specification with implementation details  
**DEVELOPER EXPERIENCE**: Comprehensive boilerplate elimination while maintaining type safety  
**ARCHITECTURAL ENFORCEMENT**: Compile-time validation of all architectural constraints  
**IMPLEMENTATION READINESS**: Ready for systematic macro development