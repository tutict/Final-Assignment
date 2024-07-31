package finalassignmentbackend;

import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.annotations.QuarkusMain;
import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;

@QuarkusMain
public class FinalAssignmentBackendMain {

    private final Vertx vertx;

    public FinalAssignmentBackendMain(Vertx vertx) {
        this.vertx = vertx;
    }

    @PostConstruct
    public void deployVerticles() {
        vertx.deployVerticle("com.tutict.finalassignmentbackend.config.vertx.WebSocketServer", res -> {
            if (res.succeeded()) {
                System.out.println("WebSocket server deployed successfully.");
            } else {
                System.err.println("Failed to deploy WebSocket server: " + res.cause().getMessage());
            }
        });
    }

    public static void main(String... args) {
        Quarkus.run();
    }
}
