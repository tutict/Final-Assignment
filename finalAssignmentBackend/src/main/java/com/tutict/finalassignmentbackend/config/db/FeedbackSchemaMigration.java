package com.tutict.finalassignmentbackend.config.db;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class FeedbackSchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(FeedbackSchemaMigration.class.getName());

    private final JdbcTemplate jdbcTemplate;

    public FeedbackSchemaMigration(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void afterPropertiesSet() {
        jdbcTemplate.execute("""
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
                """);
        LOG.log(Level.INFO, "Ensured consultation_feedback table exists.");
    }
}
