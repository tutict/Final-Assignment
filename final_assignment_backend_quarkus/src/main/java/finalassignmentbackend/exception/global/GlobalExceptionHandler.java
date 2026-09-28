package finalassignmentbackend.exception.global;

import com.baomidou.mybatisplus.core.exceptions.MybatisPlusException;
import finalassignmentbackend.reliability.LedgerConnectionPolicy;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.UriInfo;
import java.util.Map;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import org.apache.kafka.common.errors.ResourceNotFoundException;

import java.util.logging.Level;
import java.util.logging.Logger;

@Provider
public class GlobalExceptionHandler {

    private static final Logger logger = Logger.getLogger(String.valueOf(GlobalExceptionHandler.class));

    // 处理 ResourceNotFoundException
    @Provider
    public static class ResourceNotFoundExceptionHandler implements ExceptionMapper<ResourceNotFoundException> {
        @Override
        public Response toResponse(ResourceNotFoundException ex) {
            logger.log(Level.WARNING, "Resource not found", ex);
            return Response.status(Response.Status.NOT_FOUND).entity("没找到相应的资源" + ex.getMessage()).build();
        }
    }

    // 处理 IllegalArgumentException
    @Provider
    public static class IllegalArgumentExceptionHandler implements ExceptionMapper<IllegalArgumentException> {
        @Override
        public Response toResponse(IllegalArgumentException ex) {
            logger.log(Level.WARNING, "Invalid request parameter", ex);
            return Response.status(Response.Status.BAD_REQUEST).entity("无效的请求参数: " + ex.getMessage()).build();
        }
    }

    // 处理 NotAuthorizedException
    @Provider
    public static class UnauthorizedExceptionHandler implements ExceptionMapper<NotAuthorizedException> {
        @Override
        public Response toResponse(NotAuthorizedException ex) {
            logger.log(Level.WARNING, "Unauthorized access", ex);
            return Response.status(Response.Status.UNAUTHORIZED).entity("未经授权的访问: " + ex.getMessage()).build();
        }
    }

    // 处理 ForbiddenException
    @Provider
    public static class ForbiddenExceptionHandler implements ExceptionMapper<ForbiddenException> {
        @Override
        public Response toResponse(ForbiddenException ex) {
            logger.log(Level.WARNING, "Forbidden access", ex);
            return Response.status(Response.Status.FORBIDDEN).entity("禁止访问: " + ex.getMessage()).build();
        }
    }

    static Response connectionWaitResponse(Exception ex, Request request, UriInfo uriInfo, ReliabilityMetrics metrics) {
        if (!LedgerConnectionPolicy.connectionWait(ex)) {
            return null;
        }
        if (metrics != null) {
            metrics.dependencyTimeout();
        }
        return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                .header("Retry-After", "1")
                .entity(Map.of("errorCode", "DEPENDENCY_TIMEOUT", "message", "Database connection wait exceeded 200ms"))
                .build();
    }

    @Provider
    public static class MyBatisExceptionHandle implements ExceptionMapper<MybatisPlusException> {
        @Context
        UriInfo uriInfo;

        @Context
        Request request;

        @Inject
        ReliabilityMetrics metrics;

        @Override
        public Response toResponse(MybatisPlusException ex) {
            Response shed = connectionWaitResponse(ex, request, uriInfo, metrics);
            if (shed != null) {
                return shed;
            }
            logger.log(Level.WARNING, "MyBatis Plus Error", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(ex.getMessage()).build();
        }
    }

    @Provider
    public static class GenericExceptionHandler implements ExceptionMapper<Exception> {
        @Context
        UriInfo uriInfo;

        @Context
        Request request;

        @Inject
        ReliabilityMetrics metrics;

        @Override
        public Response toResponse(Exception ex) {
            if (ex instanceof WebApplicationException wae && wae.getResponse() != null) {
                return wae.getResponse();
            }
            Response shed = connectionWaitResponse(ex, request, uriInfo, metrics);
            if (shed != null) {
                return shed;
            }
            logger.log(Level.SEVERE, "An error occurred", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(ex.getMessage()).build();
        }
    }
}
