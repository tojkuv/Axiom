using System.Net.Http.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Aspire.ServiceDiscovery;

/// <summary>
/// Aspire-based service discovery for Axiom endpoints
/// </summary>
public class AspireServiceDiscovery : IAxiomServiceDiscovery
{
    private readonly object _serviceDiscovery;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AspireServiceDiscovery> _logger;
    private readonly IMemoryCache _cache;

    public AspireServiceDiscovery(
        object serviceDiscovery,
        IConfiguration configuration,
        ILogger<AspireServiceDiscovery> logger,
        IMemoryCache cache)
    {
        _serviceDiscovery = serviceDiscovery;
        _configuration = configuration;
        _logger = logger;
        _cache = cache;
    }

    public async ValueTask<Uri?> ResolveEndpointAsync<TEndpoint>(CancellationToken ct = default)
        where TEndpoint : IAxiom<object, object>
    {
        var endpointName = typeof(TEndpoint).Name;

        // Check configuration first
        var configuredUrl = _configuration[$"endpoints:{endpointName}"];
        if (!string.IsNullOrEmpty(configuredUrl))
        {
            return new Uri(configuredUrl);
        }

        // Try service discovery
        var serviceName = GetServiceNameForEndpoint<TEndpoint>();
        if (serviceName != null)
        {
            return await ResolveServiceAsync(serviceName, ct);
        }

        return null;
    }

    public ValueTask<Uri?> ResolveServiceAsync(string serviceName, CancellationToken ct = default)
    {
        // Check cache first
        if (_cache.TryGetValue<Uri>($"service:{serviceName}", out var cached))
        {
            return ValueTask.FromResult<Uri?>(cached);
        }

        try
        {
            // TODO: Use Aspire service discovery when proper types are available
            // var endpoints = await _serviceDiscovery.GetEndpointsAsync(serviceName, ct);
            // var endpoint = endpoints.FirstOrDefault();

            // For now, return null to indicate service discovery is not yet implemented
            return ValueTask.FromResult<Uri?>(null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to resolve service {ServiceName}", serviceName);
        }

        return ValueTask.FromResult<Uri?>(null);
    }

    public async ValueTask<IReadOnlyList<EndpointInfo>> DiscoverEndpointsAsync(CancellationToken ct = default)
    {
        var endpoints = new List<EndpointInfo>();

        // Discover from all registered Axiom services
        var services = _configuration.GetSection("services").GetChildren();

        foreach (var service in services)
        {
            var serviceName = service.Key;
            var serviceUrl = await ResolveServiceAsync(serviceName, ct);

            if (serviceUrl != null)
            {
                // Get endpoint metadata from service
                var metadata = await GetServiceMetadataAsync(serviceUrl, ct);
                endpoints.AddRange(metadata);
            }
        }

        return endpoints;
    }

    private async Task<IReadOnlyList<EndpointInfo>> GetServiceMetadataAsync(
        Uri serviceUrl,
        CancellationToken ct)
    {
        // Call /.axiom/endpoints to get metadata
        using var client = new HttpClient { BaseAddress = serviceUrl };

        try
        {
            var response = await client.GetFromJsonAsync<EndpointDiscoveryResponse>(
                "/.axiom/endpoints",
                ct);

            return response?.Endpoints ?? Array.Empty<EndpointInfo>();
        }
        catch
        {
            return Array.Empty<EndpointInfo>();
        }
    }

    private string? GetServiceNameForEndpoint<TEndpoint>()
        where TEndpoint : IAxiom<object, object>
    {
        // Try to determine service name from endpoint type
        var endpointType = typeof(TEndpoint);
        var assemblyName = endpointType.Assembly.GetName().Name;
        
        // Look for configuration mapping
        var serviceName = _configuration[$"endpoints:{endpointType.Name}:service"];
        if (!string.IsNullOrEmpty(serviceName))
        {
            return serviceName;
        }

        // Default to assembly name
        return assemblyName?.ToLowerInvariant();
    }
}