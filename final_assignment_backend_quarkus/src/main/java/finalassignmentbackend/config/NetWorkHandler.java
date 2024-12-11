package finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.route.EventBusAddress;
import finalassignmentbackend.config.route.NetWorkRoute;
import io.smallrye.mutiny.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
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

@Slf4j
@ApplicationScoped
public class NetWorkHandler extends AbstractVerticle {

    @Inject
    ProducerTemplate producerTemplate;

    @Inject
    TokenProvider tokenProvider;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "server.port", defaultValue = "8081")
    int port;

    @ConfigProperty(name = "backend.url")
    String backendUrl;

    private WebClient webClient;

    @PostConstruct
    public void init() {
        io.vertx.core.Vertx coreVertx = vertx.getDelegate();
        webClient = WebClient.create(coreVertx);
    }

    @Override
    public void start(Promise<Void> startPromise) {
        Router router = Router.router(vertx);

        configureCors(router);
        configureSockJS(router);
        configureHttpRouting(router);

        setupHttpServer(router, startPromise);
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

        sockJSHandler.bridge(bridgeOptions);

        router.route("/eventbus/*").handler(sockJSHandler);
    }

    private void configureHttpRouting(Router router) {
        router.route().handler(ctx -> {
            HttpServerRequest request = ctx.request();
            String path = request.path();

            if (path.startsWith("/eventbus")) {
                String useSockJS = request.getParam("useSockJS");

                if ("true".equals(useSockJS)) {
                    // 已在 configureSockJS 方法中处理
                    ctx.next();
                } else {
                    // 尝试升级为 WebSocket
                    if (request.headers().contains("Upgrade", "websocket", true)) {
                        ctx.request().toWebSocket()
                                .subscribe()
                                .with(this::handleWebSocketConnection, t -> {
                                    log.error("WebSocket 连接失败", t);
                                    ctx.response().setStatusCode(500).setStatusMessage("WebSocket 连接失败").closed();
                                });
                    } else {
                        // 转发 HTTP 请求
                        forwardHttpRequest(request);
                    }
                }
            } else {
                ctx.fail(404);
            }
        });
    }

    private void setupHttpServer(Router router, Promise<Void> startPromise) {
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .listen(port)
                .subscribe().with(
                        server -> {
                            log.info("WebSocket 服务器已在端口 {} 启动", server.actualPort());
                            startPromise.complete();
                        },
                        failure -> {
                            log.error("服务器启动失败: {}", failure.getMessage(), failure);
                            startPromise.fail(failure);
                        }
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

                        System.out.println(ws.path());

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
        String targetUrl = backendUrl + path;

        request.bodyHandler(body -> {
            if (body == null || body.length() == 0) {
                log.error("请求体为空，无法发送 JSON 数据");
                request.response().setStatusCode(400).setStatusMessage("请求体为空").closed();
                return;
            }

            try {
                JsonObject jsonBody = body.toJsonObject();

                webClient.postAbs(targetUrl)
                        .sendJsonObject(jsonBody)
                        .onSuccess(response -> {
                            log.info("转发 HTTP 请求成功: {}", response.statusMessage());

                            // 设置状态码
                            request.response().setStatusCode(response.statusCode());

                            // 复制所有响应头
                            response.headers().forEach(entry -> request.response().putHeader(entry.getKey(), entry.getValue()));

                            // 结束响应并发送消息体
                            request.response().setStatusMessage(response.bodyAsString()).closed();
                        })
                        .onFailure(failure -> {
                            log.error("转发 HTTP 请求失败", failure);
                            request.response().setStatusCode(500).setStatusMessage("转发失败").closed();
                        });
            } catch (Exception e) {
                log.error("请求体解析失败", e);
                request.response().setStatusCode(400).setStatusMessage("请求体解析失败").closed();
            }
        });
    }
}