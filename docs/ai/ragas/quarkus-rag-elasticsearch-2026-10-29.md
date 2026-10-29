# Quarkus 后端 Elasticsearch 兼容与混合检索（2026-10-29）

本报告记录把 Elasticsearch 索引、Ollama 向量嵌入与 BM25 + 向量混合检索移植到
`final_assignment_backend_quarkus` 的范围、实现、验证与遗留风险。Spring 参考实现的改造与
评测基线见 [refusal-2026-10-29.md](refusal-2026-10-29.md)；Quarkus 的纯 RAG 流水线与答案层
拒答能力见 [quarkus-refusal-2026-10-29.md](quarkus-refusal-2026-10-29.md)；Cloud 与 Go 的移植
分别见 [cloud-parity-2026-10-28.md](cloud-parity-2026-10-28.md) 与
[go-parity-2026-10-29.md](go-parity-2026-10-29.md)。

## 结论摘要

- Quarkus 后端现在有完整的「MySQL 文档/分块 → Ollama 嵌入 → Elasticsearch 向量索引 →
  BM25 + kNN 混合检索 → 严格 ACL 收敛」链路，管理端 `/index/migrate`、`/embedding/run`、
  `/embedding/requeue`、`/backfill` 从零计数桩改为真实实现。
- 检索身份**只来自服务端**：请求体里的 `roles` / `asRole` 被完全忽略，ACL 判定改为
  `acl_scope` + `metadata` 明细（角色 / 用户 / 部门）的严格放行，RAGAS 的三条 ACL 探针
  从形同虚设变为真实约束。
- `MAX_TOP_K` 由 20 提升到 50，满足评测脚本 `_user_control_visible` 用 `max(50, top_k)`
  取控制文档的要求。
- Quarkus 使用**自己的索引与别名**（`rag_chunk_quarkus_v1` / `rag_chunk_quarkus_current`），
  与 Spring 的 `rag_chunk_v1` / `rag_chunk_current` 隔离：各后端索引里都是 768 维
  `nomic-embed-text` 向量，但 `chunk_id` 生成算法与写入时机各自独立，共用索引会互相覆盖。
  （本报告写作时 Go 仍是 384 维确定性向量，Go 后续也已切换为 `nomic-embed-text`。）
- 单元测试全部通过（48 个测试类、222 个用例、0 failure / 0 error）。
- **RAGAS 端到端已执行**，与 Spring 基线在同一数据集、同一裁判、同一模型下可比。两次基线对齐
  配置的运行（运行 B `20261029T045537Z-3b26af06`、运行 C `20261029T054721Z-3b26af06`）：

  | 指标 | Spring 基线 | 运行 B | 运行 C | 与基线偏差 |
  | --- | ---: | ---: | ---: | --- |
  | Faithfulness | 0.9907 | 0.9638 | 0.9315 | −0.0269 / −0.0592 |
  | Response Relevancy | 0.8521 | 0.8701 | 0.8378 | +0.0180 / −0.0143 |
  | Context Precision | 0.9949 | 0.9552 | 0.9889 | −0.0397 / −0.0060 |
  | Context Recall | 0.9815 | 0.9828 | 0.9815 | +0.0013 / 0.0000 |
  | Answer Correctness | 0.7713 | 0.8117 | 0.7902 | +0.0404 / +0.0189 |
  | 引用合规 | 0.9000 | 0.9667 | 0.9000 | +0.0667 / 0.0000 |
  | 可评分覆盖 | 27/30 | 29/30 | 27/30 | — |
  | 不可答拒答 | 3/3 | 3/3 | 3/3 | — |
  | ACL 泄漏 / 上下文漂移 / 硬失败 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | — |

- **检索层是确定性的**：运行 B 与运行 C 的 36 题检索结果**完全一致**（36/36 同序同集）；与
  Spring 基线相比 35 题集合相同、31 题顺序相同，唯一差异是 a04 的第 3 位（`c-fine-refund` ↔
  `c-fine-payment-guide`，均在 top-5 内）。检索链路的移植是忠实的。
- **生成层是随机的**：同一构建两次运行的配对差为 Faithfulness −0.0370、Relevancy −0.0289、
  Answer Correctness −0.0214，单题最大摆动 −1.0（a25 答偏），而 Context Precision 与
  Context Recall 的配对差恒为 **0.0000**。也就是说「与基线偏差 ≤ 0.03」这条验收带**低于本
  数据集生成侧的噪声底**，只对检索侧指标（Context Precision / Context Recall）成立——这两项
  Quarkus 与基线的差距是 −0.0064 与 0.0000。
- **护栏拒答集合随采样变化**：Spring 拒 a10 / a16 / a28，运行 B 只拒 a10，运行 C 拒
  a10 / a28 / a30。主题校验在多跳题上本就是边缘判定，两端都会误拒；a10 的「无引用」拒答则
  三次稳定复现。
- 清理范围已实测：只删掉 `suite=ragas` 的 31 条文档，ES 别名上残留 0，共享的 12 条非 ragas
  语料未受影响。

## 背景：移植前的差距

移植前 Quarkus 只有 MySQL 词法检索（`RagQueryService` 的整句 + 中文 bigram 打分），
`scripts/ragas` 评测脚手架依赖的管理端契约无法满足：

