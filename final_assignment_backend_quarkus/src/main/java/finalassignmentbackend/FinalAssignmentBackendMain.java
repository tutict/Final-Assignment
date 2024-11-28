package finalassignmentbackend;

import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.QuarkusApplication;
import io.quarkus.runtime.annotations.QuarkusMain;
import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;

import java.util.logging.Level;
import java.util.logging.Logger;

import static io.vertx.codegen.CodeGenProcessor.log;

// 使用Quarkus应用程序注解
@QuarkusMain
public class FinalAssignmentBackendMain implements QuarkusApplication {

    @Inject
    Vertx vertx; // 或者使用 @Named("customVertx") 来区分

    private static final Logger logger = Logger.getLogger(String.valueOf(FinalAssignmentBackendMain.class));

    @PostConstruct
    public void deployVerticles() {
        vertx.deployVerticle("com.tutict.finalassignmentbackend.config.vertx.WebSocketServer", res -> {
            if (res.succeeded()) {
                logger.info("WebSocket server deployed successfully.");
            } else {
                // 部署失败时打印错误信息
                log.log(Level.SEVERE, String.format("Failed to deploy WebSocket server: %s", res.cause().getMessage()));
            }
        });
    }

    @Override
    public int run(String... args) {
        logger.info("Quarkus application is running...");
        Quarkus.waitForExit();
        return 0;
    }

    public static void main(String[] args) {
        Quarkus.run(FinalAssignmentBackendMain.class, args);
    }
}
