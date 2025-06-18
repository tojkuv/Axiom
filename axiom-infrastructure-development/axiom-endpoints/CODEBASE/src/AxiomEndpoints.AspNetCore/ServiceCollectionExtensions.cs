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

        // Generated registration will be available after source generation
        // For now, rely on manual discovery until generators create the registration classes

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
    public Collection<Assembly> AssembliesToScan { get; } = new();
    public bool UseMiddlewarePipeline { get; set; } = true;
    public bool EnableDetailedErrors { get; set; } = false;
    
    public AxiomOptions()
    {
        // Get the assembly that called AddAxiomEndpoints
        var callingAssembly = Assembly.GetCallingAssembly();
        
        // If the calling assembly is a framework assembly, scan the entry assembly instead
        if (IsFrameworkAssembly(callingAssembly))
        {
            var entryAssembly = Assembly.GetEntryAssembly();
            if (entryAssembly != null && !IsFrameworkAssembly(entryAssembly))
            {
                AssembliesToScan.Add(entryAssembly);
            }
        }
        else
        {
            AssembliesToScan.Add(callingAssembly);
        }
        
        // Also scan all loaded assemblies that might contain endpoints
        var loadedAssemblies = AppDomain.CurrentDomain.GetAssemblies()
            .Where(a => !IsFrameworkAssembly(a) && ContainsEndpointTypes(a))
            .ToArray();
            
        foreach (var assembly in loadedAssemblies)
        {
            if (!AssembliesToScan.Contains(assembly))
            {
                AssembliesToScan.Add(assembly);
            }
        }
    }
    
    private static bool IsFrameworkAssembly(Assembly assembly)
    {
        var name = assembly.GetName().Name ?? "";
        return name.StartsWith("Microsoft.") || 
               name.StartsWith("System.") || 
               name.StartsWith("AxiomEndpoints.") ||
               name.StartsWith("netstandard") ||
               name.StartsWith("mscorlib");
    }
    
    private static bool ContainsEndpointTypes(Assembly assembly)
    {
        try
        {
            return assembly.GetTypes().Any(type => 
                !type.IsAbstract && 
                type.IsClass && 
                type.GetInterfaces().Any(i => 
                    i.IsGenericType && 
                    (i.GetGenericTypeDefinition() == typeof(IAxiom<,>) ||
                     i.GetGenericTypeDefinition() == typeof(IAxiom<,,>) ||
                     i.GetGenericTypeDefinition() == typeof(IRouteAxiom<,>) ||
                     i.GetGenericTypeDefinition() == typeof(IServerStreamAxiom<,>) ||
                     i.GetGenericTypeDefinition() == typeof(IClientStreamAxiom<,>) ||
                     i.GetGenericTypeDefinition() == typeof(IBidirectionalStreamAxiom<,>))));
        }
        catch
        {
            return false;
        }
    }
}