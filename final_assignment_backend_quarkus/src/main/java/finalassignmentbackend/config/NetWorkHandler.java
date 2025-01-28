package finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsActionRegistry;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.client.WebClient;
import io.vertx.mutiny.core.Vertx;
import io.vertx.mutiny.core.http.HttpServerRequest;
import io.vertx.mutiny.core.http.ServerWebSocket;
import io.vertx.mutiny.ext.web.Router;
import io.vertx.mutiny.ext.web.handler.CorsHandler;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.lang.reflect.Method;
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
    WsActionRegistry wsActionRegistry;

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
        setupNetWorksServer(router);
    }

    /*
     * 配置跨域请求和路由
     */
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

    private void setupNetWorksServer(Router router) {

        // 将 HTTP 转发请求挂载到 /api/* 路径下
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            request.toWebSocket().subscribe().with(
                    ws -> {

                        log.info("WebSocket 连接已建立, path={}", ws.path());

                        if (ws.path().contains("/eventbus")) {
                            handleWebSocketConnection(ws);
                        } else {
                            ws.close((short) 1003, "Unsupported path").subscribe().with(
                                    success -> log.info("关闭 {} WebSocket 连接成功 {}", ws.path(), success),
                                    failure -> log.error("关闭 {} WebSocket 连接失败: {}", ws.path(), failure.getMessage(), failure)
                            );
                        }
                    },
                    failure -> {
                        log.error("WebSocket 升级失败: {}", failure.getMessage(), failure);
                        ctx.response().setStatusCode(400).setStatusMessage("WebSocket upgrade failed").closed();
                    }
            );
        });

        // 处理未匹配的路由（使用正则）
        router.routeWithRegex("^/(?!api(/|$)|eventbus(/|$)).*")
                .handler(ctx -> ctx.response().setStatusCode(404)
                        .setStatusMessage("未找到资源")
                        .closed());

        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        // 启动 Network 服务
        vertx.createHttpServer(options)
                .requestHandler(router)
                .listen(port)  // 确保这里使用了指定的端口
                .subscribe().with(
                        server -> log.info("Network服务器已在端口 {} 启动", server.actualPort()),
                        failure -> log.error("Network服务器启动失败: {}", failure.getMessage(), failure)
                );
    }

    private void handleWebSocketConnection(ServerWebSocket ws) {
        ws.frameHandler(frame -> {
            if (frame.isText()) {
                String message = frame.textData();
                try {
                    JsonNode root = objectMapper.readTree(message);

                    String token = root.path("token").asText(null);
                    if (token == null || !tokenProvider.validateToken(token)) {
                        log.warn("无效令牌, 关闭 WS");
                        ws.close((short) 1000, "Invalid token").subscribe().with(
                                success -> log.info("websocket closed due to invalid token: {}", success),
                                failure -> log.error("关闭websocket连接失败: {}", failure.getMessage(), failure)
                        );
                        return;
                    }

                    // 解析 service, action, idempotencyKey
                    String service = root.path("service").asText(null);
                    String action = root.path("action").asText(null);
                    String idempotencyKey = root.path("idempotencyKey").asText(null);

                    JsonNode argsArray = root.path("args");
                    if (argsArray.isMissingNode() || !argsArray.isArray()) {
                        // 如果你想继续兼容 data 作为单对象，也可做兼容判断
                        log.warn("Missing or invalid 'args' array");
                        ws.writeTextMessage("{\"error\":\"Missing or invalid 'args' array\"}")
                                .subscribe().with(
                                        success -> log.info("websocket write success: {}", success),
                                        failure -> log.error("websocket write fail: {}", failure.getMessage(), failure)
                                );
                        return;
                    }

                    log.info("Received service={}, action={}, idempotencyKey={}, args={}",
                            service, action, idempotencyKey, argsArray);

                    // 找 HandlerMethod
                    WsActionRegistry.HandlerMethod handler = wsActionRegistry.getHandler(service, action);
                    if (handler == null) {
                        ws.writeTextMessage("{\"error\":\"No such WsAction for " + service + "#" + action + "\"}")
                                .subscribe().with(
                                        success -> log.info("websocket write success: {}", success),
                                        failure -> log.error("websocket write fail: {}", failure.getMessage(), failure)
                                );
                        return;
                    }

                    // 反射
                    Method m = handler.getMethod();
                    Class<?>[] paramTypes = m.getParameterTypes();
                    Object bean = handler.getBean();
                    int paramCount = paramTypes.length;

                    if (argsArray.size() != paramCount) {
                        ws.writeTextMessage("{\"error\":\"Param mismatch, method expects "
                                        + paramCount + " but got " + argsArray.size() + "\"}")
                                .subscribe().with(
                                        success -> log.info("websocket write success: {}", success),
                                        failure -> log.error("websocket write fail: {}", failure.getMessage(), failure)
                                );
                        return;
                    }

                    // 准备 invoke 的参数数组
                    Object[] invokeArgs = new Object[paramCount];
                    for (int i = 0; i < paramCount; i++) {
                        Class<?> pt = paramTypes[i];
                        JsonNode argNode = argsArray.get(i);

                        invokeArgs[i] = convertJsonToParam(argNode, pt);
                    }

                    // 最终调用
                    Object result = m.invoke(bean, invokeArgs);

                    // 处理返回值
                    if (m.getReturnType() != void.class && result != null) {
                        String retJson = objectMapper.writeValueAsString(result);
                        ws.writeTextMessage("{\"result\":" + retJson + "}")
                                .subscribe().with(
                                        success -> log.info("websocket write: success: {}", success),
                                        failure -> log.error("websocket write fail: {}", failure.getMessage(), failure)
                                );
                    } else {
                        ws.writeTextMessage("{\"status\":\"OK\"}")
                                .subscribe().with(
                                        success -> log.info("websocket write: success: {}", success),
                                        failure -> log.error("websocket write fail: {}", failure.getMessage(), failure)
                                );
                    }

                } catch (Exception e) {
                    log.error("JSON解析/调用异常", e);
                    ws.close((short) 1000, "Invalid JSON or reflect error").subscribe().with(
                            success -> log.info("websocket closed: invalid JSON: {}", success),
                            failure -> log.error("close websocket failure: {}", failure.getMessage(), failure)
                    );
                }
            } else {
                log.warn("不支持的 WS消息类型");
            }
        });

        ws.closeHandler(() -> log.info("WebSocket 连接已关闭, path={}", ws.path()));
    }

    private Object convertJsonToParam(JsonNode node, Class<?> targetType) throws JsonProcessingException {
        if (targetType == String.class) {
            return node.asText();
        } else if (targetType == int.class || targetType == Integer.class) {
            return node.asInt();
        } else if (targetType == long.class || targetType == Long.class) {
            return node.asLong();
        } else if (targetType == boolean.class || targetType == Boolean.class) {
            return node.asBoolean();
        } else {
            // fallback: 直接映射为 Java对象 (实体等)
            return objectMapper.treeToValue(node, targetType);
        }
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

                            // 将后端响应体写回给前端
                            String responseBody = response.bodyAsString();
                            log.info("[{}] 后端响应Body: {}", requestId, responseBody);

                            // 设置响应内容类型（如果后端是 JSON，可写 application/json）
                            request.response().putHeader("Content-Type", "application/json");

                            // 将后端响应体写回前端
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