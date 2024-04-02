package com.tutict.finalassignmentbackend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true); // 允许cookies跨域
        config.addAllowedOrigin("*"); // #允许任何域名使用
        config.addAllowedHeader("*"); // #允许任何头
        config.addAllowedMethod("*"); // 允许任何方法（post、get等）
        source.registerCorsConfiguration("/**", config); // CORS 配置对所有接口都生效
        return new CorsFilter(source);
    }
}