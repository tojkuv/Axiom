using System.Runtime.CompilerServices;
using System.Buffers;
using Microsoft.AspNetCore.Http;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using FluentAssertions;

namespace AxiomEndpoints.Tests;

/// <summary>
/// Test utilities for streaming endpoints
/// </summary>
public static class StreamingTestHelpers
{
    /// <summary>
    /// Creates a test async enumerable from a collection
    /// </summary>
    public static async IAsyncEnumerable<T> ToAsyncEnumerable<T>(
        this IEnumerable<T> source,
        TimeSpan? delay = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        foreach (var item in source)
        {
            if (delay.HasValue)
            {
                await Task.Delay(delay.Value, cancellationToken);
            }

            yield return item;
        }
    }

    /// <summary>
    /// Collects streaming results with timeout
    /// </summary>
    public static async Task<List<T>> CollectAsync<T>(
        this IAsyncEnumerable<T> source,
        int maxItems = 100,
        TimeSpan? timeout = null,
        CancellationToken cancellationToken = default)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);

        if (timeout.HasValue)
        {
            cts.CancelAfter(timeout.Value);
        }

        var results = new List<T>();

        await foreach (var item in source.WithCancellation(cts.Token))
        {
            results.Add(item);

            if (results.Count >= maxItems)
            {
                break;
            }
        }

        return results;
    }
}

/// <summary>
/// Base class for streaming endpoint tests
/// </summary>
public abstract class StreamingEndpointTest<TEndpoint>
{
    protected IContext Context { get; } = new TestContext();

    protected async Task<List<TResponse>> TestServerStreamAsync<TRequest, TResponse>(
        IServerStreamAxiom<TRequest, TResponse> endpoint,
        TRequest request,
        int expectedCount)
    {
        var results = await endpoint
            .StreamAsync(request, Context)
            .Take(expectedCount)
            .ToListAsync(CancellationToken.None);

        results.Should().HaveCount(expectedCount);
        return results;
    }

    protected async Task<Result<TResponse>> TestClientStreamAsync<TRequest, TResponse>(
        IClientStreamAxiom<TRequest, TResponse> endpoint,
        IEnumerable<TRequest> requests)
    {
        var result = await endpoint.HandleAsync(
            requests.ToAsyncEnumerable(),
            Context);

        result.Should().BeSuccess<TResponse>();
        return result;
    }

    protected async Task<List<TResponse>> TestBidirectionalStreamAsync<TRequest, TResponse>(
        IBidirectionalStreamAxiom<TRequest, TResponse> endpoint,
        IEnumerable<TRequest> requests,
        int expectedResponseCount)
    {
        var responses = await endpoint
            .StreamAsync(requests.ToAsyncEnumerable(), Context)
            .Take(expectedResponseCount)
            .ToListAsync(CancellationToken.None);

        responses.Should().HaveCount(expectedResponseCount);
        return responses;
    }

    protected abstract TEndpoint CreateEndpoint();
}

/// <summary>
/// Extensions for FluentAssertions to work with Result types
/// </summary>
public static class ResultAssertionExtensions
{
    public static void BeSuccess<T>(this FluentAssertions.Primitives.ObjectAssertions assertions)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeTrue($"Expected success but got error: {result.Error?.Message}");
    }

    public static void BeFailure<T>(this FluentAssertions.Primitives.ObjectAssertions assertions)
    {
        if (assertions.Subject is not Result<T> result)
        {
            throw new ArgumentException("Subject must be a Result<T>");
        }

        result.IsSuccess.Should().BeFalse("Expected failure but got success");
    }
}

