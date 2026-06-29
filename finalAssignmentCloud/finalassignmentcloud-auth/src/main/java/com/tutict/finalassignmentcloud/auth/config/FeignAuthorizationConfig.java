package com.tutict.finalassignmentcloud.auth.config;

import feign.RequestInterceptor;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Configuration
public class FeignAuthorizationConfig {

    @Bean
    public RequestInterceptor forwardAuthorizationHeader(
            @Value("${internal.service-token:${INTERNAL_SERVICE_TOKEN:}}") String serviceToken) {
        if (serviceToken == null || serviceToken.isBlank()) {
            throw new IllegalStateException(
                    "internal.service-token must be provided through INTERNAL_SERVICE_TOKEN or configuration");
        }
        return template -> {
            // 转发入站用户 JWT，供下游 JWT 保护的端点鉴权
            RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
            if (attributes instanceof ServletRequestAttributes servletAttributes) {
                HttpServletRequest request = servletAttributes.getRequest();
                String authorization = request.getHeader("Authorization");
                if (authorization != null && !authorization.isBlank()) {
                    template.header("Authorization", authorization);
                }
            }
            // 注入内部 service token，供 /internal/** 端点校验（非 internal 端点忽略该头）
            template.header("X-Internal-Service-Token", serviceToken);
        };
    }
}
