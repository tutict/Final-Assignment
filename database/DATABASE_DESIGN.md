# 交通违法行为处理管理系统数据库设计

- 版本：3.0
- 更新时间：2026-05-26
- 数据库：MySQL 8.0+
- 字符集：`utf8mb4`
- 排序规则：`utf8mb4_unicode_ci`

## 设计目标

数据库围绕交通违法处理的真实业务链路设计，重点解决以下问题：

- 账号与司机档案解耦但可关联
- 管理员账号与驾驶员账号共用统一账号表
- 司机、车辆、违法、罚款、扣分、申诉之间有清晰外键关系
- 敏感字段支持密文存储和 blind-index 精确查询
- 搜索读模型由 Elasticsearch 承载，MySQL 作为事实数据源
- Kafka 幂等请求历史可追踪
- RAG 知识库独立建模，支持资料录入、分块、向量化任务和 Elasticsearch 检索

## 角色与账号模型

### sys_user

统一账号表，承载驾驶员、普通管理员、超级管理员。

关键字段：

| 字段 | 说明 |
| --- | --- |
| `user_id` | 账号主键 |
| `username` | 登录名 |
| `password` | BCrypt 密码 |
| `email` | 邮箱 |
| `id_card_number` | 身份证号兼容明文字段 |
| `id_card_number_ciphertext` | 身份证号密文 |
| `id_card_number_blind_index` | 身份证号 blind-index |
| `contact_number` | 手机号兼容明文字段 |
| `contact_number_ciphertext` | 手机号密文 |
| `contact_number_blind_index` | 手机号 blind-index |

角色通过 `sys_user_role` 关联 `sys_role`。

### sys_role

推荐角色：

| 角色 | 说明 |
| --- | --- |
| `USER` | 驾驶员端账号 |
| `ADMIN` | 普通管理员，处理业务 |
| `SUPER_ADMIN` | 超级管理员，审查日志、管理 RAG、维护系统 |

### driver_information

司机档案表。驾驶员账号通过 `driver_information.user_id` 绑定司机档案。

关键字段：

| 字段 | 说明 |
| --- | --- |
| `driver_id` | 司机档案主键 |
| `user_id` | 关联 `sys_user.user_id` |
| `name` | 姓名 |
| `id_card_number` / `id_card_number_ciphertext` / `id_card_number_blind_index` | 身份证号兼容列、密文列、查询列 |
| `contact_number` / `contact_number_ciphertext` / `contact_number_blind_index` | 手机号兼容列、密文列、查询列 |
| `driver_license_number` | 驾驶证号 |
| `current_points` | 当前记分 |
| `status` | 驾驶证状态 |

业务规则：

- 一个驾驶员账号最多关联一个主司机档案
- 驾驶员端查询个人违法、罚款、申诉、车辆时，以 `user_id -> driver_id` 作为边界
- 管理员可以维护司机档案，但不能绕过权限查询其他敏感数据

## 核心业务表

### vehicle_information

车辆信息表。

关键字段：

| 字段 | 说明 |
| --- | --- |
| `vehicle_id` | 车辆主键 |
| `license_plate` | 车牌号 |
| `frame_number` | VIN / 车架号 |
| `owner_name` | 车主姓名 |
| `owner_id_card` / `owner_id_card_ciphertext` / `owner_id_card_blind_index` | 车主身份证号 |
| `owner_contact` / `owner_contact_ciphertext` / `owner_contact_blind_index` | 车主手机号 |
| `status` | 车辆状态 |

### driver_vehicle

驾驶员与车辆关联表，用于支持一人多车、一车多驾驶员。

| 字段 | 说明 |
| --- | --- |
| `id` | 关联主键 |
| `driver_id` | 司机档案 ID |
| `vehicle_id` | 车辆 ID |
| `relationship` | 车主、亲属、借用等关系 |
| `is_primary` | 是否主车辆 |
| `status` | 绑定状态 |

建议索引：

```sql
UNIQUE KEY uk_driver_vehicle (driver_id, vehicle_id)
KEY idx_driver_vehicle_driver (driver_id)
KEY idx_driver_vehicle_vehicle (vehicle_id)
```

### offense_type_dict

