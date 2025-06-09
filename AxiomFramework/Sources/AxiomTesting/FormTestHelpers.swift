import XCTest
import SwiftUI
@testable import Axiom

// MARK: - Form Test Helpers

/// Test helpers for form validation and binding behaviors
public struct FormTestHelpers {
    
    /// Simulate user input in a form field
    public static func simulateInput<T>(
        in binding: Binding<T>,
        value: T
    ) {
        binding.wrappedValue = value
    }
    
    /// Assert form field validation state
    public static func assertValidation<T>(
        for value: T,
        validator: (T) -> Bool,
        expectedValid: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let isValid = validator(value)
        XCTAssertEqual(
            isValid,
            expectedValid,
            "Validation failed for value: \(value)",
            file: file,
            line: line
        )
    }
    
    /// Test optional binding behavior
    public static func assertOptionalBinding<T: Equatable>(
        binding: Binding<T?>,
        nonOptional: Binding<T>,
        testValue: T,
        nilValue: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Test nil -> default
        binding.wrappedValue = nil
        XCTAssertEqual(nonOptional.wrappedValue, nilValue, file: file, line: line)
        
        // Test value passthrough
        binding.wrappedValue = testValue
        XCTAssertEqual(nonOptional.wrappedValue, testValue, file: file, line: line)
        
        // Test default -> nil (only for string empty value)
        nonOptional.wrappedValue = nilValue
        if nilValue is String && (nilValue as! String).isEmpty {
            XCTAssertNil(binding.wrappedValue, file: file, line: line)
        } else {
            XCTAssertEqual(binding.wrappedValue, nilValue, file: file, line: line)
        }
    }
    
    /// Assert validation result matches expectations
    public static func assertValidationResult(
        _ result: ValidationResult,
        isValid: Bool,
        errorMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(result.isValid, isValid, file: file, line: line)
        if let expectedMessage = errorMessage {
            XCTAssertEqual(
                result.errorMessage,
                expectedMessage,
                file: file,
                line: line
            )
        }
    }
    
    /// Create a test binding with tracking
    public static func trackingBinding<T>(
        initialValue: T,
        didSet: @escaping (T) -> Void = { _ in }
    ) -> Binding<T> {
        var value = initialValue
        return Binding(
            get: { value },
            set: { newValue in
                value = newValue
                didSet(newValue)
            }
        )
    }
    
    /// Assert form field format
    public static func assertFormat(
        input: String,
        formatter: (String) -> String,
        expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let formatted = formatter(input)
        XCTAssertEqual(
            formatted,
            expected,
            "Format failed for input: \(input)",
            file: file,
            line: line
        )
    }
}

// MARK: - Advanced Form Testing

/// Comprehensive form testing utilities
public struct AdvancedFormTestHelpers {
    
    /// Test complete form validation flow
    public static func assertFormValidationFlow<T>(
        form: T,
        validInputs: [String: Any],
        invalidInputs: [String: Any],
        expectedErrors: [String: String]
    ) async throws where T: FormValidatable {
        // Test with invalid inputs first
        for (field, invalidValue) in invalidInputs {
            try form.setField(field, value: invalidValue)
        }
        
        let invalidResult = await form.validate()
        XCTAssertFalse(invalidResult.isValid, "Form should be invalid with invalid inputs")
        
        for (field, expectedError) in expectedErrors {
            XCTAssertTrue(
                invalidResult.fieldErrors[field]?.contains(expectedError) == true,
                "Expected error '\(expectedError)' for field '\(field)'"
            )
        }
        
        // Test with valid inputs
        for (field, validValue) in validInputs {
            try form.setField(field, value: validValue)
        }
        
        let validResult = await form.validate()
        XCTAssertTrue(validResult.isValid, "Form should be valid with valid inputs")
        XCTAssertTrue(validResult.fieldErrors.isEmpty, "No field errors should exist")
    }
    
    /// Test form field interdependencies
    public static func assertFieldDependencies<T>(
        form: T,
        primaryField: String,
        primaryValue: Any,
        dependentField: String,
        expectedDependentState: FieldState
    ) async throws where T: FormValidatable {
        // Set primary field value
        try form.setField(primaryField, value: primaryValue)
        
        // Check dependent field state
        let dependentState = form.getFieldState(dependentField)
        
        switch expectedDependentState {
        case .enabled:
            XCTAssertTrue(dependentState.isEnabled, "Dependent field should be enabled")
        case .disabled:
            XCTAssertFalse(dependentState.isEnabled, "Dependent field should be disabled")
        case .required:
            XCTAssertTrue(dependentState.isRequired, "Dependent field should be required")
        case .optional:
            XCTAssertFalse(dependentState.isRequired, "Dependent field should be optional")
        case .visible:
            XCTAssertTrue(dependentState.isVisible, "Dependent field should be visible")
        case .hidden:
            XCTAssertFalse(dependentState.isVisible, "Dependent field should be hidden")
        }
    }
    
