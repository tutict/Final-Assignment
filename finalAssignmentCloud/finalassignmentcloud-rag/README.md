# finalassignmentcloud-rag

RAG is isolated as its own knowledge service instead of being embedded in the AI chat service.

## Boundary

- Owns RAG tables: `rag_document`, `rag_chunk`, `rag_embedding_task`.
- Owns document ingestion, chunking, embedding task scheduling, Elasticsearch vector index maintenance, and retrieval.
- Exposes query contract through `POST /api/rag/query`.
- Exposes super-admin management contract through `/api/rag/admin/**`.
- Does not directly read traffic, user, audit, or system service databases.

Business services should publish source documents through an explicit API or event contract. The current backfill endpoint is intentionally disabled by default because direct cross-database reads would violate the microservice boundary.

## Runtime Dependencies

- MySQL schema from `classpath:rag/rag_schema.sql`.
- Elasticsearch for hybrid BM25/vector retrieval.
- Ollama embedding endpoint when `rag.embedding.provider=ollama`.
- Nacos discovery/config consistent with the other Cloud services.

## AI Chat Integration

`finalassignmentcloud-ai` calls this service through OpenFeign service discovery with service id
`finalassignmentcloud-rag`. The AI service forwards the current `Authorization` header, so RAG keeps
ownership and role filtering inside the RAG boundary.

Required runtime switches:

- `AI_RAG_ENABLED=true` on `finalassignmentcloud-ai`.
- `RAG_RETRIEVAL_ENABLED=true` on `finalassignmentcloud-rag`.
- `AI_RAG_TOP_K` can override the AI-side default query size.
