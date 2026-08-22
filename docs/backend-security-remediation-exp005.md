# Spring Boot 后端整改记录 (EXP-005 Security & Reliability Fixes)

日期：2026-08-22
分支：experiment/looppilot-final-assignment-exp-005
模块：finalAssignmentBackend（单体），finalAssignmentCloud（微服务）

本次整改覆盖 10 个阶段（A–J），目标是安全加固、幂等可靠性与构建可复现性，并保证两端（monolith / cloud）行为一致。

---

## 阶段总览

| 阶段 | 主题 | 状态 |
|------|------|------|
| A | RAG ACL 服务端认证上下文 | 完成 |
| B | ML-DSA JWT 过期校验 | 完成 |
| C | SysUser 敏感字段 DTO | 完成 |
| D | Refresh Token O(N) 查找修复 | 完成 |
| E | 幂等状态机 | 完成 |
| F | WebSocket logout 生命周期 | 完成 |
| G | 登录限流代理 IP 信任 | 完成 |
| H | RAG 删除与资源上限 | 完成 |
| I | Cloud auth 一致性 | 完成 |
| J | 构建修复与测试 | 完成 |

---

## A. RAG ACL 服务端认证上下文

**问题**：`RagQueryRequest` 之前接受客户端提交的 `userId` / `roles` / `department`，可被任意客户端伪造 ACL 提权。

**修复**：
- `RagQueryRequest` 只保留 `query` 与 `topK`，不再包含任何 ACL 字段（monolith 与 cloud 两端）。
- `RagQueryService.query()` 一律从 `SecurityContextHolder` 派生 ACL：`userId = authentication.getName()`，roles 取 `authorities` 去 `ROLE_` 前缀，department 由角色推导（`SUPER_ADMIN`/`ADMIN` → ALL，`TRAFFIC_POLICE`/`FINANCE`/`APPEAL_REVIEWER` → DEPARTMENT）。
- Monolith 的 `RagQueryController` 在无认证上下文时直接返回 401，使用 `ServerSideRagQueryRequest` 传递服务端派生上下文。
- Market 链路的 `ChatPipeline.retrieve()` 同样只信任 SecurityContextHolder，忽略客户端 metadata。

**验证**：`RagAclAuthorizationIntegrationTest` —— 未认证 401、客户端 ACL 字段被忽略。

## B. ML-DSA JWT 过期校验

**问题**：ML-DSA-65 自建 JWT 解析器未校验 `exp`，已过期 token 仍可通过 `validateToken`。

**修复**（三处 TokenProvider：monolith `TokenProvider`、cloud `TokenProvider`、cloud `ServiceTokenProvider`）：
- 校验 `alg` 头必须为 `ML-DSA-65`。
- 校验 `exp` 必须存在、为数字、且未被 `nowSeconds` 超过。
- 校验 `sub` 非空。
- 校验 `iat` 不得显著超前（> now + 300s）。
- Cloud `TokenProvider` 将硬编码 TTL 改为可配置 `jwt.access-token-expiration`。

**验证**：`TokenProviderMlDsaExpirationIntegrationTest`。

## C. SysUser 敏感字段 DTO

**问题**：`SysUserResponse` 可能携带 `idCardNumber`、`contactNumber`、`loginFailures`、`lastLoginIp`、`passwordUpdateTime`。

**修复**：
- Cloud `SysUserResponse` 移除上述敏感字段，只保留安全字段。
- `AuthWsService.getAllUsers()` / `AuthController.getAllUsers()` 统一返回 `SysUserResponse`（不再直接暴露 `SysUser` 实体）。
- Monolith 侧 `UserProfileResponse` 对手机号打码 `maskPhone`。

**验证**：`WsLogoutRevocationIntegrationTest` 校验用户列表响应不含敏感字段名。

## D. Refresh Token O(N) 查找修复

**问题**：旧实现按 token 全表扫描（BCrypt/密文无法建索引），每次 refresh 都是 O(N)。

**修复**（monolith `RefreshTokenService` / `RefreshToken`）：
- 新增 `lookupDigest`（HMAC-SHA-256 摘要），按 digest 唯一索引 O(1) 查找。
- 遗留无 digest 旧行：首次使用时线性回扫并 backfill。
- 旋转用乐观锁（`id` + `revoked=false`），防御并发重用。
- 迁移 SQL：`db/refresh_tokens_add_lookup_digest.sql`。

**验证**：`RefreshTokenLookupIntegrationTest` —— 旋转后旧 token 失效。

## E. 幂等状态机

**问题**：幂等键在目标写入成功前就预写 SUCCESS/PENDING，失败后同键重试被误当成功。

**修复**（`SysBackupRestoreService`、`SysSettingsService` 的 `checkAndInsertIdempotency`）：
- 只插入 PROCESSING 状态，绝不预写 SUCCESS/PENDING。
- FAILED 同键允许重试。
- 并发同键冲突通过 `DataIntegrityViolationException` 兜底处理。

**验证**：`IdempotencyRetryIntegrationTest`。

## F. WebSocket logout 生命周期

**问题**：登出仅黑名单 access token，未吊销已签发 WS ticket，也未断开存量 WS 连接。

**修复**（monolith `WsTicketService` / `NetWorkHandler` / `AuthWsService`）：
- `WsTicketService.invalidateUserTickets(username)` 吊销该用户全部 ticket。
- Ticket 增加 `sessionGeneration`，同用户名 session 世代变化后旧 ticket 失效。
- `NetWorkHandler.closeUserConnections(username)` 主动断开该用户 WS 连接。
- 反向代理场景：转发前剥离客户端伪造的 `X-Forwarded-For`/`X-Real-IP`，用 `request.remoteAddress()` 重建可信链。

