package com.tutict.finalassignmentbackend.reliability;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class LedgerReconciliationService {

    private final JdbcTemplate jdbcTemplate;

    public LedgerReconciliationService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public int reconcileStaleProcessing() {
        LocalDateTime cutoff = LocalDateTime.now().minus(LedgerIdempotencyDecider.PROCESSING_TTL);
        List<StaleRow> rows = jdbcTemplate.query(
                "SELECT id, business_type, business_id FROM sys_request_history WHERE business_status = 'PROCESSING' AND updated_at < ?",
                (rs, rowNum) -> new StaleRow(rs.getLong("id"), rs.getString("business_type"), readLongOrNull(rs, "business_id")),
                cutoff);
        int changed = 0;
        for (StaleRow row : rows) {
            boolean exists = row.businessId() != null && ledgerRowExists(row.businessType(), row.businessId());
            String next = exists ? "SUCCESS" : "FAILED";
            changed += jdbcTemplate.update(
                    "UPDATE sys_request_history SET business_status = ?, updated_at = ? WHERE id = ? AND business_status = 'PROCESSING'",
                    next, LocalDateTime.now(), row.id());
        }
        return changed;
    }

    static Long readLongOrNull(ResultSet rs, String column) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private boolean ledgerRowExists(String businessType, long businessId) {
        String table = tableFor(businessType);
        String idColumn = idColumnFor(table);
        if (table == null || idColumn == null) {
            return false;
        }
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM " + table + " WHERE " + idColumn + " = ?",
                Integer.class,
                businessId);
        return count != null && count > 0;
    }

    static String tableFor(String businessType) {
        if (businessType == null) {
            return null;
        }
        String value = businessType.toUpperCase();
        if (value.startsWith("PAYMENT")) return "payment_record";
        if (value.startsWith("FINE")) return "fine_record";
        if (value.startsWith("DEDUCTION")) return "deduction_record";
        if (value.startsWith("APPEAL_REVIEW")) return "appeal_review";
        if (value.startsWith("APPEAL")) return "appeal_record";
        return null;
    }

    static String idColumnFor(String table) {
        if (table == null) {
            return null;
        }
        return switch (table) {
            case "payment_record" -> "payment_id";
            case "fine_record" -> "fine_id";
            case "deduction_record" -> "deduction_id";
            case "appeal_record" -> "appeal_id";
            case "appeal_review" -> "review_id";
            default -> "id";
        };
    }

    private record StaleRow(long id, String businessType, Long businessId) {}
}
