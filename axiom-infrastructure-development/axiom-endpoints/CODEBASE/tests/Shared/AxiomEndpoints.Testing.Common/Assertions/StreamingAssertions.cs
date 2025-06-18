using FluentAssertions;
using FluentAssertions.Execution;
using FluentAssertions.Primitives;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.Testing.Common.Assertions;

public static class StreamingAssertionExtensions
{
    public static AsyncEnumerableAssertions<T> Should<T>(this IAsyncEnumerable<T> asyncEnumerable) => new(asyncEnumerable);
    public static StreamingResultAssertions<T> Should<T>(this Task<List<T>> streamingResult) => new(streamingResult);
}

public class AsyncEnumerableAssertions<T> : ReferenceTypeAssertions<IAsyncEnumerable<T>, AsyncEnumerableAssertions<T>>
{
    public AsyncEnumerableAssertions(IAsyncEnumerable<T> instance) : base(instance) { }

    protected override string Identifier => "async enumerable";

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> YieldExactly(int expectedCount, string because = "", params object[] becauseArgs)
    {
        var items = new List<T>();
        await foreach (var item in Subject)
        {
            items.Add(item);
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(items.Count == expectedCount)
            .FailWith("Expected async enumerable to yield exactly {0} items, but yielded {1}.", 
                expectedCount, items.Count);

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> YieldAtLeast(int minimumCount, string because = "", params object[] becauseArgs)
    {
        var count = 0;
        await foreach (var item in Subject)
        {
            count++;
            if (count >= minimumCount) break;
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(count >= minimumCount)
            .FailWith("Expected async enumerable to yield at least {0} items, but yielded {1}.", 
                minimumCount, count);

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> YieldItemsMatching(Func<T, bool> predicate, string because = "", params object[] becauseArgs)
    {
        var items = new List<T>();
        await foreach (var item in Subject)
        {
            items.Add(item);
        }

        var matchingItems = items.Where(predicate).ToList();

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(matchingItems.Count == items.Count)
            .FailWith("Expected all items to match predicate, but {0} out of {1} items did not match.", 
                items.Count - matchingItems.Count, items.Count);

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> YieldItemsInOrder(IEnumerable<T> expectedItems, string because = "", params object[] becauseArgs)
    {
        var actualItems = new List<T>();
        await foreach (var item in Subject)
        {
            actualItems.Add(item);
        }

        var expectedList = expectedItems.ToList();

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(actualItems.SequenceEqual(expectedList))
            .FailWith("Expected items to be yielded in order {0}, but found {1}.", 
                string.Join(", ", expectedList), string.Join(", ", actualItems));

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> CompleteWithin(TimeSpan timeout, string because = "", params object[] becauseArgs)
    {
        using var cts = new CancellationTokenSource(timeout);
        var completed = false;

        try
        {
            await foreach (var item in Subject.WithCancellation(cts.Token))
            {
                // Process all items
            }
            completed = true;
        }
        catch (OperationCanceledException) when (cts.Token.IsCancellationRequested)
        {
            // Timeout occurred
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(completed)
            .FailWith("Expected async enumerable to complete within {0}, but it did not.", timeout);

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> NotThrow(string because = "", params object[] becauseArgs)
    {
        Exception? caughtException = null;

        try
        {
            await foreach (var item in Subject)
            {
                // Process all items
            }
        }
        catch (Exception ex)
        {
            caughtException = ex;
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(caughtException == null)
            .FailWith("Expected async enumerable to not throw, but it threw {0}: {1}", 
                caughtException?.GetType().Name, caughtException?.Message);

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }

    public async Task<AndConstraint<AsyncEnumerableAssertions<T>>> ThrowExactly<TException>(string because = "", params object[] becauseArgs) 
        where TException : Exception
    {
        Exception? caughtException = null;

        try
        {
            await foreach (var item in Subject)
            {
                // Process all items
            }
        }
        catch (Exception ex)
        {
            caughtException = ex;
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(caughtException is TException)
            .FailWith("Expected async enumerable to throw {0}, but {1}.", 
                typeof(TException).Name, 
                caughtException == null ? "no exception was thrown" : $"threw {caughtException.GetType().Name}");

        return new AndConstraint<AsyncEnumerableAssertions<T>>(this);
    }
}

public class StreamingResultAssertions<T> : ReferenceTypeAssertions<Task<List<T>>, StreamingResultAssertions<T>>
{
    public StreamingResultAssertions(Task<List<T>> instance) : base(instance) { }

    protected override string Identifier => "streaming result";

    public async Task<AndConstraint<StreamingResultAssertions<T>>> CompleteWithExactly(int expectedCount, string because = "", params object[] becauseArgs)
    {
        var result = await Subject;

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(result.Count == expectedCount)
            .FailWith("Expected streaming result to contain exactly {0} items, but contained {1}.", 
                expectedCount, result.Count);

        return new AndConstraint<StreamingResultAssertions<T>>(this);
    }

    public async Task<AndConstraint<StreamingResultAssertions<T>>> ContainItemsMatching(Func<T, bool> predicate, string because = "", params object[] becauseArgs)
    {
        var result = await Subject;
        var matchingItems = result.Where(predicate).ToList();

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(matchingItems.Count == result.Count)
            .FailWith("Expected all streaming result items to match predicate, but {0} out of {1} items did not match.", 
                result.Count - matchingItems.Count, result.Count);

        return new AndConstraint<StreamingResultAssertions<T>>(this);
    }

    public async Task<AndConstraint<StreamingResultAssertions<T>>> BeInOrder(IComparer<T>? comparer = null, string because = "", params object[] becauseArgs)
    {
        var result = await Subject;
        comparer ??= Comparer<T>.Default;

        var isOrdered = true;
        for (int i = 1; i < result.Count; i++)
        {
            if (comparer.Compare(result[i - 1], result[i]) > 0)
            {
                isOrdered = false;
                break;
            }
        }

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(isOrdered)
            .FailWith("Expected streaming result items to be in order, but they were not.");

        return new AndConstraint<StreamingResultAssertions<T>>(this);
    }
}