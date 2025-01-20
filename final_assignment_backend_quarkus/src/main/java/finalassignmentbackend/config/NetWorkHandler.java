package finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.route.EventBusAddress;
import io.netty.handler.codec.http.HttpResponseStatus;
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
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;
import org.apache.camel.ProducerTemplate;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Set;
import java.util.UUID;

@Slf4j
@ApplicationScoped
public class NetWorkHandler extends AbstractVerticle {

    @ConfigProperty(name = "network.server.port", defaultValue = "8081")
    int port;

    @ConfigProperty(name = "backend.url")
    String backendUrl;

    @ConfigProperty(name = "backend.port")
    int backendPort;

    @Inject
    Vertx vertx;

    @Inject
    TokenProvider tokenProvider;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    ProducerTemplate producerTemplate;

    private WebClient webClient;

    @PostConstruct
    public void init() {
        io.vertx.core.Vertx coreVertx = vertx.getDelegate();
        webClient = WebClient.create(coreVertx);
    }

    @Override
    public void start() {
        Router router = Router.router(vertx);

        configureCors(router);
        configureSockJS(router);
        configureHttpRouting(router);

        setupHttpServer(router);
    }

    private void configureCors(Router router) {
        Set<String> allowedHeaders = Set.of(
                "Authorization",
                "X-Requested-With",
                "Sec-WebSocket-Key",
                "Sec-WebSocket-Version",
                "Sec-WebSocket-Protocol",
                "Content-Type",
                "Accept"
        );

        router.route().handler(CorsHandler.create()
                .addOrigin("*")  // 根据需要设置允许的来源
                .allowedHeaders(allowedHeaders)
                .allowedMethod(HttpMethod.GET)
                .allowedMethod(HttpMethod.POST)
                .allowedMethod(HttpMethod.PUT)
                .allowedMethod(HttpMethod.OPTIONS));
    }

    private void configureSockJS(Router router) {
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(2000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress(EventBusAddress.CLIENT_TO_SERVER))
                .addOutboundPermitted(new PermittedOptions().setAddress(EventBusAddress.SERVER_TO_CLIENT));

        // 创建桥接路由器
        Router sockJSRouter = sockJSHandler.bridge(bridgeOptions);

        // 使用 Route.subRouter 方法将 SockJSHandler 作为子路由器挂载到 /eventbus 路径下
        router.route("/eventbus/*").subRouter(sockJSRouter);
    }

    private void configureHttpRouting(Router router) {
        // 将 HTTP 转发请求挂载到 /api/* 路径下
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        // 处理未匹配的路由
        router.route().handler(ctx -> ctx.response().setStatusCode(404).setStatusMessage("未找到资源").closed());
    }

