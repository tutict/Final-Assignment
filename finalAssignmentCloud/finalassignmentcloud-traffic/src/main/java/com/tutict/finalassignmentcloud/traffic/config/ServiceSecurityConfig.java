package com.tutict.finalassignmentcloud.traffic.config;

import com.tutict.finalassignmentcloud.config.security.SecurityResponseWriter;
import com.tutict.finalassignmentcloud.config.security.ServiceJwtAuthenticationFilter;
import com.tutict.finalassignmentcloud.config.security.ServiceTokenProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(jsr250Enabled = true, prePostEnabled = true, securedEnabled = true)
public class ServiceSecurityConfig {

    @Bean
    public ServiceTokenProvider serviceTokenProvider(
            @Value("${jwt.secret.key:${JWT_SECRET_KEY:}}") String base64Secret) {
        return new ServiceTokenProvider(base64Secret);
    }

    @Bean
    public ServiceJwtAuthenticationFilter serviceJwtAuthenticationFilter(ServiceTokenProvider tokenProvider) {
        return new ServiceJwtAuthenticationFilter(tokenProvider);
    }

    @Bean
    public SecurityFilterChain serviceSecurityFilterChain(HttpSecurity http,
                                                          ServiceJwtAuthenticationFilter jwtAuthenticationFilter)
            throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(SecurityResponseWriter::writeUnauthorized)
                        .accessDeniedHandler(SecurityResponseWriter::writeForbidden))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
