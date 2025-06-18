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

    private static int FindSegmentEnd(ReadOnlySpan<char> template)
    {
        int braceDepth = 0;
        for (int i = 0; i < template.Length; i++)
        {
            char c = template[i];
            if (c == '{')
            {
                braceDepth++;
            }
            else if (c == '}')
            {
                braceDepth--;
            }
            else if (braceDepth == 0 && (c == '/' || c == '#'))
            {
                return i;
            }
        }
        return -1;
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

        // Find the end of the current segment, but don't split on '?' inside parameter braces
        var segmentEnd = FindSegmentEnd(template);
        if (segmentEnd == -1) segmentEnd = template.Length;

        var segment = template[..segmentEnd];
        var remaining = segmentEnd < template.Length ? template[(segmentEnd + 1)..] : ReadOnlySpan<char>.Empty;

        // Handle segments that mix literal text with parameters (e.g., "v{version}")
        // Skip this logic if the segment is purely a parameter
        var segmentString = segment.ToString();
        var openBrace = segmentString.IndexOf('{');
        if (openBrace > 0) // Only if there's literal text BEFORE the parameter
        {
            var closeBrace = segmentString.IndexOf('}', openBrace + 1);
            if (closeBrace > openBrace)
            {
                // We have a parameter in this segment with literal prefix
                var literalPrefix = segment[..openBrace];
                var paramPart = segment[openBrace..(closeBrace + 1)];
                var literalSuffix = segment[(closeBrace + 1)..];

                // Add the literal prefix
                var prefixString = literalPrefix.ToString();
                if (!node.LiteralNodes.TryGetValue(prefixString, out var prefixNode))
                {
                    prefixNode = new RouteNode();
                    node.LiteralNodes[prefixString] = prefixNode;
                }

                // Process the parameter part
                var paramName = paramPart[1..^1]; // Remove { and }
                var colonIndex = paramName.IndexOf(':');
                if (colonIndex > 0)
                {
                    paramName = paramName[..colonIndex];
                }

                // Check if parameter is optional (ends with '?')
                bool isOptional = false;
                if (paramName.Length > 0 && paramName[^1] == '?')
                {
                    isOptional = true;
                    paramName = paramName[..^1]; // Remove the '?' suffix
                }

                var paramString = paramName.ToString();
                if (!prefixNode.ParameterNodes.TryGetValue(paramString, out var paramNode))
                {
                    paramNode = new RouteNode();
                    prefixNode.ParameterNodes[paramString] = paramNode;
                    
                    // Mark the parameter as optional in the node
                    if (isOptional)
                    {
                        paramNode.IsOptional = true;
                    }
                }

                // If there's a literal suffix, we need to continue building from the parameter node
                var nextTemplate = literalSuffix.Length > 0 
                    ? $"{literalSuffix.ToString()}/{remaining.ToString()}".TrimEnd('/') 
                    : remaining.ToString();
                
                AddRoute(paramNode, nextTemplate, endpoint);
                
                // For optional parameters, also add a route that skips this parameter
                if (isOptional)
                {
                    if (remaining.IsEmpty)
                    {
                        // If this is the last segment, set the endpoint on the prefix node
                        prefixNode.Endpoint = endpoint;
                    }
                    else
                    {
                        AddRoute(prefixNode, remaining, endpoint);
                    }
                }
                
                return;
            }
        }

        // Handle pure parameter segments {param}
        if (segment.Length > 0 && segment[0] == '{' && segment[^1] == '}')
        {
            var paramName = segment[1..^1];
            var colonIndex = paramName.IndexOf(':');
            if (colonIndex > 0)
            {
                paramName = paramName[..colonIndex];
            }

            // Check if parameter is optional (ends with '?')
            bool isOptional = false;
            if (paramName.Length > 0 && paramName[^1] == '?')
            {
                isOptional = true;
                paramName = paramName[..^1]; // Remove the '?' suffix
            }

            var paramString = paramName.ToString();
            if (!node.ParameterNodes.TryGetValue(paramString, out var paramNode))
            {
                paramNode = new RouteNode();
                node.ParameterNodes[paramString] = paramNode;
                
                // Mark the parameter as optional in the node
                if (isOptional)
                {
                    paramNode.IsOptional = true;
                }
            }
            
            AddRoute(paramNode, remaining, endpoint);
            
            // For optional parameters, also add a route that skips this parameter
            if (isOptional)
            {
                if (remaining.IsEmpty)
                {
                    // If this is the last segment, set the endpoint on the current node
                    node.Endpoint = endpoint;
                }
                else
                {
                    AddRoute(node, remaining, endpoint);
                }
            }
        }
        else
        {
            // Handle pure literal segments
            var literalSegmentString = segment.ToString();
            if (!node.LiteralNodes.TryGetValue(literalSegmentString, out var literalNode))
            {
                literalNode = new RouteNode();
                node.LiteralNodes[literalSegmentString] = literalNode;
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

        // Try literal matches first
        if (node.LiteralNodes.TryGetValue(segment.ToString(), out var literalNode))
        {
            var result = MatchNode(literalNode, remaining, parameters);
            if (result != null) return result;
        }

        // Try partial literal matches (for mixed literal/parameter patterns like "v{version}")
        foreach (var (literalKey, literalSubNode) in node.LiteralNodes)
        {
            if (segment.StartsWith(literalKey))
            {
                // The segment starts with this literal, check if we can match the rest as parameters
                var remainingSegment = segment[literalKey.Length..];
                
                // Try to match the remaining part of the segment with parameters
                foreach (var (paramName, paramNode) in literalSubNode.ParameterNodes)
                {
                    var originalParameterCount = parameters.Count;
                    parameters[paramName] = remainingSegment.ToString();
                    
                    var result = MatchNode(paramNode, remaining, parameters);
                    if (result != null) return result;
                    
                    // Cleanup on failure
                    while (parameters.Count > originalParameterCount)
                    {
                        var lastKey = parameters.Keys.Last();
                        parameters.Remove(lastKey);
                    }
                }
            }
        }

        // Try parameter matches
        foreach (var (paramName, paramNode) in node.ParameterNodes)
        {
            var originalParameterCount = parameters.Count;
            parameters[paramName] = segment.ToString();
            
            var result = MatchNode(paramNode, remaining, parameters);
            if (result != null) return result;
            
            // Cleanup on failure
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
        public bool IsOptional { get; set; }
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