# Quarkus 后端 vs Spring 后端 —— 方法级差异清单

> 对比对象：`final_assignment_backend_quarkus`（Quarkus）与 `finalAssignmentBackend`（Spring）
> 生成方式：全量抽取两边 service / controller 的 `public`/`protected` 方法签名 + 类级路由 + HTTP 动词 + 鉴权注解，逐对 `diff`
> 代码量：Spring 399 文件 / ~49,240 行；Quarkus 128 文件 / ~17,967 行（约 36%）
> 说明：本清单聚焦"两边都存在"的对应文件的方法级差异，以及"单边独有"的整文件。业务逻辑体内的细节差异（如某方法内是否发 Kafka）在备注中标注。

---

## 一、系统性差异（贯穿几乎所有模块，不逐个重复）

1. **`afterCommit` 方法 = Elasticsearch 索引事务后同步钩子**
   - Spring 几乎每个 service 都有一个 `afterCommit`（提交后把实体写入 ES 的 `*SearchRepository`），并且大量查询是"先查 ES 索引、回落 DB、再回写索引"。
   - Quarkus **没有任何 ES 集成**（0 个 `*Document` 实体），所有查询直接走 MyBatis-Plus DB。
   - 因此下表中凡 Quarkus"缺 `afterCommit`"均属此项，**不代表业务方法缺失**，单列出来只为完整。

2. **Kafka 事件发布**
   - Spring service 层会主动发布 Kafka 事件（`KafkaMessageSender`、`BusinessEventPushService`，以及 `OffenseRecordService` 的 `publishCreateKafkaAfterCommit` 等）。
   - Quarkus **service 层零 Kafka 发布**（仅 `kafkaListener` 包做消费）。

3. **鉴权注解风格**
   - Spring 用 `@PreAuthorize`（Spring Security，SpEL），Quarkus 用 `@RolesAllowed`（JAX-RS/JWT RBAC）。
   - 实测两边**控制器上几乎都没有**方法级鉴权注解（各 controller 计数基本为 0），说明都依赖统一的 JWT 过滤器/拦截器。差异主要在 `@WsAction` 上：Spring 带 `roles={...}`，Quarkus 的 `@WsAction` 丢掉了 `roles` 属性。

---

## 二、Service 层逐个差异清单

图例：**共有** = 两边同名方法数；**仅 Spring** = Quarkus 缺的方法；`*` = 上述 ES 同步钩子（非业务缺失）。

