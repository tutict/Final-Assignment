package com.tutict.finalassignmentbackend.config.vertx;

import com.tutict.finalassignmentbackend.config.NetWorkHandler;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.context.annotation.Configuration;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
public class VertxConfig {

    private final Vertx vertx;
    private final NetWorkHandler netWorkHandler;

    public VertxConfig(Vertx vertx, NetWorkHandler netWorkHandler) {
        this.vertx = vertx;
        this.netWorkHandler = netWorkHandler;
    }

    @PostConstruct
    public void start() {
        log.info("Starting Vert.x instance...");
        try {
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle(netWorkHandler, deploymentOptions, result -> {
                if (result.succeeded()) {
                    log.info("NetWorkHandler deployed successfully: {}", result.result());
                } else {
                    log.error("Failed to deploy NetWorkHandler: {}", result.cause().getMessage(), result.cause());
                }
            });
        } catch (Exception e) {
            log.error("Exception occurred during NetWorkHandler startup: {}", e.getMessage(), e);
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
}