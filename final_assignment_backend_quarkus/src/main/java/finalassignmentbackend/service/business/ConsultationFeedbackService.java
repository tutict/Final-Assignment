package finalassignmentbackend.service.business;

import io.agroal.api.AgroalDataSource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@ApplicationScoped
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

    private final AgroalDataSource dataSource;

    @Inject
    public ConsultationFeedbackService(AgroalDataSource dataSource) {
        this.dataSource = dataSource;
    }

    public void ensureTable() throws SQLException {
        try (Connection connection = dataSource.getConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(ENSURE_TABLE);
        }
    }

    public static boolean isStaffRole(String authority) {
        if (authority == null || authority.isBlank()) {
            return false;
        }
        String role = authority.startsWith("ROLE_") ? authority.substring("ROLE_".length()) : authority;
        return "ADMIN".equals(role) || "SUPER_ADMIN".equals(role);
    }

    public List<Map<String, Object>> list(String username, boolean staff) throws SQLException {
        String sql = """
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                """;
        if (!staff) {
            sql += " WHERE username = ?";
        }
        sql += " ORDER BY feedback_id DESC";
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (!staff) {
                statement.setString(1, username);
            }
            try (ResultSet rows = statement.executeQuery()) {
                List<Map<String, Object>> items = new ArrayList<>();
                while (rows.next()) {
                    items.add(toResponse(rows));
                }
                return items;
            }
        }
    }

    public SavedFeedback create(String username, boolean staff, Map<String, Object> body, String idempotencyKey)
            throws SQLException {
        String key = blankToNull(idempotencyKey);
        if (key != null && key.codePointCount(0, key.length()) > MAX_KEY) {
            throw new FeedbackRequestException(400, "INVALID_ARGUMENT", "幂等键过长");
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
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("""
                     INSERT INTO consultation_feedback
                         (username, feedback_type, content, contact, status, idempotency_key, created_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?)
                     """, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, username);
            statement.setString(2, type);
            statement.setString(3, content);
            statement.setString(4, blankToNull(contact));
            statement.setString(5, status);
            statement.setString(6, key);
            statement.setTimestamp(7, createdAt);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                long id = keys.next() ? keys.getLong(1) : 0L;
                return new SavedFeedback(response(id, username, type, content, contact, status, createdAt), true);
            }
        } catch (SQLException ex) {
            if (key != null && isDuplicate(ex)) {
                Map<String, Object> existing = findByKey(key);
                if (existing != null) {
                    return new SavedFeedback(replay(existing, username), false);
                }
                // 并发窗口内唯一键被占用但回查不到行：仍按幂等冲突处理，避免 5xx。
                throw new FeedbackRequestException(409, "IDEMPOTENCY_CONFLICT", "幂等键已被使用");
            }
            throw ex;
        }
    }

    public Map<String, Object> update(String username, boolean staff, long feedbackId, Map<String, Object> body)
            throws SQLException {
        Map<String, Object> current = findById(feedbackId);
        if (current == null) {
            throw new FeedbackRequestException(404, "NOT_FOUND", "Feedback not found");
        }
        String owner = String.valueOf(current.get("username"));
        if (!staff && !username.equals(owner)) {
            throw new FeedbackRequestException(403, "FORBIDDEN", "Forbidden");
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
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("""
                     UPDATE consultation_feedback
                     SET feedback_type = ?, content = ?, contact = ?, status = ?
                     WHERE feedback_id = ?
                     """)) {
            statement.setString(1, type);
            statement.setString(2, content);
            statement.setString(3, blankToNull(contact));
            statement.setString(4, status);
            statement.setLong(5, feedbackId);
            statement.executeUpdate();
        }
        current.put("feedbackType", type);
        current.put("content", content);
        current.put("feedback", content);
        current.put("contact", contact);
        current.put("status", status);
        return current;
    }

    private Map<String, Object> replay(Map<String, Object> existing, String username) {
        if (!username.equals(String.valueOf(existing.get("username")))) {
            throw new FeedbackRequestException(409, "IDEMPOTENCY_CONFLICT", "幂等键已被使用");
        }
        return existing;
    }

    private Map<String, Object> findByKey(String key) throws SQLException {
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("""
                     SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                     FROM consultation_feedback WHERE idempotency_key = ?
                     """)) {
            statement.setString(1, key);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? toResponse(rows) : null;
            }
        }
    }

    private Map<String, Object> findById(long id) throws SQLException {
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("""
                     SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                     FROM consultation_feedback WHERE feedback_id = ?
                     """)) {
            statement.setLong(1, id);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? toResponse(rows) : null;
            }
        }
    }

    private static boolean isDuplicate(Throwable error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof SQLException sql) {
                if (sql.getErrorCode() == 1062) {
                    return true;
                }
                SQLException next = sql.getNextException();
                if (next != null && next != sql && isDuplicate(next)) {
                    return true;
                }
            }
            Throwable cause = current.getCause();
            if (cause == null || cause == current) {
                return false;
            }
            current = cause;
        }
        return false;
    }

    static String requiredContent(String content) {
        if (content == null || content.isBlank()) {
            throw new FeedbackRequestException(400, "INVALID_ARGUMENT", "反馈内容不能为空");
        }
        String trimmed = content.trim();
        if (trimmed.codePointCount(0, trimmed.length()) > MAX_CONTENT) {
            throw new FeedbackRequestException(400, "INVALID_ARGUMENT", "反馈内容过长");
        }
        return trimmed;
    }

    static String normalizeStatus(String requested, boolean staff, String fallback) {
        if (!staff || requested == null || requested.isBlank()) {
            return fallback == null || fallback.isBlank() ? "Pending" : fallback;
        }
        if (!STATUSES.contains(requested)) {
            throw new FeedbackRequestException(400, "INVALID_ARGUMENT", "反馈状态不合法");
        }
        return requested;
    }

    private static Map<String, Object> toResponse(ResultSet rows) throws SQLException {
        return response(rows.getLong("feedback_id"), rows.getString("username"), rows.getString("feedback_type"),
                rows.getString("content"), rows.getString("contact"), rows.getString("status"),
                rows.getTimestamp("created_at"));
    }

    private static Map<String, Object> response(long id, String username, String type, String content,
                                                String contact, String status, Timestamp createdAt) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("feedbackId", id);
        row.put("username", username);
        row.put("feedbackType", type);
        row.put("content", content);
        row.put("feedback", content);
        row.put("contact", contact == null ? "" : contact);
        row.put("status", status);
        row.put("timestamp", createdAt == null ? "" : createdAt.toLocalDateTime().format(TIMESTAMP));
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

    public static final class SavedFeedback {
        private final Map<String, Object> body;
        private final boolean created;

        public SavedFeedback(Map<String, Object> body, boolean created) {
            this.body = body;
            this.created = created;
        }

        public Map<String, Object> body() {
            return body;
        }

        public boolean created() {
            return created;
        }
    }

    public static final class FeedbackRequestException extends RuntimeException {
        private final int status;
        private final String code;

        public FeedbackRequestException(int status, String code, String message) {
            super(message);
            this.status = status;
            this.code = code;
        }

        public int status() {
            return status;
        }

        public String code() {
            return code;
        }
    }
}
