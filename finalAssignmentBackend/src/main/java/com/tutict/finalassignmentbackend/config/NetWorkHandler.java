package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsActionRegistry;
import com.tutict.finalassignmentbackend.config.websocket.WsTicketService;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
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
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.stream.Collectors;

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

    private final TokenProvider tokenProvider;
    private final WsActionRegistry wsActionRegistry;
    private final WsTicketService wsTicketService;

    private final ObjectMapper objectMapper;
    private final CorsProperties corsProperties;
    private final Map<String, Set<ServerWebSocket>> webSocketsByUsername = new ConcurrentHashMap<>();
    private WebClient webClient;

    public NetWorkHandler(TokenProvider tokenProvider,
                          @Lazy WsActionRegistry wsActionRegistry,
                          WsTicketService wsTicketService,
                          ObjectMapper objectMapper,
                          CorsProperties corsProperties) {
        this.tokenProvider = tokenProvider;
        this.wsActionRegistry = wsActionRegistry;
        this.wsTicketService = wsTicketService;
        this.objectMapper = objectMapper;
        this.corsProperties = corsProperties;
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
        router.post("/api/ws-ticket").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            String token = extractBearerToken(request);
            if (token == null || !tokenProvider.validateToken(token)) {
                ctx.response().setStatusCode(401).setStatusMessage("Unauthorized").end();
                return;
            }
            WsTicketService.Ticket ticket = wsTicketService.issue(
                    tokenProvider.getUsernameFromToken(token),
                    tokenProvider.extractRoles(token)
            );
            writeJsonResponse(ctx.response(), ApiResponse.ok(Map.of(
                    "ticket", ticket.value(),
                    "expiresAt", ticket.expiresAt().toString()
            )));
        });
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            HandshakePrincipal principal = authenticateWebSocketHandshake(request);
            if (principal == null) {
                log.warn("Rejected unauthenticated WebSocket handshake, path={}", request.path());
                ctx.response().setStatusCode(401).setStatusMessage("Unauthorized").end();
                return;
            }

            String username = principal.username();
            List<String> roles = principal.roles();
            request.toWebSocket().onSuccess(ws -> {
                log.info("WebSocket 连接已建立, path={}", ws.path());
                if (ws.path().contains("/eventbus")) {
                    handleWebSocketConnection(ws, username, roles);
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

        List<String> allowedOrigins = corsProperties.getAllowedOrigins();
        router.route().handler(CorsHandler.create()
                .addOrigins(allowedOrigins)
                .allowedHeaders(allowedHeaders)
                .allowedMethod(io.vertx.core.http.HttpMethod.GET)
                .allowedMethod(io.vertx.core.http.HttpMethod.POST)
                .allowedMethod(io.vertx.core.http.HttpMethod.PUT)
                .allowedMethod(io.vertx.core.http.HttpMethod.DELETE)
                .allowedMethod(io.vertx.core.http.HttpMethod.OPTIONS)
                .allowCredentials(true));
    }

    private HandshakePrincipal authenticateWebSocketHandshake(HttpServerRequest request) {
        String token = extractBearerToken(request);
        if (token != null && tokenProvider.validateToken(token)) {
            return new HandshakePrincipal(
                    tokenProvider.getUsernameFromToken(token),
                    tokenProvider.extractRoles(token)
            );
        }

        WsTicketService.Ticket ticket = wsTicketService.consume(request.params().get("ws_ticket"));
        if (ticket != null) {
            return new HandshakePrincipal(ticket.username(), ticket.roles());
        }

        return null;
    }

    private String extractBearerToken(HttpServerRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.startsWith("Bearer ")) {
            return authorization.substring(7);
        }
        return null;
    }
    private void handleWebSocketConnection(ServerWebSocket ws, String username, List<String> roles) {
        registerWebSocket(username, ws);
        ws.frameHandler(frame -> {
            if (frame.isText()) {
                String message = frame.textData();
                String requestId = null;
                try {
                    JsonNode root = objectMapper.readTree(message);

                    requestId = root.path("requestId").asText(null);
                    String service = root.path("service").asText(null);
                    String action = root.path("action").asText(null);
                    String idempotencyKey = root.path("idempotencyKey").asText(null);

                    JsonNode argsArray = root.path("args");
                    if (argsArray.isMissingNode() || !argsArray.isArray()) {
                        log.warn("Invalid or missing 'args' array");
                        writeWsError(ws, requestId, "Missing or invalid 'args' array");
                        return;
                    }

                    log.info("Received service={}, action={}, idempotencyKey={}, argsCount={}, user={}",
                            service, action, idempotencyKey, argsArray.size(), username);

                    WsActionRegistry.HandlerMethod handler = wsActionRegistry.getHandler(service, action);
                    if (handler == null) {
                        writeWsError(ws, requestId, "No such WsAction for " + service + "#" + action);
                        return;
                    }

                    if (!isActionAllowed(handler, roles)) {
                        log.warn("Rejected unauthorized WsAction service={}, action={}, user={}, roles={}",
                                service, action, username, roles);
                        writeWsError(ws, requestId, "Forbidden");
                        return;
                    }

                    Method method = handler.getMethod();
                    Class<?>[] paramTypes = method.getParameterTypes();
                    Object bean = handler.getBean();
                    int paramCount = paramTypes.length;

                    if (argsArray.size() != paramCount) {
                        writeWsError(ws, requestId, "Param mismatch, method expects "
                                + paramCount + " but got " + argsArray.size());
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
                        writeWsResult(ws, requestId, result);
                    } else {
                        writeWsStatus(ws, requestId, "OK");
                    }

                } catch (Exception e) {
                    log.error("JSON parsing or reflection error", e);
                    writeWsError(ws, requestId, "Invalid JSON or reflect error");
                }
            } else {
                log.warn("Unsupported WebSocket frame type");
            }
        });

        ws.closeHandler(v -> {
            unregisterWebSocket(username, ws);
            log.info("WebSocket connection closed, path={} {}", ws.path(), v);
        });
    }

    private boolean isActionAllowed(WsActionRegistry.HandlerMethod handler, List<String> roles) {
        if (handler.getWsAction().allowAuthenticated()) {
            return true;
        }

        String[] requiredRoles = handler.getWsAction().roles();
        if (requiredRoles.length == 0) {
            return false;
        }

        Set<String> grantedRoles = roles == null
                ? Set.of()
                : roles.stream()
                .map(this::normalizeRole)
                .filter(role -> !role.isBlank())
                .collect(Collectors.toSet());

        return Arrays.stream(requiredRoles)
                .map(this::normalizeRole)
                .anyMatch(grantedRoles::contains);
    }

    private String normalizeRole(String role) {
        if (role == null) {
            return "";
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        return normalized.startsWith("ROLE_") ? normalized.substring("ROLE_".length()) : normalized;
    }
    public void pushToUser(String username, Map<String, Object> payload) {
        if (username == null || username.isBlank()) {
            broadcastBusinessEvent(payload);
            return;
        }
        Set<ServerWebSocket> sockets = webSocketsByUsername.get(username);
        if (sockets == null || sockets.isEmpty()) {
            log.info("No active WebSocket session for user={}", username);
            return;
        }
        sockets.forEach(ws -> writeWsResponse(ws, payload));
    }

    public void broadcastBusinessEvent(Map<String, Object> payload) {
        webSocketsByUsername.values().stream()
                .flatMap(Set::stream)
                .forEach(ws -> writeWsResponse(ws, payload));
    }

    private void registerWebSocket(String username, ServerWebSocket ws) {
        if (username == null || username.isBlank()) {
            return;
        }
        webSocketsByUsername
                .computeIfAbsent(username, ignored -> new CopyOnWriteArraySet<>())
                .add(ws);
        log.info("Registered WebSocket session for user={}, activeSessions={}",
                username,
                webSocketsByUsername.get(username).size());
    }

    private void unregisterWebSocket(String username, ServerWebSocket ws) {
        if (username == null || username.isBlank()) {
            return;
        }
        Set<ServerWebSocket> sockets = webSocketsByUsername.get(username);
        if (sockets == null) {
            return;
        }
        sockets.remove(ws);
        if (sockets.isEmpty()) {
            webSocketsByUsername.remove(username);
        }
    }

    private void writeJsonResponse(HttpServerResponse response, Object body) {
        try {
            response.putHeader("Content-Type", "application/json");
            response.end(objectMapper.writeValueAsString(body));
        } catch (JsonProcessingException e) {
            log.error("Error serializing HTTP response", e);
            response.setStatusCode(500).setStatusMessage("Internal server error").end();
        }
    }

    private record HandshakePrincipal(String username, List<String> roles) {
    }
    private void writeWsResult(ServerWebSocket ws, String requestId, Object result) {
        Map<String, Object> response = baseWsResponse(requestId);
        response.put("result", result);
        writeWsResponse(ws, response);
    }

    private void writeWsStatus(ServerWebSocket ws, String requestId, String status) {
        Map<String, Object> response = baseWsResponse(requestId);
        response.put("status", status);
        writeWsResponse(ws, response);
    }

    private void writeWsError(ServerWebSocket ws, String requestId, String error) {
        Map<String, Object> response = baseWsResponse(requestId);
        response.put("error", error);
        writeWsResponse(ws, response);
    }

    private Map<String, Object> baseWsResponse(String requestId) {
        Map<String, Object> response = new LinkedHashMap<>();
        if (requestId != null && !requestId.isBlank()) {
            response.put("requestId", requestId);
        }
        return response;
    }

    private void writeWsResponse(ServerWebSocket ws, Map<String, Object> response) {
        try {
            ws.writeTextMessage(objectMapper.writeValueAsString(response))
                    .onSuccess(result -> log.info("WebSocket write success: {}", result))
                    .onFailure(failure -> log.error("WebSocket write failure: {}", failure.getMessage(), failure));
        } catch (JsonProcessingException e) {
            log.error("Error serializing WebSocket response", e);
            ws.writeTextMessage("{\"error\":\"Internal server error\"}")
                    .onSuccess(result -> log.info("Error response sent: {}", result))
                    .onFailure(failure -> log.error("Failed to send error response: {}", failure.getMessage(), failure));
        }
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
        });
        log.debug("[{}] Forward headers: {}", requestId, sanitizeHeaders(headers));

        MultiMap queryParams = request.params();
        log.debug("[{}] Query params: {}", requestId, sanitizeParameters(queryParams));

        HttpMethod method = request.method();
        var httpRequest = webClient.requestAbs(method, targetUrl).putHeaders(headers);

        if (method == HttpMethod.GET || method == HttpMethod.DELETE) {
            log.info("[{}] Forwarding {} request with query param names: {}", requestId, method, queryParams.names());
            httpRequest.send()
                    .onSuccess(response -> handleResponse(request, response, requestId))
                    .onFailure(failure -> {
                        log.error("[{}] Forwarding {} request failed: {}", requestId, method, failure.getMessage(), failure);
                        request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                    });
        } else {
            request.bodyHandler(body -> {
                try {
                    String contentType = request.getHeader("Content-Type");
                    if (body.length() == 0) {
                        log.info("[{}] No body provided for {} request, proceeding with empty request", requestId, method);
                        httpRequest.send()
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding {} request failed: {}", requestId, method, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else if (contentType != null && contentType.toLowerCase().contains("text/plain")) {
                        String rawBody = body.toString();
                        log.debug("[{}] Request body length for {}: {} bytes", requestId, method, body.length());
                        httpRequest.putHeader("Content-Type", contentType);
                        httpRequest.sendBuffer(Buffer.buffer(rawBody))
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding {} request failed: {}", requestId, method, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                        JsonObject jsonBody = body.toJsonObject();
                        log.debug("[{}] Request body length for {}: {} bytes", requestId, method, body.length());
                        httpRequest.putHeader("Content-Type", "application/json");
                        httpRequest.sendJsonObject(jsonBody)
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding {} request failed: {}", requestId, method, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    } else {
                        log.warn("[{}] Unrecognized Content-Type: {} for {}, forwarding as raw buffer", requestId, contentType, method);
                        httpRequest.sendBuffer(body)
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> {
                                    log.error("[{}] Forwarding {} request failed: {}", requestId, method, failure.getMessage(), failure);
                                    request.response().setStatusCode(500).setStatusMessage("Forwarding failed").end();
                                });
                    }
                } catch (Exception e) {
                    log.error("[{}] Request body parsing failed for {}: {}", requestId, method, e.getMessage(), e);
                    request.response().setStatusCode(400).setStatusMessage("Request body parsing failed").end();
                }
            });
        }
    }

    private void handleResponse(HttpServerRequest request, HttpResponse<io.vertx.core.buffer.Buffer> response, String requestId) {
        log.info("[{}] Response status code: {}", requestId, response.statusCode());
        log.debug("[{}] Response headers: {}", requestId, sanitizeHeaders(response.headers()));
        String responseBody = response.bodyAsString();
        log.debug("[{}] Backend response body length: {} bytes",
                requestId,
                responseBody != null ? responseBody.length() : 0);

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

    private Map<String, String> sanitizeHeaders(MultiMap headers) {
        return headers.entries().stream()
                .filter(entry -> !isSensitiveHeader(entry.getKey()))
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        Map.Entry::getValue,
                        (first, ignored) -> first));
    }

    private boolean isSensitiveHeader(String headerName) {
        return headerName != null
                && ("Authorization".equalsIgnoreCase(headerName)
                || "Cookie".equalsIgnoreCase(headerName)
                || "Set-Cookie".equalsIgnoreCase(headerName));
    }

    private Map<String, String> sanitizeParameters(MultiMap params) {
        return params.entries().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        entry -> isSensitiveParameter(entry.getKey()) ? "[REDACTED]" : entry.getValue(),
                        (first, ignored) -> first));
    }

    private boolean isSensitiveParameter(String parameterName) {
        if (parameterName == null) {
            return false;
        }
        String lowerName = parameterName.toLowerCase();
        return lowerName.contains("token")
                || lowerName.contains("password")
                || lowerName.contains("authorization")
                || lowerName.contains("idcard")
                || lowerName.contains("phone");
    }
}
