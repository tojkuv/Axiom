using System;
using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

public class TestOptional
{
    public static void Main()
    {
        // Simple case: just one optional parameter
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/test/{id?}",
                typeof(object),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);

        Console.WriteLine("Testing simple optional parameter:");
        Console.WriteLine("Template: /test/{id?}");

        // Test with parameter
        var result1 = matcher.Match("/test/123");
        Console.WriteLine($"Match '/test/123': {result1 != null}");
        if (result1 != null)
        {
            foreach (var param in result1.Parameters)
            {
                Console.WriteLine($"  Parameter {param.Key} = {param.Value}");
            }
        }

        // Test without parameter
        var result2 = matcher.Match("/test");
        Console.WriteLine($"Match '/test': {result2 != null}");
        if (result2 != null)
        {
            foreach (var param in result2.Parameters)
            {
                Console.WriteLine($"  Parameter {param.Key} = {param.Value}");
            }
        }
    }
}