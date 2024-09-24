package finalassignmentbackend.config.vertx;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandler;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class WebSocketServer extends AbstractVerticle {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketServer.class);

    @ConfigProperty(name = "server.port")
    int port;

    @Override
    public void start(Promise<Void> startPromise) {
        Router router = Router.router(vertx);

        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(3000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        sockJSHandler.bridge(bridgeOptions);

        router.route("/eventbus/*").handler(sockJSHandler);

        vertx.createHttpServer().requestHandler(router).listen(port, res -> {
            if (res.succeeded()) {
                logger.info("WebSocket server is up and running on port {}", port);
                startPromise.complete();
            } else {
                logger.error("Could not start WebSocket server on port {}", port, res.cause());
                startPromise.fail(res.cause());
            }
        });

        vertx.eventBus().<String>consumer("chat.to.server", message -> {
            logger.info("Received message: {}", message.body());
            vertx.eventBus().publish("chat.to.client", "Reply: " + message.body());
        });
    }
}