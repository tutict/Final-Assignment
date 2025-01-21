package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.NetWorkHandler;
import io.quarkus.runtime.Startup;
import io.vertx.core.DeploymentOptions;
import io.vertx.mutiny.core.Vertx;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Startup
@ApplicationScoped
public class VertxConfig {

    @Inject
    Vertx vertx;

    @Inject
    NetWorkHandler netWorkHandler;

    @PostConstruct
    public void start() {
        log.info("Starting Vert.x instance...");
        try {
            // 部署 NetWorkHandler Verticle
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle(netWorkHandler, deploymentOptions)
                    .subscribe().with(
                            id -> log.info("WebSocketServer deployed successfully: {}", id),
                            failure -> log.error("Failed to deploy WebSocketServer: {}", failure.getMessage(), failure)
                    );
        } catch (Exception e) {
            log.error("WebSocketServer 启动过程中出现异常：{}", e.getMessage(), e);
        }
    }
}
