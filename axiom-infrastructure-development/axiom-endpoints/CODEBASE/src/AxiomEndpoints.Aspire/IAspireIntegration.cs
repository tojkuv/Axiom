using System.Collections.Frozen;
using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Aspire;

/// <summary>
/// Core Aspire integration for Axiom Endpoints
/// </summary>
public interface IAspireIntegration
{
    /// <summary>
    /// Register Axiom services with Aspire
    /// </summary>
    void RegisterServices(IDistributedApplicationBuilder builder);

    /// <summary>
    /// Configure Axiom for Aspire environment
    /// </summary>
    void ConfigureAxiom(AxiomOptions options, object discovery);
}

/// <summary>
/// Service discovery integration
/// </summary>
public interface IAxiomServiceDiscovery
{
    /// <summary>
    /// Resolve endpoint URL by type
    /// </summary>
    ValueTask<Uri?> ResolveEndpointAsync<TEndpoint>(CancellationToken ct = default)
        where TEndpoint : IAxiom<object, object>;

    /// <summary>
    /// Resolve service URL by name
    /// </summary>
    ValueTask<Uri?> ResolveServiceAsync(string serviceName, CancellationToken ct = default);

    /// <summary>
    /// Get all available endpoints
    /// </summary>
    ValueTask<IReadOnlyList<EndpointInfo>> DiscoverEndpointsAsync(CancellationToken ct = default);
}

/// <summary>
/// Aspire resource definition for Axiom service
/// </summary>
public interface IAxiomResource
{
    /// <summary>
    /// Endpoints exposed by this service
    /// </summary>
    IReadOnlyList<EndpointMetadata> Endpoints { get; }

    /// <summary>
    /// Event topics this service publishes/subscribes
    /// </summary>
    IReadOnlyList<EventTopicMetadata> EventTopics { get; }
}

/// <summary>
/// Endpoint metadata for service discovery
/// </summary>
public record EndpointMetadata
{
    public required Type EndpointType { get; init; }
    public required string Route { get; init; }
    public required HttpMethod Method { get; init; }
    public required bool SupportsGrpc { get; init; }
    public required string? Description { get; init; }
    public FrozenSet<string> RequiredScopes { get; init; } = FrozenSet<string>.Empty;
}

/// <summary>
/// Event topic metadata
/// </summary>
public record EventTopicMetadata
{
    public required string TopicName { get; init; }
    public required Type EventType { get; init; }
    public required EventRole Role { get; init; }
}

public enum EventRole
{
    Publisher,
    Subscriber,
    Both
}

/// <summary>
/// Endpoint info for discovery
/// </summary>
public record EndpointInfo
{
    public required string Name { get; init; }
    public required string Route { get; init; }
    public required string Method { get; init; }
    public required string Service { get; init; }
    public required Uri BaseUrl { get; init; }
    public bool SupportsGrpc { get; init; }
    public FrozenDictionary<string, string> Metadata { get; init; } =
        FrozenDictionary<string, string>.Empty;
}

/// <summary>
/// Endpoint discovery response
/// </summary>
public record EndpointDiscoveryResponse
{
    public required IReadOnlyList<EndpointInfo> Endpoints { get; init; }
}

/// <summary>
/// Temporary placeholder for AxiomOptions - will be defined elsewhere
/// </summary>
public class AxiomOptions
{
    public bool UseAspireServiceDiscovery { get; set; }
    public bool UseAspireConfiguration { get; set; }
    public bool EnableDetailedErrors { get; set; }
    public bool EnableSwagger { get; set; }
    public bool EnableGraphQL { get; set; }
    public bool EnableDeveloperExceptionPage { get; set; }
    public bool EnableDeveloperDashboard { get; set; }
}