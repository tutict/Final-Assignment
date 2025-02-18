package com.tutict.finalassignmentbackend.exception.global;

import com.github.dockerjava.api.exception.UnauthorizedException;
import jakarta.ws.rs.ForbiddenException;
import org.apache.kafka.common.errors.ResourceNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.support.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.logging.Level;
import java.util.logging.Logger;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = Logger.getLogger(String.valueOf(GlobalExceptionHandler.class));

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<String> handleResourceNotFoundException(ResourceNotFoundException ex) {
        logger.log(Level.WARNING, "Resource not found", ex);
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex) {
        logger.log(Level.WARNING, "Invalid request parameter", ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("无效的请求参数: " + ex.getMessage());
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<String> handleUnauthorizedException(UnauthorizedException ex) {
        logger.log(Level.WARNING, "Unauthorized access", ex);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("未经授权的访问: " + ex.getMessage());
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<String> handleForbiddenException(ForbiddenException ex) {
        logger.log(Level.WARNING, "Forbidden access", ex);
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("禁止访问: " + ex.getMessage());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<String> handleDataIntegrityViolationException(DataIntegrityViolationException ex) {
        logger.log(Level.WARNING, "Data integrity violation", ex);
        return ResponseEntity.status(HttpStatus.CONFLICT).body("数据完整性冲突: " + ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<String> handleMethodArgumentNotValidException(MethodArgumentNotValidException ex) {
        if (ex.getBindingResult() != null) {
            logger.log(Level.WARNING, "Invalid request parameter", ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("请求参数验证失败: " + ex.getBindingResult().toString());
        }
        return null;
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleGenericException(Exception ex) {
        logger.log(Level.WARNING, "Generic exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("服务器内部错误: " + ex.getMessage());
    }
}
