package finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsActionRegistry;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.MultiMap;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.json.JsonObject;
import io.vertx.mutiny.core.Vertx;
import io.vertx.mutiny.core.http.HttpServerRequest;
import io.vertx.mutiny.core.http.ServerWebSocket;
import io.vertx.mutiny.ext.web.Router;
import io.vertx.mutiny.ext.web.client.HttpResponse;
import io.vertx.mutiny.ext.web.client.WebClient;
import io.vertx.mutiny.ext.web.handler.CorsHandler;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.inject.spi.BeanManager;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.lang.reflect.Method;
import java.util.Set;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

// Quarkus Verticle类，用于处理网络请求和WebSocket连接
@ApplicationScoped
public class NetWorkHandler extends AbstractVerticle {

    // 日志记录器，用于记录网络处理过程中的信息
    private static final Logger log = Logger.getLogger(NetWorkHandler.class.getName());

    // 注入配置属性：服务器端口
    @ConfigProperty(name = "network.server.port", defaultValue = "8081")
    int port;

    // 注入配置属性：后端服务URL
    @ConfigProperty(name = "backend.url")
    String backendUrl;

    // 注入配置属性：后端服务端口
    @ConfigProperty(name = "backend.port")
    int backendPort;

    // 注入TokenProvider用于验证JWT
    @Inject
    TokenProvider tokenProvider;

    // 注入WsActionRegistry用于处理WebSocket动作
    @Inject
    WsActionRegistry wsActionRegistry;

    // 注入ObjectMapper用于JSON序列化和反序列化
    @Inject
    ObjectMapper objectMapper;

    // WebClient实例，用于转发HTTP请求
    private WebClient webClient;

    // 初始化方法，在Quarkus应用启动时调用
    public void init(@Observes @Priority(1) jakarta.enterprise.context.Initialized.ApplicationScoped event, BeanManager beanManager) {
        webClient = WebClient.create(vertx);
    }

    // 启动Verticle，配置路由和服务器
    @Override
    public void start() {
        this.webClient = WebClient.create(vertx);

        Router router = Router.router(vertx);
        configureCors(router);
        setupNetWorksServer(router);
    }

