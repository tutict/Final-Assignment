package finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

@ApplicationScoped
public class VertxConfig {

    @Produces
    public Vertx vertx() {
        Vertx vertx = Vertx.vertx(new VertxOptions().setWorkerPoolSize(10));
        vertx.deployVerticle(new WebSocketServer());
        return vertx;
    }
}
