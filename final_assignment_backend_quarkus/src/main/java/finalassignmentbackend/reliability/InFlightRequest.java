package finalassignmentbackend.reliability;

import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;

/**
 * 单个请求占用的在飞名额。
 *
 * <p>Spring 侧用 servlet 过滤器的 finally 块配对「进入/离开」，任何请求（被拒绝的、流式
 * 响应的、客户端中途断开的）都会归还名额。Quarkus 的 JAX-RS 响应过滤器不会在这些路径上
 * 执行，用它配对会让计数只增不减，最后把所有读请求永久拒掉。请求作用域 Bean 在请求结束
 * 时一定被销毁，因此用 {@link PreDestroy} 归还名额不会漏计。
 */
@RequestScoped
public class InFlightRequest {

    @Inject
    InFlightCounter counter;

    private boolean held;

    public void hold() {
        if (held) {
            return;
        }
        held = true;
        counter.enter();
    }

    @PreDestroy
    void release() {
        if (!held) {
            return;
        }
        held = false;
        counter.exit();
    }
}
