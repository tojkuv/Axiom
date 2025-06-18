using FluentAssertions;
using FluentAssertions.Execution;
using FluentAssertions.Primitives;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.Testing.Common.Assertions;

public static class EndpointAssertionExtensions
{
    public static ResultAssertions<T> Should<T>(this Result<T> result) => new(result);
    public static EndpointAssertions Should(this object endpoint) => new(endpoint);
}

public class EndpointAssertions : ReferenceTypeAssertions<object, EndpointAssertions>
{
    public EndpointAssertions(object instance) : base(instance) { }

    protected override string Identifier => "endpoint";

    public AndConstraint<EndpointAssertions> ImplementAxiom(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .Given(() => Subject)
            .ForCondition(endpoint => endpoint != null)
            .FailWith("Expected endpoint to implement IAxiom, but found <null>.")
            .Then
            .ForCondition(endpoint => endpoint!.GetType().GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IAxiom<,>)))
            .FailWith("Expected {0} to implement IAxiom<,>, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }

    public AndConstraint<EndpointAssertions> ImplementServerStreamAxiom(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .Given(() => Subject)
            .ForCondition(endpoint => endpoint != null)
            .FailWith("Expected endpoint to implement IServerStreamAxiom, but found <null>.")
            .Then
            .ForCondition(endpoint => endpoint!.GetType().GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IServerStreamAxiom<,>)))
            .FailWith("Expected {0} to implement IServerStreamAxiom<,>, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }

    public AndConstraint<EndpointAssertions> ImplementClientStreamAxiom(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .Given(() => Subject)
            .ForCondition(endpoint => endpoint != null)
            .FailWith("Expected endpoint to implement IClientStreamAxiom, but found <null>.")
            .Then
            .ForCondition(endpoint => endpoint!.GetType().GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IClientStreamAxiom<,>)))
            .FailWith("Expected {0} to implement IClientStreamAxiom<,>, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }

    public AndConstraint<EndpointAssertions> ImplementBidirectionalStreamAxiom(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .Given(() => Subject)
            .ForCondition(endpoint => endpoint != null)
            .FailWith("Expected endpoint to implement IBidirectionalStreamAxiom, but found <null>.")
            .Then
            .ForCondition(endpoint => endpoint!.GetType().GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IBidirectionalStreamAxiom<,>)))
            .FailWith("Expected {0} to implement IBidirectionalStreamAxiom<,>, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }

    public AndConstraint<EndpointAssertions> HaveHandleAsyncMethod(string because = "", params object[] becauseArgs)
    {
        var handleMethod = Subject?.GetType().GetMethod("HandleAsync");

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(handleMethod != null)
            .FailWith("Expected {0} to have HandleAsync method, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }

    public AndConstraint<EndpointAssertions> HaveStreamAsyncMethod(string because = "", params object[] becauseArgs)
    {
        var streamMethod = Subject?.GetType().GetMethod("StreamAsync");

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(streamMethod != null)
            .FailWith("Expected {0} to have StreamAsync method, but it does not.", Subject);

        return new AndConstraint<EndpointAssertions>(this);
    }
}

public class ResultAssertions<T> : ReferenceTypeAssertions<Result<T>, ResultAssertions<T>>
{
    public ResultAssertions(Result<T> instance) : base(instance) { }

    protected override string Identifier => "result";

    public AndConstraint<ResultAssertions<T>> BeSuccess(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject.IsSuccess)
            .FailWith("Expected result to be success, but found failure with error: {0}", 
                Subject.Error?.Message ?? "Unknown error");

        return new AndConstraint<ResultAssertions<T>>(this);
    }

    public AndConstraint<ResultAssertions<T>> BeFailure(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(!Subject.IsSuccess)
            .FailWith("Expected result to be failure, but found success with value: {0}", Subject.Value);

        return new AndConstraint<ResultAssertions<T>>(this);
    }

    public AndConstraint<ResultAssertions<T>> BeSuccessWithValue(T expectedValue, string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject.IsSuccess)
            .FailWith("Expected result to be success, but found failure with error: {0}", 
                Subject.Error?.Message ?? "Unknown error")
            .Then
            .ForCondition(Equals(Subject.Value, expectedValue))
            .FailWith("Expected result value to be {0}, but found {1}", expectedValue, Subject.Value);

        return new AndConstraint<ResultAssertions<T>>(this);
    }

    public AndConstraint<ResultAssertions<T>> BeFailureWithError(string expectedError, string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(!Subject.IsSuccess)
            .FailWith("Expected result to be failure, but found success with value: {0}", Subject.Value)
            .Then
            .ForCondition(Subject.Error?.Message == expectedError)
            .FailWith("Expected result error to be {0}, but found {1}", expectedError, Subject.Error?.Message);

        return new AndConstraint<ResultAssertions<T>>(this);
    }

    public AndConstraint<ResultAssertions<T>> HaveValue(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject.IsSuccess && Subject.Value != null)
            .FailWith("Expected result to have a value, but it does not.");

        return new AndConstraint<ResultAssertions<T>>(this);
    }

    public AndConstraint<ResultAssertions<T>> HaveError(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(!Subject.IsSuccess && Subject.Error != null)
            .FailWith("Expected result to have an error, but it does not.");

        return new AndConstraint<ResultAssertions<T>>(this);
    }
}