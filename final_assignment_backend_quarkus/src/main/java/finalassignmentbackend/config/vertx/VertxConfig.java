package finalassignmentbackend.config.vertx;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.runtime.Startup;
import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.jboss.logging.Logger;

@Startup
@ApplicationScoped
public class VertxConfig {

    private static final Logger log = Logger.getLogger(VertxConfig.class);

    @Inject
    TokenProvider tokenProvider;

    @Produces
    @ApplicationScoped
    public Vertx vertx() {
        VertxOptions vertxOptions = new VertxOptions()
                .setWorkerPoolSize(10)
                .setBlockedThreadCheckInterval(2000);

        Vertx vertx = Vertx.vertx(vertxOptions);

        vertx.deployVerticle(new WebSocketServer(tokenProvider).toString())
                .onSuccess(id -> log.info("WebSocketServer deployed successfully: " + id))
                .onFailure(t -> log.error("Failed to deploy WebSocketServer", t));

        return vertx;
    }
}
