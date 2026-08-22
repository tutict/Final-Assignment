package com.tutict.finalassignmentbackend.config.websocket;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Service
public class WsTicketService {

    private static final Duration TICKET_TTL = Duration.ofSeconds(30);

    // ticket keyed by ticket value; each ticket knows its owner and session
    private final ConcurrentMap<String, Ticket> tickets = new ConcurrentHashMap<>();
    // per-user mapping of active (unconsumed) ticket values
    private final ConcurrentMap<String, ConcurrentMap<String, Long>> ticketsByUser = new ConcurrentHashMap<>();

    public Ticket issue(String username, List<String> roles) {
        return issue(username, roles, null);
    }

    public Ticket issue(String username, List<String> roles, String sessionGeneration) {
        purgeExpired();
        Ticket ticket = new Ticket(
                UUID.randomUUID().toString(),
                username,
                roles == null ? List.of() : List.copyOf(roles),
                sessionGeneration == null ? "" : sessionGeneration,
                Instant.now().plus(TICKET_TTL)
        );
        tickets.put(ticket.value(), ticket);
        ticketsByUser.computeIfAbsent(username, ignored -> new ConcurrentHashMap<>())
                .put(ticket.value(), Long.valueOf(1));
        return ticket;
    }

    public Ticket consume(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        Ticket ticket = tickets.remove(value);
        if (ticket == null) {
            return null;
        }
        ConcurrentMap<String, Long> userTickets = ticketsByUser.get(ticket.username());
        if (userTickets != null) {
            userTickets.remove(value);
        }
        if (ticket.expiresAt().isBefore(Instant.now())) {
            return null;
        }
        return ticket;
    }

    /** Revoke all unconsumed tickets for a user (called on logout). */
    public void invalidateUserTickets(String username) {
        if (username == null || username.isBlank()) {
            return;
        }
        ConcurrentMap<String, Long> userTickets = ticketsByUser.remove(username);
        if (userTickets != null) {
            userTickets.keySet().forEach(tickets::remove);
        }
    }

    private void purgeExpired() {
        Instant now = Instant.now();
        tickets.entrySet().removeIf(entry -> {
            if (entry.getValue().expiresAt().isBefore(now)) {
                ConcurrentMap<String, Long> userTickets = ticketsByUser.get(entry.getValue().username());
                if (userTickets != null) {
                    userTickets.remove(entry.getKey());
                }
                return true;
            }
            return false;
        });
    }

    public record Ticket(String value, String username, List<String> roles, String sessionGeneration, Instant expiresAt) {
    }
}