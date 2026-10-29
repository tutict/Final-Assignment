# Quarkus 后端纯 RAG 与拒答能力（2026-10-29）

本报告记录把 Spring 主后端的纯 RAG 对话链路与答案层拒答能力移植到
`final_assignment_backend_quarkus` 的范围、实现与验证。Spring 的改造与评测结论见
[refusal-2026-10-29.md](refusal-2026-10-29.md)；Cloud 与 Go 的移植分别见
[cloud-parity-2026-10-28.md](cloud-parity-2026-10-28.md) 与
[go-parity-2026-10-29.md](go-parity-2026-10-29.md)。

## 结论摘要

- Quarkus 现在有独立的纯 RAG 回合：**检索 → 编号资料 → 提示词 → 流式生成 → 清洗内部标签 →
  引用护栏（最多一次引用修复）→ 生成后主题校验（fail-open）→ SSE**，两条标准拒答文本与
  Spring / Go 逐字一致。
- 一次 SSE 流只有一个 `messageId`，引用修复沿用首个身份；控制事件与错误帧原样透传。
- 引用强制在 Quarkus **默认关闭**（`AI_GUARDRAIL_CITATION_ENFORCEMENT=false`），开启后
  "检索被请求但结果为空/检索失败"的回合会返回 `NO_SOURCE_ANSWER`。这是与 Spring / Go
  默认值的唯一实质差异，因为 Quarkus 的对话链路尚未用 RAGAS 校准。
- 主题校验默认打开但**必须显式配置裁判模型**才生效；裁判是独立于聊天模型的 Ollama 客户端
  （`temperature=0`、JSON 输出），超时、调用失败或输出无法解析一律放行。
- Quarkus 的知识库检索走 MySQL（关键字 + 中文 bigram 评分），**没有移植 Elasticsearch /
  向量检索与 embedding 队列**。RAGAS 采集依赖 ES alias 可见性检查，因此本轮无法对 Quarkus
  执行 RAGAS，只有单元测试与构建验证。

## 移植范围

| 能力 | Spring | Quarkus |
| --- | --- | --- |
| 纯 RAG 流水线 | `ChatPipeline` | `ai/chat/ChatPipeline` |
| 编号提示词与上下文预算 | `PromptAssembler` | `ai/chat/PromptAssembler` |
| 内部标签清洗 | `AnswerTextSanitizer` | `ai/guardrail/AnswerTextSanitizer` |
| 引用判定与标准拒答文本 | `AnswerGroundingPolicy` | `ai/guardrail/AnswerGroundingPolicy` |
| 一次引用修复 | `ChatPipeline` | `ai/guardrail/GuardrailStage` |
| 生成后主题校验 | `TopicGroundingVerifier` | `ai/guardrail/TopicGroundingVerifier` |
| 按次模型 / JSON 输出 / 独立超时 | `AiGenerationOptions` + provider 隔离调用 | `JudgeModelFactory`（独立 `OllamaChatModel`） |
| 单 `messageId` | `ChatPipeline` | rebind 到首个 token 的身份 |
| 纯 RAG 开关 | `AI_AGENT_ENABLED` | 同名环境变量 |
| SSE 逐条推送 | `Flux<ChatStreamEvent>` | `Multi<String>` + JSON 帧 |

明确未移植：

- Elasticsearch / 向量混合检索、embedding 任务队列与索引别名切换。Quarkus 的
  `RagQueryService` 在 MySQL 文档与 chunk 上做词面检索；`/api/rag/admin/embedding/*` 与
  `index/migrate` 目前是返回零计数的兼容桩。
- Spring 的 keepalive / queue 事件。Quarkus 当前不生成这两类事件；`GuardrailStage` 仍把
  任何非 TOKEN 事件视为"非文本回答"直接透传，便于以后接入。

## 实现

### 1. 纯 RAG 流水线

- `ChatPipeline` 先绑定会话归属，再执行 Agent 路由；Agent 返回 `draft` / `result` /
  `action` 时直接输出控制事件，不调用聊天模型，也不进入文本护栏。
- 纯 RAG 回合按请求元数据决定是否检索（`ragEnabled`，默认 `AI_RAG_ENABLED`），再按
  `ragTopK` / `topK` 取 top-K（1–20，默认 `AI_RAG_TOP_K=5`）。检索异常等同于空结果并记录
  WARN，不会让聊天直接失败。
- `PromptAssembler` 只向模型暴露 `[n]` 与正文，按 `AI_PROMPT_CONTEXT_TOKEN_BUDGET`
  截断资料；被截断的段落不会进入护栏判定。
- 生成走 LangChain4j `StreamingChatModel`，token 通过 Mutiny emitter 汇入；阻塞操作
  （JDBC 检索、GraalPy 网页搜索、护栏判定）都在 worker 线程执行，不占用 Vert.x 事件循环。
- 每条 SSE 帧是 `{"type","sessionKey","messageId","token"|"payload","timestamp"}`，与
  React 前端和 `scripts/ragas/ragas_eval/sse.py` 的解析契约一致；`SseHeadersFilter` 关闭
  反向代理缓冲，`NetWorkHandler` 对 `/api/ai/chat/stream` 使用 180s 空闲超时的独立客户端。

