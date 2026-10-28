# Cloud 后端 RAG 答案质量对齐报告（2026-10-28）

本报告把主后端第二轮的答案层改进移植到 `finalAssignmentCloud`，并用同一套 RAGAS 数据集复测。
移植范围包括纯 RAG 开关、上下文去元数据、引用提示词、`temperature=0.2`、内部标签清洗与一次性
引用修复重试；同时修正 Cloud 混合检索融合权重与主后端不一致的问题。评测固定数据集、语料、
答案模型、裁判与 topK，原始产物保存在 `artifacts/ragas/`（gitignored）。

## 结论摘要

- 移植在 Cloud 上按预期工作：29/30 可评分，五项 RAGAS 指标全部达标，引用合规 0.9667，
  fallback、上下文漂移、provider 错误与 ACL 泄漏均为 0，无硬失败。
- 与主后端 `improvement4-20261028` 配对（29 道共同题）后，Cloud 各项均值低 0.00–0.03：
  Faithfulness −0.0316、Response Relevancy −0.0331、Context Precision −0.0084、Context Recall
  0.0000、Answer Correctness −0.0189。
- 差距可定位到两个可解释点：a10 在引用修复重试后仍无引用，被护栏拒答（主后端该题通过）；
  a23 的采样把“附带引用来源”写成“并不附带引用来源”，Response Relevancy 记为 0。剔除 a23 后
  RR 差 −0.0006、F 差 −0.0149、AC 差 −0.0151；其余差异与裁判对逐字相同答案的重复打分波动同
  量级（a25 两侧答案完全一致，AC 分别为 0.452 与 0.738）。
- 检索层逐题一致（30/30 命中、`sourceId` 顺序零差异），因此本报告验证的是答案链路“移植后行为
  一致”，不是新的算法增益。
- 不可回答拒答率 0/3 与主后端相同，仍是两套后端共有的主要缺口。

## 范围与方法

- 后端：`finalAssignmentCloud`，网关 `18080`（8080 被主后端占用）、AI `18086`、RAG `18088`；
  `dev` profile，`AI_AGENT_ENABLED=false`、`AI_RAG_ENABLED=true`、`RAG_RETRIEVAL_ENABLED=true`。
- 检索：网关转发到 Cloud RAG 的 `POST /api/rag/query`，Elasticsearch BM25 + kNN，加权 RRF
  （BM25 0.8 / 向量 0.2，候选深度倍率 3），topK=5；索引 `rag_chunk_ragas_v1` / alias
  `rag_chunk_ragas_current` 与主后端评测共用。
- 答案：网关转发到 Cloud AI 的 `POST /api/ai/chat/stream`，`llama3.2`，产品嵌入
  `nomic-embed-text`（768 维）；纯 RAG 模式不经过 Agent 工具路由。
- 裁判：`qwen2.5:7b`，评测嵌入 `bge-m3`，RAGAS 0.4.3；AC 独立以 `num_predict=2048`、单并发执行。
- 数据集：30 道可回答题（22 个 PUBLIC 语料块、4 道多跳）、3 道不可回答题、3 个 ACL 探针；
  `golden-set.json` 未修改，数据集与语料 hash 与主后端基线一致。

对比对象为主后端 `improvement4-20261028`（同数据集、同语料、同模型、同裁判、topK=5）。Cloud 侧
服务由当前工作树构建，提交后代码与评测时的构建内容一致。

## Cloud 改动

### 1. 纯 RAG 开关

`AgentRuntime` 加 `@ConditionalOnProperty(prefix="ai.agent", name="enabled", havingValue="true",
matchIfMissing=true)`：`AI_AGENT_ENABLED=false` 时工具路由 Bean 不创建，聊天直接走 provider +
检索上下文。Agent 约束只在 runtime 存在时注入，避免导航/草稿规则把纯 RAG 回答带离上下文。

### 2. 答案层防护

- `ContextBuilder` 只向模型暴露 `[n]` 与正文，按 1200 token 预算截断，上下文经注入消毒。
- `PromptTemplateService` 在有上下文时追加五条引用规则；引用修复请求额外加入“上一版因无引用被拒绝”
  的指令。
