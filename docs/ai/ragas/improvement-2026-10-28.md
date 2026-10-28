# RAG 效果提升报告（2026-10-28，第二轮）

本报告记录 Spring 主后端纯 RAG 模式的第二轮效果优化。第一轮（2026-10-23）解决了检索召回
与答案内部标签泄漏；本轮聚焦答案层的引用合规、上下文噪声与生成稳定性。所有对比固定数据集
（hash `292298fd0e39`）、语料（`42a579afea01`）、答案模型 `llama3.2`、裁判 `qwen2.5:7b`、
评测嵌入 `bge-m3` 与 topK=5，原始产物保存在 `artifacts/ragas/`（gitignored）。

## 结论摘要

- 最终一轮 `improvement4-20261028` 完成 30/30 可回答样本评分，引用合规 30/30，ACL 泄漏 0，
  上下文漂移 0，provider 错误 0：Faithfulness 0.9889、Response Relevancy 0.8889、
  Context Precision 0.9609（29/30 有分）、Context Recall 0.9833、Answer Correctness 0.7781。
- 引用合规从 `improvement2` 的 0.8333（25/30 可评分）→ `improvement3` 的 0.9000（27/30）
  → `improvement4` 的 1.0000（30/30）。最后一次提升来自生成稳定性与一次性引用修复重试，
  不是放宽护栏：重写后仍无引用依旧拒答。
- 与第一轮按 23 道共有样本配对比较，Faithfulness 0.8087 → 0.9855、Context Precision
  0.8551 → 0.9485、Context Recall 0.9783 → 1.0000；Answer Correctness 0.7313 → 0.7568
  （第一轮 AC 用 2048-token 离线重评，见 4.6）。
- 两个确定性改动构成主要收益：上下文只向模型暴露 `[n]` 与正文，消除了复述标题/来源/分数的通道；
  引用缺失时先做一次针对性重写再判定，把“检索正确但忘写引用”的样本从拒答中救回。
- 仍存在的边界：不可回答题真实拒答 0/3（此前记录的 1/3 是引用护栏拒答，不是模型主动弃答）；
  多跳题 Context Precision 0.6667；a30 的 CP 因裁判输出解析失败缺分；llama3.2 的答案完整性
  波动使 AC 在 0.75–0.80 间摆动，不能宣称稳定提升。

## 范围与方法

- 后端：`finalAssignmentBackend`，`dev` profile，`AI_AGENT_ENABLED=false`、
  `RAG_RETRIEVAL_ENABLED=true`，纯 RAG 模式。
- 检索：真实 `POST /api/rag/query`，Elasticsearch BM25 + kNN，加权 RRF（BM25 0.8 / 向量 0.2，
  候选深度倍率 3），topK=5；查询做 NFKC 归一化。
- 答案：真实 `POST /api/ai/chat/stream`，`llama3.2`，产品嵌入 `nomic-embed-text`（768 维），
  引用护栏、提示词、输出清洗均为产品链路；本轮起 Ollama `temperature=0.2`。
- 裁判：`qwen2.5:7b`，评测嵌入 `bge-m3`，RAGAS 0.4.3；AC 独立以 `num_predict=2048`、单并发执行。
- 数据集：30 道可回答题（22 个 PUBLIC 语料块、4 道多跳）、3 道不可回答题、3 个 ACL 探针；
  `golden-set.json` 未修改，数据集与语料 hash 与基线一致。

本轮共四组对比运行：

| 运行 | 代码状态 | 主要变更 | 可评分 |
| --- | --- | --- | ---: |
| `baseline-20261023` | 第一轮前 | 基线 | 30/30 |
| `improvement-20261023` | 第一轮 | 检索权重/深度、标签清洗、4 条提示词 | 30/30 |
| `improvement2-20261028` | 第一轮 | 同代码，用修复后的 AC 评测配置复跑 | 25/30 |
| `improvement3-20261028` | 本轮 | 去元数据上下文、5 条引用提示词、temperature 0.2 | 27/30 |
| `improvement4-20261028` | 本轮 | 在 improvement3 上加入一次性引用修复重试 | 30/30 |

