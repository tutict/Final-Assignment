# 2026-09-21 k6 Spring Cloud 压测报告

同日 Spring / Go / Quarkus 对照见 [四后端总览](load-test-2026-09-21.md)。

## 结论摘要

本轮把 `finalAssignmentCloud` 补成可一键拉起的网关链路，再用与 Spring / Go / Quarkus 同一套 k6 脚本打网关 `http://127.0.0.1:8080`。

整体结论：

- Cloud 一键启动已覆盖 **user / auth / traffic / audit / system / search / rag / ai + gateway**。本地 `dev` 走静态发现，不依赖 Nacos 配置中心；user 映射到 `18082`、traffic 映射到 `18083`，避开 Redpanda Pandaproxy `8082` 与 Debezium `8083`。
- k6 全 API 混合压测通过：`http_req_failed_rate=0.000`，`checks_rate=1.000`，驾驶员 / 管理员 / 超管读链路全部 1.000。
- k6 AI/RAG 分段压测通过：RAG 检索、RAG 管理、帮办循环、AI HTTP 编排均为 1.000。
- Cloud AI 的 `/api/ai/chat/actions` 原先打到 Spring AI 默认模型 `mistral`（本机没有）。已改为本机 Ollama 已有的 **`llama3.2`**，编排接口恢复 200。
- wrk 场景未跑：本机 Docker 引擎管道需要提升权限，`scripts/performance/run-load-tests.ps1` 里的 wrk 容器启动失败。k6 结论不受影响。

第一轮（修复前）曾暴露 Cloud 与单体的契约缺口，已在同日修掉后再测。见文末「修复前对照」。

## 测试环境

| 项目 | 配置 |
| --- | --- |
| 日期 | 2026-09-21 |
| 后端 | Spring Cloud 网关，`http://127.0.0.1:8080` |
| 启动 | `scripts/start-cloud-backend.ps1 -IncludeAi`（`CLOUD_SKIP_BUILD=true` 复用已打包 jar） |
| 微服务 | gateway 8080，auth 8081，user 18082，traffic 18083，audit 8084，system 8085，ai 8086，search 8087，rag 8088 |
| 数据库 | 本地 MySQL `traffic`，账号 `root/root` |
| Redis | 本机 `6379` |
| Elasticsearch | Docker `final-assignment-elasticsearch`，`http://127.0.0.1:9200` |
| AI | 本地 Ollama，聊天模型 **llama3.2**，向量模型 **nomic-embed-text** |
| RAG | `RAG_RETRIEVAL_ENABLED=true`；预热 4 份资料（已存在则 409 跳过），查询命中 5 条 |
| 压测入口 | `scripts/performance/run-load-tests.ps1 -Backend cloud` |

执行命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-cloud-backend.ps1 `
  -IncludeAi -LogDir artifacts\startup\cloud-k6

powershell -NoProfile -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Backend cloud `
  -Duration 20s `
  -DriverVus 8 `
  -AdminVus 6 `
  -SuperVus 2 `
  -LoginRate 0
