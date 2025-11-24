#!/bin/bash

# 设置工作目录和日志文件
WORK_DIR=$(pwd)
LOG_FILE="$WORK_DIR/ollama_service.log"

echo "Starting Ollama service..." > "$LOG_FILE" 2>&1

# ===== Docker Desktop bootstrap (macOS/Linux) =====
echo "Checking Docker daemon..." >> "$LOG_FILE" 2>&1
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "Docker is already running." >> "$LOG_FILE" 2>&1
  else
    # Try macOS Docker Desktop
    if [ "$(uname)" = "Darwin" ]; then
      echo "Attempting to launch Docker Desktop on macOS..." >> "$LOG_FILE" 2>&1
      open -a Docker >> "$LOG_FILE" 2>&1 || true
    else
      # Linux: try to start docker service (may require sudo)
      echo "Attempting to start docker service on Linux..." >> "$LOG_FILE" 2>&1
      if command -v systemctl >/dev/null 2>&1; then
        (sudo systemctl start docker) >> "$LOG_FILE" 2>&1 || true
      fi
    fi
    # Wait up to ~120s for docker to be ready
    __WAIT_SEC=0
    until docker info >/dev/null 2>&1 || [ $__WAIT_SEC -ge 120 ]; do
      sleep 5
      __WAIT_SEC=$((__WAIT_SEC+5))
    done
    if docker info >/dev/null 2>&1; then
      echo "Docker is ready." >> "$LOG_FILE" 2>&1
    else
      echo "Timeout waiting for Docker to be ready (120s)." >> "$LOG_FILE" 2>&1
    fi
  fi
else
  echo "Docker CLI not found in PATH. Please install Docker Desktop or Docker Engine." >> "$LOG_FILE" 2>&1
fi
# ================================================

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
