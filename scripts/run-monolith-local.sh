#!/usr/bin/env bash
# 启动单体 Spring Boot 后端（外部 8080 / 内部 9080），供前后端联调使用。
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${1:-$ROOT/artifacts/startup/monolith}"
mkdir -p "$LOG_DIR"

export JWT_SECRET="${JWT_SECRET:-dev-jwt-secret-key-for-local-startup-please-change-1234567890}"
export APP_DEV_SERVICES_ENABLED=false
export APP_DOCKER_STARTUP_SCRIPT_ENABLED=false
export APP_OLLAMA_STARTUP_SCRIPT_ENABLED=false
export APP_DEV_SERVICES_REDPANDA_ENABLED=false
export APP_ELASTICSEARCH_FALLBACK_ENABLED=true
export APP_ELASTICSEARCH_SYNC_ENABLED=false
export SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT=true
export SPRING_DEVTOOLS_RESTART_ENABLED=false
export SPRING_KAFKA_LISTENER_AUTO_STARTUP=false
export MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED=false
export MANAGEMENT_HEALTH_REDIS_ENABLED=false
export SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY=never
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/traffic}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-root}"
export SPRING_DATASOURCE_DRIVER_CLASS_NAME="${SPRING_DATASOURCE_DRIVER_CLASS_NAME:-com.mysql.cj.jdbc.Driver}"
export SPRING_DATA_REDIS_HOST=localhost
export SPRING_DATA_REDIS_PORT=6379
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export SPRING_KAFKA_LISTENER_AUTO_STARTUP=true
export SERVER_PORT=9080
export NETWORK_SERVER_PORT=8080
export BACKEND_URL=http://127.0.0.1
export BACKEND_PORT=9080

JAR="$ROOT/finalAssignmentBackend/target/finalAssignmentBackend-0.0.1-SNAPSHOT.jar"
if command -v cygpath >/dev/null 2>&1; then
  JAR="$(cygpath -w "$JAR")"
fi
java -jar "$JAR" --spring.profiles.active=dev >"$LOG_DIR/backend.log" 2>&1 &
echo $! > "$LOG_DIR/backend.pid"
echo "monolith pid=$(cat "$LOG_DIR/backend.pid") log=$LOG_DIR/backend.log"
