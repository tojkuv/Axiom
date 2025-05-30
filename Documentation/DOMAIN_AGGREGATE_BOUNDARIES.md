# Axiom Framework: Domain Aggregate Boundary Analysis

## 🎯 Domain Aggregate Boundary Challenge

With the constraint that each client owns exactly one domain model, we need systematic rules for determining how to map domain aggregates to client boundaries. This analysis establishes principles for making these architectural decisions consistently.

## 🏗️ Core Boundary Principles

### Principle 1: Business Cohesion
**Domain concepts that change together belong in the same client**

Example: User core identity vs User preferences
```swift
// ✅ HIGH COHESION - Same Client
struct User: DomainModel {
    let id: User.ID
    let name: String
    let email: EmailAddress
    let status: UserStatus        // Changes with user
    let createdAt: Date
    let lastLoginAt: Date?       // Changes with user
}

// ❌ LOW COHESION - Consider Separate Client  
struct UserPreferences: DomainModel {
    let userId: User.ID
    let theme: ThemePreference   // Changes independently
    let notifications: NotificationSettings
    let privacy: PrivacySettings
}
```

### Principle 2: UI Boundary Alignment
**Domain models should align with how data is displayed and edited in the UI**

Example: Profile editing vs Notification settings
```swift
// ✅ UI-Aligned - ProfileClient
struct UserProfile: DomainModel {
    let userId: User.ID
    let displayName: String      // Edited together in Profile screen
    let bio: String              // Edited together in Profile screen
    let avatarURL: URL?          // Edited together in Profile screen
    let location: String?        // Edited together in Profile screen
}

// ✅ UI-Aligned - SettingsClient  
struct UserSettings: DomainModel {
    let userId: User.ID
    let notificationPreferences: NotificationSettings  // Settings screen
    let privacySettings: PrivacySettings              // Settings screen
    let appPreferences: AppPreferences                // Settings screen
}
```

### Principle 3: Transaction Boundaries
**Operations that must be atomic belong in the same client**

Example: Order and Order Items
```swift
// ✅ ATOMIC - Same Client
struct Order: DomainModel {
    let id: Order.ID
    let userId: User.ID
    let items: [OrderItem]       // Must be created/updated atomically with order
    let status: OrderStatus
    let totalAmount: Money       // Calculated from items
    let createdAt: Date
}

// ❌ SEPARATE ATOMIC OPERATIONS - Different Client
struct Product: DomainModel {
    let id: Product.ID
    let name: String
    let description: String
    let price: Money             // Updated independently from orders
    let category: ProductCategory
}
```

### Principle 4: Performance and Access Patterns
**Data accessed together frequently should be in the same client**

Example: Message conversation data
```swift
// ✅ ACCESSED TOGETHER - Same Client
struct Conversation: DomainModel {
    let id: Conversation.ID
    let participants: [User.ID]   // Loaded with conversation
    let lastMessage: Message?     // Displayed with conversation list
    let unreadCount: Int         // Displayed with conversation list
    let createdAt: Date
    let updatedAt: Date
}

// ✅ SEPARATE ACCESS PATTERN - Different Client
struct Message: DomainModel {
    let id: Message.ID
    let conversationId: Conversation.ID  // Reference to conversation
    let senderId: User.ID
    let content: String
    let timestamp: Date
    let readBy: [User.ID]
}
```

## 📊 Domain Boundary Decision Framework

### Step 1: Identify Domain Concepts
List all the domain concepts in your application domain

### Step 2: Apply Boundary Principles Matrix
Score each potential grouping against the four principles:

| Grouping | Business Cohesion | UI Alignment | Transaction Boundary | Access Pattern | Total Score |
|----------|------------------|--------------|---------------------|---------------|-------------|
| User + Profile | 8/10 | 9/10 | 7/10 | 9/10 | 33/40 |
| User + Settings | 4/10 | 3/10 | 5/10 | 4/10 | 16/40 |
| Order + Items | 10/10 | 10/10 | 10/10 | 10/10 | 40/40 |

**Decision Rule**: Score ≥ 30/40 → Same Client, Score < 30/40 → Separate Clients

