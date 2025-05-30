import Foundation

// MARK: - ClientDependencies Protocol

/// Protocol for organizing client dependencies in contexts
/// Provides type-safe access to clients with clear dependency relationships
public protocol ClientDependencies: Sendable {
    /// Validates that all required clients are properly initialized
    func validateClients() async throws
}

// MARK: - Default Implementation

extension ClientDependencies {
    public func validateClients() async throws {
        // Default implementation - subclasses can override for custom validation
    }
}

// MARK: - Usage Documentation

/*
 CLIENT DEPENDENCIES USAGE:
 
 ORGANIZING CONTEXT CLIENTS:
 ```swift
 struct MyAppClients: ClientDependencies {
     let userClient: UserClient
     let dataClient: DataClient
     let analyticsClient: AnalyticsClient
     
     init(userClient: UserClient, dataClient: DataClient, analyticsClient: AnalyticsClient) {
         self.userClient = userClient
         self.dataClient = dataClient
         self.analyticsClient = analyticsClient
     }
     
     func validateClients() async throws {
         try await userClient.validateState()
         try await dataClient.validateState()
         try await analyticsClient.validateState()
     }
 }
 ```
 
 CONTEXT INTEGRATION:
 ```swift
 @MainActor
 class MyContext: AxiomContext {
     typealias Clients = MyAppClients
     
     var clients: MyAppClients {
         MyAppClients(
             userClient: userClient,
             dataClient: dataClient,
             analyticsClient: analyticsClient
         )
     }
 }
 ```
 
 BENEFITS:
 - Type-safe client organization
 - Clear dependency relationships
 - Validation capabilities
 - Better testing through dependency injection
 */