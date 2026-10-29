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
  与 Spring 的 `rag_chunk_v1` / `rag_chunk_current` 隔离：Spring 索引里是 768 维
  `nomic-embed-text` 向量，Go 是 384 维确定性向量，共用索引会互相覆盖。
- 单元测试全部通过（47 个测试类、217 个用例、0 failure / 0 error）。
- **RAGAS 端到端本轮尚未执行**，因此本文不给出 Quarkus 的 RAGAS 指标。第十二节给出复现步骤
  与验收标准，并列出会阻塞评测的前置条件（其中「停用 Spring / Go 的嵌入 worker」需要人工
  确认，见第十一节风险 R1）。

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

全量通过：47 个测试类、217 个用例、0 failure / 0 error（1 skipped 为既有跳过项）。
本轮新增 14 个测试类、106 个用例，并改写 `RagQueryServiceTest`（11 个用例，改为严格 ACL
语义）与 `ChatPipelineTest`（13 个用例，补充 ACL 断言）：

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

**未做端到端手工验证**：本地没有同时具备 ES、Ollama 嵌入模型与完整 MySQL/Redis 的运行环境，
且评测前需要停用 Spring / Go 的嵌入 worker。因此本文不宣称 Quarkus 的 RAGAS 指标。

## 端到端评测（RAGAS）

### 前置条件

- Elasticsearch 可用（`xpack.security.enabled=false`），地址由 `ELASTICSEARCH_HOST` 指定。
- Ollama 已拉取 `nomic-embed-text`（嵌入）、`qwen2.5:7b`（主题判官）、`bge-m3`、`llama3.2`。
- MySQL 与 Redis 正常，`rag_document` / `rag_chunk` / `rag_embedding_task` 三张表已存在。
- **Spring 与 Go 的嵌入 worker 已停用**（见风险 R1）。

### 步骤

```bash
# 1. 启动 Quarkus（默认端口 8080）
cd final_assignment_backend_quarkus
AI_AGENT_ENABLED=false AI_RAG_ENABLED=true \
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

### 状态

**本轮未执行。** 执行前需要先解决风险 R1，并保证 ES 与 Ollama 环境就绪。指标留待复跑后
补写到本节与 README。

## 风险与边界

- **R1 多后端抢嵌入任务（最高风险）**：`rag_embedding_task` 是 Spring / Go / Quarkus 共用表。
  Spring 的 `selectPendingTasks` 只按状态过滤，会抢走 Quarkus 的种子任务并写进 Spring 的索引，
  导致 Quarkus 索引为空、评测结果不可信。对策：Quarkus 侧后台轮询默认关闭，评测期间由
  `/embedding/run` 显式驱动；**评测前必须停用 Spring / Go 的嵌入 worker**（停止占用 9380 的
  Spring 后端进程属于破坏性操作，需要人工确认；替代方案是用独立 MySQL schema 跑 Quarkus
  评测）。
- **R2 中文分词**：`standard` 分析器对中文按字切分，效果弱于 IK。本次与 Spring 保持一致，
  若召回不达标再单独评估分析器插件（需要 ES 镜像安装插件）。
- **R3 引用强制门禁**：`AI_GUARDRAIL_CITATION_ENFORCEMENT` 在 Quarkus 仍默认 `false`，只有在
  有评测证据后才单独开启。
- **R4 回填语义差异**：Spring 的回填面向业务表抽取，Quarkus 的回填面向知识文档分块，两者
  指标不可直接对比。
- **R5 环境差异**：Quarkus 默认端口 8080（RAGAS 默认 9080 是 Spring），评测必须显式设置
  `RAGAS_BASE_URL`；索引别名必须显式设置 `RAGAS_INDEX_ALIAS=rag_chunk_quarkus_current`。
- **R6 依赖共享**：`rag_embedding_task` 与 `rag_chunk` 表由多个后端共享，跨后端并发写入时
  分块状态与向量可能不一致；`MySqlRagCandidateStore` 的回读过滤会把这类分块排除在结果之外，
  但不会自动修复。
