@echo off
echo Starting Ollama with DeepSeek-R1 in background... > "%CD%\ollama_deepseek-r1.log" 2>&1

REM 检查 Ollama 是否已安装
where ollama >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Ollama is not installed or not found in PATH. >> "%CD%\ollama_deepseek-r1.log" 2>&1
    echo Please download and install Ollama from https://ollama.com/ >> "%CD%\ollama_deepseek-r1.log" 2>&1
    exit /b 1
)

REM 在后台静默启动 Ollama 并运行 DeepSeek-R1，输出重定向到日志文件
start /B "" ollama run deepseek-r1 >> "%CD%\ollama_deepseek-r1.log" 2>&1

REM 等待几秒确保 Ollama 启动（可选，调整延迟时间）
timeout /T 5 /nobreak >nul

REM 检查日志文件是否存在错误
findstr /i "error" "%CD%\ollama_deepseek-r1.log" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Warning: Ollama log contains errors. Check ollama_deepseek-r1.log for details. >> "%CD%\ollama_deepseek-r1.log" 2>&1
    exit /b 1
)

echo Ollama with DeepSeek-R1 started successfully in background. Check ollama_deepseek-r1.log for details. >> "%CD%\ollama_deepseek-r1.log" 2>&1
exit /b 0