package finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsActionRegistry;
import finalassignmentbackend.config.websocket.WsTicketService;
import finalassignmentbackend.service.TokenBlacklistService;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.vertx.core.MultiMap;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.mutiny.core.http.HttpServerRequest;
import io.vertx.mutiny.core.http.ServerWebSocket;
import io.vertx.mutiny.ext.web.Router;
import io.vertx.ext.web.client.HttpResponse;
import io.vertx.ext.web.client.WebClient;
import io.vertx.mutiny.ext.web.handler.CorsHandler;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@ApplicationScoped
public class NetWorkHandler extends AbstractVerticle {

    private static final Logger log = Logger.getLogger(NetWorkHandler.class.getName());

    @ConfigProperty(name = "network.server.port", defaultValue = "8081")
    int port;

    @ConfigProperty(name = "backend.url")
    String backendUrl;

    @ConfigProperty(name = "backend.port")
    int backendPort;

    @Inject
    TokenProvider tokenProvider;

    @Inject
    WsActionRegistry wsActionRegistry;

    @Inject
    WsTicketService wsTicketService;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    TokenBlacklistService tokenBlacklistService;

    private final Map<String, Set<ServerWebSocket>> webSocketsByUsername = new ConcurrentHashMap<>();
    private WebClient webClient;


    @Override
    public void start() {
        this.webClient = WebClient.create(vertx.getDelegate());
        Router router = Router.router(vertx);
        configureCors(router);
        setupNetWorksServer(router);
    }

