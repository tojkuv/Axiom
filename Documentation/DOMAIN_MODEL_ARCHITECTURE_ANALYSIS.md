# Axiom Framework: Domain Model Architecture Analysis

## 🎯 Critical Architectural Gap Identified

Domain models are a fundamental component of any real-world application that was not properly addressed in the initial Axiom architecture. This analysis explores how domain models, business logic, and cross-entity relationships can be integrated within the View-Context-Client constraint system.

## 🏗️ Current Architecture Constraints

### Existing Flow
**Views → Contexts → Clients → Capabilities → System**

### Core Constraints (Must Preserve)
- ✅ **Client Isolation**: Clients can only access their own state
- ✅ **No Shared Mutable State**: Between clients
- ✅ **Context Orchestration**: Contexts orchestrate but don't mutate client state directly
- ✅ **Unidirectional Flow**: Dependencies flow in one direction
- ✅ **Actor Safety**: Thread isolation through Swift actors

## 🏢 Domain Model Challenges

### 1. Business Entity Placement
**Question**: Where do domain models like User, Product, Order, Message live?

**Challenges**:
- Domain models represent core business concepts
- Often referenced across multiple parts of the application
- Contain business logic and validation rules
- Have relationships with other domain models

### 2. Cross-Client Relationships
**Real-World Scenario**:
```
User (UserClient)
├── Orders (OrderClient) 
├── Messages (MessageClient)
├── Profile (ProfileClient)
└── Preferences (PreferencesClient)
```

**Challenge**: How does OrderClient access User information while maintaining client isolation?

### 3. Business Logic Placement
**Question**: Where does domain logic live?
- Validation rules
- Business calculations  
- Domain services
- Business workflows

### 4. Data Consistency
**Challenge**: Maintaining consistency across related entities managed by different clients
- User updates affecting Orders
- Profile changes affecting Messages
- Account state affecting multiple domains

## 🎨 Architectural Approach Analysis

### Approach A: Domain Models as Client State
```swift
actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User] // Domain model in client state
        var currentUser: User?
    }
    
    // Domain logic within client
    func validateUser(_ user: User) -> ValidationResult {
        // Business validation logic
    }
    
    func updateUser(_ user: User) async throws {
        let validated = validateUser(user)
        guard validated.isValid else { throw validated.error }
        _state.users[user.id] = user
    }
}

struct User: Sendable {
    let id: UUID
    let name: String
    let email: String
    
    // Domain logic as methods?
    func isValidEmail() -> Bool { /* validation */ }
}
```

**Pros**:
- ✅ Maintains client isolation
- ✅ Clear ownership of domain data
- ✅ Fits current architectural constraints

**Cons**:
- ❌ Business logic scattered across multiple clients  
- ❌ Difficult to share domain logic
- ❌ Cross-client relationships challenging
- ❌ Domain logic mixed with data access logic

### Approach B: Domain Aggregates = Client Boundaries  
```swift
// Each client represents a domain aggregate root
actor UserAggregateClient: AxiomClient {
    struct State: Sendable {
        var user: User
        var profile: UserProfile
        var preferences: UserPreferences
        // Complete user aggregate
    }
}

actor OrderAggregateClient: AxiomClient {
    struct State: Sendable {
        var orders: [Order]
        var orderItems: [OrderItem]
        var payments: [Payment]
        // Complete order aggregate
    }
}
```

**Pros**:
- ✅ Follows Domain-Driven Design principles
- ✅ Clear aggregate boundaries
- ✅ Maintains client isolation
- ✅ Business logic contained within aggregates

**Cons**:
- ❌ May create very large clients
- ❌ Still challenges with cross-aggregate references
- ❌ Aggregate boundaries might not align with UI needs

