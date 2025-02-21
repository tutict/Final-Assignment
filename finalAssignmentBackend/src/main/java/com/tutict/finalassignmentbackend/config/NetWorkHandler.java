package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsActionRegistry;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Vertx;
import io.vertx.ext.web.client.WebClient;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.http.HttpServerRequest;
import io.vertx.core.http.ServerWebSocket;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.CorsHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.lang.reflect.Method;
import java.util.Set;
import java.util.UUID;

import static io.vertx.core.Vertx.vertx;

@Slf4j
@Component
public class NetWorkHandler extends AbstractVerticle {

    @Value("${network.server.port:8081}")
    int port;

    @Value("${backend.url}")
    String backendUrl;

    @Value("${backend.port}")
    int backendPort;

    Vertx vertx;

    TokenProvider tokenProvider;

    @Lazy
    WsActionRegistry wsActionRegistry;

    private final ObjectMapper objectMapper;
    private WebClient webClient;


    public NetWorkHandler(TokenProvider tokenProvider, ObjectMapper objectMapper) {
        this.tokenProvider = tokenProvider;
        this.objectMapper = objectMapper;
    }


    @PostConstruct
    public void init() {
        io.vertx.core.Vertx coreVertx = vertx();
        webClient = io.vertx.ext.web.client.WebClient.create(coreVertx);
    }

    @Override
    public void start() {
        Router router = Router.router(vertx);

        configureCors(router);
        setupNetWorksServer(router);
    }

    private void setupNetWorksServer(Router router) {

        // 将 HTTP 转发请求挂载到 /api/* 路径下
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();

            // 使用异步方式将请求升级为 WebSocket
            request.toWebSocket().onSuccess(ws -> {
                log.info("WebSocket 连接已建立, path={}", ws.path());

                if (ws.path().contains("/eventbus")) {
                    handleWebSocketConnection(ws);
                } else {
                    // 如果路径不匹配，关闭连接并返回错误码 1003
                    ws.close((short) 1003, "Unsupported path").onSuccess(success ->
                            log.info("关闭 {} WebSocket 连接成功 {}", ws.path(), success)
                    ).onFailure(failure ->
                            log.error("关闭 {} WebSocket 连接失败: {}", ws.path(), failure.getMessage(), failure)
                    );
                }
            }).onFailure(failure -> {
                log.error("WebSocket 升级失败: {}", failure.getMessage(), failure);
                ctx.response().setStatusCode(400).setStatusMessage("WebSocket upgrade failed").end();
            });
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
                .onSuccess(server -> log.info("Network服务器已在端口 {} 启动", server.actualPort()))
                .onFailure(failure -> log.error("Network服务器启动失败: {}", failure.getMessage(), failure));
    }

    private void configureCors(Router router) {
        Set<String> allowedHeaders = Set.of(
                "Authorization", "X-Requested-With", "Sec-WebSocket-Key",
                "Sec-WebSocket-Version", "Sec-WebSocket-Protocol", "Content-Type", "Accept"
        );

        router.route().handler(CorsHandler.create()
                .addOrigin("*")
                .allowedHeaders(allowedHeaders)
                .allowedMethod(io.vertx.core.http.HttpMethod.GET)
                .allowedMethod(io.vertx.core.http.HttpMethod.POST)
                .allowedMethod(io.vertx.core.http.HttpMethod.PUT)
                .allowedMethod(io.vertx.core.http.HttpMethod.OPTIONS));
    }

