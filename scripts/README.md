# Development Startup Scripts

Use these scripts from the repository root.

## Windows

```bat
scripts\start-all.bat
```

This starts:

1. Docker Desktop and local Docker services from `scripts\dev-compose.yml`
2. Ollama
3. Spring Boot backend from `finalAssignmentBackend`
4. Flutter web frontend on `http://127.0.0.1:3000`

## Linux / macOS

```sh
sh scripts/start-all.sh
```

## Useful Options

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

Use a local Flutter installation that is not in `PATH`:

```bat
set FLUTTER_CMD=C:\Users\tutic\Flutter\flutter\bin\flutter.bat
scripts\start-all.bat
```

Use a different MySQL password:

```bat
set SPRING_DATASOURCE_PASSWORD=your_password
scripts\start-all.bat
```

The local MySQL database is expected at `jdbc:mysql://localhost:3306/traffic`.

## Smoke Tests

Run the local auth + AI stream chain test:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-ai-chain.ps1
```

This verifies the frontend entry page, frontend AI stream modules, backend auth flow,
CORS preflight, Ollama availability, and `/api/ai/chat/stream` SSE output.

Use strict provider mode when the backend must call a real AI provider instead of
the mock provider:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-ai-chain.ps1 -StrictProvider
```
