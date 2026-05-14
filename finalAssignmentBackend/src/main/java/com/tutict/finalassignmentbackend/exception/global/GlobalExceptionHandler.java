package com.tutict.finalassignmentbackend.exception.global;

import com.github.dockerjava.api.exception.UnauthorizedException;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.exception.BusinessException;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.exception.OptimisticLockException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.ForbiddenException;
import org.apache.kafka.common.errors.ResourceNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = Logger.getLogger(GlobalExceptionHandler.class.getName());

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleResourceNotFoundException(ResourceNotFoundException ex,
                                                                               HttpServletRequest request) {
        logger.log(Level.WARNING, "Resource not found: {0}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "请求的资源不存在", request, null);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgumentException(IllegalArgumentException ex,
                                                                              HttpServletRequest request) {
        logger.log(Level.WARNING, "Illegal argument: {0}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, ex.getMessage(), request, null);
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorizedException(UnauthorizedException ex,
                                                                           HttpServletRequest request) {
        logger.log(Level.WARNING, "Unauthorized: {0}", ex.getMessage());
        return buildResponse(HttpStatus.UNAUTHORIZED, "未授权", request, null);
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, Object>> handleForbiddenException(ForbiddenException ex,
                                                                        HttpServletRequest request) {
        logger.log(Level.WARNING, "Forbidden: {0}", ex.getMessage());
        return buildResponse(HttpStatus.FORBIDDEN, "无权访问", request, null);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        logger.log(Level.WARNING, "Access denied: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error("FORBIDDEN", "您没有权限执行此操作"));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnauthorized(AuthenticationException ex) {
        logger.log(Level.WARNING, "Unauthorized: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error("UNAUTHORIZED", "请先登录"));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrityViolationException(
            DataIntegrityViolationException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "Data integrity violation: {0}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "数据冲突或重复提交", request, null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleMethodArgumentNotValidException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "Validation failed: {0}", ex.getMessage());
        List<Map<String, String>> fieldErrors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null ? "" : error.getDefaultMessage()))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "参数校验失败", request, Map.of("errors", fieldErrors));
    }

    @ExceptionHandler(BindException.class)
    public ResponseEntity<Map<String, Object>> handleBindException(BindException ex,
                                                                   HttpServletRequest request) {
        logger.log(Level.WARNING, "Binding failed: {0}", ex.getMessage());
        List<Map<String, String>> fieldErrors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null ? "" : error.getDefaultMessage()))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "参数绑定失败", request, Map.of("errors", fieldErrors));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraintViolationException(
            ConstraintViolationException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "Constraint violation: {0}", ex.getMessage());
        List<Map<String, String>> violations = ex.getConstraintViolations()
                .stream()
                .map(ConstraintViolation::getMessage)
                .map(message -> Map.of("message", message))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "参数约束失败", request, Map.of("violations", violations));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingServletRequestParameterException(
            MissingServletRequestParameterException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "Missing request parameter: {0}", ex.getParameterName());
        return buildResponse(HttpStatus.BAD_REQUEST,
                "缺少请求参数: " + ex.getParameterName(), request, null);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException ex) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.error(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(OptimisticLockException.class)
    public ResponseEntity<ApiResponse<Void>> handleOptimisticLock(OptimisticLockException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error("CONFLICT", ex.getMessage()));
    }

    @ExceptionHandler({EntityNotFoundException.class, EmptyResultDataAccessException.class})
    public ResponseEntity<ApiResponse<Void>> handleNotFound(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error("NOT_FOUND", "请求的资源不存在"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGenericException(Exception ex) {
        logger.log(Level.SEVERE, "Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("INTERNAL_ERROR", "服务器内部错误，请联系管理员"));
    }

    private ResponseEntity<Map<String, Object>> buildResponse(HttpStatus status,
                                                              String message,
                                                              HttpServletRequest request,
                                                              Map<String, Object> extra) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("message", message);
        body.put("path", request == null ? "" : request.getRequestURI());
        if (extra != null && !extra.isEmpty()) {
            body.putAll(extra);
        }
        return ResponseEntity.status(status).body(body);
    }
}
