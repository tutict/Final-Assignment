# RAG 效果提升报告（2026-10-23）

本报告记录 Spring 主后端在纯 RAG 模式下的第一轮效果优化：先用真实 HTTP 链路证明
检索层的主要瓶颈，再分别验证融合权重、候选深度与答案输出卫生的收益，最后用同一套
RAGAS 数据集复跑答案质量。所有对比固定数据集、裁判模型、topK 与 ACL 身份，原始产物
保存在 `artifacts/ragas/`（gitignored）。

## 结论摘要

- 检索 top-5 命中从 29/30 提升到 30/30，相关块召回 93.33% → 98.33%，MRR
  0.9111 → 0.9833，nDCG@5 0.8928 → 0.9769。
- 收益来自两个必须同时存在的杠杆：BM25 权重从 0.4 提高到 0.8，候选深度从
  `topK×2` 提高到 `topK×3`。只改权重或只加深度都不足以稳定召回 a01。
- 答案中的内部上下文标签从 6/30 降到 0/30；a01 由“申诉六十日”误答改为正确引用
  缴款指南，a15 的“过失通知”纠正为“违法通知”。
- RAGAS 30/30 样本完成评分：Faithfulness 0.8256、Response Relevancy 0.8418、
  Context Precision 0.8556、Context Recall 0.9667、Answer Correctness 0.6479，引用合规率 100%。
- 生产默认 `topK=10` 时候选深度为 30；深度 30 的受控排名诊断中，基线漏召回的
  `c-fine-payment-guide` 在 a01 排第 1、a02 排第 2，`c-vehicle-transfer` 在 a28 排第 2。
  RAGAS 答案评测仍使用 `topK=5`，该口径下 a02 的第二个相关块未进入 top-5。
- 不可回答题本轮拒答率为 0/3（基线为 1/3），仍需单独改进；其他已知边界包括
  llama3.2 的语言稳定性、DEPARTMENT ACL 身份折叠和
  ES alias 自动创建；本轮不改变这些既有边界。

## 范围与方法

- 后端：`finalAssignmentBackend`，`dev` profile，`AI_AGENT_ENABLED=false`、
  `RAG_RETRIEVAL_ENABLED=true`，纯 RAG 模式。
- 检索：真实 `POST /api/rag/query`，Elasticsearch BM25 + kNN，加权 RRF，
  `candidateLimit = max(topK, topK × candidateMultiplier)`。
- 答案：真实 `POST /api/ai/chat/stream`，`llama3.2`，产品嵌入
  `nomic-embed-text`（768 维），引用护栏与提示词均为产品链路。
- 裁判：`qwen2.5:7b`，评测嵌入 `bge-m3`，RAGAS 0.4.3，topK=5。
- 数据集：30 道可回答题（22 个 PUBLIC 语料块、4 道多跳）、3 道不可回答题、
  3 个 ACL 探针；`golden-set.json` 未修改，数据集与语料 hash 与基线一致。
- 检索 A/B 使用同一驱动账号 `ce@ce.com`（PUBLIC + USER 角色 + 用户 ID），并对查询
  施加与产品一致的 NFKC 归一化；每次 A/B 只改变目标配置。
- RAGAS 复跑在最终代码上执行；裁判输出上限设为 512 token，避免个别不收敛的判定
  拖垮整轮评分（该上限只影响异常长输出，正常判定远低于上限）。

## 改动

### 1. 融合权重与候选深度

- `rag.retrieval.bm25-weight` 默认值 0.4 → 0.8，
  `rag.retrieval.vector-weight` 默认值 0.6 → 0.2，支持
  `RAG_RETRIEVAL_BM25_WEIGHT` / `RAG_RETRIEVAL_VECTOR_WEIGHT` 覆盖。
- dev 的 `candidate-multiplier` 从硬编码 2 改为与生产一致的 3，可用
  `RAG_RETRIEVAL_CANDIDATE_MULTIPLIER` 覆盖，避免开发环境与生产使用不同的候选池。
- 变更只作用于 Spring 主后端；Cloud RAG 模块仍是 0.6/0.4，未做无证据的同步。

### 2. 答案内部标签清洗

- 新增 `AnswerTextSanitizer`：删除 `retrieved_context`、`manual_rag_document[...]`、
  `rag_chunk...` 及 XML 风格上下文标签，保留 `[n]` 引用标记与中文连接词。
- `ChatPipeline` 在引用判定前清洗缓冲答案，并用清洗后的文本回放；这样用户看到的
  就是被护栏判定的文本，标签也不会再进入答案。
- 新增 6 个清洗单元测试，并补充答案回放测试，覆盖标签、下划线/连字符/空格变体与
  普通英文句子不误伤。

### 3. 提示词加固

- 明确禁止复述内部标签与资源标识，只允许 `[n]` 引用。
- 明确“上下文中没有答案时，说明知识库未覆盖，不得使用通用知识或引用无关上下文”。
- 该约束补充而非替换原有引用要求；无上下文时不追加引用规则，保持原行为。

