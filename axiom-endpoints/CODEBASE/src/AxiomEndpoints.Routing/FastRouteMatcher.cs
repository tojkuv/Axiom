using System.Buffers;
using System.Collections.Frozen;
using System.Collections.Concurrent;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Routing;

/// <summary>
/// High-performance route matcher using SearchValues and Trie
/// </summary>
public sealed class FastRouteMatcher
{
    private readonly RouteNode _root;
    private readonly SearchValues<char> _parameterDelimiters;
    private readonly FrozenDictionary<string, RouteEndpoint> _exactMatches;
    private readonly ConcurrentDictionary<string, RouteMatchResult?> _cache;

    public FastRouteMatcher(IEnumerable<RouteEndpoint> endpoints)
    {
        _root = new RouteNode();
        _parameterDelimiters = SearchValues.Create(['/', '?', '#']);
        _cache = new ConcurrentDictionary<string, RouteMatchResult?>();

        var exactMatches = new Dictionary<string, RouteEndpoint>();

        foreach (var endpoint in endpoints)
        {
            if (!endpoint.Template.Contains('{'))
            {
                exactMatches[endpoint.Template] = endpoint;
            }
            else
            {
                AddRoute(_root, endpoint.Template.AsSpan(), endpoint);
            }
        }

        _exactMatches = exactMatches.ToFrozenDictionary();
    }

    public RouteMatchResult? Match(ReadOnlySpan<char> path)
    {
        var pathString = path.ToString();
        
        if (_cache.TryGetValue(pathString, out var cachedResult))
        {
            return cachedResult;
        }

        var result = MatchInternal(path);
        _cache.TryAdd(pathString, result);
        return result;
    }

    private RouteMatchResult? MatchInternal(ReadOnlySpan<char> path)
    {
        if (_exactMatches.TryGetValue(path.ToString(), out var exactMatch))
        {
            return new RouteMatchResult(exactMatch, FrozenDictionary<string, string>.Empty);
        }

        var parameters = new Dictionary<string, string>();
        var endpoint = MatchNode(_root, path, parameters);

        if (endpoint == null)
            return null;

        var validationResult = ValidateConstraints(endpoint, parameters);
        if (!validationResult.IsValid)
            return null;

        return new RouteMatchResult(endpoint, parameters.ToFrozenDictionary());
    }

    private void AddRoute(RouteNode node, ReadOnlySpan<char> template, RouteEndpoint endpoint)
    {
        if (template.IsEmpty)
        {
            node.Endpoint = endpoint;
            return;
        }

        if (template[0] == '/')
        {
            template = template[1..];
        }

        var segmentEnd = template.IndexOfAny(_parameterDelimiters);
        if (segmentEnd == -1) segmentEnd = template.Length;

        var segment = template[..segmentEnd];
        var remaining = segmentEnd < template.Length ? template[(segmentEnd + 1)..] : ReadOnlySpan<char>.Empty;

        if (segment.Length > 0 && segment[0] == '{' && segment[^1] == '}')
        {
            var paramName = segment[1..^1];
            var colonIndex = paramName.IndexOf(':');
            if (colonIndex > 0)
            {
                paramName = paramName[..colonIndex];
            }

            var paramString = paramName.ToString();
            if (!node.ParameterNodes.TryGetValue(paramString, out var paramNode))
            {
                paramNode = new RouteNode();
                node.ParameterNodes[paramString] = paramNode;
            }
            
            AddRoute(paramNode, remaining, endpoint);
        }
        else
        {
            var segmentString = segment.ToString();
            if (!node.LiteralNodes.TryGetValue(segmentString, out var literalNode))
            {
                literalNode = new RouteNode();
                node.LiteralNodes[segmentString] = literalNode;
            }
            
            AddRoute(literalNode, remaining, endpoint);
        }
    }

