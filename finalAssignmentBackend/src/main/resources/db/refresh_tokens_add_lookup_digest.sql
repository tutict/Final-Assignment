-- 迁移：为 refresh_tokens 添加 lookup_digest 列，实现 O(1) 令牌查找。
-- lookup_digest 是 token 的 HMAC-SHA-256 摘要，用于快速定位对应行。
-- 旧行（无 digest）在首次使用时通过 backfill 补全。
-- 回滚：ALTER TABLE refresh_tokens DROP COLUMN lookup_digest;

ALTER TABLE refresh_tokens ADD COLUMN lookup_digest CHAR(64) NULL AFTER token;
CREATE UNIQUE INDEX idx_refresh_tokens_lookup_digest ON refresh_tokens (lookup_digest);