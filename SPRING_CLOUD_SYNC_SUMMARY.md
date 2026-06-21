# Spring Cloud 代码同步总结

## 概述
已成功将 main 分支的 Spring Boot 单体应用中的关键功能同步到 Spring Cloud 微服务架构。

## 已完成的同步任务

### 1. ✅ 敏感数据盲索引加密系统 (Critical Security)

**文件位置:**
- `finalassignmentcloud-common/src/main/java/com/tutict/finalassignmentcloud/config/security/crypto/`
  - `SensitiveDataCryptoService.java` - AES-256-GCM 加密 + HMAC-SHA256 盲索引
  - `SensitiveDataPersistenceService.java` - 持久化层集成
- `finalassignmentcloud-common/src/main/java/com/tutict/finalassignmentcloud/config/db/`
  - `SensitiveDataSchemaMigration.java` - 自动数据库迁移

**实体类更新:**
- `DriverInformation.java` - 添加身份证、联系电话的密文和盲索引字段
- `VehicleInformation.java` - 添加车主身份证、联系电话的密文和盲索引字段
- `PaymentRecord.java` - 添加缴款人身份证、联系电话、银行账号的密文和盲索引字段
- `AppealRecord.java` - 添加申诉人身份证、联系电话的密文和盲索引字段

**功能特性:**
- GDPR/CCPA 合规的敏感数据加密
- 支持精确查询的盲索引（无需解密）
- 自动数据库迁移和数据回填

**配置要求:**
```yaml
app:
  security:
    sensitive-data:
      encryption:
        enabled: true
        key: <base64-encoded-32-byte-key>
      blind-index:
        key: <base64-encoded-32-byte-key>
```

---

### 2. ✅ 幂等性抽象层

**文件位置:**
- `finalassignmentcloud-common/src/main/java/com/tutict/finalassignmentcloud/common/idempotency/`
  - `IdempotentExecution.java` - 执行结果记录
  - `IdempotentRequestExecutor.java` - HTTP/服务层幂等性模板
  - `IdempotentKafkaMessageProcessor.java` - Kafka 消息处理幂等性模板

**功能特性:**
- 可重用的幂等性执行模板
- 支持 HTTP 请求和 Kafka 消息处理
- 状态机管理：PROCESSING → SUCCESS/FAILED → DONE
- 领域异常支持

**使用示例:**
```java
// HTTP 请求幂等性
idempotentRequestExecutor.execute(
    idempotencyKey,
    () -> checkDuplicate(idempotencyKey),
    () -> registerProcessing(idempotencyKey),
    () -> performAction(),
    result -> markSuccess(idempotencyKey, result),
    ex -> markFailure(idempotencyKey, ex)
);

// Kafka 消息幂等性
idempotentKafkaMessageProcessor.process(
    record, acknowledgment, "Payment", "create",
    key -> checkDuplicate(key),
    payload -> handleMessage(payload),
    (key, result) -> markSuccess(key, result),
    (key, ex) -> markFailure(key, ex)
);
```

**注意:** IdempotentKafkaMessageProcessor 和 SensitiveDataSchemaMigration 需要以下依赖：
```xml
<!-- Spring Kafka (如果使用 Kafka 幂等性) -->
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>

<!-- Spring JDBC (如果使用敏感数据迁移) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
```

---

### 3. ✅ WebSocket 安全加固

**文件位置:**
- `finalassignmentcloud-auth/src/main/java/com/tutict/finalassignmentcloud/auth/config/websocket/`
  - `WsTicketService.java` - 一次性票据服务（30秒 TTL）
- `finalassignmentcloud-auth/src/main/java/com/tutict/finalassignmentcloud/auth/service/`
  - `TokenBlacklistService.java` - Redis 支持的令牌黑名单（SHA-256 哈希）
- `finalassignmentcloud-auth/src/main/java/com/tutict/finalassignmentcloud/auth/controller/`
  - `AuthController.java` - 添加 `/api/auth/ws-ticket` 端点

**功能特性:**
- 单次使用的 WebSocket 连接票据
- 30 秒票据有效期
- 基于 Redis 的令牌黑名单（立即撤销）
- SHA-256 哈希保护令牌隐私

**使用流程:**
1. 客户端使用 JWT 调用 `POST /api/auth/ws-ticket`
2. 服务端返回一次性票据
3. 客户端使用票据连接 WebSocket（不再使用查询参数传递 JWT）
4. 服务端验证并消费票据（一次性使用）