| # | 契约要求 | 移植前状态 | 后果 |
| --- | --- | --- | --- |
| C1 | 评测语料需写入 ES，`source_id` 可被 `terms` 聚合命中 | 无任何 ES 写入 | `wait_for_index_visibility` 超时失败 |
| C2 | `POST /api/rag/admin/embedding/run` 需真正消费任务 | 桩返回 0 | `wait_for_embeddings` 300s 超时 |
| C3 | `GET /api/rag/admin/documents?query=ragas` 需按 `metadata_json` 过滤 | 只过滤 title/source_table/source_id | 找不到种子文档，清理越权 |
| C4 | `POST /api/rag/query` 的 ACL 身份必须来自服务端 | 直接读请求体 `roles`/`asRole` | 客户端可伪造角色越权读取 |
| C5 | 正向控制文档必须可见，`topK` 需支持到 50 | `MAX_TOP_K = 20` | 控制文档被截断，误判 ACL 失败 |
| C6 | 删除文档需同步删除 ES 文档 | 只删 MySQL | 清理后 ES 残留，`source_id` 仍可命中 |
| C7 | ACL 明细（角色 / 用户 / 部门）需参与检索过滤 | 完全未参与 | p01/p02/p03 三条 ACL 探针形同虚设 |
| C8 | 检索需 BM25 + 向量混合（RRF） | 仅 MySQL 词法 | 召回率与答案质量显著低于 Spring 基线 |

## 架构

```text
管理端 / 评测脚本
  POST /api/rag/admin/documents/manual   → RagIndexingService → MySQL(rag_document / rag_chunk / rag_embedding_task)
  POST /api/rag/admin/embedding/run      → RagEmbeddingWorker
                                            ├─ OllamaEmbeddingProvider  (nomic-embed-text, 768 维)
                                            ├─ RagChunkSourceFactory     (ES 文档体)
                                            └─ RagIndexManager           → Elasticsearch  rag_chunk_quarkus_v1
                                                                        (alias rag_chunk_quarkus_current)

检索
  POST /api/rag/query
    → SecurityContext → RagAccessContext(userId, roles, department)
    → HybridRetriever
        ├─ ElasticsearchRagSearchBackend.bm25Search   (multi_match + match_phrase)
        ├─ ElasticsearchRagSearchBackend.vectorSearch (kNN, dense_vector cosine)
        ├─ RRF 融合 + 词法加权 + minScore 截断
        └─ MySqlRagCandidateStore   → MySQL 回读，严格 ACL + 状态过滤
    → ES 异常时回退 MySQL 词法检索（严格 ACL）
```

### 新增组件

| 包 | 类 | 职责 |
| --- | --- | --- |
| `rag/elasticsearch` | `ElasticsearchClient` | JDK `HttpClient` + JSON-P 的 ES 客户端，非 2xx 抛带状态码与响应的异常 |
| | `RagIndexMapping` | 索引 settings 与 mappings，字段清单照搬 Spring 参考实现 |
| | `RagIndexManager` | 懒创建索引、别名 `is_write_index=true`、索引迁移、分块写入与删除 |
| | `RagChunkSourceFactory` | 把文档 + 分块 + 向量组装成 ES 文档体 |
| `rag/embedding` | `RagEmbeddingProvider` / `OllamaEmbeddingProvider` | 向量提供者接口与 Ollama 实现（`/api/embeddings` → `/api/embed` 回退） |
| | `RagEmbeddingTaskStore` / `MyBatisRagEmbeddingTaskStore` | 嵌入队列的持久化边界（认领、重试、毒化、重排） |
| | `RagEmbeddingWorker` | 任务工作器：互斥执行、时间预算、失败重试、成功标记 |
| `rag/access` | `RagAccessContext` | 服务端推导的调用者身份（用户 + 角色 + 部门） |
| | `RagAclPolicy` | `acl_scope` + `metadata` 明细的放行判定 |
| `rag/retrieval` | `RagSearchHit` / `RagSearchBackend` / `ElasticsearchRagSearchBackend` | 检索结果模型与 ES 检索后端 |
| | `HybridRetriever` | RRF 融合、词法加权、候选截断 |
| `rag/service` | `MySqlRagCandidateStore` | ES 命中回读 MySQL，严格收敛可见性 |
| | `RagDocumentDeletionService` | 事务化删除文档 / 分块 / 任务，提交后删 ES |
| | `RagBackfillJob` | 知识文档分块回填到嵌入队列 |
| | `RagQueryService` | ES 优先检索 + 异常回退 MySQL 词法 |

**零新依赖**：ES 与 Ollama 客户端都用 JDK 自带的 `HttpClient` 与 JSON-P
（`quarkus-rest-jsonb` 已带 parsson）实现，不引入官方 ES 客户端或 Ollama SDK。仓库既有先例：
`service/business/SearchService` 已经用 `HttpClient` 直连 ES。

## 索引与映射

| 项 | 值 | 说明 |
| --- | --- | --- |
| 物理索引 | `rag_chunk_quarkus_v1` | `rag.index.name`，与 Spring 的 `rag_chunk_v1` 隔离 |
| 写别名 | `rag_chunk_quarkus_current` | `rag.index.alias`，检索一律走别名 |
| 文档 `_id` | `chunk_id` | 重复写入即覆盖，天然幂等 |
| `embedding` | `dense_vector`，`dims=768`，`similarity=cosine` | 与 Spring 完全一致 |
| 分析器 | `standard` | 与 Spring 一致；中文召回弱于 IK，见风险 R2 |
| 分片 / 副本 | `1 / 0` | 与 Spring 一致 |
| `refresh_interval` | `30s` | 与 Spring 一致 |

字段清单（`keyword` 除非另注）：`chunk_id`、`document_id`、`content`（text）、`title`
（text + keyword）、`source_type`、`source_table`、`source_id`、`source_field`
（keyword + text）、`source_version`、`route`、`acl_scope`、`acl_roles`、`acl_user_ids`、
`acl_departments`、`embedding_provider`、`embedding_model`、`metadata`（object）、
`embedding`（dense_vector）。

