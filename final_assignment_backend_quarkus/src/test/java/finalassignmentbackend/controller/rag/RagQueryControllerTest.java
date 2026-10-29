package finalassignmentbackend.controller.rag;

import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.service.RagQueryService;
import finalassignmentbackend.rag.service.RagQueryService.RetrievedChunk;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.security.Principal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 检索接口的可见性判定。
 *
 * <p>身份只能来自服务端会话：请求体里自带的 roles / asRole 一律无效。
 */
class RagQueryControllerTest {

    private RagQueryController controller;
    private RecordingRag rag;

    @BeforeEach
    void setUp() {
        rag = new RecordingRag();
        controller = new RagQueryController();
        controller.ragQueryService = rag;
    }

    @Test
    void rolesInTheRequestBodyAreIgnored() {
        Map<String, Object> request = new LinkedHashMap<>();
        request.put("query", "罚款怎么缴");
        request.put("roles", List.of("SUPER_ADMIN"));
        request.put("asRole", "SUPER_ADMIN");

        controller.query(context("driver-1", Set.of("USER")), request);

        assertEquals(Set.of("USER"), rag.context.roles());
        assertEquals("driver-1", rag.context.userId());
    }

    @Test
    void userIdComesFromTheAuthenticatedPrincipal() {
        Map<String, Object> request = Map.of("query", "罚款怎么缴", "userId", "mallory");

        controller.query(context("driver-1", Set.of("USER")), request);

        assertEquals("driver-1", rag.context.userId());
    }

    @Test
    void topKIsClampedToFifty() {
        controller.query(context("driver-1", Set.of("USER")), Map.of("query", "罚款", "topK", 999));

        assertEquals(50, rag.topK);
    }

    @Test
    void topKBelowOneIsClampedToOne() {
        controller.query(context("driver-1", Set.of("USER")), Map.of("query", "罚款", "topK", 0));

        assertEquals(1, rag.topK);
    }

    @Test
    void missingTopKFallsBackToTheDefault() {
        controller.query(context("driver-1", Set.of("USER")), Map.of("query", "罚款"));

        assertEquals(RagQueryService.DEFAULT_TOP_K, rag.topK);
    }

    @Test
    void blankQueryIsRejected() {
        Response response = controller.query(context("driver-1", Set.of("USER")), Map.of("query", "   "));

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
        ApiResponse<?> body = (ApiResponse<?>) response.getEntity();
        assertEquals("INVALID_QUERY", body.errorCode);
        assertTrue(rag.calls.get() == 0, "the service must not be reached for a blank query");
    }

    @Test
    void missingQueryIsRejected() {
        Response response = controller.query(context("driver-1", Set.of("USER")), Map.of());

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
    }

    @Test
    void resultsAreReturnedWithTheirScores() {
        rag.results = List.of(new RetrievedChunk("c1", "d1", "s1", "罚款应当在十五日内缴纳。",
                "缴款期限", "MANUAL", "/userFineListPage", 1.5));

        Response response = controller.query(context("driver-1", Set.of("USER")), Map.of("query", "罚款"));

        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        ApiResponse<?> body = (ApiResponse<?>) response.getEntity();
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.data;
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> results = (List<Map<String, Object>>) data.get("results");
        assertEquals(1, results.size());
        assertEquals("c1", results.get(0).get("chunkId"));
        assertEquals(1.5, results.get(0).get("finalScore"));
    }

    @Test
    void administratorRoleIsTakenFromTheSession() {
        controller.query(context("admin-1", Set.of("SUPER_ADMIN")), Map.of("query", "罚款"));

        assertEquals(Set.of("SUPER_ADMIN"), rag.context.roles());
        assertEquals("ALL", rag.context.department());
    }

    private static SecurityContext context(String userId, Set<String> roles) {
        Principal principal = () -> userId;
        return new SecurityContext() {
            @Override
            public Principal getUserPrincipal() {
                return principal;
            }

            @Override
            public boolean isUserInRole(String role) {
                return roles.contains(role);
            }

            @Override
            public boolean isSecure() {
                return true;
            }

            @Override
            public String getAuthenticationScheme() {
                return "Bearer";
            }
        };
    }

    private static final class RecordingRag extends RagQueryService {

        private final java.util.concurrent.atomic.AtomicInteger calls = new java.util.concurrent.atomic.AtomicInteger();
        private List<RetrievedChunk> results = List.of();
        private RagAccessContext context;
        private int topK;

        @Override
        public List<RetrievedChunk> retrieve(String query, RagAccessContext context, int topK) {
            calls.incrementAndGet();
            this.context = context;
            this.topK = topK;
            return results;
        }
    }
}
