using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AxiomEndpoints.Core;
using System.Reflection;
using System.Buffers;
using System.Linq;
using Grpc.AspNetCore.Server;
using Grpc.AspNetCore.Web;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Extension methods for configuring Axiom gRPC services
/// </summary>
public static class GrpcServiceExtensions
{
    /// <summary>
    /// Adds Axiom gRPC services to the service collection
    /// </summary>
    public static IServiceCollection AddAxiomGrpc(
        this IServiceCollection services,
        Action<AxiomGrpcOptions>? configure = null)
    {
        var options = new AxiomGrpcOptions();
        configure?.Invoke(options);

        // Add core gRPC services
        services.AddGrpc(grpcOptions =>
        {
            grpcOptions.EnableDetailedErrors = options.EnableDetailedErrors;
            grpcOptions.MaxReceiveMessageSize = options.MaxReceiveMessageSize;
            grpcOptions.MaxSendMessageSize = options.MaxSendMessageSize;
            // grpcOptions.CompressionProviders = options.CompressionProviders; // Requires ICompressionProvider interface
            
            // Add global interceptors
            foreach (var interceptorType in options.GlobalInterceptors)
            {
                grpcOptions.Interceptors.Add(interceptorType);
            }
        });

        // Add gRPC-Web support if enabled
        if (options.EnableGrpcWeb)
        {
            // services.AddGrpcWeb(grpcWebOptions =>
            // {
            //     grpcWebOptions.GrpcWebEnabled = true;
            //     grpcWebOptions.DefaultEnabled = options.GrpcWebDefaultEnabled;
            // });
        }

        // Add CORS if configured
        if (options.CorsPolicy != null)
        {
            services.AddCors(corsOptions =>
            {
                corsOptions.AddPolicy("AxiomGrpcCors", options.CorsPolicy);
            });
        }

        // Add protocol negotiation
        services.AddSingleton<IProtocolNegotiator, DefaultProtocolNegotiator>();

        // Add context factory
        services.AddScoped<IContextFactory, DefaultContextFactory>();

        // Add gRPC reflection in development
        if (options.EnableReflection)
        {
            // services.AddGrpcReflection(); // Requires Grpc.AspNetCore.Server.Reflection package
        }

        // Add health checks if enabled
        if (options.EnableHealthChecks)
        {
            // services.AddGrpcHealthChecks(); // Requires Grpc.HealthCheck package
        }

        // Register generated gRPC services from assemblies
        foreach (var assembly in options.AssembliesToScan)
        {
            RegisterGrpcServicesFromAssembly(services, assembly);
        }

        return services;
    }

    /// <summary>
    /// Maps Axiom gRPC services to the application
    /// </summary>
    public static WebApplication MapAxiomGrpcServices(
        this WebApplication app,
        Action<AxiomGrpcMappingOptions>? configure = null)
    {
        var options = new AxiomGrpcMappingOptions();
        configure?.Invoke(options);

        // Use CORS if configured
        if (options.UseCors)
        {
            app.UseCors("AxiomGrpcCors");
        }

        // Add protocol routing middleware
        app.UseMiddleware<ProtocolRoutingMiddleware>();

        // Enable gRPC-Web if configured
        if (options.EnableGrpcWeb)
        {
            // app.UseGrpcWeb(new GrpcWebOptions 
            // { 
            //     DefaultEnabled = options.GrpcWebDefaultEnabled 
            // });
        }

        // Map generated gRPC services
        var serviceRegistrationType = FindServiceRegistrationType(app.Services);
        if (serviceRegistrationType != null)
        {
            var mapMethod = serviceRegistrationType.GetMethod("MapGrpcServices");
            mapMethod?.Invoke(null, new object[] { app });
        }

        // Map gRPC reflection in development
        if (app.Environment.IsDevelopment() && options.EnableReflection)
        {
            // app.MapGrpcReflectionService(); // Requires Grpc.AspNetCore.Server.Reflection package
        }

        // Map health checks if enabled
        if (options.EnableHealthChecks)
        {
            // app.MapGrpcHealthChecksService(); // Requires Grpc.HealthCheck package
        }

        return app;
    }

    /// <summary>
    /// Adds unified endpoint mapping that supports both HTTP and gRPC
    /// </summary>
    public static IServiceCollection AddUnifiedEndpointMapping(
        this IServiceCollection services,
        params Assembly[] assemblies)
    {
        // Register endpoint types for dependency injection
        foreach (var assembly in assemblies)
        {
            var endpointTypes = assembly.GetTypes()
                .Where(IsEndpointType)
                .ToList();

            foreach (var endpointType in endpointTypes)
            {
                services.AddScoped(endpointType);
            }
        }

        return services;
    }

    /// <summary>
    /// Maps unified endpoints that support multiple protocols
    /// </summary>
    public static WebApplication MapUnifiedEndpoints(
        this WebApplication app,
        params Assembly[] assemblies)
    {
        foreach (var assembly in assemblies)
        {
            app.MapUnifiedEndpoints(assembly);
        }

        return app;
    }

