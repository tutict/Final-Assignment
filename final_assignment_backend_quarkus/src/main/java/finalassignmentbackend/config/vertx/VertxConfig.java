package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.runtime.Startup;
import io.vertx.core.VertxOptions;
import io.vertx.mutiny.core.Vertx;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Startup
@ApplicationScoped
public class VertxConfig {

    @Inject
    WebSocketServer webSocketServer;

    @Inject
    TokenProvider tokenProvider;

    public VertxConfig(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @PostConstruct
    public void start() {
        VertxOptions vertxOptions = new VertxOptions()
                .setWorkerPoolSize(10)
                .setBlockedThreadCheckInterval(2000);

        Vertx vertx = Vertx.vertx(vertxOptions);

        webSocketServer.start();

        vertx.deployVerticle(webSocketServer)
                .subscribe().with(
                        id -> log.info("WebSocketServer deployed successfully: {}", id),
                        failure -> log.error("Failed to deploy WebSocketServer", failure)
                );
    }
}
