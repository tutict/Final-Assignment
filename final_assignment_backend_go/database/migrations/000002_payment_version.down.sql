-- Rollback: Remove version column

DROP INDEX idx_payment_version ON payment_record;
ALTER TABLE payment_record DROP COLUMN version;
