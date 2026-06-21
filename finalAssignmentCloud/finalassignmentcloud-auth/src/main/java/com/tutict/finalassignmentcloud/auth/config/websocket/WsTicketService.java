package com.tutict.finalassignmentcloud.auth.config.websocket;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Service
public class WsTicketService {

    private static final Duration TICKET_TTL = Duration.ofSeconds(30);

    private final ConcurrentMap<String, Ticket> tickets = new ConcurrentHashMap<>();

    public Ticket issue(String username, List<String> roles) {
        purgeExpired();
        Ticket ticket = new Ticket(
                UUID.randomUUID().toString(),
                username,
                roles == null ? List.of() : List.copyOf(roles),
                Instant.now().plus(TICKET_TTL)
        );
        tickets.put(ticket.value(), ticket);
        return ticket;
    }

    public Ticket consume(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        Ticket ticket = tickets.remove(value);
        if (ticket == null || ticket.expiresAt().isBefore(Instant.now())) {
            return null;
        }
        return ticket;
    }

    private void purgeExpired() {
        Instant now = Instant.now();
        tickets.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
    }

    public record Ticket(String value, String username, List<String> roles, Instant expiresAt) {
    }
}
