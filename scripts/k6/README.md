# k6 压测脚本

脚本默认连接 `http://127.0.0.1:8080`。本地种子账号默认值如下，可通过环境变量覆盖：
## 多后端

同一套脚本覆盖 Spring / Cloud / Go / Quarkus。路径不变：`/api/rag/admin` 与 `/api/ai/chat/stream`。

| 后端 | `BACKEND` | 默认 `BASE_URL` |
| --- | --- | --- |
| Spring 单体 | `spring` | `http://127.0.0.1:8080` |
| Spring Cloud 网关 | `cloud` | `http://127.0.0.1:8080` |
| Go | `go` | `http://127.0.0.1:8080` |
| Quarkus | `quarkus` | `http://127.0.0.1:8080` |

```powershell
$env:BACKEND='go'
$env:BASE_URL='http://127.0.0.1:8080'
k6 run scripts/k6/ai-rag-staged-load.js
```

统一编排：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 -Backend quarkus -Duration 20s
```

`ai-rag-staged-load.js` 额外覆盖：

- SUPER_ADMIN：`GET /api/rag/admin/overview|documents/{id}`、`POST /preview`
- ADMIN：可访问 RAG 管理接口（200）
- USER/驾驶员：RAG 管理接口 403
- 驾驶员帮办循环：`POST /api/ai/chat/stream` 查询自己的违法、写操作先草稿、他人 draft 拒绝

响应体会自动解开 `{ success, data }` 包装，因此 Cloud / Go / Quarkus 与 Spring 可共用脚本。




## Cloud / Go / Quarkus 高并发

`high-concurrency-load.js` 专门打三端高并发：驾驶员读、管理员读、RAG 管理/preview、RAG 检索，以及限流后的帮办 SSE。默认峰值约 160/120/40 VU + RAG 25 req/s + agent 6 req/s。

单独打一个后端：

```powershell
$env:BACKEND='cloud'
$env:BASE_URL='http://127.0.0.1:8080'
k6 run scripts/k6/high-concurrency-load.js
```

Go / Quarkus 若占用不同端口：

```powershell
$env:BACKEND='go'
$env:BASE_URL_GO='http://127.0.0.1:18080'
k6 run scripts/k6/high-concurrency-load.js
```

一次打三端（健康检查失败的会跳过）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-high-concurrency.ps1 `
  -Backend all `
  -CloudUrl http://127.0.0.1:8080 `
  -GoUrl http://127.0.0.1:18080 `
  -QuarkusUrl http://127.0.0.1:8081 `
  -Hold 2m `
  -DriverVus 160 `
  -AdminVus 120
```

只打业务读、不要帮办 SSE：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-high-concurrency.ps1 -Backend quarkus -SkipAgent
```

摘要输出到 `artifacts/k6/high-concurrency-<backend>-summary.json`。

| 角色 | 用户名 | 密码 | 环境变量 |
| --- | --- | --- | --- |
| 驾驶员 | `ce@ce.com` | `123456` | `PERF_USERNAME` / `PERF_PASSWORD` |
| 普通管理员 | `admin` | `Admin@123456` | `PERF_ADMIN_USERNAME` / `PERF_ADMIN_PASSWORD` |
| 超级管理员 | `superadmin` | `SuperAdmin@123456` | `PERF_SUPER_USERNAME` / `PERF_SUPER_PASSWORD` |

## 全链路混合压测

覆盖健康检查、驾驶员读链路、普通管理员六大业务读链路、超级管理员日志/RAG 读链路和登录基线。

```powershell
$env:BASE_URL='http://127.0.0.1:8080'
$env:PERF_DURATION='20s'
$env:PERF_USER_VUS='8'
$env:PERF_ADMIN_VUS='6'
$env:PERF_SUPER_VUS='2'
$env:PERF_LOGIN_RATE='1'
$env:PERF_SUMMARY_JSON='artifacts/k6/full-api-load-summary.json'
k6 run scripts/k6/full-api-load.js
```

## 认证读链路压测

用于单独观察 `/api/auth/me` 与登录基线，不建议和 wrk 登录压测连续高强度执行。

```powershell
$env:PERF_READ_VUS='12'
$env:PERF_LOGIN_RATE='1'
k6 run scripts/k6/auth-read-load.js
```

## AI/RAG 分段压测

`ai-rag-staged-load.js` 将 AI 链路拆成三段观测：

- AI HTTP 编排：`GET /api/ai/chat/actions`
- RAG 检索：`POST /api/rag/query`
- 模型生成：`POST /api/ai/chat/stream`

默认不把 AI actions / 模型生成失败作为进程失败，只记录成功率，避免把模型不可用或 agent 异常误判为 HTTP 层性能。需要严格阈值时设置 `PERF_STRICT=true`。

```powershell
$env:PERF_DURATION='20s'
$env:PERF_AI_ACTION_RATE='1'
$env:PERF_RAG_RATE='1'
$env:PERF_INCLUDE_MODEL='false'
k6 run scripts/k6/ai-rag-staged-load.js
```

启用模型生成阶段：

```powershell
$env:PERF_INCLUDE_MODEL='true'
$env:PERF_MODEL_RATE='1'
k6 run scripts/k6/ai-rag-staged-load.js
```

`scripts/performance/run-load-tests.ps1` 会先调用 `scripts/performance/seed-rag-load-dataset.ps1` 写入专用 RAG 压测资料，再以 `PERF_STRICT=true` 执行 AI/RAG 分段压测。`ai-rag-staged-load.js` 会在 AI stream 摘要中分别输出真实 `ollama` 调用成功率和 `noop fallback` 比例。

## 2026-09-21 四后端结果

同一套脚本、`Duration 20s`。总览：`docs/performance/load-test-2026-09-21.md`。

| 后端 | 全 API checks | p95 | 报告 |
| --- | ---: | ---: | --- |
| spring | 1.000 | 56ms | [spring](../../docs/performance/load-test-2026-09-21-spring.md) |
| cloud | 1.000 | 97ms | [cloud](../../docs/performance/load-test-2026-09-21-cloud.md) |
| quarkus | 1.000 | 101ms | [quarkus](../../docs/performance/load-test-2026-09-21-quarkus.md) |
| go | 0.571 | 3.6ms | [go](../../docs/performance/load-test-2026-09-21-go.md) |

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 -Backend spring -Duration 20s
powershell -ExecutionPolicy Bypass -File scripts\start-cloud-backend.ps1 -IncludeAi
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 -Backend cloud -Duration 20s
```

## 本地完整编排

推荐优先使用统一入口，统一传入 RAG 查询词、AI actions 业务意图和模型生成提示词，避免 PowerShell 中文编码影响脚本参数：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Duration 20s `
  -DriverVus 8 `
  -AdminVus 6 `
  -SuperVus 2 `
  -LoginRate 0 `
  -IncludeModel
```

如果启用真实 Ollama，`PERF_STRICT=true` 会把 `/api/ai/chat/actions` 的尾延迟也纳入阈值判断；模型参与动作编排时该场景可能因为 `ai_http_orchestration_ms` 超阈值而返回 k6 exit code `99`。
