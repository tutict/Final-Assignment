# 交通违法行为处理管理系统 - 数据库设计说明

## 版本信息
- **版本**: 2.0
- **创建日期**: 2025-11-04
- **数据库**: MySQL 8.0+
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci

---

## 目录
1. [设计概述](#设计概述)
2. [主要改进点](#主要改进点)
3. [数据库结构](#数据库结构)
4. [表结构详解](#表结构详解)
5. [视图说明](#视图说明)
6. [触发器说明](#触发器说明)
7. [存储过程说明](#存储过程说明)
8. [索引策略](#索引策略)
9. [ER关系图](#ER关系图)
10. [使用指南](#使用指南)

---

## 设计概述

### 系统目标
本系统旨在为交通管理部门提供一套完整的交通违法行为处理解决方案，包括：
- 驾驶员和车辆信息管理
- 违法记录的录入、查询、处理
- 罚款的开具、支付、统计
- 扣分记录的管理和积分追踪
- 申诉的受理、审核、处理
- 系统用户权限管理
- 操作审计和日志记录

### 设计原则
1. **数据规范化**: 遵循第三范式(3NF)，减少数据冗余
2. **关系完整性**: 使用外键约束保证数据一致性
3. **可扩展性**: 预留扩展字段和JSON字段存储动态数据
4. **性能优化**: 合理使用索引，提供常用查询视图
5. **审计追踪**: 所有表包含创建时间、更新时间、操作人等审计字段
6. **软删除**: 使用deleted_at字段实现软删除，保留历史数据
7. **安全性**: 敏感信息加密存储，权限分级管理

---

## 主要改进点

### 相比原模型的改进

#### 1. 消除数据冗余
**原问题**: `offense_information` 表同时存储了 `license_plate`, `driver_name` 和外键 `driver_id`, `vehicle_id`

**改进方案**:
```sql
-- 旧设计 (冗余)
CREATE TABLE offense_information (
    offense_id INT,
    license_plate VARCHAR(20),  -- 冗余
    driver_name VARCHAR(100),   -- 冗余
    driver_id INT,
    vehicle_id INT
);

-- 新设计 (规范)
CREATE TABLE offense_record (
    offense_id BIGINT,
    driver_id BIGINT,  -- 仅保留外键
    vehicle_id BIGINT, -- 仅保留外键
    -- 通过关联查询获取详细信息
    CONSTRAINT fk_offense_driver FOREIGN KEY (driver_id) REFERENCES driver_information (driver_id),
    CONSTRAINT fk_offense_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle_information (vehicle_id)
);
```

#### 2. 完善关系设计
**新增**: `driver_vehicle` 关联表，支持驾驶员与车辆的多对多关系

```sql
-- 新增驾驶员-车辆关联表
CREATE TABLE driver_vehicle (
    id BIGINT,
    driver_id BIGINT,
    vehicle_id BIGINT,
    relationship ENUM('Owner', 'Family', 'Borrower', 'Other'),
    is_primary TINYINT(1),
    PRIMARY KEY (id),
    UNIQUE KEY uk_driver_vehicle (driver_id, vehicle_id)
);
```

#### 3. 建立违法类型字典
**新增**: `offense_type_dict` 表，统一管理违法类型和处罚标准

```sql
CREATE TABLE offense_type_dict (
    type_id INT,
    offense_code VARCHAR(50),
    offense_name VARCHAR(200),
    category VARCHAR(50),
    standard_fine_amount DECIMAL(10,2),
    deducted_points INT,
    severity_level ENUM('Minor', 'Moderate', 'Severe', 'Critical'),
    legal_basis TEXT
);
```

#### 4. 分离支付管理
**新增**: `payment_record` 表，独立管理支付流水

```sql
CREATE TABLE payment_record (
    payment_id BIGINT,
    fine_id BIGINT,
    payment_number VARCHAR(100),
    payment_amount DECIMAL(10,2),
    payment_method ENUM('Cash', 'BankCard', 'Alipay', 'WeChat', 'BankTransfer'),
    payment_time DATETIME,
    payment_status ENUM('Pending', 'Success', 'Failed', 'Refunded')
);
```

#### 5. 完善申诉流程
**新增**: `appeal_review` 表，记录申诉审核过程

```sql
CREATE TABLE appeal_review (
    review_id BIGINT,
    appeal_id BIGINT,
    review_level ENUM('Primary', 'Secondary', 'Final'),
    review_time DATETIME,
    reviewer VARCHAR(100),
    review_result ENUM('Approved', 'Rejected', 'Need_Resubmit', 'Transfer'),
    review_opinion TEXT
);
```

#### 6. 统一系统管理
**改进**: 将用户权限管理表统一命名为 `sys_*` 前缀

```sql
-- 原表名 -> 新表名
user_management -> sys_user
role_management -> sys_role
permission_management -> sys_permission
user_role -> sys_user_role
role_permission -> sys_role_permission
```

#### 7. 规范审计字段
**统一**: 所有表包含完整的审计字段

```sql
-- 标准审计字段
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
created_by VARCHAR(50),
updated_by VARCHAR(50),
deleted_at TIMESTAMP NULL
```

#### 8. 优化数据类型
**改进**:
- ID字段统一使用 `BIGINT UNSIGNED`
- 金额字段使用 `DECIMAL(10,2)`
- 枚举字段使用 `ENUM` 类型
- 动态数据使用 `JSON` 类型

#### 9. 完善索引设计
**新增**: 根据查询场景添加合理索引

```sql
-- 示例：offense_record 表的索引
KEY idx_offense_code (offense_code),
KEY idx_offense_time (offense_time),
KEY idx_driver_id (driver_id),
KEY idx_vehicle_id (vehicle_id),
KEY idx_process_status (process_status),
KEY idx_offense_location (offense_province, offense_city),
KEY idx_deleted_at (deleted_at)
```

#### 10. 增加业务功能
**新增**:
- 积分自动计算触发器
- 罚款支付状态自动更新
- 常用查询视图
- 数据统计存储过程

---

## 数据库结构

### 表清单

#### 核心业务表 (10张)

| 序号 | 表名 | 说明 | 记录数预估 |
|------|------|------|-----------|
| 1 | `driver_information` | 驾驶员信息表 | 100万+ |
| 2 | `vehicle_information` | 车辆信息表 | 200万+ |
| 3 | `driver_vehicle` | 驾驶员-车辆关联表 | 300万+ |
| 4 | `offense_type_dict` | 违法类型字典表 | 1000+ |
| 5 | `offense_record` | 违法记录表 | 1000万+ |
| 6 | `fine_record` | 罚款记录表 | 800万+ |
| 7 | `payment_record` | 支付记录表 | 600万+ |
| 8 | `deduction_record` | 扣分记录表 | 500万+ |
| 9 | `appeal_record` | 申诉记录表 | 10万+ |
| 10 | `appeal_review` | 申诉审核表 | 20万+ |

#### 系统管理表 (5张)

| 序号 | 表名 | 说明 | 记录数预估 |
|------|------|------|-----------|
| 11 | `sys_user` | 系统用户表 | 1000+ |
| 12 | `sys_role` | 系统角色表 | 50+ |
| 13 | `sys_permission` | 系统权限表 | 200+ |
| 14 | `sys_user_role` | 用户角色关联表 | 2000+ |
| 15 | `sys_role_permission` | 角色权限关联表 | 500+ |

#### 审计日志表 (2张)

| 序号 | 表名 | 说明 | 记录数预估 |
|------|------|------|-----------|
| 16 | `audit_login_log` | 登录日志表 | 100万+ |
| 17 | `audit_operation_log` | 操作日志表 | 1000万+ |

#### 系统配置表 (4张)

| 序号 | 表名 | 说明 | 记录数预估 |
|------|------|------|-----------|
| 18 | `sys_settings` | 系统设置表 | 100+ |
| 19 | `sys_dict` | 数据字典表 | 500+ |
| 20 | `sys_request_history` | 请求历史表(幂等性) | 10万+ |
| 21 | `sys_backup_restore` | 备份恢复表 | 100+ |

### 视图清单

| 序号 | 视图名 | 说明 |
|------|--------|------|
| 1 | `view_offense_details` | 违法记录详情视图 |
| 2 | `view_driver_points_summary` | 驾驶员积分统计视图 |
| 3 | `view_vehicle_offense_summary` | 车辆违法统计视图 |
| 4 | `view_fine_payment_summary` | 罚款支付统计视图 |
| 5 | `view_appeal_summary` | 申诉处理统计视图 |

### 触发器清单

| 序号 | 触发器名 | 表 | 时机 | 说明 |
|------|---------|-----|------|------|
| 1 | `trg_after_deduction_insert` | deduction_record | AFTER INSERT | 自动更新驾驶员积分 |
| 2 | `trg_after_deduction_update` | deduction_record | AFTER UPDATE | 恢复取消的扣分 |
| 3 | `trg_after_payment_insert` | payment_record | AFTER INSERT | 更新罚款支付状态 |
| 4 | `trg_before_fine_insert` | fine_record | BEFORE INSERT | 计算罚款总额 |

### 存储过程清单

| 序号 | 存储过程名 | 说明 |
|------|-----------|------|
| 1 | `sp_get_driver_offense_records` | 查询驾驶员违法记录(分页) |
| 2 | `sp_offense_statistics_by_type` | 违法类型统计分析 |
| 3 | `sp_calculate_overdue_late_fees` | 批量计算逾期滞纳金 |

---

## 表结构详解

### 1. driver_information (驾驶员信息表)

#### 表说明
存储驾驶员的基本信息、驾驶证信息、积分情况等。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| driver_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 驾驶员ID |
| name | VARCHAR(100) | NOT NULL | 姓名 |
| id_card_number | VARCHAR(18) | NOT NULL, UNIQUE | 身份证号 |
| gender | ENUM('Male','Female') | NOT NULL | 性别 |
| birthdate | DATE | NOT NULL | 出生日期 |
| contact_number | VARCHAR(20) | NULL | 联系电话 |
| email | VARCHAR(100) | NULL | 电子邮箱 |
| address | VARCHAR(255) | NULL | 联系地址 |
| driver_license_number | VARCHAR(50) | NOT NULL, UNIQUE | 驾驶证号 |
| license_type | VARCHAR(10) | NOT NULL | 准驾车型 |
| first_license_date | DATE | NOT NULL | 初次领证日期 |
| issue_date | DATE | NOT NULL | 签发日期 |
| expiry_date | DATE | NOT NULL | 有效期 |
| issuing_authority | VARCHAR(100) | NULL | 发证机关 |
| current_points | INT | DEFAULT 12 | 当前积分 |
| total_deducted_points | INT | DEFAULT 0 | 累计扣分 |
| status | ENUM | DEFAULT 'Active' | 驾驶证状态 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 索引设计
```sql
PRIMARY KEY (driver_id),
UNIQUE KEY uk_id_card_number (id_card_number),
UNIQUE KEY uk_driver_license_number (driver_license_number),
KEY idx_name (name),
KEY idx_contact_number (contact_number),
KEY idx_status (status),
KEY idx_deleted_at (deleted_at)
```

#### 业务规则
1. 身份证号和驾驶证号必须唯一
2. 积分范围: 0-12分，扣满12分状态变为Suspended
3. 驾驶证到期后状态自动变为Expired
4. 支持软删除，不物理删除历史数据

---

### 2. vehicle_information (车辆信息表)

#### 表说明
存储车辆的基本信息、车主信息、注册信息等。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| vehicle_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 车辆ID |
| license_plate | VARCHAR(20) | NOT NULL, UNIQUE | 车牌号 |
| plate_color | ENUM | DEFAULT 'Blue' | 车牌颜色 |
| vehicle_type | VARCHAR(50) | NOT NULL | 车辆类型 |
| brand | VARCHAR(50) | NULL | 品牌 |
| model | VARCHAR(100) | NULL | 型号 |
| vehicle_color | VARCHAR(50) | NULL | 车身颜色 |
| engine_number | VARCHAR(50) | NULL | 发动机号 |
| frame_number | VARCHAR(50) | NOT NULL, UNIQUE | 车架号(VIN) |
| owner_name | VARCHAR(100) | NOT NULL | 车主姓名 |
| owner_id_card | VARCHAR(18) | NOT NULL | 车主身份证号 |
| owner_contact | VARCHAR(20) | NULL | 车主联系电话 |
| owner_address | VARCHAR(255) | NULL | 车主地址 |
| first_registration_date | DATE | NULL | 初次登记日期 |
| registration_date | DATE | NULL | 注册登记日期 |
| issuing_authority | VARCHAR(100) | NULL | 发证机关 |
| status | ENUM | DEFAULT 'Active' | 车辆状态 |
| inspection_expiry_date | DATE | NULL | 年检到期日期 |
| insurance_expiry_date | DATE | NULL | 保险到期日期 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 索引设计
```sql
PRIMARY KEY (vehicle_id),
UNIQUE KEY uk_license_plate (license_plate),
UNIQUE KEY uk_frame_number (frame_number),
KEY idx_owner_id_card (owner_id_card),
KEY idx_owner_name (owner_name),
KEY idx_status (status),
KEY idx_deleted_at (deleted_at)
```

---

### 3. driver_vehicle (驾驶员-车辆关联表)

#### 表说明
维护驾驶员和车辆之间的多对多关系，一个驾驶员可以驾驶多辆车，一辆车可以有多个驾驶员。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 关联ID |
| driver_id | BIGINT UNSIGNED | NOT NULL, FK | 驾驶员ID |
| vehicle_id | BIGINT UNSIGNED | NOT NULL, FK | 车辆ID |
| relationship | ENUM | DEFAULT 'Owner' | 关系类型 |
| is_primary | TINYINT(1) | DEFAULT 0 | 是否主要使用人 |
| bind_date | DATE | NULL | 绑定日期 |
| unbind_date | DATE | NULL | 解绑日期 |
| status | ENUM | DEFAULT 'Active' | 状态 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 业务规则
1. 同一驾驶员和车辆组合必须唯一
2. 一辆车只能有一个主要使用人(is_primary=1)
3. 解绑后unbind_date字段记录解绑时间

---

### 4. offense_type_dict (违法类型字典表)

#### 表说明
存储所有违法类型的定义、处罚标准、法律依据等信息。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| type_id | INT UNSIGNED | PK, AUTO_INCREMENT | 类型ID |
| offense_code | VARCHAR(50) | NOT NULL, UNIQUE | 违法代码 |
| offense_name | VARCHAR(200) | NOT NULL | 违法名称 |
| category | VARCHAR(50) | NOT NULL | 违法类别 |
| description | TEXT | NULL | 违法描述 |
| standard_fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | 标准罚款金额 |
| min_fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | 最低罚款金额 |
| max_fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | 最高罚款金额 |
| deducted_points | INT | DEFAULT 0 | 扣分 |
| detention_days | INT | DEFAULT 0 | 拘留天数 |
| license_suspension_days | INT | DEFAULT 0 | 吊销驾照天数 |
| severity_level | ENUM | DEFAULT 'Minor' | 严重程度 |
| legal_basis | TEXT | NULL | 法律依据 |
| status | ENUM | DEFAULT 'Active' | 状态 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 示例数据
```sql
INSERT INTO offense_type_dict VALUES
(1, '1001', '闯红灯', '信号灯违法', '驾驶机动车违反道路交通信号灯通行', 200.00, 200.00, 200.00, 6, 0, 0, 'Severe', '《道路交通安全法》第90条', 'Active'),
(2, '1002', '超速20%-50%', '超速违法', '超过规定时速20%以上未达50%', 200.00, 100.00, 500.00, 6, 0, 0, 'Moderate', '《道路交通安全法》第90条', 'Active'),
(3, '1003', '酒后驾驶', '酒驾毒驾', '饮酒后驾驶机动车', 2000.00, 1000.00, 2000.00, 12, 0, 0, 'Critical', '《道路交通安全法》第91条', 'Active');
```

---

### 5. offense_record (违法记录表)

#### 表说明
记录所有交通违法行为，包括违法详情、处理状态、罚款扣分等信息。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| offense_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 违法记录ID |
| offense_code | VARCHAR(50) | NOT NULL, FK | 违法代码 |
| offense_number | VARCHAR(100) | NOT NULL, UNIQUE | 违法编号 |
| offense_time | DATETIME | NOT NULL | 违法时间 |
| offense_location | VARCHAR(200) | NOT NULL | 违法地点 |
| offense_province | VARCHAR(50) | NULL | 违法省份 |
| offense_city | VARCHAR(50) | NULL | 违法城市 |
| driver_id | BIGINT UNSIGNED | NULL, FK | 驾驶员ID |
| vehicle_id | BIGINT UNSIGNED | NOT NULL, FK | 车辆ID |
| offense_description | TEXT | NULL | 违法详情描述 |
| evidence_type | ENUM | DEFAULT 'Photo' | 证据类型 |
| evidence_urls | JSON | NULL | 证据文件URL列表 |
| enforcement_agency | VARCHAR(100) | NULL | 执法机关 |
| enforcement_officer | VARCHAR(100) | NULL | 执法人员 |
| enforcement_device | VARCHAR(100) | NULL | 执法设备编号 |
| process_status | ENUM | DEFAULT 'Unprocessed' | 处理状态 |
| notification_status | ENUM | DEFAULT 'Not_Sent' | 通知状态 |
| notification_time | DATETIME | NULL | 通知时间 |
| fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | 罚款金额 |
| deducted_points | INT | DEFAULT 0 | 扣分 |
| detention_days | INT | DEFAULT 0 | 拘留天数 |
| process_time | DATETIME | NULL | 处理时间 |
| process_handler | VARCHAR(100) | NULL | 处理人 |
| process_result | VARCHAR(255) | NULL | 处理结果 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 索引设计
```sql
PRIMARY KEY (offense_id),
UNIQUE KEY uk_offense_number (offense_number),
KEY idx_offense_code (offense_code),
KEY idx_offense_time (offense_time),
KEY idx_driver_id (driver_id),
KEY idx_vehicle_id (vehicle_id),
KEY idx_process_status (process_status),
KEY idx_offense_location (offense_province, offense_city),
KEY idx_deleted_at (deleted_at)
```

#### 业务规则
1. offense_number 为业务流水号，全局唯一
2. evidence_urls 使用JSON格式存储多个证据文件URL
3. 违法记录创建后默认状态为 'Unprocessed'
4. 处理后根据结果可能创建罚款记录和扣分记录

---

### 6. fine_record (罚款记录表)

#### 表说明
记录罚款决定书信息，包括罚款金额、滞纳金、支付状态等。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| fine_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 罚款记录ID |
| offense_id | BIGINT UNSIGNED | NOT NULL, FK | 违法记录ID |
| fine_number | VARCHAR(100) | NOT NULL, UNIQUE | 罚款编号 |
| fine_amount | DECIMAL(10,2) | NOT NULL | 罚款金额 |
| late_fee | DECIMAL(10,2) | DEFAULT 0.00 | 滞纳金 |
| total_amount | DECIMAL(10,2) | NOT NULL | 总金额 |
| fine_date | DATE | NOT NULL | 罚款决定日期 |
| payment_deadline | DATE | NULL | 缴款期限 |
| issuing_authority | VARCHAR(100) | NOT NULL | 开具机关 |
| handler | VARCHAR(100) | NOT NULL | 经办人 |
| approver | VARCHAR(100) | NULL | 审批人 |
| payment_status | ENUM | DEFAULT 'Unpaid' | 支付状态 |
| paid_amount | DECIMAL(10,2) | DEFAULT 0.00 | 已支付金额 |
| unpaid_amount | DECIMAL(10,2) | DEFAULT 0.00 | 未支付金额 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 触发器
- `trg_before_fine_insert`: 插入前自动计算 total_amount = fine_amount + late_fee

---

### 7. payment_record (支付记录表)

#### 表说明
记录罚款的每一笔支付流水，支持分次支付。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| payment_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 支付记录ID |
| fine_id | BIGINT UNSIGNED | NOT NULL, FK | 罚款记录ID |
| payment_number | VARCHAR(100) | NOT NULL, UNIQUE | 支付流水号 |
| payment_amount | DECIMAL(10,2) | NOT NULL | 支付金额 |
| payment_method | ENUM | NOT NULL | 支付方式 |
| payment_time | DATETIME | NOT NULL | 支付时间 |
| payment_channel | VARCHAR(100) | NULL | 支付渠道 |
| payer_name | VARCHAR(100) | NOT NULL | 缴款人姓名 |
| payer_id_card | VARCHAR(18) | NULL | 缴款人身份证号 |
| payer_contact | VARCHAR(20) | NULL | 缴款人联系电话 |
| bank_name | VARCHAR(100) | NULL | 银行名称 |
| bank_account | VARCHAR(50) | NULL | 银行账号 |
| transaction_id | VARCHAR(100) | NULL, UNIQUE | 交易流水号 |
| receipt_number | VARCHAR(50) | NULL | 票据号码 |
| receipt_url | VARCHAR(500) | NULL | 票据文件URL |
| payment_status | ENUM | DEFAULT 'Success' | 支付状态 |
| refund_amount | DECIMAL(10,2) | DEFAULT 0.00 | 退款金额 |
| refund_time | DATETIME | NULL | 退款时间 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 触发器
- `trg_after_payment_insert`: 插入后自动更新罚款记录的支付状态

---

### 8. deduction_record (扣分记录表)

#### 表说明
记录驾驶员的每一次扣分操作，自动更新驾驶员的当前积分。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| deduction_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 扣分记录ID |
| offense_id | BIGINT UNSIGNED | NOT NULL, FK | 违法记录ID |
| driver_id | BIGINT UNSIGNED | NOT NULL, FK | 驾驶员ID |
| deducted_points | INT | NOT NULL | 扣分分值 |
| deduction_time | DATETIME | NOT NULL | 扣分时间 |
| scoring_cycle | VARCHAR(20) | NOT NULL | 记分周期 |
| handler | VARCHAR(100) | NOT NULL | 处理人 |
| handler_dept | VARCHAR(100) | NULL | 处理部门 |
| approver | VARCHAR(100) | NULL | 审批人 |
| approval_time | DATETIME | NULL | 审批时间 |
| status | ENUM | DEFAULT 'Effective' | 状态 |
| restore_time | DATETIME | NULL | 恢复时间 |
| restore_reason | VARCHAR(255) | NULL | 恢复原因 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

#### 触发器
- `trg_after_deduction_insert`: 插入后自动扣除驾驶员积分
- `trg_after_deduction_update`: 更新为取消/恢复时自动恢复驾驶员积分

---

### 9. appeal_record (申诉记录表)

#### 表说明
记录对违法记录的申诉信息，包括申诉理由、证据、受理和处理情况。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| appeal_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 申诉记录ID |
| offense_id | BIGINT UNSIGNED | NOT NULL, FK | 违法记录ID |
| appeal_number | VARCHAR(100) | NOT NULL, UNIQUE | 申诉编号 |
| appellant_name | VARCHAR(100) | NOT NULL | 申诉人姓名 |
| appellant_id_card | VARCHAR(18) | NOT NULL | 申诉人身份证号 |
| appellant_contact | VARCHAR(20) | NULL | 申诉人联系电话 |
| appellant_email | VARCHAR(100) | NULL | 申诉人电子邮箱 |
| appellant_address | VARCHAR(255) | NULL | 申诉人联系地址 |
| appeal_type | ENUM | NOT NULL | 申诉类型 |
| appeal_reason | TEXT | NOT NULL | 申诉理由 |
| appeal_time | DATETIME | NOT NULL | 申诉时间 |
| evidence_description | TEXT | NULL | 证据说明 |
| evidence_urls | JSON | NULL | 证据文件URL列表 |
| acceptance_status | ENUM | DEFAULT 'Pending' | 受理状态 |
| acceptance_time | DATETIME | NULL | 受理时间 |
| acceptance_handler | VARCHAR(100) | NULL | 受理人 |
| rejection_reason | VARCHAR(255) | NULL | 不予受理原因 |
| process_status | ENUM | DEFAULT 'Unprocessed' | 处理状态 |
| process_time | DATETIME | NULL | 处理时间 |
| process_result | VARCHAR(255) | NULL | 处理结果 |
| process_handler | VARCHAR(100) | NULL | 处理人 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| created_by | VARCHAR(50) | NULL | 创建人 |
| updated_by | VARCHAR(50) | NULL | 更新人 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

---

### 10. appeal_review (申诉审核表)

#### 表说明
记录申诉的每一级审核过程，支持多级审核。

#### 字段说明

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| review_id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | 审核记录ID |
| appeal_id | BIGINT UNSIGNED | NOT NULL, FK | 申诉记录ID |
| review_level | ENUM | NOT NULL | 审核级别 |
| review_time | DATETIME | NOT NULL | 审核时间 |
| reviewer | VARCHAR(100) | NOT NULL | 审核人 |
| reviewer_dept | VARCHAR(100) | NULL | 审核部门 |
| review_result | ENUM | NOT NULL | 审核结果 |
| review_opinion | TEXT | NOT NULL | 审核意见 |
| suggested_action | ENUM | NULL | 处理建议 |
| suggested_fine_amount | DECIMAL(10,2) | NULL | 建议罚款金额 |
| suggested_points | INT | NULL | 建议扣分 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | ON UPDATE | 更新时间 |
| deleted_at | TIMESTAMP | NULL | 软删除时间 |
| remarks | TEXT | NULL | 备注 |

---

## 视图说明

### 1. view_offense_details (违法记录详情视图)

#### 用途
提供违法记录的完整信息，包括驾驶员、车辆、违法类型等关联数据。

#### 查询示例
```sql
SELECT * FROM view_offense_details
WHERE license_plate = '京A12345'
ORDER BY offense_time DESC;
```

---

### 2. view_driver_points_summary (驾驶员积分统计视图)

#### 用途
统计每个驾驶员的积分情况、违法次数、罚款总额等。

#### 查询示例
```sql
SELECT * FROM view_driver_points_summary
WHERE current_points < 6  -- 积分不足6分的驾驶员
ORDER BY current_points ASC;
```

---

### 3. view_vehicle_offense_summary (车辆违法统计视图)

#### 用途
统计每辆车的违法情况、未处理违法数、未支付罚款等。

#### 查询示例
```sql
SELECT * FROM view_vehicle_offense_summary
WHERE unprocessed_count > 0  -- 有未处理违法的车辆
ORDER BY offense_count DESC;
```

---

### 4. view_fine_payment_summary (罚款支付统计视图)

#### 用途
查看罚款的支付情况、逾期天数等。

#### 查询示例
```sql
SELECT * FROM view_fine_payment_summary
WHERE payment_status = 'Overdue'  -- 逾期未支付
ORDER BY overdue_days DESC;
```

---

### 5. view_appeal_summary (申诉处理统计视图)

#### 用途
统计申诉的处理情况、耗时等。

#### 查询示例
```sql
SELECT * FROM view_appeal_summary
WHERE process_status = 'Under_Review'
ORDER BY process_hours DESC;
```

---

## 触发器说明

### 1. trg_after_deduction_insert

#### 触发时机
在 `deduction_record` 表插入新记录后

#### 功能
自动更新驾驶员的当前积分和累计扣分，积分扣至0分时自动将驾驶证状态改为 'Suspended'

#### 示例
```sql
-- 插入扣分记录
INSERT INTO deduction_record (offense_id, driver_id, deducted_points, deduction_time, scoring_cycle, handler)
VALUES (1001, 1, 6, NOW(), '2025-01-01至2026-01-01', '张警官');

-- 触发器自动执行：
-- UPDATE driver_information
-- SET current_points = current_points - 6,
--     total_deducted_points = total_deducted_points + 6
-- WHERE driver_id = 1;
```

---

### 2. trg_after_deduction_update

#### 触发时机
在 `deduction_record` 表更新记录后

#### 功能
当扣分记录状态从 'Effective' 变为 'Cancelled' 或 'Restored' 时，自动恢复驾驶员的积分

---

### 3. trg_after_payment_insert

#### 触发时机
在 `payment_record` 表插入新记录后

#### 功能
自动更新罚款记录的已支付金额、未支付金额和支付状态

---

### 4. trg_before_fine_insert

#### 触发时机
在 `fine_record` 表插入新记录前

#### 功能
自动计算 total_amount = fine_amount + late_fee，并设置 unpaid_amount = total_amount

---

## 存储过程说明

### 1. sp_get_driver_offense_records

#### 功能
查询指定驾驶员的违法记录，支持日期范围和分页

#### 参数
- `p_driver_id`: 驾驶员ID
- `p_start_date`: 开始日期
- `p_end_date`: 结束日期
- `p_page_num`: 页码
- `p_page_size`: 每页记录数

#### 调用示例
```sql
CALL sp_get_driver_offense_records(1, '2025-01-01', '2025-12-31', 1, 20);
```

---

### 2. sp_offense_statistics_by_type

#### 功能
统计指定时间范围内的违法类型分布

#### 参数
- `p_start_date`: 开始日期
- `p_end_date`: 结束日期

#### 调用示例
```sql
CALL sp_offense_statistics_by_type('2025-01-01', '2025-12-31');
```

---

### 3. sp_calculate_overdue_late_fees

#### 功能
批量计算所有逾期罚款的滞纳金（按日计算，比例3%）

#### 调用示例
```sql
-- 建议每天定时执行
CALL sp_calculate_overdue_late_fees();
```

---

## 索引策略

### 索引设计原则
1. **主键索引**: 所有表都有自增主键
2. **唯一索引**: 业务唯一字段（身份证号、车牌号、业务编号等）
3. **外键索引**: 所有外键字段
4. **查询索引**: 经常用于WHERE、ORDER BY的字段
5. **联合索引**: 多字段组合查询
6. **覆盖索引**: 包含SELECT字段的索引

### 重点索引说明

#### offense_record 表索引
```sql
-- 时间范围查询
KEY idx_offense_time (offense_time)

-- 按地区统计
KEY idx_offense_location (offense_province, offense_city)

-- 按处理状态查询
KEY idx_process_status (process_status)

-- 关联查询
KEY idx_driver_id (driver_id)
KEY idx_vehicle_id (vehicle_id)

-- 软删除过滤
KEY idx_deleted_at (deleted_at)
```

#### 其他表索引优化
- 日志表：按时间、用户、操作类型建立索引
- 关联表：双向外键索引
- 字典表：按类型、状态建立索引

---

## ER关系图

### 核心实体关系

```
驾驶员信息 (driver_information)
    ||
    || 1:N
    ||
驾驶员-车辆关联 (driver_vehicle)
    ||
    || M:N
    ||
车辆信息 (vehicle_information)
    ||
    || 1:N
    ||
违法记录 (offense_record) ---FK---> 违法类型字典 (offense_type_dict)
    ||
    || 1:1
    ||
罚款记录 (fine_record)
    ||
    || 1:N
    ||
支付记录 (payment_record)

违法记录 (offense_record)
    ||
    || 1:1
    ||
扣分记录 (deduction_record) ---FK---> 驾驶员信息 (driver_information)

违法记录 (offense_record)
    ||
    || 1:N
    ||
申诉记录 (appeal_record)
    ||
    || 1:N
    ||
申诉审核 (appeal_review)
```

### 系统管理关系

```
系统用户 (sys_user)
    ||
    || M:N
    ||
用户角色关联 (sys_user_role)
    ||
    || M:N
    ||
系统角色 (sys_role)
    ||
    || M:N
    ||
角色权限关联 (sys_role_permission)
    ||
    || M:N
    ||
系统权限 (sys_permission)
```

---

## 使用指南

### 数据库安装

#### 1. 创建数据库
```sql
CREATE DATABASE traffic_offense_system
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;
```

#### 2. 执行DDL脚本
```bash
mysql -u root -p traffic_offense_system < traffic.sql
```

### 初始化数据

#### 1. 登录系统
- 默认账号: `admin`
- 默认密码: `admin123` (BCrypt加密后的值)

#### 2. 修改默认密码
```sql
UPDATE sys_user
SET password = '新的BCrypt加密密码',
    password_update_time = NOW()
WHERE username = 'admin';
```

### 常用查询示例

#### 1. 查询驾驶员违法情况
```sql
SELECT * FROM view_driver_points_summary
WHERE driver_license_number = 'XXXXXX'
ORDER BY last_offense_time DESC;
```

#### 2. 查询车辆未处理违法
```sql
SELECT * FROM view_offense_details
WHERE license_plate = '京A12345'
  AND process_status = 'Unprocessed'
ORDER BY offense_time DESC;
```

#### 3. 查询逾期未缴罚款
```sql
SELECT * FROM view_fine_payment_summary
WHERE payment_status = 'Overdue'
  AND overdue_days > 30
ORDER BY overdue_days DESC;
```

#### 4. 统计每月违法趋势
```sql
SELECT
    DATE_FORMAT(offense_time, '%Y-%m') AS month,
    COUNT(*) AS offense_count,
    SUM(fine_amount) AS total_fine_amount
FROM offense_record
WHERE offense_time >= '2025-01-01'
  AND deleted_at IS NULL
GROUP BY DATE_FORMAT(offense_time, '%Y-%m')
ORDER BY month;
```

### 定时任务建议

#### 1. 每天计算逾期滞纳金
```sql
-- 每天凌晨1点执行
CALL sp_calculate_overdue_late_fees();
```

#### 2. 清理过期日志
```sql
-- 每月清理3个月前的登录日志
DELETE FROM audit_login_log
WHERE login_time < DATE_SUB(NOW(), INTERVAL 3 MONTH);
```

#### 3. 数据备份
```bash
# 每天凌晨2点全量备份
mysqldump -u root -p traffic_offense_system > backup_$(date +%Y%m%d).sql
```

### 性能优化建议

#### 1. 分区表优化
对于数据量巨大的表（如违法记录、日志表），建议按时间分区：
```sql
ALTER TABLE offense_record
PARTITION BY RANGE (YEAR(offense_time)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

#### 2. 读写分离
- 主库：处理写操作（INSERT、UPDATE、DELETE）
- 从库：处理读操作（SELECT）

#### 3. 缓存策略
- Redis缓存热点数据（违法类型字典、系统设置）
- 缓存查询结果（统计数据、视图数据）

#### 4. 慢查询优化
```sql
-- 开启慢查询日志
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- 分析慢查询
SHOW FULL PROCESSLIST;
EXPLAIN SELECT ...;
```

---

## 附录

### 附录A: 枚举值说明

#### 性别 (gender)
- `Male`: 男
- `Female`: 女

#### 驾驶证状态 (driver.status)
- `Active`: 正常
- `Suspended`: 暂扣
- `Revoked`: 吊销
- `Expired`: 过期

#### 车辆状态 (vehicle.status)
- `Active`: 正常
- `Inactive`: 停用
- `Scrapped`: 报废
- `Stolen`: 被盗
- `Mortgaged`: 抵押

#### 违法处理状态 (offense.process_status)
- `Unprocessed`: 未处理
- `Processing`: 处理中
- `Processed`: 已处理
- `Appealing`: 申诉中
- `Appeal_Approved`: 申诉通过
- `Appeal_Rejected`: 申诉驳回
- `Cancelled`: 已撤销

#### 支付状态 (fine.payment_status)
- `Unpaid`: 未支付
- `Partial`: 部分支付
- `Paid`: 已支付
- `Overdue`: 逾期
- `Waived`: 已免除

#### 申诉类型 (appeal.appeal_type)
- `Information_Error`: 信息错误
- `Equipment_Error`: 设备错误
- `Judgment_Error`: 判定错误
- `Force_Majeure`: 不可抗力
- `Other`: 其他

---

### 附录B: 数据迁移脚本

如需从旧版本数据库迁移，请参考以下脚本：

```sql
-- 1. 迁移驾驶员信息
INSERT INTO driver_information (
    name, id_card_number, gender, birthdate, contact_number,
    driver_license_number, license_type, first_license_date,
    issue_date, expiry_date, status, created_at
)
SELECT
    name, id_card_number, gender, birthdate, contact_number,
    driver_license_number, allowed_vehicle_type, first_license_date,
    issue_date, expiry_date,
    CASE WHEN status = 'Active' THEN 'Active' ELSE 'Inactive' END,
    NOW()
FROM old_driver_information
WHERE deleted_at IS NULL;

-- 2. 迁移车辆信息
-- ... (类似处理)

-- 3. 迁移违法记录
-- ... (需要关联新的驾驶员ID和车辆ID)
```

---

### 附录C: 常见问题

#### Q1: 如何重置驾驶员积分周期？
```sql
UPDATE driver_information
SET current_points = 12,
    total_deducted_points = 0
WHERE driver_id = ?;
```

#### Q2: 如何撤销一条违法记录？
```sql
-- 1. 软删除违法记录
UPDATE offense_record
SET deleted_at = NOW(),
    process_status = 'Cancelled'
WHERE offense_id = ?;

-- 2. 撤销扣分（触发器会自动恢复积分）
UPDATE deduction_record
SET status = 'Cancelled',
    restore_time = NOW(),
    restore_reason = '违法记录撤销'
WHERE offense_id = ?;

-- 3. 退款（如已支付）
-- 手动处理退款流程
```

#### Q3: 如何批量导入违法记录？
```sql
-- 使用LOAD DATA INFILE
LOAD DATA INFILE '/path/to/offense_data.csv'
INTO TABLE offense_record
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(offense_code, offense_time, offense_location, ...);
```

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 2.0 | 2025-11-04 | 重新设计数据库模型，优化表结构、关系和索引 |
| 1.0 | 2024-XX-XX | 初始版本 |

---

## 联系方式

如有问题或建议，请联系开发团队。

---

**文档结束**