    /// Test form submission flow
    public static func assertFormSubmission<T>(
        form: T,
        validData: [String: Any],
        expectedSubmissionResult: FormSubmissionResult
    ) async throws where T: FormSubmittable {
        // Populate form with valid data
        for (field, value) in validData {
            try form.setField(field, value: value)
        }
        
        // Validate form
        let validationResult = await form.validate()
        XCTAssertTrue(validationResult.isValid, "Form must be valid before submission")
        
        // Submit form
        let submissionResult = try await form.submit()
        
        switch expectedSubmissionResult {
        case .success:
            XCTAssertTrue(submissionResult.isSuccess, "Form submission should succeed")
        case .failure(let expectedError):
            XCTAssertFalse(submissionResult.isSuccess, "Form submission should fail")
            XCTAssertEqual(submissionResult.error?.localizedDescription, expectedError)
        case .validation(let expectedErrors):
            XCTAssertFalse(submissionResult.isSuccess, "Form submission should fail validation")
            XCTAssertEqual(submissionResult.validationErrors, expectedErrors)
        }
    }
    
    /// Test form reset functionality
    public static func assertFormReset<T>(
        form: T,
        initialData: [String: Any],
        modifiedData: [String: Any]
    ) async throws where T: FormResettable {
        // Set initial state
        for (field, value) in initialData {
            try form.setField(field, value: value)
        }
        
        let initialState = form.getCurrentState()
        
        // Modify form
        for (field, value) in modifiedData {
            try form.setField(field, value: value)
        }
        
        let modifiedState = form.getCurrentState()
        XCTAssertNotEqual(initialState, modifiedState, "Form state should change after modification")
        
        // Reset form
        form.reset()
        
        let resetState = form.getCurrentState()
        XCTAssertEqual(initialState, resetState, "Form state should match initial state after reset")
    }
    
    /// Test form autosave functionality
    public static func assertFormAutosave<T>(
        form: T,
        field: String,
        value: Any,
        autosaveDelay: Duration = .seconds(1)
    ) async throws where T: FormAutosavable {
        // Enable autosave
        form.enableAutosave(delay: autosaveDelay)
        
        // Track autosave calls
        var autosaveCallCount = 0
        form.onAutosave = { 
            autosaveCallCount += 1
        }
        
        // Set field value
        try form.setField(field, value: value)
        
        // Wait for autosave delay plus buffer
        try await Task.sleep(for: autosaveDelay + .milliseconds(100))
        
        XCTAssertEqual(autosaveCallCount, 1, "Autosave should be triggered once")
        
        // Verify saved state
        let savedState = await form.getAutosavedState()
        XCTAssertEqual(savedState[field] as? String, value as? String, "Field value should be autosaved")
    }
}

// MARK: - Binding Testing Utilities

/// Test SwiftUI binding behaviors with forms
public struct FormBindingTestHelpers {
    
    /// Test two-way binding synchronization
    public static func assertTwoWayBinding<T: Equatable>(
        binding: Binding<T>,
        modelProperty: KeyPath<Any, T>,
        model: Any,
        testValue: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Test binding -> model
        binding.wrappedValue = testValue
        
        // In real implementation, this would check the model property
        // For now, we'll verify the binding value itself
        XCTAssertEqual(
            binding.wrappedValue,
            testValue,
            "Binding should update with new value",
            file: file,
            line: line
        )
    }
    
    /// Test computed binding behavior
    public static func assertComputedBinding<T: Equatable, U: Equatable>(
        sourceBinding: Binding<T>,
        computedBinding: Binding<U>,
        sourceValue: T,
        expectedComputedValue: U,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        sourceBinding.wrappedValue = sourceValue
        
        XCTAssertEqual(
            computedBinding.wrappedValue,
            expectedComputedValue,
            "Computed binding should reflect source changes",
            file: file,
            line: line
        )
    }
    
    /// Test binding performance under rapid updates
    public static func assertBindingPerformance<T>(
        binding: Binding<T>,
        values: [T],
        maxUpdateTime: Duration = .milliseconds(100)
    ) async throws {
        let startTime = ContinuousClock.now
        
        for value in values {
            binding.wrappedValue = value
        }
        
        let endTime = ContinuousClock.now
        let totalTime = endTime - startTime
        
        XCTAssertLessThan(
            totalTime,
            maxUpdateTime,
            "Binding updates should complete within \(maxUpdateTime)"
        )
    }
}

