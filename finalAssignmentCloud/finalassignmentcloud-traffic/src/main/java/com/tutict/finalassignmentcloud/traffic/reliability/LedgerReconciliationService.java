package com.tutict.finalassignmentcloud.traffic.reliability;

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
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(2);
        List<StaleRow> rows = jdbcTemplate.query(
                "SELECT id, business_type, business_id FROM sys_request_history WHERE business_status = 'PROCESSING' AND updated_at < ?",
                (rs, rowNum) -> {
                    long businessId = rs.getLong("business_id");
                    return new StaleRow(rs.getLong("id"), rs.getString("business_type"), rs.wasNull() ? null : businessId);
                },
                cutoff);
        int changed = 0;
        for (StaleRow row : rows) {
            boolean exists = row.businessId() != null && count(tableFor(row.businessType()), idColumnFor(row.businessType()), row.businessId()) > 0;
            changed += jdbcTemplate.update(
                    "UPDATE sys_request_history SET business_status = ?, updated_at = ? WHERE id = ? AND business_status = 'PROCESSING'",
                    exists ? "SUCCESS" : "FAILED", LocalDateTime.now(), row.id());
        }
        return changed;
    }

    private int count(String table, String column, long id) {
        if (table == null || column == null) {
            return 0;
        }
        Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + table + " WHERE " + column + " = ?", Integer.class, id);
        return count == null ? 0 : count;
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

    static String idColumnFor(String businessType) {
        String table = tableFor(businessType);
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