违法类型字典，管理违法代码、处罚标准、扣分规则和法律依据。

### offense_record

违法行为主表。

| 字段 | 说明 |
| --- | --- |
| `offense_id` | 违法记录主键 |
| `offense_number` | 违法编号 |
| `offense_code` | 违法代码，关联 `offense_type_dict` |
| `driver_id` | 司机档案 ID |
| `vehicle_id` | 车辆 ID |
| `offense_time` | 违法时间 |
| `offense_location` | 违法地点 |
| `process_status` | 处理状态 |
| `fine_amount` | 罚款金额 |
| `deducted_points` | 扣分 |

状态流转建议：

```text
UNPROCESSED -> PROCESSING -> PROCESSED
UNPROCESSED -> APPEALING -> APPEAL_APPROVED / APPEAL_REJECTED
```

### fine_record

罚款记录表，通常由违法记录生成。

### payment_record

缴费流水表。

敏感字段：

| 字段 | 说明 |
| --- | --- |
| `payer_id_card` / `payer_id_card_ciphertext` / `payer_id_card_blind_index` | 缴款人身份证号 |
| `payer_contact` / `payer_contact_ciphertext` / `payer_contact_blind_index` | 缴款人手机号 |
| `bank_account` / `bank_account_ciphertext` / `bank_account_blind_index` | 银行账号 |

### deduction_record

扣分记录表。与 `offense_record` 和 `driver_information` 关联。

### appeal_record

申诉记录表。

敏感字段：

| 字段 | 说明 |
| --- | --- |
| `appellant_id_card` / `appellant_id_card_ciphertext` / `appellant_id_card_blind_index` | 申诉人身份证号 |
| `appellant_contact` / `appellant_contact_ciphertext` / `appellant_contact_blind_index` | 申诉人手机号 |

### appeal_review

申诉审核过程表，用于记录多轮审核意见和最终处理结果。

## 审计与系统表

| 表 | 说明 |
| --- | --- |
| `audit_login_log` | 登录审计 |
| `audit_operation_log` | 操作审计，超级管理员审查入口 |
| `sys_settings` | 系统设置 |
| `sys_dict` | 数据字典 |
| `sys_request_history` | 幂等请求与 Kafka 处理历史 |
| `sys_backup_restore` | 备份恢复记录 |

`sys_request_history` 是业务幂等的核心支撑，Kafka Listener 和关键 HTTP 请求会使用请求 key 标记处理中、成功或失败，避免重复请求造成多次写入。

## RAG 表

RAG 表结构定义位于：

```text
finalAssignmentBackend/src/main/resources/rag/rag_schema.sql
```

### rag_document

资料级元数据。

| 字段 | 说明 |
| --- | --- |
| `id` | 文档 ID |
| `source_type` | 来源类型，例如手工录入、上传文件、业务表抽取 |
| `source_table` | 来源表 |
| `source_id` | 来源记录 ID |
| `source_version` | 来源版本 |
| `title` | 标题 |
| `content_hash` | 内容哈希 |
| `status` | 索引状态 |
| `acl_scope` | 可见范围 |
| `route` | 前端路由 |
| `metadata_json` | 扩展元数据 |

### rag_chunk

资料分块。

关键字段：

| 字段 | 说明 |
| --- | --- |
| `id` | chunk ID |
| `document_id` | 关联 `rag_document.id` |
| `chunk_no` | 文档内分块序号 |
| `content` | chunk 文本 |
| `content_hash` | chunk 内容哈希 |
| `source_field` | 来源字段 |
| `status` | 分块状态，例如 `PENDING_EMBEDDING`、`EMBEDDED` |
| `embedding_model` | 最近一次成功向量化模型 |
| `embedding_hash` | provider、模型、内容和向量共同计算的哈希 |

### rag_embedding_task

向量化任务队列。资料写入 `rag_chunk` 后会按 provider 和 model 创建任务，后台 embedding worker 定时消费 `PENDING` / `FAILED` 任务，调用 embedding 模型生成向量，再写入 Elasticsearch `rag_chunk_current` alias。

关键字段：

