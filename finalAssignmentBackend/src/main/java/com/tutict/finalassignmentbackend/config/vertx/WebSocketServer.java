package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.http.HttpServer;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.sockjs.SockJSHandler;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import org.springframework.stereotype.Component;

@Component
public class WebSocketServer extends AbstractVerticle {

    @Override
    public void start(Promise<Void> startPromise) {
        // 创建 Vert.x 事件总线
        Router router = Router.router(vertx);

        // 创建 SockJS 处理器
        SockJSHandlerOptions options = new SockJSHandlerOptions().setHeartbeatInterval(3000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, options);

        // 将 SockJS 处理器添加到路由器
        router.route("/eventbus/*").handler(sockJSHandler);

        // 创建 HTTP 服务器
        HttpServer server = vertx.createHttpServer();

        // 将路由器与 HTTP 服务器关联
        server.requestHandler(router).listen(8082, res -> {
            if (res.succeeded()) {
                System.out.println("WebSocket server is up and running on port 8082!");
                startPromise.complete();
            } else {
                System.err.println("Could not start WebSocket server on port 8082");
                startPromise.fail(res.cause());
            }
        });

        // 为 SockJS 配置事件总线
        vertx.eventBus().consumer("events", message -> {
            // 处理来自 WebSocket 客户端的消息
            System.out.println("Received message: " + message.body());
        });
    }
}
