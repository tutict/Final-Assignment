package com.tutict.finalassignmentbackend.config;

import com.tutict.finalassignmentbackend.config.login.JWT.TokenProvider;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.http.HttpServerRequest;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.CorsHandler;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandler;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.Set;

@Slf4j
@Component
public class WebSocketServer extends AbstractVerticle {

    private final Vertx vertx;
    private final TokenProvider tokenProvider;

    int port = 8082; // 保持 8082 为默认值，确保服务器在该端口上运行

    @Autowired
    public WebSocketServer(Vertx vertx, TokenProvider tokenProvider) {
        this.vertx = vertx;
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void start(Promise<Void> startPromise) {

        Router router = Router.router(vertx);

        // 配置CORS
        Set<String> allowedHeaders = new HashSet<>();
        allowedHeaders.add("Authorization");
        allowedHeaders.add("X-Requested-With");
        allowedHeaders.add("Sec-WebSocket-Key");
        allowedHeaders.add("Sec-WebSocket-Version");
        allowedHeaders.add("Sec-WebSocket-Protocol");

        Set<HttpMethod> allowedMethods = new HashSet<>();
        allowedMethods.add(HttpMethod.GET);
        allowedMethods.add(HttpMethod.POST);
        allowedMethods.add(HttpMethod.DELETE);
        allowedMethods.add(HttpMethod.PATCH);
        allowedMethods.add(HttpMethod.OPTIONS);
        allowedMethods.add(HttpMethod.PUT);

        router.route().handler(CorsHandler.create().addOrigin("http://localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        // 配置SockJS
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(2000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        // 设置桥接选项
        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        // 将 SockJS 处理程序挂载到 /eventbus/* 路径
        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            String useSockJS = request.getParam("useSockJS");
            if ("true".equals(useSockJS)) {
                // 使用 SockJS 处理连接
                sockJSHandler.bridge(bridgeOptions).handle(request);
            } else {
                // 尝试升级为 WebSocket
                if (request.headers().contains("Upgrade", "websocket", true)) {
                    // 让请求继续，以便 webSocketHandler 处理
                    ctx.next();
                } else {
                    request.response().setStatusCode(400).end("需要 WebSocket 连接");
                }
            }
        });

        // 创建HTTP服务器
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    String token = ws.headers().get("Authorization");
                    if (token != null && token.startsWith("Bearer ")) {
                        String jwtToken = token.substring(7);
                        if (tokenProvider.validateToken(jwtToken)) {
                            ws.handler(buffer -> {
                                try {
                                    vertx.eventBus().publish("chat.to.server", buffer);
                                } catch (Exception e) {
                                    log.error("处理WebSocket消息失败：{}", e.getMessage());
                                    ws.close();
                                }
                            });
                        } else {
                            log.warn("收到无效的令牌，拒绝WebSocket连接");
                            ws.close();
                        }
                    } else {
                        log.warn("Authorization头缺失或不以Bearer开头，拒绝WebSocket连接");
                        ws.close();
                    }
                })
                .listen(port, res -> {
                    if (res.succeeded()) {
                        log.info("WebSocket服务器已启动，运行在端口{}", res.result().actualPort());
                        startPromise.complete();
                    } else {
                        log.error("无法在端口{}启动WebSocket服务器", port, res.cause());
                        startPromise.fail(res.cause());
                    }
                });

        // 事件总线消费者
        vertx.eventBus().<Buffer>consumer("chat.to.server", message -> {
            log.info("收到长度为{}的二进制消息", message.body().length());
            vertx.eventBus().publish("chat.to.client", message.body());
        });
    }
}