    private void setupHttpServer(Router router) {
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        // 启动 WebSocket 服务
        vertx.createHttpServer(options)
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    // 只处理 /eventbus 路径上的 WebSocket 连接
                    if (ws.path().startsWith("/eventbus")) {
                        handleWebSocketConnection(ws);
                    } else {
                        ws.close().subscribe().with(
                                success -> log.info("关闭 WebSocket 成功 {}", success),
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
                    JsonNode jsonNode = objectMapper.readTree(message);

                    String token = jsonNode.has("token") ? jsonNode.get("token").asText() : null;

                    if (token != null && tokenProvider.validateToken(token)) {
                        String action = jsonNode.has("action") ? jsonNode.get("action").asText() : null;
                        JsonNode data = jsonNode.has("data") ? jsonNode.get("data") : null;

                        log.info("Received action: {}, with data: {}", action, data);

                        producerTemplate.sendBodyAndHeader(EventBusAddress.CLIENT_TO_SERVER, data, "RequestPath", ws.path());

                    } else {
                        log.warn("无效的令牌，关闭 WebSocket 连接");
                        ws.close((short) 1000, "Invalid token").subscribe().with(
                                success -> log.info("WebSocket 连接已关闭: Invalid token: {}", success),
                                failure -> log.error("关闭 WebSocket 连接失败: {}", failure.getMessage(), failure)
                        );
                    }
                } catch (JsonProcessingException e) {
                    log.error("无效的 JSON 消息，关闭 WebSocket 连接", e);
                    ws.close((short) 1000, "Invalid JSON format").subscribe().with(
                            success -> log.info("WebSocket 连接已关闭: Invalid JSON format: {}", success),
                            failure -> log.error("关闭 WebSocket 连接失败: {}", failure.getMessage(), failure)
                    );
                }
            } else {
                log.warn("不支持的 WebSocket 消息类型");
            }
        });

        ws.closeHandler(() -> log.info("WebSocket 连接已关闭"));
    }

    private void forwardHttpRequest(HttpServerRequest request) {
        String path = request.path();
        String targetUrl = backendUrl + ":" + backendPort + path;
        UUID requestId = UUID.randomUUID();
        log.info("[{}] Forwarding request from path: {} to targetUrl: {}", requestId, path, targetUrl);

        // 防止循环转发
        if (request.headers().contains("X-Forwarded-By")) {
            log.error("[{}] 检测到循环转发，终止请求处理", requestId);
            request.response()
                    .setStatusCode(500)
                    .setStatusMessage("循环转发")
                    .closed();
            return;
        }

        // 添加自定义头以标识请求已被转发
        request.headers().add("X-Forwarded-By", "NetWorkHandler");

        request.bodyHandler(body -> {
            log.info("[{}] body1: {}", requestId, body);
            if (body == null || body.length() == 0) {
                log.error("[{}] 请求体为空，无法发送 JSON 数据", requestId);
                request.response()
                        .setStatusCode(400)
                        .setStatusMessage("请求体为空")
                        .closed();
                return;
            }

            try {
                JsonObject jsonBody = body.toJsonObject();
                log.info("[{}] body2: {}", requestId, jsonBody);

                webClient.postAbs(targetUrl)
                        .putHeader("X-Forwarded-By", "NetWorkHandler")
                        .sendJsonObject(jsonBody)
                        .onSuccess(response -> {
                            log.info("[{}] response: {}", requestId, response);
                            log.info("[{}] 转发 HTTP 请求成功: {}", requestId, response.statusMessage());

                            // 设置响应状态码
                            request.response().setStatusCode(response.statusCode());

                            // 仅在 statusMessage 不为 null 时设置
                            String statusMessage = response.statusMessage();
                            if (statusMessage != null) {
                                request.response().setStatusMessage(statusMessage);
                            } else {
                                log.warn("[{}] 后端响应的 statusMessage 为 null，使用默认消息", requestId);
                                // 根据 statusCode 设置默认的 reasonPhrase
                                try {
                                    HttpResponseStatus defaultReason = HttpResponseStatus.valueOf(response.statusCode());
                                    request.response().setStatusMessage(defaultReason.reasonPhrase());
                                } catch (IllegalArgumentException e) {
                                    log.error("[{}] 无法获取 statusMessage 的默认值: {}", requestId, e.getMessage());
                                    // 可以选择设置一个通用的默认消息
                                    request.response().setStatusMessage("Unknown Status");
                                }
                            }

                            // 复制所有响应头，避免复制保留头（如 Transfer-Encoding）
                            response.headers().forEach(entry -> {
                                if (!entry.getKey().equalsIgnoreCase("Transfer-Encoding")) {
                                    request.response().putHeader(entry.getKey(), entry.getValue());
                                }
                            });

                            // **将后端响应体写回给前端**
                            String responseBody = response.bodyAsString();
                            log.info("[{}] 后端响应Body: {}", requestId, responseBody);

                            // 设置响应内容类型（如果后端是 JSON，可写 application/json）
                            request.response().putHeader("Content-Type", "application/json");

                            // **将后端响应体写回前端**
                            request.response().sendAndAwait(responseBody);

                        })
                        .onFailure(failure -> {
                            log.error("[{}] 转发 HTTP 请求失败", requestId, failure);
                            request.response()
                                    .setStatusCode(500)
                                    .setStatusMessage("转发失败")
                                    .closed();
                        });
            } catch (Exception e) {
                log.error("[{}] 请求体解析失败", requestId, e);
                request.response()
                        .setStatusCode(400)
                        .setStatusMessage("请求体解析失败")
                        .closed();
            }
        }).exceptionHandler(e -> {
            log.error("[{}] 处理请求体时发生异常", requestId, e);
            request.response()
                    .setStatusCode(500)
                    .setStatusMessage("服务器内部错误")
                    .closed();
        });
    }
}