### Step 3: Validate Against Constraints
- Does the client become too large? (>500 lines of domain logic)
- Does it violate single responsibility?
- Can it be easily understood and maintained?

## 🏢 Common iOS Application Domain Boundaries

### User Management Domain

#### UserClient - Core Identity
```swift
struct User: DomainModel {
    let id: User.ID
    let username: String
    let email: EmailAddress
    let status: UserStatus        // active, suspended, deleted
    let accountType: AccountType  // free, premium, admin
    let createdAt: Date
    let lastLoginAt: Date?
    
    // Core identity business logic
    func canAccessPremiumFeatures() -> Bool
    func isActiveUser() -> Bool
    func canBeDeleted() -> Bool
}
```

#### ProfileClient - Extended User Data  
```swift
struct UserProfile: DomainModel {
    let userId: User.ID           // Reference to User
    let displayName: String
    let bio: String
    let avatarURL: URL?
    let location: String?
    let website: URL?
    let dateOfBirth: Date?
    
    // Profile-specific business logic
    func isProfileComplete() -> Bool
    func getDisplayName() -> String  // Fallback to username
}
```

#### SettingsClient - User Preferences
```swift
struct UserSettings: DomainModel {
    let userId: User.ID           // Reference to User
    let notificationSettings: NotificationSettings
    let privacySettings: PrivacySettings
    let appPreferences: AppPreferences
    let language: Locale
    let timezone: TimeZone
    
    // Settings business logic
    func shouldNotify(for event: NotificationEvent) -> Bool
    func getEffectivePrivacyLevel() -> PrivacyLevel
}
```

### E-commerce Domain

#### ProductClient - Product Catalog
```swift
struct Product: DomainModel {
    let id: Product.ID
    let name: String
    let description: String
    let price: Money
    let category: ProductCategory
    let imageURLs: [URL]
    let specifications: [String: String]
    let status: ProductStatus     // active, discontinued
    
    // Product business logic
    func isAvailableForPurchase() -> Bool
    func getDiscountedPrice(discount: Discount?) -> Money
    func isInCategory(_ category: ProductCategory) -> Bool
}
```

#### InventoryClient - Stock Management
```swift
struct InventoryItem: DomainModel {
    let productId: Product.ID     // Reference to Product
    let quantity: Int
    let reservedQuantity: Int
    let minimumStock: Int
    let lastRestocked: Date
    let location: WarehouseLocation
    
    // Inventory business logic
    func availableQuantity() -> Int
    func needsRestock() -> Bool
    func canFulfillOrder(quantity: Int) -> Bool
}
```

#### OrderClient - Order Management
```swift
struct Order: DomainModel {
    let id: Order.ID
    let userId: User.ID           // Reference to User
    let items: [OrderItem]
    let status: OrderStatus
    let shippingAddress: Address
    let billingAddress: Address
    let totalAmount: Money
    let discounts: [Discount]
    let createdAt: Date
    
    // Order business logic  
    func canBeCancelled() -> Bool
    func calculateTotal() -> Money
    func canBeShipped() -> Bool
}
```

### Social/Content Domain

#### PostClient - User Posts
```swift
struct Post: DomainModel {
    let id: Post.ID
    let authorId: User.ID         // Reference to User
    let content: String
    let imageURLs: [URL]
    let hashtags: [String]
    let mentions: [User.ID]
    let visibility: PostVisibility
    let createdAt: Date
    let editedAt: Date?
    
    // Post business logic
    func canBeEditedBy(userId: User.ID) -> Bool
    func isVisibleTo(userId: User.ID) -> Bool
    func getHashtags() -> [String]
}
```

#### InteractionClient - Likes/Comments/Shares
```swift
struct Interaction: DomainModel {
    let id: Interaction.ID
    let userId: User.ID           // Reference to User
    let targetId: TargetID        // Post, Comment, etc.
    let type: InteractionType     // like, comment, share
    let content: String?          // For comments
    let createdAt: Date
    
    // Interaction business logic
    func isCommentType() -> Bool
    func canBeDeletedBy(userId: User.ID) -> Bool
}
```