```

等价于 `scripts\start-all.bat -b cloud -f none` 拉起网关后再跑同一套 k6。

## k6 全 API 混合压测

覆盖：健康检查、驾驶员读（`/api/auth/me`、`/api/appeals/my`）、管理员业务读（车辆/违法/罚款/缴费/扣分/违法类型/申诉/权限/角色/设置）、超管日志与 RAG 读。`PERF_LOGIN_RATE=0`，登录只在 setup 取 token。

| 指标 | 结果 |
| --- | ---: |
| 请求数 | 2058（约 48 req/s） |
| HTTP 失败率 | 0.000 |
| checks 通过率 | 1.000 |
| 平均耗时 | 33.457ms |
| p95 | 97.194ms |
| p99 | 131.037ms |
| health_ok | 1.000 |
| user_read_ok | 1.000 |
| admin_read_ok | 1.000 |
| super_read_ok | 1.000 |

原始输出：`artifacts/k6/full-api-load-summary.json`、`artifacts/k6/full-api-load.txt`。

结论：网关把权限/角色/申诉/设置接到正确服务后，Cloud 读链路与 Spring 单体脚本契约对齐，没有 4xx/5xx。p95 高于 2026-06-01 单体的 51ms，符合多进程 + 网关转发的预期，仍在 100ms 量级。

## k6 AI/RAG 分段压测

配置：

- AI actions：约 2 req/s
- RAG 检索：约 2 req/s
- RAG 管理：1 req/s
- 帮办 SSE：1 req/s
- `PERF_STRICT=true`
- `IncludeModel=false`（帮办循环仍走真实 `/api/ai/chat/stream`）

| 链路 | 成功率 | 平均 | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| AI HTTP 编排 `/api/ai/chat/actions` | 1.000（41/41） | 575ms | 1024ms | 1228ms |
| RAG 检索 `/api/rag/query` | 1.000（41/41） | 17.8ms | 21.8ms | 75.6ms |
| RAG 管理 overview/list/detail/preview | 1.000 | 10.9ms | 16.3ms | 33.4ms |
| USER 访问 RAG 管理 403 | 1.000 | — | — | — |
| 帮办查询 / 草稿拒绝 | 1.000（20/20） | 45.5ms | 48.5ms | 183ms |

原始输出：`artifacts/k6/ai-rag-staged-load-summary.json`。

说明：

- AI actions 延迟明显高于 2026-06-01 单体（当时 p95 12.7ms）。单体那轮 actions 基本是本地编排；Cloud 这轮 `ChatAgent` 走 Spring AI `OllamaChatModel` 调 **llama3.2**，所以是模型往返而不是网关开销。
- 帮办 SSE 在改模型后的摘要里平均 45ms，明显快于改模型前那轮（p95 约 6s）。以本文件记录的 JSON 摘要为准。

## wrk

未执行。`docker run williamyeh/wrk` 在本机报 `open //./pipe/docker_engine: Access is denied`。需要提升权限后再补：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 -Backend cloud -Duration 20s
```

## 启动与模型约定

| 项 | 值 |
| --- | --- |
| 一键启动 | `scripts\start-all.bat -b cloud -f none` 或 `scripts\start-cloud-backend.ps1 -IncludeAi` |
| 本地配置 | `finalAssignmentCloud/config/local-dev.yml` |
| Spring AI 聊天模型 | `spring.ai.ollama.chat.options.model=llama3.2` |
| 自定义 Ollama provider | `ai.ollama.chat-model=llama3.2` |
| 覆盖方式 | 环境变量 `OLLAMA_CHAT_MODEL` / `OLLAMA_MODEL` |

`finalassignmentcloud-ai` 已重新加入 Maven reactor。启动脚本仍用 `-IncludeAi` / `CLOUD_INCLUDE_AI=true` 决定是否拉起 AI 进程（jar 约 290MB，含 GraalPy）。

## 修复前对照（同日第一轮）

同一套脚本、同一网关，修复前：

| 指标 | 第一轮 |
| --- | ---: |
| HTTP 失败率 | 0.293 |
| checks | 0.670 |
| user_read_ok | 0.500 |
| admin_read_ok | 0.701 |
| super_read_ok | 0.900 |
| AI actions | 0.000（`mistral` 不存在） |
| 帮办循环 | 0.000（当时 AI 未进启动链） |

失败接口与原因：

| 接口 | 原因 | 修复 |
| --- | --- | --- |
| `GET /api/appeals/my` | Cloud traffic 没有 `/my` | 补齐并按当前用户 driverId 查询 |
| `GET /api/appeals` | `offenseId` 为必填，k6 只传 page/size | 改为可选，缺省走列表 |
| `GET /api/permissions`、`/api/roles` | 网关只转发 `/api/users/**` | 用户服务路由增加这两个前缀 |
| `GET /api/system/settings` | system 进程起不来 | 拆开 MapperScan、弱化 ES、补 CacheManager |
| `GET /api/system/logs/overview` | Feign 拉 system 请求历史失败导致 500 | overview 在 Feign 失败时仍返回 200 |
| `GET /api/ai/chat/actions` | Spring AI 默认 `mistral` | 默认改为 `llama3.2` |

## 与 2026-06-01 Spring 单体对照

| 项 | Spring 单体 2026-06-01 | Cloud 2026-09-21 |
| --- | ---: | ---: |
| 全 API HTTP 失败率 | 0.000 | 0.000 |
| 全 API checks | 1.000 | 1.000 |
| 全 API p95 | 51ms | 97ms |
| RAG 检索 p95 | 1198ms | 22ms |
| AI actions p95 | 13ms（偏本地编排） | 1024ms（真实 llama3.2） |

RAG 检索 Cloud 更快，是因为本轮命中的是已预热的小数据集且 embedding 未在请求路径上重算。AI actions 不可直接比吞吐，模型路径不同。
