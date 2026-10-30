# RAGAS 答案质量基线（topK=10，2026-10-30）

本报告是 Spring 主后端在**默认 topK=10** 口径下的重跑基线。它与
[baseline-2026-10-23.md](baseline-2026-10-23.md)、`20261029-refusal-verifier` 的差别只有两点：
`--top-k` 从 5 提到 10（与四端交互式聊天默认值一致），以及**显式开启生成后主题校验**
（`AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b`）。

起因是 `20261029-refusal-verifier` 那次运行漏配主题校验模型，导致「不可答拒答 0/3」的
假结论；补配置后 5 和 10 两个 topK 都拒答 3/3，于是按线上默认值定稿，重跑一份可长期
对照的基线。

## 结论摘要

- 五项 RAGAS 指标与引用合规全部达标，无硬失败：Faithfulness 0.9036、Response Relevancy
  0.8900、Context Precision 0.9468、Context Recall 1.0000、Answer Correctness 0.7770、
  引用合规 28/28（分母为已交付答案）。
- **topK=10 把上一轮剩下的块级漏召回补齐**：相关块召回 100%（topK=5 对照运行
  `20261029-refusal-verifier` 为 98.33%，唯一缺口是 a02 的 `c-fine-payment-guide`），
  Context Recall 从 0.9815 升到 1.0000。top-10 命中数两种口径都是 30/30，差异只在块级。
  更早的 `baseline-2026-10-23`（候选深度倍率 2、权重不同）曾有 a01/a02/a28 三处漏召回，
  在倍率改 3 之后已只剩 a02 一处。
- 代价是上下文预算翻倍：单题最大上下文从 379 token 涨到 763 token（预算 1200），答案
  延迟中位数从 692 ms 涨到 811 ms。
- 配对比较（两次运行都评分的 26 题）显示检索侧净改善、生成侧轻微下滑：Faithfulness
  −0.0750，26 题里只有 5 题有非零变化——a17 −1.0、a11 −0.5、a27 −0.5、a23 −0.2、
  a03 +0.25。a17/a27 是模型漏掉并列项，a11 是裁判假阴性（内容完整却给 0.5）。
  Response Relevancy +0.0366、Answer Correctness +0.0063、Context Precision −0.0135。
- 拒答侧保持稳定：不可答 3/3 拒答，ACL 泄漏 0/3，上下文漂移 0，provider 错误 0，fallback 0。

## 运行环境

| 项目 | 值 |
| --- | --- |
| 运行 ID | `baseline-20261029-topk10-verifier` |
| 时间 | 2026-10-29T17:19:46+00:00（本地 2026-10-30 01:19） |
| 评测时 HEAD | 17ec08ac（`git_dirty=true`） |
| 后端 | http://localhost:9080（`dev` profile） |
| 答案模型 | llama3.2 |
| 产品嵌入 | nomic-embed-text（768 维） |
| 裁判模型 | qwen2.5:7b |
| 评测嵌入 | bge-m3（仅评测侧） |
| RAGAS / Python | 0.4.3 / 3.12.9 |
| topK | 10 |
| 候选深度 | 30（`candidate-multiplier=3`） |
| 索引 name / alias | `rag_chunk_ragas_v1` / `rag_chunk_ragas_current` |
| 主题校验 | 开启（`AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b`） |
| 语料文档数 | 31（30 个 golden chunk + 1 个 USER 控制文档） |
| 数据集 hash | `292298fd0e39` |
| golden set hash | `d8d8659a7e59` |
| 语料 hash | `42a579afea01` |

`git_dirty=true` 的来源是本轮尚未提交的评测侧改动（`ragas_eval/config.py` 的
`DEFAULT_TOP_K`、CLI help、`.env.example`、`scripts/ragas/README.md`）与 README 文案，
**不包含任何后端代码**——被测后端就是 17ec08ac 这一次提交。

## 结果总表

