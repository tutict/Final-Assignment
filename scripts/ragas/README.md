# RAGAS 答案质量评估

离线评估后端 RAG 的答案质量（默认 Spring 主后端，也可指向 Spring Cloud）。与 CI 中的 `RagRetrievalQualityTest`（只评估 recall/MRR/nDCG）互补：
本工具回答“检索到的资料是否被正确、忠实、可引用地用于回答”。

评估使用真实产品链路：同一 `ChatPipeline`、同一提示词、同一 Ollama 模型与引用护栏。检索上下文来自
`POST /api/rag/query`（与聊天相同的身份、问题与 topK），答案来自 `POST /api/ai/chat/stream`。

## 前提

- 必须使用 `uv` 管理的 CPython 3.12；系统 Python 可能是 GraalPy，不能直接运行。
- ES / MySQL / Redis 已启动（`scripts/start-dev.ps1`）。
- 后端以**纯 RAG 模式**启动，否则知识问题会被 Agent 工具路由截走：

```bash
cd finalAssignmentBackend
AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true mvn spring-boot:run
```

- 建议用独立索引评估，避免既有语料污染检索；服务端与评测端的 alias 必须一致：

```bash
RAG_INDEX_NAME=rag_chunk_ragas_v1 RAG_INDEX_ALIAS=rag_chunk_ragas_current \
AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true mvn spring-boot:run

export RAGAS_INDEX_ALIAS=rag_chunk_ragas_current
```

- Ollama 模型：

```bash
ollama pull nomic-embed-text   # 产品检索嵌入（768 维，写入索引）
ollama pull qwen2.5:7b         # RAGAS 裁判
ollama pull bge-m3             # RAGAS 相似度嵌入（仅评测侧）
```

产品答案模型由服务端 `OLLAMA_MODEL` 决定（默认 `llama3.2`）。本工具不修改服务端模型，只在 manifest 中记录。
`RAGAS_OLLAMA_URL` 必须指向裁判与评测嵌入实际所在的 Ollama 实例；Windows 上若同时存在多个
实例，`localhost` 与 `127.0.0.1` 可能命中不同实例，建议显式填写地址。

## 快速开始

```bash
cd scripts/ragas
cp .env.example .env           # 按需修改账号、模型与 URL
uv sync                        # 首次生成 uv.lock；之后可用 --frozen
uv run pytest
uv run ragas-eval validate
uv run ragas-eval preflight
uv run ragas-eval seed
uv run ragas-eval run --limit 3   # 冒烟：每种类型 3 题
uv run ragas-eval run --top-k 5   # 全量基线
```

一键执行（预检 → 写入 → 评估）：

```bash
uv run ragas-eval all --top-k 5
```

清理 RAGAS 文档（只删除 `metadataJson.suite == "ragas"` 的记录，不触碰其它知识库数据）：

```bash
uv run ragas-eval seed --cleanup
```

## 评测 Spring Cloud 后端

默认配置面向 Spring 主后端（`finalAssignmentBackend`）。同一套数据集与评分流程无需改代码即可指向
`finalAssignmentCloud`：Cloud 拆为网关 + 业务服务 + AI + RAG，评测统一从网关进入。Cloud 的数据集、seed
载荷、SSE 事件、管理接口契约、检索融合权重（BM25 0.8 / 向量 0.2、候选深度倍率 3）与主后端一致。

```powershell
# 启动含 AI 模块的 Cloud 栈；8080 被主后端占用时换一个网关端口
$env:AI_AGENT_ENABLED = "false"
$env:AI_RAG_ENABLED = "true"
$env:RAG_RETRIEVAL_ENABLED = "true"
$env:RAG_INDEX_NAME = "rag_chunk_ragas_v1"
$env:RAG_INDEX_ALIAS = "rag_chunk_ragas_current"
powershell -ExecutionPolicy Bypass -File scripts\start-cloud-backend.ps1 -IncludeAi -GatewayPort 18080
```

```bash
cd scripts/ragas
RAGAS_BASE_URL=http://127.0.0.1:18080 \
RAGAS_TARGET_LABEL="Spring Cloud 后端" \
RAGAS_INDEX_ALIAS=rag_chunk_ragas_current \
uv run ragas-eval all --top-k 5
```

- `RAGAS_TARGET_LABEL` 只写入 `manifest.json` 与报告环境表，用于区分同一数据集在不同后端的运行。
- Cloud 与主后端共用同一 MySQL `traffic` 库，`RAGAS_DRIVER_*` / `RAGAS_ADMIN_*` 默认账号通常可直接复用。
- ES / Redis / MySQL 不在默认端口时，服务端覆盖 `ELASTICSEARCH_URIS`、`SPRING_DATA_REDIS_PORT`、
  `SPRING_DATASOURCE_URL` 等；评测端覆盖 `RAGAS_ES_URL`（就绪检查用）。
