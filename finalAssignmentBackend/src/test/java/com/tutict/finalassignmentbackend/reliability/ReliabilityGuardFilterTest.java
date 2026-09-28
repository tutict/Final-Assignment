package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.tutict.finalassignmentbackend.service.auth.TokenBlacklistService;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.servlet.FilterChain;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class ReliabilityGuardFilterTest {

    @Test
    void loginAndRefreshReturn503WhenRedisIsDown() throws Exception {
        ReliabilityGuardFilter filter = filter(false);
        assertShed(filter, "POST", "/api/auth/login");
        assertShed(filter, "POST", "/api/auth/refresh");
    }

    @Test
    void ordinaryGetContinuesWhenRedisIsDown() throws Exception {
        ReliabilityGuardFilter filter = filter(false);
        MockHttpServletResponse response = new MockHttpServletResponse();
        boolean[] continued = {false};
        filter.doFilter(request("GET", "/api/offenses/1"), response, (req, res) -> continued[0] = true);
        assertThat(continued[0]).isTrue();
        assertThat(response.getStatus()).isNotEqualTo(503);
    }

    @Test
    void ledgerPostWithoutIdempotencyKeyIs400() throws Exception {
        ReliabilityGuardFilter filter = filter(true);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request("POST", "/api/payments"), response, (req, res) -> {
            throw new AssertionError("ledger post without key should stop");
        });
        assertThat(response.getStatus()).isEqualTo(400);
        assertThat(response.getContentAsString()).contains("MISSING_HEADER");
    }


    @Test
    void appealDecisionWithoutKeyIs400() throws Exception {
        ReliabilityGuardFilter filter = filter(true);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request("PUT", "/api/appeals/4"), response, (req, res) -> {
            throw new AssertionError("appeal decision without key should stop");
        });
        assertThat(response.getStatus()).isEqualTo(400);
        MockHttpServletRequest present = request("PUT", "/api/appeals/4");
        present.addHeader("Idempotency-Key", "appeal-decision-1");
        MockHttpServletResponse continued = new MockHttpServletResponse();
        boolean[] called = {false};
        filter.doFilter(present, continued, (req, res) -> called[0] = true);
        assertThat(called[0]).isTrue();
    }
    private static void assertShed(ReliabilityGuardFilter filter, String method, String path) throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request(method, path), response, (req, res) -> {
            throw new AssertionError("should shed");
        });
        assertThat(response.getStatus()).isEqualTo(503);
        assertThat(response.getHeader("Retry-After")).isEqualTo("1");
    }

    private static MockHttpServletRequest request(String method, String path) {
        return new MockHttpServletRequest(method, path);
    }

    @SuppressWarnings("unchecked")
    private static ReliabilityGuardFilter filter(boolean redisUp) {
        TokenBlacklistService blacklist = mock(TokenBlacklistService.class);
        when(blacklist.redisReachable()).thenReturn(redisUp);
        ObjectProvider<TokenBlacklistService> blacklistProvider = mock(ObjectProvider.class);
        when(blacklistProvider.getIfAvailable()).thenReturn(blacklist);
        ObjectProvider<DataSource> dataSource = mock(ObjectProvider.class);
        return new ReliabilityGuardFilter(false, dataSource, new ReliabilityMetrics(new SimpleMeterRegistry()), blacklistProvider);
    }

    @Test
    void responsesAndPoolWaitAreMeasured() throws Exception {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        ReliabilityMetrics metrics = new ReliabilityMetrics(registry);
        ReliabilityGuardFilter filter = filterWith(true, metrics);
        filter.doFilter(request("POST", "/api/payments"), new MockHttpServletResponse(), (req, res) -> {
            throw new AssertionError("missing key");
        });
        filter.doFilter(request("GET", "/api/offenses/1"), new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(200));
        filter.doFilter(request("GET", "/api/offenses/2"), new MockHttpServletResponse(), (req, res) -> ((MockHttpServletResponse) res).setStatus(500));
        assertThat(registry.get("http_responses_4xx_total").counter().count()).isEqualTo(1d);
        assertThat(registry.get("http_responses_2xx_total").counter().count()).isEqualTo(1d);
        assertThat(registry.get("http_responses_5xx_total").counter().count()).isEqualTo(1d);

        ObjectProvider<DataSource> dataSource = mock(ObjectProvider.class);
        when(dataSource.getIfAvailable()).thenReturn(null);
        new PoolWaitGauge(registry, dataSource);
        assertThat(registry.get("db_pool_wait_count").gauge().value()).isEqualTo(0d);
    }

    @SuppressWarnings("unchecked")
    private static ReliabilityGuardFilter filterWith(boolean redisUp, ReliabilityMetrics metrics) {
        TokenBlacklistService blacklist = mock(TokenBlacklistService.class);
        when(blacklist.redisReachable()).thenReturn(redisUp);
        ObjectProvider<TokenBlacklistService> blacklistProvider = mock(ObjectProvider.class);
        when(blacklistProvider.getIfAvailable()).thenReturn(blacklist);
        ObjectProvider<DataSource> dataSource = mock(ObjectProvider.class);
        return new ReliabilityGuardFilter(false, dataSource, metrics, blacklistProvider);
    }
}
