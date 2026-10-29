package finalassignmentbackend.reliability;

import jakarta.ws.rs.container.ContainerResponseFilter;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class InFlightRequestTest {

    @Test
    void slotIsReturnedWhenRequestEnds() {
        InFlightCounter counter = new InFlightCounter();
        InFlightRequest request = new InFlightRequest();
        request.counter = counter;

        request.hold();
        assertEquals(1, counter.value());

        request.release();
        assertEquals(0, counter.value());
    }

    @Test
    void holdingTwiceTakesOneSlot() {
        InFlightCounter counter = new InFlightCounter();
        InFlightRequest request = new InFlightRequest();
        request.counter = counter;

        request.hold();
        request.hold();
        assertEquals(1, counter.value());

        request.release();
        assertEquals(0, counter.value());
    }

    @Test
    void releaseWithoutHoldDoesNotPushCounterNegative() {
        InFlightCounter counter = new InFlightCounter();
        InFlightRequest request = new InFlightRequest();
        request.counter = counter;

        request.release();

        assertEquals(0, counter.value());
    }

    /**
     * 在飞名额不能靠 JAX-RS 响应过滤器归还：流式响应和被拒绝的请求不会执行响应过滤器，
     * 计数只增不减会把读请求永久拒掉。请求作用域 Bean 的 @PreDestroy 才能保证归还。
     */
    @Test
    void loadShedFilterDoesNotPairSlotsWithResponseFilters() {
        assertFalse(ContainerResponseFilter.class.isAssignableFrom(LoadShedFilter.class));
    }
}
