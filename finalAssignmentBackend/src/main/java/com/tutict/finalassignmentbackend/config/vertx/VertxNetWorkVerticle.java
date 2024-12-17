package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class VertxNetWorkVerticle extends AbstractVerticle {

    @Override
    public void start(Promise<Void> startPromise) {
        log.info("VertxNetWorkVerticle is starting...");
        // 添加 Vert.x 相关的初始化逻辑，例如启动 HTTP 服务器
        vertx.createHttpServer()
                .requestHandler(req -> req.response().end("Hello from Vert.x Verticle!"))
                .listen(9090, http -> {
                    if (http.succeeded()) {
                        log.info("Vert.x HTTP server started on port 9090");
                        startPromise.complete();
                    } else {
                        log.error("Failed to start Vert.x HTTP server", http.cause());
                        startPromise.fail(http.cause());
                    }
                });
    }

    @Override
    public void stop(Promise<Void> stopPromise) {
        log.info("VertxNetWorkVerticle is stopping...");
        // 添加 Vert.x 相关的资源清理逻辑
        stopPromise.complete();
    }
}
