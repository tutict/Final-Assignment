package com.tutict.finalassignmentbackend.config.db;

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
public class RequestHistorySchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(RequestHistorySchemaMigration.class.getName());
    private static final String TABLE = "sys_request_history";

    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;

    public RequestHistorySchemaMigration(DataSource dataSource, JdbcTemplate jdbcTemplate) {
        this.dataSource = dataSource;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void afterPropertiesSet() {
        try (Connection connection = dataSource.getConnection()) {
            if (!tableExists(connection, TABLE)) {
                LOG.log(Level.INFO, "Skip request-history migration because table {0} does not exist.", TABLE);
                return;
            }
            applyDefault(connection, "request_method", "'UNKNOWN'",
                    "VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN' COMMENT 'Request method'");
            applyDefault(connection, "request_url", "''",
                    "VARCHAR(500) NOT NULL DEFAULT '' COMMENT 'Request URL'");
            applyDefault(connection, "business_type", "'GENERAL'",
                    "VARCHAR(50) NOT NULL DEFAULT 'GENERAL' COMMENT 'Business type'");
        } catch (SQLException ex) {
            throw new IllegalStateException("Failed to inspect request-history schema", ex);
        } catch (RuntimeException ex) {
            throw new IllegalStateException("Failed to migrate request-history schema", ex);
        }
    }

    private void applyDefault(Connection connection, String columnName, String defaultExpression, String definition)
            throws SQLException {
        if (!columnExists(connection, TABLE, columnName)) {
            return;
        }
        jdbcTemplate.execute("UPDATE " + TABLE
                + " SET " + columnName + " = " + defaultExpression
                + " WHERE " + columnName + " IS NULL");
        jdbcTemplate.execute("ALTER TABLE " + TABLE
                + " MODIFY COLUMN " + columnName + " " + definition);
        LOG.log(Level.INFO, "Ensured default for {0}.{1}.", new Object[]{TABLE, columnName});
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
}
