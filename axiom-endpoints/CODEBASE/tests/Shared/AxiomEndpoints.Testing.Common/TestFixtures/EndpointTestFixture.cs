using AxiomEndpoints.Core;
using AxiomEndpoints.Testing.Common.MockServices;
using Microsoft.AspNetCore.Http;

namespace AxiomEndpoints.Testing.Common.TestFixtures;

public class EndpointTestFixture : IDisposable
{
    private bool _disposed;

    public IContext Context { get; } = new MockContext();
    public HttpContext HttpContext { get; } = new DefaultHttpContext();

    public virtual void Dispose()
    {
        if (!_disposed)
        {
            _disposed = true;
        }
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed && disposing)
        {
            // Cleanup resources
        }
    }
}

public abstract class EndpointTestFixture<TEndpoint> : EndpointTestFixture
{
    public abstract TEndpoint CreateEndpoint();

    protected virtual TResponse ExecuteEndpoint<TRequest, TResponse>(
        Func<TRequest, IContext, TResponse> endpointHandler,
        TRequest request)
    {
        return endpointHandler(request, Context);
    }

    protected virtual async Task<TResponse> ExecuteEndpointAsync<TRequest, TResponse>(
        Func<TRequest, IContext, Task<TResponse>> endpointHandler,
        TRequest request)
    {
        return await endpointHandler(request, Context);
    }
}