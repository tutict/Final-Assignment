package com.tutict.finalassignmentcloud.config.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.servlet.FilterChain;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

@DisplayName("InternalServiceTokenFilter 行为测试")
class InternalServiceTokenFilterTest {

    private static final String TOKEN = "a-very-strong-internal-token-123456";
    private static final String INTERNAL_PATH = "/api/users/internal/authentication/username/alice";

    private InternalServiceTokenFilter filter() {
        return new InternalServiceTokenFilter(TOKEN);
    }

    private MockHttpServletResponse call(InternalServiceTokenFilter filter, MockHttpServletRequest req)
            throws Exception {
        MockHttpServletResponse res = new MockHttpServletResponse();
        boolean[] chained = {false};
        FilterChain chain = (request, response) -> chained[0] = true;
        filter.doFilter(req, res, chain);
        res.setHeader("X-Chained", Boolean.toString(chained[0]));
        return res;
    }

    @BeforeEach
    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    private static MockHttpServletRequest request(String uri) {
        return new MockHttpServletRequest("GET", uri);
    }

    private static void assertInternalIdentity() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        assertThat(authentication).isNotNull();
        assertThat(authentication.getName()).isEqualTo(InternalServiceTokenFilter.INTERNAL_PRINCIPAL);
        assertThat(authentication.getAuthorities())
                .extracting("authority")
                .containsExactlyInAnyOrder("ROLE_INTERNAL", "INTERNAL");
    }

    @Test
    @DisplayName("构造时空/弱 token 抛异常（fail-fast）")
    void rejectsWeakOrMissingToken() {
        assertThatThrownBy(() -> new InternalServiceTokenFilter(""))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new InternalServiceTokenFilter("changeme"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("internal 路径 + 正确 token：放行并授予内部身份")
    void internalPathWithValidTokenPasses() throws Exception {
        MockHttpServletRequest req = request(INTERNAL_PATH);
        req.addHeader(InternalServiceTokenFilter.HEADER, TOKEN);

        MockHttpServletResponse res = call(filter(), req);

        assertThat(res.getHeader("X-Chained")).isEqualTo("true");
        assertThat(res.getStatus()).isEqualTo(200);
        assertInternalIdentity();
    }

    @Test
    @DisplayName("internal 路径 + 缺失 token：401 且不进入业务链")
    void internalPathMissingTokenBlocked() throws Exception {
        MockHttpServletResponse res = call(filter(), request(INTERNAL_PATH));

        assertThat(res.getHeader("X-Chained")).isEqualTo("false");
        assertThat(res.getStatus()).isEqualTo(401);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    @DisplayName("internal 路径 + 错误 token：401")
    void internalPathWrongTokenBlocked() throws Exception {
        MockHttpServletRequest req = request(INTERNAL_PATH);
        req.addHeader(InternalServiceTokenFilter.HEADER, "wrong-token");

        MockHttpServletResponse res = call(filter(), req);

        assertThat(res.getHeader("X-Chained")).isEqualTo("false");
        assertThat(res.getStatus()).isEqualTo(401);
    }

    @Test
    @DisplayName("非 internal 路径：无 token 也放行")
    void nonInternalPathPassesWithoutToken() throws Exception {
        MockHttpServletResponse res = call(filter(), request("/api/users/search/username/alice"));

        assertThat(res.getHeader("X-Chained")).isEqualTo("true");
        assertThat(res.getStatus()).isEqualTo(200);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    @DisplayName("内部令牌不会把终端用户提权成管理员")
    void internalTokenNeverGrantsAdministrativeAuthorities() throws Exception {
        MockHttpServletRequest req = request("/api/users");
        req.addHeader(InternalServiceTokenFilter.HEADER, TOKEN);

        call(filter(), req);

        assertInternalIdentity();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getAuthorities())
                .noneMatch(authority -> authority.toString().contains("ADMIN"));
    }

    @Test
    @DisplayName("已有终端用户身份时，内部令牌不覆盖该身份")
    void internalTokenKeepsTheEndUserIdentityOnUserFacingPaths() throws Exception {
        Authentication endUser = new UsernamePasswordAuthenticationToken("alice", null,
                List.of(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(endUser);
        MockHttpServletRequest req = request("/api/users");
        req.addHeader(InternalServiceTokenFilter.HEADER, TOKEN);

        call(filter(), req);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isSameAs(endUser);
    }

    @Test
    @DisplayName("internal 路径一律按内部服务身份执行")
    void internalPathOverridesTheEndUserIdentity() throws Exception {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "alice", null, List.of(new SimpleGrantedAuthority("ROLE_USER"))));
        MockHttpServletRequest req = request(INTERNAL_PATH);
        req.addHeader(InternalServiceTokenFilter.HEADER, TOKEN);

        call(filter(), req);

        assertInternalIdentity();
    }

    @Test
    @DisplayName("百分号编码的 internal 段同样要求内部令牌")
    void percentEncodedInternalSegmentIsBlocked() throws Exception {
        MockHttpServletResponse res = call(filter(), request("/api/users/%69nternal/authentication/username/alice"));

        assertThat(res.getStatus()).isEqualTo(401);
    }

    @Test
    @DisplayName("矩阵参数与相对路径不能绕过内部令牌校验")
    void obfuscatedInternalPathsAreBlocked() throws Exception {
        List<String> obfuscated = List.of(
                "/api/users/internal;x=1/authentication/username/alice",
                "/api/users//internal/authentication/username/alice",
                "/api/users/./internal/authentication/username/alice",
                "/api/users/x/../internal/authentication/username/alice",
                "/api/users/%2e%2e/internal/authentication/username/alice",
                "/api/users/%69nternal%2f/authentication/username/alice");

        for (String uri : obfuscated) {
            MockHttpServletResponse res = call(filter(), request(uri));

            assertThat(res.getStatus()).as(uri).isEqualTo(401);
            assertThat(res.getHeader("X-Chained")).as(uri).isEqualTo("false");
        }
    }

    @Test
    @DisplayName("上下文路径前缀会被剥离后再判断")
    void contextPathIsStrippedBeforeMatching() throws Exception {
        MockHttpServletRequest req = request("/svc/api/users/internal/authentication/username/alice");
        req.setContextPath("/svc");

        MockHttpServletResponse res = call(filter(), req);

        assertThat(res.getStatus()).isEqualTo(401);
    }
}
