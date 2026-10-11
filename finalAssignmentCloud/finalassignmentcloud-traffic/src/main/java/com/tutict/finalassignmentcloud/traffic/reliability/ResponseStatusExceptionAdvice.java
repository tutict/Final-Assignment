package com.tutict.finalassignmentcloud.traffic.reliability;

import java.util.Map;

import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/**
 * common 模块的 GlobalExceptionHandler 用 @ExceptionHandler(Exception.class) 兜底，
 * 会把 ResponseStatusException 吞成 500。此 advice 以更高优先级保留其状态码，
 * 并返回与其他三端一致的 {errorCode, message} 契约。
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ResponseStatusExceptionAdvice {

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> handleResponseStatusException(ResponseStatusException ex) {
        HttpStatus status = HttpStatus.valueOf(ex.getStatusCode().value());
        String message = ex.getReason() == null ? status.getReasonPhrase() : ex.getReason();
        return ResponseEntity.status(status)
                .body(Map.of("errorCode", errorCode(status), "message", message));
    }

    private static String errorCode(HttpStatus status) {
        return switch (status) {
            case BAD_REQUEST -> "INVALID_ARGUMENT";
            case FORBIDDEN -> "FORBIDDEN";
            case NOT_FOUND -> "NOT_FOUND";
            case CONFLICT -> "IDEMPOTENCY_CONFLICT";
            default -> "REQUEST_FAILED";
        };
    }
}
