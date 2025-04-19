@echo off
setlocal EnableDelayedExpansion

REM 设置工作目录和日志文件
set "WORK_DIR=%CD%"
set "LOG_FILE=%WORK_DIR%\ollama_deepseek-r1.log"
set "MODEL_NAME=deepseek-for-hgl-bishe"
set "HUGGINGFACE_REPO=4513P/deepseek-for-my-bishe"
set "GGUF_FILE=deepseek_r1_for_hgl_bishe.gguf"
set "MODELFILE=Modelfile"

echo Starting Ollama setup for DeepSeek-R1... > "%LOG_FILE%" 2>&1

REM 检查 Ollama 是否已安装
where ollama >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Ollama is not installed or not found in PATH. >> "%LOG_FILE%" 2>&1
    echo Please download and install Ollama from https://ollama.com/ >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 PowerShell 是否可用（用于下载文件）
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is not available. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 ollama list 是否已有模型
echo Checking if model %MODEL_NAME% exists in ollama list... >> "%LOG_FILE%" 2>&1
ollama list | findstr /i "%MODEL_NAME%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Model %MODEL_NAME% already exists. Skipping download and build. >> "%LOG_FILE%" 2>&1
    goto :run_model
)

REM 下载 GGUF 文件从 Hugging Face
echo Downloading %GGUF_FILE% from Hugging Face... >> "%LOG_FILE%" 2>&1
powershell -Command "Invoke-WebRequest -Uri 'https://huggingface.co/%HUGGINGFACE_REPO%/resolve/main/%GGUF_FILE%' -OutFile '%WORK_DIR%\%GGUF_FILE%'" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to download %GGUF_FILE%. Check network or Hugging Face repository. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 GGUF 文件是否存在
if not exist "%WORK_DIR%\%GGUF_FILE%" (
    echo Error: %GGUF_FILE% not found after download. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 下载 Modelfile 从 Hugging Face
echo Downloading %MODELFILE% from Hugging Face... >> "%LOG_FILE%" 2>&1
powershell -Command "Invoke-WebRequest -Uri 'https://huggingface.co/%HUGGINGFACE_REPO%/resolve/main/%MODELFILE%' -OutFile '%WORK_DIR%\%MODELFILE%'" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to download %MODELFILE%. Check network or Hugging Face repository. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 检查 Modelfile 是否存在
if not exist "%WORK_DIR%\%MODELFILE%" (
    echo Error: %MODELFILE% not found after download. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

REM 构建 Ollama 模型
echo Building Ollama model %MODEL_NAME%... >> "%LOG_FILE%" 2>&1
ollama create %MODEL_NAME% -f "%WORK_DIR%\%MODELFILE%" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create Ollama model %MODEL_NAME%. Check %MODELFILE% or logs. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

:run_model
REM 在后台启动 Ollama 并运行模型
echo Starting Ollama with %MODEL_NAME% in background... >> "%LOG_FILE%" 2>&1
start /B "" ollama run %MODEL_NAME% >> "%LOG_FILE%" 2>&1

REM 等待几秒确保 Ollama 启动
timeout /T 5 /nobreak >nul

REM 检查日志文件是否存在错误
findstr /i "error" "%LOG_FILE%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Warning: Ollama log contains errors. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
    exit /b 1
)

echo Ollama with %MODEL_NAME% started successfully in background. Check %LOG_FILE% for details. >> "%LOG_FILE%" 2>&1
exit /b 0