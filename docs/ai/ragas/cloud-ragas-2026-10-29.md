# Spring Cloud 后端 RAGAS 评测报告（2026-10-29）

本报告记录 `finalAssignmentCloud` 在**当前代码**（已含生成后主题校验）下的 RAGAS 端到端评测结果，
并与 Spring 主后端基线逐题配对比较。上一轮结果见
[cloud-parity-2026-10-28.md](cloud-parity-2026-10-28.md)（那一轮尚未移植主题校验，拒答率 0/3）；
本轮的重点是验证「拒答能力移植到微服务链路后是否与单体一致」。

## 结论摘要

- Cloud 在纯 RAG 模式下**全部指标达标**：Faithfulness 0.9658、Response Relevancy 0.8435、
  Context Precision 0.9536、Context Recall 0.9821、Answer Correctness 0.7451、引用合规 0.9333，
  fallback / 上下文漂移 / provider 错误 / ACL 泄漏均为 0，无硬失败。
- **拒答能力生效**：3 道不可答题全部拒答（上一轮 0/3），3 条 ACL 探针全部未泄漏。
- 与 Spring 基线配对（26 道共同可评分题）差距很小：Faithfulness −0.0080、Relevancy −0.0047、
  Context Precision −0.0067、Context Recall **±0.0000**、Answer Correctness −0.0357。
- 检索层与 Spring 基线几乎完全一致：36/36 同集合、35/36 同顺序，唯一差异是 a19 第 3/4 位
  （`c-offense-notice` ↔ `c-appeal-process`）的一次并列名次互换。
- 本轮代价是两题被「无引用」护栏误拒（a10、a20），可评分覆盖 28/30，仍高于 0.90 的评估线。

## 范围与方法

- 后端：`finalAssignmentCloud`，网关 18090（8080 被 Go 后端占用）、RAG 18088、AI 18086；
  `dev` profile，静态服务发现，`AI_AGENT_ENABLED=false`、`AI_RAG_ENABLED=true`、
  `RAG_RETRIEVAL_ENABLED=true`。
- 检索：网关转发到 Cloud RAG 的 `POST /api/rag/query`，Elasticsearch BM25 + kNN 加权 RRF
  （BM25 0.8 / 向量 0.2，候选深度倍率 3，词法 rerank 0.15），topK=5。
- 语料：索引 `rag_chunk_ragas_v1` / 别名 `rag_chunk_ragas_current`，与 Spring 基线**同一份语料**
  （31 篇，`metadata.suite=ragas`，向量为 Ollama `nomic-embed-text` 768 维）。本轮由 Cloud 的
  管理接口重新写入：文档主键与分块主键都是内容哈希的确定性结果，因此写回的是与 Spring 种子
  完全相同的行与同一批 ES 文档（`rag_chunk_ragas_current` 计数仍为 31，无重复文档）。
- 答案：网关转发到 Cloud AI 的 `POST /api/ai/chat/stream`，`llama3.2`，`temperature=0.2`；
  引用护栏开启（`AI_GUARDRAIL_CITATION_ENFORCEMENT=true`），生成后主题校验由
  `AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b` 开启。
- 裁判：`qwen2.5:7b`，评测嵌入 `bge-m3`，RAGAS 0.4.3；AC 独立以 `num_predict=2048`、单并发执行。
- 数据集：30 道可回答题（22 个 PUBLIC 语料块、4 道多跳）、3 道不可回答题、3 道 ACL 探针；
  `golden-set.json` 未修改。dataset / golden / corpus hash 与 Spring 基线、Go、Quarkus 三轮完全一致。

对比对象为主后端 `20261029-refusal-verifier`（同数据集、同语料、同模型、同裁判、topK=5）。

## 指标总表

| 指标 | 均值 | 目标 | 结果 |
| --- | ---: | ---: | --- |
| Faithfulness | 0.9658 | 0.7500 | PASS |
| Response Relevancy | 0.8435 | 0.7500 | PASS |
| Context Precision (with reference) | 0.9536 | 0.6000 | PASS |
| Context Recall | 0.9821 | 0.8500 | PASS |
| Answer Correctness | 0.7451 | 0.5500 | PASS |
| Citation compliance | 0.9333 | 0.9000 | PASS |
| Fallback rate | 0.0000 | ≤ 0.1000 | PASS |

