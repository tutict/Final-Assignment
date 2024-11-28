package finalassignmentbackend.config.vertx;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.runtime.StartupEvent;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.CorsHandler;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandler;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.HashSet;
import java.util.Set;

@Slf4j
@ApplicationScoped
public class WebSocketServer {


    @ConfigProperty(name = "server.port", defaultValue = "8080")
    int port;

    @Inject
    Vertx vertx;

    private final TokenProvider tokenProvider;

    public WebSocketServer(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    /**
     * 启动 WebSocket 服务
     */
    public void onStart(@Observes StartupEvent event) {
        start();
    }

    /**
     * 初始化 WebSocket 服务器
     */
    public void start() {
        Router router = Router.router(vertx);

        // 配置 CORS
        Set<String> allowedHeaders = new HashSet<>();
        allowedHeaders.add("Authorization");
        allowedHeaders.add("X-Requested-With");
        allowedHeaders.add("Sec-WebSocket-Key");
        allowedHeaders.add("Sec-WebSocket-Version");
        allowedHeaders.add("Sec-WebSocket-Protocol");

        Set<HttpMethod> allowedMethods = new HashSet<>();
        allowedMethods.add(HttpMethod.GET);
        allowedMethods.add(HttpMethod.POST);
        allowedMethods.add(HttpMethod.DELETE);
        allowedMethods.add(HttpMethod.PATCH);
        allowedMethods.add(HttpMethod.OPTIONS);
        allowedMethods.add(HttpMethod.PUT);

        router.route().handler(CorsHandler.create()
                .addOrigin("http://localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        // 配置 SockJS
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(2000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        // 设置桥接选项
        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        // 将 SockJS 处理程序添加到路由
        router.route("/eventbus/*").handler(sockJSHandler);
        sockJSHandler.bridge(bridgeOptions);

        // 配置 HTTP 服务器
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    String token = ws.headers().get("Authorization");
                    if (token != null && token.startsWith("Bearer ")) {
                        String jwtToken = token.substring(7);
                        if (tokenProvider.validateToken(jwtToken)) {
                            ws.handler(buffer -> {
                                try {
                                    vertx.eventBus().publish("chat.to.server", buffer);
                                } catch (Exception e) {
                                    log.error("处理 WebSocket 消息失败: {}", e.getMessage(), e);
                                    ws.close();
                                }
                            });
                        } else {
                            log.warn("无效的令牌，关闭 WebSocket 连接");
                            ws.close();
                        }
                    } else {
                        log.warn("缺少 Authorization header 或其格式不正确，关闭 WebSocket 连接");
                        ws.close();
                    }
                })
                .listen(port, res -> {
                    if (res.succeeded()) {
                        log.info("WebSocket 服务器已在端口 {} 启动", res.result().actualPort());
                    } else {
                        log.error("WebSocket 服务器启动失败, 错误信息: {}", res.cause().getMessage(), res.cause());
                    }
                });
    }
}