package finalassignmentbackend.controller;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsTicketService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.util.List;
import java.util.Map;

@Path("/api/ws-ticket")
@Produces(MediaType.APPLICATION_JSON)
public class WsTicketController {

    @Inject
    WsTicketService wsTicketService;

    @Inject
    TokenProvider tokenProvider;

    @POST
    @RunOnVirtualThread
    public Response issue(@HeaderParam("Authorization") String authorization,
                          @Context SecurityContext securityContext) {
        String token = extractBearerToken(authorization);
        if (token != null && tokenProvider.validateToken(token)) {
            WsTicketService.Ticket ticket = wsTicketService.issue(
                    tokenProvider.getUsernameFromToken(token),
                    tokenProvider.extractRoles(token)
            );
            return Response.ok(ticketPayload(ticket)).build();
        }

        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return Response.status(Response.Status.UNAUTHORIZED).build();
        }
        WsTicketService.Ticket ticket = wsTicketService.issue(securityContext.getUserPrincipal().getName(), knownRoles(securityContext));
        return Response.ok(ticketPayload(ticket)).build();
    }

    private Map<String, String> ticketPayload(WsTicketService.Ticket ticket) {
        return Map.of(
                "ticket", ticket.value(),
                "expiresAt", ticket.expiresAt().toString()
        );
    }

    private String extractBearerToken(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        return authorization.substring(7);
    }

    private List<String> knownRoles(SecurityContext securityContext) {
        return List.of("SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER", "USER").stream()
                .filter(securityContext::isUserInRole)
                .toList();
    }
}