### 4. 评测工具链

- RAGAS 裁判 `ChatOllama` 增加 `num_predict=512`。本轮复跑前观测到个别判定会一直
  生成到上下文上限，导致单 job 超过 5 分钟并触发 `TimeoutError`；限制输出后整轮
  评分稳定完成，未再出现超时。

## 检索 A/B 证据

### 端到端 API 结果（topK=5）

| 配置 | 候选深度 | hit@5 | 相关块召回 | MRR | nDCG@5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 基线：BM25 0.4 / 向量 0.6 | 10 | 29/30 | 0.9333 | 0.9111 | 0.8928 |
| BM25 0.6 / 向量 0.4 | 15 | 30/30 | 0.9833 | 0.9333 | 0.9400 |
| **BM25 0.8 / 向量 0.2** | 15 | **30/30** | **0.9833** | **0.9833** | **0.9769** |
| BM25 0.8 / 向量 0.2（复跑） | 15 | 30/30 | 0.9833 | 0.9833 | 0.9769 |

最后一行是发布前的完整复跑，与上一行逐题一致，说明结果可复现。基线数据来自
`docs/ai/ragas/baseline-2026-10-23.json`；复跑原始结果在
`artifacts/ragas/retrieval-improved-top5.json`。

### 为什么只调权重不够

RRF 分数为 `100 × weight / (60 + rank)`。旧配置下，一个只在 BM25 列表出现的
正确块（a01 的 `c-fine-payment-guide`）得分是 `100×0.4/61 = 0.6557`，而同时进入
两个列表的文档在第 1 名可得 `100×(0.4+0.6)/61 = 1.6393`，差距过大。

把 BM25 权重提高到 0.8 后，单列表正确块得分变为 `100×0.8/61 = 1.3115`，但仍低于
任何在第 5 名同时出现的文档（`100×1.0/65 = 1.5385`）。因此在候选深度 10 时，
即使权重提到 0.8，a01 仍然进不了 top-5。

候选深度提高到 15 后，该块以向量第 11 名进入候选池，得分变为
`100×(0.8/61 + 0.2/71) = 1.5932`，跃居第 1。两个杠杆必须同时存在，这也解释了
基线中 a01/a02/a28 三个漏召回为何共享同一根因。

### 候选深度的受控模拟

固定同一批查询、ACL 与 NFKC 归一化，只改变候选深度和 BM25 权重（top-5、未叠加
产品重排），结果如下：

| 候选深度 | BM25 0.4 | BM25 0.5 | BM25 0.6 | BM25 0.7 | BM25 0.8 |
| ---: | --- | --- | --- | --- | --- |
| 10 | - | - | 29/30 | 29/30 | 29/30 |
| 15 | 29/30 | 30/30 | 30/30 | 30/30 | 30/30 |
| 20 | - | - | 30/30 | 30/30 | 30/30 |
| 30 | 29/30 | 30/30 | 30/30 | 30/30 | 30/30 |

表内为 hit@5（30 题中命中至少一个相关块的题数）；`-` 表示该组合未做模拟。深度 15
是 a01 的拐点：低于 15 时只调权重无法召回，达到 15 后 0.5 以上都能召回；0.8 在
15/20/30 三档都取得最高 MRR 与 nDCG。完整数据在
`artifacts/ragas/rank-diagnostics-{10,15,20,30}.json`。

### 逐题变化

相对基线，7 道题的名次或召回发生变化，其中 6 道改善：

| ID | 变化 | 说明 |
| --- | --- | --- |
| a01 | MRR 0 → 1.0，召回 0 → 1.0 | 缴款时限指南从缺失变为第 1 |
| a07 | MRR 0.333 → 1.0 | 申诉材料块从第 3 升到第 1 |
| a11 | MRR 0.5 → 1.0 | 相关块升到第 1 |
| a22 | MRR 0.5 → 1.0 | 相关块升到第 1 |
| a28 | 召回 0.5 → 1.0 | 过户块从缺失进入第 2 |
| a30 | nDCG 0.877 → 1.0 | 排序更优 |
| a09 | MRR 1.0 → 0.5，nDCG 0.92 → 0.693 | 唯一回退，相关块仍在第 2，不影响命中 |

a02 的 `c-fine-payment-guide` 在 topK=5、候选深度 15 下仍未召回；它的向量名次是
16，需要候选深度 ≥16。生产默认 topK=10 时深度为 30，该块进入第 2 名，因此这不是
生产配置的召回缺口。

### 默认候选深度检查

生产默认 `topK=10` 配合倍率 3 会请求深度 30。深度 30 的受控排名诊断（topK=5）显示，
基线遗漏的 `c-fine-payment-guide` 在 a01、a02 分别排第 1 和第 2，`c-vehicle-transfer`
在 a28 排第 2；真实 API 的 top-5 改进复跑也命中 30/30 题。此处不把受控排名模拟表述为
独立的 topK=10 端到端评测，生产部署如调整权重、topK 或索引仍应按实际配置复测。

