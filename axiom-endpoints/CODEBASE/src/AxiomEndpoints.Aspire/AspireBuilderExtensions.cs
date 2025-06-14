using System.Reflection;
using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;

namespace AxiomEndpoints.Aspire;

/// <summary>
/// Aspire builder extensions for Axiom Endpoints
/// NOTE: This is a foundational implementation that demonstrates the integration approach.
/// Full implementation would require the complete Aspire workload to be installed.
/// </summary>
public static class AspireBuilderExtensions
{
    // TODO: Implement full Aspire builder extensions when Aspire workload is available
    // The interfaces and structure are in place for future enhancement
}

/// <summary>
/// Axiom service annotation for Aspire
/// </summary>
public class AxiomServiceAnnotation : IResourceAnnotation
{
    public string Type => "axiom.service";
}

/// <summary>
/// Basic Axiom project resource implementation
/// </summary>
public class AxiomProjectResource : IAxiomResource
{
    private readonly List<EndpointMetadata> _endpoints = new();
    private readonly List<EventTopicMetadata> _eventTopics = new();

    public AxiomProjectResource(string name, string projectPath)
    {
        Name = name;
        ProjectPath = projectPath;
    }

    public string Name { get; }
    public string ProjectPath { get; }
    public IReadOnlyList<EndpointMetadata> Endpoints => _endpoints;
    public IReadOnlyList<EventTopicMetadata> EventTopics => _eventTopics;

    internal void AddEndpoints(IEnumerable<EndpointMetadata> endpoints)
    {
        _endpoints.AddRange(endpoints);
    }

    internal void AddEventTopics(IEnumerable<EventTopicMetadata> topics)
    {
        _eventTopics.AddRange(topics);
    }
}