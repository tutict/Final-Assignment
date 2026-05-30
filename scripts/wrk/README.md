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

## 非 2xx 端点统计

`read-mix.lua` 和 `super-read-mix.lua` 会在 wrk 结束时额外输出 `Non-2xx responses by endpoint`，用于定位管理员/超级管理员混合读中的失败端点。该统计基于 wrk Lua 回调记录，适合本地压测排查；如需严格审计，仍应结合后端访问日志和 `endpoint` 标签指标。
