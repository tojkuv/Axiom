using System.Collections.ObjectModel;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Core.Middleware;

namespace AxiomEndpoints.AspNetCore;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddAxiomEndpoints(
        this IServiceCollection services,
        Action<AxiomOptions>? configure = null)
    {
        var options = new AxiomOptions();
        configure?.Invoke(options);

        services.AddSingleton(options);
        services.AddSingleton<TimeProvider>(TimeProvider.System);
        services.AddScoped<IContext, DefaultContext>();
        services.AddHttpContextAccessor();

        // Register middleware services
        if (options.UseMiddlewarePipeline)
        {
            services.AddSingleton<MiddlewarePipelineFactory>();
            services.AddSingleton<IRateLimiterService, DefaultRateLimiterService>();
            services.AddScoped<IAuditLogger, DefaultAuditLogger>();
            services.AddSingleton<IFeatureManager, DefaultFeatureManager>();
        }

        // Use generated registration - placeholder until source generator is working
        // Generated.EndpointRegistration.RegisterEndpoints(services);

        // Fallback: Scan for endpoints not covered by generator
        var endpointTypes = options.AssembliesToScan
            .SelectMany(a => a.GetTypes())
            .Where(IsEndpointType)
            .ToList();

        foreach (var endpointType in endpointTypes)
        {
            services.AddScoped(endpointType);
        }

        return services;
    }

    internal static bool IsEndpointType(Type type)
    {
        if (!type.IsClass || type.IsAbstract)
            return false;

        return type.GetInterfaces().Any(i =>
            i.IsGenericType &&
            (i.GetGenericTypeDefinition() == typeof(IAxiom<,>) ||
             i.GetGenericTypeDefinition() == typeof(IAxiom<,,>) ||
             i.GetGenericTypeDefinition() == typeof(IRouteAxiom<,>) ||
             i.GetGenericTypeDefinition() == typeof(IServerStreamAxiom<,>) ||
             i.GetGenericTypeDefinition() == typeof(IClientStreamAxiom<,>) ||
             i.GetGenericTypeDefinition() == typeof(IBidirectionalStreamAxiom<,>)));
    }
}

public class AxiomOptions
{
    public Collection<Assembly> AssembliesToScan { get; } = new([Assembly.GetCallingAssembly()]);
    public bool UseMiddlewarePipeline { get; set; } = true;
    public bool EnableDetailedErrors { get; set; } = false;
}