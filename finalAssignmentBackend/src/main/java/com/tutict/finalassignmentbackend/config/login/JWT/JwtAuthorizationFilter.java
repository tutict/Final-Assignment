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


/**
 * 自定义的过滤器类，用于处理JWT令牌
 * 该类继承了Filter，并重写了doFilter方法，用以在请求处理前验证JWT令牌
 */
@Component
public class JwtAuthorizationFilter implements Filter {

    private final TokenProvider tokenProvider;

    public JwtAuthorizationFilter(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }


        /**
         * 对HTTP请求进行过滤，验证JWT令牌并设置认证信息
         *
         * @param request  ServletRequest对象，通常是一个HTTP请求
         * @param response ServletResponse对象，通常是一个HTTP响应
         * @param chain    FilterChain对象，用于继续传递请求或响应
         * @throws IOException           如果在读取或写入过程中发生I/O错误
         * @throws ServletException      如果过滤器抛出了异常
         */

        @Override
        public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
            // 将ServletRequest转换为HttpServletRequest，以便获取请求头
            HttpServletRequest httpRequest = (HttpServletRequest) request;
            // 从请求中提取JWT令牌
            String jwtToken = extractToken(httpRequest);

            try {
                // 如果令牌不为空且验证通过
                if (jwtToken != null && tokenProvider.validateToken(jwtToken)) {
                    // 从令牌中获取用户名
                    String username = tokenProvider.getUsernameFromToken(jwtToken);

                    // 如果用户名不为空且当前没有认证信息
                    if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                        // 创建认证对象并设置到上下文中
                        Authentication authentication = tokenProvider.getAuthentication(jwtToken);
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                    }
                }
            } catch (Exception ex) {
                // 如果处理令牌时发生异常，抛出ServletException
                throw new ServletException("Error processing JWT Token", ex);
            }

            // 继续执行请求链
            chain.doFilter(request, response);
        }

        /**
         * 从HttpServletRequest中提取JWT令牌
         *
         * @param request HttpServletRequest对象，用于获取请求头
         * @return 提取到的JWT令牌字符串，如果请求头格式不正确或没有则返回null
         */
        private String extractToken(HttpServletRequest request) {
            // 获取请求头中的Authorization信息
            String authHeader = request.getHeader("Authorization");
            // 如果请求头存在且以"Bearer "开头，则返回令牌字符串
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                return authHeader.substring(7);
            }
            return null;
        }
    }