### 2. 清洗与引用护栏

- `AnswerTextSanitizer` 逐条移植 Spring：剥离 `<retrieved_context>`、`retrieved_context`、
  `manual_rag_document[...]`、`rag_chunk[...]` 等内部标签、占位引用 `[n]`、句首连接词，
  并规范空格与标点；用户可见的 `[1]` / `【1】` 保留。
- `AnswerGroundingPolicy` 与 Java 版逐条对应：半角 `[1]`、全角 `【1】`、分组 `[1,2]` /
  `[1，2]`，编号必须落在实际进入提示词的资料范围内；也接受答案中出现显著的来源标识、文档
  ID 或标题（中文 ≥2 字，拉丁字母 ≥4 字符且含字母，避免 `12` 这类裸编号误判）。
- 无引用时 `GuardrailStage` 先用 `PromptAssembler.assembleCitationRepair` 再调用一次模型；
  仍无引用则用 `UNCITED_ANSWER` 拒答，完全没有可用资料时用 `NO_SOURCE_ANSWER` 拒答。
  两条文本与 `AnswerGroundingPolicy.java` 逐字一致，`sse.py` 按字节比较。
- 判定对象是 `assembled.sources()`——即真正放进提示词的资料子集，而不是检索 top-K 全量。
- 非文本事件（错误帧、`isFallback` 兜底、任何控制事件）不参与判定，原样回放；`DONE` 由
  `ChatPipeline` 统一追加，护栏不重复生成。

### 3. 主题校验

`TopicGroundingVerifier` 的提示词、跳过条件与幂等语义照搬 Spring：

- 输入：清洗后的用户问题、清洗后的答案、实际进入提示词的资料；资料按 `[n] 正文` 拼接。
- 输出：`{"topic_in_sources": boolean, "reason": string}`；解析支持严格 JSON、首尾花括号
  切片、字符串形式的 `"true"` / `"false"`。
- 判定 false 时用 `NO_SOURCE_ANSWER` 拒答；判定 true、超时、请求失败或解析失败一律放行。
- 跳过：校验关闭、问题或答案为空、资料为空、答案已是标准拒答文本、资料中含 `WEB_SEARCH`
  来源、所有资料正文为空。Quarkus 的网页搜索会把结果作为 `WEB_SEARCH` 资料并入本轮上下文，
  因此这条跳过条件会实际生效。
- 裁判由 `JudgeModelFactory` 构建为独立的 `OllamaChatModel`：复用
  `quarkus.langchain4j.ollama.base-url`（即 `OLLAMA_BASE_URL`），不重试、温度 0、
  `numPredict=96`、`format=json`，超时取 `AI_GUARDRAIL_TOPIC_TIMEOUT`。生成答案的聊天模型
  不会审查自己的输出。
- 与 Spring 的差异：Spring 通过统一 provider registry 可以选任意已配置 provider 做裁判；
  Quarkus 模块目前只接入 Ollama，因此裁判模型也必须是 Ollama 模型。

### 4. 流水线接线

`ChatPipeline.answerEvents` 的顺序：

1. 判断 `ragEngaged` 并检索；提示词组装后得到 `assembled.sources()`。
2. 生成 `messageId`，所有 token、错误帧、`done` 使用同一身份。
3. `ragEngaged || !assembled.sources().isEmpty()` 时进入 `GuardrailStage`；否则直接流式
   返回（`ragEnabled=false` 的请求级关闭完全旁路护栏）。
4. `GuardrailStage` 缓冲 token，结束后在工作线程执行：清洗 → 引用判定 → 一次修复 →
   主题校验。通过时回放原 token（清洗有变化时替换为单个清洗后的 token）；拒答时输出单个
   标准文本 token。两种情况下都由上层追加唯一的 `done`。
5. 修复本身失败（超时 180s 或模型报错）时不再重试，按 `UNCITED_ANSWER` 拒答；修复流内的
   错误帧仍然原样透传，避免把"模型不可用"改写成引用拒答。

上下文预算只决定"模型看到了哪几段"，护栏判断的也是同一子集；被截断掉的资料不能作为回答
依据通过检查。

## 配置

Quarkus 读取与 Spring / Go 同名的环境变量：

| 键 | 默认 | 说明 |
| --- | --- | --- |
| `AI_AGENT_ENABLED` | `true` | `false` = 纯 RAG，不路由工具 |
| `AI_RAG_ENABLED` | `true` | 请求可用 `metadata.ragEnabled=false` 单次关闭 |
| `AI_RAG_TOP_K` | `5` | 请求可用 `metadata.ragTopK` / `topK` 覆盖，上限 20 |
| `AI_PROMPT_CONTEXT_TOKEN_BUDGET` | `1200` | 进入提示词与护栏的资料预算 |
| `AI_GUARDRAIL_CITATION_ENFORCEMENT` | `false` | **Quarkus 默认关闭**；开启后无引用即拒答 |
| `AI_GUARDRAIL_TOPIC_VERIFICATION` | `true` | 需同时配置裁判模型才生效 |
| `AI_GUARDRAIL_TOPIC_MODEL` | 空 | 空 = 校验关闭并打印 WARN |
| `AI_GUARDRAIL_TOPIC_TIMEOUT` | `PT12S` | 裁判调用超时；评测建议 `20s` |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | 聊天与裁判共用 |
| `AI_CHAT_MODEL` | `llama3.2` | Ollama 模型名（扩展的构建期配置） |
| `AI_CHAT_TIMEOUT` | `120s` | 聊天流超时；引用修复的等待上限为 180s |

