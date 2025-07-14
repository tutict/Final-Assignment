package finalassignmentbackend.config.vertx;

import finalassignmentbackend.config.NetWorkHandler;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Vertx;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.inject.spi.BeanManager;
import jakarta.inject.Inject;

import java.util.logging.Level;
import java.util.logging.Logger;

// Quarkus配置类，用于管理Vert.x实例和NetWorkHandler的部署
@ApplicationScoped
public class VertxConfig {

    // 日志记录器，用于记录Vert.x实例和NetWorkHandler的生命周期信息
    private static final Logger log = Logger.getLogger(VertxConfig.class.getName());

    // 注入Vertx实例
    @Inject
    Vertx vertx;

    // 注入NetWorkHandler实例
    @Inject
    NetWorkHandler netWorkHandler;

    // 启动方法，在Quarkus应用启动时调用
    public void start(@Observes @Priority(1) jakarta.enterprise.context.Initialized.ApplicationScoped event, BeanManager beanManager) {
        log.log(Level.INFO, "正在启动Vert.x实例...");
        try {
            // 配置部署选项，设置实例数为1
            DeploymentOptions deploymentOptions = new DeploymentOptions().setInstances(1);
            vertx.deployVerticle(netWorkHandler, deploymentOptions, result -> {
                if (result.succeeded()) {
                    log.log(Level.INFO, "NetWorkHandler部署成功: {0}", result.result());
                } else {
                    log.log(Level.SEVERE, "NetWorkHandler部署失败: {0}", result.cause().getMessage());
                }
            });
        } catch (Exception e) {
            log.log(Level.SEVERE, "NetWorkHandler启动过程中发生异常: {0}", e.getMessage());
        }
    }

    // 关闭方法，在Quarkus应用销毁时调用
    public void shutdown(@Observes jakarta.enterprise.context.BeforeDestroyed.ApplicationScoped event, BeanManager beanManager) {
        vertx.close(ar -> {
            if (ar.succeeded()) {
                log.log(Level.INFO, "Vert.x实例关闭成功。");
            } else {
                log.log(Level.SEVERE, "Vert.x实例关闭失败: {0}", ar.cause().getMessage());
            }
        });
    }
}