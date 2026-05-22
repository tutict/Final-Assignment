@echo off
setlocal EnableExtensions

if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage

set "SCRIPT_DIR=%~dp0"
set "COMPOSE_FILE=%SCRIPT_DIR%dev-compose.yml"

if "%START_DOCKER%"=="" set "START_DOCKER=true"
if "%START_OLLAMA%"=="" set "START_OLLAMA=true"
if "%DOCKER_WAIT_SECONDS%"=="" set "DOCKER_WAIT_SECONDS=180"
if "%OLLAMA_WAIT_SECONDS%"=="" set "OLLAMA_WAIT_SECONDS=60"
if "%DOCKER_DESKTOP_PATH%"=="" set "DOCKER_DESKTOP_PATH=C:\Program Files\Docker\Docker\Docker Desktop.exe"
if "%OLLAMA_EXE%"=="" set "OLLAMA_EXE=ollama"

if /i not "%START_DOCKER%"=="false" call :start_docker
if errorlevel 1 exit /b 1

if /i not "%START_OLLAMA%"=="false" call :start_ollama
if errorlevel 1 exit /b 1

echo Local environment is ready.
exit /b 0

:start_docker
if not exist "%COMPOSE_FILE%" (
  echo [ERROR] Docker compose file not found: "%COMPOSE_FILE%"
  exit /b 1
)

where docker >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Docker CLI was not found in PATH.
  exit /b 1
)

docker info >nul 2>nul
if errorlevel 1 (
  echo Docker daemon is not ready. Starting Docker Desktop...
  if not exist "%DOCKER_DESKTOP_PATH%" (
    echo [ERROR] Docker Desktop executable not found: "%DOCKER_DESKTOP_PATH%"
    exit /b 1
  )
  start "" "%DOCKER_DESKTOP_PATH%"
)

for /l %%i in (1,1,%DOCKER_WAIT_SECONDS%) do (
  docker info >nul 2>nul
  if not errorlevel 1 goto docker_ready
  timeout /t 1 /nobreak >nul
)

echo [ERROR] Docker daemon did not become ready in %DOCKER_WAIT_SECONDS% seconds.
exit /b 1

:docker_ready
echo Starting Docker services from "%COMPOSE_FILE%"...
docker compose -f "%COMPOSE_FILE%" up -d --wait --wait-timeout %DOCKER_WAIT_SECONDS%
exit /b %ERRORLEVEL%

:start_ollama
set "OLLAMA_CMD="
if exist "%OLLAMA_EXE%" set "OLLAMA_CMD=%OLLAMA_EXE%"
if not defined OLLAMA_CMD (
  for /f "delims=" %%I in ('where "%OLLAMA_EXE%" 2^>nul') do (
    set "OLLAMA_CMD=%%I"
    goto ollama_found
  )
)

:ollama_found
if not defined OLLAMA_CMD (
  echo [ERROR] Ollama executable was not found: %OLLAMA_EXE%
  echo Set START_OLLAMA=false to skip Ollama startup.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }"
if not errorlevel 1 (
  echo Ollama is already reachable.
  exit /b 0
)

echo Starting Ollama service...
start "" /B "%OLLAMA_CMD%" serve

for /l %%i in (1,1,%OLLAMA_WAIT_SECONDS%) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }"
  if not errorlevel 1 goto ollama_ready
  timeout /t 1 /nobreak >nul
)

echo [ERROR] Ollama did not become reachable in %OLLAMA_WAIT_SECONDS% seconds.
exit /b 1

:ollama_ready
echo Ollama is ready.
exit /b 0

:usage
echo Usage: scripts\start-env.bat
echo.
echo Starts local Docker services and Ollama.
echo.
echo Optional environment variables:
echo   START_DOCKER=false       Skip Docker compose services.
echo   START_OLLAMA=false       Skip Ollama.
echo   DOCKER_DESKTOP_PATH      Docker Desktop executable path.
echo   DOCKER_WAIT_SECONDS      Docker readiness timeout. Default: 180
echo   OLLAMA_EXE               Ollama executable or absolute path. Default: ollama
echo   OLLAMA_WAIT_SECONDS      Ollama readiness timeout. Default: 60
exit /b 0