### 被否决的方案：先重排后截断

考虑过把轻量重排提前到 `fuseResults` 的截断之前。模拟结果（topK=5，旧权重 0.4）：

| 方案 | hit@5 | 召回 | MRR | nDCG@5 |
| --- | ---: | ---: | ---: | ---: |
| 截断后重排（现状） | 29/30 | 0.9333 | 0.9111 | 0.8928 |
| 重排后截断 | 30/30 | 0.9667 | 0.9178 | 0.9057 |

该方案能补回 a01，但 MRR/nDCG 仍明显低于仅调整权重与深度的 0.9833/0.9769；
在 0.6/0.8 权重下两种顺序结果完全相同，说明收益主要来自融合配置而非重排时机。
本轮不引入结构调整，避免增加延迟与复杂度。

## 答案质量（RAGAS）

本轮与基线使用相同数据集、答案模型、裁判模型、评测嵌入与 topK=5。评分阈值仍是 advisory：

| 指标 | 基线 | 本轮 | 目标 | 本轮结果 |
| --- | ---: | ---: | ---: | --- |
| Faithfulness | 0.8017 | 0.8256 | 0.7500 | PASS |
| Response Relevancy | 0.7918 | 0.8418 | 0.7500 | PASS |
| Context Precision (with reference) | 0.8511 | 0.8556 | 0.6000 | PASS |
| Context Recall | 0.9667 | 0.9667 | 0.8500 | PASS |
| Answer Correctness | 0.7601 | 0.6479 | 0.5500 | PASS，低于基线 |
| Citation compliance | 0.9667 | 1.0000 | 0.9000 | PASS |
| Fallback rate | 0.0000 | 0.0000 | ≤ 0.1000 | PASS |

30/30 可回答样本可评分，覆盖率 100%；上下文漂移、provider 错误、引用护栏拒答和 ACL 泄漏均为 0。
四道多跳题的 Context Precision 为 0.3333，低于整体均值；Answer Correctness 从基线的 0.7601 降到
0.6479，不能据此宣称整体答案正确性提升。评分由 `qwen2.5:7b` 裁判，解释单题分数时仍需核对原文。

## 输出卫生与拒答

复跑产物中的 30 条可回答答案没有出现 `retrieved_context`、`retrieved context`、
`retrieved-context`、`manual_rag_document` 或 `rag_chunk` 等内部标识（0/30）。
提示词约束与输出清洗共同改善了输出卫生；输出清洗应独立于引用强制开关工作。

不可回答题拒答为 0/3（0%），低于 80% 的 advisory 目标：三题都出现了用相邻上下文或通用知识补全答案的情况。
这也说明引用格式检查只能确认引用存在，不能确认引用实际支持结论；后续需要单独设计拒答与证据蕴含校验。

## 结论与后续

- 融合权重与候选深度是当前最高性价比的检索杠杆；配置已进入默认值与环境变量，
  不需要改代码即可回退或继续调参。
- 内部标签清洗与提示词约束解决了产品可见的输出卫生问题；引用护栏现在判定的是
  用户实际看到的文本。
- 下一轮优先级：不可回答题的拒答与“引用是否真的支持结论”的检查；更强答案模型或
  语言后校验；修复 DEPARTMENT ACL 身份折叠；把 ES alias 存在性纳入启动检查。

## 复现

```bash
cd finalAssignmentBackend
AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true \
RAG_INDEX_NAME=rag_chunk_ragas_v1 RAG_INDEX_ALIAS=rag_chunk_ragas_current \
RAG_RETRIEVAL_BM25_WEIGHT=0.8 RAG_RETRIEVAL_VECTOR_WEIGHT=0.2 \
RAG_RETRIEVAL_CANDIDATE_MULTIPLIER=3 \
mvn spring-boot:run

cd scripts/ragas
uv sync --frozen
uv run ragas-eval validate
uv run ragas-eval preflight
uv run ragas-eval seed
uv run ragas-eval run --top-k 5 --run-id improvement-20261023 \
  --max-workers 2 --metric-timeout 300 --max-retries 1
```

检索 A/B 与诊断脚本是本轮的一次性工具，位于 `artifacts/ragas/`（gitignored）：
`retrieval_eval.py`、`rank_diagnostics.py`、`rerank_simulation.py`。

## 局限

- RAGAS 只覆盖纯 RAG 模式；默认 Agent 模式仍走工具路由，不在本轮范围。
- 绝对分数依赖 qwen2.5:7b 裁判；个别 0 分需结合原文复核。跨运行比较固定了数据集、
  裁判与 topK，但复跑结果仍可能受裁判波动影响。
- 检索 A/B 的评价集只有 30 道可回答题，a02 的残余缺块是 topK=5 评测口径的结果；
  生产 topK=10 的完整召回由单独的受控检查证明，不与 topK=5 指标直接混比。
- 未覆盖扫描版 PDF、图片 OCR、多轮对话与部门语料可见性。
