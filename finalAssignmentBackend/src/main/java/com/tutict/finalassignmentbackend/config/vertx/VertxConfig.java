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
        // 创建Vertx实例，设置工作线程池大小为10
        Vertx vertx = Vertx.vertx(new VertxOptions().setWorkerPoolSize(10));
        // 部署WebSocket服务器Verticle
        vertx.deployVerticle(new WebSocketServer());
        return vertx;
    }
}
