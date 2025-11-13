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
        logger.log(Level.WARNING, "资源未找到: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("资源未找到: " + ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex) {
        logger.log(Level.WARNING, "无效的请求参数: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("无效的请求参数: " + ex.getMessage());
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<String> handleUnauthorizedException(UnauthorizedException ex) {
        logger.log(Level.WARNING, "未授权访问: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("未授权访问: " + ex.getMessage());
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<String> handleForbiddenException(ForbiddenException ex) {
        logger.log(Level.WARNING, "禁止访问: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("禁止访问: " + ex.getMessage());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<String> handleDataIntegrityViolationException(DataIntegrityViolationException ex) {
        logger.log(Level.WARNING, "数据完整性冲突: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body("数据完整性冲突: " + ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<String> handleMethodArgumentNotValidException(MethodArgumentNotValidException ex) {
        if (ex.getBindingResult() != null) {
            logger.log(Level.WARNING, "请求参数验证失败: {0}", ex.getBindingResult());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("请求参数验证失败: " + ex.getBindingResult());
        }
        return null;
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleGenericException(Exception ex) {
        logger.log(Level.SEVERE, "未捕获异常: {0}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("服务器内部错误: " + ex.getMessage());
    }
}
