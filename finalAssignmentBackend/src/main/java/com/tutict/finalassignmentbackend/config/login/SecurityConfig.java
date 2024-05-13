package com.tutict.finalassignmentbackend.config.login;

import com.tutict.finalassignmentbackend.config.login.JWT.JwtAuthenticationFilter;
import com.tutict.finalassignmentbackend.config.login.JWT.JwtAuthorizationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 由于使用JWT，禁用了基于session的认证
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                // 允许所有用户访问公共API
                .authorizeRequests(authorize -> authorize
                        .antMatchers("/api/public/**").permitAll()
                        // 其他所有请求都需要认证
                        .anyRequest().authenticated()
                )
                // 添加JWT身份验证过滤器
                .addFilterBefore(new JwtAuthenticationFilter(tokenProvider, authenticationManager()), UsernamePasswordAuthenticationFilter.class)
                // 添加JWT授权过滤器
                .addFilterAfter(new JwtAuthorizationFilter(tokenProvider), JwtAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        PasswordEncoder encoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
        UserDetails user = User.withUsername("user")
                .password(encoder.encode("password"))
                .roles("USER")
                .build();

        UserDetails admin = User.withUsername("admin")
                .password(encoder.encode("password"))
                .roles("ADMIN")
                .build();

        return new InMemoryUserDetailsManager(user, admin);
    }
}