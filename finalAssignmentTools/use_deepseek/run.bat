@echo off
echo Starting Ollama with DeepSeek-R1 in background...

REM 检查 Ollama 是否已安装
where ollama >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Ollama is not installed or not found in PATH.
    echo Please download and install Ollama from https://ollama.com/
    exit /b 1
)

REM 在后台启动 Ollama 并运行 DeepSeek-R1，输出重定向到文件
start "Ollama DeepSeek-R1" /B ollama run deepseek-r1 > "%CD%\ollama_deepseek-r1.log" 2>&1

echo Ollama with DeepSeek-R1 started in background. Check ollama_deepseek-r1.log for details.