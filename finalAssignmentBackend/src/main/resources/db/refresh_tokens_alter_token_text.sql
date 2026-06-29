-- 迁移：refresh_tokens.token 由 BCrypt 哈希改为 ML-KEM 信封密文（~2KB），需扩列。
-- 既有 BCrypt 哈希行无法解密，部署后旧 refresh token 全部失效，用户需重新登录。
-- 开发库可先执行：TRUNCATE TABLE refresh_tokens;
ALTER TABLE refresh_tokens MODIFY COLUMN token TEXT NOT NULL;