### Messaging Domain

#### ConversationClient - Chat Threads
```swift
struct Conversation: DomainModel {
    let id: Conversation.ID
    let participants: [User.ID]   // References to Users
    let type: ConversationType    // direct, group
    let name: String?             // For group chats
    let lastMessageId: Message.ID?
    let createdAt: Date
    let updatedAt: Date
    
    // Conversation business logic
    func isGroupConversation() -> Bool
    func canUserJoin(userId: User.ID) -> Bool
    func getDisplayName(for userId: User.ID) -> String
}
```

#### MessageClient - Individual Messages
```swift
struct Message: DomainModel {
    let id: Message.ID
    let conversationId: Conversation.ID  // Reference to Conversation
    let senderId: User.ID               // Reference to User
    let content: String
    let type: MessageType               // text, image, file
    let attachments: [MessageAttachment]
    let timestamp: Date
    let readBy: [User.ID: Date]
    
    // Message business logic
    func isReadBy(userId: User.ID) -> Bool
    func canBeEditedBy(userId: User.ID) -> Bool
    func hasAttachments() -> Bool
}
```

## 🤖 AI Agent Decision Guidelines

### Automatic Boundary Detection Rules

#### Rule 1: Reference Density
If Entity A has >3 properties referencing Entity B, consider merging

```swift
// HIGH REFERENCE DENSITY - Consider merging
struct OrderItem {
    let orderId: Order.ID         // Reference 1
    let productId: Product.ID
    let quantity: Int
    let priceAtTime: Money
}

struct Order {
    let items: [OrderItem]        // Reference 2 (strong coupling)
    let totalAmount: Money        // Reference 3 (calculated from items)
}
```

#### Rule 2: Lifecycle Coupling
If Entity A cannot exist without Entity B, they belong together

```swift
// LIFECYCLE COUPLED - Same client
struct Order {
    let items: [OrderItem]        // OrderItems can't exist without Order
}
```

#### Rule 3: Business Operation Span
If >70% of business operations involve both entities, merge them

```swift
// BUSINESS OPERATION OVERLAP - Consider merging
// Operations: createOrder, addItem, removeItem, calculateTotal, applyDiscount
// All operations involve both Order and OrderItem
```

### Boundary Decision Algorithm

```swift
func determineClientBoundary(entities: [DomainEntity]) -> ClientBoundaryDecision {
    let cohesionScore = calculateBusinessCohesion(entities)
    let uiAlignmentScore = calculateUIAlignment(entities)  
    let transactionScore = calculateTransactionBoundary(entities)
    let accessScore = calculateAccessPattern(entities)
    
    let totalScore = cohesionScore + uiAlignmentScore + transactionScore + accessScore
    
    if totalScore >= 30 {
        return .sameClient(entities)
    } else {
        return .separateClients(entities.map { [$0] })
    }
}
```

## 📋 Domain Boundary Validation Checklist

### Before Finalizing Client Boundaries:

#### Single Responsibility Check
- [ ] Does the client have a single, clear domain responsibility?
- [ ] Can the client be described in one sentence?
- [ ] Would a new team member understand the client's purpose immediately?

#### Size and Complexity Check  
- [ ] Is the domain model <200 lines of code?
- [ ] Are there <15 business methods on the domain model?
- [ ] Can the domain logic be easily unit tested?

#### Relationship Check
- [ ] Are cross-client references limited to IDs?
- [ ] Can contexts easily coordinate between related clients?
- [ ] Are there no circular dependencies between domain models?

#### Performance Check
- [ ] Is the domain model serializable for state snapshots?
- [ ] Are common query patterns efficient?
- [ ] Does the client state fit reasonable memory constraints?

---

**BOUNDARY ANALYSIS STATUS**: Complete domain boundary principles and guidelines established  
**NEXT**: Design cross-domain communication patterns and data consistency approaches  
**AI IMPACT**: Systematic rules enable automatic client boundary detection  
**VALIDATION**: 1:1 domain model to client constraint maintained with clear decision framework