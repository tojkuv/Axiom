import Foundation
import SwiftUI

/// Protocol for contexts that support delete confirmation
@MainActor
protocol DeleteConfirmable: ObservableObject {
    associatedtype ItemType
    
    var showDeleteConfirmation: Bool { get set }
    var itemToDelete: ItemType? { get set }
    
    func requestDelete(item: ItemType)
    func confirmDelete()
    func cancelDelete()
    func performDelete(item: ItemType) async
}

/// Default implementations for delete confirmation
extension DeleteConfirmable {
    func requestDelete(item: ItemType) {
        itemToDelete = item
        showDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let item = itemToDelete else { return }
        
        Task {
            await performDelete(item: item)
        }
        
        // Clear confirmation state
        itemToDelete = nil
        showDeleteConfirmation = false
    }
    
    func cancelDelete() {
        itemToDelete = nil
        showDeleteConfirmation = false
    }
}

/// Helper view modifier for delete confirmation dialogs
struct DeleteConfirmationModifier<Item>: ViewModifier {
    @Binding var showConfirmation: Bool
    let item: Item?
    let itemName: (Item) -> String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    
    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete Item",
            isPresented: $showConfirmation,
            titleVisibility: .visible,
            presenting: item
        ) { item in
            Button("Delete", role: .destructive, action: confirmAction)
            Button("Cancel", role: .cancel, action: cancelAction)
        } message: { item in
            Text("Are you sure you want to delete \"\(itemName(item))\"?")
        }
    }
}

extension View {
    func deleteConfirmation<Item>(
        isPresented: Binding<Bool>,
        item: Item?,
        itemName: @escaping (Item) -> String,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationModifier(
            showConfirmation: isPresented,
            item: item,
            itemName: itemName,
            confirmAction: confirmAction,
            cancelAction: cancelAction
        ))
    }
}