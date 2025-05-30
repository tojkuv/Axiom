# Axiom Framework: Domain Model Design Patterns

## 🎯 Core Domain Model Constraints

Based on architectural analysis and requirements clarification:

### **Fundamental Rules**
1. **Not all clients have domain models** - Infrastructure clients exist without domain models
2. **1:1 Domain-Client Relationship** - Each domain model is owned by exactly one client
3. **Domain Models as Value Objects** - Immutable structs with embedded business logic
4. **Cross-Domain References via IDs** - No direct object references between domains
5. **Context Orchestration** - Contexts coordinate cross-domain operations

## 🏗️ Client Type Classification

### Domain Clients (Own Domain Models)
**Purpose**: Manage specific business entities and their related operations

```swift
// ✅ Domain Client Example
actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User]        // Owns User domain model
        var currentUserId: User.ID?
    }
    
    // Domain operations
    func createUser(_ user: User) async throws
    func updateUser(_ user: User) async throws  
    func getUser(id: User.ID) -> User?
    func validateUser(_ user: User) -> ValidationResult
}
```

**Examples**: UserClient, OrderClient, ProductClient, MessageClient, AccountClient

### Infrastructure Clients (No Domain Models)
**Purpose**: Provide access to system capabilities and services

```swift
// ✅ Infrastructure Client Example  
actor NetworkClient: AxiomClient {
    struct State: Sendable {
        var connectionStatus: ConnectionStatus
        var requestQueue: [NetworkRequest]
        var activeRequests: Set<UUID>
        // No domain model - pure infrastructure
    }
    
    // Infrastructure operations
    func makeRequest<T>(_ request: NetworkRequest) async throws -> T
    func uploadData(_ data: Data, to url: URL) async throws
    func downloadFile(from url: URL) async throws -> Data
}
```

**Examples**: NetworkClient, DatabaseClient, CacheClient, NotificationClient, LocationClient, CameraClient, BiometricClient

## 📐 Domain Model Design Patterns

### Pattern 1: Domain Model Value Objects

**Core Principles**:
- Immutable structs implementing `DomainModel` protocol
- Embedded business logic as methods
- Value semantics for safe sharing
- Strong typing with domain-specific types

```swift
protocol DomainModel: Sendable, Identifiable, Codable {
    associatedtype ID: Hashable & Sendable & Codable
    var id: ID { get }
    
    // Domain validation
    func validate() -> ValidationResult
}

struct User: DomainModel {
    struct ID: Hashable, Sendable, Codable {
        let value: UUID
    }
    
    let id: ID
    let name: String
    let email: EmailAddress  // Strong typing
    let status: UserStatus
    let createdAt: Date
    let lastLoginAt: Date?
    
    // Domain business logic embedded
    func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        if name.isEmpty {
            issues.append(.emptyName)
        }
        
        if !email.isValid {
            issues.append(.invalidEmail)
        }
        
        return ValidationResult(issues: issues)
    }
    
    func canPlaceOrder() -> Bool {
        status == .active && validate().isValid
    }
    
    func canAccessPremiumFeatures() -> Bool {
        status == .premium || status == .admin
    }
    
    // Immutable updates
    func withUpdatedEmail(_ newEmail: EmailAddress) -> Result<User, ValidationError> {
        let updated = User(
            id: id,
            name: name, 
            email: newEmail,
            status: status,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
        
        let validation = updated.validate()
        return validation.isValid ? .success(updated) : .failure(.invalid(validation))
    }
    
    func withLastLogin(_ date: Date) -> User {
        User(id: id, name: name, email: email, status: status, 
             createdAt: createdAt, lastLoginAt: date)
    }
}
```

### Pattern 2: Domain Client Operations

**Core Principles**:
- Single domain model ownership per client
- Domain operations through client APIs
- State snapshots for read access
- Atomic state updates