| 指标 | 均值 | 目标 | 结果 |
| --- | ---: | ---: | --- |
| Faithfulness | 0.9036 | 0.7500 | PASS |
| Response Relevancy | 0.8900 | 0.7500 | PASS |
| Context Precision (with reference) | 0.9468 | 0.6000 | PASS |
| Context Recall | 1.0000 | 0.8500 | PASS |
| Answer Correctness | 0.7770 | 0.5500 | PASS |
| Citation compliance（已交付答案） | 1.0000 | 0.9000 | PASS |
| Citation compliance（含拒答，旧口径） | 0.9333 | - | - |
| Fallback rate | 0.0000 | ≤ 0.1000 | PASS |
| 不可回答拒答率 | 1.0000 | ≥ 0.8000 | PASS |
| 可评分覆盖率 | 0.9333 | ≥ 0.9000 | PASS |
| ACL 泄漏 | 0 / 3 | 0 | PASS（硬失败） |
| 上下文漂移 | 0 | 0 | PASS（硬失败） |
| Provider 错误 | 0 | 0 | PASS（硬失败） |

阈值来自 `scripts/ragas/targets.json`，`enforce=false`；只有 ACL 泄漏、上下文漂移、
provider 错误与预检失败是硬失败，实际均为 0。

## 样本与覆盖

| 项目 | 值 |
| --- | ---: |
| 可回答题 | 30 |
| 可评分样本 | 28 |
| 可评分覆盖率 | 93.33% |
| 引用护栏拒答 | 2 |
| 排除原因 | `guardrail_no_source=1`、`guardrail_uncited=1` |
| 多跳题 | 4（全部可评分） |
| 上下文预算 | 最大 763 / 1200 token，全部在预算内 |
| 答案延迟中位数 | 811.3 ms（p90 1054.2 ms） |

被排除的两题：

| ID | 问题 | 拦截环节 | 检索是否命中正确块 |
| --- | --- | --- | --- |
| a16 | 超速百分之二十以上未达百分之五十如何处罚？ | 主题校验（no_source） | 是（c-offense-speeding 第 1） |
| a19 | 业务办理进度在哪里查看，会推送哪些节点？ | 引用护栏（uncited） | 是（c-progress-message 第 1） |

两题的正确块都排在第 1 位，拦截发生在**生成层**而不是检索层：a19 模型没给引用且一次
修复重试后仍无引用，a16 则被主题校验判定「检索资料没有覆盖所问主题」。这与上一轮
topK=5 的排除集合（a10、a16、a28）不同——a10 和 a28 在这次都通过了护栏并拿到分数，
a19 反而被拦。同一构建的排除集合本来就不稳定，见「局限」。

多跳切片（4 题全评分）：Faithfulness 0.7500、Response Relevancy 0.8809、
Context Precision 0.6607、Context Recall 1.0000、Answer Correctness 0.7811。
多跳的 precision 偏低来自 a28：检索到了两个正确块（recall 1.0），但答案把「过户」写成
「注册登记」，裁判据此把证据判为不精确。

## 检索质量诊断

| 指标 | 值 |
| --- | ---: |
| top-10 命中题数 | 30 / 30（100%） |
| 相关块召回（按 relevantChunkIds 并集） | 100% |
| RAGAS Context Recall | 1.0000 |
| RAGAS Context Precision | 0.9468 |
| 单题最大上下文 | 763 token |

对照 `20261029-refusal-verifier`（topK=5）：命中同为 30/30，块级召回 98.33%，唯一缺口是
a02 的 `c-fine-payment-guide`。提高到 topK=10 后该块进入结果，召回达到 100%。
这与 [baseline-2026-10-23.md](baseline-2026-10-23.md) 的诊断一致：候选深度 =
topK × multiplier，topK=5 且倍率 2 时候选深度只有 10，BM25 top-1 的正确块进不了向量
候选列表；本轮倍率已改为 3、topK=10，候选深度 30，剩余缺口自然消失。

需要注意 topK 变化会改变候选深度与 RRF 分数，最终列表**不是**简单的 topK 嵌套。
`baseline-2026-10-23` 已实测 topK=5 的结果并非 topK=10 结果的前 5 条，因此跨 topK 的
指标不能逐题对照，只能整轮比较。

## 与 topK=5 基线的对比

对照对象是 `20261029-refusal-verifier`（topK=5、commit 64273f73、端口 9381、可评分
27/30）。两次运行的可评分集合不同（topK=5 排除 a10/a16/a28，topK=10 排除 a16/a19），
所以先给可直接对照的整轮数字，再给**同一批 26 题的配对均值**——后者才是判断 topK 影响
的依据。

