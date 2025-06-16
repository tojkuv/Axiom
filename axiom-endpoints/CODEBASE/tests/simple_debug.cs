using System;
using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

namespace DebugRouteMatcher
{
    class Program
    {
        static void Main()
        {
            // Test the simple versioned route first
            var endpoints = new[]
            {
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

            Console.WriteLine("Testing versioned routes:");
            Console.WriteLine("Template: /api/v{version}/users");

            var result = matcher.Match("/api/v1/users");
            Console.WriteLine($"Match '/api/v1/users': {result != null}");
            if (result != null)
            {
                foreach (var param in result.Parameters)
                {
                    Console.WriteLine($"  Parameter {param.Key} = {param.Value}");
                }
            }
            else
            {
                Console.WriteLine("  No match found");
            }
        }
    }
}