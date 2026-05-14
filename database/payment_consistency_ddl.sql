SET @payment_version_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'payment_record'
      AND column_name = 'version'
);
SET @payment_version_ddl := IF(
    @payment_version_exists = 0,
    'ALTER TABLE payment_record ADD COLUMN version INT NOT NULL DEFAULT 0 COMMENT ''optimistic lock version''',
    'SELECT 1'
);
PREPARE payment_version_stmt FROM @payment_version_ddl;
EXECUTE payment_version_stmt;
DEALLOCATE PREPARE payment_version_stmt;

SET @idempotency_key_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'sys_request_history'
      AND index_name = 'uk_idempotency_key'
);
SET @idempotency_key_ddl := IF(
    @idempotency_key_exists = 0,
    'ALTER TABLE sys_request_history ADD UNIQUE KEY uk_idempotency_key (idempotency_key)',
    'SELECT 1'
);
PREPARE idempotency_key_stmt FROM @idempotency_key_ddl;
EXECUTE idempotency_key_stmt;
DEALLOCATE PREPARE idempotency_key_stmt;