## 改动

### 1. 上下文只暴露编号与正文

`ContextBuilder` 的每个条目从 `title + source + score + content` 收缩为 `[n] + content`，
同时删除来源拼接与分数格式化逻辑；内容仍经过提示词注入清洗。这样模型没有可复述的标题、
来源标识和检索分数，引用编号与正文一一对应，也缩短了上下文。

### 2. 引用提示词升级

有检索上下文时，系统提示词固定为五条约束：仅依据上下文与会话窗口作答；每个事实句用
`[n]` 标注来源（并给出中文示例）；不得提文档标题、来源标识、检索分数或内部标签；
上下文只覆盖相近但不同主题时明确说明未覆盖，多部分问题逐部分回答并点名未覆盖部分；
使用与用户相同的语言。上下文不可信的警告保持不变。无上下文回合不追加引用规则。

引用修复提示词在上述规则前额外加入一条：“上一版因完全没有引用被拒绝，请重写并为每个
事实句补上来源编号”。该指令只出现在重试请求中，正常请求不包含。

### 3. 生成温度与 Ollama options

新增 `ai.ollama.temperature`（`OLLAMA_TEMPERATURE`），默认 `0.2`。`OllamaAiProvider` 在
`/api/chat` 请求体中发送 `options.temperature`，并在设置 `maxTokens` 时发送
`options.num_predict`。低温减少引用标记遗漏与语言漂移；重试时同样生效。

### 4. 一次性引用修复重试

`ChatPipeline` 在纯 RAG 回合（无 agent runtime、检索结果非空）遇到无引用答案时，用修复
提示词重新请求一次；重试沿用第一次的 `messageId`，避免同一个 SSE 流出现两个消息身份。
重试仍无引用则按原逻辑拒答。Agent 路径不重试，因为重放会再次执行工具与副作用。

同时收紧事件边界：`QUEUE` 与 keep-alive 立即透传且不进入引用判定，队列通知不能成为
“非文本事件”从而豁免引用检查；`TOOL`/`DRAFT`/`RESULT`/`ACTION`、ERROR 与 `isFallback`
事件仍原样透传。新增 4 个测试覆盖重试成功、二次失败拒答、关闭强制不重试、QUEUE 透传。

### 5. 清洗器与评测工具链

- `AnswerTextSanitizer` 删除占位引用 `[n]` / `[N]`，保留数字引用 `[2]`；防止提示词示例被
  模型原样抄进答案。
- RAGAS `AnswerCorrectness` 独立评测：`num_predict=2048`、`max_workers=1`，缺失行串行重试；
  其余四项指标仍并行。新增 `tests/test_metrics.py` 覆盖列名映射、非有限分数与均值计算。

## 证据

### 1. 检索回归

本轮未改检索代码。用 `improvement4` 的 30 条真实检索结果计算：hit@5 30/30、相关块召回
0.9833、MRR 0.9833、nDCG@5 0.9769，与第一轮逐项一致。生产默认 `topK=10` 的端到端复跑为
hit 30/30、召回 1.0000、MRR 0.9833、nDCG 0.9898（`artifacts/ragas/retrieval-production-top10.json`）。

### 2. 引用合规与覆盖率

| 运行 | 可评分 | 覆盖率 | 引用合规 | 护栏拒答 | 排除原因 |
| --- | ---: | ---: | ---: | ---: | --- |
| `baseline-20261023` | 30/30 | 1.0000 | 0.9667 | 0 | — |
| `improvement-20261023` | 30/30 | 1.0000 | 1.0000 | 0 | — |
| `improvement2-20261028` | 25/30 | 0.8333 | 0.8333 | 5 | `guardrail_uncited=5` |
| `improvement3-20261028` | 27/30 | 0.9000 | 0.9000 | 3 | `guardrail_uncited=3` |
| `improvement4-20261028` | 30/30 | 1.0000 | 1.0000 | 0 | — |

