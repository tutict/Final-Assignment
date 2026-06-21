# AI Chat System - k6 压力测试使用指南

## 快速开始

### 1. 安装 k6

#### Windows
```powershell
# 使用 Chocolatey
choco install k6

# 或使用 Scoop
scoop install k6

# 或手动下载
# https://github.com/grafana/k6/releases
```

#### Linux/Mac
```bash
# Mac (Homebrew)
brew install k6

# Linux (Debian/Ubuntu)
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### 2. 启动 AI Chat 服务

```bash
# 1. 配置环境变量（使用 mock provider 进行纯性能测试）
cp .env.example .env

# 编辑 .env，使用以下配置进行压测：
# AI_PROVIDER_TYPE=local
# AI_PROVIDER_URL=http://localhost:11434/v1  # 或使用 mock
# RAG_ENABLED=false  # 可选：禁用 RAG 减少外部依赖
# WEB_SEARCH_ENABLED=false  # 可选：禁用搜索

# 2. 启动服务
go run cmd/server/main.go

# 3. 验证服务
curl http://localhost:8081/api/ai/chat/stream -X POST \
  -H "Content-Type: application/json" \
  -d '{"message":"test","sessionKey":"test"}'
```

### 3. 运行测试

#### 基础测试（2分钟）
```bash
cd k6
k6 run basic-test.js
```

#### 负载测试（18分钟）
```bash
k6 run load-test.js --out json=load-test-results.json
```

#### 压力测试（27分钟）
```bash
k6 run stress-test.js --out json=stress-test-results.json
```

#### 峰值测试（15分钟）
```bash
k6 run spike-test.js --out json=spike-test-results.json
```

## 测试脚本说明

### basic-test.js - 基础功能测试
**目的**: 验证系统基本功能和建立性能基线

**配置**:
- 虚拟用户: 10 VU
- 持续时间: 2分钟（30s 预热 + 1m 稳定 + 30s 冷却）
- 阈值: P95 < 1000ms, 错误率 < 10%

**适用场景**: 
- 首次压测，验证功能
- 快速性能检查
- CI/CD 集成

### load-test.js - 负载测试
**目的**: 模拟真实用户负载，验证系统稳定性

**配置**:
- 虚拟用户: 20 → 50 → 100 VU（渐进式）
- 持续时间: 18分钟
- 用户行为: 80% 司机 + 20% 管理员
- 阈值: P95 < 2000ms, P99 < 5000ms, 错误率 < 5%

**特点**:
- 模拟真实用户思考时间（2-7秒）
- 多种查询类型
- RAG 开关随机
- 详细的性能指标

### stress-test.js - 压力测试
**目的**: 找出系统性能极限和崩溃点

**配置**:
- 虚拟用户: 50 → 100 → 200 → 300 → 400 VU
- 持续时间: 27分钟
- 阈值: P95 < 5000ms, 错误率 < 20%

**观察点**:
- 首次出现错误的并发数
- 响应时间激增的临界点
- 资源耗尽点（CPU、内存、连接）

### spike-test.js - 峰值测试
**目的**: 测试系统应对突发流量的能力

**配置**:
- 虚拟用户: 10 → 200 VU（10秒内突增）
- 持续时间: 15分钟
- 阈值: P95 < 3000ms, 错误率 < 15%

**验证**:
- 突增时刻的表现
- 系统恢复能力
- 是否有永久性损坏

## 监控和分析

### 实时监控

#### 系统资源
```bash
# Windows: 任务管理器
# 查看 CPU、内存、网络

# Linux: htop
htop

# 或使用 top
top -p $(pgrep -f "ai-chat")
```

#### Go 应用指标
```bash
# 如果启用了 pprof
go tool pprof http://localhost:6060/debug/pprof/heap
go tool pprof http://localhost:6060/debug/pprof/goroutine
```

### 结果分析

#### 查看 k6 输出
```bash
# 基本统计
cat load-test-results.json | jq '.metrics.http_req_duration'

# 响应时间分析
cat load-test-results.json | jq '{
  avg: .metrics.http_req_duration.values.avg,
  min: .metrics.http_req_duration.values.min,
  max: .metrics.http_req_duration.values.max,
  p50: .metrics.http_req_duration.values.med,
  p95: .metrics.http_req_duration.values["p(95)"],
  p99: .metrics.http_req_duration.values["p(99)"]
}'

# 错误率
cat load-test-results.json | jq '.metrics.http_req_failed.values.rate'

# 吞吐量
cat load-test-results.json | jq '.metrics.http_reqs.values.rate'
```

#### 生成图表（可选）
```bash
# 使用 k6 Cloud 或 Grafana
k6 run load-test.js --out influxdb=http://localhost:8086/k6
```

## 预期性能指标

### 基础性能（单用户）
- 响应时间: 50-100ms (P95)
- 吞吐量: 10+ req/s
- 错误率: 0%

### 中等负载（50 VU）
- 响应时间: 100-500ms (P95)
- 吞吐量: 20-30 req/s
- 错误率: < 1%

### 高负载（100 VU）
- 响应时间: 500-2000ms (P95)
- 吞吐量: 30-50 req/s
- 错误率: < 5%

### 极限压力（200+ VU）
- 响应时间: 2000-5000ms (P95)
- 可能开始出现错误
- 资源接近饱和

## 故障排查

### 常见问题

#### 1. 连接被拒绝
```
Error: dial tcp: connection refused
```
**解决**: 确认服务已启动，端口正确

#### 2. 超时错误
```
Error: request timeout
```
**解决**: 增加超时时间或降低并发数

#### 3. 高错误率
**可能原因**:
- AI Provider 限流
- 数据库连接池耗尽
- 内存不足
- CPU 瓶颈

**排查步骤**:
1. 查看服务日志
2. 检查资源使用
3. 分析错误类型
4. 逐步降低负载

#### 4. 内存持续增长
**解决**:
```bash
# 使用 pprof 分析
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/heap
```

## 优化建议

### 服务端优化
1. **增加数据库连接池**
   ```go
   db.SetMaxOpenConns(100)
   db.SetMaxIdleConns(10)
   ```

2. **启用 HTTP 连接复用**
   ```go
   client.Transport = &http.Transport{
       MaxIdleConns: 100,
       MaxIdleConnsPerHost: 10,
   }
   ```

3. **调整 Goroutine 池大小**
4. **启用响应压缩**
5. **增加缓存**

### 系统优化
1. **增加文件描述符限制**
   ```bash
   ulimit -n 65536
   ```

2. **调整 TCP 参数**
3. **使用 SSD 存储**
4. **增加内存**

## 持续集成

### 在 CI/CD 中运行
```yaml
# .github/workflows/performance-test.yml
name: Performance Test
on: [push]
jobs:
  k6:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run k6 test
        uses: grafana/k6-action@v0.3.0
        with:
          filename: k6/basic-test.js
```

## 安全提示

⚠️ **警告**: 
- 切勿对生产环境进行压力测试
- 确认测试 URL 为 localhost 或测试环境
- 使用测试数据，不要使用真实用户数据
- 压测可能导致系统不可用

## 更多资源

- [k6 官方文档](https://k6.io/docs/)
- [k6 测试模式](https://k6.io/docs/test-types/)
- [性能测试最佳实践](https://k6.io/docs/testing-guides/)

---

**创建日期**: 2026-06-21  
**版本**: 1.0  
**维护者**: AI Chat 开发团队
