# AI Chat Service - Deployment Guide

## 概述

AI Chat Service 是一个基于 Go 的智能对话服务，支持 RAG（检索增强生成）、Web 搜索和角色权限控制。

## 功能特性

- ✅ **流式对话** - Server-Sent Events (SSE) 实时推送
- ✅ **RAG 增强** - 自动检索业务知识库
- ✅ **Web 搜索** - Baidu 搜索集成（带缓存）
- ✅ **角色权限** - 基于角色的 AI 行为控制
- ✅ **多 Provider 支持** - OpenAI、Claude、本地模型
- ✅ **动态策略** - 从 Markdown 文件加载角色策略

## 快速开始

### 1. 环境准备

```bash
# 安装 Go 1.24+
go version

# 克隆项目
cd final_assignment_backend_go

# 安装依赖
go mod download
```

### 2. 配置

复制示例配置文件：

```bash
cp .env.example .env
```

编辑 `.env` 文件，配置 AI Provider：

```bash
# OpenAI 配置
AI_PROVIDER_TYPE=openai
AI_PROVIDER_API_KEY=sk-xxxxx
AI_PROVIDER_MODEL=gpt-4

# 或使用本地模型（Ollama）
AI_PROVIDER_TYPE=local
AI_PROVIDER_URL=http://localhost:11434/v1
AI_PROVIDER_MODEL=llama2
```

### 3. 创建角色约束文件

在 `./constraints` 目录创建角色策略文件：

```bash
mkdir -p constraints
```

**constraints/driver.md**:
```markdown
# Driver Role Constraints

You are an AI assistant for drivers in a traffic management system.

## Permissions
- View own violation records only
- Query own payment status
- Ask questions about traffic rules

## Restrictions
- Cannot access other users' data
- Cannot modify any records
- Cannot perform administrative operations

## Response Guidelines
- Be helpful and polite
- Provide accurate traffic law information
- Guide users through self-service processes
```

**constraints/admin.md**:
```markdown
# Admin Role Constraints

You are an AI assistant for administrators in a traffic management system.

## Permissions
- View all violations in assigned department
- Manage user accounts
- Generate reports

## Restrictions
- Cannot access data outside assigned department
- Cannot modify system-wide settings

## Response Guidelines
- Provide clear administrative guidance
- Include relevant data and statistics
- Maintain professional tone
```

### 4. 运行服务

```bash
# 开发模式
go run cmd/server/main.go

# 或构建并运行
go build -o ai-chat-server cmd/server/main.go
./ai-chat-server
```

服务将在 `http://localhost:8081` 启动。

### 5. 测试 API

```bash
curl -X POST http://localhost:8081/api/ai/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "message": "交通违章如何处理？",
    "sessionKey": "session-123",
    "metadata": {
      "ragEnabled": true,
      "topK": 5,
      "userId": "user123",
      "roles": ["DRIVER"]
    }
  }'
```

响应（SSE 格式）：
```
data: {"sessionKey":"session-123","timestamp":"2026-06-21T..."}

data: {"type":"token","token":"根据","timestamp":"..."}

data: {"type":"done","timestamp":"..."}
```

## 配置说明

### 必需配置

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `AI_PROVIDER_TYPE` | AI 提供商类型 | `openai`, `claude`, `local` |
| `AI_PROVIDER_API_KEY` | API 密钥（非本地模型） | `sk-xxxxx` |
| `AI_PROVIDER_MODEL` | 模型名称 | `gpt-4`, `claude-3-opus` |

### 可选配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `RAG_ENABLED` | `true` | 启用 RAG 检索 |
| `RAG_TOP_K` | `10` | RAG 检索结果数 |
| `WEB_SEARCH_ENABLED` | `true` | 启用 Web 搜索 |
| `SERVER_PORT` | `8081` | HTTP 服务端口 |
| `AGENT_CONSTRAINTS_PATH` | `./constraints` | 角色策略文件路径 |

## 架构说明

