package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VertxConfig {

    @Bean
    public Vertx vertx() {
        Vertx vertx = Vertx.vertx(new VertxOptions().setWorkerPoolSize(10));
        vertx.deployVerticle(new WebSocketServer());
        return vertx;
    }
}
