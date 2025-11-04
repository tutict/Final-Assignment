-- ============================================================================
-- 交通违法行为处理管理系统 - 优化后的数据库模型
-- 版本: 2.0
-- 创建日期: 2025-11-04
-- 数据库: MySQL 8.0+
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
-- ============================================================================

-- 设置字符集和排序规则
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- 1. 核心业务表 - 驾驶员和车辆管理
-- ============================================================================

-- 1.1 驾驶员信息表
DROP TABLE IF EXISTS `driver_information`;
CREATE TABLE `driver_information` (
    `driver_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '驾驶员ID',
    `name` VARCHAR(100) NOT NULL COMMENT '姓名',
    `id_card_number` VARCHAR(18) NOT NULL COMMENT '身份证号',
    `gender` ENUM('Male', 'Female') NOT NULL COMMENT '性别',
    `birthdate` DATE NOT NULL COMMENT '出生日期',
    `contact_number` VARCHAR(20) NULL COMMENT '联系电话',
    `email` VARCHAR(100) NULL COMMENT '电子邮箱',
    `address` VARCHAR(255) NULL COMMENT '联系地址',

    -- 驾驶证信息
    `driver_license_number` VARCHAR(50) NOT NULL COMMENT '驾驶证号',
    `license_type` VARCHAR(10) NOT NULL COMMENT '准驾车型(A1,A2,B1,B2,C1,C2等)',
    `first_license_date` DATE NOT NULL COMMENT '初次领证日期',
    `issue_date` DATE NOT NULL COMMENT '驾驶证签发日期',
    `expiry_date` DATE NOT NULL COMMENT '驾驶证有效期',
    `issuing_authority` VARCHAR(100) NULL COMMENT '发证机关',

    -- 积分信息
    `current_points` INT DEFAULT 12 COMMENT '当前积分(满分12分)',
    `total_deducted_points` INT DEFAULT 0 COMMENT '累计扣分',

    -- 状态信息
    `status` ENUM('Active', 'Suspended', 'Revoked', 'Expired') DEFAULT 'Active' COMMENT '驾驶证状态',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`driver_id`),
    UNIQUE KEY `uk_id_card_number` (`id_card_number`) USING BTREE,
    UNIQUE KEY `uk_driver_license_number` (`driver_license_number`) USING BTREE,
    KEY `idx_name` (`name`) USING BTREE,
    KEY `idx_contact_number` (`contact_number`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    KEY `idx_created_at` (`created_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='驾驶员信息表';

-- 1.2 车辆信息表
DROP TABLE IF EXISTS `vehicle_information`;
CREATE TABLE `vehicle_information` (
    `vehicle_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '车辆ID',
    `license_plate` VARCHAR(20) NOT NULL COMMENT '车牌号',
    `plate_color` ENUM('Blue', 'Yellow', 'Black', 'White', 'Green') DEFAULT 'Blue' COMMENT '车牌颜色',

    -- 车辆基本信息
    `vehicle_type` VARCHAR(50) NOT NULL COMMENT '车辆类型',
    `brand` VARCHAR(50) NULL COMMENT '品牌',
    `model` VARCHAR(100) NULL COMMENT '型号',
    `vehicle_color` VARCHAR(50) NULL COMMENT '车身颜色',
    `engine_number` VARCHAR(50) NULL COMMENT '发动机号',
    `frame_number` VARCHAR(50) NULL COMMENT '车架号(VIN)',

    -- 车主信息
    `owner_name` VARCHAR(100) NOT NULL COMMENT '车主姓名',
    `owner_id_card` VARCHAR(18) NOT NULL COMMENT '车主身份证号',
    `owner_contact` VARCHAR(20) NULL COMMENT '车主联系电话',
    `owner_address` VARCHAR(255) NULL COMMENT '车主地址',

    -- 注册信息
    `first_registration_date` DATE NULL COMMENT '初次登记日期',
    `registration_date` DATE NULL COMMENT '注册登记日期',
    `issuing_authority` VARCHAR(100) NULL COMMENT '发证机关',

    -- 状态信息
    `status` ENUM('Active', 'Inactive', 'Scrapped', 'Stolen', 'Mortgaged') DEFAULT 'Active' COMMENT '车辆状态',
    `inspection_expiry_date` DATE NULL COMMENT '年检到期日期',
    `insurance_expiry_date` DATE NULL COMMENT '保险到期日期',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`vehicle_id`),
    UNIQUE KEY `uk_license_plate` (`license_plate`) USING BTREE,
    UNIQUE KEY `uk_frame_number` (`frame_number`) USING BTREE,
    KEY `idx_owner_id_card` (`owner_id_card`) USING BTREE,
    KEY `idx_owner_name` (`owner_name`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    KEY `idx_created_at` (`created_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='车辆信息表';

-- 1.3 驾驶员-车辆关联表 (多对多关系)
DROP TABLE IF EXISTS `driver_vehicle`;
CREATE TABLE `driver_vehicle` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '关联ID',
    `driver_id` BIGINT UNSIGNED NOT NULL COMMENT '驾驶员ID',
    `vehicle_id` BIGINT UNSIGNED NOT NULL COMMENT '车辆ID',
    `relationship` ENUM('Owner', 'Family', 'Borrower', 'Other') DEFAULT 'Owner' COMMENT '关系类型',
    `is_primary` TINYINT(1) DEFAULT 0 COMMENT '是否主要使用人(1=是,0=否)',
    `bind_date` DATE NULL COMMENT '绑定日期',
    `unbind_date` DATE NULL COMMENT '解绑日期',
    `status` ENUM('Active', 'Inactive') DEFAULT 'Active' COMMENT '状态',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_driver_vehicle` (`driver_id`, `vehicle_id`, `deleted_at`) USING BTREE,
    KEY `idx_driver_id` (`driver_id`) USING BTREE,
    KEY `idx_vehicle_id` (`vehicle_id`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_dv_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_information` (`driver_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_dv_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle_information` (`vehicle_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='驾驶员-车辆关联表';

-- ============================================================================
-- 2. 核心业务表 - 违法记录管理
-- ============================================================================

-- 2.1 违法类型字典表
DROP TABLE IF EXISTS `offense_type_dict`;
CREATE TABLE `offense_type_dict` (
    `type_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '类型ID',
    `offense_code` VARCHAR(50) NOT NULL COMMENT '违法代码',
    `offense_name` VARCHAR(200) NOT NULL COMMENT '违法名称',
    `category` VARCHAR(50) NOT NULL COMMENT '违法类别(超速,闯红灯,酒驾,毒驾等)',
    `description` TEXT NULL COMMENT '违法描述',

    -- 处罚标准
    `standard_fine_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '标准罚款金额(元)',
    `min_fine_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '最低罚款金额(元)',
    `max_fine_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '最高罚款金额(元)',
    `deducted_points` INT DEFAULT 0 COMMENT '扣分(0-12分)',
    `detention_days` INT DEFAULT 0 COMMENT '拘留天数',
    `license_suspension_days` INT DEFAULT 0 COMMENT '吊销驾照天数',

    -- 严重程度
    `severity_level` ENUM('Minor', 'Moderate', 'Severe', 'Critical') DEFAULT 'Minor' COMMENT '严重程度',

    -- 法律依据
    `legal_basis` TEXT NULL COMMENT '法律依据',

    -- 状态
    `status` ENUM('Active', 'Inactive') DEFAULT 'Active' COMMENT '状态',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`type_id`),
    UNIQUE KEY `uk_offense_code` (`offense_code`) USING BTREE,
    KEY `idx_category` (`category`) USING BTREE,
    KEY `idx_severity_level` (`severity_level`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='违法类型字典表';

-- 2.2 违法记录表 (优化版)
DROP TABLE IF EXISTS `offense_record`;
CREATE TABLE `offense_record` (
    `offense_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '违法记录ID',

    -- 违法信息
    `offense_code` VARCHAR(50) NOT NULL COMMENT '违法代码',
    `offense_number` VARCHAR(100) NOT NULL COMMENT '违法编号(业务流水号)',
    `offense_time` DATETIME NOT NULL COMMENT '违法时间',
    `offense_location` VARCHAR(200) NOT NULL COMMENT '违法地点',
    `offense_province` VARCHAR(50) NULL COMMENT '违法省份',
    `offense_city` VARCHAR(50) NULL COMMENT '违法城市',

    -- 关联信息 (仅存储外键，不冗余数据)
    `driver_id` BIGINT UNSIGNED NULL COMMENT '驾驶员ID',
    `vehicle_id` BIGINT UNSIGNED NOT NULL COMMENT '车辆ID',

    -- 违法详情
    `offense_description` TEXT NULL COMMENT '违法详情描述',
    `evidence_type` ENUM('Photo', 'Video', 'Witness', 'Sensor', 'Other') DEFAULT 'Photo' COMMENT '证据类型',
    `evidence_urls` JSON NULL COMMENT '证据文件URL列表(JSON数组)',

    -- 执法信息
    `enforcement_agency` VARCHAR(100) NULL COMMENT '执法机关',
    `enforcement_officer` VARCHAR(100) NULL COMMENT '执法人员',
    `enforcement_device` VARCHAR(100) NULL COMMENT '执法设备编号',

    -- 处理状态
    `process_status` ENUM('Unprocessed', 'Processing', 'Processed', 'Appealing', 'Appeal_Approved', 'Appeal_Rejected', 'Cancelled')
        DEFAULT 'Unprocessed' COMMENT '处理状态',
    `notification_status` ENUM('Not_Sent', 'Sent', 'Received', 'Confirmed') DEFAULT 'Not_Sent' COMMENT '通知状态',
    `notification_time` DATETIME NULL COMMENT '通知时间',

    -- 处罚信息
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '罚款金额(元)',
    `deducted_points` INT DEFAULT 0 COMMENT '扣分',
    `detention_days` INT DEFAULT 0 COMMENT '拘留天数',

    -- 处理信息
    `process_time` DATETIME NULL COMMENT '处理时间',
    `process_handler` VARCHAR(100) NULL COMMENT '处理人',
    `process_result` VARCHAR(255) NULL COMMENT '处理结果',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`offense_id`),
    UNIQUE KEY `uk_offense_number` (`offense_number`) USING BTREE,
    KEY `idx_offense_code` (`offense_code`) USING BTREE,
    KEY `idx_offense_time` (`offense_time`) USING BTREE,
    KEY `idx_driver_id` (`driver_id`) USING BTREE,
    KEY `idx_vehicle_id` (`vehicle_id`) USING BTREE,
    KEY `idx_process_status` (`process_status`) USING BTREE,
    KEY `idx_offense_location` (`offense_province`, `offense_city`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    KEY `idx_created_at` (`created_at`) USING BTREE,
    CONSTRAINT `fk_offense_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_information` (`driver_id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_offense_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle_information` (`vehicle_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_offense_type` FOREIGN KEY (`offense_code`) REFERENCES `offense_type_dict` (`offense_code`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='违法记录表';

-- ============================================================================
-- 3. 核心业务表 - 罚款和支付管理
-- ============================================================================

-- 3.1 罚款记录表
DROP TABLE IF EXISTS `fine_record`;
CREATE TABLE `fine_record` (
    `fine_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '罚款记录ID',
    `offense_id` BIGINT UNSIGNED NOT NULL COMMENT '违法记录ID',
    `fine_number` VARCHAR(100) NOT NULL COMMENT '罚款编号(决定书编号)',

    -- 罚款信息
    `fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '罚款金额(元)',
    `late_fee` DECIMAL(10,2) DEFAULT 0.00 COMMENT '滞纳金(元)',
    `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '总金额(元)',

    -- 罚款决定
    `fine_date` DATE NOT NULL COMMENT '罚款决定日期',
    `payment_deadline` DATE NULL COMMENT '缴款期限',
    `issuing_authority` VARCHAR(100) NOT NULL COMMENT '开具机关',
    `handler` VARCHAR(100) NOT NULL COMMENT '经办人',
    `approver` VARCHAR(100) NULL COMMENT '审批人',

    -- 支付状态
    `payment_status` ENUM('Unpaid', 'Partial', 'Paid', 'Overdue', 'Waived') DEFAULT 'Unpaid' COMMENT '支付状态',
    `paid_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '已支付金额(元)',
    `unpaid_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '未支付金额(元)',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`fine_id`),
    UNIQUE KEY `uk_fine_number` (`fine_number`) USING BTREE,
    KEY `idx_offense_id` (`offense_id`) USING BTREE,
    KEY `idx_payment_status` (`payment_status`) USING BTREE,
    KEY `idx_fine_date` (`fine_date`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_fine_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_record` (`offense_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='罚款记录表';

-- 3.2 支付记录表 (新增)
DROP TABLE IF EXISTS `payment_record`;
CREATE TABLE `payment_record` (
    `payment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '支付记录ID',
    `fine_id` BIGINT UNSIGNED NOT NULL COMMENT '罚款记录ID',
    `payment_number` VARCHAR(100) NOT NULL COMMENT '支付流水号',

    -- 支付信息
    `payment_amount` DECIMAL(10,2) NOT NULL COMMENT '支付金额(元)',
    `payment_method` ENUM('Cash', 'BankCard', 'Alipay', 'WeChat', 'BankTransfer', 'Other') NOT NULL COMMENT '支付方式',
    `payment_time` DATETIME NOT NULL COMMENT '支付时间',
    `payment_channel` VARCHAR(100) NULL COMMENT '支付渠道',

    -- 支付人信息
    `payer_name` VARCHAR(100) NOT NULL COMMENT '缴款人姓名',
    `payer_id_card` VARCHAR(18) NULL COMMENT '缴款人身份证号',
    `payer_contact` VARCHAR(20) NULL COMMENT '缴款人联系电话',

    -- 银行信息
    `bank_name` VARCHAR(100) NULL COMMENT '银行名称',
    `bank_account` VARCHAR(50) NULL COMMENT '银行账号',
    `transaction_id` VARCHAR(100) NULL COMMENT '交易流水号',

    -- 票据信息
    `receipt_number` VARCHAR(50) NULL COMMENT '票据号码',
    `receipt_url` VARCHAR(500) NULL COMMENT '票据文件URL',

    -- 支付状态
    `payment_status` ENUM('Pending', 'Success', 'Failed', 'Refunded', 'Cancelled') DEFAULT 'Success' COMMENT '支付状态',
    `refund_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '退款金额(元)',
    `refund_time` DATETIME NULL COMMENT '退款时间',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`payment_id`),
    UNIQUE KEY `uk_payment_number` (`payment_number`) USING BTREE,
    UNIQUE KEY `uk_transaction_id` (`transaction_id`) USING BTREE,
    KEY `idx_fine_id` (`fine_id`) USING BTREE,
    KEY `idx_payment_time` (`payment_time`) USING BTREE,
    KEY `idx_payment_status` (`payment_status`) USING BTREE,
    KEY `idx_payer_id_card` (`payer_id_card`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_payment_fine` FOREIGN KEY (`fine_id`) REFERENCES `fine_record` (`fine_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';

-- ============================================================================
-- 4. 核心业务表 - 扣分管理
-- ============================================================================

-- 4.1 扣分记录表
DROP TABLE IF EXISTS `deduction_record`;
CREATE TABLE `deduction_record` (
    `deduction_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '扣分记录ID',
    `offense_id` BIGINT UNSIGNED NOT NULL COMMENT '违法记录ID',
    `driver_id` BIGINT UNSIGNED NOT NULL COMMENT '驾驶员ID',

    -- 扣分信息
    `deducted_points` INT NOT NULL DEFAULT 0 COMMENT '扣分分值',
    `deduction_time` DATETIME NOT NULL COMMENT '扣分时间',
    `scoring_cycle` VARCHAR(20) NOT NULL COMMENT '记分周期(如:2025-01-01至2026-01-01)',

    -- 处理信息
    `handler` VARCHAR(100) NOT NULL COMMENT '处理人',
    `handler_dept` VARCHAR(100) NULL COMMENT '处理部门',
    `approver` VARCHAR(100) NULL COMMENT '审批人',
    `approval_time` DATETIME NULL COMMENT '审批时间',

    -- 状态
    `status` ENUM('Effective', 'Cancelled', 'Restored') DEFAULT 'Effective' COMMENT '状态',
    `restore_time` DATETIME NULL COMMENT '恢复时间',
    `restore_reason` VARCHAR(255) NULL COMMENT '恢复原因',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`deduction_id`),
    KEY `idx_offense_id` (`offense_id`) USING BTREE,
    KEY `idx_driver_id` (`driver_id`) USING BTREE,
    KEY `idx_deduction_time` (`deduction_time`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_deduction_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_record` (`offense_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_deduction_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_information` (`driver_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='扣分记录表';

-- ============================================================================
-- 5. 核心业务表 - 申诉管理
-- ============================================================================

-- 5.1 申诉记录表
DROP TABLE IF EXISTS `appeal_record`;
CREATE TABLE `appeal_record` (
    `appeal_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '申诉记录ID',
    `offense_id` BIGINT UNSIGNED NOT NULL COMMENT '违法记录ID',
    `appeal_number` VARCHAR(100) NOT NULL COMMENT '申诉编号',

    -- 申诉人信息
    `appellant_name` VARCHAR(100) NOT NULL COMMENT '申诉人姓名',
    `appellant_id_card` VARCHAR(18) NOT NULL COMMENT '申诉人身份证号',
    `appellant_contact` VARCHAR(20) NULL COMMENT '申诉人联系电话',
    `appellant_email` VARCHAR(100) NULL COMMENT '申诉人电子邮箱',
    `appellant_address` VARCHAR(255) NULL COMMENT '申诉人联系地址',

    -- 申诉信息
    `appeal_type` ENUM('Information_Error', 'Equipment_Error', 'Judgment_Error', 'Force_Majeure', 'Other')
        NOT NULL COMMENT '申诉类型',
    `appeal_reason` TEXT NOT NULL COMMENT '申诉理由',
    `appeal_time` DATETIME NOT NULL COMMENT '申诉时间',

    -- 证据材料
    `evidence_description` TEXT NULL COMMENT '证据说明',
    `evidence_urls` JSON NULL COMMENT '证据文件URL列表(JSON数组)',

    -- 受理信息
    `acceptance_status` ENUM('Pending', 'Accepted', 'Rejected', 'Need_Supplement') DEFAULT 'Pending' COMMENT '受理状态',
    `acceptance_time` DATETIME NULL COMMENT '受理时间',
    `acceptance_handler` VARCHAR(100) NULL COMMENT '受理人',
    `rejection_reason` VARCHAR(255) NULL COMMENT '不予受理原因',

    -- 处理状态
    `process_status` ENUM('Unprocessed', 'Under_Review', 'Approved', 'Rejected', 'Withdrawn')
        DEFAULT 'Unprocessed' COMMENT '处理状态',
    `process_time` DATETIME NULL COMMENT '处理时间',
    `process_result` VARCHAR(255) NULL COMMENT '处理结果',
    `process_handler` VARCHAR(100) NULL COMMENT '处理人',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`appeal_id`),
    UNIQUE KEY `uk_appeal_number` (`appeal_number`) USING BTREE,
    KEY `idx_offense_id` (`offense_id`) USING BTREE,
    KEY `idx_appellant_id_card` (`appellant_id_card`) USING BTREE,
    KEY `idx_appeal_time` (`appeal_time`) USING BTREE,
    KEY `idx_process_status` (`process_status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_appeal_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_record` (`offense_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='申诉记录表';

-- 5.2 申诉审核表 (新增)
DROP TABLE IF EXISTS `appeal_review`;
CREATE TABLE `appeal_review` (
    `review_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '审核记录ID',
    `appeal_id` BIGINT UNSIGNED NOT NULL COMMENT '申诉记录ID',

    -- 审核信息
    `review_level` ENUM('Primary', 'Secondary', 'Final') NOT NULL COMMENT '审核级别',
    `review_time` DATETIME NOT NULL COMMENT '审核时间',
    `reviewer` VARCHAR(100) NOT NULL COMMENT '审核人',
    `reviewer_dept` VARCHAR(100) NULL COMMENT '审核部门',

    -- 审核意见
    `review_result` ENUM('Approved', 'Rejected', 'Need_Resubmit', 'Transfer') NOT NULL COMMENT '审核结果',
    `review_opinion` TEXT NOT NULL COMMENT '审核意见',

    -- 处理建议
    `suggested_action` ENUM('Cancel_Offense', 'Reduce_Fine', 'Reduce_Points', 'Reject_Appeal', 'Other')
        NULL COMMENT '处理建议',
    `suggested_fine_amount` DECIMAL(10,2) NULL COMMENT '建议罚款金额(元)',
    `suggested_points` INT NULL COMMENT '建议扣分',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`review_id`),
    KEY `idx_appeal_id` (`appeal_id`) USING BTREE,
    KEY `idx_review_time` (`review_time`) USING BTREE,
    KEY `idx_reviewer` (`reviewer`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_review_appeal` FOREIGN KEY (`appeal_id`) REFERENCES `appeal_record` (`appeal_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='申诉审核表';

-- ============================================================================
-- 6. 系统管理表 - 用户权限管理
-- ============================================================================

-- 6.1 用户管理表
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
    `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',

    -- 账号信息
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码(加密存储)',
    `salt` VARCHAR(64) NULL COMMENT '密码盐值',

    -- 个人信息
    `real_name` VARCHAR(100) NULL COMMENT '真实姓名',
    `id_card_number` VARCHAR(18) NULL COMMENT '身份证号',
    `gender` ENUM('Male', 'Female', 'Other') NULL COMMENT '性别',
    `contact_number` VARCHAR(20) NULL COMMENT '联系电话',
    `email` VARCHAR(100) NULL COMMENT '电子邮箱',

    -- 工作信息
    `department` VARCHAR(100) NULL COMMENT '所属部门',
    `position` VARCHAR(100) NULL COMMENT '职位',
    `employee_number` VARCHAR(50) NULL COMMENT '工号',

    -- 账号状态
    `status` ENUM('Active', 'Inactive', 'Locked', 'Expired') DEFAULT 'Active' COMMENT '账号状态',
    `account_expiry_date` DATE NULL COMMENT '账号有效期',

    -- 安全信息
    `login_failures` INT DEFAULT 0 COMMENT '登录失败次数',
    `last_login_time` DATETIME NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(50) NULL COMMENT '最后登录IP',
    `password_update_time` DATETIME NULL COMMENT '密码修改时间',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_username` (`username`) USING BTREE,
    KEY `idx_real_name` (`real_name`) USING BTREE,
    KEY `idx_id_card_number` (`id_card_number`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_department` (`department`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统用户表';

-- 6.2 角色管理表
DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role` (
    `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '角色ID',
    `role_code` VARCHAR(50) NOT NULL COMMENT '角色编码',
    `role_name` VARCHAR(100) NOT NULL COMMENT '角色名称',
    `role_type` ENUM('System', 'Business', 'Custom') DEFAULT 'Business' COMMENT '角色类型',
    `role_description` TEXT NULL COMMENT '角色描述',

    -- 权限范围
    `data_scope` ENUM('All', 'Department', 'Department_And_Sub', 'Self', 'Custom')
        DEFAULT 'Self' COMMENT '数据权限范围',

    -- 状态
    `status` ENUM('Active', 'Inactive') DEFAULT 'Active' COMMENT '状态',
    `sort_order` INT DEFAULT 0 COMMENT '排序',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`role_id`),
    UNIQUE KEY `uk_role_code` (`role_code`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统角色表';

-- 6.3 权限管理表
DROP TABLE IF EXISTS `sys_permission`;
CREATE TABLE `sys_permission` (
    `permission_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '权限ID',
    `parent_id` INT UNSIGNED DEFAULT 0 COMMENT '父权限ID(0表示顶级)',
    `permission_code` VARCHAR(100) NOT NULL COMMENT '权限编码',
    `permission_name` VARCHAR(100) NOT NULL COMMENT '权限名称',
    `permission_type` ENUM('Menu', 'Button', 'API', 'Data') DEFAULT 'Menu' COMMENT '权限类型',
    `permission_description` TEXT NULL COMMENT '权限描述',

    -- 菜单信息
    `menu_path` VARCHAR(200) NULL COMMENT '菜单路径',
    `menu_icon` VARCHAR(100) NULL COMMENT '菜单图标',
    `component` VARCHAR(200) NULL COMMENT '组件路径',

    -- API信息
    `api_path` VARCHAR(200) NULL COMMENT 'API路径',
    `api_method` VARCHAR(20) NULL COMMENT 'API方法(GET,POST,PUT,DELETE)',

    -- 显示信息
    `is_visible` TINYINT(1) DEFAULT 1 COMMENT '是否可见(1=是,0=否)',
    `is_external` TINYINT(1) DEFAULT 0 COMMENT '是否外部链接(1=是,0=否)',
    `sort_order` INT DEFAULT 0 COMMENT '排序',

    -- 状态
    `status` ENUM('Active', 'Inactive') DEFAULT 'Active' COMMENT '状态',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`permission_id`),
    UNIQUE KEY `uk_permission_code` (`permission_code`) USING BTREE,
    KEY `idx_parent_id` (`parent_id`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统权限表';

-- 6.4 用户角色关联表
DROP TABLE IF EXISTS `sys_user_role`;
CREATE TABLE `sys_user_role` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '关联ID',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    `role_id` INT UNSIGNED NOT NULL COMMENT '角色ID',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role` (`user_id`, `role_id`, `deleted_at`) USING BTREE,
    KEY `idx_user_id` (`user_id`) USING BTREE,
    KEY `idx_role_id` (`role_id`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_ur_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_ur_role` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`role_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- 6.5 角色权限关联表
DROP TABLE IF EXISTS `sys_role_permission`;
CREATE TABLE `sys_role_permission` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '关联ID',
    `role_id` INT UNSIGNED NOT NULL COMMENT '角色ID',
    `permission_id` INT UNSIGNED NOT NULL COMMENT '权限ID',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_permission` (`role_id`, `permission_id`, `deleted_at`) USING BTREE,
    KEY `idx_role_id` (`role_id`) USING BTREE,
    KEY `idx_permission_id` (`permission_id`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`role_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_rp_permission` FOREIGN KEY (`permission_id`) REFERENCES `sys_permission` (`permission_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限关联表';

-- ============================================================================
-- 7. 审计日志表
-- ============================================================================

-- 7.1 登录日志表
DROP TABLE IF EXISTS `audit_login_log`;
CREATE TABLE `audit_login_log` (
    `log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志ID',

    -- 登录信息
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `login_time` DATETIME NOT NULL COMMENT '登录时间',
    `logout_time` DATETIME NULL COMMENT '退出时间',
    `login_result` ENUM('Success', 'Failed', 'Locked') NOT NULL COMMENT '登录结果',
    `failure_reason` VARCHAR(255) NULL COMMENT '失败原因',

    -- 客户端信息
    `login_ip` VARCHAR(50) NOT NULL COMMENT '登录IP',
    `login_location` VARCHAR(200) NULL COMMENT '登录地点',
    `browser_type` VARCHAR(100) NULL COMMENT '浏览器类型',
    `browser_version` VARCHAR(50) NULL COMMENT '浏览器版本',
    `os_type` VARCHAR(100) NULL COMMENT '操作系统',
    `os_version` VARCHAR(50) NULL COMMENT '操作系统版本',
    `device_type` VARCHAR(50) NULL COMMENT '设备类型',
    `user_agent` TEXT NULL COMMENT 'User Agent',

    -- 会话信息
    `session_id` VARCHAR(100) NULL COMMENT '会话ID',
    `token` VARCHAR(500) NULL COMMENT '访问令牌',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`log_id`),
    KEY `idx_username` (`username`) USING BTREE,
    KEY `idx_login_time` (`login_time`) USING BTREE,
    KEY `idx_login_result` (`login_result`) USING BTREE,
    KEY `idx_login_ip` (`login_ip`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录日志表';

-- 7.2 操作日志表
DROP TABLE IF EXISTS `audit_operation_log`;
CREATE TABLE `audit_operation_log` (
    `log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志ID',

    -- 操作信息
    `operation_type` VARCHAR(50) NOT NULL COMMENT '操作类型(INSERT,UPDATE,DELETE,SELECT,EXPORT等)',
    `operation_module` VARCHAR(100) NOT NULL COMMENT '操作模块',
    `operation_function` VARCHAR(100) NOT NULL COMMENT '操作功能',
    `operation_content` TEXT NULL COMMENT '操作内容',
    `operation_time` DATETIME NOT NULL COMMENT '操作时间',

    -- 操作人信息
    `user_id` BIGINT UNSIGNED NULL COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `real_name` VARCHAR(100) NULL COMMENT '真实姓名',

    -- 请求信息
    `request_method` VARCHAR(20) NULL COMMENT '请求方法',
    `request_url` VARCHAR(500) NULL COMMENT '请求URL',
    `request_params` TEXT NULL COMMENT '请求参数',
    `request_ip` VARCHAR(50) NOT NULL COMMENT '请求IP',

    -- 响应信息
    `operation_result` ENUM('Success', 'Failed', 'Exception') DEFAULT 'Success' COMMENT '操作结果',
    `response_data` TEXT NULL COMMENT '响应数据',
    `error_message` TEXT NULL COMMENT '错误信息',
    `execution_time` INT NULL COMMENT '执行时长(毫秒)',

    -- 数据变更
    `old_value` TEXT NULL COMMENT '变更前数据(JSON)',
    `new_value` TEXT NULL COMMENT '变更后数据(JSON)',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`log_id`),
    KEY `idx_user_id` (`user_id`) USING BTREE,
    KEY `idx_username` (`username`) USING BTREE,
    KEY `idx_operation_time` (`operation_time`) USING BTREE,
    KEY `idx_operation_type` (`operation_type`) USING BTREE,
    KEY `idx_operation_module` (`operation_module`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE,
    CONSTRAINT `fk_op_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志表';

-- ============================================================================
-- 8. 系统配置表
-- ============================================================================

-- 8.1 系统设置表
DROP TABLE IF EXISTS `sys_settings`;
CREATE TABLE `sys_settings` (
    `setting_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '设置ID',
    `setting_key` VARCHAR(100) NOT NULL COMMENT '设置键',
    `setting_value` TEXT NULL COMMENT '设置值',
    `setting_type` VARCHAR(50) NOT NULL COMMENT '设置类型(String,Number,Boolean,JSON)',
    `category` VARCHAR(50) NOT NULL COMMENT '设置分类',
    `description` VARCHAR(500) NULL COMMENT '设置描述',

    -- 状态
    `is_encrypted` TINYINT(1) DEFAULT 0 COMMENT '是否加密(1=是,0=否)',
    `is_editable` TINYINT(1) DEFAULT 1 COMMENT '是否可编辑(1=是,0=否)',
    `sort_order` INT DEFAULT 0 COMMENT '排序',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`setting_id`),
    UNIQUE KEY `uk_setting_key` (`setting_key`) USING BTREE,
    KEY `idx_category` (`category`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统设置表';

-- 8.2 数据字典表
DROP TABLE IF EXISTS `sys_dict`;
CREATE TABLE `sys_dict` (
    `dict_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '字典ID',
    `parent_id` INT UNSIGNED DEFAULT 0 COMMENT '父字典ID(0表示顶级)',
    `dict_type` VARCHAR(50) NOT NULL COMMENT '字典类型',
    `dict_code` VARCHAR(50) NOT NULL COMMENT '字典编码',
    `dict_label` VARCHAR(200) NOT NULL COMMENT '字典标签',
    `dict_value` VARCHAR(200) NOT NULL COMMENT '字典值',
    `dict_description` TEXT NULL COMMENT '字典描述',

    -- 样式
    `css_class` VARCHAR(100) NULL COMMENT 'CSS类名',
    `list_class` VARCHAR(100) NULL COMMENT '列表样式',

    -- 状态
    `is_default` TINYINT(1) DEFAULT 0 COMMENT '是否默认(1=是,0=否)',
    `is_fixed` TINYINT(1) DEFAULT 0 COMMENT '是否固定(1=是,0=否)',
    `status` ENUM('Active', 'Inactive') DEFAULT 'Active' COMMENT '状态',
    `sort_order` INT DEFAULT 0 COMMENT '排序',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by` VARCHAR(50) NULL COMMENT '创建人',
    `updated_by` VARCHAR(50) NULL COMMENT '更新人',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`dict_id`),
    UNIQUE KEY `uk_dict_type_code` (`dict_type`, `dict_code`) USING BTREE,
    KEY `idx_parent_id` (`parent_id`) USING BTREE,
    KEY `idx_dict_type` (`dict_type`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据字典表';

-- 8.3 请求历史表 (幂等性控制)
DROP TABLE IF EXISTS `sys_request_history`;
CREATE TABLE `sys_request_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录ID',
    `idempotency_key` VARCHAR(64) NOT NULL COMMENT '幂等性键',
    `request_method` VARCHAR(20) NOT NULL COMMENT '请求方法',
    `request_url` VARCHAR(500) NOT NULL COMMENT '请求URL',
    `request_params` TEXT NULL COMMENT '请求参数',
    `business_type` VARCHAR(50) NOT NULL COMMENT '业务类型',
    `business_id` BIGINT UNSIGNED NULL COMMENT '业务ID',
    `business_status` VARCHAR(20) NULL COMMENT '业务状态',
    `user_id` BIGINT UNSIGNED NULL COMMENT '用户ID',
    `request_ip` VARCHAR(50) NULL COMMENT '请求IP',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_idempotency_key` (`idempotency_key`) USING BTREE,
    KEY `idx_business_type` (`business_type`) USING BTREE,
    KEY `idx_business_id` (`business_id`) USING BTREE,
    KEY `idx_user_id` (`user_id`) USING BTREE,
    KEY `idx_created_at` (`created_at`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='请求历史表(幂等性控制)';

-- 8.4 备份恢复表
DROP TABLE IF EXISTS `sys_backup_restore`;
CREATE TABLE `sys_backup_restore` (
    `backup_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '备份ID',
    `backup_type` ENUM('Full', 'Incremental', 'Differential') DEFAULT 'Full' COMMENT '备份类型',
    `backup_file_name` VARCHAR(255) NOT NULL COMMENT '备份文件名',
    `backup_file_path` VARCHAR(500) NOT NULL COMMENT '备份文件路径',
    `backup_file_size` BIGINT UNSIGNED NULL COMMENT '备份文件大小(字节)',
    `backup_time` DATETIME NOT NULL COMMENT '备份时间',
    `backup_duration` INT NULL COMMENT '备份耗时(秒)',
    `backup_handler` VARCHAR(100) NULL COMMENT '备份操作人',

    -- 恢复信息
    `restore_time` DATETIME NULL COMMENT '恢复时间',
    `restore_duration` INT NULL COMMENT '恢复耗时(秒)',
    `restore_status` ENUM('Success', 'Failed', 'Partial') NULL COMMENT '恢复状态',
    `restore_handler` VARCHAR(100) NULL COMMENT '恢复操作人',
    `error_message` TEXT NULL COMMENT '错误信息',

    -- 状态
    `status` ENUM('Success', 'Failed', 'In_Progress') DEFAULT 'Success' COMMENT '备份状态',

    -- 审计字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
    `remarks` TEXT NULL COMMENT '备注',

    PRIMARY KEY (`backup_id`),
    KEY `idx_backup_time` (`backup_time`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE,
    KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='备份恢复表';

-- ============================================================================
-- 9. 创建视图
-- ============================================================================

-- 9.1 违法记录详情视图
DROP VIEW IF EXISTS `view_offense_details`;
CREATE VIEW `view_offense_details` AS
SELECT
    o.offense_id,
    o.offense_number,
    o.offense_code,
    ot.offense_name,
    ot.category AS offense_category,
    o.offense_time,
    o.offense_location,
    o.offense_province,
    o.offense_city,

    -- 驾驶员信息
    d.driver_id,
    d.name AS driver_name,
    d.id_card_number AS driver_id_card,
    d.driver_license_number,
    d.contact_number AS driver_contact,

    -- 车辆信息
    v.vehicle_id,
    v.license_plate,
    v.vehicle_type,
    v.owner_name AS vehicle_owner,
    v.owner_id_card AS owner_id_card,

    -- 处罚信息
    o.fine_amount,
    o.deducted_points,
    o.process_status,
    o.process_time,
    o.process_handler,

    -- 其他信息
    o.enforcement_agency,
    o.created_at,
    o.updated_at
FROM offense_record o
LEFT JOIN offense_type_dict ot ON o.offense_code = ot.offense_code
LEFT JOIN driver_information d ON o.driver_id = d.driver_id
LEFT JOIN vehicle_information v ON o.vehicle_id = v.vehicle_id
WHERE o.deleted_at IS NULL;

-- 9.2 驾驶员积分统计视图
DROP VIEW IF EXISTS `view_driver_points_summary`;
CREATE VIEW `view_driver_points_summary` AS
SELECT
    d.driver_id,
    d.name,
    d.id_card_number,
    d.driver_license_number,
    d.current_points,
    d.total_deducted_points,
    d.status AS license_status,

    -- 当前记分周期统计
    COUNT(DISTINCT o.offense_id) AS offense_count,
    COALESCE(SUM(o.deducted_points), 0) AS cycle_deducted_points,
    COALESCE(SUM(o.fine_amount), 0) AS total_fine_amount,

    -- 未处理违法数
    COUNT(DISTINCT CASE WHEN o.process_status = 'Unprocessed' THEN o.offense_id END) AS unprocessed_count,

    -- 最近违法时间
    MAX(o.offense_time) AS last_offense_time
FROM driver_information d
LEFT JOIN offense_record o ON d.driver_id = o.driver_id AND o.deleted_at IS NULL
WHERE d.deleted_at IS NULL
GROUP BY d.driver_id;

-- 9.3 车辆违法统计视图
DROP VIEW IF EXISTS `view_vehicle_offense_summary`;
CREATE VIEW `view_vehicle_offense_summary` AS
SELECT
    v.vehicle_id,
    v.license_plate,
    v.vehicle_type,
    v.owner_name,
    v.owner_id_card,
    v.status AS vehicle_status,

    -- 违法统计
    COUNT(DISTINCT o.offense_id) AS offense_count,
    COALESCE(SUM(o.fine_amount), 0) AS total_fine_amount,
    COALESCE(SUM(o.deducted_points), 0) AS total_deducted_points,

    -- 未处理违法数
    COUNT(DISTINCT CASE WHEN o.process_status = 'Unprocessed' THEN o.offense_id END) AS unprocessed_count,

    -- 未支付罚款总额
    COALESCE(SUM(CASE WHEN f.payment_status IN ('Unpaid', 'Overdue') THEN f.unpaid_amount ELSE 0 END), 0) AS unpaid_amount,

    -- 最近违法时间
    MAX(o.offense_time) AS last_offense_time
FROM vehicle_information v
LEFT JOIN offense_record o ON v.vehicle_id = o.vehicle_id AND o.deleted_at IS NULL
LEFT JOIN fine_record f ON o.offense_id = f.offense_id AND f.deleted_at IS NULL
WHERE v.deleted_at IS NULL
GROUP BY v.vehicle_id;

-- 9.4 罚款支付统计视图
DROP VIEW IF EXISTS `view_fine_payment_summary`;
CREATE VIEW `view_fine_payment_summary` AS
SELECT
    f.fine_id,
    f.fine_number,
    f.offense_id,
    o.offense_number,
    v.license_plate,

    -- 罚款信息
    f.fine_amount,
    f.late_fee,
    f.total_amount,
    f.payment_status,
    f.paid_amount,
    f.unpaid_amount,
    f.fine_date,
    f.payment_deadline,

    -- 支付统计
    COUNT(DISTINCT p.payment_id) AS payment_count,
    MAX(p.payment_time) AS last_payment_time,

    -- 逾期天数
    CASE
        WHEN f.payment_status IN ('Unpaid', 'Partial', 'Overdue') AND f.payment_deadline < CURDATE()
        THEN DATEDIFF(CURDATE(), f.payment_deadline)
        ELSE 0
    END AS overdue_days
FROM fine_record f
LEFT JOIN offense_record o ON f.offense_id = o.offense_id AND o.deleted_at IS NULL
LEFT JOIN vehicle_information v ON o.vehicle_id = v.vehicle_id AND v.deleted_at IS NULL
LEFT JOIN payment_record p ON f.fine_id = p.fine_id AND p.deleted_at IS NULL AND p.payment_status = 'Success'
WHERE f.deleted_at IS NULL
GROUP BY f.fine_id;

-- 9.5 申诉处理统计视图
DROP VIEW IF EXISTS `view_appeal_summary`;
CREATE VIEW `view_appeal_summary` AS
SELECT
    a.appeal_id,
    a.appeal_number,
    a.offense_id,
    o.offense_number,
    v.license_plate,
    a.appellant_name,
    a.appellant_id_card,
    a.appeal_type,
    a.appeal_time,
    a.acceptance_status,
    a.process_status,

    -- 审核次数
    COUNT(DISTINCT r.review_id) AS review_count,

    -- 处理耗时
    CASE
        WHEN a.process_time IS NOT NULL
        THEN TIMESTAMPDIFF(HOUR, a.appeal_time, a.process_time)
        ELSE TIMESTAMPDIFF(HOUR, a.appeal_time, NOW())
    END AS process_hours
FROM appeal_record a
LEFT JOIN offense_record o ON a.offense_id = o.offense_id AND o.deleted_at IS NULL
LEFT JOIN vehicle_information v ON o.vehicle_id = v.vehicle_id AND v.deleted_at IS NULL
LEFT JOIN appeal_review r ON a.appeal_id = r.appeal_id AND r.deleted_at IS NULL
WHERE a.deleted_at IS NULL
GROUP BY a.appeal_id;

-- ============================================================================
-- 10. 初始化数据
-- ============================================================================

-- 10.1 初始化系统设置
INSERT INTO `sys_settings` (`setting_key`, `setting_value`, `setting_type`, `category`, `description`, `is_editable`) VALUES
('system.name', '交通违法行为处理管理系统', 'String', 'System', '系统名称', 1),
('system.version', '2.0.0', 'String', 'System', '系统版本', 0),
('system.login_timeout', '30', 'Number', 'Security', '登录超时时间(分钟)', 1),
('system.session_timeout', '120', 'Number', 'Security', '会话超时时间(分钟)', 1),
('system.password_min_length', '8', 'Number', 'Security', '密码最小长度', 1),
('system.max_login_failures', '5', 'Number', 'Security', '最大登录失败次数', 1),
('system.page_size', '20', 'Number', 'Display', '默认分页大小', 1),
('system.date_format', 'YYYY-MM-DD', 'String', 'Display', '日期格式', 1),
('system.time_format', 'HH:mm:ss', 'String', 'Display', '时间格式', 1);

-- 10.2 初始化数据字典
INSERT INTO `sys_dict` (`dict_type`, `dict_code`, `dict_label`, `dict_value`, `dict_description`, `sort_order`) VALUES
-- 性别
('gender', 'Male', '男', 'Male', '男性', 1),
('gender', 'Female', '女', 'Female', '女性', 2),

-- 车牌颜色
('plate_color', 'Blue', '蓝牌', 'Blue', '小型汽车号牌', 1),
('plate_color', 'Yellow', '黄牌', 'Yellow', '大型汽车号牌', 2),
('plate_color', 'Black', '黑牌', 'Black', '使馆汽车号牌', 3),
('plate_color', 'White', '白牌', 'White', '警用汽车号牌', 4),
('plate_color', 'Green', '绿牌', 'Green', '新能源汽车号牌', 5),

-- 准驾车型
('license_type', 'A1', 'A1', 'A1', '大型客车', 1),
('license_type', 'A2', 'A2', 'A2', '牵引车', 2),
('license_type', 'B1', 'B1', 'B1', '中型客车', 3),
('license_type', 'B2', 'B2', 'B2', '大型货车', 4),
('license_type', 'C1', 'C1', 'C1', '小型汽车', 5),
('license_type', 'C2', 'C2', 'C2', '小型自动挡汽车', 6);

-- 10.3 初始化超级管理员
INSERT INTO `sys_user` (`username`, `password`, `real_name`, `gender`, `contact_number`, `email`, `department`, `position`, `status`) VALUES
('admin', '$2a$10$N.ZOnHkGqe.MvV57Ym2/Pe4wxJPxlhHiJ8QALj3T5xJrJzKKLX5Ke', '系统管理员', 'Male', '13800138000', 'admin@system.com', '信息中心', '系统管理员', 'Active');
-- 注：密码为 admin123，实际使用时应使用 BCrypt 加密

-- 10.4 初始化角色
INSERT INTO `sys_role` (`role_code`, `role_name`, `role_type`, `role_description`, `data_scope`) VALUES
('SUPER_ADMIN', '超级管理员', 'System', '拥有系统所有权限', 'All'),
('ADMIN', '系统管理员', 'System', '系统管理员角色', 'All'),
('TRAFFIC_POLICE', '交警', 'Business', '交通警察，处理违法记录', 'Department'),
('FINANCE', '财务人员', 'Business', '财务人员，处理罚款和支付', 'Department'),
('APPEAL_REVIEWER', '申诉审核员', 'Business', '申诉审核人员', 'Department');

-- 10.5 初始化权限
INSERT INTO `sys_permission` (`parent_id`, `permission_code`, `permission_name`, `permission_type`, `menu_path`) VALUES
-- 一级菜单
(0, 'system', '系统管理', 'Menu', '/system'),
(0, 'driver', '驾驶员管理', 'Menu', '/driver'),
(0, 'vehicle', '车辆管理', 'Menu', '/vehicle'),
(0, 'offense', '违法管理', 'Menu', '/offense'),
(0, 'fine', '罚款管理', 'Menu', '/fine'),
(0, 'appeal', '申诉管理', 'Menu', '/appeal'),
(0, 'statistics', '统计分析', 'Menu', '/statistics'),

-- 系统管理子菜单
(1, 'system:user', '用户管理', 'Menu', '/system/user'),
(1, 'system:role', '角色管理', 'Menu', '/system/role'),
(1, 'system:permission', '权限管理', 'Menu', '/system/permission'),
(1, 'system:dict', '字典管理', 'Menu', '/system/dict'),
(1, 'system:settings', '系统设置', 'Menu', '/system/settings'),
(1, 'system:log', '日志管理', 'Menu', '/system/log');

-- 10.6 分配超级管理员角色
INSERT INTO `sys_user_role` (`user_id`, `role_id`) VALUES (1, 1);

-- ============================================================================
-- 11. 创建触发器
-- ============================================================================

-- 11.1 驾驶员扣分触发器 - 自动更新驾驶员当前积分
DROP TRIGGER IF EXISTS `trg_after_deduction_insert`;
DELIMITER $$
CREATE TRIGGER `trg_after_deduction_insert`
AFTER INSERT ON `deduction_record`
FOR EACH ROW
BEGIN
    IF NEW.status = 'Effective' THEN
        UPDATE `driver_information`
        SET
            `current_points` = `current_points` - NEW.deducted_points,
            `total_deducted_points` = `total_deducted_points` + NEW.deducted_points,
            `status` = CASE
                WHEN (`current_points` - NEW.deducted_points) <= 0 THEN 'Suspended'
                ELSE `status`
            END
        WHERE `driver_id` = NEW.driver_id;
    END IF;
END$$
DELIMITER ;

-- 11.2 扣分记录更新触发器 - 恢复积分
DROP TRIGGER IF EXISTS `trg_after_deduction_update`;
DELIMITER $$
CREATE TRIGGER `trg_after_deduction_update`
AFTER UPDATE ON `deduction_record`
FOR EACH ROW
BEGIN
    -- 如果扣分记录被取消或恢复
    IF OLD.status = 'Effective' AND NEW.status IN ('Cancelled', 'Restored') THEN
        UPDATE `driver_information`
        SET
            `current_points` = LEAST(`current_points` + OLD.deducted_points, 12),
            `total_deducted_points` = GREATEST(`total_deducted_points` - OLD.deducted_points, 0)
        WHERE `driver_id` = NEW.driver_id;
    END IF;
END$$
DELIMITER ;

-- 11.3 支付记录触发器 - 更新罚款支付状态
DROP TRIGGER IF EXISTS `trg_after_payment_insert`;
DELIMITER $$
CREATE TRIGGER `trg_after_payment_insert`
AFTER INSERT ON `payment_record`
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'Success' THEN
        UPDATE `fine_record`
        SET
            `paid_amount` = `paid_amount` + NEW.payment_amount,
            `unpaid_amount` = `total_amount` - (`paid_amount` + NEW.payment_amount),
            `payment_status` = CASE
                WHEN (`total_amount` - (`paid_amount` + NEW.payment_amount)) <= 0 THEN 'Paid'
                WHEN (`paid_amount` + NEW.payment_amount) > 0 THEN 'Partial'
                ELSE 'Unpaid'
            END
        WHERE `fine_id` = NEW.fine_id;
    END IF;
END$$
DELIMITER ;

-- 11.4 罚款记录触发器 - 创建时计算总金额
DROP TRIGGER IF EXISTS `trg_before_fine_insert`;
DELIMITER $$
CREATE TRIGGER `trg_before_fine_insert`
BEFORE INSERT ON `fine_record`
FOR EACH ROW
BEGIN
    SET NEW.total_amount = NEW.fine_amount + IFNULL(NEW.late_fee, 0);
    SET NEW.unpaid_amount = NEW.total_amount;
END$$
DELIMITER ;

-- ============================================================================
-- 12. 创建存储过程
-- ============================================================================

-- 12.1 查询驾驶员违法记录
DROP PROCEDURE IF EXISTS `sp_get_driver_offense_records`;
DELIMITER $$
CREATE PROCEDURE `sp_get_driver_offense_records`(
    IN p_driver_id BIGINT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_page_num INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    SET v_offset = (p_page_num - 1) * p_page_size;

    SELECT
        o.*,
        v.license_plate,
        v.vehicle_type,
        ot.offense_name,
        ot.category
    FROM offense_record o
    LEFT JOIN vehicle_information v ON o.vehicle_id = v.vehicle_id
    LEFT JOIN offense_type_dict ot ON o.offense_code = ot.offense_code
    WHERE o.driver_id = p_driver_id
        AND o.deleted_at IS NULL
        AND (p_start_date IS NULL OR o.offense_time >= p_start_date)
        AND (p_end_date IS NULL OR o.offense_time <= p_end_date)
    ORDER BY o.offense_time DESC
    LIMIT v_offset, p_page_size;
END$$
DELIMITER ;

-- 12.2 统计违法类型分布
DROP PROCEDURE IF EXISTS `sp_offense_statistics_by_type`;
DELIMITER $$
CREATE PROCEDURE `sp_offense_statistics_by_type`(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT
        ot.category,
        ot.offense_name,
        COUNT(*) AS offense_count,
        SUM(o.fine_amount) AS total_fine_amount,
        SUM(o.deducted_points) AS total_points
    FROM offense_record o
    INNER JOIN offense_type_dict ot ON o.offense_code = ot.offense_code
    WHERE o.deleted_at IS NULL
        AND (p_start_date IS NULL OR o.offense_time >= p_start_date)
        AND (p_end_date IS NULL OR o.offense_time <= p_end_date)
    GROUP BY ot.category, ot.offense_name
    ORDER BY offense_count DESC;
END$$
DELIMITER ;

-- 12.3 批量处理逾期罚款计算滞纳金
DROP PROCEDURE IF EXISTS `sp_calculate_overdue_late_fees`;
DELIMITER $$
CREATE PROCEDURE `sp_calculate_overdue_late_fees`()
BEGIN
    DECLARE v_late_fee_rate DECIMAL(5,4) DEFAULT 0.03; -- 滞纳金比例 3%

    UPDATE fine_record
    SET
        late_fee = ROUND(fine_amount * v_late_fee_rate * DATEDIFF(CURDATE(), payment_deadline), 2),
        total_amount = fine_amount + ROUND(fine_amount * v_late_fee_rate * DATEDIFF(CURDATE(), payment_deadline), 2),
        unpaid_amount = fine_amount + ROUND(fine_amount * v_late_fee_rate * DATEDIFF(CURDATE(), payment_deadline), 2) - paid_amount,
        payment_status = 'Overdue'
    WHERE payment_status IN ('Unpaid', 'Partial')
        AND payment_deadline < CURDATE()
        AND deleted_at IS NULL;
END$$
DELIMITER ;

-- ============================================================================
-- 13. 创建索引优化
-- ============================================================================

-- 已在表定义中创建，无需额外添加

-- ============================================================================
-- 结束
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- 输出成功信息
SELECT '数据库模型创建成功！' AS message;
SELECT '总共创建了以下对象：' AS summary;
SELECT '- 19 张数据表' AS detail UNION ALL
SELECT '- 5 个视图' AS detail UNION ALL
SELECT '- 4 个触发器' AS detail UNION ALL
SELECT '- 3 个存储过程' AS detail;