整轮（不同分母，仅供参考）：

| 指标 | topK=5 | topK=10 | 差 |
| --- | ---: | ---: | ---: |
| Faithfulness | 0.9907 | 0.9036 | −0.0871 |
| Response Relevancy | 0.8521 | 0.8900 | +0.0379 |
| Context Precision | 0.9949 | 0.9468 | −0.0481 |
| Context Recall | 0.9815 | 1.0000 | +0.0185 |
| Answer Correctness | 0.7713 | 0.7770 | +0.0057 |
| 可评分覆盖 | 27/30 | 28/30 | +1 题 |

配对（两次都评分的 26 题，同一裁判、同一数据集）：

| 指标 | topK=5 | topK=10 | 配对差 |
| --- | ---: | ---: | ---: |
| Faithfulness | 0.9904 | 0.9154 | **−0.0750** |
| Response Relevancy | 0.8521 | 0.8887 | +0.0366 |
| Context Precision | 0.9947 | 0.9811 | −0.0135 |
| Context Recall | 0.9808 | 1.0000 | +0.0192 |
| Answer Correctness | 0.7743 | 0.7806 | +0.0063 |

配对集合里仅新增 a10、a28，仅缺 a19。Faithfulness 的跌幅逐题拆开，26 题里只有 5 题
有非零变化，合计 −1.95 分（−1.95 / 26 = −0.0750，与配对差完全吻合）：

| ID | 问题 | 配对差 | 观察 | 性质 |
| --- | --- | ---: | --- | --- |
| a17 | 超速未达百分之二十如何处罚？ | −1.000 | 上一轮答「处警告或二百元以下罚款」，本轮只答「二百元以下罚款」，漏掉并列处罚「警告」 | 真实缩答 |
| a27 | 超速百分之二十以上和违章停车分别怎么处罚？ | −0.500 | 本轮漏掉「可将车辆拖移至不妨碍交通的地点」 | 真实缩答 |
| a11 | 满分学习需要多长时间，考试内容是什么？ | −0.500 | 本轮「七日学习 + 科目一」两项都在，且上下文 [1] 同时包含两者；上一轮拆成 [1][2] 两个引用得 1.0，本轮合并成一个引用得 0.5 | **裁判假阴性** |
| a23 | 智能助手能回答哪些问题，回答是否附带来源？ | −0.200 | 漏答「附带引用来源」，属真实缺失但幅度被压低 | 真实缺失 |
| a03 | 逾期缴纳罚款的滞纳金如何计算，最多会是多少？ | +0.250 | 本轮忠实度更高 | 改善 |

a17 与 a27 的正确块在两种 topK 下都排第 1，检索完全没变，变的是模型这次没把并列项
写全。所以这不是 topK 破坏了答案忠实度，而是**上下文变长后 llama3.2 更容易压缩答案、
丢掉并列项**。README 已记录同一构建两次运行的 Faithfulness 配对差可达 −0.0370、单题
最大 −1.0，a17 与 a27 落在既有采样噪声的形态里；a11 则是纯粹的裁判不稳定。

## 弱样例

按 Answer Correctness 升序的前六题：

| ID | 问题 | 关键指标 | 观察 |
| --- | --- | ---: | --- |
| a07 | 提交申诉需要提供哪些材料？ | AC 0.4609 / F 1.000 | 只答「上传证据照片或视频」，漏掉参考答案里的身份证明与行驶证 |
| a14 | 车辆过户需要哪些证件，在哪里办理？ | AC 0.4874 / F 1.000 | **答案与参考答案几乎逐字相同**（身份证、行驶证、登记证书、车管所、转移登记全中），仍被判 0.487 |
| a26 | 记满十二分并考试合格后，记分会怎么处理？ | AC 0.5758 / F 1.000 | 只说「记分将被清除」，漏掉前置的七日满分学习与科目一 |
| a09 | 一个记分周期内记满十二分会怎样？ | AC 0.5865 / F 1.000 | 只答「学习并考试」，漏七日满分学习、科目一与「记分予以清除」 |
| a01 | 罚款最晚需要在多长时间内缴纳？ | AC 0.5930 / F 1.000 | 本轮正确答出 15 日（上一轮误答 60 日），仍漏「逾期将产生滞纳金」 |
| a04 | 缴款成功后如何获取电子票据？ | AC 0.5976 / F 0.833 | 漏「系统自动生成」与「与纸质票据同等法律效力」 |