索引生命周期：首次写入或查询前由 `ensureReady()` 懒创建；别名缺失时补建并标记
`is_write_index=true`；**别名已存在时不会被抢占**（可能指向别的物理索引）。写入始终落在物理
索引，检索走别名，两边不会指向不同的库。

## 嵌入链路

- 提供者：Ollama `POST /api/embeddings`（`{"model","prompt"}`），404 时回退
  `POST /api/embed`（`{"model","input"}`），与 Spring provider 同策略。
- 维度校验：向量长度必须等于 `rag.embedding.dimensions`（768），否则任务失败，**绝不写入
  ES、绝不置 `SUCCEEDED`**。
- 任务状态机：`PENDING → RUNNING → SUCCEEDED / FAILED → POISONED`。
  - 认领使用带状态条件的 UPDATE（`status IN (PENDING, FAILED)`），只有把状态改成 `RUNNING`
    成功的一方真正获得任务，多后端并发轮询不会重复处理。
  - `RUNNING` 超过 10 分钟视为被中断，重新排队。
  - 失败按 `retry-delay` 退避重试；`attempt_count` 达到 `max-attempts` 转 `POISONED`。
  - 分块或文档已不存在时直接 `POISONED`（无法重试）。
- 顺序是**先写 ES，再标记成功**：ES 写成功但数据库标记失败时，分块状态仍不是 `EMBEDDED`，
  检索侧会把它过滤掉，不会出现「索引里有、库里说没有」的脏召回。
- 单次 `/embedding/run` 有 20s 时间预算（`rag.embedding.request-budget`），超预算后不再开启
  新任务，剩余留给下一次调用，避免超出评测脚本的 60s 超时。
- **后台轮询默认关闭**（`rag.embedding.scheduler-enabled=false`）：`rag_embedding_task` 表由
  Spring / Go / Quarkus 共用，评测期间由 `/embedding/run` 显式驱动。

## 检索链路

### ES 侧

- BM25：`multi_match`（`title^4`、`content^3`、`source_field.text^1.5`、`source_type`、
  `source_table`）+ 两个 `match_phrase` 加成（2 / 1.5）。
- 向量：顶层 `knn`，`field=embedding`、`k=size`、`num_candidates=max(50, size*4)`。
- ACL 粗过滤：`bool.should`（`PUBLIC` / 命中角色 / 命中用户 / 命中部门）+
  `minimum_should_match: 1`。
- 别名缺失时自动回退到物理索引。

### 融合与排序

1. BM25 与 kNN 各取 `topK × candidateMultiplier`（默认 3）候选。
2. RRF 融合：`100 × weight / (60 + rank)`，权重 `0.8 / 0.2`。
3. `minScore`（默认 0.2）过滤。
4. ACL 后置过滤。
5. 词法加权（`rerank-lexical-weight=0.15`）：标题 0.45 / 正文 0.45 / 来源字段 0.10，
   分词用 `[\p{IsHan}]{2,}|[\p{Alnum}_]{2,}` 并为汉字串补 bigram。
6. 截断到 `topK`。

公式与顺序对齐 Spring 的 `HybridRetriever`。

### MySQL 严格收敛

ES 只做粗过滤，最终可见性以库里的行为为准。`MySqlRagCandidateStore` 对每条 ES 命中回读
chunk 与 document，并丢弃：

- MySQL 中不存在的分块（ES 残留）；
- 状态不是 `EMBEDDED` 的分块；
- 状态不是 `READY` 的文档；
- 非知识库来源（`source_type` 不是 `MANUAL` / `UPLOAD`）；
- ACL 不放行的文档。

**MySQL 回读是正确性兜底**：ES 删除失败或事务回滚都不会造成越权或脏召回。

### 降级

只有 ES 调用**抛异常**（连接失败、索引不存在、5xx）时才回退 MySQL 词法检索（同样严格 ACL）。
ES 正常返回空结果**不回退**，避免用词法结果掩盖向量检索缺陷。

### 检索结果异常排查

首次评测的采集阶段出现过一个症状：不同问题返回**完全相同**的 top-5，且 `finalScore` 依次是
0.3279 / 0.3226 / 0.3175 / 0.3125 / 0.3077。这组数恰好等于 `100 × 0.2 / (60 + rank)`，
说明 **只有向量侧（权重 0.2）参与融合，BM25 侧（权重 0.8）一条都没贡献**。

排查结论是**不是代码缺陷**，依据：

| 检查 | 结果 |
| --- | --- |
| 用后端完全相同的 BM25 / kNN 请求体直连 ES | 两者都正常，且结果随问题变化 |
| `POST /api/rag/query` 走完整链路 | 排序随问题变化，融合分约 1.6（BM25 0.8 + 向量 0.2 都在贡献） |
| ES 索引内容 | 31 条文档全部带 768 维向量，`acl_scope` 分布 PUBLIC 22 / ROLE 4 / USER 3 / DEPARTMENT 2 |
| 采集时间线 | 该次采集跨越了 11:32:00 的 Quarkus 开发模式热重载重启，样本来自重启前的实例 |

在已提交构建上重跑，症状不复现。详见「端到端评测（RAGAS）」一节的结果。

## 评测前修复

评测准备阶段暴露了四个与检索无关、但会直接阻断评测的缺陷，均已单独提交修复：

