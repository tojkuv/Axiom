using Grpc.Core;
using Grpc.Core.Interceptors;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.Core;
using Google.Protobuf;
using Google.Protobuf.WellKnownTypes;
using System.Text.Json;
using System.Collections.Generic;
using System.Linq;

namespace AxiomEndpoints.Grpc;

/// <summary>
/// Maps between Axiom errors and gRPC status codes
/// </summary>
public static class GrpcAxiomErrorMapping
{
    /// <summary>
    /// Converts an Axiom AxiomError to a gRPC Status
    /// </summary>
    public static Status ToGrpcStatus(this AxiomError error)
    {
        var statusCode = error.Type switch
        {
            ErrorType.NotFound => StatusCode.NotFound,
            ErrorType.Validation => StatusCode.InvalidArgument,
            ErrorType.Unauthorized => StatusCode.Unauthenticated,
            ErrorType.Forbidden => StatusCode.PermissionDenied,
            ErrorType.Conflict => StatusCode.AlreadyExists,
            ErrorType.TooManyRequests => StatusCode.ResourceExhausted,
            ErrorType.Internal => StatusCode.Internal,
            ErrorType.NotImplemented => StatusCode.Unimplemented,
            ErrorType.Timeout => StatusCode.DeadlineExceeded,
            ErrorType.Unavailable => StatusCode.Unavailable,
            _ => StatusCode.Unknown
        };

        var message = string.IsNullOrEmpty(error.Message) ? "An error occurred" : error.Message;
        return new Status(statusCode, message);
    }

    /// <summary>
    /// Converts an Axiom AxiomError to an HTTP IResult
    /// </summary>
    public static IResult ToHttpResult(this AxiomError error)
    {
        return error.Type switch
        {
            ErrorType.NotFound => Results.NotFound(CreateAxiomErrorResponse(error)),
            ErrorType.Validation => Results.BadRequest(CreateAxiomErrorResponse(error)),
            ErrorType.Unauthorized => Results.Unauthorized(),
            ErrorType.Forbidden => Results.Forbid(),
            ErrorType.Conflict => Results.Conflict(CreateAxiomErrorResponse(error)),
            ErrorType.TooManyRequests => Results.StatusCode(429),
            ErrorType.NotImplemented => Results.StatusCode(501),
            ErrorType.Timeout => Results.StatusCode(408),
            ErrorType.Unavailable => Results.StatusCode(503),
            _ => Results.Problem(CreateProblemDetails(error))
        };
    }

    /// <summary>
    /// Converts a gRPC Status to an Axiom AxiomError
    /// </summary>
    public static AxiomError FromGrpcStatus(Status status)
    {
        var errorType = status.StatusCode switch
        {
            StatusCode.NotFound => ErrorType.NotFound,
            StatusCode.InvalidArgument => ErrorType.Validation,
            StatusCode.Unauthenticated => ErrorType.Unauthorized,
            StatusCode.PermissionDenied => ErrorType.Forbidden,
            StatusCode.AlreadyExists => ErrorType.Conflict,
            StatusCode.ResourceExhausted => ErrorType.TooManyRequests,
            StatusCode.Unimplemented => ErrorType.NotImplemented,
            StatusCode.DeadlineExceeded => ErrorType.Timeout,
            StatusCode.Unavailable => ErrorType.Unavailable,
            StatusCode.Internal => ErrorType.Internal,
            _ => ErrorType.Internal
        };

        var code = $"GRPC_{status.StatusCode}";
        var message = status.Detail ?? "gRPC error occurred";
        
        return new AxiomError(code, message, errorType);
    }

    /// <summary>
    /// Converts an Axiom AxiomError to an RpcException with rich error details
    /// </summary>
    public static RpcException ToRpcException(this AxiomError error)
    {
        var status = error.ToGrpcStatus();
        var trailers = new Metadata();

        // Add error details as trailing metadata
        try
        {
            var errorDetails = CreateAxiomErrorDetails(error);
            if (errorDetails.Any())
            {
                var errorInfo = new Google.Rpc.Status
                {
                    Code = (int)status.StatusCode,
                    Message = status.Detail ?? error.Message,
                };
                
                errorInfo.Details.AddRange(errorDetails);
                
                // Serialize the rich error details
                var serialized = errorInfo.ToByteArray();
                trailers.Add("grpc-status-details-bin", serialized);
            }
        }
        catch (Exception)
        {
            // If we can't serialize error details, add as simple metadata
            trailers.Add("error-code", error.Code);
            trailers.Add("error-type", error.Type.ToString());
        }

        // Add correlation ID if available
        if (!string.IsNullOrEmpty(error.CorrelationId))
        {
            trailers.Add("correlation-id", error.CorrelationId);
        }

        return new RpcException(status, trailers);
    }

