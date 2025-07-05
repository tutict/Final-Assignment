@echo off
setlocal EnableDelayedExpansion

REM 设置工作目录和日志文件
set "WORK_DIR=%CD%"
set "LOG_FILE=%WORK_DIR%\docker_desktop_service.log"
set "DOCKER_DESKTOP_PATH=C:\Program Files\Docker\Docker\Docker Desktop.exe"

echo Starting Docker Desktop setup... > "%LOG_FILE%" 2>&1

REM 检查 Docker Desktop 是否已安装
if not exist "%DOCKER_DESKTOP_PATH%" (
    echo Error: Docker Desktop is not installed at %DOCKER_DESKTOP_PATH%. >> "%LOG_FILE%" 2>&1
    echo Please download and install Docker Desktop from https://www.docker.com/products/docker-desktop/ >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 Docker 服务是否已在运行
docker info >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Docker Desktop is already running. >> "%LOG_FILE%" 2>&1
    exit /b 0
)

REM 在后台启动 Docker Desktop
echo Starting Docker Desktop in background... >> "%LOG_FILE%" 2>&1
start /B "" "%DOCKER_DESKTOP_PATH%" >> "%LOG_FILE%" 2>&1

REM 等待 Docker 服务启动
timeout /T 10 /nobreak >nul

REM 检查 Docker 服务是否启动成功
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Warning: Docker Desktop failed to start. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

echo Docker Desktop started successfully in background. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
exit /b 0