```swift
actor UserClient: AxiomClient {
    struct State: Sendable {
        var users: [User.ID: User]
        var currentUserId: User.ID?
        
        // Computed properties for common queries
        var currentUser: User? {
            guard let id = currentUserId else { return nil }
            return users[id]
        }
        
        var activeUsers: [User] {
            users.values.filter { $0.status == .active }
        }
    }
    
    private var _state = State(users: [:], currentUserId: nil)
    var stateSnapshot: State { _state }
    
    // MARK: - Domain Operations
    
    func createUser(name: String, email: EmailAddress) async throws -> User {
        let user = User(
            id: User.ID(value: UUID()),
            name: name,
            email: email,
            status: .active,
            createdAt: Date(),
            lastLoginAt: nil
        )
        
        let validation = user.validate()
        guard validation.isValid else {
            throw UserError.validationFailed(validation)
        }
        
        _state.users[user.id] = user
        notifyObservers()
        
        return user
    }
    
    func updateUser(_ user: User) async throws {
        let validation = user.validate()
        guard validation.isValid else {
            throw UserError.validationFailed(validation)
        }
        
        guard _state.users[user.id] != nil else {
            throw UserError.userNotFound
        }
        
        _state.users[user.id] = user
        notifyObservers()
    }
    
    func getUser(id: User.ID) -> User? {
        stateSnapshot.users[id]
    }
    
    func setCurrentUser(_ userId: User.ID) async throws {
        guard _state.users[userId] != nil else {
            throw UserError.userNotFound
        }
        
        _state.currentUserId = userId
        
        // Update last login
        if let user = _state.users[userId] {
            let updatedUser = user.withLastLogin(Date())
            _state.users[userId] = updatedUser
        }
        
        notifyObservers()
    }
    
    func validateUserForOrdering(id: User.ID) -> Bool {
        guard let user = getUser(id: id) else { return false }
        return user.canPlaceOrder()
    }
}
```

### Pattern 3: Cross-Domain References

**Core Principles**:
- Use ID-based references between domain models
- No direct object references across client boundaries
- Context orchestration for cross-domain operations

```swift
struct Order: DomainModel {
    struct ID: Hashable, Sendable, Codable {
        let value: UUID
    }
    
    let id: ID
    let userId: User.ID           // ✅ ID-based reference
    let items: [OrderItem]
    let status: OrderStatus
    let createdAt: Date
    let totalAmount: Money
    
    func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        if items.isEmpty {
            issues.append(.emptyOrder)
        }
        
        if totalAmount.amount <= 0 {
            issues.append(.invalidAmount)
        }
        
        return ValidationResult(issues: issues)
    }
    
    func canBeCancelled() -> Bool {
        status == .pending || status == .confirmed
    }
    
    func withStatus(_ newStatus: OrderStatus) -> Order {
        Order(id: id, userId: userId, items: items, 
              status: newStatus, createdAt: createdAt, totalAmount: totalAmount)
    }
}

actor OrderClient: AxiomClient {
    struct State: Sendable {
        var orders: [Order.ID: Order]    // Owns Order domain model
        var ordersByUser: [User.ID: Set<Order.ID>]
    }
    
    func getOrdersForUser(_ userId: User.ID) -> [Order] {
        guard let orderIds = stateSnapshot.ordersByUser[userId] else { return [] }
        return orderIds.compactMap { stateSnapshot.orders[$0] }
    }
    
    func createOrder(userId: User.ID, items: [OrderItem]) async throws -> Order {
        let order = Order(
            id: Order.ID(value: UUID()),
            userId: userId,           // ✅ Store user ID, not user object
            items: items,
            status: .pending,
            createdAt: Date(),
            totalAmount: calculateTotal(items)
        )
        
        let validation = order.validate()
        guard validation.isValid else {
            throw OrderError.validationFailed(validation)
        }
        
        _state.orders[order.id] = order
        _state.ordersByUser[userId, default: []].insert(order.id)
        notifyObservers()
        
        return order
    }
}
```

### Pattern 4: Context Cross-Domain Orchestration

**Core Principles**:
- Contexts coordinate operations across multiple domain clients
- Business workflows implemented in contexts
- Domain validation before cross-domain operations

