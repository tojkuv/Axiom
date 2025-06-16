using System;
using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

class DebugMinimal
{
    static void Main()
    {
        // Exact same test as failing unit test
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/files/{path}/{version?}",
                typeof(object),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);

        Console.WriteLine("Debug test - matching /files/{path}/{version?}");
        
        // This should work
        var result1 = matcher.Match("/files/document.pdf/v2");
        Console.WriteLine($"Result 1 (/files/document.pdf/v2): {result1 != null}");
        if (result1 != null)
        {
            Console.WriteLine($"  Endpoint: {result1.Endpoint.Template}");
            foreach (var param in result1.Parameters)
            {
                Console.WriteLine($"  {param.Key} = {param.Value}");
            }
        }

        // This should also work
        var result2 = matcher.Match("/files/document.pdf");
        Console.WriteLine($"Result 2 (/files/document.pdf): {result2 != null}");
        if (result2 != null)
        {
            Console.WriteLine($"  Endpoint: {result2.Endpoint.Template}");
            foreach (var param in result2.Parameters)
            {
                Console.WriteLine($"  {param.Key} = {param.Value}");
            }
        }
    }
}