共同形态是 **faithfulness 高、correctness 中等**：答案说的每句都能在上下文里找到，
但只覆盖了参考答案的一部分。这是当前生成侧的稳定短板（答案过短），与检索无关。

但 a14 是反例，必须单独拎出来：答案内容与参考答案等价，五项指标里 precision / recall /
faithfulness 都是 1.0，只有 Answer Correctness 是 0.487。同一个答案在上一轮
`20261029-refusal-verifier` 里同样只拿到 0.4874，说明这是 **answer_correctness 的
裁判口径问题（对逐字正确的短答案给低分），不是答案缺陷**。这也意味着 0.7770 这个均值
偏保守。

两个 0 分点需要单独说明，都有明确原因，不是指标噪声：

- a17 Faithfulness 0.000：漏掉「警告」，剩下的「二百元以下罚款」单独看仍成立，但裁判
  对比参考答案后判为不忠实。属于缩答导致的并列项丢失。
- a28 Context Precision 0.000：检索到的两个块都相关（recall 1.0），但答案把「过户」
  说成「办理注册登记」（应为「转移登记」），裁判据此判定证据不支持结论。

## 不可回答与 ACL

| ID | 问题 | 是否拒答 | 观察 |
| --- | --- | --- | --- |
| u01 | 车辆达到报废标准后应如何办理报废？ | 是 | 主题校验拦截，标准拒答文案 |
| u02 | 外地驾驶证转入本地需要哪些手续？ | 是 | 上一轮先「没有发现规定」再继续作答，本轮直接拒答 |
| u03 | 在高速公路上占用应急车道会怎么处罚？ | 是 | 上一轮用违停条款硬答并带 [4]，本轮拒答 |

3/3 全部拒答，且拒答文案与 `NO_SOURCE_ANSWER` 常量逐字一致（该一致性已由
`scripts/ragas/tests/test_refusal_text_parity.py` 跨四后端守卫）。

ACL 探针 3/3 通过，受限 `sourceId`（`c-admin-audit-log`、`c-user-offense-mine`、
`c-dept-finance-sop`）均未出现在检索结果中，`control_visible=true`。已知 DEPARTMENT
缺陷未在本次工具链中绕过（详见「局限」）。

## 输出卫生

本轮 30 题答案中**没有**出现 `retrieved_context`、`retrieved context`、
`manual_rag_document[...]`、`[ unspecified ]` 或 `Supporting sentence` 等内部标签或
占位符（正则全量扫描，命中 0 题）。对比 2026-10-23 基线的 6/30 泄漏，输出清洗层的
效果是稳定的。

## 指标口径提醒

本次运行产出的 `metrics.json` 里 `citation_compliance` 是**旧口径 0.9333**
（28/30，分母含护栏拒答）。这个口径有问题：两处「不合规」正是被引用护栏拒答的 a16、a19
（拒答文本本来就不带 `[n]`），所以 28/30 = 1 − 2/30，指标与拒答率互为镜像，读数会随
拒答策略变动而漂移。

跑完本轮后已把工具链改成：`citation_compliance` 的分母改为**已交付答案**（剔除 provider
错误与护栏拒答），同时保留 `citation_compliance_all` 记录旧口径。按新定义重算本轮：

| 口径 | 分子/分母 | 值 |
| --- | --- | ---: |
| Citation compliance（已交付） | 28 / 28 | 1.0000 |
| Citation compliance（含拒答，旧口径） | 28 / 30 | 0.9333 |
| 其中引用合规拒答 | 1 / 30 | 3.33% |

要诚实说明：引用强制生效时交付答案必然带引用，所以新口径在四个后端上都是 1.0000，
**它本身没有区分度**，作用是「不再把拒答算成引用缺陷」。真正有信息量的是另外两行——
被引用护栏拦下的题数（本例 1 题），以及关掉引用强制后才会波动的 `citation_compliance`。
拒答规模仍由 `scored_coverage`（0.9333，目标 0.90）与 `exclusion_reasons` 兜底。