基线工具链未统计护栏拒答（`guardrail_refusal_count=0`），但其 u01 答案就是
`UNCITED_ANSWER` 文本，引用合规 0.9667 正对应这条样本。

### 3. 指标总表

各轮可评分集合不同，均值不能直接横比；配对比较见下一节。括号内为该指标的评分数。

| 指标 | 基线 10-23 | 第一轮 10-23 | improvement2 10-28 | improvement3 10-28 | improvement4 10-28 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Faithfulness | 0.8017 (30) | 0.8256 (30) | 0.8933 (25) | 0.9926 (27) | 0.9889 (30) |
| Response Relevancy | 0.7918 (30) | 0.8418 (30) | 0.8422 (25) | 0.8788 (27) | 0.8889 (30) |
| Context Precision | 0.8511 (30) | 0.8556 (30) | 0.9528 (24) | 0.9615 (26) | 0.9609 (29) |
| Context Recall | 0.9667 (30) | 0.9667 (30) | 1.0000 (25) | 0.9815 (27) | 0.9833 (30) |
| Answer Correctness | 0.7601 (30)\* | 0.6479 (25)\* | 0.7657 (25) | 0.8023 (27) | 0.7781 (30) |

\* 第一轮 AC 的 0.6479 是裁判输出被 512-token 上限截断的伪影；同一批答案用 2048-token
离线重评为 0.7710，基线为 0.7579，见 4.6。

`improvement4` 的 Context Precision 少 1 条：a30 的裁判输出解析失败（与 improvement3 相同），
该指标按其余 29 条取均值；其余指标均为 30/30。

### 4. 配对比较

只保留在四组运行中都存在且有分的样本：23 道题；CP 22 道、AC 23 道（第一轮 AC 缺失的 4 道
用离线重评分补齐）。第一轮的 AC 数值来自 2048-token 重评，其余指标来自当轮评分。

| 指标 | 第一轮 | improvement2 | improvement3 | improvement4 |
| --- | ---: | ---: | ---: | ---: |
| Faithfulness | 0.8087 | 0.8841 | 0.9913 | 0.9855 |
| Response Relevancy | 0.8659 | 0.8365 | 0.8717 | 0.8752 |
| Context Precision | 0.8551 | 0.9485 | 0.9545 | 0.9485 |
| Context Recall | 0.9783 | 1.0000 | 1.0000 | 1.0000 |
| Answer Correctness | 0.7313 | 0.7597 | 0.7890 | 0.7568 |

读法：

- 相对第一轮，Faithfulness 与 Context Precision 的配对提升最明显，且 improvement3/4 之间
  几乎相同（−0.006 / −0.006），说明收益来自上下文去元数据与提示词，而不是重试。
- improvement4 相对 improvement3 的差异（F −0.006、RR +0.004、CP −0.006、AC −0.032）在
  llama3.2 的答案波动范围内，不能声称答案质量进一步提升；本轮的确定性收益是覆盖率与引用合规。
- improvement2 的配对样本排除了它自己被护栏拒答的 5 条答案，均值对其偏有利；即便这样，
  improvement3 仍更高。

### 5. 逐题定位

- improvement3 的三条未引用样本 a10、a19、a20，其检索首条分别是 `c-license-cycle`、
  `c-progress-message`、`c-idempotency`，正是各自的相关块；失败是引用遗漏，不是检索失败。
- improvement4 采集窗口（21:15:09–21:15:24）内后端记录 3 次引用修复重试；最终 30/30 可评分、
  全部引用合规，a10/a19/a20 均有 `[n]`，AC 分别为 0.8418、0.7397、0.8387。
- 多跳切片 4/4 有分：F 1.0000、RR 0.8674、CP 0.6667、CR 1.0000、AC 0.8196。CP 低主要来自
  a28：上下文混合了年检与过户两个主题，CP 为 0；该题此前的来源标识泄漏已消失。
- 最低 AC 样本：a25 0.4524、a14 0.4874、a16 0.5722、a26 0.5798、a09 0.5865。它们的
  Faithfulness 均为 1.0，问题是答案只覆盖了参考答案的一部分（例如 a25 只列出缴费渠道，
  未提电子票据），属于完整性不足而非编造。
