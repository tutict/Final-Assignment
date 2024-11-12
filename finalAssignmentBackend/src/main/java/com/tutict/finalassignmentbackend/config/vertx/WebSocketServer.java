package com.tutict.finalassignmentbackend.config.vertx;

import com.auth0.jwt.exceptions.JWTVerificationException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.SignatureAlgorithm;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.buffer.Buffer;
import io.vertx.core.http.HttpMethod;
import io.vertx.core.http.HttpServerOptions;
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
import java.util.Base64;
import java.util.HashSet;
import java.util.Set;

import static com.tutict.finalassignmentbackend.controller.UserManagementController.logger;


// 使用Slf4J进行日志记录
@Slf4j
// 定义一个WebSocket服务器类，继承自AbstractVerticle
@Component
public class WebSocketServer extends AbstractVerticle {

    // 注入服务器端口配置
    @Value("${server.port}")
    private int port;

    // 生成并注入JWT密钥
    private final String secretKey = Base64.getEncoder()
            .encodeToString(Keys.hmacShaKeyFor(SignatureAlgorithm.HS256.getJcaName().getBytes()).getEncoded());

    /**
     * 在Verticle启动时执行
     * 配置路由器、WebSocket处理器和事件总线消费者
     * 以启动WebSocket服务器
     *
     * @param startPromise 启动承诺，用于通知Vert.x启动已完成
     */
    @Override
    public void start(Promise<Void> startPromise) {

        // 创建一个路由器实例
        Router router = Router.router(vertx);

        // 设置跨域处理器
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

        // 添加跨域处理器到路由器
        router.route().handler(CorsHandler.create().addOrigin("http://localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        // 配置SockJS处理器选项，设置心跳间隔
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(2000);
        SockJSHandler sockJSHandler = SockJSHandler.create(vertx, sockJSOptions);

        // 配置SockJS桥接选项，允许的消息地址
        SockJSBridgeOptions bridgeOptions = new SockJSBridgeOptions()
                .addInboundPermitted(new PermittedOptions().setAddress("chat.to.server"))
                .addOutboundPermitted(new PermittedOptions().setAddress("chat.to.client"));

        // 将SockJS处理器添加到路由器的特定路径
        router.route("/eventbus/*").handler(sockJSHandler);

        // 为SockJS处理器配置桥接选项
        sockJSHandler.bridge(bridgeOptions);

        // 创建HTTP服务器，配置请求处理器和WebSocket处理器
        HttpServerOptions options = new HttpServerOptions()
                .setMaxWebSocketFrameSize(1000000)
                .setTcpKeepAlive(true);

        vertx.createHttpServer(options)
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    // 提取并验证JWT令牌
                    String token = ws.headers().get("Authorization");
                    if (token != null && token.startsWith("Bearer ")) {
                        String jwtToken = token.substring(7);
                        if (validateToken(jwtToken)) {
                            // 处理WebSocket消息
                            ws.handler(buffer -> {
                                try {
                                    vertx.eventBus().publish("chat.to.server", buffer);
                                } catch (Exception e) {
                                    log.error("Failed to handle WebSocket message: {}", e.getMessage());
                                    ws.reject();
                                }
                            });
                        } else {
                            log.warn("Invalid token received, rejecting WebSocket connection");
                            ws.reject();
                        }
                    } else {
                        log.warn("Authorization header missing or does not start with Bearer, rejecting WebSocket connection");
                        ws.reject();
                    }
                })
                .listen(port, res -> {
                    if (res.succeeded()) {
                        // 服务器启动成功时记录日志并完成启动承诺
                        log.info("WebSocket server is up and running on port {}", res.result().actualPort());
                        startPromise.complete();
                    } else {
                        // 启动失败时记录错误并失败启动承诺
                        log.error("Could not start WebSocket server on port {}", port, res.cause());
                        startPromise.fail(res.cause());
                    }
                });

        // 事件总线消费者，处理发送到“chat.to.server”的消息
        vertx.eventBus().<Buffer>consumer("chat.to.server", message -> {
            // 记录消息长度并转发到“chat.to.client”
            log.info("Received binary message of length: {}", message.body().length());
            vertx.eventBus().publish("chat.to.client", message.body());
        });

    }

    /**
     * 验证JWT令牌的有效性
     *
     * @param token 待验证的JWT令牌
     * @return 如果令牌有效则返回true，否则返回false
     */
    boolean validateToken(String token) {
        logger.info("Attempting to validate JWT token.");

        try {
            // 创建密钥并解析JWT
            SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            logger.info("JWT token is valid.");
            return true; // 令牌有效
        } catch (JWTVerificationException e) {
            // JWT验证失败
            logger.error("JWT签名无效,报错如下： {}", e.getMessage());
            return false;
        } catch (IllegalArgumentException e) {
            // JWT字符串为空
            logger.error("JWT声明字符串为空,报错如下： {}", e.getMessage());
            return false;
        } catch (Exception e) {
            // 其他异常
            logger.error("解析JWT时发生意外错误,报错如下： {}", e.getMessage());
            return false;
        }
    }
}
