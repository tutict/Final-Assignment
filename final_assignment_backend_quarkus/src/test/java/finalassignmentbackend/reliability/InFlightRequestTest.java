package finalassignmentbackend.reliability;

import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.container.ContainerResponseFilter;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

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

    /**
     * 上面的结构断言只证明了「不用响应过滤器」，没证明真的挂了生命周期回调：把 release()
     * 上的 @PreDestroy 删掉、或者把 Bean 改成 ApplicationScoped，其余用例仍然全绿——它们
     * 都是直接调 release()。这里按容器的方式找到注解并调用，删注解即红。
     */
    @Test
    void releaseIsThePreDestroyHookOfARequestScopedBean() throws Exception {
        assertTrue(
                InFlightRequest.class.isAnnotationPresent(RequestScoped.class),
                "@PreDestroy 只在请求结束时触发，Bean 必须是 @RequestScoped");

        Method release = InFlightRequest.class.getDeclaredMethod("release");
        assertTrue(
                release.isAnnotationPresent(PreDestroy.class),
                "release() 必须带 @PreDestroy，否则容器不会在请求结束时归还名额");

        InFlightCounter counter = new InFlightCounter();
        InFlightRequest request = new InFlightRequest();
        request.counter = counter;

        request.hold();
        assertEquals(1, counter.value());

        release.setAccessible(true);
        release.invoke(request);
        assertEquals(0, counter.value(), "容器销毁时必须把名额还回去");
    }
}
