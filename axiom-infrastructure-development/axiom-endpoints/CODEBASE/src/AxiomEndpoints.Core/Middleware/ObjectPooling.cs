using System.Collections.Concurrent;
using System.Text;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Generic object pool interface for reducing allocations
/// </summary>
/// <typeparam name="T">Type of objects to pool</typeparam>
public interface IObjectPool<T> where T : class
{
    /// <summary>
    /// Get an object from the pool
    /// </summary>
    T Get();
    
    /// <summary>
    /// Return an object to the pool
    /// </summary>
    void Return(T item);
    
    /// <summary>
    /// Current number of objects in the pool
    /// </summary>
    int Count { get; }
    
    /// <summary>
    /// Number of objects currently active (checked out)
    /// </summary>
    int CountActive { get; }
}

/// <summary>
/// Thread-safe object pool implementation
/// </summary>
/// <typeparam name="T">Type of objects to pool</typeparam>
public class ObjectPool<T> : IObjectPool<T> where T : class
{
    private readonly ConcurrentQueue<T> _objects = new();
    private readonly Func<T> _objectFactory;
    private readonly Action<T>? _resetAction;
    private readonly int _maxSize;
    private int _count;
    private int _countActive;

    /// <summary>
    /// Create a new object pool
    /// </summary>
    /// <param name="objectFactory">Factory function to create new objects</param>
    /// <param name="resetAction">Action to reset objects before returning to pool</param>
    /// <param name="maxSize">Maximum number of objects to pool</param>
    public ObjectPool(Func<T> objectFactory, Action<T>? resetAction = null, int maxSize = 100)
    {
        _objectFactory = objectFactory;
        _resetAction = resetAction;
        _maxSize = maxSize;
    }

    public int Count => _count;
    public int CountActive => _countActive;

    public T Get()
    {
        if (_objects.TryDequeue(out var item))
        {
            Interlocked.Decrement(ref _count);
            Interlocked.Increment(ref _countActive);
            return item;
        }

        Interlocked.Increment(ref _countActive);
        return _objectFactory();
    }

    public void Return(T item)
    {
        if (item == null) return;

        _resetAction?.Invoke(item);

        if (_count < _maxSize)
        {
            _objects.Enqueue(item);
            Interlocked.Increment(ref _count);
        }

        Interlocked.Decrement(ref _countActive);
    }
}

/// <summary>
/// Pooled StringBuilder for reducing allocations in string building operations
/// </summary>
public static class StringBuilderPool
{
    private static readonly ObjectPool<StringBuilder> Pool = new(
        () => new StringBuilder(capacity: 4096), // Pre-allocate reasonable capacity
        sb => sb.Clear(), // Reset for reuse
        50); // Pool up to 50 instances

    /// <summary>
    /// Get a StringBuilder from the pool
    /// </summary>
    public static StringBuilder Get() => Pool.Get();

    /// <summary>
    /// Return a StringBuilder to the pool
    /// </summary>
    public static void Return(StringBuilder sb)
    {
        // Don't pool very large builders to avoid memory pressure
        if (sb.Capacity <= 32768) // 32KB limit
        {
            Pool.Return(sb);
        }
    }

    /// <summary>
    /// Get string content and return StringBuilder to pool in one operation
    /// </summary>
    public static string GetStringAndReturn(StringBuilder sb)
    {
        var result = sb.ToString();
        Return(sb);
        return result;
    }

    /// <summary>
    /// Pool statistics for monitoring
    /// </summary>
    public static (int Available, int Active) GetStatistics() => (Pool.Count, Pool.CountActive);
}

/// <summary>
/// Pooled MemoryStream for reducing allocations in stream operations
/// </summary>
public static class MemoryStreamPool
{
    private static readonly ObjectPool<MemoryStream> Pool = new(
        () => new MemoryStream(),
        ms => { ms.Position = 0; ms.SetLength(0); }, // Reset for reuse
        25); // Pool up to 25 instances

    /// <summary>
    /// Get a MemoryStream from the pool
    /// </summary>
    public static MemoryStream Get() => Pool.Get();

    /// <summary>
    /// Return a MemoryStream to the pool
    /// </summary>
    public static void Return(MemoryStream ms)
    {
        if (ms.Capacity <= 1048576) // Don't pool streams larger than 1MB
        {
            Pool.Return(ms);
        }
        else
        {
            ms.Dispose();
        }
    }

    /// <summary>
    /// Pool statistics for monitoring
    /// </summary>
    public static (int Available, int Active) GetStatistics() => (Pool.Count, Pool.CountActive);
}

/// <summary>
/// Configuration options for object pooling
/// </summary>
public class ObjectPoolingOptions
{
    /// <summary>
    /// Whether object pooling is enabled
    /// </summary>
    public bool EnableObjectPooling { get; set; } = true;
    
    /// <summary>
    /// Maximum size for StringBuilder pool
    /// </summary>
    public int StringBuilderPoolMaxSize { get; set; } = 50;
    
    /// <summary>
    /// Maximum capacity for pooled StringBuilders (in characters)
    /// </summary>
    public int StringBuilderMaxCapacity { get; set; } = 32768; // 32KB
    
    /// <summary>
    /// Initial capacity for new StringBuilders
    /// </summary>
    public int StringBuilderInitialCapacity { get; set; } = 4096; // 4KB
    
    /// <summary>
    /// Maximum size for MemoryStream pool
    /// </summary>
    public int MemoryStreamPoolMaxSize { get; set; } = 25;
    
    /// <summary>
    /// Maximum capacity for pooled MemoryStreams (in bytes)
    /// </summary>
    public long MemoryStreamMaxCapacity { get; set; } = 1048576; // 1MB
}

/// <summary>
/// Extension methods for convenient object pooling usage
/// </summary>
public static class ObjectPoolExtensions
{
    /// <summary>
    /// Execute an action with a pooled StringBuilder
    /// </summary>
    public static T WithPooledStringBuilder<T>(Func<StringBuilder, T> action)
    {
        var sb = StringBuilderPool.Get();
        try
        {
            return action(sb);
        }
        finally
        {
            StringBuilderPool.Return(sb);
        }
    }

    /// <summary>
    /// Execute an action with a pooled StringBuilder and return the string result
    /// </summary>
    public static string WithPooledStringBuilder(Action<StringBuilder> action)
    {
        var sb = StringBuilderPool.Get();
        try
        {
            action(sb);
            return sb.ToString();
        }
        finally
        {
            StringBuilderPool.Return(sb);
        }
    }

    /// <summary>
    /// Execute an action with a pooled MemoryStream
    /// </summary>
    public static T WithPooledMemoryStream<T>(Func<MemoryStream, T> action)
    {
        var ms = MemoryStreamPool.Get();
        try
        {
            return action(ms);
        }
        finally
        {
            MemoryStreamPool.Return(ms);
        }
    }

    /// <summary>
    /// Execute an async action with a pooled MemoryStream
    /// </summary>
    public static async Task<T> WithPooledMemoryStreamAsync<T>(Func<MemoryStream, Task<T>> action)
    {
        var ms = MemoryStreamPool.Get();
        try
        {
            return await action(ms);
        }
        finally
        {
            MemoryStreamPool.Return(ms);
        }
    }
}