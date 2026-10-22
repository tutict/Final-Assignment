package com.tutict.finalassignmentcloud.auth.config.login.jwt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.tutict.finalassignmentcloud.auth.config.PublicEndpoints;
import com.tutict.finalassignmentcloud.auth.reliability.BlacklistAccessPolicy;
import com.tutict.finalassignmentcloud.auth.service.TokenBlacklistService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletResponse;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class JwtAuthenticationFilterTest {

    private ch.qos.logback.classic.Logger filterLogger;
    private ListAppender<ILoggingEvent> appender;

    @BeforeEach
    void attachAppender() {
        filterLogger = (ch.qos.logback.classic.Logger) LoggerFactory.getLogger(JwtAuthenticationFilter.class);
        appender = new ListAppender<>();
        appender.start();
        filterLogger.addAppender(appender);
    }

    @AfterEach
    void detachAppender() {
        filterLogger.detachAppender(appender);
        appender.stop();
    }

    @Test
    void publicEndpointWithoutTokenDoesNotWarn() throws Exception {
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(
                mock(TokenProvider.class), null, null, new PublicEndpoints());
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, mock(FilterChain.class));

        assertTrue(warnings().isEmpty(), () -> "unexpected warnings: " + warnings());
    }

    @Test
    void protectedEndpointWithoutTokenStillWarns() throws Exception {
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(
                mock(TokenProvider.class), null, null, new PublicEndpoints());
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/payments");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, mock(FilterChain.class));

        assertEquals(1, warnings().size());
        assertTrue(warnings().get(0).contains("/api/payments"), warnings().get(0));
    }

    @Test
    void revokedTokenIsStillRejected() throws Exception {
        TokenBlacklistService blacklistService = mock(TokenBlacklistService.class);
        when(blacklistService.inspect("revoked-token")).thenReturn(BlacklistAccessPolicy.Verdict.REVOKED);
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(
                mock(TokenProvider.class), blacklistService, null, new PublicEndpoints());
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/payments");
        request.addHeader("Authorization", "Bearer revoked-token");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, mock(FilterChain.class));

        assertEquals(HttpServletResponse.SC_UNAUTHORIZED, response.getStatus());
    }

    private List<String> warnings() {
        return appender.list.stream()
                .filter(event -> event.getLevel() == Level.WARN)
                .map(ILoggingEvent::getFormattedMessage)
                .toList();
    }
}
