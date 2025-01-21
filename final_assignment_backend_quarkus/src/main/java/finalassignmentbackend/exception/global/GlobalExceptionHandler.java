package finalassignmentbackend.exception.global;

import com.baomidou.mybatisplus.core.exceptions.MybatisPlusException;
import jakarta.ws.rs.ForbiddenException;
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

    @Provider
    public static class MyBatisExceptionHandle implements ExceptionMapper<MybatisPlusException> {
        @Override
        public Response toResponse(MybatisPlusException ex) {
            logger.log(Level.WARNING, "MyBatis Plus Error", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity("MyBatis Plus 异常: " + ex.getMessage()).build();
        }
    }

    // 其他错误
    @Provider
    public static class GenericExceptionHandler implements ExceptionMapper<Exception> {
        @Override
        public Response toResponse(Exception ex) {
            logger.log(Level.SEVERE, "An error occurred", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity("服务器内部错误: " + ex.getMessage()).build();
        }
    }
}
