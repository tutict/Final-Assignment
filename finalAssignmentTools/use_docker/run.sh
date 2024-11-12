#!/bin/bash

# 处理 Ctrl+C 信号以停止所有容器
# shellcheck disable=SC2317
function cleanup {
    echo ""
    echo "正在停止 Kafka 和 Redis 容器..."
    docker stop kafka redis > /dev/null 2>&1
    echo "容器已停止。"
    exit 0
}

# 绑定 Ctrl+C 信号到 cleanup 函数
trap cleanup INT

# 检查是否以非 root 用户运行，如果是非 root 用户且未添加到 docker 组，请确保有权限使用 Docker
if ! docker info > /dev/null 2>&1; then
    echo "请确保 Docker 正常运行并且当前用户有权限使用 Docker。"
    exit 1
fi

# 检查端口 9092 是否被占用
if lsof -i:9092 &> /dev/null; then
    echo "端口 9092 已被占用，请关闭占用该端口的进程后再运行此脚本。"
    exit 1
fi

# 检查端口 9092 是否被占用
if lsof -i:6379 &> /dev/null; then
    echo "端口 6379 已被占用，请关闭占用该端口的进程后再运行此脚本。"
    exit 1
fi

# 定义镜像名称
KAFKA_IMAGE="apache/kafka:latest"
REDIS_IMAGE="redis:latest"

# 检查并下载 Redis 镜像
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$REDIS_IMAGE\$"; then
    echo "未找到 Redis 镜像，正在从 Docker Hub 下载..."
    docker pull $REDIS_IMAGE
fi

# 启动 Redis 容器
if docker ps -a --format "{{.Names}}" | grep -q "^redis$"; then
    echo "启动已有的 Redis 容器..."
    docker start redis > /dev/null 2>&1
else
    echo "创建并启动新的 Redis 容器..."
    docker run -d --name redis -p 6379:6379 $REDIS_IMAGE
fi

# 检查并下载 Kafka 镜像
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$KAFKA_IMAGE\$"; then
    echo "未找到 Kafka 镜像，正在从 Docker Hub 下载..."
    docker pull $KAFKA_IMAGE
fi

# 启动 Kafka 容器（单机模式）
if docker ps -a --format "{{.Names}}" | grep -q "^kafka$"; then
    echo "启动已有的 Kafka 容器..."
    docker start kafka > /dev/null 2>&1
else
echo "创建并启动新的 Kafka 容器"
docker run -d --name kafka -p 9092:9092 $KAFKA_IMAGE
fi

echo "Kafka 和 Redis 容器已启动。"
echo "按 Ctrl+C 以停止所有服务并退出..."

exit 0
