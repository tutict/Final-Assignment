package com.tutict.finalassignmentbackend.exception.global;

import com.github.dockerjava.api.exception.UnauthorizedException;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.FieldErrorDetail;
import com.tutict.finalassignmentbackend.exception.BusinessException;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.exception.OptimisticLockException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.ForbiddenException;
import org.apache.kafka.common.errors.ResourceNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = Logger.getLogger(GlobalExceptionHandler.class.getName());

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleResourceNotFoundException(ResourceNotFoundException ex) {
        logger.log(Level.WARNING, "Resource not found: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error("NOT_FOUND", messageOrDefault(ex.getMessage(), "Resource not found")));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgumentException(IllegalArgumentException ex) {
        logger.log(Level.WARNING, "Illegal argument: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error("INVALID_ARGUMENT", messageOrDefault(ex.getMessage(), "Invalid argument")));
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnauthorizedException(UnauthorizedException ex) {
        logger.log(Level.WARNING, "Unauthorized: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error("UNAUTHORIZED", "Unauthorized"));
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<ApiResponse<Void>> handleForbiddenException(ForbiddenException ex) {
        logger.log(Level.WARNING, "Forbidden: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error("FORBIDDEN", "Forbidden"));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        logger.log(Level.WARNING, "Access denied: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error("FORBIDDEN", "Forbidden"));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnauthorized(AuthenticationException ex) {
        logger.log(Level.WARNING, "Unauthorized: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error("UNAUTHORIZED", "Please login first"));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataIntegrityViolationException(DataIntegrityViolationException ex) {
        logger.log(Level.WARNING, "Data integrity violation: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error("CONFLICT", "\u6570\u636e\u7ea6\u675f\u51b2\u7a81"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<List<FieldErrorDetail>>> handleMethodArgumentNotValidException(
            MethodArgumentNotValidException ex) {
        logger.log(Level.WARNING, "Validation failed: {0}", ex.getMessage());
        return validationError(ex.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorDetail(
                        error.getField(),
                        translateMessage(messageOrDefault(error.getDefaultMessage(), "校验失败"))))
                .toList());
    }

    @ExceptionHandler(BindException.class)
    public ResponseEntity<ApiResponse<List<FieldErrorDetail>>> handleBindException(BindException ex) {
        logger.log(Level.WARNING, "Binding failed: {0}", ex.getMessage());
        return validationError(ex.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorDetail(
                        error.getField(),
                        translateMessage(messageOrDefault(error.getDefaultMessage(), "校验失败"))))
                .toList());
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<List<FieldErrorDetail>>> handleConstraintViolationException(
            ConstraintViolationException ex) {
        logger.log(Level.WARNING, "Constraint violation: {0}", ex.getMessage());
        return validationError(ex.getConstraintViolations().stream()
                .map(this::toFieldError)
                .toList());
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<Void>> handleMissingServletRequestParameterException(
            MissingServletRequestParameterException ex) {
        logger.log(Level.WARNING, "Missing request parameter: {0}", ex.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(
                        "MISSING_PARAMETER",
                        "缺少必要请求参数: " + ex.getParameterName()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleHttpMessageNotReadableException(
            HttpMessageNotReadableException ex) {
        logger.log(Level.WARNING, "Request body is not readable: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error("BAD_REQUEST", "Invalid request body"));
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
                .body(ApiResponse.error("NOT_FOUND", "Resource not found"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGenericException(Exception ex) {
        logger.log(Level.SEVERE, "Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("INTERNAL_ERROR", "Internal server error"));
    }

    private ResponseEntity<ApiResponse<List<FieldErrorDetail>>> validationError(List<FieldErrorDetail> errors) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.<List<FieldErrorDetail>>builder()
                        .success(false)
                        .errorCode("VALIDATION_ERROR")
                        .message("\u8bf7\u6c42\u53c2\u6570\u6821\u9a8c\u5931\u8d25")
                        .data(errors)
                        .build());
    }

    private FieldErrorDetail toFieldError(ConstraintViolation<?> violation) {
        String path = violation.getPropertyPath() == null ? "" : violation.getPropertyPath().toString();
        int lastDot = path.lastIndexOf('.');
        String field = lastDot >= 0 ? path.substring(lastDot + 1) : path;
        return new FieldErrorDetail(field, translateMessage(violation.getMessage()));
    }

    private static String messageOrDefault(String message, String fallback) {
        return message == null || message.isBlank() ? fallback : message;
    }

    private static String translateMessage(String message) {
        if (message == null) {
            return "校验失败";
        }
        return switch (message) {
            case "must not be blank" -> "不能为空";
            case "must not be null" -> "不能为空";
            case "must be positive" -> "必须大于 0";
            default -> message;
        };
    }
}
