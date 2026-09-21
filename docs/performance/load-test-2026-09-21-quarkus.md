# 2026-09-21 k6 / wrk Quarkus 压测报告

## 结论摘要

- 全 API 混合压测通过：失败率 0、checks 1.000，读链路全绿。吞吐约 **96 req/s**，p95 **101ms**（略高于 Spring 单体，接近 Cloud 网关）。
- AI/RAG：AI actions、RAG 检索、RAG 管理 1.000；**帮办循环 0.000**；USER RAG 403 对齐 0.000。
- wrk 管理员读 / RAG preview / RAG query **无 Non-2xx**。驾驶员混合读与登录出现 timeout（32 / 16），平均延迟偏高。

## 测试环境

| 项目 | 配置 |
| --- | --- |
| 日期 | 2026-09-21 |
| 后端 | Quarkus `final_assignment_backend_quarkus`，`http://127.0.0.1:8080` |
| 压测入口 | `scripts/performance/run-load-tests.ps1 -Backend quarkus -Duration 20s` |
| 原始输出 | `artifacts/performance/2026-09-21/quarkus/` |

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Backend quarkus -Duration 20s -DriverVus 8 -AdminVus 6 -SuperVus 2 -LoginRate 1
```

## k6 全 API 混合压测

| 指标 | 结果 |
| --- | ---: |
| 请求数 | 4143（约 96 req/s） |
| HTTP 失败率 | 0.000 |
| checks | 1.000 |
| 平均 / p95 / p99 | 27.7ms / **101.4ms** / 152.0ms |
| health_ok | 1.000 |
| user_read_ok | 1.000 |
| admin_read_ok | 1.000 |
| super_read_ok | 1.000 |

四后端里全 API 请求数最高，读契约与 Spring / Cloud 对齐。

## k6 AI/RAG 分段压测

| 链路 | 成功率 | 平均 | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| AI HTTP 编排 | 1.000 | 15.6ms | 53.2ms | 60.6ms |
| RAG 检索 | 1.000 | 18.8ms | 56.6ms | 63.0ms |
| RAG 管理 | 1.000 | 14.4ms | 57.1ms | 64.7ms |
| USER RAG 管理 403 | **0.000** | — | — | — |
| 帮办查询循环 | **0.000** | 10.2ms | 47.6ms | 51.8ms |
| 帮办草稿/拒绝 | **0.000** | — | — | — |
| AI stream 返回 | **0.000** | 10.2ms | 28.6ms | 48.4ms |

帮办失败很快（~10ms），更像 SSE/路由/鉴权未打通，而不是模型慢。RAG 查询本身是健康的。

## wrk（20s）

| 场景 | 请求 | req/s | 平均延迟 | Non-2xx | timeout |
| --- | ---: | ---: | ---: | ---: | ---: |
| driver-read-mix | 1802 | 79 | 363ms | 0 | 32 |
| admin-read-mix | 12512 | 625 | 121ms | 0 | — |
| super-read-mix | 13286 | 581 | 104ms | 0 | 28 |
| rag-query | 30794 | 1347 | 89ms | 0 | — |
| rag-admin-preview | 32432 | 1621 | 5.4ms | 0 | — |
| ai-actions | 54657 | 2375 | 90ms | 0 | — |
| login | 1370 | 60 | 260ms | 0 | 16 |

Quarkus wrk 的业务读几乎没有 Non-2xx，这点和 Spring 高并发大量 4xx 不同。驾驶员混合与登录的 timeout 说明连接预算或慢请求仍在，但 HTTP 状态是干净的。
