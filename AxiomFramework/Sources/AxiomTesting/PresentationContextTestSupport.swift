import Foundation
@testable import Axiom

// MARK: - Mock Types for Testing

public struct MockPresentation: BindablePresentation {
    public let id: String
    public private(set) var isAppeared = false
    public private(set) var isDisappeared = false
    
    public var presentationIdentifier: String { id }
    
    public init(id: String) {
        self.id = id
    }
    
    public mutating func simulateAppear() {
        isAppeared = true
        isDisappeared = false
    }
    
    public mutating func simulateDisappear() {
        isDisappeared = true
    }
    
    public func simulateDeallocation() {
        Task { @MainActor in
            PresentationContextBindingManager.shared.unbind(self)
        }
    }
}

public class MockContext: PresentationBindable {
    public let id: String
    public var isActive = false
    
    public var bindingIdentifier: String { id }
    
    public init(id: String) {
        self.id = id
    }
}

// MARK: - Test Validator Wrapper

/// Wrapper around PresentationContextBindingManager for backward compatibility with tests
@MainActor
public class PresentationContextValidator {
    private let manager = PresentationContextBindingManager.shared
    
    public init() {
        // Reset manager state for testing
        manager.resetForTesting()
    }
    
    public var lastError: String? {
        manager.lastError
    }
    
    public func bindContext<P: BindablePresentation, C: PresentationBindable>(
        _ context: C,
        to presentation: P
    ) -> Bool {
        manager.bind(context, to: presentation)
    }
    
    public func getContext<P: BindablePresentation>(for presentation: P) -> AnyObject? {
        manager.context(for: presentation, as: MockContext.self)
    }
    
    public var bindingCount: Int {
        manager.bindingCount
    }
    
    public var uniquePresentationCount: Int {
        manager.uniquePresentationCount
    }
    
    public var uniqueContextCount: Int {
        manager.uniqueContextCount
    }
}