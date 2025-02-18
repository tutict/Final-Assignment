package com.tutict.finalassignmentbackend.config.vertx;

import com.tutict.finalassignmentbackend.config.NetWorkHandler;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Verticle;
import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
public class VertxConfig {

    // 注入 Vertx 实例
    Vertx vertx;

    // 注入 NetWorkHandler 处理器
    NetWorkHandler netWorkHandler;

    /**
     * 当 Spring Boot 应用准备好后，部署 Verticle。
     */
    @PostConstruct
    public void start() {
        log.info("Starting Vert.x instance...");
        try {
            // 部署 NetWorkHandler Verticle
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle((Verticle) netWorkHandler, deploymentOptions, result -> {
                if (result.succeeded()) {
                    log.info("WebSocketServer deployed successfully: {}", result.result());
                } else {
                    log.error("Failed to deploy WebSocketServer: {}", result.cause().getMessage(), result.cause());
                }
            });
        } catch (Exception e) {
            log.error("Exception occurred during WebSocketServer startup: {}", e.getMessage(), e);
        }
    }

    @PreDestroy
    public void shutdown() {
        vertx.close(ar -> {
            if (ar.succeeded()) {
                log.info("Vert.x instance closed successfully.");
            } else {
                log.error("Failed to close Vert.x instance.", ar.cause());
            }
        });
    }

    /**
     * Vertx 实例的配置 Bean，Spring Boot 自动管理它。
     *
     * @return Vertx 实例
     */
    @Bean
    public Vertx vertx() {
        return Vertx.vertx();
    }
}