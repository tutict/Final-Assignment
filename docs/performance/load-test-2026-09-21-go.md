# 2026-09-21 k6 / wrk Go 压测报告

## 结论摘要

- 延迟极低：全 API 平均 **2.5ms**，p95 **3.6ms**。这是四后端里最「快」的数字，但 **契约未对齐**，不能当成可用性胜利。
- 全 API：`http_req_failed_rate=0.619`，`checks_rate=0.571`。健康检查 0.000，驾驶员读 0.500，超管读 0.899；管理员业务读 1.000。
- AI/RAG：RAG 检索与 RAG 管理 1.000；AI actions 0.000；USER RAG 403 对齐 0.000；帮办查询循环 1.000 但单次约 **21s**（明显卡在模型/超时边界）。
- wrk 吞吐很高（管理员读 2921 req/s），同时大量 Non-2xx。`rag-query` 与 `login` 无 Non-2xx。

## 测试环境

| 项目 | 配置 |
| --- | --- |
| 日期 | 2026-09-21 |
| 后端 | Go / Gin `final_assignment_backend_go`，报告中的 `BASE_URL=http://127.0.0.1:8080` |
| 压测入口 | `scripts/performance/run-load-tests.ps1 -Backend go -Duration 20s` |
| 原始输出 | `artifacts/performance/2026-09-21/go/` |

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Backend go -Duration 20s -DriverVus 8 -AdminVus 6 -SuperVus 2 -LoginRate 1
```

## k6 全 API 混合压测

| 指标 | 结果 |
| --- | ---: |
| 请求数 | 3540（约 83 req/s） |
| HTTP 失败率 | **0.619** |
| checks | **0.571** |
| 平均 / p95 / p99 | 2.5ms / **3.6ms** / 12.6ms |
| health_ok | **0.000** |
| user_read_ok | **0.500** |
| admin_read_ok | 1.000 |
| super_read_ok | 0.899 |

解读：

- `health_ok=0` 说明 k6 探测的健康路径（`/actuator/health` 等）与 Go 实际暴露的 `/api/actuator/health` 或响应体未对上，尽管其它业务读已经打到 8080。
- `user_read_ok=0.5` 与 Cloud 修复前相同形态，高度疑似 `/api/appeals/my` 缺失或 4xx，而 `/api/auth/me` 成功。
- 管理员读全过，说明车辆/违法/罚款等主路径可用。

## k6 AI/RAG 分段压测

| 链路 | 成功率 | 平均 | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| AI HTTP 编排 | **0.000** | 7.6ms | 15.0ms | 16.7ms |
| RAG 检索 | 1.000 | 13.5ms | 20.7ms | 22.0ms |
| RAG 管理 | 1.000 | 4.9ms | 18.6ms | 21.1ms |
| USER RAG 管理 403 | **0.000** | — | — | — |
| 帮办查询循环 | 1.000 | **21374ms** | 21413ms | 21452ms |
| 帮办草稿/拒绝 | **0.000** | — | — | — |

AI actions 失败快（~8ms），更像 4xx/空体而不是模型超时。帮办 SSE 成功但每次约 21s，接近客户端超时，不适合作为高并发场景。

## wrk（20s）

| 场景 | 请求 | req/s | 平均延迟 | Non-2xx |
| --- | ---: | ---: | ---: | ---: |
| driver-read-mix | 46934 | 2346 | 14ms | 17605 |
| admin-read-mix | 58702 | 2921 | 16ms | 7831 |
| super-read-mix | 55550 | 2755 | 12ms | 23812 |
| rag-query | 17215 | 856 | 10ms | 0 |
| rag-admin-preview | 14902 | 744 | 15ms | 261 |
| ai-actions | 60199 | 3009 | 2.6ms | **60199**（全部非 2xx） |
| login | 1671 | 83 | 191ms | 0 |

Go 的 wrk 吞吐远高于 Java 系，但 ai-actions 100% Non-2xx 与 k6 actions 失败一致，应先补契约再谈吞吐。
