package com.tutict.finalassignmentcloud.auth.controller;

import com.tutict.finalassignmentcloud.auth.config.websocket.WsTicketService;
import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.dto.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * WebSocket 连接票据签发接口。
 *
 * 前端先用 Bearer 令牌换取一次性票据，再用票据建立 /eventbus/websocket 连接，
 * 避免把长期令牌放进 WebSocket 握手 URL。
 */
@RestController
@RequestMapping("/api/ws-ticket")
@Tag(name = "WebSocket", description = "WebSocket 连接票据接口")
public class WsTicketController {

    private final WsTicketService wsTicketService;

    public WsTicketController(WsTicketService wsTicketService) {
        this.wsTicketService = wsTicketService;
    }

    @PostMapping
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "签发 WebSocket 连接票据", description = "票据有效期 30 秒且只能被消费一次")
    public ResponseEntity<ApiResponse<Map<String, String>>> issue(Authentication authentication) {
        if (!SecurityRoleUtils.isAuthenticated(authentication)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("UNAUTHORIZED", "Unauthorized"));
        }
        List<String> roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
        WsTicketService.Ticket ticket = wsTicketService.issue(authentication.getName(), roles);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "ticket", ticket.value(),
                "expiresAt", ticket.expiresAt().toString())));
    }
}
