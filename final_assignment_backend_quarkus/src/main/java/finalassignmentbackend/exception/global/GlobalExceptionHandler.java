package finalassignmentbackend.exception.global;

import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import org.apache.kafka.common.errors.ResourceNotFoundException;
import org.jboss.logging.Logger;

@Provider
public class GlobalExceptionHandler {

    private static final Logger logger = Logger.getLogger(GlobalExceptionHandler.class);

    @Provider
    public static class ResourceNotFoundExceptionHandler implements ExceptionMapper<ResourceNotFoundException> {
        @Override
        public Response toResponse(ResourceNotFoundException ex) {
            logger.error("Resource not found", ex);
            return Response.status(Response.Status.NOT_FOUND).entity(ex.getMessage()).build();
        }
    }

    @Provider
    public static class IllegalArgumentExceptionHandler implements ExceptionMapper<IllegalArgumentException> {
        @Override
        public Response toResponse(IllegalArgumentException ex) {
            logger.error("Invalid request parameter", ex);
            return Response.status(Response.Status.BAD_REQUEST).entity("无效的请求参数: " + ex.getMessage()).build();
        }
    }

    @Provider
    public static class UnauthorizedExceptionHandler implements ExceptionMapper<NotAuthorizedException> {
        @Override
        public Response toResponse(NotAuthorizedException ex) {
            logger.error("Unauthorized access", ex);
            return Response.status(Response.Status.UNAUTHORIZED).entity("未经授权的访问: " + ex.getMessage()).build();
        }
    }

    @Provider
    public static class ForbiddenExceptionHandler implements ExceptionMapper<ForbiddenException> {
        @Override
        public Response toResponse(ForbiddenException ex) {
            logger.error("Forbidden access", ex);
            return Response.status(Response.Status.FORBIDDEN).entity("禁止访问: " + ex.getMessage()).build();
        }
    }

    @Provider
    public static class GenericExceptionHandler implements ExceptionMapper<Exception> {
        @Override
        public Response toResponse(Exception ex) {
            logger.error("Internal server error", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity("服务器内部错误: " + ex.getMessage()).build();
        }
    }
}