| 提交 | 现象 | 根因 | 修复 |
| --- | --- | --- | --- |
| `a2a50a4c` | 配置里把判官模型留空就起不来 | SmallRye 把空字符串按 `null` 处理，Quarkus 启动期拒绝「空串 String 属性」（SRCFG00040） | 判官模型改用 `Optional<String>`，「没配判官模型」回到文档承诺的「校验关闭」 |
| `a26198a4` | SSE 对话返回 503 `DEPENDENCY_TIMEOUT` | JWT 鉴权过滤器里的 Redis 黑名单检查是阻塞调用，跑在事件循环上会抛 `The current thread cannot be blocked` | 两个 SSE 入口补 `@Blocking`，语义与 `@RunOnVirtualThread` 一致 |
| `66de29e1` | 跑一段时间后所有读接口永久 503 | 负载拒流用 JAX-RS 响应过滤器配对「进入 / 离开」，被拒流、客户端断连、流式响应的请求走不到过滤器，计数只增不减 | 改用请求作用域 `InFlightRequest` + `@PreDestroy` 归还名额；`/actuator/prometheus` 暴露 `in_flight_requests` |
| `3b26af06` | 清理评测语料时 ES 日志刷 404 告警 | ES 删除不存在的文档返回 404，被当作异常抛出 | `deleteJson` 对 404 返回空对象，删除幂等 |

## ACL 规则

身份来源：JAX-RS `SecurityContext`。`userId` 取 principal name；角色集合按
`RagAccessContext.KNOWN_ROLES` 逐一询问 `isUserInRole`；部门按 Spring 的角色映射推导
（`SUPER_ADMIN` / `ADMIN` → `ALL`，`TRAFFIC_POLICE` / `FINANCE` / `APPEAL_REVIEWER` →
`DEPARTMENT`）。请求体中的 `roles` / `asRole` 一律忽略。

| `acl_scope` | 放行条件（metadata 键，兼容驼峰 / 下划线） | RAGAS 期望 |
| --- | --- | --- |
| `PUBLIC` / 空 | 无条件 | 所有语料主体可见 |
| `ROLE` | `roles` ∩ metadata(`roles`/`aclRoles`/`acl_roles`) ≠ ∅ | p01（`aclRoles=[SUPER_ADMIN]`）driver 不可见 |
| `USER` | `userId` ∈ metadata(`userIds`/`userId`/`aclUserIds`/`acl_user_ids`) | p02（`aclUserIds=[driver-1001]`）driver 不可见；控制文档（`userIds=[ce@ce.com]`）可见 |
| `DEPARTMENT` | `department` ∈ metadata(`departments`/`department`/`aclDepartments`/`acl_departments`) | p03（`aclDepartments=[finance]`）driver 不可见 |
| 其他 | 一律拒绝 | — |

`rag_document` 没有独立的 ACL 明细列，明细存放在 `metadata_json`（与 Spring 一致），由
`RagChunkSourceFactory` 写入 ES 的 `acl_roles` / `acl_user_ids` / `acl_departments` 三个
keyword 字段。

**与 Spring 相同的已知限制**：部门身份被折叠成字符串 `"DEPARTMENT"`，而语料里的部门明细是
`finance` 这类真实部门名，因此 DEPARTMENT 语料对任何调用者都不可见。这不是移植引入的偏差，
而是 Spring 参考实现本身的行为（RAGAS 报告的「附带发现」里同样点名），Quarkus 有意保持一致，
因此 p03 探针对 driver 与 admin 都是「不可见」，评测不会因此误判为泄漏。

## 管理端契约

| 端点 | 参数 | 行为 |
| --- | --- | --- |
| `POST /api/rag/admin/index/migrate` | `indexName`、`requeue`、`requeueLimit` | 不带 `indexName` 时幂等准备索引与别名（`createdIndex` / `aliasSwitched`）；带 `indexName` 时迁移到该索引并把写别名挪过去；`requeue=true` 时把全部分块重新排队（包含已标记 `EMBEDDED` 的分块） |
| `POST /api/rag/admin/embedding/run` | `limit` | 消费一批待嵌入任务，返回 `selectedTasks` / `succeededTasks` / `failedTasks` / `hasMore` / `alreadyRunning` |
| `POST /api/rag/admin/embedding/requeue` | `limit` | 把失败、中毒或未嵌入的分块重新排队 |
| `POST /api/rag/admin/backfill` | `page`、`size` | 知识文档回填：未嵌入的分块退回待嵌入并补建任务；已嵌入的不动 |
| `POST /api/rag/admin/backfill/run` | `startPage`、`size`、`maxPages` | 连续回填多页，返回 `processedPages` |
| `GET /api/rag/admin/documents` | `query`、`page`、`size`、`limit` | 关键字过滤含 `metadata_json`（评测语料靠 `metadata.suite` 识别） |
| `GET /api/rag/admin/documents/{id}` | - | 返回文档、正文与每个分块的 `embeddingStatus` / `embeddingModel` / `embeddingHash` / `updatedAt` |
| `DELETE /api/rag/admin/documents/{id}` | - | 事务内删除任务 → 分块 → 文档，提交后删 ES；返回 `{documents,chunks,tasks}` |
| `GET /api/rag/admin/overview` | - | 补充 `embeddingEnabled` / `indexName` / `indexAlias` / `indexExists`；ES 不可达时 `indexExists=false`，接口不失败 |

`/index/migrate` 与 `/backfill` 在 RAG 或 ES 关闭时返回 `409 RAG_DISABLED`。

**与 Spring 的差异**：Spring 的 `/backfill` 是把业务表（违法类型、申诉记录）重新抽进索引，
Quarkus 侧没有对应的抽取器，这里改为保证已有知识文档的向量是齐的。

## 配置

全部带默认值，可用环境变量或系统属性覆盖。

