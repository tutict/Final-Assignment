package com.tutict.finalassignmentbackend.config.vertx;

import com.tutict.finalassignmentbackend.config.login.JWT.TokenProvider;
import com.tutict.finalassignmentbackend.config.WebSocketServer;
import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import io.vertx.core.DeploymentOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Configuration
public class VertxConfig {

    TokenProvider tokenProvider;

    @Bean
    public Vertx vertx() {
        VertxOptions vertxOptions = new VertxOptions()
                .setWorkerPoolSize(10)
                .setBlockedThreadCheckInterval(2000);
        return Vertx.vertx(vertxOptions);
    }

    @PostConstruct
    public void deployWebSocketServer() {
        log.info("Starting Vert.x instance...");
        try {
            Vertx vertx = vertx();
            log.debug("Vert.x instance started successfully.");

            // 手动实例化 WebSocketServer
            WebSocketServer server = new WebSocketServer(vertx, tokenProvider);

            // 使用 Vert.x 管理 Verticle 部署
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle(server, deploymentOptions, res -> {
                if (res.succeeded()) {
                    log.info("WebSocketServer deployed successfully: {}", res.result());
                } else {
                    log.error("Failed to deploy WebSocketServer: {}", res.cause().getMessage(), res.cause());
                }
            });
        } catch (Exception e) {
            log.error("WebSocketServer 启动过程中出现异常：{}", e.getMessage(), e);
            throw e;
        }
    }
}