| Service（Spring 位置 → Quarkus 位置） | 共有 | Quarkus 缺失（仅 Spring 有） | Quarkus 额外 | 关键业务备注 |
|---|---|---|---|---|
| **SysUserService** (admin→) | 21 | `afterCommit*`、`findPage`、`getAllUsers`、`isUsernameExists` | — | ⚠ 缺**用户名查重** `isUsernameExists`、分页 `findPage`、全量 `getAllUsers` |
| **SysRoleService** | 17 | `afterCommit*` | — | 基本一致 |
| **SysPermissionService** | 20 | `afterCommit*` | — | 基本一致 |
| **SysRolePermissionService** | 12 | `afterCommit*` | — | 基本一致 |
| **SysUserRoleService** | 12 | `afterCommit*` | — | 基本一致 |
| **SysSettingsService** | 16 | `afterCommit*` | — | 基本一致 |
| **SysDictService** | 16 | `afterCommit*` | — | 基本一致 |
| **SysBackupRestoreService** | 16 | `afterCommit*`、`findByStatus`、`findPage` | — | 缺按状态查询、分页 |
| **SysRequestHistoryService** (system→) | 19 | `afterCommit*`、`count`、`findByTimeRange`、`findByUsername`、`findRecent` | — | ⚠ 缺 4 个统计/查询方法 |
| **FineRecordService** (offense→) | 15 | `afterCommit*` | — | ⚠ 另：`validateRecord` 缺"从 Offense 回填 driverId"；`checkAndInsertIdempotency` 缺 Kafka 发送；`@WsAction` 缺 roles |
| **DeductionRecordService** (offense→) | 15 | `afterCommit*` | — | 同 Fine 系列（无 ES/Kafka） |
| **OffenseRecordService** (offense→) | 22 | `findPage`、`publishCreateKafkaAfterCommit`、`shadowCompareKafkaUpdateMerge`、`updateKafkaFullUpdate` | — | ⚠ 缺 **governance 全量更新合并 + Kafka 影子比对**（Spring 的核心治理逻辑），缺分页 |
| **OffenseTypeDictService** (offense→) | 18 | `afterCommit*` | — | 基本一致 |
| **PaymentRecordService** (payment→) | 20 | `afterCommit*`、`isDuplicateIdempotencyKey` | — | 缺幂等查重辅助方法 |
| **DriverInformationService** (driver→) | 12 | `afterCommit*`、`findLinkedDriver`、`findOrCreateLinkedDriver` | — | ⚠ 缺"关联司机 / 不存在则自动创建"业务 |
| **DriverVehicleService** (driver→) | 13 | `afterCommit*` | — | 基本一致 |
| **VehicleInformationService** (driver→) | 21 | `afterCommit*`、`getVehicleInformationByDriverId`、`searchByOwnerIdCard`、`searchByOwnerName`、`searchByStatus`、`suggestPlates` | — | ⚠ 缺 5 个查询/车牌联想方法 |
| **AuditLoginLogService** (audit→) | 17 | `afterCommit*`、`count`、`findPage`、`findRecent` | — | 缺统计/分页/最近记录 |
| **AuditOperationLogService** (audit→) | 17 | `afterCommit*`、`count`、`findPage`、`findRecent` | — | 缺统计/分页/最近记录 |
| **AuthWsService** (auth→) | 3 | `getCurrentUserProfile`、`logout`、`refresh` | — | ⚠⚠ **缺 token 刷新 / 登出 / 当前用户** |
| **AppealReviewService** (appeal→) | 13 | `afterCommit*` | — | 基本一致 |
| **AppealRecordService → AppealManagementService**（改名） | 19 | `applyKafkaEvent`、`findByCreatedBy`、`findByDriverId` | — | 缺 Kafka 事件应用 + 按创建人/司机查询 |
| **AIChatSearchService** (ai→ai) | 2 | — | — | ✅ **完全一致** |
| **StateMachineService** (statemachine→statemachine) | 3 | — | `canTransitionAppealState`、`canTransitionOffenseState`、`canTransitionPaymentState` | 🔵 Quarkus **反而更多**（额外暴露 3 个状态校验方法） |

---

## 三、Controller 层逐个差异清单

图例：**共有** = 两边同名处理方法数；基础路径两边**全部一致**（见下）。

| Controller | 基础路径（两边一致） | 共有 | Quarkus 缺失端点 | 仅命名不同（功能相同） |
|---|---|---|---|---|
| **AuthController** | `/api/auth` | 3 | ⚠⚠ `refresh`(POST `/refresh`)、`logout`(POST `/logout`)、`getCurrentUser`(GET `/me`) | — |
| **UserManagementController** | `/api/users` | 25 | — | ✅ 完全一致 |
| **RoleManagementController** | `/api/roles` | 21 | — | `deleteByNameDeprecated`↔`deleteRoleByNameDeprecated` 等 3 个 |
| **PermissionManagementController** | `/api/permissions` | 16 | — | `getByNameDeprecated`↔`getPermissionByNameDeprecated` 等 3 个 |
| **SystemSettingsController** | `/api/system/settings` | 24 | — | ✅ 完全一致 |
| **BackupRestoreController** | `/api/system/backup` | 12 | — | ✅ 完全一致 |
| **LoginLogController** | `/api/logs/login` | 13 | — | ✅ 完全一致 |
| **OperationLogController** | `/api/logs/operation` | 13 | — | ✅ 完全一致 |
| **SystemLogsController** | `/api/system/logs` | 13 | — | ✅ 完全一致 |
| **AppealManagementController** | `/api/appeals` | 23 | `getMyAppeals`（GET，我的申诉） | — |
| **FineInformationController** | `/api/fines` | 10 | — | ✅ 完全一致（近期已补齐） |
| **DeductionInformationController** | `/api/deductions` | 10 | — | ✅ 完全一致 |
| **PaymentRecordController** | `/api/payments` | 15 | `createDriverPayment`(POST)、`findByDriver`(GET) | — |
| **OffenseInformationController** | `/api/offenses` | 17 | `getDetails`(GET，明细) | — |
| **OffenseTypeController** | `/api/offense-types` | 14 | — | ✅ 完全一致 |
| **DriverInformationController** | `/api/drivers` | 8 | `searchDrivers`(GET) | — |
| **VehicleInformationController** | `/api/vehicles` | 26 | `autocompletePlates`(GET)、`listVehicleRecordsByDriver`(GET) | — |
| **TrafficViolationController** | `/api/violations` | 3 | — | ✅ 完全一致 |
| **ProgressItemController** | `/api/progress` | 7 | `getByStatus`（Quarkus 用 `listByStatus`）、`getByTimeRangeDeprecated` | 若干 deprecated 改名 |
| **WorkflowController** | `/api/workflow` | 3 | — | ✅ 完全一致 |
| **OffenseDetailsController** | (view) | 1 | — | ✅ 完全一致 |

