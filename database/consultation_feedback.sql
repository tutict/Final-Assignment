-- Existing databases can apply this without recreating traffic_management.
-- status 只允许 Pending / Processing / Resolved / Completed。
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
);
