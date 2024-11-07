@echo off

REM 检查并启动 Redis 容器
docker ps -a --format "{{.Names}}" | findstr /r "^redis$" >nul
if %ERRORLEVEL% EQU 0 (
    docker start redis >nul 2>&1
) else (
    docker run -d --name redis -p 6379:6379 redis
)

REM 检查并启动 Zookeeper 容器
docker ps -a --format "{{.Names}}" | findstr /r "^zookeeper$" >nul
if %ERRORLEVEL% EQU 0 (
    docker start zookeeper >nul 2>&1
) else (
    docker run -d --name zookeeper -p 2181:2181 ^
        -e ALLOW_ANONYMOUS_LOGIN=yes ^
        zookeeper:latest
)

REM 等待 Zookeeper 启动完成
echo 等待 Zookeeper 启动...
timeout /t 5 /nobreak >nul

REM 检查并启动 Kafka 容器
docker ps -a --format "{{.Names}}" | findstr /r "^kafka$" >nul
if %ERRORLEVEL% EQU 0 (
    docker start kafka >nul 2>&1
) else (
    docker run -d --name kafka -p 9092:9092 ^
        --link zookeeper:zookeeper ^
        -e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 ^
        -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 ^
        -e ALLOW_PLAINTEXT_LISTENER=yes ^
        apache/kafka:latest
)

echo Kafka 和 Redis 容器已启动。