    private void handleWebSocketConnection(ServerWebSocket ws) {
        ws.frameHandler(frame -> {
            if (frame.isText()) {
                String message = frame.textData();
                try {
                    JsonNode root = objectMapper.readTree(message);
                    String token = root.path("token").asText(null);

                    if (token == null || !tokenProvider.validateToken(token)) {
                        log.warn("Invalid token, closing WS");
                        ws.close((short) 1000, "Invalid token").onSuccess(result -> log.info("WebSocket closed due to invalid token: {}", result))
                                .onFailure(failure -> log.error("Error closing WebSocket: {}", failure.getMessage(), failure));
                        return;
                    }

                    String service = root.path("service").asText(null);
                    String action = root.path("action").asText(null);
                    String idempotencyKey = root.path("idempotencyKey").asText(null);

                    JsonNode argsArray = root.path("args");
                    if (argsArray.isMissingNode() || !argsArray.isArray()) {
                        log.warn("Invalid or missing 'args' array");
                        ws.writeTextMessage("{\"error\":\"Missing or invalid 'args' array\"}")
                                .onSuccess(result -> log.info("WebSocket write success: {}", result))
                                .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
                        return;
                    }

                    log.info("Received service={}, action={}, idempotencyKey={}, args={}",
                            service, action, idempotencyKey, argsArray);

                    WsActionRegistry.HandlerMethod handler = wsActionRegistry.getHandler(service, action);
                    if (handler == null) {
                        ws.writeTextMessage("{\"error\":\"No such WsAction for " + service + "#" + action + "\"}")
                                .onSuccess(result -> log.info("WebSocket write success: {}", result))
                                .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
                        return;
                    }

                    Method method = handler.getMethod();
                    Class<?>[] paramTypes = method.getParameterTypes();
                    Object bean = handler.getBean();
                    int paramCount = paramTypes.length;

                    if (argsArray.size() != paramCount) {
                        ws.writeTextMessage("{\"error\":\"Param mismatch, method expects "
                                        + paramCount + " but got " + argsArray.size() + "\"}")
                                .onSuccess(result -> log.info("WebSocket write success: {}", result))
                                .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
                        return;
                    }

                    Object[] invokeArgs = new Object[paramCount];
                    for (int i = 0; i < paramCount; i++) {
                        Class<?> pt = paramTypes[i];
                        JsonNode argNode = argsArray.get(i);

                        invokeArgs[i] = convertJsonToParam(argNode, pt);
                    }

                    Object result = method.invoke(bean, invokeArgs);

                    if (method.getReturnType() != void.class && result != null) {
                        try {
                            String retJson = objectMapper.writeValueAsString(result);
                            ws.writeTextMessage("{\"result\":" + retJson + "}")
                                    .onSuccess(response -> log.info("WebSocket write success: {}", response))
                                    .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
                        } catch (JsonProcessingException e) {
                            log.error("Error serializing result to JSON", e);
                            ws.writeTextMessage("{\"error\":\"Internal server error\"}")
                                    .onSuccess(response -> log.info("Error response sent: {}", response))
                                    .onFailure(failure -> log.error("Failed to send error response: {}", failure.getMessage(), failure));
                        }
                    } else {
                        ws.writeTextMessage("{\"status\":\"OK\"}")
                                .onSuccess(response -> log.info("WebSocket write success: {}", response))
                                .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
                    }

                } catch (Exception e) {
                    log.error("JSON parsing or reflection error", e);
                    ws.close((short) 1000, "Invalid JSON or reflect error")
                            .onComplete(ar -> {
                                if (ar.succeeded()) {
                                    log.info("WebSocket closed due to invalid JSON");
                                } else {
                                    log.error("Error closing WebSocket: {}", ar.cause().getMessage(), ar.cause());
                                }
                            });
                }
            } else {
                log.warn("Unsupported WebSocket frame type");
            }
        });

        ws.closeHandler(v -> log.info("WebSocket connection closed, path={} {}", ws.path(), v));
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
            return objectMapper.treeToValue(node, targetType);
        }
    }

    private void forwardHttpRequest(HttpServerRequest request) {
        String path = request.path();
        String targetUrl = backendUrl + ":" + backendPort + path;
        UUID requestId = UUID.randomUUID();
        log.info("[{}] Forwarding request from path: {} to targetUrl: {}", requestId, path, targetUrl);

        if (request.headers().contains("X-Forwarded-By")) {
            log.error("[{}] Detected circular forwarding, aborting request", requestId);
            request.response()
                    .setStatusCode(500)
                    .setStatusMessage("Circular forwarding detected")
                    .closed();
            return;
        }

        request.headers().add("X-Forwarded-By", "NetWorkHandler");

        request.bodyHandler(body -> {
            log.info("[{}] body1: {}", requestId, body);
            if (body == null || body.length() == 0) {
                log.error("[{}] Request body is empty, unable to send JSON", requestId);
                request.response()
                        .setStatusCode(400)
                        .setStatusMessage("Empty request body")
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
                            log.info("[{}] Response: {}", requestId, response);
                            log.info("[{}] Forwarded HTTP request success: {}", requestId, response.statusMessage());
                            request.response().setStatusCode(response.statusCode());

                            String statusMessage = response.statusMessage();
                            if (statusMessage != null) {
                                request.response().setStatusMessage(statusMessage);
                            } else {
                                log.warn("[{}] Backend response statusMessage is null, using default message", requestId);
                                try {
                                    HttpResponseStatus defaultReason = HttpResponseStatus.valueOf(response.statusCode());
                                    request.response().setStatusMessage(defaultReason.reasonPhrase());
                                } catch (IllegalArgumentException e) {
                                    log.error("[{}] Could not get default statusMessage: {}", requestId, e.getMessage());
                                    request.response().setStatusMessage("Unknown Status");
                                }
                            }

                            response.headers().forEach(entry -> {
                                if (!entry.getKey().equalsIgnoreCase("Transfer-Encoding")) {
                                    request.response().putHeader(entry.getKey(), entry.getValue());
                                }
                            });

                            String responseBody = response.bodyAsString();
                            log.info("[{}] Backend response body: {}", requestId, responseBody);
                            request.response().putHeader("Content-Type", "application/json");
                            request.response().send(responseBody);

                        })
                        .onFailure(failure -> {
                            log.error("[{}] Forwarding HTTP request failed", requestId, failure);
                            request.response()
                                    .setStatusCode(500)
                                    .setStatusMessage("Forwarding failed")
                                    .closed();
                        });
            } catch (Exception e) {
                log.error("[{}] Request body parsing failed", requestId, e);
                request.response()
                        .setStatusCode(400)
                        .setStatusMessage("Request body parsing failed")
                        .closed();
            }
        }).exceptionHandler(e -> {
            log.error("[{}] Exception occurred while processing request body", requestId, e);
            request.response()
                    .setStatusCode(500)
                    .setStatusMessage("Internal Server Error")
                    .closed();
        });
    }
}
