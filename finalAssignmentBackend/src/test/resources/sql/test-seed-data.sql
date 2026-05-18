CREATE TABLE IF NOT EXISTS sys_role (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_code VARCHAR(64) NOT NULL,
    role_name VARCHAR(128) NOT NULL,
    role_type VARCHAR(32) NULL,
    role_description VARCHAR(255) NULL,
    data_scope VARCHAR(64) NULL,
    status VARCHAR(32) NULL,
    sort_order INT NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL,
    UNIQUE KEY uk_sys_role_role_code (role_code)
);

CREATE TABLE IF NOT EXISTS sys_user (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NULL,
    real_name VARCHAR(100) NULL,
    id_card_number VARCHAR(32) NULL,
    gender VARCHAR(32) NULL,
    contact_number VARCHAR(32) NULL,
    email VARCHAR(128) NULL,
    department VARCHAR(128) NULL,
    position VARCHAR(128) NULL,
    employee_number VARCHAR(64) NULL,
    status VARCHAR(32) NULL,
    account_expiry_date DATE NULL,
    login_failures INT NULL,
    last_login_time DATETIME NULL,
    last_login_ip VARCHAR(64) NULL,
    password_update_time DATETIME NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL,
    UNIQUE KEY uk_sys_user_username (username)
);

CREATE TABLE IF NOT EXISTS sys_user_role (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL,
    created_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    UNIQUE KEY uk_sys_user_role_user_role (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    token VARCHAR(255) NOT NULL,
    user_id BIGINT NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    INDEX idx_refresh_tokens_user_revoked (user_id, revoked),
    INDEX idx_refresh_tokens_expires_at (expires_at)
);

CREATE TABLE IF NOT EXISTS driver_information (
    driver_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NULL,
    id_card_number VARCHAR(32) NULL,
    gender VARCHAR(32) NULL,
    birthdate DATE NULL,
    contact_number VARCHAR(32) NULL,
    email VARCHAR(128) NULL,
    address VARCHAR(255) NULL,
    driver_license_number VARCHAR(64) NULL,
    license_type VARCHAR(32) NULL,
    first_license_date DATE NULL,
    issue_date DATE NULL,
    expiry_date DATE NULL,
    issuing_authority VARCHAR(128) NULL,
    current_points INT NULL,
    total_deducted_points INT NULL,
    status VARCHAR(32) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS audit_login_log (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NULL,
    login_time DATETIME NULL,
    logout_time DATETIME NULL,
    login_result VARCHAR(32) NULL,
    failure_reason VARCHAR(255) NULL,
    login_ip VARCHAR(64) NULL,
    login_location VARCHAR(128) NULL,
    browser_type VARCHAR(64) NULL,
    browser_version VARCHAR(64) NULL,
    os_type VARCHAR(64) NULL,
    os_version VARCHAR(64) NULL,
    device_type VARCHAR(64) NULL,
    user_agent VARCHAR(512) NULL,
    session_id VARCHAR(128) NULL,
    token VARCHAR(512) NULL,
    created_at DATETIME NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

INSERT INTO sys_role (
    role_code, role_name, role_type, role_description, data_scope, status,
    sort_order, created_at, updated_at, created_by
)
VALUES
    ('SUPER_ADMIN', '超级管理员', 'System', '测试用超级管理员角色', 'All', 'Active', 1, NOW(), NOW(), 'test-seed'),
    ('ADMIN', '管理员', 'System', '测试用管理员角色', 'Department', 'Active', 2, NOW(), NOW(), 'test-seed'),
    ('USER', '普通用户', 'Business', '测试用普通用户角色', 'Self', 'Active', 3, NOW(), NOW(), 'test-seed')
ON DUPLICATE KEY UPDATE
    role_name = VALUES(role_name),
    role_type = VALUES(role_type),
    role_description = VALUES(role_description),
    data_scope = VALUES(data_scope),
    status = VALUES(status),
    updated_at = NOW();

INSERT INTO sys_user (
    username, password, salt, real_name, contact_number, email, status,
    login_failures, password_update_time, created_at, updated_at, created_by
)
VALUES
    ('admin',
     '$2a$12$PW3K2/TxmVth2CmbBw5fFuIXRtYj5vPIyqXJLAMC0KQUKSV7oPPNW',
     NULL, '测试管理员', '13800138001', 'admin@test.com', 'Active',
     0, NOW(), NOW(), NOW(), 'test-seed'),
    ('testuser',
     '$2a$12$cnyYWbDEKRb9MJeYZ8BMfOAcHGz/BSfN4Ou5.R6P8uSuen71DhT8y',
     NULL, '测试用户', '13800138002', 'user@test.com', 'Active',
     0, NOW(), NOW(), NOW(), 'test-seed'),
    ('superadmin',
     '$2a$12$ymiLs1eRyOcHP0.3E12xd.O8/hmX5ADn1du61kX6DuJEGXcSLEiCW',
     NULL, '测试超级管理员', '13800138003', 'super@test.com', 'Active',
     0, NOW(), NOW(), NOW(), 'test-seed')
ON DUPLICATE KEY UPDATE
    password = VALUES(password),
    real_name = VALUES(real_name),
    contact_number = VALUES(contact_number),
    email = VALUES(email),
    status = VALUES(status),
    updated_at = NOW();

INSERT INTO sys_user_role (user_id, role_id, created_at, created_by)
SELECT u.user_id, r.role_id, NOW(), 'test-seed'
FROM sys_user u
JOIN sys_role r ON
    (u.username = 'admin' AND r.role_code = 'ADMIN')
    OR (u.username = 'testuser' AND r.role_code = 'USER')
    OR (u.username = 'superadmin' AND r.role_code = 'SUPER_ADMIN')
ON DUPLICATE KEY UPDATE created_by = VALUES(created_by);
