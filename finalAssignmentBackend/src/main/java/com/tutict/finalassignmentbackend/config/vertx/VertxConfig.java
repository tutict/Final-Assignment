package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VertxConfig {

    @Bean
    public Vertx vertx() {
        return Vertx.vertx();
    }
}
