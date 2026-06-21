package com.tutict.finalassignmentcloud.config.db;

import com.tutict.finalassignmentcloud.config.security.crypto.SensitiveDataCryptoService;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class SensitiveDataSchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(SensitiveDataSchemaMigration.class.getName());
    private static final String CIPHERTEXT_DEFINITION = "TEXT NULL COMMENT 'Encrypted sensitive value'";
    private static final String BLIND_INDEX_DEFINITION = "VARCHAR(128) NULL COMMENT 'Blind index for exact sensitive lookup'";

    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;
    private final SensitiveDataCryptoService cryptoService;

    public SensitiveDataSchemaMigration(
            DataSource dataSource,
            JdbcTemplate jdbcTemplate,
            SensitiveDataCryptoService cryptoService
    ) {
        this.dataSource = dataSource;
        this.jdbcTemplate = jdbcTemplate;
        this.cryptoService = cryptoService;
    }

    @Override
    public void afterPropertiesSet() {
        try (Connection connection = dataSource.getConnection()) {
            migrateTable(connection, "driver_information", "driver_id", List.of(
                    new SensitiveColumn("id_card_number", "id_card_number_ciphertext",
                            "id_card_number_blind_index", "idx_driver_id_card_bidx"),
                    new SensitiveColumn("contact_number", "contact_number_ciphertext",
                            "contact_number_blind_index", "idx_driver_contact_bidx")
            ));
            migrateTable(connection, "vehicle_information", "vehicle_id", List.of(
                    new SensitiveColumn("owner_id_card", "owner_id_card_ciphertext",
                            "owner_id_card_blind_index", "idx_vehicle_owner_id_bidx"),
                    new SensitiveColumn("owner_contact", "owner_contact_ciphertext",
                            "owner_contact_blind_index", "idx_vehicle_owner_contact_bidx")
            ));
            migrateTable(connection, "payment_record", "payment_id", List.of(
                    new SensitiveColumn("payer_id_card", "payer_id_card_ciphertext",
                            "payer_id_card_blind_index", "idx_payment_payer_id_bidx"),
                    new SensitiveColumn("payer_contact", "payer_contact_ciphertext",
                            "payer_contact_blind_index", "idx_payment_payer_contact_bidx"),
                    new SensitiveColumn("bank_account", "bank_account_ciphertext",
                            "bank_account_blind_index", "idx_payment_bank_bidx")
            ));
            migrateTable(connection, "appeal_record", "appeal_id", List.of(
                    new SensitiveColumn("appellant_id_card", "appellant_id_card_ciphertext",
                            "appellant_id_card_blind_index", "idx_appeal_appellant_id_bidx"),
                    new SensitiveColumn("appellant_contact", "appellant_contact_ciphertext",
                            "appellant_contact_blind_index", "idx_appeal_appellant_contact_bidx")
            ));
        } catch (SQLException ex) {
            throw new IllegalStateException("Failed to inspect sensitive-data schema", ex);
        } catch (RuntimeException ex) {
            throw new IllegalStateException("Failed to migrate sensitive-data schema", ex);
        }
    }

    private void migrateTable(Connection connection, String tableName, String idColumn, List<SensitiveColumn> columns)
            throws SQLException {
        if (!tableExists(connection, tableName)) {
            LOG.log(Level.INFO, "Skip sensitive-data migration because table {0} does not exist.", tableName);
            return;
        }
        for (SensitiveColumn column : columns) {
            if (!columnExists(connection, tableName, column.plaintextColumn())) {
                continue;
            }
            addColumnIfMissing(connection, tableName, column.ciphertextColumn(), CIPHERTEXT_DEFINITION);
            addColumnIfMissing(connection, tableName, column.blindIndexColumn(), BLIND_INDEX_DEFINITION);
            addIndexIfMissing(connection, tableName, column.indexName(), column.blindIndexColumn());
            backfillColumn(tableName, idColumn, column);
        }
    }

    private void addColumnIfMissing(Connection connection, String tableName, String columnName, String definition)
            throws SQLException {
        if (columnExists(connection, tableName, columnName)) {
            return;
        }
        jdbcTemplate.execute("ALTER TABLE " + tableName + " ADD COLUMN " + columnName + " " + definition);
        LOG.log(Level.INFO, "Added {0}.{1}.", new Object[]{tableName, columnName});
    }

    private void addIndexIfMissing(Connection connection, String tableName, String indexName, String columnName)
            throws SQLException {
        if (indexExists(connection, tableName, indexName)) {
            return;
        }
        jdbcTemplate.execute("CREATE INDEX " + indexName + " ON " + tableName + " (" + columnName + ")");
        LOG.log(Level.INFO, "Added index {0} on {1}.{2}.", new Object[]{indexName, tableName, columnName});
    }

    private void backfillColumn(String tableName, String idColumn, SensitiveColumn column) {
        String selectSql = "SELECT " + idColumn + ", " + column.plaintextColumn()
                + " FROM " + tableName
                + " WHERE " + column.plaintextColumn() + " IS NOT NULL"
                + " AND " + column.plaintextColumn() + " <> ''"
                + " AND (" + column.ciphertextColumn() + " IS NULL"
                + " OR " + column.blindIndexColumn() + " IS NULL)";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(selectSql);
        int updated = 0;
        for (Map<String, Object> row : rows) {
            Object id = getValue(row, idColumn);
            String plaintext = Objects.toString(getValue(row, column.plaintextColumn()), null);
            if (id == null || !StringUtils.hasText(plaintext)) {
                continue;
            }
            String trimmed = plaintext.trim();
            String ciphertext = cryptoService.isEnabled() ? cryptoService.encrypt(trimmed) : null;
            String blindIndex = cryptoService.blindIndex(trimmed);
            if (ciphertext == null && blindIndex == null) {
                continue;
            }
            updated += updateBackfill(tableName, idColumn, id, column, ciphertext, blindIndex);
        }
        if (updated > 0) {
            LOG.log(Level.INFO, "Backfilled {0}.{1} for {2} row(s).",
                    new Object[]{tableName, column.plaintextColumn(), updated});
        }
    }

    private int updateBackfill(String tableName,
                               String idColumn,
                               Object id,
                               SensitiveColumn column,
                               String ciphertext,
                               String blindIndex) {
        if (ciphertext != null && blindIndex != null) {
            return jdbcTemplate.update(
                    "UPDATE " + tableName
                            + " SET " + column.ciphertextColumn() + " = ?, "
                            + column.blindIndexColumn() + " = ?"
                            + " WHERE " + idColumn + " = ?"
                            + " AND (" + column.ciphertextColumn() + " IS NULL"
                            + " OR " + column.blindIndexColumn() + " IS NULL)",
                    ciphertext,
                    blindIndex,
                    id
            );
        }
        if (ciphertext != null) {
            return jdbcTemplate.update(
                    "UPDATE " + tableName
                            + " SET " + column.ciphertextColumn() + " = ?"
                            + " WHERE " + idColumn + " = ?"
                            + " AND " + column.ciphertextColumn() + " IS NULL",
                    ciphertext,
                    id
            );
        }
        return jdbcTemplate.update(
                "UPDATE " + tableName
                        + " SET " + column.blindIndexColumn() + " = ?"
                        + " WHERE " + idColumn + " = ?"
                        + " AND " + column.blindIndexColumn() + " IS NULL",
                blindIndex,
                id
        );
    }

    private Object getValue(Map<String, Object> row, String columnName) {
        for (Map.Entry<String, Object> entry : row.entrySet()) {
            if (entry.getKey().equalsIgnoreCase(columnName)) {
                return entry.getValue();
            }
        }
        return null;
    }

    private boolean tableExists(Connection connection, String tableName) throws SQLException {
        DatabaseMetaData metaData = connection.getMetaData();
        return hasTable(metaData, connection.getCatalog(), tableName)
                || hasTable(metaData, connection.getCatalog(), tableName.toUpperCase(Locale.ROOT));
    }

    private boolean hasTable(DatabaseMetaData metaData, String catalog, String tableName) throws SQLException {
        try (ResultSet resultSet = metaData.getTables(catalog, null, tableName, new String[]{"TABLE"})) {
            return resultSet.next();
        }
    }

    private boolean columnExists(Connection connection, String tableName, String columnName) throws SQLException {
        DatabaseMetaData metaData = connection.getMetaData();
        return hasColumn(metaData, connection.getCatalog(), tableName, columnName)
                || hasColumn(metaData, connection.getCatalog(), tableName.toUpperCase(Locale.ROOT), columnName)
                || hasColumn(metaData, connection.getCatalog(), tableName, columnName.toUpperCase(Locale.ROOT));
    }

    private boolean hasColumn(DatabaseMetaData metaData, String catalog, String tableName, String columnName)
            throws SQLException {
        try (ResultSet resultSet = metaData.getColumns(catalog, null, tableName, columnName)) {
            return resultSet.next();
        }
    }

    private boolean indexExists(Connection connection, String tableName, String indexName) throws SQLException {
        DatabaseMetaData metaData = connection.getMetaData();
        try (ResultSet resultSet = metaData.getIndexInfo(connection.getCatalog(), null, tableName, false, false)) {
            while (resultSet.next()) {
                String currentName = resultSet.getString("INDEX_NAME");
                if (indexName.equalsIgnoreCase(currentName)) {
                    return true;
                }
            }
        }
        return false;
    }

    private record SensitiveColumn(
            String plaintextColumn,
            String ciphertextColumn,
            String blindIndexColumn,
            String indexName
    ) {
    }
}