**验证**：`WsLogoutRevocationIntegrationTest` —— 登出后 ws-ticket 签发失败。

## G. 登录限流代理 IP 信任

**问题**：`LoginAttemptGuard` 无条件信任 `X-Forwarded-For`，攻击者可伪造 IP 绕过 IP 级限流。

**修复**（monolith `LoginAttemptGuard`）：
- 引入 `trustedProxyCidrs` 列表与 CIDR 匹配。
- 仅当直连对端在可信代理网段内时才信任转发头；否则用远端 socket 地址作为客户端标识。

**验证**：`RateLimitProxyHeaderIntegrationTest` —— 伪造 X-Forwarded-For 不绕过账号窗口配额。

## H. RAG 删除与资源上限

**问题**：文档删除只删 DB，ES chunk 残留；上传缺少 ZIP/XML 炸弹防护；topK 无上限。

**修复**：
- `RagChunkVectorIndexService.deleteByDocumentId()`（两端）通过 ES delete-by-query（`term: document_id`）删除 chunk。
- `RagManagementController.deleteDocument()` 加 `@Transactional`，DB 删除提交后用 `TransactionSynchronization.afterCommit` 触发 best-effort ES 清理，ES 失败不回滚 DB 事务。
- `RagQueryService` 的 topK 限制到 `[1, 50]`（两端）。
- `RagUploadedFileParser`（两端）新增：
  - ZIP 总解压上限 256MB、单条目上限 64MB、条目数上限 1024；
  - XML 实体展开上限 64、元素深度上限 128（防 XML 炸弹）。
- `application.yml`（两端 RAG 服务）新增 `spring.servlet.multipart.max-file-size=8MB` / `max-request-size=12MB`。
- `AiChatStreamRequest` 增加常量：消息 ≤10000、sessionKey ≤128、metadata ≤2048、对话窗口 ≤20 轮。

**验证**：`RagDeletionResourceLimitIntegrationTest`。

## I. Cloud auth 一致性

**问题**：cloud auth 服务 login/register 直接回显 `ex.getMessage()`（可能暴露 Feign/DB 细节）；`/api/auth/refresh`、`/api/users/me/password` 被 permitAll；`TokenBlacklistService` 未接入认证过滤器。

**修复**（cloud `AuthController` / `SecurityConfig` / `JwtAuthenticationFilter`）：
- login 失败固定返回 `"Invalid username or password."`（已确认 cloud 无 refresh endpoint，移除误导性的 permitAll 路径）。
- register 失败返回 `"Registration failed. Please try again later."`，不再回显异常消息。
- `SecurityConfig` 移除 `/api/auth/refresh`、`/api/users/me/password` 的 permitAll 白名单。
- `JwtAuthenticationFilter` 注入 `TokenBlacklistService`，IS 黑名单中的 token 一律不建立认证上下文。
- `SecurityConfig` 装配 `JwtAuthenticationFilter(tokenProvider, tokenBlacklistService)`。

**验证**：`AuthErrorSanitizationIntegrationTest` —— 错误响应不含 `FeignException`/`SQLException`/`localhost`。

## J. 构建修复与测试

- `graalpy-maven-plugin` 版本 `25.0.3` → `25.2.4`（修复 `ModuleNotFoundError: No module named '_ctypes'`）。
- 新增 `mybatis-plus-spring:3.5.17` 依赖，`MybatisSqlSessionFactoryBean` 改从 `com.baomidou.mybatisplus.spring` 导入。
- `finalAssignmentBackend` 与 `finalAssignmentCloud` 均 `mvn -q -DskipTests compile -Dgraalpy.skip=true` 通过。

新增测试（`src/test/java/.../integration/`）：
- `auth/AuthErrorSanitizationIntegrationTest`
- `auth/TokenProviderMlDsaExpirationIntegrationTest`
- `auth/RefreshTokenLookupIntegrationTest`
- `auth/WsLogoutRevocationIntegrationTest`
- `auth/RateLimitProxyHeaderIntegrationTest`
- `rag/RagAclAuthorizationIntegrationTest`
- `rag/RagDeletionResourceLimitIntegrationTest`
- `IdempotencyRetryIntegrationTest`
- `regression/FullFixRegressionTest`

新增迁移：`finalAssignmentBackend/src/main/resources/db/refresh_tokens_add_lookup_digest.sql`

---

## 遗留项 / 已知限制

1. **cloud 端 refresh**：auth-service 当前没有 `POST /api/auth/refresh` 实现。已在契约层面移除该路径的 permitAll 声明，并在 API 文档（本文件）中明确“cloud 暂不支持 refresh”。前端目前使用单 token（`/api/auth/login` → `accessToken`），无 refresh 依赖。
2. **cloud 端幂等/WebSocket/限流**：monolith 的幂等状态机、WS 生命周期、代理 IP 信任修复在 cloud 各业务服务中未逐一移植；cloud 当前以 auth-service 聚合为主，业务服务按需同步。若 cloud 业务服务需要同等保障，需逐服务移植同一套 `LoginAttemptGuard` / 幂等 executor 逻辑。
3. **ES 兜底索引**：`RagChunkVectorIndexService.index()` 在 alias 写入失败时降级写 indexName；ES 完全不可用时 RAG 索引/删除整体功能受限。
4. **ML-DSA 密钥轮换**：`TokenProvider` 支持 ephemeral 密钥生成，但未实现在线密钥轮换（新旧密钥双验）。生产部署需引入 ecdsa/pq 双链或版本化密钥存储。
5. **`/api/ai/chat/actions`** 仍要求认证，但未在本轮新增动作级 ACL 白名单；如需动作级细分，见后续迭代。