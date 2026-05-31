# Development Startup Scripts

Run these scripts from the repository root.

## Main Startup

Windows:

```bat
scripts\start-all.bat
```

Linux / macOS:

```sh
sh scripts/start-all.sh
```

The full startup flow attempts to start:

1. Docker Desktop or the local Docker service
2. Local services from `scripts\dev-compose.yml`
3. Ollama
4. Spring Boot backend from `finalAssignmentBackend`
5. Flutter web frontend at `http://127.0.0.1:3000`

The backend uses the local MySQL database by default:

```text
jdbc:mysql://localhost:3306/traffic
```

## Common Options

Skip Docker/Ollama and only start backend + frontend:

```bat
set START_LOCAL_SERVICES=false
scripts\start-all.bat
```

```sh
START_LOCAL_SERVICES=false sh scripts/start-all.sh
```

Skip only Ollama:

```bat
set START_OLLAMA=false
scripts\start-all.bat
```

```sh
START_OLLAMA=false sh scripts/start-all.sh
```

Use a Flutter installation outside `PATH`:

```bat
set FLUTTER_CMD=C:\Users\tutic\Flutter\flutter\bin\flutter.bat
scripts\start-all.bat
```

Use a different MySQL password:

```bat
set DB_PASSWORD=your_password
scripts\start-all.bat
```

Enable sensitive data encryption and blind-index generation:

```bat
set SENSITIVE_DATA_ENCRYPTION_ENABLED=true
set SENSITIVE_DATA_ENCRYPTION_KEY=your_32_byte_base64_or_strong_secret
set SENSITIVE_DATA_BLIND_INDEX_KEY=another_32_byte_base64_or_strong_secret
scripts\start-all.bat
```

Use Ollama for RAG embeddings:

```bat
set RAG_EMBEDDING_ENABLED=true
set RAG_EMBEDDING_PROVIDER=ollama
set RAG_EMBEDDING_MODEL=nomic-embed-text
set RAG_EMBEDDING_DIMENSIONS=768
scripts\start-all.bat
```

The Ollama model must exist locally before the backend can turn `rag_chunk` rows into vectors:

```powershell
ollama pull nomic-embed-text
```

## Local Infrastructure

`scripts\dev-compose.yml` contains:

- Redis
- Redpanda
- Elasticsearch 9.4.1
- Debezium Connect

The default Elasticsearch image is Elastic GA 9.4.1. The backend still uses the Spring Boot managed `elasticsearch-java 9.2.2` client, which can connect to newer 9.x minor server versions; upgrade the client separately only when 9.4-specific typed APIs are needed. Override the image with `ELASTICSEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:<version>` when testing another Elasticsearch server.

RAG vector documents are written to the Elasticsearch `rag_chunk_current` alias after `rag_embedding_task` rows are consumed. The local default uses Ollama `nomic-embed-text` with 768 dimensions; change `RAG_EMBEDDING_MODEL` and `RAG_EMBEDDING_DIMENSIONS` together when switching models.

Start only the infrastructure:

```powershell
docker compose -f scripts\dev-compose.yml up -d
```

Reset only the local Redpanda data volume after an incompatible Redpanda image
upgrade, for example when the container fails with `Attempted to upgrade from
incompatible logical version ...`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\reset-redpanda-dev-data.ps1
```

For non-interactive recovery:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\reset-redpanda-dev-data.ps1 -Force
```

This deletes only the local `final-assignment-dev_redpanda-data` Kafka log
volume and recreates Redpanda plus Debezium Connect. It does not delete MySQL,
Redis, or Elasticsearch data.

Start the Spring Boot backend only:

```bat
scripts\start-backend-dev.bat
```

## MySQL CDC Search Sync

The engineering-grade search path is:

```text
MySQL binlog -> Debezium Connect -> Redpanda -> Spring Boot CDC Consumer -> Elasticsearch
```

Start the required services and register the connector:

```powershell
docker compose -f scripts\dev-compose.yml up -d redpanda elasticsearch debezium-connect
$env:MYSQL_CDC_PASSWORD='your_cdc_password'
powershell -ExecutionPolicy Bypass -File scripts\debezium\register-mysql-cdc.ps1
```

Enable the backend consumer:

```bat
set CDC_ELASTICSEARCH_ENABLED=true
```

See the root `README.md` for MySQL binlog and CDC user setup.

## Smoke Tests

Run the local auth + AI stream chain test:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-ai-chain.ps1
```

This checks:

- frontend entry page
- frontend AI stream modules
- backend auth flow
- CORS preflight
- Ollama availability
- `/api/ai/chat/stream` SSE output

Use strict provider mode when the backend must call a real AI provider instead of the mock provider:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-ai-chain.ps1 -StrictProvider
```

## Load Tests

k6 and wrk load-test scripts live under `scripts\k6` and `scripts\wrk`.

Run the local all-round load-test orchestration:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-load-tests.ps1 `
  -Duration 20s `
  -DriverVus 8 `
  -AdminVus 6 `
  -SuperVus 2 `
  -LoginRate 0 `
  -IncludeModel
```

The report is maintained at `docs\performance\load-test-2026-05-30.md`. The generated raw outputs are written to `artifacts\k6` and `artifacts\wrk`; those directories are ignored by Git.

Run the Kafka/Redpanda Pandaproxy load-test orchestration:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\performance\run-kafka-load-tests.ps1 `
  -Duration 20s `
  -K6Rate 20 `
  -K6Vus 16 `
  -WrkConnections 32 `
  -BatchSize 10
```

This scenario writes to the dedicated `perf-kafka-http` topic through Redpanda
Pandaproxy. k6 and wrk are HTTP load-test tools, so the scripts measure Kafka
produce through Redpanda's HTTP proxy rather than raw Kafka protocol throughput.
