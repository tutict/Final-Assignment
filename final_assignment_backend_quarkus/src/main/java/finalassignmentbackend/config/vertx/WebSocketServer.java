package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.netty.handler.codec.http.QueryStringDecoder;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.MultiMap;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import io.vertx.mutiny.core.Vertx;
import io.vertx.mutiny.core.http.HttpServerRequest;
import io.vertx.mutiny.core.http.ServerWebSocket;
import io.vertx.mutiny.ext.web.Router;
import io.vertx.mutiny.ext.web.handler.CorsHandler;
import io.vertx.mutiny.ext.web.handler.sockjs.SockJSHandler;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.HashSet;
import java.util.Set;

@Slf4j
@ApplicationScoped
public class WebSocketServer extends AbstractVerticle {

    private final Vertx vertx;
    private final TokenProvider tokenProvider;

    @ConfigProperty(name = "server.port", defaultValue = "8082")
    int port;

    @Inject
    public WebSocketServer(Vertx vertx, TokenProvider tokenProvider) {
        this.vertx = vertx;
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void start() {
        Router router = Router.router(vertx);

        // 配置 CORS
        Set<String> allowedHeaders = new HashSet<>();
        allowedHeaders.add("Authorization");
        allowedHeaders.add("X-Requested-With");
        allowedHeaders.add("Sec-WebSocket-Key");
        allowedHeaders.add("Sec-WebSocket-Version");
        allowedHeaders.add("Sec-WebSocket-Protocol");
        allowedHeaders.add("Content-Type");
        allowedHeaders.add("Accept");

        router.route().handler(CorsHandler.create()
                .addOrigin("*")  // 根据需要设置允许的来源
                .allowedHeaders(allowedHeaders)
                .allowedMethod(HttpMethod.GET)
                .allowedMethod(HttpMethod.POST)
                .allowedMethod(HttpMethod.OPTIONS));

        // 配置 SockJS 处理程序
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
                    request.response().setStatusCode(400).end("需要 WebSocket 连接")
                            .subscribe().with(
                                    success -> log.info("响应结束成功：{}", (success)),
                                    failure -> log.error("响应结束失败：{}", failure.getMessage(), failure)
                            );
                }
            }
        });

        // 配置 HTTP 服务器
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    // 只处理 /eventbus 路径上的 WebSocket 连接
                    if (ws.path().equals("/eventbus")) {
                        handleWebSocketConnection(ws);
                    } else {
                        ws.closeReason();
                    }
                })
                .listen(port)
                .subscribe().with(
                        server -> log.info("服务器已在端口 {} 启动", server.actualPort()),
                        failure -> log.error("服务器启动失败: {}", failure.getMessage(), failure)
                );
    }

    private void handleWebSocketConnection(ServerWebSocket ws) {
        // 获取查询字符串
        String query = ws.query();
        if (query != null) {
            // 使用 QueryStringDecoder 解析查询参数
            QueryStringDecoder decoder = new QueryStringDecoder("?" + query);
            MultiMap params = MultiMap.caseInsensitiveMultiMap();
            decoder.parameters().forEach((key, values) -> {
                if (values != null && !values.isEmpty()) {
                    params.add(key, values.getFirst());
                }
            });

            // 获取 token 参数
            String token = params.get("token");
            if (token != null && tokenProvider.validateToken(token)) {
                ws.frameHandler(frame -> {
                    if (frame.isText()) {
                        String message = frame.textData();
                        // 处理消息
                        vertx.eventBus().publish("chat.to.server", message);
                        log.info("收到来自 WebSocket 客户端的消息: {}", message);
                    }
                });
                // 添加关闭处理程序
                ws.closeHandler(() -> log.info("WebSocket 连接已关闭"));
            } else {
                log.warn("无效的令牌，关闭 WebSocket 连接");
                ws.closeReason();
            }
        } else {
            log.warn("缺少查询参数，关闭 WebSocket 连接");
            ws.closeReason();
        }
    }
}
