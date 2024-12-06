package finalassignmentbackend.config.vertx;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.client.WebClient;
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
                .addInboundPermitted(new PermittedOptions().setAddress("client.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("server.to.client"));

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
                        // 转发http请求
                        forwardHttpRequest(request);
                    }
                }
            } else {
                ctx.failed();
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
        ws.frameHandler(frame -> {
            if (frame.isText()) {
                String message = frame.textData();
                try {
                    // 使用 Jackson 或 Gson 解析 JSON
                    ObjectMapper objectMapper = new ObjectMapper();
                    JsonNode jsonNode = objectMapper.readTree(message);

                    // 提取 token
                    String token = jsonNode.has("token") ? jsonNode.get("token").asText() : null;

                    // 验证 token
                    if (token != null && tokenProvider.validateToken(token)) {
                        // 处理消息
                        String action = jsonNode.has("action") ? jsonNode.get("action").asText() : null;
                        JsonNode data = jsonNode.has("data") ? jsonNode.get("data") : null;

                        // 根据 action 或 data 做一些操作
                        log.info("Received action: {}, with data: {}", action, data);

                        // 将消息发布到事件总线
                        vertx.eventBus().publish("client.to.server", message);

                    } else {
                        // 如果 token 无效，关闭连接
                        log.warn("无效的令牌，关闭 WebSocket 连接");
                        ws.closeAndForget((short) 1000, "Invalid token");
                    }
                } catch (JsonProcessingException e) {
                    // 如果解析 JSON 失败，关闭连接
                    log.error("无效的 JSON 消息，关闭 WebSocket 连接", e);
                    ws.closeAndForget((short) 1000, "Invalid JSON format");
                }
            } else {
                // 如果不是文本消息，忽略
                log.warn("不支持的 WebSocket 消息类型");
            }
        });

        // 添加关闭处理程序
        ws.closeHandler(() -> log.info("WebSocket 连接已关闭"));
    }

    private void forwardHttpRequest(HttpServerRequest ctx) {
        // 获取 Vert.x 实例
        io.vertx.core.Vertx coreVertx = this.vertx.getDelegate(); // 使用正确的 Vertx 类型

        WebClient webClient = WebClient.create(coreVertx);  // 通过 coreVertx 创建 WebClient
        String path = ctx.path();

        System.out.println("path:"+path);

        String targetUrl = "http://localhost:8081" + path;  // 目标服务的基础 URL，请确保这是你需要转发的完整服务地址

        // 确保在读取请求体之前设置了 bodyHandler
        ctx.bodyHandler(body -> {
            // 检查请求体是否为空
            if (body == null || body.length() == 0) {
                log.error("请求体为空，无法发送 JSON 数据");
                ctx.response().setStatusCode(400);
                return;
            }

            try {
                // 转换请求体为 JsonObject
                JsonObject jsonBody = body.toJsonObject();

                // 使用 WebClient 转发请求
                webClient.postAbs(targetUrl)
                        .sendJson(jsonBody)
                        .onSuccess(response -> {
                            log.info("转发 http 请求成功: {}", response.statusMessage());
                            log.info("发送的 JSON 数据: {}", jsonBody.encodePrettily());
                            ctx.response().setStatusCode(response.statusCode());
                            response.headers().forEach(header -> ctx.response().putHeader(header.getKey(), header.getValue()));
                            ctx.response().end(response.bodyAsString())
                                    .subscribe().with(
                                            success -> log.info("响应成功发送1: {}", success),
                                            failure -> log.error("响应发送失败", failure)
                                    );
                        })
                        .onFailure(failure -> {
                            log.error("转发 http 请求失败", failure);
                            ctx.response().setStatusCode(500)
                                    .end("转发失败")
                                    .subscribe().with(
                                            success -> log.info("响应成功发送2: {}", success),
                                            error -> log.error("错误响应发送失败", error)
                                    );
                        });
            } catch (Exception e) {
                log.error("请求体解析失败", e);
                ctx.response().setStatusCode(400);
            }
        });
    }
}