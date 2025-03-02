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
                .authorizeHttpRequests(authorize -> authorize
                        // 公共接口（无需认证）
                        .requestMatchers("/api/auth/register", "/api/auth/login", "/api/ai/chat").permitAll()
                        // 所有 /api/** 接口需要认证（具体权限由 @PreAuthorize 控制）
                        .requestMatchers("/api/**").authenticated()
                        // EventBus 相关接口需要认证（具体权限由 @PreAuthorize 或其他配置控制）
                        .requestMatchers("/eventbus/**").authenticated()
                        // 其他所有请求需要认证
                        .anyRequest().authenticated()
                )
                .csrf(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        return http.build();
    }
}