- 运行规模：30 条答案平均延迟 462 ms（中位数 438.5 ms），平均上下文 365 token、
  最大 379，全部在 1200 token 预算内。

### 6. Answer Correctness 伪影与拒答口径

第一轮 AC 从 baseline 的 0.7601 降到 0.6479，曾被当作答案质量回退。复核发现两处评测问题：

1. 第一轮 AC 实际只有 25/30 有分，且裁判 `num_predict=512` 对长中文答案的“陈述拆分”
   会截断，导致 factual score 塌到 0。用同一裁判、`num_predict=2048` 离线重评原始答案：
   基线 0.7579（30 条）、第一轮 0.7710（30 条）——第一轮并未回退。
2. 工具链现已把 AC 独立评测（2048 token、单并发、缺失重试），本轮四次运行不再出现
   整题 AC 缺失。

不可回答题的“历史 1/3 拒答”同样是口径问题：基线 u01 的答案文本等于
`UNCITED_ANSWER`，improvement2 的 u01 也是引用护栏拒答；两者都不是模型主动弃答。
四组运行的真实拒答率均为 0/3。improvement4 的 u01 复用“车辆过户”上下文并补出未受支持的
办理步骤，是本轮最明确的拒答缺口。

### 7. ACL 与运行卫生

ACL 探针 3/3 通过、0 泄漏；上下文漂移 0；provider 错误 0；fallback 0；答案内部标签泄漏 0；
事件类型只有 `token`/`done`。探针仍只覆盖 ROLE/USER：`RagQueryController`/`AiCallerIdentity`
把部门身份折叠为 `"DEPARTMENT"`，DEPARTMENT 语料在真实接口下对任何人不可见，本轮未修复。

## 结论与后续

- 采纳：去元数据上下文、五条引用提示词、temperature 0.2、一次性引用修复重试。护栏语义不变：
  没有引用就不回答。
- 需要单独设计的能力：不可回答题的拒答与“引用是否真的支持结论”的蕴含校验；当前引用检查
  只能确认存在合法编号，不能确认证据支持结论。
- 答案完整性是 AC 波动的主因；更强答案模型、参考要点覆盖检查或结构化回答模板比继续调
  提示词更可能有稳定收益。
- 已知工程边界不变：DEPARTMENT ACL 身份折叠、ES alias 自动创建、扫描版 PDF/OCR。
- 评测工具可在后续加入主指标缺分重试（例如 a30 的 CP），避免单题解析失败降低样本数。

## 复现

```bash
cd finalAssignmentBackend
AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true \
RAG_INDEX_NAME=rag_chunk_ragas_v1 RAG_INDEX_ALIAS=rag_chunk_ragas_current \
OLLAMA_TEMPERATURE=0.2 \
mvn spring-boot:run

cd scripts/ragas
uv sync --frozen
uv run ragas-eval validate
uv run ragas-eval preflight
uv run ragas-eval seed
uv run ragas-eval run --top-k 5 --run-id improvement4-20261028 \
  --max-workers 2 --metric-timeout 420 --max-retries 2
```

配对统计脚本为本轮一次性工具，位于 `artifacts/ragas/paired_compare.py`（gitignored）。

## 局限

- 每个配置只跑一轮，30 道题上的均值仍受 llama3.2 采样与 qwen2.5 裁判波动影响；不能把
  0.01 级别的差异解释为确定收益。
- 上下文去元数据、提示词与 temperature 是同一次提交引入的捆绑变更，本报告只能评估组合效果，
  不能拆分单个杠杆的贡献。
- 引用合规只检查格式与编号范围；improvement4 的 u01 表明“有引用”不等于“引用支持结论”。
- 只覆盖纯 RAG 模式；默认 Agent 模式仍走工具路由，不适用本报告结论。
- 数据集只有 30 道可回答题，多跳 4 道；CP 的 0.6667 与单题 0 分都可能被单条样本放大。
