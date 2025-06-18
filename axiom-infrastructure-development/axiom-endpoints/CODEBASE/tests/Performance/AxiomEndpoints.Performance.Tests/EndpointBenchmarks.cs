using BenchmarkDotNet.Attributes;
using AxiomEndpoints.Core;
using AxiomEndpoints.Testing.Common.TestData;
using AxiomEndpoints.Testing.Common.MockServices;

namespace AxiomEndpoints.Performance.Tests;

/// <summary>
/// Performance benchmarks for endpoint execution
/// </summary>
[MemoryDiagnoser]
[SimpleJob]
public class EndpointBenchmarks
{
    private SimpleEndpoint _simpleEndpoint = null!;
    private TestServerStreamEndpoint _streamEndpoint = null!;
    private MockContext _context = null!;
    private TestRequest _request = null!;

    [GlobalSetup]
    public void Setup()
    {
        _simpleEndpoint = new SimpleEndpoint();
        _streamEndpoint = new TestServerStreamEndpoint();
        _context = new MockContext();
        _request = new TestRequest("Test message");
    }

    [Benchmark]
    public async Task<Result<TestResponse>> SimpleEndpointExecution()
    {
        return await _simpleEndpoint.HandleAsync(_request, _context);
    }

    [Benchmark]
    public async Task StreamingEndpointExecution()
    {
        var responses = new List<TestResponse>();
        await foreach (var response in _streamEndpoint.StreamAsync(_request, _context))
        {
            responses.Add(response);
        }
    }

    [Benchmark]
    public async Task MultipleEndpointCalls()
    {
        var tasks = new Task[100];
        for (int i = 0; i < 100; i++)
        {
            tasks[i] = _simpleEndpoint.HandleAsync(_request, _context).AsTask();
        }
        await Task.WhenAll(tasks);
    }

    [Benchmark]
    public void ResultTypeCreation()
    {
        for (int i = 0; i < 1000; i++)
        {
            var success = ResultFactory.Success(new TestResponse("test"));
            var failure = ResultFactory.Failure<TestResponse>(AxiomError.Validation("error"));
        }
    }

    [Benchmark]
    public void ResultTypeMatching()
    {
        var result = ResultFactory.Success(new TestResponse("test"));
        
        for (int i = 0; i < 1000; i++)
        {
            var output = result.Match(
                success: r => r.Message,
                failure: e => e.Message
            );
        }
    }

    [Benchmark]
    public void ContextOperations()
    {
        var context = new MockContext();
        
        for (int i = 0; i < 1000; i++)
        {
            context.SetRouteValue("id", Guid.NewGuid());
            var id = context.GetRouteValue<Guid>("id");
            // Simulate other context operations
            _ = context.CancellationToken;
        }
    }

    [Benchmark]
    public async Task ConcurrentEndpointExecution()
    {
        var tasks = new Task[Environment.ProcessorCount * 2];
        
        for (int i = 0; i < tasks.Length; i++)
        {
            tasks[i] = Task.Run(async () =>
            {
                for (int j = 0; j < 100; j++)
                {
                    await _simpleEndpoint.HandleAsync(_request, _context);
                }
            });
        }
        
        await Task.WhenAll(tasks);
    }

    [Benchmark]
    public void ErrorHandlingPerformance()
    {
        for (int i = 0; i < 1000; i++)
        {
            try
            {
                throw new InvalidOperationException("Test error");
            }
            catch (Exception ex)
            {
                var error = AxiomError.Validation(ex.Message);
                var result = ResultFactory.Failure<TestResponse>(error);
            }
        }
    }
}