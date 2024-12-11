package finalassignmentbackend;

import finalassignmentbackend.config.NetWorkHandler;
import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.QuarkusApplication;
import io.quarkus.runtime.annotations.QuarkusMain;
import io.vertx.mutiny.core.Vertx;
import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;

import java.util.logging.Logger;


// 使用Quarkus应用程序注解
@QuarkusMain
public class FinalAssignmentBackendMain implements QuarkusApplication {

    @Inject
    Vertx vertx; // 或者使用 @Named("customVertx") 来区分

    @Inject
    NetWorkHandler netWorkHandler;

    private static final Logger logger = Logger.getLogger(String.valueOf(FinalAssignmentBackendMain.class));

    @PostConstruct
    public void deployVerticles() {
        vertx.deployVerticle(netWorkHandler)
                .subscribe().with(
                        id -> logger.info("Network server deployed successfully."),
                        failure -> logger.severe("Failed to deploy network server: " + failure.getMessage())
                );
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
