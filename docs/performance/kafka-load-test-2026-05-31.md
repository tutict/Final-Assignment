# 2026-05-31 Kafka / Redpanda k6 + wrk 专项压测报告

## 结论

本轮压测覆盖 Redpanda 的 Kafka 写入面，但工具路径是 Redpanda Pandaproxy HTTP API。原因是 wrk 只能压 HTTP，普通 k6 也没有内置 Kafka 协议客户端；因此本报告衡量的是“HTTP Pandaproxy -> Kafka topic”的写入能力，不等同于原生 Kafka producer 协议上限。

Redpanda 与 Debezium Connect 均保持 healthy。清洁压测前重建了专用 topic `perf-kafka-http`，没有触碰业务 topic、Debezium 内部 topic、MySQL、Redis 或 Elasticsearch 数据。

## 环境

| 项目 | 值 |
| --- | --- |
| Redpanda | `docker.redpanda.com/redpandadata/redpanda:v26.1.9` |
| Debezium Connect | `quay.io/debezium/connect:3.5.1.Final` |
| Kafka API | `localhost:9092` |
| Redpanda Admin API | `localhost:9644` |
| Pandaproxy | `localhost:8082` |
| 压测 topic | `perf-kafka-http` |
| topic 分区 | `6` |
| 批量大小 | `10 records/request` |
| 单条 payload | 约 `256 bytes` |

## 命令

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-kafka-load-tests.ps1 `
  -Duration 20s `
  -K6Rate 20 `
  -K6Vus 16 `
  -K6MaxVus 64 `
  -WrkThreads 4 `
  -WrkConnections 32 `
  -BatchSize 10 `
  -PayloadBytes 256 `
  -ResetTopic
```

该脚本会：

- 启动并等待 Redpanda / Debezium Connect healthy。
- 可选删除并重建专用压测 topic。
- 用 k6 以恒定到达率写入 Pandaproxy。
- 用 wrk 以固定连接数写入 Pandaproxy。
- 输出 topic 分区 high-watermark。

## k6 结果

| 指标 | 结果 |
| --- | ---: |
| 目标到达率 | `20 iterations/s` |
| 实际 iterations | `350` |
| HTTP 请求数 | `351` |
| produce 成功率 | `100.00%` |
| 写入 records | `3500` |
| records 吞吐 | `174.32 records/s` |
| 平均耗时 | `2.04 s` |
| p90 | `3.16 s` |
| p95 | `3.39 s` |
| 最大耗时 | `3.91 s` |
| dropped iterations | `50` |

k6 在 `20 iterations/s * 10 records/request` 的目标下触发 `Insufficient VUs, reached 64 active VUs`，说明本地 Pandaproxy 写入链路尾延迟偏高，导致恒定到达率场景需要更多并发 VU 才能完全追上目标速率。

## wrk 结果

| 指标 | 结果 |
| --- | ---: |
| 线程 / 连接 | `4 / 32` |
| 请求数 | `5920` |
| HTTP 2xx | `5920` |
| HTTP 4xx / 5xx | `0 / 0` |
| 估算 records 写入 | `59200` |
| 请求吞吐 | `260.02 req/s` |
| records 吞吐 | `2600.2 records/s` |
| 平均延迟 | `190.47 ms` |
| 最大延迟 | `1.79 s` |
| 传输吞吐 | `83.14 KB/s` |

wrk 压测期间所有 Pandaproxy produce 请求均为 2xx，未出现失败响应。

## Topic 校验

清洁压测后 `rpk topic describe perf-kafka-http -p`：

| 分区 | high-watermark |
| ---: | ---: |
| 0 | `10557` |
| 1 | `10790` |
| 2 | `10531` |
| 3 | `10257` |
| 4 | `10264` |
| 5 | `10621` |
| 合计 | `63020` |

high-watermark 合计与本轮 k6、wrk 发送量基本一致；wrk 统计窗口外的少量在途请求会造成高水位略高于 wrk 报告的 timed requests 估算值。

## 风险与下一步

1. 当前结果是 Pandaproxy HTTP 写入能力，不是原生 Kafka producer 协议峰值。若要测原生 Kafka，需要补充 `rpk topic produce` 基准或使用 `xk6-kafka` 构建专用 k6。
2. k6 场景暴露尾延迟明显，后续可单独对比 `BatchSize=1/10/50`、`--smp`、Redpanda memory、宿主机磁盘与 Docker Desktop 资源限制。
3. Debezium Connect 本轮只做健康检查，没有注册 MySQL CDC connector；如需测完整 CDC 链路，应另建“批量写 MySQL -> Debezium -> Redpanda -> 后端 CDC consumer -> Elasticsearch”的端到端场景。

## 产物

- [`scripts/performance/run-kafka-load-tests.ps1`](../../scripts/performance/run-kafka-load-tests.ps1)
- [`scripts/k6/kafka-pandaproxy-load.js`](../../scripts/k6/kafka-pandaproxy-load.js)
- [`scripts/wrk/kafka-pandaproxy-produce.lua`](../../scripts/wrk/kafka-pandaproxy-produce.lua)
- 原始输出：`artifacts/k6/kafka-pandaproxy-load.txt`、`artifacts/wrk/kafka-pandaproxy-produce.txt`，不纳入 Git。
