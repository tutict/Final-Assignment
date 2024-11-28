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

    // 定义一个Vertx实例，作为部署Verticles的基础
    private final Vertx vertx;
    private static final Logger logger = Logger.getLogger(String.valueOf(FinalAssignmentBackendMain.class));

    /**
     * FinalAssignmentBackendApplication的构造函数
     *
     * @param vertx Vertx实例，用于部署和运行Verticle
     */
    @Inject
    public FinalAssignmentBackendMain(Vertx vertx) {
        this.vertx = vertx;
    }

    /**
     * 在应用程序上下文初始化后调用此方法以部署Verticles
     */
    @PostConstruct
    public void deployVerticles() {
        // 部署WebSocket服务器Verticle
        vertx.deployVerticle("com.tutict.finalassignmentbackend.config.vertx.WebSocketServer", res -> {
            if (res.succeeded()) {
                // 部署成功时打印消息
                logger.info("WebSocket server deployed successfully.");
            } else {
                // 部署失败时打印错误信息
                log.log(Level.SEVERE, String.format("Failed to deploy WebSocket server: %s", res.cause().getMessage()));
            }
        });
    }

    /**
     * 实现run方法以启动Quarkus应用程序
     *
     * @param args 命令行参数
     * @return 返回状态码
     */
    @Override
    public int run(String... args) {
        logger.info("Quarkus application is running...");
        Quarkus.waitForExit();
        return 0;
    }

    /**
     * 主函数，启动Quarkus应用程序
     *
     * @param args 命令行参数
     */
    public static void main(String[] args) {
        Quarkus.run(FinalAssignmentBackendMain.class, args);
    }
}
