package finalassignmentbackend.config.vertx;

import jakarta.enterprise.context.ApplicationScoped;

/**
 * Quarkus 的 {@code quarkus-vertx} 扩展会自动提供 {@code io.vertx.core.Vertx} bean
 * （SYNTHETIC bean），因此这里不再手动 {@code @Produces} 一个 Vertx 实例——
 * 历史代码那样做会导致 "Ambiguous dependencies for type Vertx" 的 CDI 部署错误
 * （自定义 producer 与框架内置 bean 冲突）。需要 Vertx 的地方直接 {@code @Inject} 即可。
 *
 * <p>该类保留为空 {@code @ApplicationScoped} 占位，避免引用它的其它配置类编译失败；
 * 不再产生任何 bean。
 */
@ApplicationScoped
public class VertxBeanConfig {

}
