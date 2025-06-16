using AxiomEndpoints.Routing;
using System;

// Quick test to see what template is generated
public class DebugTest
{
    public static void Main()
    {
        var template = RouteTemplateGenerator.Generate(typeof(TestRoutes.Files.ByPath));
        Console.WriteLine($"Generated template: '{template}'");
        
        var route = new TestRoutes.Files.ByPath("documents/report.pdf");
        var url = route.ToUrl();
        Console.WriteLine($"Generated URL: '{url}'");
    }
}

public static class TestRoutes
{
    public record Files : AxiomEndpoints.Core.IRoute<Files>
    {
        public static System.Collections.Frozen.FrozenDictionary<string, object> Metadata { get; } =
            System.Collections.Frozen.FrozenDictionary<string, object>.Empty;

        public record ByPath(
            string Path,
            string? Version = null
        ) : AxiomEndpoints.Core.IRoute<ByPath>
        {
            public static System.Collections.Frozen.FrozenDictionary<string, object> Metadata { get; } =
                System.Collections.Frozen.FrozenDictionary<string, object>.Empty;
        }
    }
}