    // 配置CORS，允许跨域请求
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
                .allowedMethod(HttpMethod.OPTIONS));
    }

    // 配置网络服务器，处理HTTP和WebSocket请求
    private void setupNetWorksServer(Router router) {
        // 处理API请求的路由
        router.route("/api/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            forwardHttpRequest(request);
        });

        // 处理WebSocket请求的路由
        router.route("/eventbus/*").handler(ctx -> {
            HttpServerRequest request = ctx.request();
            request.toWebSocket().onSuccess(ws -> {
                log.log(Level.INFO, "WebSocket连接已建立, path={0}", ws.path());
                if (ws.path().contains("/eventbus")) {
                    handleWebSocketConnection(ws);
                } else {
                    ws.close((short) 1003, "不支持的路径")
                            .onItem().invoke(success -> log.log(Level.INFO, "关闭 {0} WebSocket连接成功 {1}", new Object[]{ws.path(), success}))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "关闭 {0} WebSocket连接失败: {1}", new Object[]{ws.path(), failure.getMessage()}))
                            .subscribe().asCompletionStage();
                }
            }).onFailure().invoke(failure -> {
                log.log(Level.SEVERE, "WebSocket升级失败: {0}", failure.getMessage());
                ctx.response().setStatusCode(400).setStatusMessage("WebSocket升级失败").end();
            }).subscribe().asCompletionStage();
        });

        // 处理未匹配的路由，返回404
        router.routeWithRegex("^/(?!api(/|$)|eventbus(/|$)).*")
                .handler(ctx -> ctx.response().setStatusCode(404)
                        .setStatusMessage("未找到资源")
                        .end());

        // 配置HTTP服务器选项
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        // 启动HTTP服务器
        vertx.createHttpServer(options)
                .requestHandler(router)
                .listen(port)
                .onItem().invoke(server -> log.log(Level.INFO, "Network服务器已在端口 {0} 启动", server.actualPort()))
                .onFailure().invoke(failure -> log.log(Level.SEVERE, "Network服务器启动失败: {0}", failure.getMessage()))
                .subscribe().asCompletionStage();
    }

    // 处理WebSocket连接
    private void handleWebSocketConnection(ServerWebSocket ws) {
        ws.textMessageHandler(message -> {
            try {
                JsonNode root = objectMapper.readTree(message);
                String token = root.path("token").asText(null);

                // 验证JWT令牌
                if (token == null || !tokenProvider.validateToken(token)) {
                    log.log(Level.WARNING, "无效的令牌，关闭WebSocket");
                    ws.close((short) 1000, "无效的令牌")
                            .onItem().invoke(result -> log.log(Level.INFO, "因无效令牌关闭WebSocket: {0}", result))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "关闭WebSocket失败: {0}", failure.getMessage()))
                            .subscribe().asCompletionStage();
                    return;
                }

                String service = root.path("service").asText(null);
                String action = root.path("action").asText(null);
                String idempotencyKey = root.path("idempotencyKey").asText(null);
                JsonNode argsArray = root.path("args");

                // 验证args数组
                if (argsArray.isMissingNode() || !argsArray.isArray()) {
                    log.log(Level.WARNING, "无效或缺失的'args'数组");
                    ws.writeTextMessage("{\"error\":\"缺失或无效的'args'数组\"}")
                            .onItem().invoke(result -> log.log(Level.INFO, "WebSocket写入成功: {0}", result))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "WebSocket写入失败: {0}", failure.getMessage()))
                            .subscribe().asCompletionStage();
                    return;
                }

                log.log(Level.INFO, "收到 service={0}, action={1}, idempotencyKey={2}, args={3}",
                        new Object[]{service, action, idempotencyKey, argsArray});

                // 获取WebSocket动作处理器
                WsActionRegistry.HandlerMethod handler = wsActionRegistry.getHandler(service, action);
                if (handler == null) {
                    ws.writeTextMessage("{\"error\":\"没有对应的WsAction: " + service + "#" + action + "\"}")
                            .onItem().invoke(result -> log.log(Level.INFO, "WebSocket写入成功: {0}", result))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "WebSocket写入失败: {0}", failure.getMessage()))
                            .subscribe().asCompletionStage();
                    return;
                }

                Method method = handler.getMethod();
                Class<?>[] paramTypes = method.getParameterTypes();
                Object bean = handler.getBean();
                int paramCount = paramTypes.length;

                // 验证参数数量
                if (argsArray.size() != paramCount) {
                    ws.writeTextMessage("{\"error\":\"参数数量不匹配，方法需要 " + paramCount + " 个参数，但收到 " + argsArray.size() + " 个\"}")
                            .onItem().invoke(result -> log.log(Level.INFO, "WebSocket写入成功: {0}", result))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "WebSocket写入失败: {0}", failure.getMessage()))
                            .subscribe().asCompletionStage();
                    return;
                }

                // 转换JSON参数
                Object[] invokeArgs = new Object[paramCount];
                for (int i = 0; i < paramCount; i++) {
                    Class<?> pt = paramTypes[i];
                    JsonNode argNode = argsArray.get(i);
                    invokeArgs[i] = convertJsonToParam(argNode, pt);
                }

                // 调用处理方法
                Object result = method.invoke(bean, invokeArgs);

                // 处理返回值
                if (method.getReturnType() != void.class && result != null) {
                    try {
                        String retJson = objectMapper.writeValueAsString(result);
                        ws.writeTextMessage("{\"result\":" + retJson + "}")
                                .onItem().invoke(response -> log.log(Level.INFO, "WebSocket写入成功: {0}", response))
                                .onFailure().invoke(failure -> log.log(Level.SEVERE, "WebSocket写入失败: {0}", failure.getMessage()))
                                .subscribe().asCompletionStage();
                    } catch (JsonProcessingException e) {
                        log.log(Level.SEVERE, "序列化结果到JSON失败", e);
                        ws.writeTextMessage("{\"error\":\"内部服务器错误\"}")
                                .onItem().invoke(response -> log.log(Level.INFO, "错误响应已发送: {0}", response))
                                .onFailure().invoke(failure -> log.log(Level.SEVERE, "发送错误响应失败: {0}", failure.getMessage()))
                                .subscribe().asCompletionStage();
                    }
                } else {
                    ws.writeTextMessage("{\"status\":\"OK\"}")
                            .onItem().invoke(response -> log.log(Level.INFO, "WebSocket写入成功: {0}", response))
                            .onFailure().invoke(failure -> log.log(Level.SEVERE, "WebSocket写入失败: {0}", failure.getMessage()))
                            .subscribe().asCompletionStage();
                }

            } catch (Exception e) {
                log.log(Level.SEVERE, "JSON解析或反射错误", e);
                ws.close((short) 1000, "无效的JSON或反射错误")
                        .onItem().invoke(result -> log.log(Level.INFO, "因无效JSON关闭WebSocket"))
                        .onFailure().invoke(failure -> log.log(Level.SEVERE, "关闭WebSocket失败: {0}", failure.getMessage()))
                        .subscribe().asCompletionStage();
            }
        });

        // 处理WebSocket关闭
        ws.closeHandler(v -> log.log(Level.INFO, "WebSocket连接关闭, path={0} {1}", new Object[]{ws.path(), v}));
    }

    // 将JSON节点转换为方法参数
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

    // 转发HTTP请求到后端服务
    private void forwardHttpRequest(HttpServerRequest request) {
        String requestId = UUID.randomUUID().toString();
        String path = request.path();
        String query = request.query();
        String targetUrl = backendUrl + ":" + backendPort + path + (query != null ? "?" + query : "");
        log.log(Level.INFO, "[{0}] 从路径转发请求: {1} 到目标URL: {2}", new Object[]{requestId, path, targetUrl});

        // 检测循环转发
        if (request.headers().contains("X-Forwarded-By")) {
            log.log(Level.SEVERE, "[{0}] 检测到循环转发，终止请求", requestId);
            request.response().setStatusCode(500).setStatusMessage("检测到循环转发").end();
            return;
        }

        request.headers().add("X-Forwarded-By", "NetWorkHandler");

        // 复制请求头
        MultiMap headers = MultiMap.caseInsensitiveMultiMap();
        request.headers().forEach(entry -> {
            headers.add(entry.getKey(), entry.getValue());
            log.log(Level.INFO, "[{0}] 转发头: {1} = {2}", new Object[]{requestId, entry.getKey(), entry.getValue()});
        });

        MultiMap queryParams = request.params();
        log.log(Level.INFO, "[{0}] 查询参数: {1}", new Object[]{requestId, queryParams});

        HttpMethod method = request.method();
        var httpRequest = webClient.requestAbs(method, targetUrl).putHeaders(headers);

        // 处理GET或DELETE请求
        if (method == HttpMethod.GET || method == HttpMethod.DELETE) {
            log.log(Level.INFO, "[{0}] 转发 {1} 请求，查询参数: {2}", new Object[]{requestId, method, queryParams});
            httpRequest.send()
                    .onItem().invoke(response -> handleResponse(request, response, requestId))
                    .onFailure().invoke(failure -> {
                        log.log(Level.SEVERE, "[{0}] 转发 {1} 请求失败: {2}", new Object[]{requestId, method, failure.getMessage()});
                        request.response().setStatusCode(500).setStatusMessage("转发失败").end();
                    })
                    .subscribe().asCompletionStage();
        } else {
            // 处理带有请求体的请求
            request.body()
                    .onItem().invoke(body -> {
                        try {
                            String contentType = request.getHeader("Content-Type");
                            if (body == null || body.length() == 0) {
                                log.log(Level.INFO, "[{0}] {1} 请求无请求体，继续处理空请求", new Object[]{requestId, method});
                                httpRequest.send()
                                        .onItem().invoke(response -> handleResponse(request, response, requestId))
                                        .onFailure().invoke(failure -> {
                                            log.log(Level.SEVERE, "[{0}] 转发 {1} 请求失败: {2}", new Object[]{requestId, method, failure.getMessage()});
                                            request.response().setStatusCode(500).setStatusMessage("转发失败").end();
                                        })
                                        .subscribe().asCompletionStage();
                            } else if (contentType != null && contentType.toLowerCase().contains("text/plain")) {
                                String rawBody = body.toString();
                                log.log(Level.INFO, "[{0}] {1} 的原始请求体: {2}", new Object[]{requestId, method, rawBody});
                                httpRequest.putHeader("Content-Type", contentType);
                                httpRequest.sendBuffer(Buffer.buffer(rawBody))
                                        .onItem().invoke(response -> handleResponse(request, response, requestId))
                                        .onFailure().invoke(failure -> {
                                            log.log(Level.SEVERE, "[{0}] 转发 {1} 请求失败: {2}", new Object[]{requestId, method, failure.getMessage()});
                                            request.response().setStatusCode(500).setStatusMessage("转发失败").end();
                                        })
                                        .subscribe().asCompletionStage();
                            } else if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                                JsonObject jsonBody = body.toJsonObject();
                                log.log(Level.INFO, "[{0}] {1} 的JSON请求体: {2}", new Object[]{requestId, method, jsonBody});
                                httpRequest.putHeader("Content-Type", "application/json");
                                httpRequest.sendJsonObject(jsonBody)
                                        .onItem().invoke(response -> handleResponse(request, response, requestId))
                                        .onFailure().invoke(failure -> {
                                            log.log(Level.SEVERE, "[{0}] 转发 {1} 请求失败: {2}", new Object[]{requestId, method, failure.getMessage()});
                                            request.response().setStatusCode(500).setStatusMessage("转发失败").end();
                                        })
                                        .subscribe().asCompletionStage();
                            } else {
                                log.log(Level.WARNING, "[{0}] 无法识别的Content-Type: {1} for {2}, 作为原始缓冲区转发", new Object[]{requestId, contentType, method});
                                httpRequest.sendBuffer(body)
                                        .onItem().invoke(response -> handleResponse(request, response, requestId))
                                        .onFailure().invoke(failure -> {
                                            log.log(Level.SEVERE, "[{0}] 转发 {1} 请求失败: {2}", new Object[]{requestId, method, failure.getMessage()});
                                            request.response().setStatusCode(500).setStatusMessage("转发失败").end();
                                        })
                                        .subscribe().asCompletionStage();
                            }
                        } catch (Exception e) {
                            log.log(Level.SEVERE, "[{0}] 请求体解析失败 for {1}: {2}", new Object[]{requestId, method, e.getMessage()});
                            request.response().setStatusCode(400).setStatusMessage("请求体解析失败").end();
                        }
                    })
                    .onFailure().invoke(failure -> {
                        log.log(Level.SEVERE, "[{0}] 获取请求体失败: {1}", new Object[]{requestId, failure.getMessage()});
                        request.response().setStatusCode(400).setStatusMessage("获取请求体失败").end();
                    })
                    .subscribe().asCompletionStage();
        }
    }

    // 处理后端响应
    private void handleResponse(HttpServerRequest request, HttpResponse<Buffer> response, String requestId) {
        log.log(Level.INFO, "[{0}] 响应状态码: {1}", new Object[]{requestId, response.statusCode()});
        log.log(Level.INFO, "[{0}] 响应头: {1}", new Object[]{requestId, response.headers()});
        String responseBody = response.bodyAsString();
        log.log(Level.INFO, "[{0}] 后端响应体: {1}", new Object[]{requestId, responseBody != null ? responseBody : "null"});

        var clientResponse = request.response();
        clientResponse.setStatusCode(response.statusCode());

        String statusMessage = response.statusMessage();
        if (statusMessage != null) {
            clientResponse.setStatusMessage(statusMessage);
        } else {
            log.log(Level.WARNING, "[{0}] 后端响应状态消息为空", requestId);
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
            log.log(Level.WARNING, "[{0}] 响应体为空或无内容，状态: {1}", new Object[]{requestId, response.statusCode()});
            clientResponse.putHeader("Content-Type", "application/json");
            clientResponse.end();
        }
    }
}