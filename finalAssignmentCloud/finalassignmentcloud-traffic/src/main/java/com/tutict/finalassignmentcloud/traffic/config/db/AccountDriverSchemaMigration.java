package com.tutict.finalassignmentcloud.traffic.config.db;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class AccountDriverSchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(AccountDriverSchemaMigration.class.getName());
    private static final String DRIVER_TABLE = "driver_information";
    private static final String AUTH_USER_COLUMN = "auth_user_id";
    private static final String AUTH_USER_INDEX = "uk_driver_information_auth_user";
    private static final String BUSINESS_DRIVER_COLUMN = "driver_id";

    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;

    public AccountDriverSchemaMigration(DataSource dataSource, JdbcTemplate jdbcTemplate) {
        this.dataSource = dataSource;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void afterPropertiesSet() {
        try (Connection connection = dataSource.getConnection()) {
            if (!tableExists(connection, DRIVER_TABLE)) {
                LOG.log(Level.INFO, "Skip account-driver migration because table {0} does not exist.", DRIVER_TABLE);
                return;
            }
            addColumnIfMissing(connection, DRIVER_TABLE, AUTH_USER_COLUMN,
                    "BIGINT NULL COMMENT 'Linked sys_user.user_id'");
            relaxDraftDriverProfileColumns(connection);
            addIndexIfMissing(connection, DRIVER_TABLE, AUTH_USER_INDEX, AUTH_USER_COLUMN, true);
            migrateDriverBusinessLinks(connection);
        } catch (SQLException ex) {
            throw new IllegalStateException("Failed to inspect account-driver schema", ex);
        } catch (RuntimeException ex) {
            throw new IllegalStateException("Failed to migrate account-driver schema", ex);
        }
    }

    private void migrateDriverBusinessLinks(Connection connection) throws SQLException {
        addBusinessDriverLink(connection, "vehicle_information", "idx_vehicle_information_driver");
        addBusinessDriverLink(connection, "fine_record", "idx_fine_record_driver");
        addBusinessDriverLink(connection, "payment_record", "idx_payment_record_driver");
        addBusinessDriverLink(connection, "appeal_record", "idx_appeal_record_driver");
        backfillBusinessDriverLinks(connection);
    }

    private void addBusinessDriverLink(Connection connection, String tableName, String indexName) throws SQLException {
        if (!tableExists(connection, tableName)) {
            return;
        }
        addColumnIfMissing(connection, tableName, BUSINESS_DRIVER_COLUMN,
                "BIGINT NULL COMMENT 'Linked driver_information.driver_id'");
        addIndexIfMissing(connection, tableName, indexName, BUSINESS_DRIVER_COLUMN, false);
    }

    private void addColumnIfMissing(Connection connection, String tableName, String columnName, String definition)
            throws SQLException {
        if (columnExists(connection, tableName, columnName)) {
            return;
        }
        jdbcTemplate.execute("ALTER TABLE " + tableName + " ADD COLUMN " + columnName + " " + definition);
        LOG.log(Level.INFO, "Added {0}.{1}.", new Object[]{tableName, columnName});
    }

    private void relaxDraftDriverProfileColumns(Connection connection) throws SQLException {
        relaxColumnIfPresent(connection, DRIVER_TABLE, "id_card_number",
                "VARCHAR(18) NULL COMMENT 'Identity card number'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "gender",
                "ENUM('Male','Female','Other') NULL COMMENT 'Gender'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "birthdate",
                "DATE NULL COMMENT 'Birth date'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "driver_license_number",
                "VARCHAR(50) NULL COMMENT 'Driver license number'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "license_type",
                "VARCHAR(10) NULL COMMENT 'Permitted vehicle type'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "first_license_date",
                "DATE NULL COMMENT 'First license date'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "issue_date",
                "DATE NULL COMMENT 'License issue date'");
        relaxColumnIfPresent(connection, DRIVER_TABLE, "expiry_date",
                "DATE NULL COMMENT 'License expiry date'");
    }

    private void relaxColumnIfPresent(Connection connection, String tableName, String columnName, String definition)
            throws SQLException {
        if (!columnExists(connection, tableName, columnName)) {
            return;
        }
        jdbcTemplate.execute("ALTER TABLE " + tableName + " MODIFY COLUMN " + columnName + " " + definition);
        LOG.log(Level.INFO, "Relaxed {0}.{1} for draft driver profiles.", new Object[]{tableName, columnName});
    }

    private void addIndexIfMissing(Connection connection, String tableName, String indexName,
                                   String columnName, boolean unique) throws SQLException {
        if (indexExists(connection, tableName, indexName)) {
            return;
        }
        String uniquePrefix = unique ? "UNIQUE " : "";
        jdbcTemplate.execute("CREATE " + uniquePrefix + "INDEX " + indexName
                + " ON " + tableName + " (" + columnName + ")");
        LOG.log(Level.INFO, "Added index {0} on {1}.{2}.", new Object[]{indexName, tableName, columnName});
    }

    private void backfillBusinessDriverLinks(Connection connection) throws SQLException {
        if (tableExists(connection, "fine_record") && tableExists(connection, "offense_record")) {
            jdbcTemplate.update("""
                    UPDATE fine_record fr
                    SET driver_id = (
                        SELECT off.driver_id
                        FROM offense_record off
                        WHERE off.offense_id = fr.offense_id
                    )
                    WHERE fr.driver_id IS NULL
                      AND fr.offense_id IS NOT NULL
                    """);
        }
        if (tableExists(connection, "payment_record") && tableExists(connection, "fine_record")) {
            jdbcTemplate.update("""
                    UPDATE payment_record pr
                    SET driver_id = (
                        SELECT fr.driver_id
                        FROM fine_record fr
                        WHERE fr.fine_id = pr.fine_id
                    )
                    WHERE pr.driver_id IS NULL
                      AND pr.fine_id IS NOT NULL
                    """);
        }
        if (tableExists(connection, "appeal_record") && tableExists(connection, "offense_record")) {
            jdbcTemplate.update("""
                    UPDATE appeal_record ar
                    SET driver_id = (
                        SELECT off.driver_id
                        FROM offense_record off
                        WHERE off.offense_id = ar.offense_id
                    )
                    WHERE ar.driver_id IS NULL
                      AND ar.offense_id IS NOT NULL
                    """);
        }
        if (tableExists(connection, "vehicle_information") && tableExists(connection, "driver_vehicle")) {
            jdbcTemplate.update("""
                    UPDATE vehicle_information vi
                    SET driver_id = (
                        SELECT MIN(dv.driver_id)
                        FROM driver_vehicle dv
                        WHERE dv.vehicle_id = vi.vehicle_id
                          AND (dv.status IS NULL OR dv.status = 'Active')
                    )
                    WHERE vi.driver_id IS NULL
                      AND EXISTS (
                          SELECT 1
                          FROM driver_vehicle dv
                          WHERE dv.vehicle_id = vi.vehicle_id
                            AND (dv.status IS NULL OR dv.status = 'Active')
                      )
                    """);
        }
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
}
