#!/bin/bash

echo "Starting Ollama with DeepSeek-R1 in background..."

# 检查 Ollama 是否已安装
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama is not installed or not found in PATH."
    echo "Please download and install Ollama from https://ollama.com/"
    exit 1
fi

# 在后台启动 Ollama 并运行 DeepSeek-R1，输出重定向到文件
ollama run deepseek-r1 > ollama_deepseek-r1.log 2>&1 &

echo "Ollama with DeepSeek-R1 started in background. Check ollama_deepseek-r1.log for details."