    private static object CreateAxiomErrorResponse(AxiomError error)
    {
        return new
        {
            error = new
            {
                code = error.Code,
                message = error.Message,
                type = error.Type.ToString(),
                correlationId = error.CorrelationId,
                details = error.Details
            }
        };
    }

    private static Microsoft.AspNetCore.Mvc.ProblemDetails CreateProblemDetails(AxiomError error)
    {
        return new Microsoft.AspNetCore.Mvc.ProblemDetails
        {
            Title = error.Type.ToString(),
            Detail = error.Message,
            Status = GetHttpStatusCode(error.Type),
            Type = $"https://httpstatuses.com/{GetHttpStatusCode(error.Type)}",
            Extensions =
            {
                ["code"] = error.Code,
                ["correlationId"] = error.CorrelationId,
                ["details"] = error.Details
            }
        };
    }

    private static int GetHttpStatusCode(ErrorType errorType)
    {
        return errorType switch
        {
            ErrorType.NotFound => 404,
            ErrorType.Validation => 400,
            ErrorType.Unauthorized => 401,
            ErrorType.Forbidden => 403,
            ErrorType.Conflict => 409,
            ErrorType.TooManyRequests => 429,
            ErrorType.NotImplemented => 501,
            ErrorType.Timeout => 408,
            ErrorType.Unavailable => 503,
            _ => 500
        };
    }

    private static IList<Any> CreateAxiomErrorDetails(AxiomError error)
    {
        var details = new List<Any>();

        // Add error info using protobuf Any to wrap error details
        var errorInfo = Any.Pack(new Value 
        { 
            StringValue = $"Code: {error.Code}, Type: {error.Type}" 
        });
        details.Add(errorInfo);

        // Add validation details if it's a validation error
        if (error.Type == ErrorType.Validation && error.Fields != null)
        {
            // Create a simple validation error representation using Any
            var validationDetails = Any.Pack(new Value 
            { 
                StringValue = $"Validation errors: {string.Join(", ", error.Fields.Select(f => $"{f.Key}: {f.Value}"))}" 
            });
            details.Add(validationDetails);
        }

        return details;
    }
}

/// <summary>
/// Interceptor for handling exceptions and converting them to appropriate gRPC responses
/// </summary>
public class GrpcAxiomErrorHandlingInterceptor : Interceptor
{
    private readonly ILogger<GrpcAxiomErrorHandlingInterceptor> _logger;

    public GrpcAxiomErrorHandlingInterceptor(ILogger<GrpcAxiomErrorHandlingInterceptor> logger)
    {
        _logger = logger;
    }

    public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
        TRequest request,
        ServerCallContext context,
        UnaryServerMethod<TRequest, TResponse> continuation)
    {
        try
        {
            return await continuation(request, context);
        }
        catch (RpcException)
        {
            // Re-throw RpcExceptions as they're already properly formatted
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in gRPC call {Method}", context.Method);
            
            // Convert to appropriate gRPC exception
            var error = MapExceptionToAxiomError(ex);
            throw error.ToRpcException();
        }
    }

    public override async Task<TResponse> ClientStreamingServerHandler<TRequest, TResponse>(
        IAsyncStreamReader<TRequest> requestStream,
        ServerCallContext context,
        ClientStreamingServerMethod<TRequest, TResponse> continuation)
    {
        try
        {
            return await continuation(requestStream, context);
        }
        catch (RpcException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in gRPC client streaming call {Method}", context.Method);
            
            var error = MapExceptionToAxiomError(ex);
            throw error.ToRpcException();
        }
    }

    public override async Task ServerStreamingServerHandler<TRequest, TResponse>(
        TRequest request,
        IServerStreamWriter<TResponse> responseStream,
        ServerCallContext context,
        ServerStreamingServerMethod<TRequest, TResponse> continuation)
    {
        try
        {
            await continuation(request, responseStream, context);
        }
        catch (RpcException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in gRPC server streaming call {Method}", context.Method);
            
            var error = MapExceptionToAxiomError(ex);
            throw error.ToRpcException();
        }
    }

    public override async Task DuplexStreamingServerHandler<TRequest, TResponse>(
        IAsyncStreamReader<TRequest> requestStream,
        IServerStreamWriter<TResponse> responseStream,
        ServerCallContext context,
        DuplexStreamingServerMethod<TRequest, TResponse> continuation)
    {
        try
        {
            await continuation(requestStream, responseStream, context);
        }
        catch (RpcException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in gRPC duplex streaming call {Method}", context.Method);
            
            var error = MapExceptionToAxiomError(ex);
            throw error.ToRpcException();
        }
    }

    private static AxiomError MapExceptionToAxiomError(Exception ex)
    {
        return ex switch
        {
            ArgumentNullException nullEx => new AxiomError("MISSING_ARGUMENT", nullEx.Message, ErrorType.Validation),
            ArgumentException argEx => new AxiomError("INVALID_ARGUMENT", argEx.Message, ErrorType.Validation),
            UnauthorizedAccessException => new AxiomError("UNAUTHORIZED", "Access denied", ErrorType.Unauthorized),
            NotImplementedException => new AxiomError("NOT_IMPLEMENTED", "Feature not implemented", ErrorType.NotImplemented),
            TimeoutException => new AxiomError("TIMEOUT", "Operation timed out", ErrorType.Timeout),
            OperationCanceledException => new AxiomError("CANCELLED", "Operation was cancelled", ErrorType.Internal),
            _ => new AxiomError("INTERNAL_ERROR", "An internal error occurred", ErrorType.Internal)
        };
    }
}

