#!/bin/bash

# 启动 Redis 容器，如果容器已存在则启动，否则创建并启动
if docker ps -a --format '{{.Names}}' | grep -Eq "^redis\$"; then
    docker start redis > /dev/null 2>&1
else
    docker run -d --name redis -p 6379:6379 redis
fi

# 启动 Zookeeper 容器
if docker ps -a --format '{{.Names}}' | grep -Eq "^zookeeper\$"; then
    docker start zookeeper > /dev/null 2>&1
else
    docker run -d --name zookeeper -p 2181:2181 \
        -e ALLOW_ANONYMOUS_LOGIN=yes \
        zookeeper:latest
fi

# 等待 Zookeeper 启动完成
echo "等待 Zookeeper 启动..."
sleep 5

# 启动 Kafka 容器
if docker ps -a --format '{{.Names}}' | grep -Eq "^kafka\$"; then
    docker start kafka > /dev/null 2>&1
else
    docker run -d --name kafka -p 9092:9092 \
        --link zookeeper:zookeeper \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 \
        -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        apache/kafka:latest
fi

echo "Kafka 和 Redis 容器已启动。"