```
project/
├── internal/
│   ├── ai/                    # AI 核心逻辑
│   │   ├── chat_pipeline.go   # 聊天管道编排
│   │   ├── prompt_assembler.go # Prompt 组装
│   │   ├── web_search_service.go # Web 搜索
│   │   ├── agent_constraints_loader.go # 策略加载
│   │   └── role_resolver.go   # 角色解析
│   ├── config/                # 配置管理
│   ├── handler/               # HTTP 处理器
│   ├── provider/              # AI Provider 实现
│   │   ├── openai_provider.go
│   │   └── factory.go
│   └── service/               # 业务服务接口
└── cmd/
    └── server/
        └── main.go            # 入口文件
```

## Provider 配置示例

### OpenAI

```bash
AI_PROVIDER_TYPE=openai
AI_PROVIDER_API_KEY=sk-proj-xxxxx
AI_PROVIDER_MODEL=gpt-4-turbo-preview
```

### Claude (通过 Anthropic API)

```bash
AI_PROVIDER_TYPE=claude
AI_PROVIDER_API_KEY=sk-ant-xxxxx
AI_PROVIDER_MODEL=claude-3-opus-20240229
AI_PROVIDER_URL=https://api.anthropic.com/v1
```

### 本地模型（Ollama）

首先启动 Ollama：
```bash
ollama serve
ollama pull llama2
```

然后配置：
```bash
AI_PROVIDER_TYPE=local
AI_PROVIDER_MODEL=llama2
AI_PROVIDER_URL=http://localhost:11434/v1
```

## 测试

运行所有测试：
```bash
go test ./project/internal/... -v
```

查看测试覆盖率：
```bash
go test ./project/internal/... -cover
```

## 部署

### Docker 部署

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o ai-chat-server cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/ai-chat-server .
COPY --from=builder /app/constraints ./constraints

EXPOSE 8081
CMD ["./ai-chat-server"]
```

构建并运行：
```bash
docker build -t ai-chat-service .
docker run -p 8081:8081 --env-file .env ai-chat-service
```

### 生产环境建议

1. **安全性**
   - 使用 HTTPS
   - API Key 通过环境变量或密钥管理服务注入
   - 启用请求限流

2. **性能**
   - 启用缓存（`CACHE_ENABLED=true`）
   - 调整 RAG Token Budget
   - 配置合理的超时时间

3. **监控**
   - 记录请求日志
   - 监控 AI Provider 响应时间
   - 追踪错误率和缓存命中率

## API 文档

### POST /api/ai/chat/stream

流式 AI 对话接口。

**请求体**:
```json
{
  "message": "用户消息",
  "sessionKey": "会话标识",
  "metadata": {
    "ragEnabled": true,
    "topK": 5,
    "userId": "用户ID",
    "roles": ["DRIVER"],
    "temperature": 0.7,
    "maxTokens": 2000
  }
}
```

**响应**: Server-Sent Events (SSE)

```
data: {"type":"session","sessionKey":"...","timestamp":"..."}

data: {"type":"token","token":"文本片段","timestamp":"..."}

data: {"type":"done","timestamp":"..."}
```

**事件类型**:
- `session` - 会话初始化
- `token` - 文本 token
- `done` - 流式结束
- `error` - 错误信息

## 故障排查

### 常见问题

**Q: 服务启动失败**
```
A: 检查配置文件是否正确，特别是 AI_PROVIDER_API_KEY
```

**Q: RAG 检索无结果**
```
A: 确认 RAG 服务已启动，检查 RAG_ENABLED 配置
```

**Q: Web 搜索失败**
```
A: Baidu 可能触发反爬虫，可以调整 WEB_SEARCH_CACHE_TTL 增加缓存时间
```

**Q: 角色约束不生效**
```
A: 检查 constraints/ 目录下的 .md 文件是否存在且格式正确
```

## 开发

### 添加新的 AI Provider

1. 在 `internal/provider/` 创建新文件
2. 实现 `service.AiProvider` 接口
3. 在 `factory.go` 中注册

### 添加新角色

1. 在 `constraints/` 创建新的 .md 文件
2. 定义角色权限和约束
3. 在 `role_resolver.go` 中添加角色优先级

## 许可证

本项目遵循 MIT 许可证。

## 支持

如有问题，请提交 Issue 或联系开发团队。
