package com.tutict.finalassignmentbackend.exception.global;

import com.github.dockerjava.api.exception.UnauthorizedException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.ForbiddenException;
import org.apache.kafka.common.errors.ResourceNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
        logger.log(Level.WARNING, "资源未找到: {0}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "资源未找到: " + ex.getMessage(), request, null);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgumentException(IllegalArgumentException ex,
                                                                              HttpServletRequest request) {
        logger.log(Level.WARNING, "无效的请求参数: {0}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "无效的请求参数: " + ex.getMessage(), request, null);
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorizedException(UnauthorizedException ex,
                                                                           HttpServletRequest request) {
        logger.log(Level.WARNING, "未授权访问: {0}", ex.getMessage());
        return buildResponse(HttpStatus.UNAUTHORIZED, "未授权访问: " + ex.getMessage(), request, null);
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, Object>> handleForbiddenException(ForbiddenException ex,
                                                                        HttpServletRequest request) {
        logger.log(Level.WARNING, "禁止访问: {0}", ex.getMessage());
        return buildResponse(HttpStatus.FORBIDDEN, "禁止访问: " + ex.getMessage(), request, null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrityViolationException(
            DataIntegrityViolationException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "数据完整性冲突: {0}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "数据完整性冲突: " + ex.getMessage(), request, null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleMethodArgumentNotValidException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "请求参数验证失败: {0}", ex.getMessage());
        List<Map<String, String>> fieldErrors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null ? "" : error.getDefaultMessage()))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "请求参数验证失败", request, Map.of("errors", fieldErrors));
    }

    @ExceptionHandler(BindException.class)
    public ResponseEntity<Map<String, Object>> handleBindException(BindException ex,
                                                                   HttpServletRequest request) {
        logger.log(Level.WARNING, "请求参数绑定失败: {0}", ex.getMessage());
        List<Map<String, String>> fieldErrors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null ? "" : error.getDefaultMessage()))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "请求参数绑定失败", request, Map.of("errors", fieldErrors));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraintViolationException(
            ConstraintViolationException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "请求参数校验失败: {0}", ex.getMessage());
        List<Map<String, String>> violations = ex.getConstraintViolations()
                .stream()
                .map(ConstraintViolation::getMessage)
                .map(message -> Map.of("message", message))
                .toList();
        return buildResponse(HttpStatus.BAD_REQUEST, "请求参数校验失败", request, Map.of("violations", violations));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingServletRequestParameterException(
            MissingServletRequestParameterException ex,
            HttpServletRequest request) {
        logger.log(Level.WARNING, "缺少请求参数: {0}", ex.getParameterName());
        return buildResponse(HttpStatus.BAD_REQUEST,
                "缺少请求参数: " + ex.getParameterName(), request, null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex,
                                                                      HttpServletRequest request) {
        logger.log(Level.SEVERE, "未捕获异常: {0}", ex.getMessage());
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR,
                "服务器内部错误: " + ex.getMessage(), request, null);
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
