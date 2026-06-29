package com.tutict.finalassignmentcloud.config.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

@DisplayName("InternalServiceTokenFilter 行为测试")
class InternalServiceTokenFilterTest {

    private static final String TOKEN = "a-very-strong-internal-token-123456";

    private InternalServiceTokenFilter filter() {
        return new InternalServiceTokenFilter(TOKEN);
    }

    private boolean[] call(InternalServiceTokenFilter filter, MockHttpServletRequest req) throws Exception {
        MockHttpServletResponse res = new MockHttpServletResponse();
        boolean[] chained = {false};
        FilterChain chain = (request, response) -> chained[0] = true;
        filter.doFilter(req, res, chain);
        // status 默认 200；被拒时 filter 设 401
        boolean blocked = res.getStatus() == 401;
        return new boolean[]{chained[0], blocked};
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
    @DisplayName("internal 路径 + 正确 token：放行")
    void internalPathWithValidTokenPasses() throws Exception {
        InternalServiceTokenFilter f = filter();
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/users/internal/search/username/alice");
        req.addHeader(InternalServiceTokenFilter.HEADER, TOKEN);

        boolean[] result = call(f, req);

        assertThat(result[0]).isTrue();   // chain 被调用
        assertThat(result[1]).isFalse();  // 未被 block
    }

    @Test
    @DisplayName("internal 路径 + 缺失 token：401")
    void internalPathMissingTokenBlocked() throws Exception {
        InternalServiceTokenFilter f = filter();
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/users/internal/search/username/alice");

        boolean[] result = call(f, req);

        assertThat(result[0]).isFalse();
        assertThat(result[1]).isTrue();
    }

    @Test
    @DisplayName("internal 路径 + 错误 token：401")
    void internalPathWrongTokenBlocked() throws Exception {
        InternalServiceTokenFilter f = filter();
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/users/internal/search/username/alice");
        req.addHeader(InternalServiceTokenFilter.HEADER, "wrong-token");

        boolean[] result = call(f, req);

        assertThat(result[0]).isFalse();
        assertThat(result[1]).isTrue();
    }

    @Test
    @DisplayName("非 internal 路径：无 token 也放行")
    void nonInternalPathPassesWithoutToken() throws Exception {
        InternalServiceTokenFilter f = filter();
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/users/search/username/alice");

        boolean[] result = call(f, req);

        assertThat(result[0]).isTrue();
        assertThat(result[1]).isFalse();
    }
}
