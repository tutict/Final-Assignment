# Go RAG live environment

This environment runs the live dependencies required by the go-zero RAG admin service:

- MySQL 8.4 on `127.0.0.1:3307`
- Elasticsearch 8.12.2 on `127.0.0.1:9201`

Start it from this directory:

```powershell
docker compose up -d
```

Run the go-zero API against the live config from the module root:

```powershell
go run ./project/cmd/gozeroapi -f project/etc/gozero-rag-live.yaml
```

Useful smoke checks:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8081/api/rag/admin/overview
Invoke-WebRequest -UseBasicParsing -Method POST http://127.0.0.1:8081/api/rag/admin/backfill
Invoke-WebRequest -UseBasicParsing -Method POST http://127.0.0.1:8081/api/rag/admin/embedding/run
Invoke-WebRequest -UseBasicParsing -Method POST http://127.0.0.1:8081/api/rag/query -ContentType 'application/json' -Body '{"query":"illegal parking appeal","topK":5,"roles":["admin"]}'
```

The default live config uses deterministic embeddings, so Ollama is not required for this dependency stack.