    private void configureCors(Router router) {
        Set<String> allowedHeaders = Set.of(
                "Authorization", "X-Requested-With", "Sec-WebSocket-Key",
                "Sec-WebSocket-Version", "Sec-WebSocket-Protocol", "Content-Type", "Accept"
        );

        router.route().handler(CorsHandler.create()
                .addOrigin("*")
                .allowedHeaders(allowedHeaders)
                .allowedMethod(HttpMethod.GET)
                .allowedMethod(HttpMethod.POST)
                .allowedMethod(HttpMethod.PUT)
                .allowedMethod(HttpMethod.DELETE)
                .allowedMethod(HttpMethod.OPTIONS)
                .allowCredentials(true));
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
            writeJson(ctx.response(), Map.of(
                    "ticket", ticket.value(),
                    "expiresAt", ticket.expiresAt().toString()
            ));
        });

        router.route("/api/*").handler(ctx -> forwardHttpRequest(ctx.request()));

        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            HandshakePrincipal principal = authenticateWebSocketHandshake(request);
            if (principal == null) {
                log.log(Level.WARNING, "Rejected unauthenticated WebSocket handshake, path={0}", request.path());
                ctx.response().setStatusCode(401).setStatusMessage("Unauthorized").end();
                return;
            }

            request.toWebSocket().subscribe().with(ws -> {
                if (ws.path().contains("/eventbus")) {
                    handleWebSocketConnection(ws, principal.username(), principal.roles());
                } else {
                    ws.close((short) 1003, "Unsupported path").subscribe().asCompletionStage();
                }
            }, failure -> {
                log.log(Level.SEVERE, "WebSocket upgrade failed: {0}", failure.getMessage());
                ctx.response().setStatusCode(400).setStatusMessage("WebSocket upgrade failed").end();
            });
        });

        router.routeWithRegex("^/(?!api(/|$)|eventbus(/|$)).*")
                .handler(ctx -> ctx.response().setStatusCode(404).setStatusMessage("Not Found").end());

        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .listen(port)
                .onItem().invoke(server -> log.log(Level.INFO, "Network server started on port {0}", server.actualPort()))
                .onFailure().invoke(failure -> log.log(Level.SEVERE, "Network server startup failed: {0}", failure.getMessage()))
                .subscribe().asCompletionStage();
    }

    private HandshakePrincipal authenticateWebSocketHandshake(HttpServerRequest request) {
        String token = extractBearerToken(request);
        if (token != null && !tokenBlacklistService.isBlacklisted(token) && tokenProvider.validateToken(token)) {
            return new HandshakePrincipal(tokenProvider.getUsernameFromToken(token), tokenProvider.extractRoles(token));
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
        ws.textMessageHandler(message -> {
            String requestId = null;
            try {
                JsonNode root = objectMapper.readTree(message);
                requestId = root.path("requestId").asText(null);
                String service = root.path("service").asText(null);
                String action = root.path("action").asText(null);
                JsonNode argsArray = root.path("args");

                if (argsArray.isMissingNode() || !argsArray.isArray()) {
                    writeWsError(ws, requestId, "Missing or invalid args array");
                    return;
                }

                WsActionRegistry.HandlerMethod handler = wsActionRegistry.getHandler(service, action);
                if (handler == null) {
                    writeWsError(ws, requestId, "No such WsAction for " + service + "#" + action);
                    return;
                }

                if (!isActionAllowed(handler, roles)) {
                    log.log(Level.WARNING, "Rejected unauthorized WsAction service={0}, action={1}, user={2}, roles={3}",
                            new Object[]{service, action, username, roles});
                    writeWsError(ws, requestId, "Forbidden");
                    return;
                }

                Method method = handler.getMethod();
                Class<?>[] paramTypes = method.getParameterTypes();
                Object bean = handler.getBean();
                int paramCount = paramTypes.length;

                if (argsArray.size() != paramCount) {
                    writeWsError(ws, requestId, "Param mismatch, method expects " + paramCount + " but got " + argsArray.size());
                    return;
                }

                Object[] invokeArgs = new Object[paramCount];
                for (int i = 0; i < paramCount; i++) {
                    invokeArgs[i] = convertJsonToParam(argsArray.get(i), paramTypes[i]);
                }

                Object result = method.invoke(bean, invokeArgs);
                if (method.getReturnType() != void.class && result != null) {
                    writeWsResult(ws, requestId, result);
                } else {
                    writeWsStatus(ws, requestId, "OK");
                }
            } catch (Exception e) {
                log.log(Level.SEVERE, "WebSocket JSON parsing or reflection error", e);
                writeWsError(ws, requestId, "Invalid JSON or reflect error");
            }
        });

        ws.closeHandler(() -> {
            unregisterWebSocket(username, ws);
            log.log(Level.INFO, "WebSocket connection closed, path={0}", ws.path());
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
                : roles.stream().map(this::normalizeRole).filter(role -> !role.isBlank()).collect(Collectors.toSet());

        return Arrays.stream(requiredRoles).map(this::normalizeRole).anyMatch(grantedRoles::contains);
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
        webSocketsByUsername.computeIfAbsent(username, ignored -> new CopyOnWriteArraySet<>()).add(ws);
    }

    private void unregisterWebSocket(String username, ServerWebSocket ws) {
        Set<ServerWebSocket> sockets = webSocketsByUsername.get(username);
        if (sockets == null) {
            return;
        }
        sockets.remove(ws);
        if (sockets.isEmpty()) {
            webSocketsByUsername.remove(username, sockets);
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
        }
        return objectMapper.treeToValue(node, targetType);
    }

    private void writeWsResult(ServerWebSocket ws, String requestId, Object result) {
        try {
            Map<String, Object> payload = wsPayload(requestId);
            payload.put("result", result);
            writeWsResponse(ws, payload);
        } catch (Exception ex) {
            writeWsError(ws, requestId, "Internal server error");
        }
    }

    private void writeWsStatus(ServerWebSocket ws, String requestId, String status) {
        Map<String, Object> payload = wsPayload(requestId);
        payload.put("status", status);
        writeWsResponse(ws, payload);
    }

    private void writeWsError(ServerWebSocket ws, String requestId, String error) {
        Map<String, Object> payload = wsPayload(requestId);
        payload.put("error", error);
        writeWsResponse(ws, payload);
    }

    private Map<String, Object> wsPayload(String requestId) {
        Map<String, Object> payload = new LinkedHashMap<>();
        if (requestId != null) {
            payload.put("requestId", requestId);
        }
        return payload;
    }

    private void writeWsResponse(ServerWebSocket ws, Map<String, Object> payload) {
        try {
            ws.writeTextMessage(objectMapper.writeValueAsString(payload)).subscribe().asCompletionStage();
        } catch (JsonProcessingException e) {
            log.log(Level.SEVERE, "Failed to serialize WebSocket response", e);
        }
    }

    private void writeJson(io.vertx.mutiny.core.http.HttpServerResponse response, Object payload) {
        try {
            response.putHeader("Content-Type", "application/json").end(objectMapper.writeValueAsString(payload));
        } catch (JsonProcessingException e) {
            response.setStatusCode(500).setStatusMessage("Internal Server Error").end();
        }
    }

    private void forwardHttpRequest(HttpServerRequest request) {
        String requestId = UUID.randomUUID().toString();
        String path = request.path();
        String query = request.query();
        String targetUrl = backendUrl + ":" + backendPort + path + (query != null ? "?" + query : "");
        log.log(Level.INFO, "[{0}] Forwarding request {1} to {2}", new Object[]{requestId, path, targetUrl});

        if (request.headers().contains("X-Forwarded-By")) {
            request.response().setStatusCode(500).setStatusMessage("Forwarding loop detected").end();
            return;
        }

        request.headers().add("X-Forwarded-By", "NetWorkHandler");
        MultiMap headers = MultiMap.caseInsensitiveMultiMap();
        request.headers().forEach(entry -> headers.add(entry.getKey(), entry.getValue()));

        HttpMethod method = request.method();
        var httpRequest = webClient.requestAbs(method, targetUrl).putHeaders(headers);

        if (method == HttpMethod.GET || method == HttpMethod.DELETE) {
            httpRequest.send()
                    .onSuccess(response -> handleResponse(request, response, requestId))
                    .onFailure(failure -> request.response().setStatusCode(500).setStatusMessage("Forward failed").end());
            return;
        }

        request.body()
                .onItem().invoke(body -> {
                    if (body == null || body.length() == 0) {
                        httpRequest.send()
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> request.response().setStatusCode(500).setStatusMessage("Forward failed").end());
                    } else {
                        httpRequest.sendBuffer(Buffer.buffer(body.getBytes()))
                                .onSuccess(response -> handleResponse(request, response, requestId))
                                .onFailure(failure -> request.response().setStatusCode(500).setStatusMessage("Forward failed").end());
                    }
                })
                .onFailure().invoke(failure -> request.response().setStatusCode(400).setStatusMessage("Invalid request body").end())
                .subscribe().asCompletionStage();
    }

    private void handleResponse(HttpServerRequest request, HttpResponse<Buffer> response, String requestId) {
        var clientResponse = request.response();
        clientResponse.setStatusCode(response.statusCode());
        String statusMessage = response.statusMessage();
        clientResponse.setStatusMessage(statusMessage != null ? statusMessage : HttpResponseStatus.valueOf(response.statusCode()).reasonPhrase());
        response.headers().forEach(entry -> {
            if (!entry.getKey().equalsIgnoreCase("Transfer-Encoding")) {
                clientResponse.putHeader(entry.getKey(), entry.getValue());
            }
        });
        Buffer responseBody = response.body();
        if (responseBody != null && responseBody.length() > 0) {
            clientResponse.end(responseBody.toString());
        } else {
            clientResponse.end();
        }
    }

    private record HandshakePrincipal(String username, List<String> roles) {
    }
}
