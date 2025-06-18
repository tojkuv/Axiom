using BenchmarkDotNet.Running;

namespace AxiomEndpoints.Performance.Tests;

internal class Program
{
    static void Main(string[] args)
    {
        if (args.Length == 0 || args[0] == "routing")
        {
            BenchmarkRunner.Run<RoutingBenchmarks>();
        }
        else if (args[0] == "endpoints")
        {
            BenchmarkRunner.Run<EndpointBenchmarks>();
        }
        else if (args[0] == "all")
        {
            BenchmarkRunner.Run<RoutingBenchmarks>();
            BenchmarkRunner.Run<EndpointBenchmarks>();
        }
        else
        {
            Console.WriteLine("Usage: dotnet run [routing|endpoints|all]");
            Console.WriteLine("  routing   - Run routing performance benchmarks");
            Console.WriteLine("  endpoints - Run endpoint performance benchmarks");
            Console.WriteLine("  all       - Run all benchmarks");
            Console.WriteLine("  (default) - Run routing benchmarks");
        }
    }
}