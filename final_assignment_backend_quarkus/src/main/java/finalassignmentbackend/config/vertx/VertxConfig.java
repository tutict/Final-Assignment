package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.NetWorkHandler;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.runtime.Startup;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.VertxOptions;
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
    TokenProvider tokenProvider;

    @PostConstruct
    public void start() {
        log.info("Starting Vert.x instance...");
        try {
            VertxOptions vertxOptions = new VertxOptions()
                    .setWorkerPoolSize(10)
                    .setBlockedThreadCheckInterval(2000);

            // 创建并启动 Vert.x 实例
            Vertx vertx = Vertx.vertx(vertxOptions);
            log.debug("Vert.x instance started successfully.");

            // 手动实例化 WebSocketServer
            NetWorkHandler server = new NetWorkHandler(vertx, tokenProvider);

            // 使用 Vert.x 管理 Verticle 部署
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle(server, deploymentOptions)
                    .subscribe().with(
                            id -> log.info("WebSocketServer deployed successfully: {}", id),
                            failure -> log.error("Failed to deploy WebSocketServer: {}", failure.getMessage(), failure)
                    );
        } catch (Exception e) {
            log.error("WebSocketServer 启动过程中出现异常：{}", e.getMessage(), e);
            throw e;
        }
    }
}
