package com.tutict.finalassignmentbackend.controller.auth;

import com.tutict.finalassignmentbackend.config.websocket.WsTicketService;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ws-ticket")
public class WsTicketController {

    private final WsTicketService wsTicketService;

    public WsTicketController(WsTicketService wsTicketService) {
        this.wsTicketService = wsTicketService;
    }

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, String>>> issue(Authentication authentication) {
        List<String> roles = authentication.getAuthorities().stream()
                .map(authority -> authority.getAuthority())
                .toList();
        WsTicketService.Ticket ticket = wsTicketService.issue(authentication.getName(), roles);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "ticket", ticket.value(),
                "expiresAt", ticket.expiresAt().toString()
        )));
    }
}