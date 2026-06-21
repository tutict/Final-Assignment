# wrk 压测脚本

这些 Lua 脚本用于配合本地 Docker 镜像 `williamyeh/wrk` 运行。Windows 下推荐从仓库根目录执行，并通过 `host.docker.internal` 访问本机后端。

## 登录基准

登录接口会触发 BCrypt 校验和登录限流，建议单独运行，并放在其他读接口压测之后，避免 IP 级登录窗口影响后续 token 获取。

```powershell
docker run --rm `
  -e PERF_USERNAME=admin `
  -e PERF_PASSWORD=Admin@123456 `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t4 -c16 -d20s `
  -s /scripts/login.lua `
  http://host.docker.internal:8080/api/auth/login
```

## 驾驶员读接口混合

```powershell
$env:PERF_TOKEN='<driver access token>'
$env:PERF_DRIVER_ID='6'
docker run --rm `
  -e PERF_TOKEN="$env:PERF_TOKEN" `
  -e PERF_DRIVER_ID="$env:PERF_DRIVER_ID" `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t4 -c32 -d20s `
  -s /scripts/driver-read-mix.lua `
  http://host.docker.internal:8080
```

## 管理员读接口混合

```powershell
$env:PERF_TOKEN='<admin access token>'
docker run --rm `
  -e PERF_TOKEN="$env:PERF_TOKEN" `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t4 -c48 -d20s `
  -s /scripts/read-mix.lua `
  http://host.docker.internal:8080
```

## 超级管理员读接口混合

```powershell
$env:PERF_TOKEN='<super admin access token>'
docker run --rm `
  -e PERF_TOKEN="$env:PERF_TOKEN" `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t4 -c32 -d20s `
  -s /scripts/super-read-mix.lua `
  http://host.docker.internal:8080
```

## RAG 检索

```powershell
$env:PERF_TOKEN='<admin access token>'
docker run --rm `
  -e PERF_TOKEN="$env:PERF_TOKEN" `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t2 -c8 -d20s `
  -s /scripts/rag-query.lua `
  http://host.docker.internal:8080/api/rag/query
```

## AI actions

```powershell
$env:PERF_TOKEN='<admin access token>'
docker run --rm `
  -e PERF_TOKEN="$env:PERF_TOKEN" `
  -v "${PWD}\scripts\wrk:/scripts:ro" `
  williamyeh/wrk -t2 -c8 -d20s `
  -s /scripts/ai-actions.lua `
  http://host.docker.internal:8080
```

## 端点级失败与超时候选统计

`read-mix.lua` 和 `super-read-mix.lua` 会在 wrk 结束时额外输出：

- `Endpoint request accounting`：按 endpoint 汇总发出数、完成数、missing/timeout 候选数和非 2xx 数。
- `Estimated timeout/write-error candidates by endpoint`：用“发出数 - 完成数”定位 wrk timeout/write error 的候选端点。
- `Non-2xx responses by endpoint`：按 endpoint 汇总已收到响应中的非 2xx。

wrk 的 Lua `response` 回调不会在超时请求上触发，所以 timeout 无法像 HTTP 状态码一样被直接归因；这里的 missing 统计用于快速定位尾延迟端点，最终结论仍应结合后端访问日志、慢查询日志和 `endpoint` 标签指标。
