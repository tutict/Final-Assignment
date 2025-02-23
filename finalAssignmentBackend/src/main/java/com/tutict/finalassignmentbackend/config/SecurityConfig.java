package com.tutict.finalassignmentbackend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 配置请求授权
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/api/auth/register", "/api/auth/login").permitAll() // 公开注册和登录
                        .requestMatchers("/api/**").hasAnyRole("ADMIN", "USER") // 限制获取用户
                        .requestMatchers("/eventbus/**").hasAnyRole("ADMIN", "USER")
                        .anyRequest().authenticated() // 其他请求需认证
                )
                // 禁用 CSRF（API 服务无需 CSRF）
                .csrf(AbstractHttpConfigurer::disable)
                // 禁用表单登录（API 不使用）
                .formLogin(AbstractHttpConfigurer::disable)
                // 禁用 HTTP Basic 认证（API 使用 JWT 或其他机制）
                .httpBasic(AbstractHttpConfigurer::disable)
                // 设置无状态会话（可选，根据需求）
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        return http.build();
    }
}