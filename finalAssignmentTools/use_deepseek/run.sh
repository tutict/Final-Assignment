#!/bin/bash

# 设置工作目录和日志文件
WORK_DIR=$(pwd)
LOG_FILE="$WORK_DIR/ollama_deepseek-r1.log"
MODEL_NAME="deepseek-for-hgl-bishe"
HUGGINGFACE_REPO="4513P/deepseek-for-my-bishe"
GGUF_FILE="deepseek_r1_for_hgl_bishe.gguf"
MODELFILE="Modelfile"

echo "Starting Ollama setup for DeepSeek-R1..." > "$LOG_FILE" 2>&1

# 检查 Ollama 是否已安装
if ! command -v ollama >/dev/null 2>&1; then
    echo "Error: Ollama is not installed or not found in PATH." >> "$LOG_FILE" 2>&1
    echo "Please download and install Ollama from https://ollama.com/" >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查 curl 是否可用（用于下载文件）
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not available." >> "$LOG_FILE" 2>&1
    echo "Please install curl using 'sudo apt-get install curl' or equivalent." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查 ollama list 是否已有模型
echo "Checking if model $MODEL_NAME exists in ollama list..." >> "$LOG_FILE" 2>&1
if ollama list | grep -i "$MODEL_NAME" >/dev/null 2>&1; then
    echo "Model $MODEL_NAME already exists. Skipping download and build." >> "$LOG_FILE" 2>&1
    exec 3>&1
    exec 1>>"$LOG_FILE" 2>&1
    ollama run "$MODEL_NAME" &
    exit 0
fi

# 下载 GGUF 文件从 Hugging Face
echo "Downloading $GGUF_FILE from Hugging Face..." >> "$LOG_FILE" 2>&1
curl -L "https://huggingface.co/$HUGGINGFACE_REPO/resolve/main/$GGUF_FILE" -o "$WORK_DIR/$GGUF_FILE" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download $GGUF_FILE. Check network or Hugging Face repository." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查 GGUF 文件是否存在
if [ ! -f "$WORK_DIR/$GGUF_FILE" ]; then
    echo "Error: $GGUF_FILE not found after download." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 下载 Modelfile 从 Hugging Face
echo "Downloading $MODELFILE from Hugging Face..." >> "$LOG_FILE" 2>&1
curl -L "https://huggingface.co/$HUGGINGFACE_REPO/resolve/main/$MODELFILE" -o "$WORK_DIR/$MODELFILE" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download $MODELFILE. Check network or Hugging Face repository." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查 Modelfile 是否存在
if [ ! -f "$WORK_DIR/$MODELFILE" ]; then
    echo "Error: $MODELFILE not found after download." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 构建 Ollama 模型
echo "Building Ollama model $MODEL_NAME..." >> "$LOG_FILE" 2>&1
ollama create "$MODEL_NAME" -f "$WORK_DIR/$MODELFILE" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Ollama model $MODEL_NAME. Check $MODELFILE or logs." >> "$LOG_FILE" 2>&1
    exit 1
fi

# 在后台启动 Ollama 并运行模型
echo "Starting Ollama with $MODEL_NAME in background..." >> "$LOG_FILE" 2>&1
exec 3>&1
exec 1>>"$LOG_FILE" 2>&1
ollama run "$MODEL_NAME" &
exit 0