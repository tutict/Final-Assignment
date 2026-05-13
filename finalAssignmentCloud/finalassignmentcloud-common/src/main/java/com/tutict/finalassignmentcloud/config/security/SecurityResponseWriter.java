package com.tutict.finalassignmentcloud.config.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

public final class SecurityResponseWriter {

    private SecurityResponseWriter() {
    }

    public static void writeUnauthorized(HttpServletRequest request,
                                         HttpServletResponse response,
                                         AuthenticationException exception) throws IOException {
        write(response, HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "\u8bf7\u5148\u767b\u5f55");
    }

    public static void writeForbidden(HttpServletRequest request,
                                      HttpServletResponse response,
                                      AccessDeniedException exception) throws IOException {
        write(response, HttpStatus.FORBIDDEN, "FORBIDDEN", "\u60a8\u6ca1\u6709\u6743\u9650\u6267\u884c\u6b64\u64cd\u4f5c");
    }

    private static void write(HttpServletResponse response,
                              HttpStatus status,
                              String errorCode,
                              String message) throws IOException {
        response.setStatus(status.value());
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(String.format(
                "{\"success\":false,\"errorCode\":\"%s\",\"message\":\"%s\"}",
                errorCode,
                message));
    }
}
