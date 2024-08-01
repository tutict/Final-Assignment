package com.tutict.finalassignmentbackend.config.vertx;

import com.auth0.jwt.exceptions.JWTVerificationException;
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
import java.util.HashSet;
import java.util.Set;

import static com.tutict.finalassignmentbackend.config.login.JWT.AuthController.logger;

@Slf4j
@Component
public class WebSocketServer extends AbstractVerticle {

    @Value("${server.port}")
    private int port;

    @Value("${jwt.secret-key}")
    private String secretKey;

    @Override
    public void start(Promise<Void> startPromise) {

        Router router = Router.router(vertx);

        // 设置跨域处理器
        Set<String> allowedHeaders = new HashSet<>();
        allowedHeaders.add("x-requested-with");
        allowedHeaders.add("Access-Control-Allow-Origin");
        allowedHeaders.add("origin");
        allowedHeaders.add("Content-Type");
        allowedHeaders.add("accept");
        allowedHeaders.add("X-PINGARUNER");

        Set<HttpMethod> allowedMethods = new HashSet<>();
        allowedMethods.add(HttpMethod.GET);
        allowedMethods.add(HttpMethod.POST);
        allowedMethods.add(HttpMethod.DELETE);
        allowedMethods.add(HttpMethod.PATCH);
        allowedMethods.add(HttpMethod.OPTIONS);
        allowedMethods.add(HttpMethod.PUT);

        // 添加跨域处理器到路由器
        router.route().handler(CorsHandler.create("http:\\\\/\\\\/localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(3000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));


        router.route("/eventbus/*").handler(sockJSHandler);

        sockJSHandler.bridge(bridgeOptions);

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
boolean validateToken(String token) {

    try {
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
        Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
        return true; // Token有用
    } catch (JWTVerificationException e) {
        logger.error(e, () -> "JWT签名无效,报错如下： " + e.getMessage());
        return false;
    } catch (IllegalArgumentException e) {
        logger.error(e, () -> "JWT声明字符串为空,报错如下： " + e.getMessage());
        return false;
    } catch (Exception e) {
        logger.error(e, () -> "解析JWT时发生意外错误,报错如下： " + e.getMessage());
        return false;
    }
    }
}