- `ChatPipeline` 对 RAG 回合缓冲 TOKEN/DONE 后再判定引用；无引用时用修复提示词重试一次，仍无引用
  返回拒答文本。重试沿用第一次的 `messageId`。QUEUE/keepalive 即时透传，`TOOL`/`DRAFT`/
  `RESULT`/`ACTION`、ERROR 与 `isFallback` 事件不参与引用改写。
- `AnswerTextSanitizer` 移除模型复述的 `retrieved_context`、`rag_chunk` 等内部标签与占位引用。
- `OllamaAiProvider` 发送 `options.temperature`（默认 0.2）与可选 `num_predict`。

### 3. 检索权重对齐

Cloud 检索配置原为 BM25 0.6 / 向量 0.4，与主后端第二轮验证过的 0.8 / 0.2 不一致。权重不一致时
冒烟查询命中错误块，Faithfulness 与 Context Precision 均为 0；对齐后同一题恢复为 1.0。该修复是
本次 Cloud 与主后端可比的前提。

### 4. 评测工具链

`RAGAS_TARGET_LABEL` 写入 manifest 与报告环境表，用于区分同一数据集在不同后端的运行；没有该字段
的旧 manifest 不渲染该行。

## 证据

### 1. 指标总表

| 指标 | 均值 | 目标 | 结果 |
| --- | ---: | ---: | --- |
| Faithfulness | 0.9569 | 0.7500 | PASS |
| Response Relevancy | 0.8574 | 0.7500 | PASS |
| Context Precision (with reference) | 0.9511 | 0.6000 | PASS |
| Context Recall | 0.9828 | 0.8500 | PASS |
| Answer Correctness | 0.7569 | 0.5500 | PASS |
| Citation compliance | 0.9667 | 0.9000 | PASS |
| Fallback rate | 0.0000 | ≤ 0.1000 | PASS |

| 项目 | 值 |
| --- | ---: |
| 可回答题总数 | 30 |
| 可评分样本 | 29 |
| 可评分覆盖率 | 96.67% |
| 引用合规 | 29 / 30 |
| 上下文漂移 | 0 |
| Provider 错误 | 0 |
| Fallback 比例 | 0.0000 |
| 排除原因 | guardrail_uncited=1（a10） |

多跳切片（4 题全部可评分）：Faithfulness 1.0000、Response Relevancy 0.8994、Context Precision
0.7500、Context Recall 1.0000、Answer Correctness 0.7941。

### 2. 配对比较

只保留两套后端都能评分的题目（29 道；a10 在 Cloud 被排除），逐指标配对：

| 指标 | 主后端 (n) | Cloud (n) | 差值 |
| --- | ---: | ---: | ---: |
| Faithfulness | 0.9885 (29) | 0.9569 (29) | −0.0316 |
| Response Relevancy | 0.8905 (29) | 0.8574 (29) | −0.0331 |
| Context Precision | 0.9595 (28) | 0.9511 (29) | −0.0084 |
| Context Recall | 0.9828 (29) | 0.9828 (29) | 0.0000 |
| Answer Correctness | 0.7759 (29) | 0.7569 (29) | −0.0189 |

CP 的 n 不同是因为主后端 a30 的 CP 裁判结果解析失败，Cloud 无缺失。差值集中在两题：

- a23 的 RR 从 0.942 变为 0.000，单题即拉低 RR 均值 0.0325。剔除 a23 后，RR 为 0.8880 对
  0.8886（差 −0.0006），F 为 0.9732 对 0.9881（差 −0.0149），AC 为 0.7619 对 0.7770
  （差 −0.0151）。
- a10 被护栏拒答后不进入均值；若把它按主后端的 0.8418 计回，Cloud AC 均值升至约 0.7598，
  其余指标同步小幅回升。

F 与 AC 的剩余差距（约 0.01–0.02）与裁判波动同量级：a25 两侧答案逐字相同，Answer Correctness
仍分别为 0.452 与 0.738；a09 的答案与检索上下文也逐字相同，CP 却为 1.000 与 0.583。在
`llama3.2` 采样与 `qwen2.5:7b` 裁判下，这个量级的差异不能归因于后端实现。

