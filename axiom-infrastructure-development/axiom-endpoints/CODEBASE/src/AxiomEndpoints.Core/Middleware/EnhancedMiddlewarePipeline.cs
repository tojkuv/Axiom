using System.Collections.Concurrent;
using System.Collections.Frozen;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Enhanced middleware pipeline that leverages focused metadata types
/// </summary>
public sealed class EnhancedMiddlewarePipeline<TRequest, TResponse> : IMiddlewarePipeline<TRequest, TResponse>
{
    private readonly FrozenSet<IEndpointFilter> _filters;
    private readonly FrozenSet<IEndpointResultFilter> _resultFilters;
    private readonly FrozenSet<IEndpointExceptionFilter> _exceptionFilters;
    private readonly EndpointMetadata _metadata;

    public EnhancedMiddlewarePipeline(
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
        var filterContext = CreateFilterContext(request, context);

        try
        {
            // Execute pre-filters with metadata-aware filtering
            await ExecutePreFiltersAsync(filterContext);

            // Execute handler
            var result = await handler(request, context);

            // Execute post-filters with metadata-aware processing
            result = await ExecutePostFiltersAsync(result, filterContext);

            return result;
        }
        catch (Exception ex)
        {
            // Execute exception filters with metadata context
            return await ExecuteExceptionFiltersAsync(ex, filterContext);
        }
    }

    private EndpointFilterContext CreateFilterContext(TRequest request, IContext context)
    {
        // Enhanced context with access to focused metadata
        var properties = new Dictionary<string, object>
        {
            ["AuthMetadata"] = _metadata.Auth,
            ["CacheMetadata"] = _metadata.Cache,
            ["RateLimitMetadata"] = _metadata.RateLimit,
            ["DocsMetadata"] = _metadata.Docs
        };

        return new EndpointFilterContext
        {
            Context = context,
            Metadata = _metadata,
            Request = request!,
            EndpointType = _metadata.EndpointType,
            Properties = properties.ToFrozenDictionary()
        };
    }

    private async ValueTask ExecutePreFiltersAsync(EndpointFilterContext filterContext)
    {
        // Skip auth filters if endpoint allows anonymous access
        var enabledFilters = _filters.Where(f => ShouldExecuteFilter(f, filterContext));

        foreach (var filter in enabledFilters)
        {
            var filterResult = await filter.OnExecutingAsync(filterContext);
            if (filterResult.IsFailure)
            {
                throw new MiddlewareException(filterResult.Error);
            }
        }
    }

    private async ValueTask<Result<TResponse>> ExecutePostFiltersAsync(
        Result<TResponse> result, 
        EndpointFilterContext filterContext)
    {
        // Apply result filters based on metadata
        var enabledFilters = _resultFilters.Where(f => ShouldExecuteFilter(f, filterContext));

        foreach (var resultFilter in enabledFilters)
        {
            result = await resultFilter.OnExecutedAsync(result, filterContext);
        }

        return result;
    }

    private async ValueTask<Result<TResponse>> ExecuteExceptionFiltersAsync(
        Exception exception, 
        EndpointFilterContext filterContext)
    {
        var enabledFilters = _exceptionFilters.Where(f => ShouldExecuteFilter(f, filterContext));

        foreach (var exceptionFilter in enabledFilters)
        {
            var handled = await exceptionFilter.OnExceptionAsync<TResponse>(exception, filterContext);
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

    private bool ShouldExecuteFilter(IEndpointMiddleware filter, EndpointFilterContext context)
    {
        // Skip execution based on metadata-aware logic
        return filter switch
        {
            // Skip auth filters for anonymous endpoints
            IEndpointFilter authFilter when IsAuthFilter(authFilter) && _metadata.Auth.AllowAnonymous => false,
            
            // Skip cache filters if no caching configured
            IEndpointResultFilter cacheFilter when IsCacheFilter(cacheFilter) && _metadata.Cache.CachePolicy == null => false,
            
            // Skip rate limiting filters if no policy configured
            IEndpointFilter rateLimitFilter when IsRateLimitFilter(rateLimitFilter) && _metadata.RateLimit.RateLimitPolicy == null => false,
            
            // Default enabled check
            _ => filter.IsEnabled(context.Context)
        };
    }

    private static bool IsAuthFilter(IEndpointMiddleware filter) =>
        filter.GetType().Name.Contains("Auth", StringComparison.OrdinalIgnoreCase);

    private static bool IsCacheFilter(IEndpointMiddleware filter) =>
        filter.GetType().Name.Contains("Cache", StringComparison.OrdinalIgnoreCase);

    private static bool IsRateLimitFilter(IEndpointMiddleware filter) =>
        filter.GetType().Name.Contains("RateLimit", StringComparison.OrdinalIgnoreCase);
}

/// <summary>
/// Enhanced pipeline factory that creates metadata-aware pipelines
/// </summary>
public sealed class EnhancedMiddlewarePipelineFactory
{
    private readonly ConcurrentDictionary<Type, object> _pipelineCache = new();
    private readonly IServiceProvider _services;

    public EnhancedMiddlewarePipelineFactory(IServiceProvider services)
    {
        _services = services;
    }

    public IMiddlewarePipeline<TRequest, TResponse> GetOrCreate<TEndpoint, TRequest, TResponse>(
        AuthMetadata? authMetadata = null,
        CacheMetadata? cacheMetadata = null,
        RateLimitMetadata? rateLimitMetadata = null,
        DocsMetadata? docsMetadata = null)
        where TEndpoint : IAxiom<TRequest, TResponse>
    {
        return (IMiddlewarePipeline<TRequest, TResponse>)_pipelineCache.GetOrAdd(
            typeof(TEndpoint),
            _ => CreateEnhancedPipeline<TEndpoint, TRequest, TResponse>(
                authMetadata, cacheMetadata, rateLimitMetadata, docsMetadata));
    }

    private IMiddlewarePipeline<TRequest, TResponse> CreateEnhancedPipeline<TEndpoint, TRequest, TResponse>(
        AuthMetadata? authMetadata,
        CacheMetadata? cacheMetadata,
        RateLimitMetadata? rateLimitMetadata,
        DocsMetadata? docsMetadata)
        where TEndpoint : IAxiom<TRequest, TResponse>
    {
        var endpointType = typeof(TEndpoint);
        
        // Get attributes from endpoint
        var attributes = endpointType.GetCustomAttributes(true)
            .OfType<IEndpointMiddleware>()
            .ToList();

        // Create enhanced metadata with focused types
        var metadata = EndpointMetadata.Create(
            endpointType,
            $"/{endpointType.Name.ToLowerInvariant()}",
            HttpMethod.Get,
            typeof(TRequest),
            typeof(TResponse),
            authMetadata,
            cacheMetadata,
            rateLimitMetadata,
            docsMetadata);

        // Create enhanced pipeline
        return new EnhancedMiddlewarePipeline<TRequest, TResponse>(
            attributes.OfType<IEndpointFilter>(),
            attributes.OfType<IEndpointResultFilter>(),
            attributes.OfType<IEndpointExceptionFilter>(),
            metadata);
    }
}

/// <summary>
/// Exception thrown by middleware to short-circuit execution
/// </summary>
public class MiddlewareException : Exception
{
    public AxiomError Error { get; }

    public MiddlewareException(AxiomError error) : base(error.Message)
    {
        Error = error;
    }
}