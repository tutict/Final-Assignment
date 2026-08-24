package com.tutict.finalassignmentbackend.ai.rag.query;

import com.tutict.finalassignmentbackend.ai.chat.AiChatService;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rag")
public class RagQueryController {

    private final AiChatService aiChatService;

    public RagQueryController(AiChatService aiChatService) {
        this.aiChatService = aiChatService;
    }

    @PostMapping("/query")
    public ResponseEntity<Map<String, List<RetrievalResult>>> query(@RequestBody RagQueryRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Build a server-side-only query request with auth context
        String username = authentication.getName();
        List<String> roles = authentication.getAuthorities().stream()
                .map(a -> SecurityRoleUtils.normalizeRoleCode(a.getAuthority()))
                .filter(role -> !role.isBlank())
                .toList();

        // userId is the username from security context; department is resolved from roles
        String department = null;
        for (String role : roles) {
            if ("SUPER_ADMIN".equals(role) || "ADMIN".equals(role)) {
                department = "ALL";
                break;
            } else if ("TRAFFIC_POLICE".equals(role) || "FINANCE".equals(role) || "APPEAL_REVIEWER".equals(role)) {
                department = "DEPARTMENT";
                break;
            }
        }

        ServerSideRagQueryRequest serverRequest = new ServerSideRagQueryRequest(
                request.query(),
                request.topK(),
                username,
                roles,
                department
        );
        return ResponseEntity.ok(Map.of("results", aiChatService.retrieve(serverRequest)));
    }
}