### Approach C: Domain Models as Value Objects + Domain Services
```swift
// Immutable domain models with behavior
struct User: DomainModel {
    let id: UUID
    let name: String
    let email: String
    
    // Domain logic as pure functions
    func withUpdatedEmail(_ email: String) -> Result<User, ValidationError> {
        guard EmailValidator.isValid(email) else {
            return .failure(.invalidEmail)
        }
        return .success(User(id: id, name: name, email: email))
    }
    
    func canPlaceOrder() -> Bool {
        // Domain business rules
    }
}

// Stateless domain services
struct UserDomainService {
    static func validateUserForOrdering(_ user: User) -> ValidationResult {
        // Complex domain logic
    }
    
    static func calculateUserTier(_ user: User, orders: [Order]) -> UserTier {
        // Cross-aggregate domain logic
    }
}

actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User]
    }
    
    func updateUser(_ updatedUser: User) async throws {
        let result = updatedUser.withUpdatedEmail(updatedUser.email)
        switch result {
        case .success(let validUser):
            _state.users[validUser.id] = validUser
        case .failure(let error):
            throw error
        }
    }
}
```

**Pros**:
- ✅ Centralized domain logic
- ✅ Domain models are immutable value objects
- ✅ Clear separation of concerns
- ✅ Reusable domain services
- ✅ Fits client isolation model

**Cons**:
- ❌ Static methods less discoverable
- ❌ Domain services might become god objects
- ❌ Cross-aggregate operations still challenging

### Approach D: Enhanced Context Orchestration with Domain Coordination
```swift
// Domain models as value objects
struct User: DomainModel, Sendable {
    let id: UUID
    let name: String
    let email: String
    
    func validate() -> ValidationResult { /* domain logic */ }
    func withUpdatedEmail(_ email: String) -> User { /* immutable update */ }
}

// Clients own their domain state
actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User]
    }
    
    func getUser(id: User.ID) -> User? {
        stateSnapshot.users[id]
    }
    
    func updateUser(_ user: User) async throws {
        let validated = user.validate()
        guard validated.isValid else { throw validated.error }
        _state.users[user.id] = user
        notifyObservers() // Triggers context updates
    }
}

// Contexts coordinate cross-domain operations
struct OrderContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient
    @Client var paymentClient: PaymentClient
    
    func placeOrder(items: [OrderItem], userId: User.ID) async throws {
        // Context orchestrates cross-domain operation
        guard let user = userClient.getUser(id: userId) else {
            throw OrderError.userNotFound
        }
        
        guard user.canPlaceOrder() else {
            throw OrderError.userCannotOrder
        }
        
        let order = Order(userId: userId, items: items)
        try await orderClient.createOrder(order)
        
        // Potentially update user state through UserClient
        let updatedUser = user.withIncrementedOrderCount()
        try await userClient.updateUser(updatedUser)
    }
}
```

**Pros**:
- ✅ Domain models are immutable value objects with behavior
- ✅ Clients maintain clear ownership
- ✅ Contexts coordinate cross-domain operations naturally
- ✅ Maintains all architectural constraints
- ✅ Business logic is discoverable and centralized in domain models

**Cons**:
- ❌ Contexts become complex coordinators
- ❌ Cross-domain consistency still requires careful design

## 🔄 Cross-Client Relationship Patterns

### Pattern 1: ID-Based References
```swift
struct Order: DomainModel {
    let id: UUID
    let userId: User.ID // Reference by ID, not object
    let items: [OrderItem]
}

// Context resolves relationships
struct OrderDetailContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient
    
    var orderWithUser: (Order, User)? {
        guard let order = orderClient.currentOrder,
              let user = userClient.getUser(id: order.userId) else {
            return nil
        }
        return (order, user)
    }
}
```

### Pattern 2: Data Denormalization
```swift
struct Order: DomainModel {
    let id: UUID
    let userId: User.ID
    let userEmail: String // Denormalized user data
    let userName: String // For order display
    let items: [OrderItem]
}
```

### Pattern 3: Domain Events
```swift
// Domain events for cross-client communication
struct UserUpdatedEvent: DomainEvent {
    let userId: User.ID
    let updatedUser: User
}

actor OrderClient: AxiomClient {
    // Listen for user updates that affect orders
    func handleUserUpdated(_ event: UserUpdatedEvent) async {
        // Update any cached user data in orders
    }
}

// Application Context coordinates domain events
struct ApplicationContext: AxiomApplicationContext {
    func handleDomainEvent(_ event: DomainEvent) {
        // Route events to interested clients
    }
}
```

## 🏛️ Recommended Architecture: Enhanced Value Objects with Context Orchestration

