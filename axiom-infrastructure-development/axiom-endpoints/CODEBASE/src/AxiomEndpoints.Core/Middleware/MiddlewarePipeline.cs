using System.Collections.Concurrent;
using System.Collections.Frozen;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// High-performance middleware pipeline with minimal allocations
/// </summary>
public sealed class MiddlewarePipeline<TRequest, TResponse> : IMiddlewarePipeline<TRequest, TResponse>
{
    private readonly FrozenSet<IEndpointFilter> _filters;
    private readonly FrozenSet<IEndpointResultFilter> _resultFilters;
    private readonly FrozenSet<IEndpointExceptionFilter> _exceptionFilters;
    private readonly EndpointMetadata _metadata;

    public MiddlewarePipeline(
        IEnumerable<IEndpointFilter> filters,
        IEnumerable<IEndpointResultFilter> resultFilters,
        IEnumerable<IEndpointExceptionFilter> exceptionFilters,
        EndpointMetadata metadata)
    {
        _filters = filters.OrderBy(f => f.Order).ToFrozenSet();
        _resultFilters = resultFilters.OrderBy(f => f.Order).ToFrozenSet();
        _exceptionFilters = exceptionFilters.OrderBy(f => f.Order).ToFrozenSet();
        _metadata = metadata;
    }

    public async ValueTask<Result<TResponse>> ExecuteAsync(
        TRequest request,
        IContext context,
        Func<TRequest, IContext, ValueTask<Result<TResponse>>> handler)
    {
        var filterContext = new EndpointFilterContext
        {
            Context = context,
            Metadata = _metadata,
            Request = request!,
            EndpointType = _metadata.EndpointType,
            Properties = FrozenDictionary<string, object>.Empty
        };

        try
        {
            // Execute pre-filters
            foreach (var filter in _filters.Where(f => f.IsEnabled(context)))
            {
                var filterResult = await filter.OnExecutingAsync(filterContext);
                if (filterResult.IsFailure)
                {
                    return ResultFactory.Failure<TResponse>(filterResult.Error);
                }
            }

            // Execute handler
            var result = await handler(request, context);

            // Execute post-filters
            foreach (var resultFilter in _resultFilters.Where(f => f.IsEnabled(context)))
            {
                result = await resultFilter.OnExecutedAsync(result, filterContext);
            }

            return result;
        }
        catch (Exception ex)
        {
            // Execute exception filters
            foreach (var exceptionFilter in _exceptionFilters.Where(f => f.IsEnabled(context)))
            {
                var handled = await exceptionFilter.OnExceptionAsync<TResponse>(ex, filterContext);
                if (handled.IsSuccess || handled.Error.Type != ErrorType.Internal)
                {
                    return handled;
                }
            }

            // Unhandled exception
            return ResultFactory.Failure<TResponse>(new AxiomError(
                "INTERNAL_ERROR",
                "An unexpected error occurred",
                ErrorType.Internal));
        }
    }
}

/// <summary>
/// Pipeline factory with caching
/// </summary>
public sealed class MiddlewarePipelineFactory
{
    private readonly ConcurrentDictionary<Type, object> _pipelineCache = new();
    private readonly IServiceProvider _services;

    public MiddlewarePipelineFactory(IServiceProvider services)
    {
        _services = services;
    }

    public IMiddlewarePipeline<TRequest, TResponse> GetOrCreate<TEndpoint, TRequest, TResponse>()
        where TEndpoint : IAxiom<TRequest, TResponse>
    {
        return (IMiddlewarePipeline<TRequest, TResponse>)_pipelineCache.GetOrAdd(
            typeof(TEndpoint),
            _ => CreatePipeline<TEndpoint, TRequest, TResponse>());
    }

    public IMiddlewarePipeline<TRequest, TResponse> GetOrCreate<TRequest, TResponse>(Type endpointType)
    {
        return (IMiddlewarePipeline<TRequest, TResponse>)_pipelineCache.GetOrAdd(
            endpointType,
            _ => CreatePipeline<TRequest, TResponse>(endpointType));
    }

    private IMiddlewarePipeline<TRequest, TResponse> CreatePipeline<TEndpoint, TRequest, TResponse>()
        where TEndpoint : IAxiom<TRequest, TResponse>
    {
        return CreatePipeline<TRequest, TResponse>(typeof(TEndpoint));
    }

    private IMiddlewarePipeline<TRequest, TResponse> CreatePipeline<TRequest, TResponse>(Type endpointType)
    {
        // Get attributes from endpoint
        var attributes = endpointType.GetCustomAttributes(true)
            .OfType<IEndpointMiddleware>()
            .ToList();

        // Create pipeline
        return new MiddlewarePipeline<TRequest, TResponse>(
            attributes.OfType<IEndpointFilter>(),
            attributes.OfType<IEndpointResultFilter>(),
            attributes.OfType<IEndpointExceptionFilter>(),
            EndpointMetadata.FromType(endpointType));
    }
}