package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 配置Vert.x框架的相关设置
 */
@Configuration
public class VertxConfig {

    /**
     * 创建并配置Vert.x实例
     *
     * @return 配置好的Vertx实例
     */
    @Bean
    public Vertx vertx() {
        // 创建Vertx实例，设置工作线程池大小为10，并启用阻塞线程检查
        VertxOptions vertxOptions = new VertxOptions()
                .setWorkerPoolSize(10)
                .setBlockedThreadCheckInterval(2000); // 设置阻塞线程检查间隔，默认单位为毫秒

        Vertx vertx = Vertx.vertx(vertxOptions);

        // 部署WebSocket服务器Verticle，增加回调函数以处理部署成功和失败
        vertx.deployVerticle(new WebSocketServer(), res -> {
            if (res.succeeded()) {
                System.out.println("WebSocketServer deployed successfully: " + res.result());
            } else {
                System.err.println("Failed to deploy WebSocketServer: " + res.cause());
            }
        });
        return vertx;
    }
}
