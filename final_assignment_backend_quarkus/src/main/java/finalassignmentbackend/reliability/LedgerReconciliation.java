package finalassignmentbackend.reliability;

import io.agroal.api.AgroalDataSource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

@ApplicationScoped
public class LedgerReconciliation {

    @Inject
    AgroalDataSource dataSource;

    public int reconcileStaleProcessing() {
        Instant cutoff = Instant.now().minus(2, ChronoUnit.MINUTES);
        String select = "SELECT id, business_type, business_id FROM sys_request_history WHERE business_status = 'PROCESSING' AND updated_at < ?";
        int changed = 0;
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(select)) {
            statement.setTimestamp(1, Timestamp.from(cutoff));
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    long id = rows.getLong("id");
                    String type = rows.getString("business_type");
                    long businessId = rows.getLong("business_id");
                    boolean hasId = !rows.wasNull();
                    boolean exists = hasId && ledgerExists(connection, type, businessId);
                    String next = exists ? "SUCCESS" : "FAILED";
                    try (PreparedStatement update = connection.prepareStatement(
                            "UPDATE sys_request_history SET business_status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND business_status = 'PROCESSING'")) {
                        update.setString(1, next);
                        update.setLong(2, id);
                        changed += update.executeUpdate();
                    }
                }
            }
            return changed;
        } catch (Exception ex) {
            throw new IllegalStateException("Ledger reconciliation failed", ex);
        }
    }

    private static boolean ledgerExists(Connection connection, String businessType, long businessId) throws Exception {
        String table;
        String column;
        String value = businessType == null ? "" : businessType.toUpperCase();
        if (value.startsWith("PAYMENT")) {
            table = "payment_record";
            column = "payment_id";
        } else if (value.startsWith("FINE")) {
            table = "fine_record";
            column = "fine_id";
        } else if (value.startsWith("DEDUCTION")) {
            table = "deduction_record";
            column = "deduction_id";
        } else if (value.startsWith("APPEAL_REVIEW")) {
            table = "appeal_review";
            column = "review_id";
        } else if (value.startsWith("APPEAL")) {
            table = "appeal_record";
            column = "appeal_id";
        } else {
            return false;
        }
        try (PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*) FROM " + table + " WHERE " + column + " = ?")) {
            statement.setLong(1, businessId);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() && result.getInt(1) > 0;
            }
        }
    }
}