```swift
struct CheckoutContext: AxiomContext {
    typealias View = CheckoutView
    
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient  
    @Client var cartClient: CartClient
    @Client var paymentClient: PaymentClient
    @Client var inventoryClient: InventoryClient
    
    // Cross-domain orchestration
    func processCheckout() async throws -> Order {
        // 1. Validate user can place order
        guard let currentUser = userClient.stateSnapshot.currentUser else {
            throw CheckoutError.noCurrentUser
        }
        
        guard currentUser.canPlaceOrder() else {
            throw CheckoutError.userCannotOrder
        }
        
        // 2. Get current cart
        let cart = cartClient.stateSnapshot.currentCart
        guard !cart.items.isEmpty else {
            throw CheckoutError.emptyCart
        }
        
        // 3. Validate inventory
        for item in cart.items {
            let available = inventoryClient.getAvailableQuantity(productId: item.productId)
            guard available >= item.quantity else {
                throw CheckoutError.insufficientInventory(item.productId)
            }
        }
        
        // 4. Create order
        let order = try await orderClient.createOrder(
            userId: currentUser.id,
            items: cart.items
        )
        
        // 5. Process payment
        try await paymentClient.processPayment(
            orderId: order.id,
            amount: order.totalAmount,
            userId: currentUser.id
        )
        
        // 6. Update inventory
        for item in cart.items {
            try await inventoryClient.decrementStock(
                productId: item.productId, 
                quantity: item.quantity
            )
        }
        
        // 7. Clear cart
        await cartClient.clearCart()
        
        // 8. Update order status
        let confirmedOrder = order.withStatus(.confirmed)
        try await orderClient.updateOrder(confirmedOrder)
        
        return confirmedOrder
    }
    
    // Cross-domain queries
    var orderHistoryWithUsers: [(Order, User)] {
        let orders = orderClient.stateSnapshot.orders.values
        return orders.compactMap { order in
            guard let user = userClient.getUser(id: order.userId) else { return nil }
            return (order, user)
        }
    }
}
```

## 🎯 AI Agent Code Generation Patterns

### Domain Model Template
```swift
struct {{DomainModelName}}: DomainModel {
    struct ID: Hashable, Sendable, Codable {
        let value: UUID
    }
    
    let id: ID
    {{#properties}}
    let {{propertyName}}: {{propertyType}}
    {{/properties}}
    
    func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        {{#validationRules}}
        {{validationLogic}}
        {{/validationRules}}
        return ValidationResult(issues: issues)
    }
    
    {{#businessMethods}}
    func {{methodName}}({{parameters}}) -> {{returnType}} {
        {{businessLogic}}
    }
    {{/businessMethods}}
    
    {{#immutableUpdates}}
    func with{{PropertyName}}(_ new{{PropertyName}}: {{PropertyType}}) -> {{DomainModelName}} {
        {{DomainModelName}}({{constructorParameters}})
    }
    {{/immutableUpdates}}
}
```

### Domain Client Template
```swift
actor {{DomainModelName}}Client: AxiomClient {
    struct State: Sendable {
        var {{domainModelPluralLowercase}}: [{{DomainModelName}}.ID: {{DomainModelName}}]
        {{#additionalStateProperties}}
        var {{propertyName}}: {{propertyType}}
        {{/additionalStateProperties}}
    }
    
    private var _state = State({{domainModelPluralLowercase}}: [:])
    var stateSnapshot: State { _state }
    
    {{#crudOperations}}
    func {{operationName}}({{parameters}}) async throws -> {{returnType}} {
        {{operationImplementation}}
    }
    {{/crudOperations}}
    
    {{#domainQueries}}
    func {{queryName}}({{parameters}}) -> {{returnType}} {
        {{queryImplementation}}
    }
    {{/domainQueries}}
}
```

## 📊 Domain Architecture Benefits

### For AI Development
- **Predictable Patterns**: Clear templates for domain models and clients
- **Systematic Generation**: 1:1 domain-client mapping simplifies code generation
- **Consistent Structure**: All domain models follow the same patterns
- **Cross-Domain Coordination**: Standard context orchestration patterns

### For Application Architecture
- **Clear Ownership**: Each domain model has exactly one owning client
- **Type Safety**: Strong typing with domain-specific types
- **Business Logic Centralization**: Domain logic embedded in models
- **Cross-Domain Safety**: ID-based references prevent coupling

### For Maintenance
- **Isolated Changes**: Domain changes isolated to single client
- **Predictable Impact**: Cross-domain effects managed through contexts
- **Testing**: Domain models easily unit testable
- **Evolution**: Clear patterns for extending domain functionality

---

**DESIGN STATUS**: Core domain patterns established  
**NEXT**: Define domain aggregate boundary rules and validation patterns  
**AI IMPACT**: Enables systematic domain model and client generation  
**ARCHITECTURAL CONSTRAINT**: 1:1 domain model to client relationship maintained