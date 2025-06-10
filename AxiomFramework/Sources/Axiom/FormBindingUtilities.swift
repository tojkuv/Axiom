import SwiftUI

// MARK: - Optional Binding Extensions

public extension Binding where Value == String? {
    /// Convert optional String binding to non-optional with empty string default
    func optional(emptyValue: String = "") -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? emptyValue },
            set: { 
                if emptyValue == "" && $0.isEmpty {
                    self.wrappedValue = nil
                } else {
                    self.wrappedValue = $0
                }
            }
        )
    }
}

public extension Binding {
    /// Convert optional binding to non-optional with default value
    func optional<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
    
    /// Convert optional binding with custom nil check
    func optional<T>(
        defaultValue: T,
        isNil: @escaping (T) -> Bool
    ) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = isNil($0) ? nil : $0 }
        )
    }
}

// MARK: - Validation Support

/// Simple validation result for form fields
public struct ValidationResult {
    public let isValid: Bool
    public let errorMessage: String?
    
    public init(isValid: Bool, errorMessage: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

/// Validator functions for common patterns
public struct FormValidators {
    public static func required(_ value: String) -> ValidationResult {
        ValidationResult(
            isValid: !value.isEmpty,
            errorMessage: "This field is required"
        )
    }
    
    public static func email(_ value: String) -> ValidationResult {
        ValidationResult(
            isValid: FormatHelpers.isValidEmail(value),
            errorMessage: "Please enter a valid email address"
        )
    }
    
    public static func phoneNumber(_ value: String) -> ValidationResult {
        ValidationResult(
            isValid: FormatHelpers.isValidPhoneNumber(value),
            errorMessage: "Please enter a valid phone number"
        )
    }
    
    public static func minLength(_ length: Int) -> (String) -> ValidationResult {
        return { value in
            ValidationResult(
                isValid: value.count >= length,
                errorMessage: "Must be at least \(length) characters"
            )
        }
    }
}

// MARK: - Form Field Wrapper

public struct FormField<Content: View>: View {
    let label: String
    let required: Bool
    let content: Content
    
    public init(
        _ label: String,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.required = required
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            content
        }
    }
}

// MARK: - Format Helpers

public struct FormatHelpers {
    /// Validate phone number format
    public static func isValidPhoneNumber(_ text: String) -> Bool {
        let pattern = "^[0-9+\\-\\(\\)\\s]+$"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Validate email format
    public static func isValidEmail(_ text: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Format phone number string
    public static func formatPhoneNumber(_ text: String) -> String {
        let digits = text.filter { $0.isNumber }
        
        if digits.count == 10 {
            let areaCode = String(digits.prefix(3))
            let middle = String(digits.dropFirst(3).prefix(3))
            let last = String(digits.dropFirst(6))
            return "(\(areaCode)) \(middle)-\(last)"
        }
        
        return text
    }
}

// MARK: - Submit Button Helper

// Simple button without state for now - full SwiftUI views will be in separate module
public struct FormSubmitButton {
    public static func create(
        _ title: String,
        isValid: Binding<Bool>,
        action: @escaping () async -> Void
    ) -> some View {
        Button(title) {
            Task {
                await action()
            }
        }
        .disabled(!isValid.wrappedValue)
    }
}

// MARK: - Property Wrapper for Form State

@propertyWrapper
public final class FormValue<Value>: ObservableObject {
    private var value: Value
    private var validator: ((Value) -> Bool)?
    @Published public var isValid: Bool = true
    @Published public var errorMessage: String?
    
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            validate()
        }
    }
    
    public var projectedValue: FormValue<Value> {
        self
    }
    
    public init(
        wrappedValue: Value,
        validation: ((Value) -> Bool)? = nil
    ) {
        self.value = wrappedValue
        self.validator = validation
        self.validate()
    }
    
    private func validate() {
        if let validator = validator {
            isValid = validator(value)
        }
    }
    
    public func binding() -> Binding<Value> {
        Binding(
            get: { self.value },
            set: { self.wrappedValue = $0 }
        )
    }
}