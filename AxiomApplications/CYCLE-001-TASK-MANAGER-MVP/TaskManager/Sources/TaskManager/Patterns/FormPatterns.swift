import Foundation
import SwiftUI
import Axiom

// MARK: - Form Context Base Class

/// Base class for form contexts with common patterns
@MainActor
class FormContext<C: Client>: AutoSyncContext<C> {
    @Published var isSubmitting: Bool = false
    @Published var validationError: String?
    
    /// Override to implement form validation
    var isValid: Bool {
        true // Subclasses should override
    }
    
    /// Override to implement validation logic
    func validate() -> Bool {
        validationError = nil
        return true
    }
    
    /// Helper for async form submission
    func submitForm(_ action: @escaping () async throws -> Void) async {
        validationError = nil
        
        guard validate() else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            try await action()
        } catch {
            validationError = error.localizedDescription
        }
    }
}

// MARK: - Optional Binding Helper
// TODO: Implement optional binding helper when needed

// MARK: - Form Field Modifiers

struct FormFieldStyle: ViewModifier {
    let isValid: Bool
    
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
            )
    }
}

extension View {
    func formFieldStyle(isValid: Bool = true) -> some View {
        modifier(FormFieldStyle(isValid: isValid))
    }
}

// MARK: - Validation Error View

struct ValidationErrorView: View {
    let error: String?
    
    var body: some View {
        if let error = error {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal)
                .transition(.opacity)
        }
    }
}

// MARK: - Form Submit Button

struct FormSubmitButton: View {
    let title: String
    let isValid: Bool
    let isSubmitting: Bool
    let action: () async -> Void
    
    var body: some View {
        if isSubmitting {
            ProgressView()
                .scaleEffect(0.8)
        } else {
            Button(title) {
                Task {
                    await action()
                }
            }
            .disabled(!isValid || isSubmitting)
        }
    }
}

// MARK: - Confirmation Dialog Helper

struct ConfirmationDialog<T> {
    let title: String
    let message: String
    let primaryButton: String
    let primaryAction: (T) -> Void
    let cancelButton: String = "Cancel"
    
    func present(for item: T, isPresented: Binding<Bool>) -> some View {
        EmptyView()
            .confirmationDialog(
                title,
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                Button(primaryButton, role: .destructive) {
                    primaryAction(item)
                }
                Button(cancelButton, role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

// MARK: - Form Navigation Bar

struct FormNavigationBar: ViewModifier {
    let title: String
    let cancelAction: () -> Void
    let saveAction: () async -> Void
    let canSave: Bool
    let isSaving: Bool
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancelAction)
                        .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    FormSubmitButton(
                        title: "Save",
                        isValid: canSave,
                        isSubmitting: isSaving,
                        action: saveAction
                    )
                }
            }
            .interactiveDismissDisabled(isSaving)
    }
}

extension View {
    func formNavigationBar(
        title: String,
        cancelAction: @escaping () -> Void,
        saveAction: @escaping () async -> Void,
        canSave: Bool,
        isSaving: Bool
    ) -> some View {
        modifier(FormNavigationBar(
            title: title,
            cancelAction: cancelAction,
            saveAction: saveAction,
            canSave: canSave,
            isSaving: isSaving
        ))
    }
}