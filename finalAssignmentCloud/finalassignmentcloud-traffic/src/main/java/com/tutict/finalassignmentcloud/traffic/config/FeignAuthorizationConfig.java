package com.tutict.finalassignmentcloud.traffic.config;

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
            RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
            if (attributes instanceof ServletRequestAttributes servletAttributes) {
                HttpServletRequest request = servletAttributes.getRequest();
                String authorization = request.getHeader("Authorization");
                if (authorization != null && !authorization.isBlank()) {
                    template.header("Authorization", authorization);
                }
            }
            template.header("X-Internal-Service-Token", serviceToken);
        };
    }
}
