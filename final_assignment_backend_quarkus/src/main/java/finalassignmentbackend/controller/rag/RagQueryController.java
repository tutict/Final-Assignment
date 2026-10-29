package finalassignmentbackend.controller.rag;

import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.rag.service.RagAdminDocumentSupport;
import finalassignmentbackend.rag.service.RagQueryService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Path("/api/rag")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "USER"})
public class RagQueryController {

    @Inject RagQueryService ragQueryService;

    @POST
    @Path("/query")
    @RunOnVirtualThread
    public Response query(Map<String, Object> request) {
        String query = request == null || request.get("query") == null ? "" : String.valueOf(request.get("query")).trim();
        if (query.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_QUERY", "query must not be blank")).build();
        }
        Object roles = request.get("roles");
        String asRole = "USER";
        if (roles instanceof List<?> list && !list.isEmpty()) {
            asRole = String.valueOf(list.get(0));
        } else if (request.get("asRole") != null) {
            asRole = String.valueOf(request.get("asRole"));
        }
        asRole = RagAdminDocumentSupport.normalizePreviewRole(asRole);
        int topK = RagQueryService.DEFAULT_TOP_K;
        if (request.get("topK") instanceof Number number) {
            topK = Math.max(1, Math.min(number.intValue(), RagQueryService.MAX_TOP_K));
        }
        List<Map<String, Object>> results = new ArrayList<>();
        for (RagQueryService.RetrievedChunk chunk : ragQueryService.retrieve(query, asRole, topK)) {
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
}
