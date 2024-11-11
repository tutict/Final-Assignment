@echo off

REM 捕捉 Ctrl+C 信号并执行清理操作
REM 这部分逻辑在 Windows 下并不像 Linux 那样直接实现，但可以在正常结束脚本时清理

:cleanup
echo.
echo 正在停止 Kafka 和 Redis 容器...
docker stop kafka redis >nul 2>&1
echo 容器已停止。
goto end

REM 启动 Docker 服务
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo 请确保 Docker 正常运行并且当前用户有权限使用 Docker。
    pause
    goto end
)

REM 定义镜像名称
SET KAFKA_IMAGE=apache/kafka:latest
SET REDIS_IMAGE=redis:latest

REM 检查并下载 Redis 镜像
docker images --format "{{.Repository}}:{{.Tag}}" | findstr /i "^%REDIS_IMAGE%$" >nul
IF %ERRORLEVEL% NEQ 0 (
    echo 未找到 Redis 镜像，正在从 Docker Hub 下载...
    docker pull %REDIS_IMAGE%
)

REM 启动 Redis 容器
docker ps -a --format "{{.Names}}" | findstr /i "^redis$" >nul
IF %ERRORLEVEL% EQU 0 (
    echo 启动已有的 Redis 容器...
    docker start redis >nul 2>&1
) ELSE (
    echo 创建并启动新的 Redis 容器...
    docker run -d --name redis -p 6379:6379 %REDIS_IMAGE%
)

REM 检查并下载 Kafka 镜像
docker images --format "{{.Repository}}:{{.Tag}}" | findstr /i "^%KAFKA_IMAGE%$" >nul
IF %ERRORLEVEL% NEQ 0 (
    echo 未找到 Kafka 镜像，正在从 Docker Hub 下载...
    docker pull %KAFKA_IMAGE%
)

REM 定义日志目录为当前用户的目录
SET LOG_DIR=%USERPROFILE%\kraft-combined-logs

REM 创建日志目录
IF NOT EXIST "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

REM 启动 Kafka 容器（KRaft 模式）
echo 启动 Kafka 容器（KRaft 模式）...
docker run -d --name kafka -p 9092:9092 -p 9093:9093 ^
    -e KAFKA_NODE_ID=1 ^
    -e KAFKA_PROCESS_ROLES="broker,controller" ^
    -e KAFKA_CONTROLLER_QUORUM_VOTERS="1@localhost:9093" ^
    -e KAFKA_LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093" ^
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT" ^
    -e KAFKA_INTER_BROKER_LISTENER_NAME="PLAINTEXT" ^
    -e KAFKA_CONTROLLER_LISTENER_NAMES="CONTROLLER" ^
    -e KAFKA_LOG_DIRS="/var/lib/kraft-combined-logs" ^
    -v "%LOG_DIR%":/var/lib/kraft-combined-logs ^
    %KAFKA_IMAGE%

echo Kafka 和 Redis 容器已启动。
echo 按 Ctrl+C 停止容器...

REM 等待用户按下 Ctrl+C
:wait
timeout /t 5 >nul
IF ERRORLEVEL 1 (
    goto cleanup
) ELSE (
    goto wait
)

:end
exit /b 0