### 3. 引用、覆盖率与运行卫生

- 引用合规 29/30（0.9667）：唯一失败的是 a10，两轮生成均无 `[n]` 引用，护栏返回拒答文本并标记
  `guardrail_uncited`，该题不参与指标均值。
- 整轮评估只触发 2 次引用修复重试（AI 服务日志 `Retrying uncited answer with citation repair`）：
  1 次补齐引用后正常进入评分，1 次为 a10 且重试后仍无引用。
- fallback 比例 0.0000，上下文漂移 0，provider 错误 0；30 道可回答题的检索上下文为 340–379
  token（均值 365.3），全部在 1200 token 预算内。
- 答案延迟（不含裁判）：均值 429.9 ms、中位数 397.4 ms。
- 多跳 4/4 可评分：F 1.0000、RR 0.8994、CP 0.7500、CR 1.0000、AC 0.7941；主后端对应为
  1.0000 / 0.8674 / 0.6667 / 1.0000 / 0.8196，Cloud 的 RR 与 CP 更高、AC 低 0.0255，仍属单轮
  采样范围。
- 覆盖率 96.67% 高于 90% 的评估目标，没有因排除样本触发硬失败。

### 4. 检索回归

权重对齐后，用 Cloud 网关对 30 道题做一次 top5 检索：hit@5 30/30、相关块召回 0.9833、MRR 0.9833、
nDCG@5 0.9769，与主后端 `improvement4` 的检索结果逐题一致（返回的 `sourceId` 顺序零差异）。
两套后端在相同索引与权重下检索层等价，后续答案指标差异只能来自生成采样。

### 5. ACL 与不可回答

| 探针 | 禁止返回 | 实际返回 | 结果 |
| --- | --- | --- | --- |
| p01 操作日志审查 | c-admin-audit-log | c-fine-refund、c-vehicle-inspection、c-appeal-process、c-appeal-deadline、c-fine-late-fee | PASS |
| p02 我的违法记录 | c-user-offense-mine | c-fine-refund、c-offense-notice、c-fine-receipt、c-appeal-process、c-license-points | PASS |
| p03 每日对账怎么做 | c-dept-finance-sop | c-appeal-process、c-fine-late-fee、c-fine-refund、c-account-security、c-vehicle-inspection | PASS |

3 个探针均未返回禁止块，ACL 泄漏 0/3；与主后端一致。

不可回答题 0/3 拒答，与主后端相同：

| ID | 问题 | Cloud 行为 |
| --- | --- | --- |
| u01 | 车辆达到报废标准后应如何办理报废？ | 用车辆过户步骤作答并引用 [1]，末尾才补充“问题中没有提及报废标准”，属于部分幻觉 |
| u02 | 外地驾驶证转入本地需要哪些手续？ | 用车辆过户步骤作答并引用 [3]，属于跨域误答 |
| u03 | 在高速公路上占用应急车道会怎么处罚？ | 用违章停车罚款条款作答并引用 [3]，属于近邻条款误用 |

三题都能检索到“相关但不回答问题”的块，引用格式也合规，说明当前护栏只约束引用格式，不判断证据
是否足以支撑答案；这是两套后端共有的缺口。

### 6. 逐题定位

| 题目 | Cloud 相对主后端的变化 | 定位 |
| --- | --- | --- |
| a10 | 被护栏拒答，不参与评分 | 两轮生成均无引用，修复重试未成功 |
| a23 | F 1.000→0.500，RR 0.942→0.000 | 采样把“附带引用来源”写成“并不附带引用来源”，引用仍在但结论反转 |
| a09 | CP 1.000→0.583 | 答案与检索上下文逐字相同，仅裁判打分不同 |
| a25 | AC 0.452→0.738 | 两侧答案逐字相同，仅裁判打分不同 |
| a07 | AC 0.993→0.731 | Cloud 额外写入证据要求（忠于 [4]），与参考答案的重合度下降 |
| a11 | F 1.000→0.750，AC 0.982→0.732 | Cloud 追加“考试内容没有明确说明”的推断 |
| a13 | AC 0.819→0.569 | Cloud 省略“超过六年需每年上线检验” |
| a18 | AC 0.705→0.962 | Cloud 补充拖移条款，更接近参考答案 |
| a28 | RR 0.782→0.990，AC 0.744→0.562 | Cloud 答案更简短；两后端 CP 均为 0，非本次引入 |
| a03 | F 0.667→0.500，AC 0.730→0.602 | 答案尾部多一句推论，裁判判定更严格 |

