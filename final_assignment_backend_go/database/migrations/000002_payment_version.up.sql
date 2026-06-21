-- Migration: Add version column for optimistic locking
-- Purpose: Prevent concurrent update conflicts on payment records

ALTER TABLE payment_record
ADD COLUMN version INT NOT NULL DEFAULT 0 COMMENT 'Version for optimistic locking';

-- Create index for version queries
CREATE INDEX idx_payment_version ON payment_record(version);
