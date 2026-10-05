package com.tutict.finalassignmentcloud.traffic.controller;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/feedback")
public class FeedbackController {

    private static final DateTimeFormatter TIMESTAMP = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private static final int MAX_CONTENT = 2000;

    private final JdbcTemplate jdbcTemplate;

    public FeedbackController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public List<Map<String, Object>> list(Authentication authentication) {
        String username = authentication.getName();
        if (isStaff(authentication)) {
            return jdbcTemplate.query("""
                    SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                    FROM consultation_feedback
                    ORDER BY feedback_id DESC
                    """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                    rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                    rs.getString("status"), rs.getTimestamp("created_at")));
        }
        return jdbcTemplate.query("""
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                WHERE username = ?
                ORDER BY feedback_id DESC
                """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                rs.getString("status"), rs.getTimestamp("created_at")), username);
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(
            @RequestBody Map<String, Object> body,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            Authentication authentication) {
        String username = authentication.getName();
        String key = blankToNull(idempotencyKey);
        if (key != null) {
            List<Map<String, Object>> existing = jdbcTemplate.query("""
                    SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                    FROM consultation_feedback
                    WHERE idempotency_key = ?
                    """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                    rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                    rs.getString("status"), rs.getTimestamp("created_at")), key);
            if (!existing.isEmpty()) {
                return ResponseEntity.ok(existing.get(0));
            }
        }
        String content = firstText(body, "content", "feedback");
        if (content.isBlank()) {
            throw new IllegalArgumentException("反馈内容不能为空");
        }
        if (content.length() > MAX_CONTENT) {
            throw new IllegalArgumentException("反馈内容过长");
        }
        String type = firstText(body, "feedbackType", "type");
        if (type.isBlank()) {
            type = "咨询";
        }
        String contact = firstText(body, "contact");
        String status = isStaff(authentication) ? firstText(body, "status") : "";
        if (status.isBlank()) {
            status = "Pending";
        }
        Timestamp createdAt = Timestamp.valueOf(LocalDateTime.now());
        String storedContact = blankToNull(contact);
        final String storedType = type;
        final String storedContent = content;
        final String storedStatus = status;
        final String storedKey = key;
        KeyHolder keys = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement statement = connection.prepareStatement("""
                    INSERT INTO consultation_feedback
                        (username, feedback_type, content, contact, status, idempotency_key, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, Statement.RETURN_GENERATED_KEYS);
            statement.setString(1, username);
            statement.setString(2, storedType);
            statement.setString(3, storedContent);
            statement.setString(4, storedContact);
            statement.setString(5, storedStatus);
            statement.setString(6, storedKey);
            statement.setTimestamp(7, createdAt);
            return statement;
        }, keys);
        Number id = keys.getKey();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(toResponse(id == null ? 0L : id.longValue(), username, type, content, contact, status, createdAt));
    }

    @PutMapping("/{feedbackId}")
    public Map<String, Object> update(
            @PathVariable long feedbackId,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {
        Map<String, Object> current = jdbcTemplate.query("""
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                WHERE feedback_id = ?
                """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                rs.getString("status"), rs.getTimestamp("created_at")), feedbackId)
                .stream().findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Feedback not found"));
        String owner = String.valueOf(current.get("username"));
        if (!isStaff(authentication) && !authentication.getName().equals(owner)) {
            throw new org.springframework.security.access.AccessDeniedException("Forbidden");
        }
        String content = firstText(body, "content", "feedback");
        if (content.isBlank()) {
            content = String.valueOf(current.get("content"));
        }
        String type = firstText(body, "feedbackType");
        if (type.isBlank()) {
            type = String.valueOf(current.get("feedbackType"));
        }
        String contact = body.containsKey("contact") ? firstText(body, "contact") : String.valueOf(current.getOrDefault("contact", ""));
        String status = isStaff(authentication) && !firstText(body, "status").isBlank()
                ? firstText(body, "status")
                : String.valueOf(current.get("status"));
        jdbcTemplate.update("""
                UPDATE consultation_feedback
                SET feedback_type = ?, content = ?, contact = ?, status = ?
                WHERE feedback_id = ?
                """, type, content, blankToNull(contact), status, feedbackId);
        current.put("feedbackType", type);
        current.put("content", content);
        current.put("feedback", content);
        current.put("contact", contact);
        current.put("status", status);
        return current;
    }

    private static Map<String, Object> toResponse(long id, String username, String type, String content,
                                                   String contact, String status, Timestamp createdAt) {
        Map<String, Object> row = new LinkedHashMap<>();
        String created = createdAt == null ? "" : createdAt.toLocalDateTime().format(TIMESTAMP);
        row.put("feedbackId", id);
        row.put("username", username);
        row.put("feedbackType", type);
        row.put("content", content);
        row.put("feedback", content);
        row.put("contact", contact == null ? "" : contact);
        row.put("status", status);
        row.put("timestamp", created);
        return row;
    }

    private static String firstText(Map<String, Object> body, String... keys) {
        if (body == null) {
            return "";
        }
        for (String key : keys) {
            Object value = body.get(key);
            if (value != null && !String.valueOf(value).isBlank()) {
                return String.valueOf(value).trim();
            }
        }
        return "";
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static boolean isStaff(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            String role = authority.getAuthority();
            if (role != null && (role.contains("ADMIN") || role.contains("STAFF"))) {
                return true;
            }
        }
        return false;
    }
}