### Core Principles
1. **Domain Models as Immutable Value Objects** with embedded business logic
2. **Client Ownership** of domain aggregates based on clear boundaries
3. **Context Orchestration** for cross-domain operations and consistency
4. **ID-Based References** for cross-client relationships
5. **Domain Events** for loose coupling between domain boundaries

### Architectural Flow
```
Views → Contexts → [Domain Coordination] → Clients → [Domain Models] → Capabilities
```

### Example Implementation Pattern
```swift
// 1. Domain Model as Value Object
struct User: DomainModel, Sendable {
    let id: UUID
    let name: String
    let email: String
    let status: UserStatus
    
    // Domain logic embedded
    func validate() -> ValidationResult
    func canPlaceOrder() -> Bool
    func withUpdatedEmail(_ email: String) -> Result<User, ValidationError>
    func withIncrementedOrderCount() -> User
}

// 2. Client owns domain aggregate
actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User]
        var currentUserId: User.ID?
    }
    
    // Domain operations
    func updateUser(_ user: User) async throws
    func getUser(id: User.ID) -> User?
    func validateUserForOrdering(id: User.ID) -> Bool
}

// 3. Context orchestrates cross-domain operations
struct CheckoutContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var cartClient: CartClient
    @Client var orderClient: OrderClient
    @Client var paymentClient: PaymentClient
    
    func processCheckout() async throws {
        guard let user = userClient.getCurrentUser(),
              user.canPlaceOrder() else {
            throw CheckoutError.userCannotOrder
        }
        
        let cart = cartClient.getCurrentCart()
        let order = try await orderClient.createOrder(from: cart, user: user)
        try await paymentClient.processPayment(for: order)
        
        // Update user after successful order
        let updatedUser = user.withIncrementedOrderCount()
        try await userClient.updateUser(updatedUser)
    }
}
```

## 🎯 AI Agent Implications

### Pattern Predictability (High Priority for AI)
1. **Domain Model Structure**: Consistent value object patterns
2. **Client Boundaries**: Clear mapping between aggregates and clients  
3. **Cross-Domain Operations**: Standard context orchestration patterns
4. **Business Logic Placement**: Predictable embedding in domain models

### Code Generation Benefits
- **Domain Models**: Template-based generation with business logic placeholders
- **Client Operations**: Standard CRUD + domain-specific operations
- **Context Orchestration**: Pattern-based cross-domain operation generation
- **Validation**: Consistent validation patterns across all domain models

### Development Velocity Impact
- **Faster Domain Modeling**: Clear patterns for business logic placement
- **Predictable Relationships**: Standard ID-based reference patterns
- **Consistent Operations**: Template-based client and context generation
- **Cross-Domain Coordination**: Reusable orchestration patterns

## 🔍 Open Questions for Further Analysis

### 1. Domain Aggregate Boundaries
**Question**: How do we systematically determine client boundaries?
- By UI concerns?
- By business aggregate roots?
- By data access patterns?
- Hybrid approach?

### 2. Complex Domain Logic
**Question**: Where do complex business workflows live?
- Multi-step processes involving multiple aggregates
- Long-running business operations  
- Complex validation across multiple domains

### 3. Domain Event Architecture
**Question**: How should domain events be structured?
- Event sourcing patterns?
- Simple notification events?
- Application Context as event bus?
- Domain event store?

### 4. Performance Implications
**Question**: How do cross-domain operations affect performance?
- Multiple client coordination overhead
- Context complexity for orchestration
- Memory usage for denormalized data
- Snapshot coordination costs

## 📋 Next Steps for Domain Architecture Design

1. **Define Domain Aggregate Mapping**: Clear rules for client boundary definition
2. **Cross-Domain Communication Patterns**: Standardize relationship handling
3. **Business Logic Placement Guidelines**: Where different types of domain logic live
4. **Domain Event Architecture**: If needed for complex cross-domain scenarios
5. **Performance Validation**: Ensure domain patterns meet performance targets

---

**ANALYSIS STATUS**: Domain architecture gap identified and analyzed  
**RECOMMENDATION**: Enhanced Value Objects with Context Orchestration approach  
**NEXT**: Design specific patterns for domain aggregates and cross-domain operations  
**AI AGENT IMPACT**: Requires new code generation patterns for domain models and orchestration