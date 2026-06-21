-- Migration: Add default values to request history
-- Purpose: Handle missing data gracefully

ALTER TABLE sys_request_history
    MODIFY COLUMN request_method VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN' COMMENT 'HTTP method',
    MODIFY COLUMN request_url VARCHAR(500) NOT NULL DEFAULT '' COMMENT 'Request URL',
    MODIFY COLUMN business_type VARCHAR(50) NOT NULL DEFAULT 'GENERAL' COMMENT 'Business operation type';

-- Update existing NULL values
UPDATE sys_request_history SET request_method = 'UNKNOWN' WHERE request_method IS NULL OR request_method = '';
UPDATE sys_request_history SET request_url = '' WHERE request_url IS NULL;
UPDATE sys_request_history SET business_type = 'GENERAL' WHERE business_type IS NULL OR business_type = '';
