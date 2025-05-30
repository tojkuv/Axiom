import Foundation

// MARK: - Domain Validation Result

/// Validation result for domain models
public struct DomainValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    
    public init(isValid: Bool, errors: [String]) {
        self.isValid = isValid
        self.errors = errors
    }
}

// MARK: - Domain Model Protocol

/// The base protocol for all domain models in the Axiom framework
public protocol DomainModel: Sendable, Identifiable, Codable where ID: Hashable & Sendable & Codable {
    var id: ID { get }
    
    /// Validates the domain model against its business rules
    func validate() -> DomainValidationResult
    
    /// Returns the business rules that apply to this domain model
    func businessRules() -> [BusinessRule]
    
    /// Applies a change to the domain model, returning a new instance or an error
    func applying<T>(_ change: DomainChange<T>) -> Result<Self, DomainError>
}

// MARK: - Domain Change

/// Represents a change to be applied to a domain model
public struct DomainChange<T>: Sendable {
    public let description: String
    public let apply: @Sendable (Any) throws -> T
    
    public init(description: String, apply: @escaping @Sendable (Any) throws -> T) {
        self.description = description
        self.apply = apply
    }
}

// MARK: - Query Criteria

/// Criteria for querying domain models
public struct QueryCriteria<Model: DomainModel> {
    public let predicate: @Sendable (Model) -> Bool
    public let sortDescriptors: [SortDescriptor<Model>]
    public let limit: Int?
    
    public init(
        predicate: @escaping @Sendable (Model) -> Bool = { _ in true },
        sortDescriptors: [SortDescriptor<Model>] = [],
        limit: Int? = nil
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.limit = limit
    }
}

// MARK: - Sort Descriptor

/// Describes how to sort domain models
public struct SortDescriptor<Model: DomainModel> {
    public let compare: @Sendable (Model, Model) -> Bool
    
    public init<Value: Comparable>(keyPath: KeyPath<Model, Value>, ascending: Bool = true) {
        self.compare = { lhs, rhs in
            if ascending {
                return lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
            } else {
                return lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
            }
        }
    }
}

// MARK: - Business Operation

/// Represents a business operation to be applied to a domain model
public struct BusinessOperation<Model: DomainModel>: Sendable {
    public let name: String
    public let validate: @Sendable (Model) throws -> Void
    public let execute: @Sendable (Model) throws -> Model
    
    public init(
        name: String,
        validate: @escaping @Sendable (Model) throws -> Void,
        execute: @escaping @Sendable (Model) throws -> Model
    ) {
        self.name = name
        self.validate = validate
        self.execute = execute
    }
}

// MARK: - Default Implementation

public extension DomainModel {
    /// Default implementation that returns no business rules
    func businessRules() -> [BusinessRule] {
        []
    }
    
    /// Default implementation that always returns valid
    func validate() -> DomainValidationResult {
        DomainValidationResult(isValid: true, errors: [])
    }
    
    /// Default implementation that rejects all changes
    func applying<T>(_ change: DomainChange<T>) -> Result<Self, DomainError> {
        .failure(.stateInconsistent("Domain model does not support changes"))
    }
}

// MARK: - Empty Domain Type

/// An empty domain type for infrastructure clients that don't manage domain models
public struct EmptyDomain: DomainModel {
    public typealias ID = String
    
    public let id: ID
    
    public init() {
        self.id = "empty"
    }
}