> HTTP 动词计数佐证：以上"缺失端点"与两边 GET/POST 数量差**完全吻合**（例：Auth Spring GET2/POST4 vs Quarkus GET1/POST2；Vehicle Spring GET21 vs Quarkus GET19）。

---

## 四、单边独有（对方完全没有对应文件）

### 只有 Spring 有（Quarkus 完全缺失）
**Service：**
- `RagIndexingService`（RAG 向量索引）
- `ChatAgent`、`ChatActionRuleEngine`（AI 智能体 / 动作规则引擎）
- `BusinessRecordViewService`、`BusinessEventPushService`、`KafkaMessageSender`（业务视图 / 事件推送 / Kafka 发送）
- `RefreshTokenService`、`TokenBlacklistService`、`PqcTokenCrypto`（**刷新令牌 / 令牌黑名单 / 后量子加密**）
- `OffenseDetailService`（违章明细，Quarkus 有同名 Controller 但无独立 Service）
- `AppealStatusChangedEvent`、`PaymentStatusChangedEvent`（领域事件）

**Controller：**
- `RagManagementController`（`/api/rag`，RAG 管理）
- `WsTicketController`（WebSocket 票据签发）

### 只有 Quarkus 有（Spring 无同名文件）
**Service：** `SearchService`（Quarkus 自建的简化搜索，非 Spring 的 ES `*SearchRepository` 体系）
**Controller：** `ChatController`（`/api/.../chat`，AI 聊天入口）、`SearchResourceController`（搜索资源）

> 注：Spring 的 AI 聊天入口在 `ai` 包内（非独立 controller），RAG 检索走 `ai/rag`；Quarkus 用 `ChatController` + `service/ai` + `SearchService` 自成一套，**两边 AI/搜索实现方式不同、非对齐**。

---

## 五、结论与补齐优先级建议

**整体判断：**
- **对外接口（Controller）对齐度 ~90%**：基础路径全部一致，大部分端点齐全，仅少数辅助端点缺失。
- **Service 公共方法对齐度 ~85%**：核心 CRUD + 幂等骨架几乎 1:1；缺口集中在 ES 钩子、分页/统计查询、少量业务方法。
- **完整业务 + 基础设施对齐度 ~35–40%**：ES 检索、Kafka 发布、RAG、DDD 申诉、offense/payment 治理层、后量子安全、可观测性等**成块缺失**。

**建议补齐优先级（按业务风险从高到低）：**

| 优先级 | 缺口 | 影响 |
|---|---|---|
| 🔴 P0 | `AuthController`/`AuthWsService` 的 `refresh`/`logout`/`me` + `RefreshTokenService`/`TokenBlacklistService` | 登录后无法刷新/注销 token，安全与会话管理不完整 |
| 🔴 P0 | `OffenseRecordService` 的 governance 合并（`updateKafkaFullUpdate`/`shadowCompareKafkaUpdateMerge`）+ service 层 Kafka 发布 | 全量更新的并发/陈旧覆盖治理缺失，事件驱动链路断裂 |
| 🟠 P1 | `SysUserService.isUsernameExists`、`DriverInformationService.findOrCreateLinkedDriver`、各 `findPage`/`count`/`findRecent` | 查重、司机关联、分页统计等业务/体验缺口 |
| 🟠 P1 | `VehicleInformationService` 5 个查询、`PaymentRecordController` 司机支付、`AppealManagementController.getMyAppeals` 等缺失端点 | 前端部分页面功能不可用 |
| 🟡 P2 | ES 检索体系（`*Document` + `*SearchRepository` + `afterCommit`） | 目前直查 DB 可用，性能/全文检索降级，非阻塞 |
| 🟡 P2 | RAG（`RagIndexingService`/`RagManagementController`）、AI 智能体（`ChatAgent`） | AI 高级能力缺失，两边实现路线不同，需先决策是否对齐 |
