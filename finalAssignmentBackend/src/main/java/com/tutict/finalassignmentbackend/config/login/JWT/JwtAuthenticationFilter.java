package com.tutict.finalassignmentbackend.config.login.JWT;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
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

    /**
     * 执行过滤操作
     * 从请求中提取JWT令牌，验证令牌并设置认证信息
     *
     * @param request  请求对象
     * @param response 响应对象
     * @param chain    过滤器链
     * @throws IOException      如果在读取或写入过程中发生I/O错误
     * @throws ServletException 如果发生Servlet异常
     */
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        // 将ServletRequest转换为HttpServletRequest
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        // 从请求中提取JWT令牌
        String jwtToken = extractToken(httpRequest);

        // 如果令牌存在且有效
        if (jwtToken != null && tokenProvider.validateToken(jwtToken)) {
            // 从令牌中获取用户名
            String username = tokenProvider.getUsernameFromToken(jwtToken);

            // 如果用户名存在且上下文中的认证信息为空
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                // 创建认证对象并设置到上下文中
                Authentication authentication = tokenProvider.getAuthentication(username);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        // 继续执行过滤器链中的下一个过滤器
        chain.doFilter(request, response);
    }

    /**
     * 从请求头中提取JWT令牌
     *
     * @param request HTTP请求对象
     * @return 提取到的JWT令牌字符串，如果请求头不存在或不以"Bearer "开头，则返回null
     */
    private String extractToken(HttpServletRequest request) {
        // 获取请求头中的Authorization信息
        String authHeader = request.getHeader("Authorization");
        // 如果请求头存在且以"Bearer "开头
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            // 返回令牌字符串，去除"Bearer "部分
            return authHeader.substring(7);
        }
        // 不满足条件时返回null
        return null;
    }
}
