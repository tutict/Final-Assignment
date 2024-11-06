#!/bin/bash

# 启动 Redis 容器
docker run -d --name redis -p 6379:6379 redis

# 启动 Zookeeper 容器
docker run -d --name zookeeper -p 2181:2181 \
  -e ALLOW_ANONYMOUS_LOGIN=yes \
  bitnami/zookeeper:latest

# 等待 Zookeeper 完成启动
echo "等待 Zookeeper 启动..."
sleep 5

# 启动 Kafka 容器
docker run -d --name kafka -p 9092:9092 \
  --link zookeeper:zookeeper \
  -e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e ALLOW_PLAINTEXT_LISTENER=yes \
  bitnami/kafka:latest

echo "Kafka 和 Redis 容器已启动。"
