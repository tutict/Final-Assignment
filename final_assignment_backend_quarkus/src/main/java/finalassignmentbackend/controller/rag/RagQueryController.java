package finalassignmentbackend.controller.rag;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.service.RagAdminDocumentSupport;
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
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Path("/api/rag")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "USER"})
public class RagQueryController {

    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;

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
        int topK = 5;
        if (request.get("topK") instanceof Number number) {
            topK = Math.max(1, Math.min(number.intValue(), 20));
        }
        List<RagDocument> docs = documentMapper.selectList(new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD")));
        Map<String, RagDocument> allowed = new LinkedHashMap<>();
        List<String> ids = new ArrayList<>();
        for (RagDocument document : docs) {
            if (RagAdminDocumentSupport.isKnowledgeDocument(document) && RagAdminDocumentSupport.previewAllows(asRole, document.getAclScope())) {
                allowed.put(document.getId(), document);
                ids.add(document.getId());
            }
        }
        if (ids.isEmpty()) {
            return Response.ok(ApiResponse.ok(Map.of("results", List.of()))).build();
        }
        List<Map<String, Object>> results = new ArrayList<>();
        List<RagChunk> chunks = chunkMapper.selectList(new QueryWrapper<RagChunk>().in("document_id", ids).orderByAsc("chunk_no"));
        for (RagChunk chunk : chunks) {
            RagDocument document = allowed.get(chunk.getDocumentId());
            if (document == null) continue;
            double score = RagAdminDocumentSupport.keywordScore(query, document.getTitle(), chunk.getContent());
            if (score <= 0) continue;
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("chunkId", chunk.getId());
            item.put("documentId", document.getId());
            item.put("content", chunk.getContent());
            item.put("title", document.getTitle());
            item.put("sourceType", document.getSourceType());
            item.put("route", document.getRoute());
            item.put("finalScore", score);
            results.add(item);
        }
        results.sort(Comparator.comparingDouble(item -> -((Number) item.get("finalScore")).doubleValue()));
        if (results.size() > topK) results = new ArrayList<>(results.subList(0, topK));
        return Response.ok(ApiResponse.ok(Map.of("results", results))).build();
    }
}