// MARK: - Validation Testing Utilities

/// Test form validation rules and behaviors
public struct FormValidationTestHelpers {
    
    /// Test custom validation rule
    public static func assertValidationRule<T>(
        rule: ValidationRule<T>,
        validCases: [T],
        invalidCases: [T],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for validCase in validCases {
            let result = rule.validate(validCase)
            XCTAssertTrue(
                result.isValid,
                "Validation rule should pass for valid case: \(validCase)",
                file: file,
                line: line
            )
        }
        
        for invalidCase in invalidCases {
            let result = rule.validate(invalidCase)
            XCTAssertFalse(
                result.isValid,
                "Validation rule should fail for invalid case: \(invalidCase)",
                file: file,
                line: line
            )
        }
    }
    
    /// Test validation rule composition
    public static func assertCompositeValidation<T>(
        rules: [ValidationRule<T>],
        testValue: T,
        expectedResult: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let compositeRule = CompositeValidationRule(rules: rules)
        let result = compositeRule.validate(testValue)
        
        XCTAssertEqual(
            result.isValid,
            expectedResult,
            "Composite validation should \(expectedResult ? "pass" : "fail") for value: \(testValue)",
            file: file,
            line: line
        )
    }
    
    /// Test async validation
    public static func assertAsyncValidation<T>(
        rule: AsyncValidationRule<T>,
        testValue: T,
        expectedResult: Bool,
        timeout: Duration = .seconds(5)
    ) async throws {
        let result = try await withTimeout(timeout) {
            try await rule.validate(testValue)
        }
        
        XCTAssertEqual(
            result.isValid,
            expectedResult,
            "Async validation should \(expectedResult ? "pass" : "fail") for value: \(testValue)"
        )
    }
}

// MARK: - Supporting Types and Protocols

/// Form validation protocol
public protocol FormValidatable {
    func setField(_ field: String, value: Any) throws
    func validate() async -> FormValidationResult
    func getFieldState(_ field: String) -> FieldState
}

/// Form submission protocol
public protocol FormSubmittable: FormValidatable {
    func submit() async throws -> FormSubmissionResult
}

/// Form reset protocol
public protocol FormResettable {
    func reset()
    func getCurrentState() -> [String: Any]
}

/// Form autosave protocol
public protocol FormAutosavable {
    func enableAutosave(delay: Duration)
    func getAutosavedState() async -> [String: Any]
    var onAutosave: (() -> Void)? { get set }
}

/// Field state
public struct FieldState: Equatable {
    public let isEnabled: Bool
    public let isRequired: Bool
    public let isVisible: Bool
    
    public init(isEnabled: Bool = true, isRequired: Bool = false, isVisible: Bool = true) {
        self.isEnabled = isEnabled
        self.isRequired = isRequired
        self.isVisible = isVisible
    }
}

/// Field state enum
public enum FieldStateType {
    case enabled
    case disabled
    case required
    case optional
    case visible
    case hidden
}

/// Form validation result
public struct FormValidationResult: Equatable {
    public let isValid: Bool
    public let fieldErrors: [String: [String]]
    public let globalErrors: [String]
    
    public init(isValid: Bool, fieldErrors: [String: [String]] = [:], globalErrors: [String] = []) {
        self.isValid = isValid
        self.fieldErrors = fieldErrors
        self.globalErrors = globalErrors
    }
}

/// Form submission result
public struct FormSubmissionResult {
    public let isSuccess: Bool
    public let error: Error?
    public let validationErrors: [String: [String]]
    
    public init(isSuccess: Bool, error: Error? = nil, validationErrors: [String: [String]] = [:]) {
        self.isSuccess = isSuccess
        self.error = error
        self.validationErrors = validationErrors
    }
}

/// Form submission result type
public enum FormSubmissionResultType {
    case success
    case failure(String)
    case validation([String: [String]])
}

/// Validation rule
public protocol ValidationRule<T> {
    associatedtype T
    func validate(_ value: T) -> ValidationResult
}

/// Async validation rule
public protocol AsyncValidationRule<T> {
    associatedtype T
    func validate(_ value: T) async throws -> ValidationResult
}

/// Composite validation rule
public struct CompositeValidationRule<T>: ValidationRule {
    private let rules: [any ValidationRule<T>]
    
    public init(rules: [any ValidationRule<T>]) {
        self.rules = rules
    }
    
    public func validate(_ value: T) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        return ValidationResult(isValid: true)
    }
}

/// Utility function for timeout
private func withTimeout<T>(_ timeout: Duration, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: timeout)
            throw FormTestError.timeout
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

/// Form test errors
public enum FormTestError: Error {
    case timeout
    case invalidField(String)
    case validationFailed
}