**配置要求:**
```yaml
app:
  security:
    token-blacklist:
      fail-open: false  # Redis 不可用时的行为
```

---

### 4. ✅ AI 角色约束系统

**文件位置:**
- `finalassignmentcloud-ai/src/main/java/com/tutict/finalassignmentcloud/ai/prompt/`
  - `AiAgentRole.java` - 角色枚举（DRIVER, ADMIN, SUPER_ADMIN）
  - `AiAgentRoleResolver.java` - 从 Spring Security 或元数据解析角色
  - `AgentConstraintService.java` - 加载策略文件
- `finalassignmentcloud-ai/src/main/resources/ai/agent-constraints/`
  - `driver.md` - 驾驶员约束策略
  - `admin.md` - 管理员约束策略
  - `super_admin.md` - 超级管理员约束策略
- `finalassignmentcloud-ai/src/main/java/com/tutict/finalassignmentcloud/ai/service/`
  - `ChatAgent.java` - 更新以集成角色约束

**功能特性:**
- 基于角色的 AI 能力范围限制
- 防止通过提示注入的权限提升
- 在 AI 响应中屏蔽敏感数据
- 对数据更改操作要求确认

**角色权限:**
- **DRIVER**: 只能查询自己的违章、罚款、申诉、车辆信息
- **ADMIN**: 可以处理业务申诉、违章、扣分、罚款，但不能访问系统管理功能
- **SUPER_ADMIN**: 完整的技术管理权限（日志、RAG、用户角色权限管理）

---

## 数据库迁移脚本

敏感数据字段将自动添加到以下表：

```sql
-- driver_information
ALTER TABLE driver_information ADD COLUMN id_card_number_ciphertext TEXT NULL;
ALTER TABLE driver_information ADD COLUMN id_card_number_blind_index VARCHAR(128) NULL;
ALTER TABLE driver_information ADD COLUMN contact_number_ciphertext TEXT NULL;
ALTER TABLE driver_information ADD COLUMN contact_number_blind_index VARCHAR(128) NULL;
CREATE INDEX idx_driver_id_card_bidx ON driver_information (id_card_number_blind_index);
CREATE INDEX idx_driver_contact_bidx ON driver_information (contact_number_blind_index);

-- vehicle_information
ALTER TABLE vehicle_information ADD COLUMN owner_id_card_ciphertext TEXT NULL;
ALTER TABLE vehicle_information ADD COLUMN owner_id_card_blind_index VARCHAR(128) NULL;
ALTER TABLE vehicle_information ADD COLUMN owner_contact_ciphertext TEXT NULL;
ALTER TABLE vehicle_information ADD COLUMN owner_contact_blind_index VARCHAR(128) NULL;
CREATE INDEX idx_vehicle_owner_id_bidx ON vehicle_information (owner_id_card_blind_index);
CREATE INDEX idx_vehicle_owner_contact_bidx ON vehicle_information (owner_contact_blind_index);

-- payment_record
ALTER TABLE payment_record ADD COLUMN payer_id_card_ciphertext TEXT NULL;
ALTER TABLE payment_record ADD COLUMN payer_id_card_blind_index VARCHAR(128) NULL;
ALTER TABLE payment_record ADD COLUMN payer_contact_ciphertext TEXT NULL;
ALTER TABLE payment_record ADD COLUMN payer_contact_blind_index VARCHAR(128) NULL;
ALTER TABLE payment_record ADD COLUMN bank_account_ciphertext TEXT NULL;
ALTER TABLE payment_record ADD COLUMN bank_account_blind_index VARCHAR(128) NULL;
CREATE INDEX idx_payment_payer_id_bidx ON payment_record (payer_id_card_blind_index);
CREATE INDEX idx_payment_payer_contact_bidx ON payment_record (payer_contact_blind_index);
CREATE INDEX idx_payment_bank_bidx ON payment_record (bank_account_blind_index);

-- appeal_record
ALTER TABLE appeal_record ADD COLUMN appellant_id_card_ciphertext TEXT NULL;
ALTER TABLE appeal_record ADD COLUMN appellant_id_card_blind_index VARCHAR(128) NULL;
ALTER TABLE appeal_record ADD COLUMN appellant_contact_ciphertext TEXT NULL;
ALTER TABLE appeal_record ADD COLUMN appellant_contact_blind_index VARCHAR(128) NULL;
CREATE INDEX idx_appeal_appellant_id_bidx ON appeal_record (appellant_id_card_blind_index);
CREATE INDEX idx_appeal_appellant_contact_bidx ON appeal_record (appellant_contact_blind_index);
```

