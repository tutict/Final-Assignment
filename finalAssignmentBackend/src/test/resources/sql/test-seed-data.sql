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

CREATE TABLE IF NOT EXISTS sys_permission (
    permission_id INT PRIMARY KEY AUTO_INCREMENT,
    parent_id INT NULL,
    permission_code VARCHAR(64) NOT NULL,
    permission_name VARCHAR(128) NOT NULL,
    permission_type VARCHAR(32) NULL,
    permission_description VARCHAR(255) NULL,
    menu_path VARCHAR(255) NULL,
    menu_icon VARCHAR(64) NULL,
    component VARCHAR(255) NULL,
    api_path VARCHAR(255) NULL,
    api_method VARCHAR(16) NULL,
    is_visible BOOLEAN NULL,
    is_external BOOLEAN NULL,
    sort_order INT NULL,
    status VARCHAR(32) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL,
    UNIQUE KEY uk_sys_permission_code (permission_code)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    token TEXT NOT NULL,
    user_id BIGINT NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    INDEX idx_refresh_tokens_user_revoked (user_id, revoked),
    INDEX idx_refresh_tokens_expires_at (expires_at)
);

CREATE TABLE IF NOT EXISTS sys_request_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    idempotency_key VARCHAR(128) NOT NULL,
    request_method VARCHAR(32) NULL,
    request_url VARCHAR(255) NULL,
    request_params TEXT NULL,
    business_type VARCHAR(64) NULL,
    business_id BIGINT NULL,
    business_status VARCHAR(64) NULL,
    user_id BIGINT NULL,
    request_ip VARCHAR(64) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,
    UNIQUE KEY uk_sys_request_history_idempotency (idempotency_key)
);

CREATE TABLE IF NOT EXISTS driver_information (
    driver_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    auth_user_id BIGINT NULL,
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
    remarks VARCHAR(500) NULL,
    UNIQUE KEY uk_driver_information_auth_user (auth_user_id)
);

