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
import jakarta.annotation.PostConstruct;
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

    public void init(@Observes StartupEvent event) {
        start();
    }

    @PostConstruct
    public void start() {
        Router router = Router.router(vertx);

        // Configure CORS
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

        router.route().handler(CorsHandler.create().addOrigin("http://localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        // Configure SockJS
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(2000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        // Add SockJS handler to router
        router.route("/eventbus/*").handler(sockJSHandler);
        sockJSHandler.bridge(bridgeOptions);

        // Create HTTP server
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
                                    log.error("Failed to handle WebSocket message: {}", e.getMessage());
                                    ws.close();
                                }
                            });
                        } else {
                            log.warn("Invalid token received, closing WebSocket connection");
                            ws.close();
                        }
                    } else {
                        log.warn("Authorization header missing or does not start with Bearer, closing WebSocket connection");
                        ws.close();
                    }
                })
                .listen(port, res -> {
                    if (res.succeeded()) {
                        log.info("WebSocket server started on port {}", res.result().actualPort());
                    } else {
                        log.error("Failed to start WebSocket server on port {}", port, res.cause());
                    }
                });
    }
}