| 键 | 默认值 | 说明 |
| --- | --- | --- |
| `elasticsearch.host` | `${ELASTICSEARCH_HOST:http://localhost:9200}` | 复用既有键，`RunDocker` 的系统属性仍可覆盖 |
| `rag.elasticsearch.enabled` | `true` | ES 检索总开关 |
| `rag.index.name` / `rag.index.alias` | `rag_chunk_quarkus_v1` / `rag_chunk_quarkus_current` | 索引与别名 |
| `rag.index.text-analyzer` / `shards` / `replicas` / `refresh-interval` | `standard` / `1` / `0` / `30s` | 与 Spring 一致 |
| `rag.embedding.enabled` | `false` | 需显式开启（避免误连 Ollama） |
| `rag.embedding.provider` / `model` / `dimensions` | `ollama` / `nomic-embed-text` / `768` | 覆盖此前的 `unassigned` 默认 |
| `rag.embedding.base-url` | `${OLLAMA_BASE_URL:http://localhost:11434}` | 复用既有 Ollama 地址 |
| `rag.embedding.batch-size` / `max-attempts` / `retry-delay` / `timeout` | `25` / `3` / `1m` / `30s` | 任务状态机参数 |
| `rag.embedding.request-budget` | `20s` | 单次 `/embedding/run` 的时间预算 |
| `rag.embedding.scheduler-enabled` / `poll-interval` | `false` / `30s` | 后台轮询默认关闭，见风险 R1 |
| `rag.retrieval.enabled` | `true` | 混合检索开关 |
| `rag.retrieval.bm25-weight` / `vector-weight` | `0.8` / `0.2` | RRF 权重 |
| `rag.retrieval.min-score` | `0.2` | 融合分下限 |
| `rag.retrieval.candidate-multiplier` | `3` | 候选深度倍率 |
| `rag.retrieval.rrf-rank-constant` | `60` | RRF 常数 |
| `rag.retrieval.rerank-enabled` / `rerank-lexical-weight` | `true` / `0.15` | 词法加权 |
| `rag.mysql-fallback-enabled` | `true` | 仅 ES 异常时启用词法回退 |
| `AI_AGENT_ENABLED` | `true` | 评测时设为 `false` 进入纯 RAG |
| `AI_RAG_TOP_K` | `5` | 对话链路的默认 topK |

## 失败与降级矩阵

| 场景 | 行为 |
| --- | --- |
| ES 不可达 | 检索回退 MySQL 词法（严格 ACL）；`/embedding/run` 任务转 `FAILED`（可重试）；`/index/migrate` 返回 503；`overview.indexExists=false` |
| Ollama 不可达 / 模型缺失 | 任务 `FAILED` → 达 `max-attempts` 转 `POISONED`，`lastError` 写明原因；评测脚手架读到 `POISONED` 立即报错 |
| 向量维度不符（≠768） | 任务 `FAILED`，不写 ES，绝不置 `SUCCEEDED` |
| ES 索引 / 别名缺失 | 写入前 `ensureReady()` 懒创建；查询时缺失 → 走 MySQL 回退 |
| ES 删除失败 | 记 WARNING，MySQL 删除保留；ES 残留文档因 MySQL 回读过滤不会进入结果 |
| 事务回滚 | `AfterCommitBoundary` 不触发，ES 不发生删除；已写入的 ES 文档因分块状态非 `EMBEDDED` 被过滤 |
| 多后端抢任务 | 见风险 R1：`rag_embedding_task` 表被 Spring / Go / Quarkus 共用 |

## 验证

```bash
cd final_assignment_backend_quarkus
./gradlew --console=plain test
```

全量通过：48 个测试类、222 个用例、0 failure / 0 error（1 skipped 为既有跳过项）。
本轮新增 15 个测试类、111 个用例（ES 与混合检索 14 个类 / 107 个用例，评测前修复另加
`InFlightRequestTest` 的 4 个用例），并改写 `RagQueryServiceTest`（11 个用例，改为严格
ACL 语义）与 `ChatPipelineTest`（13 个用例，补充 ACL 断言）：

| 测试类 | 覆盖 |
| --- | --- |
| `ElasticsearchClientTest` | JDK `HttpServer` 起临时端口：成功、4xx、5xx、超时、404 视为不存在 |
| `RagIndexMappingTest` | 字段清单、dims、settings |
| `RagIndexManagerTest` | 索引已存在不重复创建、别名缺失才添加、别名存在不抢占、迁移后写入落到目标索引 |
| `RagChunkSourceFactoryTest` | ES 文档体字段与 ACL 明细 |
| `OllamaEmbeddingProviderTest` | `/api/embeddings` 成功、404 回退 `/api/embed`、维度不符、坏 JSON |
| `RagEmbeddingWorkerTest` | 成功 → `SUCCEEDED`、失败 → `FAILED` → 重试 → `POISONED`、维度不符不写 ES、互斥执行 |
| `RagAclPolicyTest` | 四种 scope、metadata 键名变体、RAGAS p01/p02/p03 与控制文档夹具 |
| `HybridRetrieverTest` | RRF 权重与名次、去重、`minScore` 截断、ACL 后置过滤、词法加权 |
| `ElasticsearchRagSearchBackendTest` | BM25 / kNN 请求体、ACL 过滤、别名回退 |
| `MySqlRagCandidateStoreTest` | 未嵌入 / 文档未就绪 / 非知识库 / ACL 拒绝的分块一律丢弃 |
| `RagQueryServiceTest` | 严格 ACL 语义、ES 异常回退、ES 空结果不回退、topK 上限 50 |
| `RagQueryControllerTest` | 伪造请求体角色无效、topK 夹取、空查询 400 |
| `RagManagementControllerTest` | metadata 过滤、overview 字段、删除计数、迁移与回填 |
| `RagDocumentDeletionServiceTest` | 无事务时立即删 ES；ES 失败不回滚 MySQL |
| `RagBackfillJobTest` | 无任务分块补建、已 `EMBEDDED` 分块不重复排队、单文档失败不影响整页 |
| `InFlightRequestTest` | 在飞名额进入 / 归还配对，重复归还与未持有时不计数 |

