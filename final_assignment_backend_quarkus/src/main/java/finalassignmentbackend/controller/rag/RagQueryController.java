package finalassignmentbackend.controller.rag;

import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.service.RagQueryService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Path("/api/rag")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "USER"})
public class RagQueryController {

    @Inject RagQueryService ragQueryService;

    @POST
    @Path("/query")
    @RunOnVirtualThread
    public Response query(@Context SecurityContext securityContext, Map<String, Object> request) {
        String query = request == null || request.get("query") == null ? "" : String.valueOf(request.get("query")).trim();
        if (query.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_QUERY", "query must not be blank")).build();
        }
        int topK = RagQueryService.DEFAULT_TOP_K;
        if (request.get("topK") instanceof Number number) {
            topK = Math.max(1, Math.min(number.intValue(), RagQueryService.MAX_TOP_K));
        }
        List<Map<String, Object>> results = new ArrayList<>();
        for (RagQueryService.RetrievedChunk chunk : ragQueryService.retrieve(query, accessContext(securityContext), topK)) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("chunkId", chunk.chunkId());
            item.put("documentId", chunk.documentId());
            item.put("sourceId", chunk.sourceId());
            item.put("content", chunk.content());
            item.put("title", chunk.title());
            item.put("sourceType", chunk.sourceType());
            item.put("route", chunk.route());
            item.put("finalScore", chunk.finalScore());
            results.add(item);
        }
        return Response.ok(ApiResponse.ok(Map.of("results", results))).build();
    }

    /**
     * 检索身份只来自服务端。
     *
     * <p>请求体里的 roles 与 asRole 会被完全忽略：调用方没有资格声明自己是谁。
     */
    static RagAccessContext accessContext(SecurityContext securityContext) {
        String userId = null;
        Set<String> roles = new LinkedHashSet<>();
        if (securityContext != null) {
            if (securityContext.getUserPrincipal() != null) {
                userId = securityContext.getUserPrincipal().getName();
            }
            for (String role : RagAccessContext.KNOWN_ROLES) {
                if (securityContext.isUserInRole(role)) {
                    roles.add(role);
                }
            }
        }
        return RagAccessContext.of(userId, roles);
    }
}
