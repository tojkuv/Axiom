using System.Net.Http.Json;
using System.Collections.Concurrent;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Aspire.ServiceDiscovery;

/// <summary>
/// Enhanced Aspire-based service discovery for Axiom endpoints
/// </summary>
public class AspireServiceDiscovery : IAxiomServiceDiscovery
{
    private readonly object _serviceDiscovery;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AspireServiceDiscovery> _logger;
    private readonly IMemoryCache _cache;
    private readonly ServiceDiscoveryOptions _options;
    private readonly ConcurrentDictionary<string, ServiceCircuitBreaker> _circuitBreakers = new();
    private readonly SemaphoreSlim _discoveryLock = new(1, 1);

    public AspireServiceDiscovery(
        object serviceDiscovery,
        IConfiguration configuration,
        ILogger<AspireServiceDiscovery> logger,
        IMemoryCache cache,
        IOptions<ServiceDiscoveryOptions> options)
    {
        _serviceDiscovery = serviceDiscovery;
        _configuration = configuration;
        _logger = logger;
        _cache = cache;
        _options = options.Value;
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

    public async ValueTask<Uri?> ResolveServiceAsync(string serviceName, CancellationToken ct = default)
    {
        var cacheKey = $"service:{serviceName}";
        
        // Check cache first
        if (_cache.TryGetValue<Uri>(cacheKey, out var cached))
        {
            _logger.LogDebug("Service {ServiceName} resolved from cache: {Uri}", serviceName, cached);
            return cached;
        }

        // Get or create circuit breaker for this service
        var circuitBreaker = _circuitBreakers.GetOrAdd(serviceName, 
            _ => new ServiceCircuitBreaker(_options.CircuitBreakerFailureThreshold, 
                                          _options.CircuitBreakerTimeout));

        if (circuitBreaker.State == CircuitBreakerState.Open)
        {
            _logger.LogWarning("Circuit breaker is open for service {ServiceName}", serviceName);
            return null;
        }

        await _discoveryLock.WaitAsync(ct);
        try
        {
            // Double-check cache after acquiring lock
            if (_cache.TryGetValue<Uri>(cacheKey, out cached))
            {
                return cached;
            }

            // Attempt service resolution with retries
            Uri? resolvedUri = null;
            var attempts = 0;
            
            while (attempts < _options.MaxRetryAttempts && resolvedUri == null)
            {
                attempts++;
                
                try
                {
                    resolvedUri = await ResolveServiceInternal(serviceName, ct);
                    
                    if (resolvedUri != null)
                    {
                        // Cache successful resolution
                        _cache.Set(cacheKey, resolvedUri, _options.CacheDuration);
                        circuitBreaker.RecordSuccess();
                        
                        _logger.LogInformation("Service {ServiceName} resolved to {Uri} after {Attempts} attempts", 
                            serviceName, resolvedUri, attempts);
                        
                        return resolvedUri;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Attempt {Attempt} failed to resolve service {ServiceName}", 
                        attempts, serviceName);
                    
                    circuitBreaker.RecordFailure();
                    
                    if (attempts < _options.MaxRetryAttempts)
                    {
                        var delay = TimeSpan.FromMilliseconds(_options.RetryDelayMs * Math.Pow(2, attempts - 1));
                        await Task.Delay(delay, ct);
                    }
                }
            }

            _logger.LogError("Failed to resolve service {ServiceName} after {Attempts} attempts", 
                serviceName, attempts);
            
            return null;
        }
        finally
        {
            _discoveryLock.Release();
        }
    }

    private async ValueTask<Uri?> ResolveServiceInternal(string serviceName, CancellationToken ct)
    {
        // Check configuration first
        var configuredUrl = _configuration[$"services:{serviceName}"];
        if (!string.IsNullOrEmpty(configuredUrl))
        {
            return new Uri(configuredUrl);
        }

        // TODO: Use Aspire service discovery when proper types are available
        // var endpoints = await _serviceDiscovery.GetEndpointsAsync(serviceName, ct);
        // var endpoint = endpoints.FirstOrDefault();
        // return endpoint?.Uri;

        // For now, return null to indicate service discovery is not yet implemented
        return null;
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

/// <summary>
/// Configuration options for service discovery
/// </summary>
public class ServiceDiscoveryOptions
{
    public TimeSpan CacheDuration { get; set; } = TimeSpan.FromMinutes(5);
    public int MaxRetryAttempts { get; set; } = 3;
    public int RetryDelayMs { get; set; } = 1000;
    public int CircuitBreakerFailureThreshold { get; set; } = 5;
    public TimeSpan CircuitBreakerTimeout { get; set; } = TimeSpan.FromMinutes(1);
    public TimeSpan HealthCheckInterval { get; set; } = TimeSpan.FromSeconds(30);
    public bool EnableEndpointCaching { get; set; } = true;
    public bool EnableCircuitBreaker { get; set; } = true;
}

/// <summary>
/// Circuit breaker for service calls
/// </summary>
public class ServiceCircuitBreaker
{
    private readonly int _failureThreshold;
    private readonly TimeSpan _timeout;
    private int _failureCount = 0;
    private DateTime _lastFailureTime = DateTime.MinValue;
    
    public ServiceCircuitBreaker(int failureThreshold, TimeSpan timeout)
    {
        _failureThreshold = failureThreshold;
        _timeout = timeout;
    }

    public CircuitBreakerState State
    {
        get
        {
            if (_failureCount >= _failureThreshold)
            {
                if (DateTime.UtcNow - _lastFailureTime < _timeout)
                {
                    return CircuitBreakerState.Open;
                }
                return CircuitBreakerState.HalfOpen;
            }
            return CircuitBreakerState.Closed;
        }
    }

    public void RecordSuccess()
    {
        _failureCount = 0;
    }

    public void RecordFailure()
    {
        _failureCount++;
        _lastFailureTime = DateTime.UtcNow;
    }
}

public enum CircuitBreakerState
{
    Closed,
    Open,
    HalfOpen
}