import Foundation
import SwiftUI
@testable import Axiom

// MARK: - Example: Action-Reducer 1:1 Mapping Enforcement

// This example demonstrates how the @Context macro will enforce
// that every action has a matching reducer implementation

// Domain State
struct ShoppingState: Axiom.State {
    var items: [String] = []
    var total: Decimal = 0
    
    init() {}
}

// Client
actor ShoppingClient: Client {
    typealias State = ShoppingState
    
    private(set) var state = ShoppingState()
    
    func updateState(_ transform: (inout ShoppingState) -> Void) async {
        transform(&state)
    }
}

// Context with COMPLETE action-reducer mapping
@MainActor
final class ValidShoppingContext: BaseContext<ValidShoppingContext.ViewState, ValidShoppingContext.ViewActions> {
    
    struct ViewState: Axiom.State {
        let itemCount: Int
        let formattedTotal: String
        
        init() {
            self.itemCount = 0
            self.formattedTotal = "$0.00"
        }
        
        init(itemCount: Int, formattedTotal: String) {
            self.itemCount = itemCount
            self.formattedTotal = formattedTotal
        }
    }
    
    struct ViewActions {
        let addItem: (String, Decimal) async -> Void
        let removeItem: (String) async -> Void
        let clearCart: () async -> Void
    }
    
    private let client: ShoppingClient
    
    init(client: ShoppingClient) {
        self.client = client
        
        let placeholder = ViewActions(
            addItem: { _, _ in },
            removeItem: { _ in },
            clearCart: { }
        )
        
        super.init(state: ViewState(), actions: placeholder)
        
        setActions(ViewActions(
            addItem: { [weak self] item, price in
                await self?.addItem(item, price: price)
            },
            removeItem: { [weak self] item in
                await self?.removeItem(item)
            },
            clearCart: { [weak self] in
                await self?.clearCart()
            }
        ))
        
        Task {
            await refreshViewState()
        }
    }
    
    // ✅ VALID: All actions have matching reducers
    
    private func addItem(_ item: String, price: Decimal) async {
        await client.updateState { state in
            state.items.append(item)
            state.total += price
        }
        await refreshViewState()
    }
    
    private func removeItem(_ item: String) async {
        await client.updateState { state in
            if let index = state.items.firstIndex(of: item) {
                state.items.remove(at: index)
                // In real app, would also adjust total
            }
        }
        await refreshViewState()
    }
    
    private func clearCart() async {
        await client.updateState { state in
            state.items.removeAll()
            state.total = 0
        }
        await refreshViewState()
    }
    
    private func refreshViewState() async {
        let state = await client.state
        updateState(ViewState(
            itemCount: state.items.count,
            formattedTotal: "$\(state.total)"
        ))
    }
}

// Example of what would FAIL macro validation:
/*
@Context  // This would generate compile errors
class InvalidShoppingContext: Context {
    struct Actions {
        let addItem: (String) async -> Void
        let removeItem: (String) async -> Void
        let checkout: () async -> Void
    }
    
    // ✅ Has reducer
    func addItem(_ item: String) async { ... }
    
    // ❌ MISSING REDUCER for removeItem
    // Compile Error: "Context 'InvalidShoppingContext' missing reducer 'removeItem(_:)' for action"
    
    // ❌ MISSING REDUCER for checkout
    // Compile Error: "Context 'InvalidShoppingContext' missing reducer 'checkout()' for action"
}
*/

// Presentation using the valid context
struct ShoppingView: Presentation {
    typealias ContextType = ValidShoppingContext
    
    let context: ValidShoppingContext
    
    var body: some View {
        VStack {
            Text("Items: \(context.state.itemCount)")
            Text("Total: \(context.state.formattedTotal)")
            
            Button("Add Apple") {
                Task {
                    await context.actions.addItem("Apple", 1.99)
                }
            }
            
            Button("Clear Cart") {
                Task {
                    await context.actions.clearCart()
                }
            }
        }
    }
}