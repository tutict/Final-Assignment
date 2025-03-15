package com.tutict.finalassignmentbackend.config.vertx;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.NetWorkHandler;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import io.vertx.core.Vertx;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VertxBeanConfig {

    @Bean
    public Vertx vertx() {
        return Vertx.vertx();
    }

    @Bean
    public NetWorkHandler netWorkHandler(TokenProvider tokenProvider, ObjectMapper objectMapper) {
        return new NetWorkHandler(tokenProvider, objectMapper);
    }
}