/// <summary>
/// Validation interceptor that provides structured error responses
/// </summary>
public class GrpcValidationInterceptor : Interceptor
{
    private readonly ILogger<GrpcValidationInterceptor> _logger;

    public GrpcValidationInterceptor(ILogger<GrpcValidationInterceptor> logger)
    {
        _logger = logger;
    }

    public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
        TRequest request,
        ServerCallContext context,
        UnaryServerMethod<TRequest, TResponse> continuation)
    {
        // Validate request before processing
        var validationAxiomError = ValidateRequest(request);
        if (validationAxiomError != null)
        {
            _logger.LogWarning("Validation failed for {Method}: {AxiomError}", context.Method, validationAxiomError.Message);
            throw validationAxiomError.ToRpcException();
        }

        return await continuation(request, context);
    }

    private static AxiomError? ValidateRequest<TRequest>(TRequest request)
    {
        if (request == null)
        {
            var fields = new Dictionary<string, string> { ["request"] = "Request is required" };
            return AxiomError.Validation("Request cannot be null", fields);
        }

        // Add more validation logic as needed
        // This could integrate with FluentValidation or other validation libraries

        return null;
    }
}

/// <summary>
/// Exception extensions for gRPC error handling
/// </summary>
public static class GrpcExceptionExtensions
{
    /// <summary>
    /// Safely extracts error details from an RpcException
    /// </summary>
    public static AxiomError? ExtractAxiomAxiomError(this RpcException rpcException)
    {
        try
        {
            var detailsBinary = rpcException.Trailers
                .FirstOrDefault(t => t.Key == "grpc-status-details-bin");

            if (detailsBinary?.ValueBytes != null)
            {
                var status = Google.Rpc.Status.Parser.ParseFrom(detailsBinary.ValueBytes);
                return new AxiomError(
                    $"GRPC_{(StatusCode)status.Code}",
                    status.Message,
                    MapStatusCodeToErrorType((StatusCode)status.Code));
            }

            // Fallback to basic error info
            return GrpcAxiomErrorMapping.FromGrpcStatus(rpcException.Status);
        }
        catch
        {
            // If we can't parse details, return basic error
            return GrpcAxiomErrorMapping.FromGrpcStatus(rpcException.Status);
        }
    }

    private static ErrorType MapStatusCodeToErrorType(StatusCode statusCode)
    {
        return statusCode switch
        {
            StatusCode.NotFound => ErrorType.NotFound,
            StatusCode.InvalidArgument => ErrorType.Validation,
            StatusCode.Unauthenticated => ErrorType.Unauthorized,
            StatusCode.PermissionDenied => ErrorType.Forbidden,
            StatusCode.AlreadyExists => ErrorType.Conflict,
            StatusCode.ResourceExhausted => ErrorType.TooManyRequests,
            StatusCode.Unimplemented => ErrorType.NotImplemented,
            StatusCode.DeadlineExceeded => ErrorType.Timeout,
            StatusCode.Unavailable => ErrorType.Unavailable,
            _ => ErrorType.Internal
        };
    }
}