除 a10、a23 外，其余逐题差异都能在“同一问题两次采样”的正常波动范围内找到对照（a25、a09 的
输入或输出完全相同而分数不同）。

## 结论与后续

Cloud 的移植达到目的：纯 RAG 开关、上下文去元数据、引用提示词、一次性引用修复、内部标签清洗、
`temperature=0.2` 与检索权重对齐在“网关 → AI → RAG”的微服务链路上与主后端行为一致；同一数据集下
所有配对指标差为 0.0000–0.0331，最大差值来自单题采样翻转与一次护栏拒答，而不是链路差异。

后续按优先级：

1. **拒答能力**：不可回答题 0/3 仍是主要缺口。需要在上游加入检索相关度阈值或答案级“证据不足”
   判定，否则引用格式合规无法阻止跨域误答。
2. **护栏漏网**：a10 证明一次性修复重试仍可能失败。可以评估第二次重试，或在“检索命中充分但生成
   持续无引用”时直接拒答；两种策略都应在下一轮 RAGAS 中验证对覆盖率的影响。
3. **评估稳定性**：单轮 0.01–0.03 的差值不足以区分实现。后续对比应固定数据集与裁判，并对关键
   指标跑多轮取均值或报告置信区间。
4. **Cloud ACL 已知缺陷**：`RagQueryController`/`AiCallerIdentity` 把部门身份折叠为字符串
   `"DEPARTMENT"`，而 `AclFilterService` 按真实部门名匹配，导致 DEPARTMENT 语料在真实接口下对
   任何人不可见。本次 ACL 探针因此只覆盖 ROLE/USER，修复后需要补 DEPARTMENT 探针。
5. Go 与 Quarkus 后端尚未移植；可按本次 Cloud 的改动清单复用同一套答案层实现。

## 复现

```powershell
# Cloud 栈（含 AI），纯 RAG 模式
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
uv run ragas-eval all --top-k 5 --run-id cloud-parity-20261028 \
  --max-workers 2 --metric-timeout 420 --max-retries 2
```

Cloud 服务端需要 `ELASTICSEARCH_URIS`（本机 9400）、`SPRING_DATA_REDIS_PORT`（本机 6700）、
`SPRING_DATASOURCE_*` 与 Ollama 地址；评测端 `RAGAS_ES_URL` 指向同一 ES。

## 局限

- 每个配置只跑一轮，30 道题的均值仍受 `llama3.2` 采样与 `qwen2.5` 裁判波动影响；不能把 0.01
  级别的差异解释为后端实现差异，a25 与 a09 的对照说明了这一点。
- 引用合规只检查格式与编号范围，不验证引用是否真的支持结论。
- Cloud 与主后端的差异主要在服务拆分、网关转发与 Feign 鉴权；答案链路的提示词、清洗与护栏是同一
  套移植实现，因此本报告验证的是“移植后行为一致”，不是独立的算法改进。
- 只覆盖纯 RAG 模式；Cloud 默认 Agent 模式不适用本报告结论。
- 数据集只有 30 道可回答题、4 道多跳；CP 的单题解析失败会被单条样本放大。
- ACL 探针只覆盖 ROLE/USER，DEPARTMENT 语料因上述身份折叠缺陷无法通过真实接口验证。
- 本次运行在 `RAGAS_TARGET_LABEL` 生效之前启动，原始 `manifest.json` / `report.md` 没有“评估目标”
  字段；本报告按启动环境将其记为“Spring Cloud 后端”。
