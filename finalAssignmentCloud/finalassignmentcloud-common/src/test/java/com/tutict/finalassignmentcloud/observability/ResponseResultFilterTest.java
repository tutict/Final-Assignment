package com.tutict.finalassignmentcloud.observability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class ResponseResultFilterTest {

    @Test
    void countsStatusUnlessTrafficAlreadyRecordedIt() throws Exception {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        ResponseResultFilter filter = new ResponseResultFilter(meters(registry));
        new PoolWaitGauge(registry, emptyDataSource());

        filter.doFilter(new MockHttpServletRequest("GET", "/api/users"), new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(200));
        MockHttpServletRequest handled = new MockHttpServletRequest("POST", "/api/payments");
        handled.setAttribute(PoolLoadShedFilter.HANDLED, Boolean.TRUE);
        filter.doFilter(handled, new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(500));
        filter.doFilter(new MockHttpServletRequest("GET", "/api/users/9"), new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(404));
        filter.doFilter(new MockHttpServletRequest("GET", "/api/users/down"), new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(503));

        assertEquals(1d, registry.get("http_responses_2xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_4xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_5xx_total").counter().count());
        assertEquals(0d, registry.get("db_pool_wait_count").gauge().value());
    }

    @SuppressWarnings("unchecked")
    private static ObjectProvider<MeterRegistry> meters(MeterRegistry registry) {
        ObjectProvider<MeterRegistry> meters = mock(ObjectProvider.class);
        when(meters.getIfAvailable()).thenReturn(registry);
        return meters;
    }

    @SuppressWarnings("unchecked")
    private static ObjectProvider<javax.sql.DataSource> emptyDataSource() {
        ObjectProvider<javax.sql.DataSource> dataSource = mock(ObjectProvider.class);
        when(dataSource.getIfAvailable()).thenReturn(null);
        return dataSource;
    }
}