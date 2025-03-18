package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsActionRegistry;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.MultiMap;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.*;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.client.HttpResponse;
import io.vertx.ext.web.client.WebClient;
import io.vertx.ext.web.handler.CorsHandler;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

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
        this.webClient = WebClient.create(vertx);

        Router router = Router.router(vertx);
        configureCors(router);
        setupNetWorksServer(router);
    }

    private void setupNetWorksServer(Router router) {
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            request.toWebSocket().onSuccess(ws -> {
                log.info("WebSocket 连接已建立, path={}", ws.path());
                if (ws.path().contains("/eventbus")) {
                    handleWebSocketConnection(ws);
                } else {
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

        router.routeWithRegex("^/(?!api(/|$)|eventbus(/|$)).*")
                .handler(ctx -> ctx.response().setStatusCode(404)
                        .setStatusMessage("未找到资源")
                        .closed());

        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .listen(port)
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
        String requestId = UUID.randomUUID().toString();
        String path = request.path();
        String query = request.query();
        String targetUrl = backendUrl + ":" + backendPort + path + (query != null ? "?" + query : "");
        log.info("[{}] Forwarding request from path: {} to targetUrl: {}", requestId, path, targetUrl);

        if (request.headers().contains("X-Forwarded-By")) {
            log.error("[{}] Detected circular forwarding, aborting request", requestId);
            request.response().setStatusCode(500).setStatusMessage("Circular forwarding detected").end();
            return;
        }

        request.headers().add("X-Forwarded-By", "NetWorkHandler");

        MultiMap headers = MultiMap.caseInsensitiveMultiMap();
        request.headers().forEach(entry -> {
            headers.add(entry.getKey(), entry.getValue());
            log.info("[{}] Forwarded header: {} = {}", requestId, entry.getKey(), entry.getValue());
        });

        MultiMap queryParams = request.params();
        log.info("[{}] Query params: {}", requestId, queryParams);

        HttpMethod method = request.method();
        var httpRequest = webClient.requestAbs(method, targetUrl).putHeaders(headers);
//        queryParams.forEach(entry -> httpRequest.addQueryParam(entry.getKey(), entry.getValue()));

        if (method == HttpMethod.GET) {
            log.info("[{}] Forwarding GET request with query params: {}", requestId, queryParams);
            httpRequest.send()
                    .onSuccess(response -> handleResponse(request, response, requestId))
                    .onFailure(failure -> {
                        log.error("[{}] Forwarding GET request failed: {}", requestId, failure.getMessage(), failure);
                        request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                    });
        } else {
            request.bodyHandler(body -> {
                try {
                    String contentType = request.getHeader("Content-Type");
                    if (body.length() == 0 && method != HttpMethod.DELETE) {
                        log.info("[{}] No body provided, proceeding with empty request", requestId);
                        httpRequest.send()
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding HTTP request failed: {}", requestId, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else if (contentType != null && contentType.toLowerCase().contains("text/plain")) {
                        String rawBody = body.toString();
                        log.info("[{}] raw body: {}", requestId, rawBody);
                        httpRequest.putHeader("Content-Type", contentType);
                        httpRequest.sendBuffer(Buffer.buffer(rawBody))
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding HTTP request failed: {}", requestId, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                        JsonObject jsonBody = body.toJsonObject();
                        log.info("[{}] body2: {}", requestId, jsonBody);
                        httpRequest.putHeader("Content-Type", "application/json");
                        httpRequest.sendJsonObject(jsonBody)
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding HTTP request failed: {}", requestId, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else {
                        log.warn("[{}] Unrecognized Content-Type: {}, forwarding as raw buffer", requestId, contentType);
                        httpRequest.sendBuffer(body)
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding HTTP request failed: {}", requestId, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    }
                } catch (Exception e) {
                    log.error("[{}] Request body parsing failed: {}", requestId, e.getMessage(), e);
                    request.response().setStatusCode(400).setStatusMessage("Request body parsing failed").end();
                }
            });
        }
    }

    private void handleResponse(HttpServerRequest request, HttpResponse<io.vertx.core.buffer.Buffer> response, String requestId) {
        log.info("[{}] Response status code: {}", requestId, response.statusCode());
        log.info("[{}] Response headers: {}", requestId, response.headers());
        String responseBody = response.bodyAsString();
        log.info("[{}] Backend response body: {}", requestId, responseBody != null ? responseBody : "null");

        HttpServerResponse clientResponse = request.response();
        clientResponse.setStatusCode(response.statusCode());

        String statusMessage = response.statusMessage();
        if (statusMessage != null) {
            clientResponse.setStatusMessage(statusMessage);
        } else {
            log.warn("[{}] Backend response statusMessage is null", requestId);
            clientResponse.setStatusMessage(HttpResponseStatus.valueOf(response.statusCode()).reasonPhrase());
        }

        response.headers().forEach(entry -> {
            if (!entry.getKey().equalsIgnoreCase("Transfer-Encoding")) {
                clientResponse.putHeader(entry.getKey(), entry.getValue());
            }
        });

        if (responseBody != null && !responseBody.isEmpty()) {
            clientResponse.putHeader("Content-Type", "application/json");
            clientResponse.end(responseBody);
        } else {
            log.warn("[{}] Response body is null or empty, status: {}", requestId, response.statusCode());
            clientResponse.putHeader("Content-Type", "application/json");
            clientResponse.end();
        }
    }
}