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

import static com.tutict.finalassignmentbackend.controller.UserManagementController.logger;


// 使用Slf4J进行日志记录
@Slf4j
// 定义一个WebSocket服务器类，继承自AbstractVerticle
@Component
public class WebSocketServer extends AbstractVerticle {

    // 注入服务器端口配置
    @Value("${server.port}")
    private int port;

    // 注入JWT密钥配置
    @Value("${jwt.secret-key}")
    private String secretKey;

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
        router.route().handler(CorsHandler.create().addOrigin("http:\\\\/\\\\/localhost:8082")
                .allowedHeaders(allowedHeaders)
                .allowedMethods(allowedMethods));

        // 配置SockJS处理器选项，设置心跳间隔
        SockJSHandlerOptions sockJSOptions = new SockJSHandlerOptions().setHeartbeatInterval(3000);
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
        vertx.createHttpServer()
                .requestHandler(router)
                .webSocketHandler(ws -> {
                    // 提取并验证JWT令牌
                    String token = ws.headers().get("Authorization");
                    if (token != null && token.startsWith("Bearer ")) {
                        String jwtToken = token.substring(7);
                        if (validateToken(jwtToken)) {
                            // 处理WebSocket消息
                            ws.handler(buffer -> vertx.eventBus().publish("chat.to.server", buffer));
                        } else {
                            ws.reject();
                        }
                    } else {
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

        try {
            // 创建密钥并解析JWT
            SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true; // 令牌有效
        } catch (JWTVerificationException e) {
            // JWT验证失败
            logger.error(e, () -> "JWT签名无效,报错如下： " + e.getMessage());
            return false;
        } catch (IllegalArgumentException e) {
            // JWT字符串为空
            logger.error(e, () -> "JWT声明字符串为空,报错如下： " + e.getMessage());
            return false;
        } catch (Exception e) {
            // 其他异常
            logger.error(e, () -> "解析JWT时发生意外错误,报错如下： " + e.getMessage());
            return false;
        }
    }
}
