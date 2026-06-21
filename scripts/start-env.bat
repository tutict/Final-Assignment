@echo off
setlocal EnableExtensions EnableDelayedExpansion

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

call :init_logging
call :log "Environment startup log directory: %STARTUP_LOG_DIR%"

if /i not "%START_DOCKER%"=="false" call :start_docker
if errorlevel 1 exit /b 1

if /i not "%START_OLLAMA%"=="false" call :start_ollama
if errorlevel 1 exit /b 1

call :log "Local environment is ready."
exit /b 0

:init_logging
if "%STARTUP_LOG_DIR%"=="" (
  for %%I in ("%SCRIPT_DIR%..\artifacts\startup") do set "STARTUP_LOG_ROOT=%%~fI"
  if "%STARTUP_RUN_ID%"=="" (
    for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd-HHmmss" 2^>nul') do set "STARTUP_RUN_ID=%%I"
  )
  if "%STARTUP_RUN_ID%"=="" set "STARTUP_RUN_ID=run-%RANDOM%"
  set "STARTUP_LOG_DIR=!STARTUP_LOG_ROOT!\!STARTUP_RUN_ID!"
)
if not exist "%STARTUP_LOG_DIR%" mkdir "%STARTUP_LOG_DIR%" >nul 2>nul
set "ENV_LOG=%STARTUP_LOG_DIR%\environment.log"
set "DOCKER_INFO_LOG=%STARTUP_LOG_DIR%\docker-info.log"
set "DOCKER_COMPOSE_LOG=%STARTUP_LOG_DIR%\docker-compose.log"
set "DOCKER_COMPOSE_PS_LOG=%STARTUP_LOG_DIR%\docker-compose-ps.log"
set "OLLAMA_LOG=%STARTUP_LOG_DIR%\ollama.log"
set "OLLAMA_ERR_LOG=%STARTUP_LOG_DIR%\ollama.err.log"
set "OLLAMA_HEALTH_LOG=%STARTUP_LOG_DIR%\ollama-health.log"
set "OLLAMA_PID_FILE=%STARTUP_LOG_DIR%\ollama.pid"
(
  echo Environment startup
  echo Started at: %STARTUP_RUN_ID% %TIME%
  echo COMPOSE_FILE=%COMPOSE_FILE%
  echo START_DOCKER=%START_DOCKER%
  echo START_OLLAMA=%START_OLLAMA%
  echo DOCKER_WAIT_SECONDS=%DOCKER_WAIT_SECONDS%
  echo OLLAMA_WAIT_SECONDS=%OLLAMA_WAIT_SECONDS%
) > "%ENV_LOG%"
exit /b 0

:log
echo %~1
>> "%ENV_LOG%" echo [%STARTUP_RUN_ID% %TIME%] %~1
exit /b 0

:sleep
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds %~1" >nul 2>nul
exit /b 0

:check_http
where curl.exe >nul 2>nul
if not errorlevel 1 (
  curl.exe -fsS --max-time 2 %~1 > "%OLLAMA_HEALTH_LOG%" 2>&1
  exit /b %ERRORLEVEL%
)
where curl >nul 2>nul
if not errorlevel 1 (
  curl -fsS --max-time 2 %~1 > "%OLLAMA_HEALTH_LOG%" 2>&1
  exit /b %ERRORLEVEL%
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing %~1 -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" > "%OLLAMA_HEALTH_LOG%" 2>&1
exit /b %ERRORLEVEL%

:print_file_tail
echo.
echo ----- %~1 (last %~2 lines) -----
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path -LiteralPath '%~1') { Get-Content -LiteralPath '%~1' -Tail %~2 } else { Write-Host '[missing] %~1' }" 2>nul
echo ----- end %~1 -----
exit /b 0

:env_fail
echo.
echo [ERROR] %~1
>> "%ENV_LOG%" echo [%STARTUP_RUN_ID% %TIME%] [ERROR] %~1
echo Environment log directory: %STARTUP_LOG_DIR%
call :print_file_tail "%ENV_LOG%" 80
call :print_file_tail "%DOCKER_INFO_LOG%" 80
call :print_file_tail "%DOCKER_COMPOSE_LOG%" 160
call :print_file_tail "%DOCKER_COMPOSE_PS_LOG%" 120
call :print_file_tail "%OLLAMA_LOG%" 120
call :print_file_tail "%OLLAMA_ERR_LOG%" 120
call :print_file_tail "%OLLAMA_HEALTH_LOG%" 80
exit /b 1

:start_docker
if not exist "%COMPOSE_FILE%" (
  call :env_fail "Docker compose file not found: %COMPOSE_FILE%"
  exit /b 1
)

