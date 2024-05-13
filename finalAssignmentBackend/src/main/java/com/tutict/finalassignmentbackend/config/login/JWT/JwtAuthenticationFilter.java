package com.tutict.finalassignmentbackend.config.login.JWT;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter implements Filter {

    private final TokenProvider tokenProvider;

    public JwtAuthenticationFilter(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        String authHeader = req.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);

            // 验证Token的有效性
            if (tokenProvider.validateToken(token)) {
                // Token有效，从Token中提取用户名
                String username = tokenProvider.getUsernameFromToken(token);

                // 检查用户名是否存在
                if (SecurityContextHolder.getContext().getAuthentication() == null) {
                    // 如果SecurityContextHolder中没有Authentication对象，则创建一个新的
                    Authentication authentication = tokenProvider.getAuthentication(username);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        }

        // 继续过滤器链
        chain.doFilter(request, response);
    }
}