| 项目 | 值 |
| --- | ---: |
| 可回答题总数 | 30 |
| 可评分样本 | 28 |
| 可评分覆盖率 | 93.33% |
| 引用合规 | 28 / 30 |
| 上下文漂移 | 0 |
| Provider 错误 | 0 |
| Fallback 比例 | 0.0000 |
| 引用护栏拒答 | 2（a10、a20 无引用） |
| 不可答拒答 | 3 / 3 |
| ACL 泄漏 | 0 / 3 |
| 硬失败 | 无 |

多跳切片（4 题全部可评分）：Faithfulness 1.0000、Response Relevancy 0.8363、Context Precision
0.7083、Context Recall 1.0000、Answer Correctness 0.7292。

答案延迟（不含裁判）：均值 729.6 ms、中位数 679.4 ms、最大 1157.4 ms。

## 与 Spring 基线的配对比较

### 1. 总体指标

| 指标 | Spring 基线 | Cloud 本轮 | 差值 |
| --- | ---: | ---: | ---: |
| Faithfulness | 0.9907 | 0.9658 | −0.0249 |
| Response Relevancy | 0.8521 | 0.8435 | −0.0086 |
| Context Precision | 0.9949 | 0.9536 | −0.0413 |
| Context Recall | 0.9815 | 0.9821 | +0.0006 |
| Answer Correctness | 0.7713 | 0.7451 | −0.0262 |
| 引用合规 | 0.9000 | 0.9333 | +0.0333 |
| 可评分覆盖 | 27/30 | 28/30 | +1 |
| 不可答拒答 | 3/3 | 3/3 | — |
| ACL 泄漏 / 上下文漂移 / provider 错误 / 硬失败 | 0 / 0 / 0 / 无 | 0 / 0 / 0 / 无 | — |

### 2. 逐题配对（26 道两侧都可评分的题）

| 指标 | 均值差 | 最小 | 最大 |
| --- | ---: | ---: | ---: |
| Faithfulness | −0.0080 | −0.3333 | +0.1250 |
| Response Relevancy | −0.0047 | −0.8563 | +0.9054 |
| Context Precision | −0.0067 | −0.1667 | 0.0000 |
| Context Recall | 0.0000 | 0.0000 | 0.0000 |
| Answer Correctness | −0.0357 | −0.5246 | +0.2583 |

Context Recall 的逐题差恒为 0.0000，Context Precision 的最大差为 0.0000——检索侧等价；
Faithfulness / Relevancy / Answer Correctness 的单题摆动（±0.8～0.9）来自 `llama3.2` 的采样与
`qwen2.5:7b` 的裁判波动，与同一构建两次运行的噪声量级一致，不是链路差异。

### 3. 检索层对比

| 维度 | 结果 |
| --- | --- |
| 集合一致 | 36 / 36 |
| 顺序一致 | 35 / 36 |

唯一差异是 a19：Spring 返回 `c-progress-message, c-vehicle-transfer, c-offense-notice,
c-appeal-process, c-idempotency`，Cloud 返回 `c-progress-message, c-vehicle-transfer,
c-appeal-process, c-offense-notice, c-idempotency`——第 3/4 位互换，两块都在 top-5 内。

## 护栏、拒答与 ACL

### 1. 拒答

| 类型 | 结果 | 细节 |
| --- | --- | --- |
| 不可答题 | 3 / 3 拒答 | u01、u02、u03 均返回 `NO_SOURCE_ANSWER` 拒答文本 |
| 可答题误拒 | 2 / 30 | a10、a20 两轮生成都没有 `[n]` 引用，一次引用修复后仍无引用，被 `UNCITED_ANSWER` 护栏拒答 |
| 引用修复重试 | 3 次 | 1 次补齐引用后正常进入评分，2 次对应 a10、a20 |

上一轮（2026-10-28）不可答题 0/3，是因为当时代码还没有主题校验：模型用「车辆过户」这类
近邻条款作答并带上合规引用，引用格式检查看不出问题。移植主题校验后，三题都由
`TopicGroundingVerifier` 判定「检索资料未覆盖所问主题」并拒答。

### 2. ACL

