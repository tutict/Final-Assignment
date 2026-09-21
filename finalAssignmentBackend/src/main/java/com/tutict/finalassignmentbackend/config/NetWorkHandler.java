package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsActionRegistry;
import com.tutict.finalassignmentbackend.config.websocket.WsTicketService;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.service.auth.TokenBlacklistService;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.MultiMap;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.*;
import io.vertx.core.http.PoolOptions;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.Router;
import io.vertx.core.http.HttpClient;
import io.vertx.core.http.HttpClientRequest;
import io.vertx.core.http.HttpClientResponse;
import io.vertx.core.http.RequestOptions;
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

    @Value("${network.server.port:8080}")
    int port;

    @Value("${backend.url}")
    String backendUrl;

    @Value("${backend.port}")
    int backendPort;

    private final TokenProvider tokenProvider;
    private final WsActionRegistry wsActionRegistry;
    private final WsTicketService wsTicketService;
    private final TokenBlacklistService tokenBlacklistService;

    private final ObjectMapper objectMapper;
    private final CorsProperties corsProperties;
    private final Map<String, Set<ServerWebSocket>> webSocketsByUsername = new ConcurrentHashMap<>();
    private HttpClient httpClient;

    public NetWorkHandler(TokenProvider tokenProvider,
                          @Lazy WsActionRegistry wsActionRegistry,
                          WsTicketService wsTicketService,
                          TokenBlacklistService tokenBlacklistService,
                          ObjectMapper objectMapper,
                          CorsProperties corsProperties) {
        this.tokenProvider = tokenProvider;
        this.wsActionRegistry = wsActionRegistry;
        this.wsTicketService = wsTicketService;
        this.tokenBlacklistService = tokenBlacklistService;
        this.objectMapper = objectMapper;
        this.corsProperties = corsProperties;
    }

    @PostConstruct
    public void init() {
        // WebClient is created in start() against the deployed Vert.x instance,
        // with an HTTP pool large enough to forward concurrent browser/k6 traffic.
    }

    @Override
    public void start() {
        HttpClientOptions clientOptions = new HttpClientOptions()
                .setKeepAlive(true)
                .setConnectTimeout(3_000)
                .setIdleTimeout(90);
        PoolOptions poolOptions = new PoolOptions()
                .setHttp1MaxSize(64)
                .setMaxWaitQueueSize(512);
        this.httpClient = vertx.createHttpClient(clientOptions, poolOptions);

        Router router = Router.router(vertx);
        configureCors(router);
        setupNetWorksServer(router);
    }

    private void setupNetWorksServer(Router router) {
        router.post("/api/ws-ticket").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            String token = extractBearerToken(request);
            if (token == null || tokenBlacklistService.isBlacklisted(token) || !tokenProvider.validateToken(token)) {
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
        router.get("/readyz").handler(ctx -> ctx.response()
                .putHeader("Content-Type", "text/plain; charset=UTF-8")
                .end("ok"));
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        // The network server is now the single external-facing port. Forward the
        // actuator/health probes to the (internal) REST server so health checks
        // against the external port keep working.
        router.route("/actuator/*").handler(ctx -> {
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
                .setTcpKeepAlive(true)
                .setIdleTimeout(0)
                .setCompressionSupported(false);

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
        if (token != null && !tokenBlacklistService.isBlacklisted(token) && tokenProvider.validateToken(token)) {
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
    /** Close all WebSocket connections for a user (called on logout). */
    public void closeUserConnections(String username) {
        if (username == null || username.isBlank()) {
            return;
        }
        Set<ServerWebSocket> sockets = webSocketsByUsername.remove(username);
        if (sockets == null) {
            return;
        }
        sockets.forEach(ws -> ws.close((short) 1000, "Logged out")
                .onFailure(failure -> log.error("Failed to close WebSocket for user={}: {}", username, failure.getMessage())));
        log.info("Closed {} WebSocket connection(s) for user={}", sockets.size(), username);
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
        log.debug("[{}] Forwarding request from path: {} to targetUrl: {}", requestId, path, targetUrl);

        if (request.headers().contains("X-Forwarded-By")) {
            log.error("[{}] Detected circular forwarding, aborting request", requestId);
            request.response().setStatusCode(500).setStatusMessage("Circular forwarding detected").end();
            return;
        }

        MultiMap headers = MultiMap.caseInsensitiveMultiMap();
        request.headers().forEach(entry -> {
            if (!"X-Forwarded-For".equalsIgnoreCase(entry.getKey())
                    && !"X-Real-IP".equalsIgnoreCase(entry.getKey())
                    && !"X-Forwarded-By".equalsIgnoreCase(entry.getKey())) {
                headers.add(entry.getKey(), entry.getValue());
            }
        });
        headers.add("X-Forwarded-By", "NetWorkHandler");
        headers.add("X-Forwarded-For", request.remoteAddress().host());

        HttpMethod method = request.method();
        boolean expectBody = method != HttpMethod.GET && method != HttpMethod.DELETE
                && method != HttpMethod.HEAD;
        if (expectBody) {
            request.pause();
        }
        RequestOptions options = new RequestOptions()
                .setMethod(method)
                .setAbsoluteURI(targetUrl)
                .setTimeout(120_000);

        httpClient.request(options).onSuccess(upstreamReq -> {
            headers.forEach(entry -> upstreamReq.putHeader(entry.getKey(), entry.getValue()));
            bindUpstreamResponse(request, upstreamReq, requestId);
            if (!expectBody) {
                upstreamReq.send().onFailure(failure -> failForward(request, requestId, failure));
                return;
            }
            request.bodyHandler(body -> {
                if (body == null || body.length() == 0) {
                    upstreamReq.send().onFailure(failure -> failForward(request, requestId, failure));
                } else {
                    upstreamReq.send(body).onFailure(failure -> failForward(request, requestId, failure));
                }
            });
            request.resume();
        }).onFailure(failure -> failForward(request, requestId, failure));
    }

    private void bindUpstreamResponse(HttpServerRequest inbound, HttpClientRequest upstreamReq, String requestId) {
        upstreamReq.response().onSuccess(upstream -> {
            HttpServerResponse outbound = inbound.response();
            outbound.setStatusCode(upstream.statusCode());
            String statusMessage = upstream.statusMessage();
            if (statusMessage != null) {
                outbound.setStatusMessage(statusMessage);
            }
            upstream.headers().forEach(entry -> {
                if (!isHopByHopHeader(entry.getKey())) {
                    outbound.putHeader(entry.getKey(), entry.getValue());
                }
            });
            if (upstream.getHeader("Content-Length") == null) {
                outbound.setChunked(true);
            }
            upstream.pipeTo(outbound).onFailure(failure -> failForward(inbound, requestId, failure));
        }).onFailure(failure -> failForward(inbound, requestId, failure));
    }

    private void failForward(HttpServerRequest request, String requestId, Throwable failure) {
        log.error("[{}] Forwarding failed: {}", requestId, failure.getMessage(), failure);
        HttpServerResponse response = request.response();
        if (response.ended()) {
            return;
        }
        if (!response.headWritten()) {
            response.setStatusCode(502).setStatusMessage("Forwarding failed").end();
            return;
        }
        response.end();
    }

    private Map<String, String> sanitizeHeaders(MultiMap headers) {
        return headers.entries().stream()
                .filter(entry -> !isSensitiveHeader(entry.getKey()))
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        Map.Entry::getValue,
                        (first, ignored) -> first));
    }

    private boolean isHopByHopHeader(String headerName) {
        if (headerName == null) {
            return false;
        }
        return headerName.equalsIgnoreCase("Transfer-Encoding")
                || headerName.equalsIgnoreCase("Connection")
                || headerName.equalsIgnoreCase("Keep-Alive")
                || headerName.equalsIgnoreCase("Proxy-Connection")
                || headerName.equalsIgnoreCase("TE")
                || headerName.equalsIgnoreCase("Trailer")
                || headerName.equalsIgnoreCase("Upgrade");
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
