#!/bin/bash

# 捕捉退出信号以清理容器
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
    echo "请确保 Docker 正常运行并且当前用户有权限使用 Docker。或者使用 sudo 命令。"
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
    docker start redis > /dev/null 2>&1 &
else
    echo "创建并启动新的 Redis 容器..."
    docker run -d --name redis -p 6379:6379 $REDIS_IMAGE &
fi

# 检查并下载 Kafka 镜像
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$KAFKA_IMAGE\$"; then
    echo "未找到 Kafka 镜像，正在从 Docker Hub 下载..."
    docker pull $KAFKA_IMAGE
fi

# 定义日志目录为主目录下的路径
LOG_DIR="$HOME/kraft-combined-logs"

# 创建日志目录
mkdir -p $LOG_DIR

# 启动 Kafka 容器（KRaft 模式）
echo "启动 Kafka 容器（KRaft 模式）..."
docker run -d --name kafka -p 9092:9092 -p 9093:9093 \
    -e KAFKA_NODE_ID=1 \
    -e KAFKA_PROCESS_ROLES="broker,controller" \
    -e KAFKA_CONTROLLER_QUORUM_VOTERS="1@localhost:9093" \
    -e KAFKA_LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093" \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT" \
    -e KAFKA_INTER_BROKER_LISTENER_NAME="PLAINTEXT" \
    -e KAFKA_CONTROLLER_LISTENER_NAMES="CONTROLLER" \
    -e KAFKA_LOG_DIRS="/var/lib/kraft-combined-logs" \
    -v $LOG_DIR:/var/lib/kraft-combined-logs \
    $KAFKA_IMAGE &

echo "Kafka 和 Redis 容器已启动。"

# 不阻塞主进程，直接返回
exit 0
