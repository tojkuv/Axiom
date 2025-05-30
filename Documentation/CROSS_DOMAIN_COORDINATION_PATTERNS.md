# Axiom Framework: Cross-Domain Coordination Patterns

## 🎯 Core Constraint: No Cross-Domain Communication

**Critical Architectural Principle**: Domain clients do not communicate with each other. All cross-domain coordination happens exclusively through Context orchestration, maintaining strict unidirectional flow.

## 🏗️ Unidirectional Flow for Domains

### Extended Architecture Flow
```
Views → Contexts → [Domain Clients] → Capabilities → System
                     ↑
              No lateral communication
              All coordination via Context
```

### Core Rules
- ✅ **Domain clients are isolated** - Cannot access other domain clients
- ✅ **ID-based references only** - Domain models reference other domains by ID
- ✅ **Context orchestration** - All cross-domain operations happen in contexts
- ✅ **Read-only snapshot access** - Contexts can read from multiple clients
- ❌ **No client-to-client communication** - Maintains strict isolation
- ❌ **No domain events between clients** - No lateral data flow

## 📐 Cross-Domain Coordination Patterns

### Pattern 1: ID-Based References (Read-Only)

**Principle**: Domain models reference other domains by ID only, never by object reference.

```swift
// ✅ CORRECT: ID-based reference
struct Order: DomainModel {
    let id: Order.ID
    let userId: User.ID           // ✅ Reference by ID only
    let items: [OrderItem]
    let status: OrderStatus
    let totalAmount: Money
    
    // ❌ FORBIDDEN: Direct object reference
    // let user: User            // Would violate isolation
}

// ✅ CORRECT: Context resolves relationships
struct OrderDetailContext: AxiomContext {
    @Client var orderClient: OrderClient
    @Client var userClient: UserClient
    
    // Context can read from multiple clients
    var orderWithUser: (Order, User)? {
        guard let order = orderClient.stateSnapshot.currentOrder,
              let user = userClient.getUser(id: order.userId) else {
            return nil
        }
        return (order, user)
    }
}
```

### Pattern 2: Context-Orchestrated Operations

**Principle**: Any operation involving multiple domains is orchestrated by the Context.

```swift
struct CheckoutContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var cartClient: CartClient
    @Client var orderClient: OrderClient
    @Client var inventoryClient: InventoryClient
    @Client var paymentClient: PaymentClient
    
    // ✅ CORRECT: Context orchestrates cross-domain operation
    func processCheckout() async throws -> Order {
        // 1. Read from multiple clients (read-only snapshots)
        guard let user = userClient.stateSnapshot.currentUser else {
            throw CheckoutError.noCurrentUser
        }
        
        let cart = cartClient.stateSnapshot.currentCart
        guard !cart.items.isEmpty else {
            throw CheckoutError.emptyCart
        }
        
        // 2. Validate business rules (using domain model logic)
        guard user.canPlaceOrder() else {
            throw CheckoutError.userCannotOrder
        }
        
        // 3. Check inventory across all items
        for item in cart.items {
            let available = inventoryClient.getAvailableQuantity(productId: item.productId)
            guard available >= item.quantity else {
                throw CheckoutError.insufficientInventory(item.productId)
            }
        }
        
        // 4. Orchestrate the transaction across multiple clients
        let order = try await orderClient.createOrder(
            userId: user.id,
            items: cart.items
        )
        
        try await paymentClient.processPayment(
            orderId: order.id,
            amount: order.totalAmount,
            userId: user.id
        )
        
        // 5. Update inventory
        for item in cart.items {
            try await inventoryClient.decrementStock(
                productId: item.productId,
                quantity: item.quantity
            )
        }
        
        // 6. Clear cart and confirm order
        await cartClient.clearCart()
        let confirmedOrder = order.withStatus(.confirmed)
        try await orderClient.updateOrder(confirmedOrder)
        
        return confirmedOrder
    }
}
```

### Pattern 3: Cross-Domain Queries via Context

**Principle**: Contexts provide computed properties that combine data from multiple clients.

