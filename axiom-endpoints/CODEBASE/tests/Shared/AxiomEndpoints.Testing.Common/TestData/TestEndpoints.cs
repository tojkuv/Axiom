using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.Testing.Common.TestData;

public sealed record TestRequest(string Message);
public sealed record TestResponse(string Message);
public sealed record ErrorResponse(string Error, int Code);

public sealed class TestServerStreamEndpoint : IServerStreamAxiom<TestRequest, TestResponse>
{
    public async IAsyncEnumerable<TestResponse> StreamAsync(TestRequest request, IContext context)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(context);
        
        for (int i = 0; i < 3; i++)
        {
            context.CancellationToken.ThrowIfCancellationRequested();
            
            yield return new TestResponse($"Response {i}");
            
            if (i < 2)
            {
                await Task.Delay(100, context.CancellationToken).ConfigureAwait(false);
            }
        }
    }
}

public sealed class TestClientStreamEndpoint : IClientStreamAxiom<TestRequest, TestResponse>
{
    public async ValueTask<Result<TestResponse>> HandleAsync(IAsyncEnumerable<TestRequest> requests, IContext context)
    {
        ArgumentNullException.ThrowIfNull(requests);
        ArgumentNullException.ThrowIfNull(context);
        
        var count = 0;
        await foreach (var request in requests.WithCancellation(context.CancellationToken).ConfigureAwait(false))
        {
            count++;
        }
        
        return ResultFactory.Success(new TestResponse($"Processed {count} requests"));
    }
}

public sealed class TestBidirectionalStreamEndpoint : IBidirectionalStreamAxiom<TestRequest, TestResponse>
{
    public async IAsyncEnumerable<TestResponse> StreamAsync(IAsyncEnumerable<TestRequest> requests, IContext context)
    {
        await foreach (var request in requests.WithCancellation(context.CancellationToken).ConfigureAwait(false))
        {
            yield return new TestResponse($"Echo: {request.Message}");
        }
    }
}

public sealed class SimpleEndpoint : IAxiom<TestRequest, TestResponse>
{
    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(context);

        await Task.Delay(10, context.CancellationToken);
        return ResultFactory.Success(new TestResponse($"Processed: {request.Message}"));
    }
}

public sealed class ErrorEndpoint : IAxiom<TestRequest, TestResponse>
{
    public ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(context);

        return ValueTask.FromResult(ResultFactory.Failure<TestResponse>(AxiomError.Validation("Test error")));
    }
}

public sealed class ThrowingEndpoint : IAxiom<TestRequest, TestResponse>
{
    public ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
    {
        throw new InvalidOperationException("Test exception");
    }
}

public sealed class CancellationEndpoint : IAxiom<TestRequest, TestResponse>
{
    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
    {
        await Task.Delay(5000, context.CancellationToken);
        return ResultFactory.Success(new TestResponse("Should not reach here"));
    }
}

public sealed class NoParametersEndpoint : IAxiom<EmptyRequest, TestResponse>
{
    public ValueTask<Result<TestResponse>> HandleAsync(EmptyRequest request, IContext context)
    {
        return ValueTask.FromResult(ResultFactory.Success(new TestResponse("No parameters")));
    }
}

public sealed record EmptyRequest;

public static class TestEndpointFactory
{
    public static TestServerStreamEndpoint CreateServerStreamEndpoint() => new();
    public static TestClientStreamEndpoint CreateClientStreamEndpoint() => new();
    public static TestBidirectionalStreamEndpoint CreateBidirectionalStreamEndpoint() => new();
    public static SimpleEndpoint CreateSimpleEndpoint() => new();
    public static ErrorEndpoint CreateErrorEndpoint() => new();
    public static ThrowingEndpoint CreateThrowingEndpoint() => new();
    public static CancellationEndpoint CreateCancellationEndpoint() => new();
    public static NoParametersEndpoint CreateNoParametersEndpoint() => new();
}