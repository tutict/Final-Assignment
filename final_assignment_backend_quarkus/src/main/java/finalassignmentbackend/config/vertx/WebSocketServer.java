package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.netty.handler.codec.http.QueryStringDecoder;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.MultiMap;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.client.WebClient;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import io.vertx.mutiny.core.Vertx;
import io.vertx.mutiny.core.http.HttpServerRequest;
import io.vertx.mutiny.core.http.ServerWebSocket;
import io.vertx.mutiny.ext.web.Router;
import io.vertx.mutiny.ext.web.RoutingContext;
import io.vertx.mutiny.ext.web.handler.CorsHandler;
import io.vertx.mutiny.ext.web.handler.sockjs.SockJSHandler;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;

import java.util.HashSet;
import java.util.Set;

@Slf4j
@ApplicationScoped
public class WebSocketServer extends AbstractVerticle {

    private final Vertx vertx;
    private final TokenProvider tokenProvider;

    int port = 8082; // 保持 8082 为默认值，确保服务器在该端口上运行

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

        router.route().handler(ctx -> {
            HttpServerRequest request = ctx.request();
            String path = request.path();

            // 如果路径以 /eventbus 开头
            if (path.startsWith("/eventbus")) {
                String useSockJS = request.getParam("useSockJS");

                if ("true".equals(useSockJS)) {
                    // 使用 SockJS 处理连接
                    sockJSHandler.bridge(bridgeOptions).handle(request);
                } else {
                    // 尝试升级为 WebSocket
                    if (request.headers().contains("Upgrade", "websocket", true)) {
                        // 处理 WebSocket 连接
                        // WebSocket 连接成功后
                        ctx.request().toWebSocket()
                                .subscribe()
                                .with(this::handleWebSocketConnection, t -> {
                                    // 处理连接失败的情况
                                    log.error("WebSocket 连接失败", t);
                                    ctx.response().setStatusCode(500);
                                });
                    } else {
                        // 转发 POST 请求
                        forwardPostRequest(ctx);
                    }
                }
            } else {
                ctx.next(); // 如果路径不匹配，继续执行下一个处理器
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
                    if (ws.path().startsWith("/eventbus")) {
                        handleWebSocketConnection(ws);
                    } else {
                        ws.close().subscribe().with(
                                success -> log.info("1:关闭 WebSocket 成功 {}", success),
                                failure -> log.error("关闭 WebSocket 失败: {}", failure.getMessage(), failure)
                        );
                    }
                })
                .listen(port)  // 确保这里使用了指定的端口
                .subscribe().with(
                        server -> log.info("WebSocket 服务器已在端口 {} 启动", server.actualPort()),
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
                ws.close().subscribe().with(
                        success -> log.info("2:关闭 WebSocket 成功 {}", success),
                        failure -> log.error("关闭 WebSocket 失败: {}", failure.getMessage(), failure)
                );
            }
        } else {
            log.warn("缺少查询参数，关闭 WebSocket 连接");
            ws.close().subscribe().with(
                    success -> log.info("3:关闭 WebSocket 成功 {}", success),
                    failure -> log.error("关闭 WebSocket 失败: {}", failure.getMessage(), failure)
            );
        }
    }

    private void forwardPostRequest(@Deprecated RoutingContext ctx) {

        WebClient webClient = WebClient.create((io.vertx.core.Vertx) vertx);  // 通过 Vertx 创建 WebClient
        String path = ctx.request().path();
        String targetUrl = "http:/" + path;  // 目标服务的基础 URL

        // 使用 WebClient 转发请求
        webClient.postAbs(targetUrl)
                .sendJson(ctx.getBodyAsJson())  // 将请求体转发
                .onSuccess(response -> {
                    // 转发成功后，将响应传回客户端
                    ctx.response().setStatusCode(response.statusCode())
                            .headers().setAll(io.vertx.mutiny.core.MultiMap.newInstance(response.headers()));
                }).onFailure(failure -> {
                    // 转发请求失败，返回错误信息
                    log.error("转发 POST 请求失败", failure);
                    ctx.response().setStatusCode(500);
                });
    }
}