历史产物未回溯改写：`artifacts/ragas/*/metrics.json` 保留生成时的旧口径数值。

## 结论与建议

1. **把 topK=10 定为评测与产品的统一口径**（已落地：`DEFAULT_TOP_K=10`、四端
   `chat_top_k=10`、CLI help 与 `.env.example` 同步）。召回缺口被彻底补上，代价是上下文
   token 翻倍、延迟 +120 ms 中位数，仍在预算内。
2. **旧基线不可直接比较**：topK=5 的 `baseline-2026-10-23`、`20261029-refusal-verifier`
   与本轮的候选深度、RRF 分数、可评分集合都不同。复现旧数必须显式传 `--top-k 5`。
3. **答案过短是当前最大质量缺口**（中高优先级）：a07/a26/a09/a04 都是「忠实但不全」。
   可在提示词里要求「逐条覆盖检索资料中的并列条件与后续影响」，或用答案完整性检查做
   生成后补全。
4. **并列项丢失需要单独盯**（中）：a17（「警告或罚款」）与 a27（「罚款并可拖移」）的
   −1.0/−0.5 都发生在并列处罚上，模型只保留了一条。若要稳定，输出后校验应检查「或」
   「并」连接的第二项是否出现。
5. **裁判假阴性需要人工复核兜底**（中）：a11（内容完整却 0.5）与 a14（逐字等价却
   0.487）证明小裁判模型对引用编号数量、短答案长度敏感。单题低分不能直接当缺陷处理，
   报告中应保留原始答案供复核。
6. **`citation_compliance` 分母已修正**（已完成）：拒答不再计入引用合规分母，旧口径保留为
   `citation_compliance_all`。注意新口径在引用强制生效时恒为 1.0000，判定回归要看
   「其中引用合规拒答」与旧口径，不能只看这一个数。

## 复现

```bash
cd finalAssignmentBackend
SERVER_PORT=9080 AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true \
AI_GUARDRAIL_TOPIC_MODEL=qwen2.5:7b \
RAG_INDEX_NAME=rag_chunk_ragas_v1 RAG_INDEX_ALIAS=rag_chunk_ragas_current \
mvn spring-boot:run

cd scripts/ragas
uv sync --frozen
uv run ragas-eval validate
uv run ragas-eval preflight
uv run ragas-eval seed
uv run ragas-eval run --top-k 10 --run-id baseline-20261029-topk10-verifier
```

原始产物位于 `artifacts/ragas/baseline-20261029-topk10-verifier/`（gitignored）：
`report.md`、`metrics.json`、`samples.jsonl`、`manifest.json`。

## 局限

- 只覆盖纯 RAG 模式（`AI_AGENT_ENABLED=false`）；默认 Agent 模式会把知识问题路由到
  数据库工具，答案不再由检索上下文驱动。
- 同一构建的**排除集合不稳定**：topK=5 排 a10/a16/a28，topK=10 排 a16/a19，其中 a10
  与 a28 属于边界判定。可评分覆盖率（0.90～0.93）应视为区间而非定值。
- 生成层采样噪声不可忽略：Faithfulness 配对差单题可达 −1.0。判断回归要靠检索侧指标
  （Context Precision / Recall）或多次运行均值，不能看单题。
- 裁判模型为 qwen2.5:7b，绝对分值依赖裁判能力。本轮已逐条复核低分样本：a14（与参考
  答案逐字等价却 0.487）、a11（内容完整却 0.5）确认为假阴性；a17、a28 的 0 分确认为
  真实缺陷。其余中高分样本未逐条复核。
- DEPARTMENT 作用域语料当前对任何身份都不可见（部门身份被折叠成字符串 `"DEPARTMENT"`，
  而 ACL 按真实部门名匹配），ACL 探针因此只覆盖 ROLE / USER。
- 数据集固定为 30 + 3 + 3 条，未覆盖扫描版 PDF、图片 OCR 与多轮对话；端到端评测需要
  ES/MySQL/Redis + Ollama，仍未进 CI（CI 的 `ai-quality-gates` 只跑工具链单元测试与配置
  一致性检查）。
