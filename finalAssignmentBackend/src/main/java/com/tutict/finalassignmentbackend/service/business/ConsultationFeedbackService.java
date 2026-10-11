package com.tutict.finalassignmentbackend.service.business;

import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.reliability.IdempotencyConflictException;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ConsultationFeedbackService {

    static final int MAX_CONTENT = 2000;
    static final int MAX_KEY = 128;
    private static final DateTimeFormatter TIMESTAMP = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private static final Set<String> STATUSES = Set.of("Pending", "Processing", "Resolved", "Completed");
    private static final String ENSURE_TABLE = """
            CREATE TABLE IF NOT EXISTS consultation_feedback (
                feedback_id BIGINT NOT NULL AUTO_INCREMENT,
                username VARCHAR(128) NOT NULL,
                feedback_type VARCHAR(32) NOT NULL DEFAULT '咨询',
                content VARCHAR(2000) NOT NULL,
                contact VARCHAR(128) NULL,
                status VARCHAR(32) NOT NULL DEFAULT 'Pending',
                idempotency_key VARCHAR(128) NULL,
                created_at DATETIME NOT NULL,
                PRIMARY KEY (feedback_id),
                UNIQUE KEY uk_feedback_idempotency (idempotency_key)
            )
            """;

    private final JdbcTemplate jdbcTemplate;

    public ConsultationFeedbackService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void ensureTable() {
        jdbcTemplate.execute(ENSURE_TABLE);
    }

    public static boolean isStaffRole(String authority) {
        if (authority == null || authority.isBlank()) {
            return false;
        }
        String role = authority.startsWith("ROLE_") ? authority.substring("ROLE_".length()) : authority;
        return "ADMIN".equals(role) || "SUPER_ADMIN".equals(role);
    }

    public List<Map<String, Object>> list(String username, boolean staff) {
        if (staff) {
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

    public SavedFeedback create(String username, boolean staff, Map<String, Object> body, String idempotencyKey) {
        String key = blankToNull(idempotencyKey);
        if (key != null && key.codePointCount(0, key.length()) > MAX_KEY) {
            throw new IllegalArgumentException("幂等键过长");
        }
        if (key != null) {
            Map<String, Object> existing = findByKey(key);
            if (existing != null) {
                return new SavedFeedback(replay(existing, username), false);
            }
        }
        String content = requiredContent(firstText(body, "content", "feedback"));
        String type = firstText(body, "feedbackType", "type");
        if (type.isBlank()) {
            type = "咨询";
        }
        String contact = firstText(body, "contact");
        String status = normalizeStatus(firstText(body, "status"), staff, "Pending");
        Timestamp createdAt = Timestamp.valueOf(LocalDateTime.now());
        KeyHolder keys = new GeneratedKeyHolder();
        final String storedType = type;
        final String storedContent = content;
        final String storedStatus = status;
        final String storedKey = key;
        final String storedContact = blankToNull(contact);
        try {
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
        } catch (DataIntegrityViolationException ex) {
            if (key == null) {
                throw ex;
            }
            Map<String, Object> existing = findByKey(key);
            if (existing != null) {
                return new SavedFeedback(replay(existing, username), false);
            }
            // 并发窗口内唯一键被占用但回查不到行：仍按幂等冲突处理，避免 5xx。
            throw new IdempotencyConflictException("幂等键已被使用");
        }
        Number id = keys.getKey();
        return new SavedFeedback(toResponse(id == null ? 0L : id.longValue(), username, type, content, contact, status, createdAt), true);
    }

    public Map<String, Object> update(String username, boolean staff, long feedbackId, Map<String, Object> body) {
        Map<String, Object> current = findById(feedbackId);
        String owner = String.valueOf(current.get("username"));
        if (!staff && !username.equals(owner)) {
            throw new AccessDeniedException("Forbidden");
        }
        String content = firstText(body, "content", "feedback");
        if (content.isBlank()) {
            content = String.valueOf(current.get("content"));
        } else {
            content = requiredContent(content);
        }
        String type = firstText(body, "feedbackType");
        if (type.isBlank()) {
            type = String.valueOf(current.get("feedbackType"));
        }
        String contact = body != null && body.containsKey("contact")
                ? firstText(body, "contact")
                : String.valueOf(current.getOrDefault("contact", ""));
        String status = normalizeStatus(firstText(body, "status"), staff, String.valueOf(current.get("status")));
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

    private Map<String, Object> replay(Map<String, Object> existing, String username) {
        if (!username.equals(String.valueOf(existing.get("username")))) {
            throw new IdempotencyConflictException("幂等键已被使用");
        }
        return existing;
    }

    private Map<String, Object> findByKey(String key) {
        return jdbcTemplate.query("""
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                WHERE idempotency_key = ?
                """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                rs.getString("status"), rs.getTimestamp("created_at")), key)
                .stream().findFirst().orElse(null);
    }

    private Map<String, Object> findById(long feedbackId) {
        return jdbcTemplate.query("""
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                WHERE feedback_id = ?
                """, (rs, row) -> toResponse(rs.getLong("feedback_id"), rs.getString("username"),
                rs.getString("feedback_type"), rs.getString("content"), rs.getString("contact"),
                rs.getString("status"), rs.getTimestamp("created_at")), feedbackId)
                .stream().findFirst()
                .orElseThrow(() -> new EntityNotFoundException("Feedback not found"));
    }

    static String requiredContent(String content) {
        if (content == null || content.isBlank()) {
            throw new IllegalArgumentException("反馈内容不能为空");
        }
        String trimmed = content.trim();
        if (trimmed.codePointCount(0, trimmed.length()) > MAX_CONTENT) {
            throw new IllegalArgumentException("反馈内容过长");
        }
        return trimmed;
    }

    static String normalizeStatus(String requested, boolean staff, String fallback) {
        if (!staff || requested == null || requested.isBlank()) {
            return fallback == null || fallback.isBlank() ? "Pending" : fallback;
        }
        if (!STATUSES.contains(requested)) {
            throw new IllegalArgumentException("反馈状态不合法");
        }
        return requested;
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

    public static final class SavedFeedback {
        private final Map<String, Object> body;
        private final boolean created;

        public SavedFeedback(Map<String, Object> body, boolean created) {
            this.body = body;
            this.created = created;
        }

        public Map<String, Object> body() { return body; }
        public boolean created() { return created; }
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
