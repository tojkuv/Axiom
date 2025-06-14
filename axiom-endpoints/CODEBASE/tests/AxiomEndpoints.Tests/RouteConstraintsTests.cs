using AxiomEndpoints.Core;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Tests;

public class RouteConstraintsTests
{
    [Theory]
    [InlineData("123e4567-e89b-12d3-a456-426614174000", true)]
    [InlineData("not-a-guid", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void TypeConstraint_Guid_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new TypeConstraint<Guid>();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("guid");
        constraint.ErrorMessage.Should().Be("Value must be a valid Guid");
    }

    [Theory]
    [InlineData("42", true)]
    [InlineData("not-a-number", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void TypeConstraint_Int_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new TypeConstraint<int>();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("int");
    }

    [Theory]
    [InlineData("true", true)]
    [InlineData("false", true)]
    [InlineData("True", true)]
    [InlineData("False", true)]
    [InlineData("not-a-bool", false)]
    public void TypeConstraint_Bool_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new TypeConstraint<bool>();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("bool");
    }

    [Theory]
    [InlineData("5", true)]   // Within range
    [InlineData("1", true)]   // Min boundary
    [InlineData("10", true)]  // Max boundary
    [InlineData("0", false)]  // Below min
    [InlineData("11", false)] // Above max
    [InlineData("not-a-number", false)]
    public void RangeConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new RangeConstraint<int> { Min = 1, Max = 10 };
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("range(1,10)");
        constraint.ErrorMessage.Should().Be("Value must be between 1 and 10");
    }

    [Theory]
    [InlineData("abc123", true)]    // Valid pattern
    [InlineData("test-123", true)]  // Valid with dash
    [InlineData("ABC123", false)]   // Uppercase not allowed
    [InlineData("abc_123", false)]  // Underscore not allowed
    [InlineData("", false)]         // Empty
    public void RegexConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new RegexConstraint(@"^[a-z0-9-]+$");
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be(@"regex(^[a-z0-9-]+$)");
        constraint.ErrorMessage.Should().Be(@"Value must match pattern: ^[a-z0-9-]+$");
    }

    [Theory]
    [InlineData("hello", true)]     // Within range
    [InlineData("hi", true)]        // Min boundary
    [InlineData("hello world", true)] // Max boundary
    [InlineData("a", false)]        // Below min
    [InlineData("this is too long", false)] // Above max
    [InlineData("", false)]         // Empty
    [InlineData(null, false)]       // Null
    public void LengthConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new LengthConstraint { MinLength = 2, MaxLength = 11 };
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("length(2,11)");
        constraint.ErrorMessage.Should().Be("Length must be between 2 and 11");
    }

    [Theory]
    [InlineData("5", true)]         // Within range
    [InlineData("10", true)]        // Min boundary
    [InlineData("9", false)]        // Below min
    [InlineData("", false)]         // Empty
    public void LengthConstraint_MinOnly_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new LengthConstraint { MinLength = 10, MaxLength = null };
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("minlength(10)");
        constraint.ErrorMessage.Should().Be("Minimum length is 10");
    }

    [Theory]
    [InlineData("hello", true)]     // Within range
    [InlineData("hello world", false)] // Above max
    public void LengthConstraint_MaxOnly_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new LengthConstraint { MinLength = null, MaxLength = 5 };
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("maxlength(5)");
        constraint.ErrorMessage.Should().Be("Maximum length is 5");
    }

    [Theory]
    [InlineData("pending", true)]
    [InlineData("Pending", true)]      // Case insensitive
    [InlineData("PENDING", true)]      // Case insensitive
    [InlineData("inprogress", true)]
    [InlineData("completed", true)]
    [InlineData("cancelled", true)]
    [InlineData("invalid", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void EnumConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new EnumConstraint<TaskStatus>();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Contain("enum(");
        constraint.ConstraintString.Should().Contain("pending");
        constraint.ConstraintString.Should().Contain("inprogress");
        constraint.ErrorMessage.Should().Contain("Value must be one of:");
    }

    [Theory]
    [InlineData("red", true)]
    [InlineData("green", true)]
    [InlineData("blue", true)]
    [InlineData("Red", true)]       // Case insensitive
    [InlineData("yellow", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void AllowedValuesConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new AllowedValuesConstraint("red", "green", "blue");
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("values(red|green|blue)");
        constraint.ErrorMessage.Should().Be("Value must be one of: red, green, blue");
        constraint.AllowedValues.Should().Contain("red");
        constraint.AllowedValues.Should().Contain("green");
        constraint.AllowedValues.Should().Contain("blue");
    }

    [Theory]
    [InlineData("hello", true)]
    [InlineData("world", true)]
    [InlineData("", false)]
    [InlineData("   ", false)]      // Whitespace only
    [InlineData(null, false)]
    public void RequiredConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new RequiredConstraint();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("required");
        constraint.ErrorMessage.Should().Be("Value is required");
    }

    [Theory]
    [InlineData("hello", true)]
    [InlineData("world", true)]
    [InlineData("Hello", true)]     // Case insensitive
    [InlineData("hello123", false)] // Contains numbers
    [InlineData("hello-world", false)] // Contains dash
    [InlineData("", false)]
    [InlineData(null, false)]
    public void AlphaConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new AlphaConstraint();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("alpha");
        constraint.ErrorMessage.Should().Be("Value must contain only letters");
    }

    [Theory]
    [InlineData("hello123", true)]
    [InlineData("test", true)]
    [InlineData("123", true)]
    [InlineData("Hello123", true)]   // Case insensitive
    [InlineData("hello-world", false)] // Contains dash
    [InlineData("hello_world", false)] // Contains underscore
    [InlineData("", false)]
    [InlineData(null, false)]
    public void AlphanumericConstraint_Should_Validate_Correctly(string? value, bool expectedValid)
    {
        var constraint = new AlphanumericConstraint();
        
        constraint.IsValid(value).Should().Be(expectedValid);
        constraint.ConstraintString.Should().Be("alphanumeric");
        constraint.ErrorMessage.Should().Be("Value must contain only letters and numbers");
    }

    [Fact]
    public void Multiple_Constraints_Should_All_Validate()
    {
        var typeConstraint = new TypeConstraint<int>();
        var rangeConstraint = new RangeConstraint<int> { Min = 1, Max = 100 };
        
        // Valid value should pass both constraints
        typeConstraint.IsValid("42").Should().BeTrue();
        rangeConstraint.IsValid("42").Should().BeTrue();
        
        // Invalid type should fail type constraint
        typeConstraint.IsValid("not-a-number").Should().BeFalse();
        
        // Out of range should fail range constraint
        rangeConstraint.IsValid("150").Should().BeFalse();
    }
}

public enum TaskStatus
{
    Pending,
    InProgress,
    Completed,
    Cancelled
}