    private RouteEndpoint? MatchNode(RouteNode node, ReadOnlySpan<char> path, Dictionary<string, string> parameters)
    {
        if (path.IsEmpty)
        {
            return node.Endpoint;
        }

        if (path[0] == '/')
        {
            path = path[1..];
        }

        var segmentEnd = path.IndexOfAny(_parameterDelimiters);
        if (segmentEnd == -1) segmentEnd = path.Length;

        var segment = path[..segmentEnd];
        var remaining = segmentEnd < path.Length ? path[(segmentEnd + 1)..] : ReadOnlySpan<char>.Empty;

        if (node.LiteralNodes.TryGetValue(segment.ToString(), out var literalNode))
        {
            var result = MatchNode(literalNode, remaining, parameters);
            if (result != null) return result;
        }

        foreach (var (paramName, paramNode) in node.ParameterNodes)
        {
            var originalParameterCount = parameters.Count;
            parameters[paramName] = segment.ToString();
            
            var result = MatchNode(paramNode, remaining, parameters);
            if (result != null) return result;
            
            while (parameters.Count > originalParameterCount)
            {
                var lastKey = parameters.Keys.Last();
                parameters.Remove(lastKey);
            }
        }

        return null;
    }

    private static ConstraintValidationResult ValidateConstraints(RouteEndpoint endpoint, Dictionary<string, string> parameters)
    {
        foreach (var (paramName, constraint) in endpoint.Constraints)
        {
            if (parameters.TryGetValue(paramName, out var value))
            {
                if (!constraint.IsValid(value))
                {
                    return new ConstraintValidationResult(false, paramName, constraint.ErrorMessage);
                }
            }
        }

        return new ConstraintValidationResult(true, null, null);
    }

    private sealed class RouteNode
    {
        public RouteEndpoint? Endpoint { get; set; }
        public Dictionary<string, RouteNode> LiteralNodes { get; } = new();
        public Dictionary<string, RouteNode> ParameterNodes { get; } = new();
    }

    public void ClearCache()
    {
        _cache.Clear();
    }

    public int CacheSize => _cache.Count;
}

public record RouteEndpoint(
    string Template,
    Type EndpointType,
    HttpMethod Method,
    ApiVersion? Version,
    FrozenDictionary<string, IRouteConstraint> Constraints,
    FrozenDictionary<string, object> Metadata
);

public record RouteMatchResult(
    RouteEndpoint Endpoint,
    FrozenDictionary<string, string> Parameters
);

public record ConstraintValidationResult(
    bool IsValid,
    string? ParameterName,
    string? ErrorMessage
);

/// <summary>
/// Builder for creating RouteEndpoint instances
/// </summary>
public class RouteEndpointBuilder
{
    private string _template = "";
    private Type? _endpointType;
    private HttpMethod _method = HttpMethod.Get;
    private ApiVersion? _version;
    private readonly Dictionary<string, IRouteConstraint> _constraints = new();
    private readonly Dictionary<string, object> _metadata = new();

    public RouteEndpointBuilder WithTemplate(string template)
    {
        _template = template;
        return this;
    }

    public RouteEndpointBuilder WithEndpointType(Type endpointType)
    {
        _endpointType = endpointType;
        return this;
    }

    public RouteEndpointBuilder WithMethod(HttpMethod method)
    {
        _method = method;
        return this;
    }

    public RouteEndpointBuilder WithVersion(ApiVersion version)
    {
        _version = version;
        return this;
    }

    public RouteEndpointBuilder WithConstraint(string parameterName, IRouteConstraint constraint)
    {
        _constraints[parameterName] = constraint;
        return this;
    }

    public RouteEndpointBuilder WithMetadata(string key, object value)
    {
        _metadata[key] = value;
        return this;
    }

    public RouteEndpoint Build()
    {
        if (_endpointType == null)
            throw new InvalidOperationException("EndpointType must be set");

        return new RouteEndpoint(
            _template,
            _endpointType,
            _method,
            _version,
            _constraints.ToFrozenDictionary(),
            _metadata.ToFrozenDictionary()
        );
    }
}