```swift
struct UserProfileContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient
    @Client var reviewClient: ReviewClient
    
    // ✅ CORRECT: Context combines data from multiple clients
    var userProfileData: UserProfileData? {
        guard let user = userClient.stateSnapshot.currentUser else { return nil }
        
        let orders = orderClient.getOrdersForUser(user.id)
        let reviews = reviewClient.getReviewsForUser(user.id)
        
        return UserProfileData(
            user: user,
            totalOrders: orders.count,
            totalSpent: orders.map(\.totalAmount).reduce(Money.zero, +),
            averageReviewRating: reviews.map(\.rating).average(),
            memberSince: user.createdAt
        )
    }
    
    var recentActivity: [ActivityItem] {
        guard let user = userClient.stateSnapshot.currentUser else { return [] }
        
        let recentOrders = orderClient.getRecentOrdersForUser(user.id, limit: 5)
        let recentReviews = reviewClient.getRecentReviewsForUser(user.id, limit: 5)
        
        // Combine and sort by timestamp
        var activities: [ActivityItem] = []
        activities.append(contentsOf: recentOrders.map(ActivityItem.order))
        activities.append(contentsOf: recentReviews.map(ActivityItem.review))
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
}

// ✅ Context-specific data transfer object
struct UserProfileData: Sendable {
    let user: User
    let totalOrders: Int
    let totalSpent: Money
    let averageReviewRating: Double
    let memberSince: Date
}
```

### Pattern 4: Sequential Domain Operations

**Principle**: Operations that affect multiple domains are executed sequentially through the Context.

```swift
struct AccountDeletionContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var orderClient: OrderClient
    @Client var reviewClient: ReviewClient
    @Client var messageClient: MessageClient
    @Client var profileClient: ProfileClient
    
    // ✅ CORRECT: Sequential operations across multiple domains
    func deleteUserAccount(userId: User.ID) async throws {
        // 1. Validate user exists and can be deleted
        guard let user = userClient.getUser(id: userId) else {
            throw AccountError.userNotFound
        }
        
        guard user.canBeDeleted() else {
            throw AccountError.cannotDeleteUser
        }
        
        // 2. Sequential cleanup across all related domains
        // Order: Reviews → Messages → Orders → Profile → User
        
        // Delete user reviews
        let userReviews = reviewClient.getReviewsForUser(userId)
        for review in userReviews {
            try await reviewClient.deleteReview(review.id)
        }
        
        // Delete user messages  
        let userMessages = messageClient.getMessagesForUser(userId)
        for message in userMessages {
            try await messageClient.deleteMessage(message.id)
        }
        
        // Cancel pending orders, archive completed orders
        let userOrders = orderClient.getOrdersForUser(userId)
        for order in userOrders {
            if order.canBeCancelled() {
                try await orderClient.cancelOrder(order.id)
            } else {
                try await orderClient.archiveOrder(order.id)
            }
        }
        
        // Delete user profile
        try await profileClient.deleteProfile(userId)
        
        // Finally delete user (marks as deleted, doesn't remove for audit)
        try await userClient.deleteUser(userId)
    }
}
```

### Pattern 5: Conditional Cross-Domain Logic

**Principle**: Business rules that span multiple domains are evaluated in the Context.

```swift
struct PostCreationContext: AxiomContext {
    @Client var userClient: UserClient
    @Client var postClient: PostClient
    @Client var contentModerationClient: ContentModerationClient
    @Client var subscriptionClient: SubscriptionClient
    
    func createPost(content: String, images: [URL]) async throws -> Post {
        // 1. Get user and validate permissions
        guard let user = userClient.stateSnapshot.currentUser else {
            throw PostError.notAuthenticated
        }
        
        guard user.canCreatePosts() else {
            throw PostError.userCannotPost
        }
        
        // 2. Check subscription limits (cross-domain business rule)
        let subscription = subscriptionClient.getSubscription(userId: user.id)
        let userPosts = postClient.getPostsForUser(user.id, createdSince: Date().startOfDay)
        
        guard subscription.canCreateAdditionalPost(existingPostsToday: userPosts.count) else {
            throw PostError.dailyLimitExceeded
        }
        
        // 3. Content moderation check
        let moderationResult = try await contentModerationClient.moderateContent(content)
        guard moderationResult.isApproved else {
            throw PostError.contentRejected(moderationResult.reason)
        }
        
        // 4. Create post with appropriate visibility based on user status
        let visibility: PostVisibility = user.isVerified ? .public : .followersOnly
        
        let post = Post(
            id: Post.ID(value: UUID()),
            authorId: user.id,
            content: content,
            imageURLs: images,
            visibility: visibility,
            createdAt: Date()
        )
        
        return try await postClient.createPost(post)
    }
}
```

