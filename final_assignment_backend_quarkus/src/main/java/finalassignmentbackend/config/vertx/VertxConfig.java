package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.runtime.Startup;
import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Startup
@ApplicationScoped
public class VertxConfig {

    private final TokenProvider tokenProvider;

    public VertxConfig(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @PostConstruct
    public void start() {
        VertxOptions vertxOptions = new VertxOptions()
                .setWorkerPoolSize(10)
                .setBlockedThreadCheckInterval(2000);

        Vertx vertx = Vertx.vertx(vertxOptions);

        vertx.deployVerticle(new WebSocketServer(tokenProvider).toString())
                .onSuccess(id -> log.info("WebSocketServer deployed successfully: {}", id))
                .onFailure(t -> log.error("Failed to deploy WebSocketServer: {}", t.getMessage()));
    }
}
