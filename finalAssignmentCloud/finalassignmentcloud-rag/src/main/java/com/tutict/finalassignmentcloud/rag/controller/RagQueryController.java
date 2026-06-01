package com.tutict.finalassignmentcloud.rag.controller;

import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.dto.response.ApiResponse;
import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;
import com.tutict.finalassignmentcloud.rag.ai.query.RagQueryRequest;
import com.tutict.finalassignmentcloud.rag.ai.query.RagQueryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rag")
@Tag(name = "RAG Query", description = "RAG retrieval APIs")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER", "USER"})
public class RagQueryController {

    private final ObjectProvider<RagQueryService> queryServiceProvider;
    private final boolean retrievalEnabled;

    public RagQueryController(ObjectProvider<RagQueryService> queryServiceProvider,
                              @Value("${rag.retrieval.enabled:false}") boolean retrievalEnabled) {
        this.queryServiceProvider = queryServiceProvider;
        this.retrievalEnabled = retrievalEnabled;
    }

    @PostMapping("/query")
    @Operation(summary = "Retrieve RAG chunks by query")
    public ResponseEntity<ApiResponse<Map<String, List<RetrievalResult>>>> query(
            @RequestBody RagQueryRequest request,
            Authentication authentication
    ) {
        RagQueryService queryService = queryServiceProvider.getIfAvailable();
        if (!retrievalEnabled || queryService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_RETRIEVAL_DISABLED", "RAG retrieval is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(Map.of("results", queryService.query(withAuthentication(request, authentication)))));
    }

    private static RagQueryRequest withAuthentication(RagQueryRequest request, Authentication authentication) {
        RagQueryRequest safeRequest = request == null
                ? new RagQueryRequest("", null, null, List.of(), null)
                : request;
        if (authentication == null) {
            return safeRequest;
        }
        List<String> roles = safeRequest.roles().isEmpty()
                ? authentication.getAuthorities().stream()
                .map(authority -> SecurityRoleUtils.normalizeRoleCode(authority.getAuthority()))
                .filter(role -> !role.isBlank())
                .toList()
                : safeRequest.roles();
        String userId = safeRequest.userId() == null || safeRequest.userId().isBlank()
                ? authentication.getName()
                : safeRequest.userId();
        return new RagQueryRequest(
                safeRequest.query(),
                safeRequest.topK(),
                userId,
                roles,
                safeRequest.department()
        );
    }
}
