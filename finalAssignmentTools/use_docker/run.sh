#!/bin/bash

# 检查是否以非 root 用户运行，如果是非 root 用户且未添加到 docker 组，请确保有权限使用 Docker
if ! docker info > /dev/null 2>&1; then
    echo "请确保 Docker 正常运行并且当前用户有权限使用 Docker。"
    exit 1
fi

# 定义镜像名称
REDIS_IMAGE="redis:latest"
ZOOKEEPER_IMAGE="zookeeper:latest"
KAFKA_IMAGE="apache/kafka:latest"

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

# 检查并下载 Zookeeper 镜像
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$ZOOKEEPER_IMAGE\$"; then
    echo "未找到 Zookeeper 镜像，正在从 Docker Hub 下载..."
    docker pull $ZOOKEEPER_IMAGE
fi

# 启动 Zookeeper 容器
if docker ps -a --format "{{.Names}}" | grep -q "^zookeeper$"; then
    echo "启动已有的 Zookeeper 容器..."
    docker start zookeeper > /dev/null 2>&1
else
    echo "创建并启动新的 Zookeeper 容器..."
    docker run -d --name zookeeper -p 2181:2181 \
        -e ALLOW_ANONYMOUS_LOGIN=yes \
        $ZOOKEEPER_IMAGE
fi

# 等待 Zookeeper 启动完成
echo "等待 Zookeeper 启动..."
sleep 5

# 检查并下载 Kafka 镜像
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$KAFKA_IMAGE\$"; then
    echo "未找到 Kafka 镜像，正在从 Docker Hub 下载..."
    docker pull $KAFKA_IMAGE
fi

# 启动 Kafka 容器
if docker ps -a --format "{{.Names}}" | grep -q "^kafka$"; then
    echo "启动已有的 Kafka 容器..."
    docker start kafka > /dev/null 2>&1
else
    echo "创建并启动新的 Kafka 容器..."
    docker run -d --name kafka -p 9092:9092 \
        --link zookeeper:zookeeper \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 \
        -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        $KAFKA_IMAGE
fi

echo "Kafka 和 Redis 容器已启动。"
