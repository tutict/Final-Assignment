package com.tutict.finalassignmentbackend;

import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.DependsOn;

// 使用Spring Boot应用程序注解
@SpringBootApplication
//@DependsOn("shellScriptConfig")
// FinalAssignmentBackendApplication类负责部署Vert.x实例
public class FinalAssignmentBackendApplication {

    // 定义一个Vertx实例，作为部署Verticles的基础
    private final Vertx vertx;

    /**
     * FinalAssignmentBackendApplication的构造函数
     * @param vertx Vertx实例，用于部署和运行Verticle
     */
    public FinalAssignmentBackendApplication(Vertx vertx) {
        this.vertx = vertx;
    }

    /**
     * 在Spring应用程序上下文初始化后调用此方法以部署Verticles
     */
    @PostConstruct
    public void deployVerticles() {
        // 部署WebSocket服务器Verticle
        vertx.deployVerticle("com.tutict.finalassignmentbackend.config.vertx.WebSocketServer", res -> {
            if (res.succeeded()) {
                // 部署成功时打印消息
                System.out.println("WebSocket server deployed successfully.");
            } else {
                // 部署失败时打印错误信息
                System.err.println("Failed to deploy WebSocket server: " + res.cause().getMessage());
            }
        });
    }

    /**
     * 主函数，启动Spring Boot应用程序
     * @param args 命令行参数
     */
    public static void main(String[] args) {
        SpringApplication.run(FinalAssignmentBackendApplication.class, args);
    }

}
