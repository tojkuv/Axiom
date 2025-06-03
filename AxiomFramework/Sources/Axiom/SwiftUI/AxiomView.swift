import SwiftUI

// MARK: - Base Presentation Implementation

/// Base view implementation for Presentation protocol
public struct BasePresentation<C: Context>: Presentation {
    public typealias ContextType = C
    
    /// Required context binding
    public let context: C
    
    /// Initialize with context
    public init(context: C) {
        self.context = context
    }
    
    /// Default body implementation
    public var body: some View {
        Text("Override body in your Presentation implementation")
            .environmentObject(context)
    }
}

// MARK: - View Extensions

public extension View {
    /// Bind a context to this view
    func axiomContext<C: Context>(_ context: C) -> some View {
        self.environmentObject(context)
    }
}