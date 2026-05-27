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

## Local Infrastructure

`scripts\dev-compose.yml` contains:

- Redis
- Redpanda
- Elasticsearch
- Debezium Connect
- Manticore Search

Start only the infrastructure:

```powershell
docker compose -f scripts\dev-compose.yml up -d
```

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