**端到端验证已完成**：本地同时具备 Elasticsearch、Ollama（`nomic-embed-text` / `qwen2.5:7b` /
`bge-m3` / `llama3.2`）、MySQL 与 Redis；评测期间只有 Quarkus 后端在跑，不存在多后端抢嵌入
任务的情况。结果见下节。

## 端到端评测（RAGAS）

### 前置条件

- Elasticsearch 可用（`xpack.security.enabled=false`），地址由 `ELASTICSEARCH_HOST` 指定。
- Ollama 已拉取 `nomic-embed-text`（嵌入）、`qwen2.5:7b`（主题判官）、`bge-m3`、`llama3.2`。
- MySQL 与 Redis 正常，`rag_document` / `rag_chunk` / `rag_embedding_task` 三张表已存在。
- **Spring 与 Go 的嵌入 worker 已停用**（见风险 R1）。本次评测环境里只有 Quarkus 一个后端
  进程在监听，因此该风险实际不存在。

### 步骤

```bash
# 1. 启动 Quarkus（默认端口 8080）
cd final_assignment_backend_quarkus
AI_AGENT_ENABLED=false AI_RAG_ENABLED=true \
AI_GUARDRAIL_CITATION_ENFORCEMENT=true AI_GUARDRAIL_TOPIC_VERIFICATION=true \
AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b \
RAG_EMBEDDING_ENABLED=true RAG_EMBEDDING_PROVIDER=ollama \
RAG_EMBEDDING_MODEL=nomic-embed-text RAG_EMBEDDING_DIMENSIONS=768 \
ELASTICSEARCH_HOST=http://localhost:9200 OLLAMA_BASE_URL=http://localhost:11434 \
./gradlew quarkusDev

# 2. 准备索引与别名
curl -X POST http://localhost:8080/api/rag/admin/index/migrate
# 期望 createdIndex=true；GET http://localhost:9200/_cat/aliases 能看到 rag_chunk_quarkus_current

# 3. 执行评测
cd scripts/ragas
RAGAS_BASE_URL=http://localhost:8080 RAGAS_ES_URL=http://localhost:9200 \
RAGAS_INDEX_ALIAS=rag_chunk_quarkus_current RAGAS_TARGET_LABEL="Quarkus" \
uv run ragas-eval preflight
uv run ragas-eval seed --cleanup
uv run ragas-eval run --top-k 5
```

`AI_GUARDRAIL_CITATION_ENFORCEMENT=true` 是与 Spring 基线对齐的**必要条件**：Spring 基线是开着
引用强制跑出来的，Quarkus 默认关闭时无引用的回答会直接透传，引用合规率与拒答统计都不可比。

### 验收标准

| 指标 | 目标 |
| --- | --- |
| 种子文档 | 22 条语料 + 1 控制文档全部 `embeddingStatus=SUCCEEDED` |
| ES 可见性 | `wait_for_index_visibility` 通过（`source_id` 聚合命中全部种子） |
| 控制文档 | `control_visible=true`（依赖 `MAX_TOP_K ≥ 50`） |
| ACL 泄漏 | p01 / p02 / p03 全部 `leaked=false` |
| 引用合规 | ≥ 0.9（对齐 Spring 基线） |
| 不可答拒答 | 3/3 拒答（字节级匹配拒答文案） |
| RAGAS 指标 | 与 Spring 基线偏差 ≤ 0.03（Faithfulness 0.9907 / Relevancy 0.8521 / Precision 0.9949 / Recall 0.9815 / Correctness 0.7713），偏差需在文档中解释 |
| 清理 | 仅删除 `metadataJson.suite=="ragas"` 的文档；清理后 `POST /_refresh` 后该批 `source_id` 命中数为 0 |

> 偏差带 0.03 是在**单次运行**的前提下设定的。实测两次运行的生成侧配对差就有 −0.0370，
> 因此这条带只对**检索侧**指标（Context Precision / Context Recall）有统计意义；生成侧指标
> 需要多次运行取中位数。下面「运行间稳定性」一节给出实测噪声。

### 结果

本轮共跑三次评测，`artifacts/ragas/`（gitignored）下的 run id 如下：

| 运行 | run id | 采集时配置 | 用途 |
| --- | --- | --- | --- |
| A | `20261029T041203Z-3b26af06` | 引用强制**关闭** | 反例：证明引用强制是基线可比的前提；同时提供检索一致性证据 |
| B | `20261029T045537Z-3b26af06` | 引用强制**开启** | 与 Spring 基线对齐的主结果 |
| C | `20261029T054721Z-3b26af06` | 引用强制**开启**，无并发负载 | 稳定性复跑 |

三次运行的 manifest 与 Spring 基线**逐项一致**：数据集 hash `292298fd…`、golden set hash
`d8d8659a…`、语料 hash `42a579af…`、topK 5、答案模型 `llama3.2`、裁判 `qwen2.5:7b`、裁判嵌入
`bge-m3`、产品嵌入 `nomic-embed-text`（四个模型的 digest 也相同）、语料 31 条、
`control_visible=true`。因此两边的分数可以直接比较。

#### 主结果（运行 B）

