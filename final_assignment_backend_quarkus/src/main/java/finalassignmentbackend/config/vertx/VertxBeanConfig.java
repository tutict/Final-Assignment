package finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

// Quarkus配置类，用于定义Vertx和NetWorkHandler的Bean
@ApplicationScoped
public class VertxBeanConfig {


    // 创建Vertx实例
    @Produces
    @ApplicationScoped
    public Vertx vertx() {
        return Vertx.vertx();
    }

}