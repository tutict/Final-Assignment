package com.tutict.finalassignmentcloud.auth.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;

/**
 * 免认证端点的唯一事实来源：SecurityConfig 的 permitAll 规则与 JWT 过滤器的日志判定共用同一个匹配器，
 * 避免两处各维护一份路径清单而发生漂移。
 */
public final class PublicEndpoints implements RequestMatcher {

    private final RequestMatcher matcher;

    public PublicEndpoints() {
        this.matcher = new OrRequestMatcher(
                PathPatternRequestMatcher.withDefaults().matcher("/api/auth/**"),
                PathPatternRequestMatcher.withDefaults().matcher("/actuator/health"),
                PathPatternRequestMatcher.withDefaults().matcher("/actuator/health/**"));
    }

    @Override
    public boolean matches(HttpServletRequest request) {
        return matcher.matches(request);
    }
}