`AI_CHAT_MODEL` 是 Quarkus LangChain4j 的构建期配置，修改后需要重新构建；其余键均为运行时
配置。

## 验证

```bash
cd final_assignment_backend_quarkus
./gradlew --console=plain test classes
```

全量测试通过（33 个测试类，0 failure / 0 error）。本轮新增 5 个测试类、44 个用例：

- `AnswerTextSanitizerTest`（6）：标签、占位引用、连接词、标点与空格、空值。
- `AnswerGroundingPolicyTest`（8）：关闭开关、空回答、无来源、无引用、半角/全角/分组编号、
  越界编号、标题命中、裸数字不命中。
- `TopicGroundingVerifierTest`（9）：未配置模型保持关闭、false/true 判定、字符串判定、
  JSON 包裹在散文中的切片、无法解析与裁判异常时 fail-open、网页来源与标准拒答跳过、
  提示词包含编号资料与问题。
- `GuardrailStageTest`（9）：清洗、无引用拒答文本、引用回答原样回放、修复只尝试一次并保留
  首个 `messageId`、修复失败兜底、无来源拒答、错误帧透传、主题校验拒答替换、
  `isFallback` 跳过判定。
- `ChatPipelineTest`（12，含新增 5 个）：单 `messageId`、Agent 旁路、空消息、会话归属、
  RAG 关闭、提示词包含资料、历史窗口；新增无引用修复后仍拒答、修复成功、检索为空拒答、
  检索失败拒答、`ragEnabled=false` 旁路护栏。

未做端到端手工验证：本地没有同时启动 Quarkus、MySQL、Redis 与 Ollama 的完整环境。因此本报告
不宣称 Quarkus 的拒答率、误拒率或 RAGAS 指标。

## 未完成：Quarkus RAGAS

> **已于同日补齐。** 本节描述的是本文写作时的状态。ES / embedding 移植与端到端评测随后完成，
> 见 [quarkus-rag-elasticsearch-2026-10-29.md](quarkus-rag-elasticsearch-2026-10-29.md)；下文
> 「Quarkus 没有 ES 索引别名与 embedding 队列」等结论以该文档为准。

RAGAS 本轮没有对 Quarkus 执行，原因是评测前置条件不匹配：

- `scripts/ragas/ragas_eval/seed.py` 与 `client.py` 除了 `POST /api/rag/query` 和
  `POST /api/ai/chat/stream`，还要求 Elasticsearch（默认 9400）中的索引别名可查询，并用
  `es_source_counts` 证明每个 `sourceId` 已完整切片、embedding。Quarkus 的检索完全在 MySQL，
  没有 ES 索引别名与 embedding 队列，`verify_seed` 必然失败。
- Quarkus 的 `/api/rag/admin/embedding/run`、`/backfill`、`/index/migrate` 是兼容桩，
  不会产生可被 ES 统计的 chunk。
- 即便绕过 seed 检查，Quarkus 的检索质量与 Spring 的 BM25+向量混合检索不同，指标不能直接
  与现有基线对比。

复现前需要先补齐 ES/embedding 移植，或在 RAGAS 中增加"MySQL 语料直写"模式。完成前，Quarkus
的拒答效果只有单元测试保障，不宣称 RAGAS 指标。

## 风险与边界

- **默认不拒答**：引用强制默认关闭，检索为空或失败时模型仍可能自由回答。要与 Spring 的
  拒答指标对齐，必须显式设置 `AI_GUARDRAIL_CITATION_ENFORCEMENT=true` 并先完成 RAGAS。
- **首字延迟**：纯 RAG 回合需要先缓冲完整回答（可能再加一次修复与一次裁判调用）才输出，
  流式体验与 Spring 同链路一致，但首 token 延迟明显高于逐 token 直出。
- **主题校验不等于蕴含校验**：资料覆盖主题但缺少具体事实时仍会放行，回答在正确主题下编造
  细节不会被这一层拦住。
- **裁判仅支持 Ollama**：没有 OpenAI-compatible 或云端裁判实现；裁判不可用时按 fail-open
  放行，拒答能力随之退化。
- **Agent 路径不判定**：Agent 的 `draft` / `result` / `action` 事件直接输出，不经过文本
  护栏；只有纯 RAG 回合受引用强制与主题校验约束。
- **检索能力差异**：Quarkus 没有向量检索与 embedding 队列，中文召回依赖词面 + bigram 评分，
  与 Spring/Cloud/Go 的检索结果不会逐题一致。
