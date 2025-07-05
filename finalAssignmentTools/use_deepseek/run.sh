#!/bin/bash

# 设置工作目录和日志文件
WORK_DIR=$(pwd)
LOG_FILE="$WORK_DIR/ollama_service.log"

echo "Starting Ollama service..." > "$LOG_FILE" 2>&1

# 检查 Ollama 是否已安装
if ! command -v ollama >/dev/null 2>&1; then
    echo "Error: Ollama is not installed or not found in PATH." >> "$LOG_FILE" 2>&1
    echo "Please download and install Ollama from https://ollama.com/" >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查 Ollama 服务是否已在运行
if ollama serve >/dev/null 2>&1; then
    echo "Ollama service is already running." >> "$LOG_FILE" 2>&1
    exit 0
fi

# 在后台启动 Ollama 服务
echo "Starting Ollama service in background..." >> "$LOG_FILE" 2>&1
ollama serve >> "$LOG_FILE" 2>&1 &
sleep 5

# 检查日志文件是否存在错误
if grep -i "error" "$LOG_FILE" >/dev/null 2>&1; then
    echo "Warning: Ollama log contains errors. Check $LOG_FILE for details." >> "$LOG_FILE" 2>&1
    exit 1
fi

echo "Ollama service started successfully in background. Check $LOG_FILE for details." >> "$LOG_FILE" 2>&1
exit 0