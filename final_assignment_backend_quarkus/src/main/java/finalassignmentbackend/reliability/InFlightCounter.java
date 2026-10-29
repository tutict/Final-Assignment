package finalassignmentbackend.reliability;

import jakarta.enterprise.context.ApplicationScoped;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 全局在飞请求计数。
 *
 * <p>数值本身没有业务含义，只用于负载拒流：并发超过连接池容量时读请求与账务写入会被拒掉。
 */
@ApplicationScoped
public class InFlightCounter {

    private final AtomicInteger inFlight = new AtomicInteger();

    void enter() {
        inFlight.incrementAndGet();
    }

    void exit() {
        inFlight.decrementAndGet();
    }

    int value() {
        return inFlight.get();
    }
}