3 个探针均未返回受限块，ACL 泄漏 0/3：

| 探针 | 禁止返回 | 结果 |
| --- | --- | --- |
| p01 操作日志审查 | `c-admin-audit-log` | PASS |
| p02 我的违法记录 | `c-user-offense-mine` | PASS |
| p03 每日对账怎么做 | `c-dept-finance-sop` | PASS |

### 3. 与上一轮 Cloud 结果的差异

| 指标 | 2026-10-28 | 2026-10-29 |
| --- | ---: | ---: |
| Faithfulness | 0.9569 | 0.9658 |
| Response Relevancy | 0.8574 | 0.8435 |
| Context Precision | 0.9511 | 0.9536 |
| Context Recall | 0.9828 | 0.9821 |
| Answer Correctness | 0.7569 | 0.7451 |
| 引用合规 | 0.9667 | 0.9333 |
| 可评分覆盖 | 29/30 | 28/30 |
| 不可答拒答 | 0/3 | **3/3** |
| ACL 泄漏 | 0 | 0 |

指标层面的 0.01～0.03 变化落在生成侧噪声带内；真正由代码带来的变化只有一项：拒答率从 0/3
变成 3/3，代价是多拒了两道可答题（a10、a20）。

## 复现

```bash
# Cloud 栈（含 AI），纯 RAG 模式 + 引用强制 + 主题校验
export AI_AGENT_ENABLED=false
export AI_RAG_ENABLED=true
export RAG_RETRIEVAL_ENABLED=true
export RAG_INDEX_NAME=rag_chunk_ragas_v1
export RAG_INDEX_ALIAS=rag_chunk_ragas_current
export RAG_EMBEDDING_ENABLED=true
export RAG_EMBEDDING_PROVIDER=ollama
export RAG_EMBEDDING_MODEL=nomic-embed-text
export RAG_EMBEDDING_DIMENSIONS=768
export AI_GUARDRAIL_CITATION_ENFORCEMENT=true
export AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b
bash scripts/start-cloud-backend.sh --include-ai --gateway-port 18090
```

```bash
cd scripts/ragas
RAGAS_BASE_URL=http://127.0.0.1:18090 \
RAGAS_ES_URL=http://127.0.0.1:9200 \
RAGAS_INDEX_ALIAS=rag_chunk_ragas_current \
RAGAS_TARGET_LABEL="Spring Cloud 后端（拒答校验）" \
uv run ragas-eval all --top-k 5 --run-id cloud-ragas-20261029 \
  --max-workers 2 --metric-timeout 420 --max-retries 2
```

本轮运行环境：MySQL 3306（`traffic` 库）、Redis 6379、Elasticsearch 9200、Ollama 11434；
Cloud 栈由 `scripts/start-cloud-backend.sh --include-ai` 构建并启动，原始产物在
`artifacts/ragas/cloud-ragas-20261029/`（gitignored）。

## 局限

- 单轮运行：30 道题的均值仍受 `llama3.2` 采样与 `qwen2.5:7b` 裁判波动影响，0.01～0.03 的差值
  不能解释为链路差异；判定回归要靠检索侧指标或多次运行均值。
- **DEPARTMENT 作用域仍然对任何身份不可见**：Cloud 把部门身份折叠为字面量 `DEPARTMENT`
  （业务角色）或 `ALL`（系统角色），语料里存的是真实部门名（`finance` / `traffic-police`），
  两者永不相等。该行为与 Spring 参考实现一致（fail-closed，不泄漏），代价是 DEPARTMENT 语料
  永远检索不到，ACL 探针实际只覆盖 ROLE / USER。修法需同时改服务端推导与语料。
- 主题校验判断的是「检索资料是否覆盖所问主题」，不是「资料是否蕴含答案中的具体事实」；
  主题正确但细节编造不会被这一层拦住。
- 引用合规只检查格式与编号范围，不验证引用是否真的支持结论。
- 只覆盖纯 RAG 模式（`AI_AGENT_ENABLED=false`），不代表默认 Agent 模式的表现。
- 本轮由 Cloud 重新写入语料；文档与分块主键是内容哈希的确定性结果，写回的是与 Spring 种子
  相同的行，但 MySQL 与 ES 的写入时间戳会更新。
