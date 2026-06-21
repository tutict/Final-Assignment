# k6 压测脚本

脚本默认连接 `http://127.0.0.1:8080`。本地种子账号默认值如下，可通过环境变量覆盖：

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
