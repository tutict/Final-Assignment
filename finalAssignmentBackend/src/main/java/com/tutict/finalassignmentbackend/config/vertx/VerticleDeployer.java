package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import io.vertx.core.Verticle;
import jakarta.annotation.PreDestroy;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class VerticleDeployer {

    private final Vertx vertx;
    private final Verticle vertxNetWorkVerticle;

    @Autowired
    public VerticleDeployer(@Lazy Vertx vertx, VertxNetWorkVerticle vertxNetWorkVerticle) {
        this.vertx = vertx;
        this.vertxNetWorkVerticle = vertxNetWorkVerticle;
    }

    @PostConstruct
    public void deployVerticles() {
        vertx.deployVerticle(vertxNetWorkVerticle)
                .onSuccess(id -> log.info("Vert.x Verticle deployed successfully with deployment ID: {}", id))
                .onFailure(err -> log.error("Failed to deploy Vert.x Verticle: {}", err.getMessage(), err));
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
