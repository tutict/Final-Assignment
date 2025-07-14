package finalassignmentbackend.config.vertx;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.NetWorkHandler;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.vertx.core.Vertx;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

// Quarkus配置类，用于定义Vertx和NetWorkHandler的Bean
@ApplicationScoped
public class VertxBeanConfig {

    // 注入TokenProvider
    @Inject
    TokenProvider tokenProvider;

    // 注入ObjectMapper
    @Inject
    ObjectMapper objectMapper;

    // 创建Vertx实例
    @Produces
    @ApplicationScoped
    public Vertx vertx() {
        return Vertx.vertx();
    }

    // 创建NetWorkHandler实例
    @Produces
    @ApplicationScoped
    public NetWorkHandler netWorkHandler() {
        return new NetWorkHandler(tokenProvider, objectMapper);
    }
}