package com.tutict.finalassignmentbackend.config.vertx;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.JwtParserBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.HttpMethod;
import io.vertx.ext.bridge.PermittedOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.CorsHandler;
import io.vertx.ext.web.handler.sockjs.SockJSBridgeOptions;
import io.vertx.ext.web.handler.sockjs.SockJSHandler;
import io.vertx.ext.web.handler.sockjs.SockJSHandlerOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;

import java.nio.charset.StandardCharsets;

import static javax.crypto.Cipher.SECRET_KEY;

@Slf4j
@Component
public class WebSocketServer extends AbstractVerticle {

    @Value("${server.port}")
    private int port;

    @Override
    public void start(Promise<Void> startPromise) {

        Router router = Router.router(vertx);

        // 设置跨域处理器
        CorsHandler corsHandler = CorsHandler.create("http://localhost:8082")
                .allowedMethod(HttpMethod.GET)
                .allowedMethod(HttpMethod.POST)
                .allowedMethod(HttpMethod.PUT)
                .allowedMethod(HttpMethod.DELETE)
                .allowedMethod(HttpMethod.OPTIONS)
                .allowedHeader("Access-Control-Allow-Method")
                .allowedHeader("Access-Control-Allow-Origin")
                .allowedHeader("Access-Control-Allow-Credentials")
                .allowedHeader("Access-Control-Allow-Headers")
                .allowedHeader("Authorization")
                .allowedHeader("Content-Type")
                .allowCredentials(true)
                .maxAgeSeconds(3600);

        // 添加跨域处理器到路由器
        router.route().handler(corsHandler);

        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(3000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        sockJSHandler.bridge(bridgeOptions);

        router.route("/eventbus/*").handler(sockJSHandler);


        vertx.createHttpServer()
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    // Extract and validate JWT from headers
                    String token = ws.headers().get("Authorization");
                    if (token != null && token.startsWith("Bearer ")) {
                        String jwtToken = token.substring(7);
                        if (validateToken(jwtToken)) {
                            ws.handler(buffer -> {
                                // Handle WebSocket messages
                                vertx.eventBus().publish("chat.to.server", buffer);
                            });
                        } else {
                            ws.reject();
                        }
                    } else {
                        ws.reject();
                    }
                })
                .listen(port, res -> {
                    if (res.succeeded()) {
                        log.info("WebSocket server is up and running on port {}", res.result().actualPort());
                        startPromise.complete();
                    } else {
                        log.error("Could not start WebSocket server on port {}", port, res.cause());
                        startPromise.fail(res.cause());
                    }
                });

        vertx.eventBus().<Buffer>consumer("chat.to.server", message -> {
            log.info("Received binary message of length: {}", message.body().length());
            // 将接收到的二进制消息发布到 chat.to.client 地址
            vertx.eventBus().publish("chat.to.client", message.body());
        });

    }
}
private boolean validateToken(String token) {
    try {
        SecretKey key = Keys.hmacShaKeyFor(SECRET_KEY.getBytes(StandardCharsets.UTF_8));
        JwtParserBuilder parserBuilder = Jwts.parserBuilder().setSigningKey(key);
        JwtParser parser = parserBuilder.build();
        parser.parseClaimsJws(token);
        return true; // Token is valid
    } catch (JwtException e) {
        return false; // Token is invalid
    }
}
}