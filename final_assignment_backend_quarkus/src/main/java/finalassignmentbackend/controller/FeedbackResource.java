package finalassignmentbackend.controller;

import io.agroal.api.AgroalDataSource;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Path("/api/feedback")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class FeedbackResource {

    private static final DateTimeFormatter TIMESTAMP = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private static final int MAX_CONTENT = 2000;

    @Inject
    AgroalDataSource dataSource;

    @GET
    public Response list(@Context SecurityContext securityContext) throws Exception {
        String username = username(securityContext);
        String sql = """
                SELECT feedback_id, username, feedback_type, content, contact, status, created_at
                FROM consultation_feedback
                """;
        if (!isStaff(securityContext)) {
            sql += " WHERE username = ?";
        }
        sql += " ORDER BY feedback_id DESC";
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (!isStaff(securityContext)) {
                statement.setString(1, username);
            }
            try (ResultSet rows = statement.executeQuery()) {
                List<Map<String, Object>> items = new ArrayList<>();
                while (rows.next()) {
                    items.add(toResponse(rows));
                }
                return Response.ok(items).build();
            }
        }
    }

    @POST
    public Response create(Map<String, Object> body,
                           @HeaderParam("Idempotency-Key") String idempotencyKey,
                           @Context SecurityContext securityContext) throws Exception {
        String username = username(securityContext);
        String key = blankToNull(idempotencyKey);
        if (key != null) {
            Map<String, Object> existing = findByKey(key);
            if (existing != null) {
                return Response.ok(existing).build();
            }
        }
        String content = firstText(body, "content", "feedback");
        if (content.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("errorCode", "INVALID_ARGUMENT", "message", "反馈内容不能为空"))
                    .build();
        }
        if (content.length() > MAX_CONTENT) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("errorCode", "INVALID_ARGUMENT", "message", "反馈内容过长"))
                    .build();
        }
        String type = firstText(body, "feedbackType", "type");
        if (type.isBlank()) {
            type = "咨询";
        }
        String contact = firstText(body, "contact");
        String status = isStaff(securityContext) ? firstText(body, "status") : "";
        if (status.isBlank()) {
            status = "Pending";
        }
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
                return Response.status(Response.Status.CREATED)
                        .entity(response(id, username, type, content, contact, status, createdAt))
                        .build();
            }
        }
    }

    @PUT
    @Path("/{feedbackId}")
    public Response update(@PathParam("feedbackId") long feedbackId,
                           Map<String, Object> body,
                           @Context SecurityContext securityContext) throws Exception {
        Map<String, Object> current = findById(feedbackId);
        if (current == null) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity(Map.of("errorCode", "NOT_FOUND", "message", "Feedback not found"))
                    .build();
        }
        String username = username(securityContext);
        if (!isStaff(securityContext) && !username.equals(String.valueOf(current.get("username")))) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity(Map.of("errorCode", "FORBIDDEN", "message", "Forbidden"))
                    .build();
        }
        String content = firstText(body, "content", "feedback");
        if (content.isBlank()) {
            content = String.valueOf(current.get("content"));
        }
        String type = firstText(body, "feedbackType");
        if (type.isBlank()) {
            type = String.valueOf(current.get("feedbackType"));
        }
        String contact = body != null && body.containsKey("contact")
                ? firstText(body, "contact")
                : String.valueOf(current.getOrDefault("contact", ""));
        String status = isStaff(securityContext) && !firstText(body, "status").isBlank()
                ? firstText(body, "status")
                : String.valueOf(current.get("status"));
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
        return Response.ok(current).build();
    }

    private Map<String, Object> findByKey(String key) throws Exception {
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

    private Map<String, Object> findById(long id) throws Exception {
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

    private static Map<String, Object> toResponse(ResultSet rows) throws Exception {
        Timestamp createdAt = rows.getTimestamp("created_at");
        return response(rows.getLong("feedback_id"), rows.getString("username"), rows.getString("feedback_type"),
                rows.getString("content"), rows.getString("contact"), rows.getString("status"), createdAt);
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

    private static String username(SecurityContext securityContext) {
        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return "";
        }
        return securityContext.getUserPrincipal().getName();
    }

    private static boolean isStaff(SecurityContext securityContext) {
        return securityContext != null && (securityContext.isUserInRole("ADMIN")
                || securityContext.isUserInRole("SUPER_ADMIN")
                || securityContext.isUserInRole("ROLE_ADMIN")
                || securityContext.isUserInRole("ROLE_SUPER_ADMIN"));
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
}