| 指标 | Spring 基线 | Quarkus（运行 B） | 差值 | 判定 |
| --- | ---: | ---: | ---: | --- |
| Faithfulness | 0.9907 | 0.9638 | −0.0269 | 达标 |
| Response Relevancy | 0.8521 | 0.8701 | +0.0180 | 达标 |
| Context Precision | 0.9949 | 0.9552 | −0.0397 | **超出 0.03，见下** |
| Context Recall | 0.9815 | 0.9828 | +0.0013 | 达标 |
| Answer Correctness | 0.7713 | 0.8117 | +0.0404 | **超出 0.03，但方向为优** |
| 引用合规 | 0.9000 | 0.9667 | +0.0667 | 达标 |
| 可评分覆盖 | 27/30（0.90） | 29/30（0.9667） | +0.0667 | 达标 |
| 不可答拒答 | 3/3 | 3/3 | 0 | 达标 |
| ACL 泄漏 | 0/3 | 0/3 | 0 | 达标 |
| 上下文漂移 / fallback / provider 错误 | 0 / 0 / 0 | 0 / 0 / 0 | 0 | 达标 |
| 护栏拒答 | 3（a10 uncited、a16/a28 误拒） | 1（a10 uncited） | −2 | 优于基线 |
| 硬失败 | 无 | 无 | — | 达标 |

两项超出 0.03 的偏差都能归因，且**不是检索退化**：

- **Context Precision −0.0397**：几乎全部来自样本集合差异，不是上下文变差。两边都评分的 26 个
  样本上，配对差只有 **−0.0064**。差值来自 a28（「车辆年检和过户分别需要办理什么？」，多跳题）：
  Spring 的主题校验把它**误拒**了（`refusal-2026-10-29.md` 已记录该误拒），因此没有分数；
  Quarkus 正常作答，裁判给出 context precision 0.0——检索到的首条覆盖年检、次条覆盖过户，
  但裁判按「逐字覆盖」的严格口径判为不相关。这是 Spring 的误拒被消除后暴露出来的题目，
  不是 Quarkus 检索更差。
- **Answer Correctness +0.0404**：方向为优，来自答案生成侧的采样波动，不是检索差异。配对差
  +0.0326，样本内正负相抵：a13 +0.4061、a19 +0.3001、a04 +0.2453 对 a11 −0.2517、
  a07 −0.1176、a25 −0.1037。同样的模型与提示词，不同采样得到不同的事实分解质量。

#### 运行 C（稳定性复跑）

| 指标 | Spring 基线 | 运行 B | 运行 C | B↔C 配对差 |
| --- | ---: | ---: | ---: | ---: |
| Faithfulness | 0.9907 | 0.9638 | 0.9315 | −0.0370 |
| Response Relevancy | 0.8521 | 0.8701 | 0.8378 | −0.0289 |
| Context Precision | 0.9949 | 0.9552 | 0.9889 | **0.0000** |
| Context Recall | 0.9815 | 0.9828 | 0.9815 | **0.0000** |
| Answer Correctness | 0.7713 | 0.8117 | 0.7902 | −0.0214 |
| 引用合规 | 0.9000 | 0.9667 | 0.9000 | — |
| 可评分覆盖 | 27/30 | 29/30 | 27/30 | — |
| 护栏拒答 | 3 | 1 | 3 | — |
| 硬失败 | 无 | 无 | 无 | — |

配对差取两次运行都评分的 27 个可答样本；与 Spring 基线对比时取双方都评分的样本
（26–27 个，取决于被拒答的题目是否重合）。

运行 C 相对基线：Faithfulness −0.0592（超出 0.03），Relevancy −0.0143、Context Precision
−0.0060、Context Recall 0.0000、Answer Correctness +0.0189（均在带内）。**同一个构建，一次
运行全部达标、另一次运行有一项超出**，这本身说明验收带与运行噪声同量级。

#### 运行间稳定性

| 维度 | B ↔ C | 判定 |
| --- | --- | --- |
| 检索结果（同序同集） | 36/36 完全一致 | 检索层**确定性** |
| Context Precision / Context Recall 配对差 | 0.0000 / 0.0000 | 由检索决定，**零噪声** |
| Faithfulness 配对差 | −0.0370（单题最大 −1.0000） | 生成侧噪声大于验收带 |
| Response Relevancy 配对差 | −0.0289（单题最大 −0.2191） | 同上 |
| Answer Correctness 配对差 | −0.0214（单题最大 −0.3485） | 同上 |
| 答案文本不同 | 21/36 | 生成每次采样都不同 |
| 护栏拒答集合 | B={a10}，C={a10, a28, a30} | 主题校验随采样摆动 |

结论：**「与基线偏差 ≤ 0.03」只对检索侧指标成立**。检索由 ES 命中与 MySQL 回读决定，
同一构建逐次可复现（36/36）；答案由 `llama3.2` 采样生成，配对差本身就能达到 −0.0370，
因此对 Faithfulness / Relevancy / Answer Correctness 谈 0.03 量级的偏差没有统计意义。
两次 Quarkus 运行与 Spring 基线在检索侧指标上的差距是 **−0.0064 / 0.0000**。

运行间差异最大的三题都可解释：

- **a25**（缴纳罚款支持微信或支付宝吗？）：运行 C 的答案是「[1] 罚款需在十五日内缴纳。」——
  答非所问，faithfulness 从 1.0 掉到 0.0，answer correctness 掉到 0.19。检索结果三次完全
  相同，属于纯生成侧的采样事故。
- **a30**（申诉材料与退款）：运行 C 被主题校验误拒（`no_source`），运行 B 与 Spring 正常作答。
- **a28**（年检与过户）：Spring 误拒，运行 B 正常作答，运行 C 又误拒。

#### 检索一致性

把三次运行采集到的 `sourceId` 列表与 Spring 基线逐题对比（36 题，含 30 可答 + 3 不可答 + 3 探针）：

| 对比项 | 运行 A | 运行 B | 运行 C |
| --- | --- | --- | --- |
| 与 Spring **顺序完全一致** | 31/36 | 31/36 | 31/36 |
| 与 Spring **集合一致** | 35/36 | 35/36 | 35/36 |
| 两次 Quarkus 运行之间完全一致 | — | 36/36 | 36/36 |