---

## 部署前检查清单

### 必须完成的配置

1. **生成加密密钥**
```bash
# 生成 32 字节密钥并 Base64 编码
openssl rand -base64 32
```

2. **配置 application.yml**
```yaml
app:
  security:
    sensitive-data:
      encryption:
        enabled: true
        key: ${ENCRYPTION_KEY}  # 从环境变量读取
      blind-index:
        key: ${BLIND_INDEX_KEY}
    token-blacklist:
      fail-open: false

spring:
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
```

3. **添加必要的依赖到 common 模块的 pom.xml**
```xml
<!-- 如果使用 Kafka 幂等性 -->
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>

<!-- 敏感数据迁移需要 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>

<!-- Token 黑名单需要 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

### 测试建议

1. **敏感数据加密测试**
   - 插入新记录，验证密文和盲索引字段自动填充
   - 使用盲索引进行精确查询
   - 验证数据可以正确解密

2. **WebSocket 安全测试**
   - 验证票据只能使用一次
   - 验证票据 30 秒后过期
   - 验证令牌黑名单立即生效

3. **AI 角色约束测试**
   - 用不同角色测试 AI 请求
   - 验证驾驶员不能访问管理员功能
   - 验证管理员不能访问系统管理功能

---

## 安全优先级

### 🔴 关键（生产前必须完成）
- ✅ 敏感数据盲索引加密
- ✅ WebSocket 安全加固
- ✅ AI 角色约束

### 🟡 中等（建议完成）
- ✅ 幂等性抽象层

### 🟢 低（已超前）
- RAG 性能改进（Cloud 版本已经更好）

---

## 下一步建议

1. **添加依赖并测试编译**
   - 在 `finalassignmentcloud-common/pom.xml` 中添加 Spring Kafka 和 Spring JDBC 依赖
   - 运行 `mvn clean compile` 验证编译成功

2. **配置加密密钥**
   - 生成生产环境加密密钥
   - 通过环境变量或密钥管理服务注入

3. **运行集成测试**
   - 测试敏感数据加密和查询
   - 测试 WebSocket 票据流程
   - 测试 AI 角色约束

4. **更新前端代码**
   - WebSocket 连接改用票据系统
   - 移除查询参数中的 JWT 传递

5. **文档更新**
   - API 文档中添加 `/api/auth/ws-ticket` 端点
   - 更新部署文档中的配置要求

---

## 文件清单

### 新增文件 (13个)
1. `finalassignmentcloud-common/config/security/crypto/SensitiveDataCryptoService.java`
2. `finalassignmentcloud-common/config/security/crypto/SensitiveDataPersistenceService.java`
3. `finalassignmentcloud-common/config/db/SensitiveDataSchemaMigration.java`
4. `finalassignmentcloud-common/common/idempotency/IdempotentExecution.java`
5. `finalassignmentcloud-common/common/idempotency/IdempotentRequestExecutor.java`
6. `finalassignmentcloud-common/common/idempotency/IdempotentKafkaMessageProcessor.java`
7. `finalassignmentcloud-auth/config/websocket/WsTicketService.java`
8. `finalassignmentcloud-auth/service/TokenBlacklistService.java`
9. `finalassignmentcloud-ai/prompt/AiAgentRole.java`
10. `finalassignmentcloud-ai/prompt/AiAgentRoleResolver.java`
11. `finalassignmentcloud-ai/prompt/AgentConstraintService.java`
12. `finalassignmentcloud-ai/resources/ai/agent-constraints/driver.md`
13. `finalassignmentcloud-ai/resources/ai/agent-constraints/admin.md`
14. `finalassignmentcloud-ai/resources/ai/agent-constraints/super_admin.md`

### 修改文件 (6个)
1. `finalassignmentcloud-common/entity/DriverInformation.java`
2. `finalassignmentcloud-common/entity/VehicleInformation.java`
3. `finalassignmentcloud-common/entity/PaymentRecord.java`
4. `finalassignmentcloud-common/entity/AppealRecord.java`
5. `finalassignmentcloud-auth/controller/AuthController.java`
6. `finalassignmentcloud-ai/service/ChatAgent.java`

---

生成时间: 2026-06-21
分支: codex/spring-cloud-update
基于: main 分支 (commit 60a3efe)