## 🚫 Anti-Patterns: What NOT to Do

### ❌ Anti-Pattern 1: Client-to-Client Communication
```swift
// ❌ FORBIDDEN: Direct client access
actor OrderClient: AxiomClient {
    @Client var userClient: UserClient  // ❌ Violates isolation
    
    func createOrder(items: [OrderItem]) async throws -> Order {
        // ❌ Direct access to another client
        let user = userClient.stateSnapshot.currentUser
        // This violates the unidirectional flow constraint
    }
}
```

### ❌ Anti-Pattern 2: Domain Events Between Clients
```swift
// ❌ FORBIDDEN: Domain events between clients
struct UserUpdatedEvent: DomainEvent {
    let user: User
}

actor OrderClient: AxiomClient {
    // ❌ Listening to events from other domains
    func handleUserUpdated(_ event: UserUpdatedEvent) {
        // This creates lateral communication between domains
    }
}
```

### ❌ Anti-Pattern 3: Shared Domain Services
```swift
// ❌ FORBIDDEN: Shared services accessed by multiple clients
class UserValidationService {
    static func validateUser(_ user: User) -> Bool { ... }
}

actor UserClient: AxiomClient {
    func updateUser(_ user: User) async throws {
        UserValidationService.validateUser(user)  // ❌ Shared dependency
    }
}

actor OrderClient: AxiomClient {
    func createOrder(userId: User.ID) async throws {
        UserValidationService.validateUser(user)  // ❌ Shared dependency
    }
}
```

## 🎯 AI Agent Code Generation Guidelines

### Cross-Domain Operation Template
```swift
struct {{ContextName}}: AxiomContext {
    {{#requiredClients}}
    @Client var {{clientName}}: {{ClientType}}
    {{/requiredClients}}
    
    func {{operationName}}({{parameters}}) async throws -> {{returnType}} {
        // 1. Read from required clients (snapshots only)
        {{#dataReads}}
        {{readOperation}}
        {{/dataReads}}
        
        // 2. Validate cross-domain business rules
        {{#validations}}
        {{validationLogic}}
        {{/validations}}
        
        // 3. Execute operations in sequence
        {{#operations}}
        {{operationCall}}
        {{/operations}}
        
        return {{result}}
    }
}
```

### Cross-Domain Query Template
```swift
var {{queryName}}: {{returnType}} {
    {{#dataReads}}
    {{snapshotAccess}}
    {{/dataReads}}
    
    {{#dataProcessing}}
    {{processingLogic}}
    {{/dataProcessing}}
    
    return {{computedResult}}
}
```

## 📊 Benefits of No Cross-Domain Communication

### For Architecture
- **Strict Isolation**: Domain clients remain completely isolated
- **Predictable Flow**: All coordination happens at context level
- **Clear Boundaries**: No ambiguity about where cross-domain logic lives
- **Easier Testing**: Each domain client can be tested in isolation

### For AI Development
- **Pattern Consistency**: All cross-domain operations follow same pattern
- **Systematic Generation**: Contexts become coordination templates
- **Reduced Complexity**: No complex event systems or service dependencies
- **Clear Dependencies**: Context dependencies are explicit and visible

### For Maintenance
- **Single Coordination Point**: Contexts are the only place for cross-domain logic
- **Impact Analysis**: Changes to cross-domain operations are localized to contexts
- **Debugging**: Cross-domain issues are always in contexts, never in clients
- **Evolution**: Adding new domains doesn't affect existing domain clients

---

**COORDINATION PATTERN STATUS**: Cross-domain coordination through Context orchestration only  
**NEXT**: Validate that domain approach maintains all architectural constraints  
**AI IMPACT**: Simplified, systematic patterns for cross-domain operations  
**CONSTRAINT ADHERENCE**: Strict unidirectional flow maintained, no lateral domain communication