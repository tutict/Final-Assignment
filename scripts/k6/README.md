# k6 压测脚本

## AI/RAG 分段压测

`ai-rag-staged-load.js` 将 AI 链路拆成三段观测：

- AI HTTP 编排：`GET /api/ai/chat/actions`
- RAG 检索：`POST /api/rag/query`
- 模型生成：`POST /api/ai/chat/stream`，默认关闭，避免本地 Ollama 被压满

常用命令：

```powershell
k6 run scripts/k6/ai-rag-staged-load.js
```

启用模型生成阶段：

```powershell
$env:PERF_INCLUDE_MODEL="true"
k6 run scripts/k6/ai-rag-staged-load.js
```
