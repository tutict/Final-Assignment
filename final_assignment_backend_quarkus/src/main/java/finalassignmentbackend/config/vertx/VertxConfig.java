package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.NetWorkHandler;
import io.quarkus.runtime.ShutdownEvent;
import io.quarkus.runtime.StartupEvent;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Vertx;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class VertxConfig {

    private static final Logger log = Logger.getLogger(VertxConfig.class.getName());

    @Inject
    Vertx vertx;

    @Inject
    NetWorkHandler netWorkHandler;

    public void start(@Observes StartupEvent event) {
        log.info("Starting Vert.x NetWorkHandler...");
        DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
        vertx.deployVerticle(netWorkHandler, deploymentOptions, result -> {
            if (result.succeeded()) {
                log.log(Level.INFO, "NetWorkHandler deployed: {0}", result.result());
            } else {
                log.log(Level.SEVERE, "NetWorkHandler deployment failed", result.cause());
            }
        });
    }

    public void shutdown(@Observes ShutdownEvent event) {
        vertx.close(ar -> {
            if (ar.succeeded()) {
                log.info("Vert.x instance closed.");
            } else {
                log.log(Level.SEVERE, "Vert.x close failed", ar.cause());
            }
        });
    }
}