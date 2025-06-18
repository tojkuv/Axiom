using System.Net.Http;

namespace AxiomEndpoints.Core;

/// <summary>
/// Base endpoint interface for unary operations
/// </summary>
public interface IAxiom<TRequest, TResponse>
{
    ValueTask<Result<TResponse>> HandleAsync(TRequest request, IContext context);
}

/// <summary>
/// Endpoint with route type for HTTP/gRPC mapping
/// </summary>
public interface IAxiom<TRoute, TRequest, TResponse> : IAxiom<TRequest, TResponse>
    where TRoute : IRoute<TRoute>
{
    static virtual HttpMethod Method => HttpMethod.Get;
}

/// <summary>
/// Marker for endpoints that handle routes directly
/// </summary>
public interface IRouteAxiom<TRoute, TResponse> : IAxiom<TRoute, TResponse>
    where TRoute : IRoute<TRoute>
{
}