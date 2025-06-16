using AxiomEndpoints.Core;
using FluentAssertions;

namespace AxiomEndpoints.Testing.Common.Assertions;

/// <summary>
/// Extensions for FluentAssertions to work with Result types
/// </summary>
public static class ResultAssertionExtensions
{
    public static void BeSuccess<T>(this FluentAssertions.Primitives.ObjectAssertions assertions)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeTrue($"Expected success but got error: {result.Error?.Message}");
    }

    public static void BeFailure<T>(this FluentAssertions.Primitives.ObjectAssertions assertions)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeFalse("Expected failure but got success");
    }

    public static AndConstraint<FluentAssertions.Primitives.ObjectAssertions> BeSuccess<T>(
        this FluentAssertions.Primitives.ObjectAssertions assertions,
        string because,
        params object[] becauseArgs)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeTrue(because, becauseArgs);
        return new AndConstraint<FluentAssertions.Primitives.ObjectAssertions>(assertions);
    }

    public static AndConstraint<FluentAssertions.Primitives.ObjectAssertions> BeFailure<T>(
        this FluentAssertions.Primitives.ObjectAssertions assertions,
        string because,
        params object[] becauseArgs)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeFalse(because, becauseArgs);
        return new AndConstraint<FluentAssertions.Primitives.ObjectAssertions>(assertions);
    }

    public static AndConstraint<FluentAssertions.Primitives.ObjectAssertions> HaveValue<T>(
        this FluentAssertions.Primitives.ObjectAssertions assertions,
        T expectedValue)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeTrue("Expected result to be successful to have a value");
        FluentAssertions.AssertionExtensions.Should((object?)result.Value).Be(expectedValue);
        return new AndConstraint<FluentAssertions.Primitives.ObjectAssertions>(assertions);
    }

    public static AndConstraint<FluentAssertions.Primitives.ObjectAssertions> HaveError<T>(
        this FluentAssertions.Primitives.ObjectAssertions assertions,
        AxiomError expectedError)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsFailure.Should().BeTrue("Expected result to be a failure to have an error");
        FluentAssertions.AssertionExtensions.Should((object?)result.Error).Be(expectedError);
        return new AndConstraint<FluentAssertions.Primitives.ObjectAssertions>(assertions);
    }
}