where docker >nul 2>nul
if errorlevel 1 (
  call :env_fail "Docker CLI was not found in PATH."
  exit /b 1
)

docker info > "%DOCKER_INFO_LOG%" 2>&1
if errorlevel 1 (
  call :log "Docker daemon is not ready. Starting Docker Desktop..."
  if not exist "%DOCKER_DESKTOP_PATH%" (
    call :env_fail "Docker Desktop executable not found: %DOCKER_DESKTOP_PATH%"
    exit /b 1
  )
  start "" "%DOCKER_DESKTOP_PATH%"
)

set /a DOCKER_WAIT_ELAPSED=0
:docker_wait_loop
docker info > "%DOCKER_INFO_LOG%" 2>&1
if not errorlevel 1 goto docker_ready
set /a DOCKER_WAIT_ELAPSED+=1
if %DOCKER_WAIT_ELAPSED% geq %DOCKER_WAIT_SECONDS% (
  call :env_fail "Docker daemon did not become ready in %DOCKER_WAIT_SECONDS% seconds."
  exit /b 1
)
call :sleep 1
goto docker_wait_loop

:docker_ready
call :log "Starting Docker services from %COMPOSE_FILE%..."
docker compose -f "%COMPOSE_FILE%" up -d --remove-orphans --wait --wait-timeout %DOCKER_WAIT_SECONDS% > "%DOCKER_COMPOSE_LOG%" 2>&1
set "COMPOSE_EXIT=%ERRORLEVEL%"
docker compose -f "%COMPOSE_FILE%" ps > "%DOCKER_COMPOSE_PS_LOG%" 2>&1
if not "%COMPOSE_EXIT%"=="0" (
  call :print_file_tail "%DOCKER_COMPOSE_LOG%" 160
  call :print_file_tail "%DOCKER_COMPOSE_PS_LOG%" 120
  call :env_fail "Docker compose startup failed with exit code %COMPOSE_EXIT%."
  exit /b %COMPOSE_EXIT%
)
call :log "Docker services are ready. Log: %DOCKER_COMPOSE_LOG%"
exit /b 0

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
  call :env_fail "Ollama executable was not found: %OLLAMA_EXE%. Set START_OLLAMA=false to skip Ollama startup."
  exit /b 1
)

call :check_http http://127.0.0.1:11434/api/tags
if not errorlevel 1 (
  call :log "Ollama is already reachable."
  exit /b 0
)

call :log "Starting Ollama service..."
set "OLLAMA_CMD_PATH=%OLLAMA_CMD%"
for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath $env:OLLAMA_CMD_PATH -ArgumentList 'serve' -RedirectStandardOutput $env:OLLAMA_LOG -RedirectStandardError $env:OLLAMA_ERR_LOG -WindowStyle Hidden -PassThru; $p.Id" 2^>nul') do set "OLLAMA_PID=%%I"
if not defined OLLAMA_PID (
  call :env_fail "Failed to start Ollama process."
  exit /b 1
)
> "%OLLAMA_PID_FILE%" echo %OLLAMA_PID%

set /a OLLAMA_WAIT_ELAPSED=0
:ollama_wait_loop
call :check_http http://127.0.0.1:11434/api/tags
if not errorlevel 1 goto ollama_ready
set /a OLLAMA_WAIT_ELAPSED+=1
if %OLLAMA_WAIT_ELAPSED% geq %OLLAMA_WAIT_SECONDS% (
  call :print_file_tail "%OLLAMA_LOG%" 120
  call :print_file_tail "%OLLAMA_ERR_LOG%" 120
  call :print_file_tail "%OLLAMA_HEALTH_LOG%" 80
  call :env_fail "Ollama did not become reachable in %OLLAMA_WAIT_SECONDS% seconds."
  exit /b 1
)
call :sleep 1
goto ollama_wait_loop

:ollama_ready
call :log "Ollama is ready. Log: %OLLAMA_LOG%"
exit /b 0

:usage
echo Usage: scripts\start-env.bat
echo.
echo Starts local Docker services and Ollama.
echo.
echo Optional environment variables:
echo   START_DOCKER=false       Skip Docker compose services.
echo   START_OLLAMA=false       Skip Ollama.
echo   STARTUP_LOG_DIR          Existing run log directory from start-dev.bat.
echo   DOCKER_DESKTOP_PATH      Docker Desktop executable path.
echo   DOCKER_WAIT_SECONDS      Docker readiness timeout. Default: 180
echo   OLLAMA_EXE               Ollama executable or absolute path. Default: ollama
echo   OLLAMA_WAIT_SECONDS      Ollama readiness timeout. Default: 60
exit /b 0
