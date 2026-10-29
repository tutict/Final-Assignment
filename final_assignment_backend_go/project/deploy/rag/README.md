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
Invoke-WebRequest -UseBasicParsing -Method POST http://127.0.0.1:8081/api/rag/query -ContentType 'application/json' -Body '{"query":"illegal parking appeal","topK":5}'
```

The live stack keeps deterministic embeddings, so Ollama is not required for this dependency stack.
Its alias (`rag_chunk_go_live_current`) is namespaced on purpose: the shared cluster's
`rag_chunk_current` alias belongs to the Spring pressure-test index, and reusing it would let
the two backends overwrite each other's vectors.

This scaffold has no JWT middleware, so retrieval runs as an anonymous principal and only PUBLIC
documents are visible. Run `cmd/app` instead when a role-scoped answer has to be verified.
