-- Rollback: Remove default values

ALTER TABLE sys_request_history
    MODIFY COLUMN request_method VARCHAR(20) NOT NULL,
    MODIFY COLUMN request_url VARCHAR(500) NOT NULL,
    MODIFY COLUMN business_type VARCHAR(50) NOT NULL;
