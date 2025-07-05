@echo off
setlocal EnableDelayedExpansion

REM 设置工作目录和日志文件
set "WORK_DIR=%CD%"
set "LOG_FILE=%WORK_DIR%\ollama_service.log"

echo Starting Ollama service... > "%LOG_FILE%" 2>&1

REM 检查 Ollama 是否已安装
where ollama >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Ollama is not installed or not found in PATH. >> "%LOG_FILE%" 2>&1
    echo Please download and install Ollama from https://ollama.com/ >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 Ollama 服务是否已在运行
ollama serve >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Ollama service is already running. >> "%LOG_FILE%" 2>&1
    exit /b 0
)

REM 在后台启动 Ollama 服务
echo Starting Ollama service in background... >> "%LOG_FILE%" 2>&1
start /B "" ollama serve >> "%LOG_FILE%" 2>&1

REM 等待几秒确保 Ollama 服务启动
timeout /T 5 /nobreak >nul

REM 检查日志文件是否存在错误
findstr /i "error" "%LOG_FILE%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Warning: Ollama log contains errors. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

echo Ollama service started successfully in background. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
exit /b 0