唯一有差异的是 a04：Spring 的第 3 条是 `c-fine-refund`，Quarkus 是 `c-fine-payment-guide`，
两者都在 top-5 内、分数接近。其余 35 题的检索结果与 Spring **逐条相同**。检索链路的移植是
忠实的。

#### 护栏行为

三次运行的护栏拒答集合：

| 运行 | 拒答样本 | 数量 |
| --- | --- | --- |
| Spring 基线 | a10（uncited）、a16 / a28（no_source） | 3 |
| 运行 B | a10（uncited） | 1 |
| 运行 C | a10（uncited）、a28 / a30（no_source） | 3 |

a10 的「无引用」拒答在三次运行中稳定复现，说明引用强制与引用修复链路是确定性生效的；
主题校验（`no_source`）则随采样摆动，两端都会在多跳题上误拒——它是 Spring 参考实现继承来的
边缘判定，不是 Quarkus 移植引入的缺陷。可评分覆盖因此在 27/30 与 29/30 之间浮动。

#### 运行 A（引用强制关闭）作为反例

| 指标 | 运行 A | 运行 B | 运行 C | Spring 基线 |
| --- | ---: | ---: | ---: | ---: |
| Faithfulness | 0.9467 | 0.9638 | 0.9315 | 0.9907 |
| Context Precision | 0.9567 | 0.9552 | 0.9889 | 0.9949 |
| Answer Correctness | 0.7634 | 0.8117 | 0.7902 | 0.7713 |
| 引用合规 | 0.8667 | 0.9667 | 0.9000 | 0.9000 |
| 可评分覆盖 | 30/30 | 29/30 | 27/30 | 27/30 |
| 护栏拒答 | 0 | 1 | 3 | 3 |

关闭引用强制时，a10 / a11 / a19 / a20 四个无引用回答被直接透传，引用合规率掉到 0.8667、
可评分覆盖虚高到 30/30——**分数看起来更「完整」，实际是护栏没生效**。这也解释了为什么
Quarkus 的引用强制默认值虽然仍是 `false`，评测必须显式打开。

### 清理范围

`seed --cleanup` 的实现只删除 `metadataJson.suite == "ragas"` 的文档（`cleanup_suite_documents`
逐条解析 `metadata_json` 后过滤），清理范围由构造保证。评测结束后的实测：

| 位置 | 清理前 | 清理后 |
| --- | --- | --- |
| MySQL `rag_document` | 43 条（31 条 `suite=ragas` + 12 条无 suite） | 12 条（全部为共享的非 ragas 语料） |
| ES `rag_chunk_quarkus_current` 上该批 `source_id` 命中 | 31 | **0**（`POST /_refresh` 后复核） |

共享的 12 条 `perf-rag-*` 语料（Spring 侧播种，3 个版本 × 4 条）从未进入 Quarkus 索引，
清理过程不涉及它们，清理后仍完整保留。

## 风险与边界

- **R1 多后端抢嵌入任务（最高风险）**：`rag_embedding_task` 是 Spring / Go / Quarkus 共用表。
  Spring 的 `selectPendingTasks` 只按状态过滤，会抢走 Quarkus 的种子任务并写进 Spring 的索引，
  导致 Quarkus 索引为空、评测结果不可信。对策：Quarkus 侧后台轮询默认关闭，评测期间由
  `/embedding/run` 显式驱动；**评测前必须停用 Spring / Go 的嵌入 worker**（停止占用 9380 的
  Spring 后端进程属于破坏性操作，需要人工确认；替代方案是用独立 MySQL schema 跑 Quarkus
  评测）。
- **R2 中文分词**：`standard` 分析器对中文按字切分，效果弱于 IK。本次与 Spring 保持一致，
  若召回不达标再单独评估分析器插件（需要 ES 镜像安装插件）。
- **R3 引用强制门禁**：`AI_GUARDRAIL_CITATION_ENFORCEMENT` 在 Quarkus 仍默认 `false`。本轮已经
  拿到评测证据（运行 A 证明关闭时引用合规只有 0.8667、无引用回答被直接透传；运行 B 打开后
  引用合规 0.9667、拒答与 Spring 基线可比），但把默认值改成 `true` 属于改变默认行为，需要单独
  提交并复核其它链路的回归，不在本次范围内。评测时必须显式打开。
- **R4 回填语义差异**：Spring 的回填面向业务表抽取，Quarkus 的回填面向知识文档分块，两者
  指标不可直接对比。
- **R5 环境差异**：Quarkus 默认端口 8080（RAGAS 默认 9080 是 Spring），评测必须显式设置
  `RAGAS_BASE_URL`；索引别名必须显式设置 `RAGAS_INDEX_ALIAS=rag_chunk_quarkus_current`。
- **R6 依赖共享**：`rag_embedding_task` 与 `rag_chunk` 表由多个后端共享，跨后端并发写入时
  分块状态与向量可能不一致；`MySqlRagCandidateStore` 的回读过滤会把这类分块排除在结果之外，
  但不会自动修复。
- **R7 评测带低于生成侧噪声底**：同一构建两次运行的 Faithfulness 配对差就有 −0.0370（单题
  最大 −1.0），因此「与基线偏差 ≤ 0.03」只对检索侧指标（Context Precision / Context Recall，
  两次运行配对差均为 0.0000）有统计意义；对生成侧指标应当看多次运行的中位数，或把带宽放宽到
  与噪声同量级。单次运行的差异不能直接当作回归。
- **R8 主题校验是边缘判定**：`no_source` 拒答在多跳题上随采样摆动（Spring 拒 a16/a28，
  Quarkus 运行 B 拒 a28、运行 C 拒 a28/a30），两端都会误拒。这是 Spring 参考实现继承来的
  行为，不是移植缺陷；若要降低误拒率，需要调整主题校验的判定口径（单独议题）。

