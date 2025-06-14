using System.Globalization;
using AxiomEndpoints.Core;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Tests;

public class ResultTests
{
    [Fact]
    public void Success_CreatesSuccessfulResult()
    {
        // Arrange
        var value = "test value";

        // Act
        var result = ResultFactory.Success(value);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.False(result.IsFailure);
        Assert.Equal(value, result.Value);
    }

    [Fact]
    public void Failure_CreatesFailedResult()
    {
        // Arrange
        var error = new AxiomError("Validation", "Test error");

        // Act
        var result = ResultFactory.Failure<string>(error);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.True(result.IsFailure);
        Assert.Equal(error, result.Error);
    }

    [Fact]
    public void NotFound_CreatesNotFoundResult()
    {
        // Arrange & Act
        var result = ResultFactory.Failure<string>(new AxiomError("NOT_FOUND", "Resource not found"));

        // Assert
        Assert.False(result.IsSuccess);
        Assert.True(result.IsFailure);
        Assert.Equal("NOT_FOUND", result.Error.Code);
        Assert.Equal("Resource not found", result.Error.Message);
    }

    [Fact]
    public void NotFound_WithoutMessage_UsesDefaultMessage()
    {
        // Arrange & Act
        var result = ResultFactory.Failure<string>(new AxiomError("NOT_FOUND", "Resource not found"));

        // Assert
        Assert.False(result.IsSuccess);
        Assert.True(result.IsFailure);
        Assert.Equal("Resource not found", result.Error.Message);
    }

    [Fact]
    public void Value_OnFailedResult_ThrowsException()
    {
        // Arrange
        var result = ResultFactory.Failure<string>(new AxiomError("Validation", "Test error"));

        // Act & Assert
        Assert.Throws<InvalidOperationException>(() => result.Value);
    }

    [Fact]
    public void Error_OnSuccessfulResult_ThrowsException()
    {
        // Arrange
        var result = ResultFactory.Success("test");

        // Act & Assert
        Assert.Throws<InvalidOperationException>(() => result.Error);
    }

    [Fact]
    public void Match_OnSuccessfulResult_CallsSuccessFunction()
    {
        // Arrange
        var result = ResultFactory.Success("test");
        var successCalled = false;
        var failureCalled = false;

        // Act
        var output = result.Match(
            success: value => { successCalled = true; return value.ToUpper(CultureInfo.InvariantCulture); },
            failure: error => { failureCalled = true; return "ERROR"; }
        );

        // Assert
        Assert.True(successCalled);
        Assert.False(failureCalled);
        Assert.Equal("TEST", output);
    }

    [Fact]
    public void Match_OnFailedResult_CallsFailureFunction()
    {
        // Arrange
        var result = ResultFactory.Failure<string>(new AxiomError("Validation", "Test error"));
        var successCalled = false;
        var failureCalled = false;

        // Act
        var output = result.Match(
            success: value => { successCalled = true; return value.ToUpper(CultureInfo.InvariantCulture); },
            failure: error => { failureCalled = true; return $"ERROR: {error.Message}"; }
        );

        // Assert
        Assert.False(successCalled);
        Assert.True(failureCalled);
        Assert.Equal("ERROR: Test error", output);
    }

    [Theory]
    [InlineData("VALIDATION_ERROR", "VALIDATION_ERROR")]
    [InlineData("NOT_FOUND", "NOT_FOUND")]
    [InlineData("UNAUTHORIZED", "UNAUTHORIZED")]
    [InlineData("FORBIDDEN", "FORBIDDEN")]
    [InlineData("INTERNAL", "INTERNAL")]
    public void Error_StaticMethods_CreateCorrectErrorTypes(string errorCode, string expectedCode)
    {
        // Arrange & Act
        var error = new AxiomError(errorCode, "Test message");

        // Assert
        Assert.Equal(expectedCode, error.Code);
        Assert.Equal("Test message", error.Message);
    }
}