- Cloud 的 RAG 服务以独立进程运行，`RAG_INDEX_NAME` / `RAG_INDEX_ALIAS` 必须与该进程一致；AI 服务通过
  Feign 访问 RAG，纯 RAG 模式必须关闭 `AI_AGENT_ENABLED` 并开启 `AI_RAG_ENABLED`。

## 数据集

`dataset/ragas-dataset.json`：

- 30 条可回答的 PUBLIC 问题，覆盖 `finalAssignmentBackend/src/test/resources/rag-eval/golden-set.json`
  的全部 22 个 PUBLIC 语料块，其中 4 条为多跳。
- 3 条不可回答问题，用于统计拒答/幻觉，不进入 RAGAS 均值。
- 3 条 ACL 探针：USER 查询管理员日志、错误用户查“我的违法记录”、无部门身份查部门规程。

语料写入时 `sourceId` 直接使用 golden `chunkId`，因此检索返回的 `sourceId` 与数据集可精确对齐。
`golden-set.json` 只读，本工具不修改它。

就绪检查分两层：先逐文档确认全部 chunk 的嵌入任务为 `SUCCEEDED`，再在 `RAGAS_INDEX_ALIAS`
上按 `source_id` 做 term 查询，确认每个 `sourceId` 已可检索。这里不依赖 topK 语义排序，
因为排序质量本身就是被评估对象；查询接口只额外做一次“非空上下文”冒烟。

## 评分与排除规则

RAGAS 指标（`ragas 0.4.3`）：Faithfulness、Response Relevancy、LLM Context Precision (with reference)、
LLM Context Recall、Answer Correctness。

Answer Correctness 单独评测：裁判 `num_predict=2048`、`max_workers=1`，缺失行串行重试；其余四项并行。
512-token 上限会截断长中文答案的陈述拆分，使 AC 假性归零。

以下样本不进入 RAGAS 均值，并在报告中单独计数：

- 检索为空
- 上下文超过 `ContextBuilder` 的 1200 token 预算
- 回答前/后两次检索的 `sourceId` 列表不一致（上下文漂移）
- provider fallback、流式错误、Agent 事件（`queue`/`tool` 等）
- 引用护栏拒答（`NO_SOURCE_ANSWER` / `UNCITED_ANSWER`）
- 空答案、RAGAS 评分失败

引用合规率按“答案包含至少一个有效 `[n]` / `【n】`”统计；ACL 探针只做硬断言，任何受限 `sourceId`
出现即视为泄漏。不可回答问题只统计拒答率。

首轮阈值写在 `targets.json`，`enforce: false` 时仅为 advisory；硬失败只有 ACL 泄漏、上下文漂移、
provider 错误、RAGAS 评分失败与预检失败。基线评审后可用 `--enforce` 启用分数阈值。

## 输出

`artifacts/ragas/<run-id>/`（gitignored）：

- `manifest.json`：git commit、数据集/语料 hash、模型 tag 与 digest、RAGAS 版本、topK、模式。
- `samples.jsonl`：逐题问题、上下文 sourceId、答案、引用、fallback、延迟、指标。
- `metrics.json`：聚合均值、可评分覆盖、切片（多跳/不可回答/ACL）、排除原因。
- `report.md`：中文报告，含总表、最差样例、ACL 与不可回答问题结果、附带发现、复现命令。

## 已知限制

- 裁判模型输出格式不稳时，先用 `--limit 3` 验证；失败可降低 `--max-workers`、提高
  `--metric-timeout`，不要盲目重试掩盖格式错误。
- `llama3.2` 的中文与引用能力有限；提示词已要求“仅依据上下文、使用 `[n]` 引用、上下文不足时明确说明”，
  但低分应如实呈现，必要时用 `OLLAMA_MODEL=qwen2.5:7b` 重启服务做对照（不改变基线）。
- 已知 DEPARTMENT ACL 缺陷（未在本工具中绕过）：真实接口把部门身份折叠为字符串 `"DEPARTMENT"`，
  而 `AclFilterService` 按真实部门名匹配，DEPARTMENT 语料对任何人不可见。ACL 探针只覆盖 ROLE/USER。
- RAGAS 需要 ES + MySQL + Redis + Ollama，不适合放进现有 CI；CI 继续只跑确定性的检索门禁。
