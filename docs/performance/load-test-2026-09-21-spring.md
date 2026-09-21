# 2026-09-21 k6 / wrk Spring Boot 单体压测报告

## 结论摘要

- 全 API 混合压测通过：`http_req_failed_rate=0.000`，`checks_rate=1.000`，驾驶员 / 管理员 / 超管读全部 1.000，p95 **56ms**。
- AI/RAG 分段：AI actions、RAG 检索、RAG 管理、帮办循环均为 1.000。USER 访问 RAG 管理的 **403 对齐为 0**（驾驶员未按契约被拒绝）。
- wrk 高并发读出现大量 Non-2xx（限流 / 鉴权混合），`rag-query` 无 Non-2xx，吞吐 34 req/s、平均延迟 231ms。
- 登录 wrk 几乎全是 Non-2xx，属于登录限流预期，不作为业务可用性失败。

## 测试环境

| 项目 | 配置 |
| --- | --- |
| 日期 | 2026-09-21 |
| 后端 | Spring Boot 单体 `finalAssignmentBackend`，`http://127.0.0.1:8080` |
| 压测入口 | `scripts/performance/run-load-tests.ps1 -Backend spring -Duration 20s` |
| 原始输出 | `artifacts/performance/2026-09-21/spring/` |

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Backend spring -Duration 20s -DriverVus 8 -AdminVus 6 -SuperVus 2 -LoginRate 1
```

## k6 全 API 混合压测

| 指标 | 结果 |
| --- | ---: |
| 请求数 | 3893（约 91 req/s） |
| HTTP 失败率 | 0.000 |
| checks | 1.000 |
| 平均 / p95 / p99 | 33.7ms / **56.0ms** / 72.3ms |
| health_ok | 1.000 |
| user_read_ok | 1.000 |
| admin_read_ok | 1.000 |
| super_read_ok | 1.000 |

与 [2026-06-01 单体](load-test-2026-06-01.md) 同量级（当时 p95 51ms、3893 请求）。

## k6 AI/RAG 分段压测

| 链路 | 成功率 | 平均 | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| AI HTTP 编排 | 1.000 | 15.3ms | 22.1ms | 24.2ms |
| RAG 检索 | 1.000 | 92.7ms | 123.0ms | 291.9ms |
| RAG 管理 | 1.000 | 16.1ms | 30.5ms | 34.9ms |
| USER RAG 管理 403 | **0.000** | — | — | — |
| 帮办循环 | 1.000 | 142.9ms | 172.9ms | 313.1ms |

AI stream 返回成功率 1.000，但摘要里「Ollama 真实调用」为 0.000，本轮帮办更像走了非模型/短路路径，延迟远低于 Cloud 调 llama3.2 的编排。

## wrk（20s）

| 场景 | 请求 | req/s | 平均延迟 | Non-2xx |
| --- | ---: | ---: | ---: | ---: |
| driver-read-mix | 6792 | 338 | 99ms | 5777 |
| admin-read-mix | 8839 | 439 | 109ms | 8753 |
| super-read-mix | 7410 | 370 | 86ms | 5572 |
| rag-query | 691 | 34 | 231ms | 0 |
| rag-admin-preview | 10344 | 516 | 16ms | 6020 |
| ai-actions | 10013 | 497 | 16ms | 8238 |
| login | 23314 | 1164 | 45ms | 23274 |

driver-read-mix 日志里夹了一句本机临时缺 `williamyeh/wrk` 镜像，后续场景已跑出完整 wrk 统计。