| 字段 | 说明 |
| --- | --- |
| `chunk_id` | 待向量化的 chunk |
| `provider` | embedding provider，例如 `ollama`、`deterministic` |
| `model` | embedding 模型，例如 `nomic-embed-text` |
| `status` | `PENDING`、`RUNNING`、`SUCCEEDED`、`FAILED`、`POISONED` |
| `attempt_count` | 尝试次数 |
| `next_retry_at` | 失败重试时间 |
| `last_error` | 最近一次错误信息 |

向量本体不存 MySQL，写入 Elasticsearch dense vector 字段；MySQL 只保留任务状态、模型名和哈希，用于追踪、重试和判断是否需要重建索引。

## 敏感字段治理

已覆盖的敏感字段：

| 表 | 字段 |
| --- | --- |
| `sys_user` | `id_card_number`, `contact_number` |
| `driver_information` | `id_card_number`, `contact_number` |
| `vehicle_information` | `owner_id_card`, `owner_contact` |
| `payment_record` | `payer_id_card`, `payer_contact`, `bank_account` |
| `appeal_record` | `appellant_id_card`, `appellant_contact` |

每个敏感字段对应：

```text
<field>              兼容旧业务的明文字段
<field>_ciphertext   AES-GCM 密文字段
<field>_blind_index  HMAC 查询索引字段
```

查询规则：

- 精确查身份证号、手机号、银行卡号时优先计算 blind-index 并查询 `*_blind_index`
- ES 只保存脱敏展示值，不保存完整敏感明文
- 历史数据由 `SensitiveDataSchemaMigration` 启动时回填

## 搜索与 CDC

搜索读模型由 Elasticsearch 承载。

同步方式：

```text
MySQL binlog -> Debezium Connect -> Redpanda -> CDC Consumer -> Elasticsearch
```

第一阶段默认覆盖：

- `driver_information`
- `vehicle_information`
- `sys_user`

可通过 `CDC_ELASTICSEARCH_TOPIC_PATTERN` 扩展更多表。

## 推荐索引

业务查询索引：

```sql
KEY idx_driver_user_id (user_id)
KEY idx_driver_license_number (driver_license_number)
KEY idx_vehicle_license_plate (license_plate)
KEY idx_driver_vehicle_driver (driver_id)
KEY idx_driver_vehicle_vehicle (vehicle_id)
KEY idx_offense_driver (driver_id)
KEY idx_offense_vehicle (vehicle_id)
KEY idx_offense_status_time (process_status, offense_time)
KEY idx_payment_status (payment_status)
KEY idx_appeal_status (process_status)
```

敏感查询索引：

```sql
KEY idx_sys_user_id_card_bidx (id_card_number_blind_index)
KEY idx_sys_user_contact_bidx (contact_number_blind_index)
KEY idx_driver_id_card_bidx (id_card_number_blind_index)
KEY idx_driver_contact_bidx (contact_number_blind_index)
KEY idx_vehicle_owner_id_bidx (owner_id_card_blind_index)
KEY idx_vehicle_owner_contact_bidx (owner_contact_blind_index)
KEY idx_payment_payer_id_bidx (payer_id_card_blind_index)
KEY idx_payment_payer_contact_bidx (payer_contact_blind_index)
KEY idx_payment_bank_bidx (bank_account_blind_index)
KEY idx_appeal_appellant_id_bidx (appellant_id_card_blind_index)
KEY idx_appeal_appellant_contact_bidx (appellant_contact_blind_index)
```

## ER 关系简图

```text
sys_user
  | 1:1
driver_information
  | M:N
driver_vehicle
  | M:N
vehicle_information
  | 1:N
offense_record
  | 1:1
fine_record
  | 1:N
payment_record

offense_record
  | 1:1
deduction_record

offense_record
  | 1:N
appeal_record
  | 1:N
appeal_review

sys_user
  | M:N
sys_user_role
  | M:N
sys_role
  | M:N
sys_role_permission
  | M:N
sys_permission
```

## 维护建议

- 所有新增敏感字段必须同时考虑密文列和 blind-index 列
- 新增搜索索引时先确认是否会泄露敏感明文
- 新增 Kafka 消费逻辑时必须使用幂等 key
- 驾驶员端查询必须以当前登录用户绑定的 `driver_id` 为边界
- 超级管理员功能应与普通管理员业务处理功能分开授权
