import XCTest
import SwiftUI
@testable import Axiom

final class FormBindingUtilitiesTests: XCTestCase {
    
    // MARK: - Optional Binding Tests
    
    func testOptionalStringBinding() {
        // Given: An optional string property
        var optionalValue: String? = nil
        let binding = Binding(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )
        
        // When: Using optional() modifier
        let nonOptionalBinding = binding.optional()
        
        // Then: Should handle nil -> empty string
        XCTAssertEqual(nonOptionalBinding.wrappedValue, "")
        
        // And: Should handle empty string -> nil
        nonOptionalBinding.wrappedValue = ""
        XCTAssertNil(optionalValue)
        
        // And: Should pass through non-empty values
        nonOptionalBinding.wrappedValue = "Hello"
        XCTAssertEqual(optionalValue, "Hello")
    }
    
    func testOptionalStringBindingWithCustomEmptyValue() {
        // Given: An optional string with custom empty value
        var optionalValue: String? = nil
        let binding = Binding(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )
        
        // When: Using optional() with custom empty value
        let nonOptionalBinding = binding.optional(emptyValue: "N/A")
        
        // Then: Should use custom empty value for nil
        XCTAssertEqual(nonOptionalBinding.wrappedValue, "N/A")
        
        // And: Empty string should not convert to nil
        nonOptionalBinding.wrappedValue = ""
        XCTAssertEqual(optionalValue, "")
    }
    
    func testOptionalNumericBinding() {
        // Given: An optional Int property
        var optionalValue: Int? = nil
        let binding = Binding(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )
        
        // When: Using optional() with default value
        let nonOptionalBinding = binding.optional(defaultValue: 0)
        
        // Then: Should handle nil -> default
        XCTAssertEqual(nonOptionalBinding.wrappedValue, 0)
        
        // And: Should pass through values
        nonOptionalBinding.wrappedValue = 42
        XCTAssertEqual(optionalValue, 42)
        
        // And: Zero should not become nil (unlike empty string)
        nonOptionalBinding.wrappedValue = 0
        XCTAssertEqual(optionalValue, 0)
    }
    
    func testOptionalBindingWithCustomNilCheck() {
        // Given: An optional custom type
        var optionalValue: Double? = nil
        let binding = Binding(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )
        
        // When: Using optional() with custom nil check
        let nonOptionalBinding = binding.optional(
            defaultValue: 0.0,
            isNil: { $0 < 0 } // Negative values become nil
        )
        
        // Then: Should handle nil -> default
        XCTAssertEqual(nonOptionalBinding.wrappedValue, 0.0)
        
        // And: Negative values should become nil
        nonOptionalBinding.wrappedValue = -1.0
        XCTAssertNil(optionalValue)
        
        // And: Positive values should pass through
        nonOptionalBinding.wrappedValue = 3.14
        XCTAssertEqual(optionalValue, 3.14)
    }
    
    // MARK: - Validation Tests
    
    func testFormValidators() {
        // Test required validator
        let requiredResult = FormValidators.required("")
        XCTAssertFalse(requiredResult.isValid)
        XCTAssertEqual(requiredResult.errorMessage, "This field is required")
        
        let validRequired = FormValidators.required("Hello")
        XCTAssertTrue(validRequired.isValid)
        
        // Test email validator
        let invalidEmail = FormValidators.email("not-an-email")
        XCTAssertFalse(invalidEmail.isValid)
        
        let validEmail = FormValidators.email("test@example.com")
        XCTAssertTrue(validEmail.isValid)
        
        // Test min length validator
        let minLength5 = FormValidators.minLength(5)
        let shortResult = minLength5("Hi")
        XCTAssertFalse(shortResult.isValid)
        XCTAssertEqual(shortResult.errorMessage, "Must be at least 5 characters")
        
        let longResult = minLength5("Hello World")
        XCTAssertTrue(longResult.isValid)
    }
    
    // MARK: - Format Helper Tests
    
    func testPhoneNumberFormatting() {
        // Test formatting
        let formatted = FormatHelpers.formatPhoneNumber("5551234567")
        XCTAssertEqual(formatted, "(555) 123-4567")
        
        // Test validation
        XCTAssertTrue(FormatHelpers.isValidPhoneNumber("555-123-4567"))
        XCTAssertTrue(FormatHelpers.isValidPhoneNumber("(555) 123-4567"))
        XCTAssertTrue(FormatHelpers.isValidPhoneNumber("+1 555 123 4567"))
        XCTAssertFalse(FormatHelpers.isValidPhoneNumber("abc-def-ghij"))
    }
    
    func testEmailValidation() {
        XCTAssertTrue(FormatHelpers.isValidEmail("test@example.com"))
        XCTAssertTrue(FormatHelpers.isValidEmail("user.name+tag@example.co.uk"))
        XCTAssertFalse(FormatHelpers.isValidEmail("not-an-email"))
        XCTAssertFalse(FormatHelpers.isValidEmail("@example.com"))
        XCTAssertFalse(FormatHelpers.isValidEmail("test@"))
    }
}