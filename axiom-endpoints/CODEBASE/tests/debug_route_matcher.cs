using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

// Test the FastRouteMatcher implementation
var endpoints = new[]
{
    new RouteEndpoint(
        "/files/{path}/{version?}",
        typeof(object),
        HttpMethod.Get,
        null,
        FrozenDictionary<string, IRouteConstraint>.Empty,
        FrozenDictionary<string, object>.Empty
    ),
    new RouteEndpoint(
        "/api/v{version}/users",
        typeof(object),
        HttpMethod.Get,
        null,
        FrozenDictionary<string, IRouteConstraint>.Empty,
        FrozenDictionary<string, object>.Empty
    )
};

var matcher = new FastRouteMatcher(endpoints);

Console.WriteLine("Testing optional parameters:");
Console.WriteLine("Template: /files/{path}/{version?}");

var result1 = matcher.Match("/files/document.pdf/v2");
Console.WriteLine($"Match '/files/document.pdf/v2': {result1 != null}");
if (result1 != null)
{
    Console.WriteLine($"  Parameters: {string.Join(", ", result1.Parameters.Select(p => $"{p.Key}={p.Value}"))}");
}

var result2 = matcher.Match("/files/document.pdf");
Console.WriteLine($"Match '/files/document.pdf': {result2 != null}");
if (result2 != null)
{
    Console.WriteLine($"  Parameters: {string.Join(", ", result2.Parameters.Select(p => $"{p.Key}={p.Value}"))}");
}

Console.WriteLine("\nTesting versioned routes:");
Console.WriteLine("Template: /api/v{version}/users");

var result3 = matcher.Match("/api/v1/users");
Console.WriteLine($"Match '/api/v1/users': {result3 != null}");
if (result3 != null)
{
    Console.WriteLine($"  Parameters: {string.Join(", ", result3.Parameters.Select(p => $"{p.Key}={p.Value}"))}");
}

var result4 = matcher.Match("/api/v2/users");
Console.WriteLine($"Match '/api/v2/users': {result4 != null}");
if (result4 != null)
{
    Console.WriteLine($"  Parameters: {string.Join(", ", result4.Parameters.Select(p => $"{p.Key}={p.Value}"))}");
}