CREATE TABLE IF NOT EXISTS vehicle_information (
    vehicle_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id BIGINT NULL,
    license_plate VARCHAR(64) NULL,
    plate_color VARCHAR(32) NULL,
    vehicle_type VARCHAR(64) NULL,
    brand VARCHAR(64) NULL,
    model VARCHAR(64) NULL,
    vehicle_color VARCHAR(32) NULL,
    engine_number VARCHAR(64) NULL,
    frame_number VARCHAR(64) NULL,
    owner_name VARCHAR(100) NULL,
    owner_id_card VARCHAR(32) NULL,
    owner_contact VARCHAR(32) NULL,
    owner_address VARCHAR(255) NULL,
    first_registration_date DATE NULL,
    registration_date DATE NULL,
    issuing_authority VARCHAR(128) NULL,
    status VARCHAR(32) NULL,
    inspection_expiry_date DATE NULL,
    insurance_expiry_date DATE NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS driver_vehicle (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id BIGINT NULL,
    vehicle_id BIGINT NULL,
    relationship VARCHAR(64) NULL,
    is_primary BOOLEAN NULL,
    bind_date DATE NULL,
    unbind_date DATE NULL,
    status VARCHAR(32) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS offense_record (
    offense_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    offense_code VARCHAR(64) NULL,
    offense_number VARCHAR(64) NULL,
    offense_time DATETIME NULL,
    offense_location VARCHAR(255) NULL,
    offense_province VARCHAR(64) NULL,
    offense_city VARCHAR(64) NULL,
    driver_id BIGINT NULL,
    vehicle_id BIGINT NULL,
    offense_description TEXT NULL,
    evidence_type VARCHAR(64) NULL,
    evidence_urls TEXT NULL,
    enforcement_agency VARCHAR(128) NULL,
    enforcement_officer VARCHAR(128) NULL,
    enforcement_device VARCHAR(128) NULL,
    process_status VARCHAR(64) NULL,
    notification_status VARCHAR(64) NULL,
    notification_time DATETIME NULL,
    fine_amount DECIMAL(12, 2) NULL,
    deducted_points INT NULL,
    detention_days INT NULL,
    process_time DATETIME NULL,
    process_handler VARCHAR(100) NULL,
    process_result VARCHAR(255) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS fine_record (
    fine_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    offense_id BIGINT NULL,
    driver_id BIGINT NULL,
    fine_number VARCHAR(64) NULL,
    fine_amount DECIMAL(12, 2) NULL,
    late_fee DECIMAL(12, 2) NULL,
    total_amount DECIMAL(12, 2) NULL,
    fine_date DATE NULL,
    payment_deadline DATE NULL,
    issuing_authority VARCHAR(128) NULL,
    handler VARCHAR(100) NULL,
    approver VARCHAR(100) NULL,
    payment_status VARCHAR(64) NULL,
    paid_amount DECIMAL(12, 2) NULL,
    unpaid_amount DECIMAL(12, 2) NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS payment_record (
    payment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    fine_id BIGINT NULL,
    driver_id BIGINT NULL,
    payment_number VARCHAR(64) NULL,
    payment_amount DECIMAL(12, 2) NULL,
    payment_method VARCHAR(64) NULL,
    payment_time DATETIME NULL,
    payment_channel VARCHAR(64) NULL,
    payer_name VARCHAR(100) NULL,
    payer_id_card VARCHAR(32) NULL,
    payer_contact VARCHAR(32) NULL,
    bank_name VARCHAR(100) NULL,
    bank_account VARCHAR(64) NULL,
    transaction_id VARCHAR(128) NULL,
    receipt_number VARCHAR(128) NULL,
    receipt_url VARCHAR(500) NULL,
    payment_status VARCHAR(64) NULL,
    version INT NULL,
    refund_amount DECIMAL(12, 2) NULL,
    refund_time DATETIME NULL,
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    deleted_at DATETIME NULL,
    remarks VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS appeal_record (
    appeal_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    offense_id BIGINT NULL,
    driver_id BIGINT NULL,
    appeal_number VARCHAR(64) NULL,
    appellant_name VARCHAR(100) NULL,
    appellant_id_card VARCHAR(32) NULL,
    appellant_contact VARCHAR(32) NULL,
    appellant_email VARCHAR(128) NULL,
    appellant_address VARCHAR(255) NULL,
    appeal_type VARCHAR(64) NULL,
    appeal_reason TEXT NULL,
    appeal_time DATETIME NULL,
    evidence_description TEXT NULL,
    evidence_urls TEXT NULL,
    acceptance_status VARCHAR(64) NULL,
    acceptance_time DATETIME NULL,
    acceptance_handler VARCHAR(100) NULL,
    rejection_reason VARCHAR(255) NULL,
    process_status VARCHAR(64) NULL,
    process_time DATETIME NULL,
    process_result VARCHAR(255) NULL,
    process_handler VARCHAR(100) NULL,
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

INSERT INTO sys_permission (
    permission_code, permission_name, permission_type, permission_description,
    api_path, api_method, is_visible, is_external, sort_order, status,
    created_at, updated_at, created_by
)
VALUES
    ('READ_OFFENSE', 'READ_OFFENSE', 'API', 'Read offense records', '/api/offenses', 'GET', TRUE, FALSE, 1, 'Active', NOW(), NOW(), 'test-seed'),
    ('READ_DRIVER', 'READ_DRIVER', 'API', 'Read driver records', '/api/drivers', 'GET', TRUE, FALSE, 2, 'Active', NOW(), NOW(), 'test-seed'),
    ('READ_VEHICLE', 'READ_VEHICLE', 'API', 'Read vehicle records', '/api/vehicles', 'GET', TRUE, FALSE, 3, 'Active', NOW(), NOW(), 'test-seed')
ON DUPLICATE KEY UPDATE
    permission_name = VALUES(permission_name),
    permission_type = VALUES(permission_type),
    permission_description = VALUES(permission_description),
    api_path = VALUES(api_path),
    api_method = VALUES(api_method),
    status = VALUES(status),
    updated_at = NOW();

INSERT INTO sys_user (
    username, password, salt, real_name, contact_number, email, status,
    login_failures, password_update_time, created_at, updated_at, created_by
)
VALUES
    ('admin',
     '$2a$12$iP8//JMEbxOt9MkARmMSP.Gs7i2h/oeC4k9HuV9t6NolT8hl.yrjW',
     NULL, '测试管理员', '13800138001', 'admin@test.com', 'Active',
     0, NOW(), NOW(), NOW(), 'test-seed'),
    ('testuser',
     '$2a$12$CFLH0Udf.VAOEODXhuH5Y.ABOF.7lX6U6dBb2RK79DtCFr8FhnZxS',
     NULL, '测试用户', '13800138002', 'user@test.com', 'Active',
     0, NOW(), NOW(), NOW(), 'test-seed'),
    ('superadmin',
     '$2a$12$i62XLZap1a8S9PqU1BKALuR8LrK6cEAQzKfwOx7OTRcpf1OJiG2qO',
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
