package com.tutict.finalassignmentbackend.config.login.JWT;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class JwtAuthorizationFilter implements Filter {

    private final TokenProvider tokenProvider;

    public JwtAuthorizationFilter(TokenProvider tokenProvider)
    {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain filterChain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String authHeader = httpRequest.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring("Bearer ".length());

            try {
                // 验证JWT Token
                if (tokenProvider.validateToken(token)) {
                    // 如果Token有效，从Token中获取用户名
                    String username = tokenProvider.getUsernameFromToken(token);

                    // 检查SecurityContextHolder是否已经有Authentication对象
                    if (SecurityContextHolder.getContext().getAuthentication() == null) {
                        // 创建Authentication对象并加入到SecurityContextHolder
                        Authentication authentication = tokenProvider.getAuthentication(username);
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                    }
                    // 其他逻辑...
                } else {
                    // 如果Token无效，可以在这里处理，例如返回401 Unauthorized响应
                    throw new ServletException("Invalid JWT Token");
                }
            } catch (Exception ex) {
                // 如果在验证过程中发生异常，可以在这里处理
                throw new ServletException("Error processing JWT Token", ex);
            }
        }

        // 继续过滤器链
        filterChain.doFilter(request, response);
    }
}