    private static void RegisterGrpcServicesFromAssembly(IServiceCollection services, Assembly assembly)
    {
        // Look for generated service implementations
        var serviceTypes = assembly.GetTypes()
            .Where(t => t.Name.EndsWith("Implementation") && t.BaseType?.Name.EndsWith("Base") == true)
            .ToList();

        foreach (var serviceType in serviceTypes)
        {
            services.AddScoped(serviceType);
        }
    }

    private static Type? FindServiceRegistrationType(IServiceProvider services)
    {
        // Look for the generated ServiceRegistration type
        var assemblies = AppDomain.CurrentDomain.GetAssemblies();
        
        foreach (var assembly in assemblies)
        {
            var type = assembly.GetTypes()
                .FirstOrDefault(t => t.Name == "ServiceRegistration" && 
                                   t.Namespace?.Contains("Generated.Grpc") == true);
            if (type != null)
            {
                return type;
            }
        }

        return null;
    }

    private static bool IsEndpointType(Type type)
    {
        return type.GetInterfaces().Any(i =>
            i.IsGenericType &&
            (i.Name == "IAxiom" || i.Name == "IRouteAxiom" ||
             i.Name.Contains("StreamAxiom")));
    }
}

/// <summary>
/// Configuration options for Axiom gRPC services
/// </summary>
public class AxiomGrpcOptions
{
    /// <summary>
    /// Whether to enable detailed error messages in development
    /// </summary>
    public bool EnableDetailedErrors { get; set; } = true;

    /// <summary>
    /// Maximum message size for receiving (in bytes)
    /// </summary>
    public int? MaxReceiveMessageSize { get; set; } = 10 * 1024 * 1024; // 10MB

    /// <summary>
    /// Maximum message size for sending (in bytes)
    /// </summary>
    public int? MaxSendMessageSize { get; set; } = 10 * 1024 * 1024; // 10MB

    /// <summary>
    /// Compression providers to use
    /// </summary>
    public IList<string> CompressionProviders { get; set; } = new List<string> { "gzip" };

    /// <summary>
    /// Global interceptors to apply to all services
    /// </summary>
    public IList<Type> GlobalInterceptors { get; set; } = new List<Type>();

    /// <summary>
    /// Whether to enable gRPC-Web support
    /// </summary>
    public bool EnableGrpcWeb { get; set; } = true;

    /// <summary>
    /// Whether gRPC-Web is enabled by default for all services
    /// </summary>
    public bool GrpcWebDefaultEnabled { get; set; } = true;

    /// <summary>
    /// CORS policy for gRPC-Web (if null, no CORS will be configured)
    /// </summary>
    public Action<Microsoft.AspNetCore.Cors.Infrastructure.CorsPolicyBuilder>? CorsPolicy { get; set; }

    /// <summary>
    /// Whether to enable gRPC reflection
    /// </summary>
    public bool EnableReflection { get; set; } = true;

    /// <summary>
    /// Whether to enable gRPC health checks
    /// </summary>
    public bool EnableHealthChecks { get; set; } = true;

    /// <summary>
    /// Assemblies to scan for gRPC services
    /// </summary>
    public IList<Assembly> AssembliesToScan { get; set; } = new List<Assembly>();
}

/// <summary>
/// Configuration options for mapping Axiom gRPC services
/// </summary>
public class AxiomGrpcMappingOptions
{
    /// <summary>
    /// Whether to use CORS middleware
    /// </summary>
    public bool UseCors { get; set; } = true;

    /// <summary>
    /// Whether to enable gRPC-Web
    /// </summary>
    public bool EnableGrpcWeb { get; set; } = true;

    /// <summary>
    /// Whether gRPC-Web is enabled by default
    /// </summary>
    public bool GrpcWebDefaultEnabled { get; set; } = true;

    /// <summary>
    /// Whether to enable gRPC reflection
    /// </summary>
    public bool EnableReflection { get; set; } = true;

    /// <summary>
    /// Whether to enable health checks
    /// </summary>
    public bool EnableHealthChecks { get; set; } = true;
}

/// <summary>
/// Default implementation of context factory
/// </summary>
public class DefaultContextFactory : IContextFactory
{
    private readonly IServiceProvider _services;

    public DefaultContextFactory(IServiceProvider services)
    {
        _services = services;
    }

    public IContext CreateContext()
    {
        // This is a simplified implementation
        // In a real scenario, this would create a proper context with HTTP context information
        return new SimpleContext(_services);
    }
}

/// <summary>
/// Simple context implementation for testing/fallback scenarios
/// </summary>
internal class SimpleContext : IContext
{
    public HttpContext HttpContext => throw new NotSupportedException("HttpContext not available in gRPC context");
    public IServiceProvider Services { get; }
    public CancellationToken CancellationToken { get; set; } = CancellationToken.None;
    public TimeProvider TimeProvider { get; }

    public SimpleContext(IServiceProvider services)
    {
        Services = services;
        TimeProvider = services.GetService<TimeProvider>() ?? TimeProvider.System;
    }

    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        throw new NotSupportedException("Route values not available in gRPC context");
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        return null;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        return null;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        return Enumerable.Empty<T>();
    }

    public bool HasQueryParameter(string key)
    {
        return false;
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("Location header not available in gRPC context");
    }
}