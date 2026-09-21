#!/usr/bin/env bash
set -euo pipefail

WAIT="false"
SKIP_BUILD="false"
INCLUDE_AI="${CLOUD_INCLUDE_AI:-false}"
LOG_DIR=""
PROFILE="${BACKEND_PROFILE:-dev}"
GATEWAY_PORT="${CLOUD_GATEWAY_PORT:-${BACKEND_PORT:-8080}}"

while [ $# -gt 0 ]; do
  case "$1" in
    --wait) WAIT="true"; shift ;;
    --skip-build) SKIP_BUILD="true"; shift ;;
    --include-ai) INCLUDE_AI="true"; shift ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --gateway-port) GATEWAY_PORT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOUD_DIR="$ROOT_DIR/finalAssignmentCloud"
[ -f "$CLOUD_DIR/pom.xml" ] || { echo "Spring Cloud project not found: $CLOUD_DIR" >&2; exit 1; }

if [ -z "$LOG_DIR" ]; then
  LOG_DIR="$ROOT_DIR/artifacts/startup/cloud-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$LOG_DIR"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

PIDS=()
NAMES=()
PORTS=()
CRITICALS=()

cleanup() {
  log "Stopping Cloud services..."
  for pid in "${PIDS[@]:-}"; do
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
}

trap cleanup EXIT INT TERM

export JWT_SECRET="${JWT_SECRET:-dev-jwt-secret-key-for-local-startup-please-change-1234567890}"
if [ -z "${JWT_SECRET_KEY:-}" ]; then
  if printf '%s' "$JWT_SECRET" | grep -Eq '^[A-Za-z0-9+/=]+$' && [ "${#JWT_SECRET}" -ge 40 ]; then
    export JWT_SECRET_KEY="$JWT_SECRET"
  else
    export JWT_SECRET_KEY="$(printf '%s' "$JWT_SECRET" | base64 | tr -d '\n')"
  fi
fi
export INTERNAL_SERVICE_TOKEN="${INTERNAL_SERVICE_TOKEN:-dev-internal-service-token-32bytes-ok}"
export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-$PROFILE}"
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/traffic?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-root}"
export AUTH_DB_URL="${AUTH_DB_URL:-$SPRING_DATASOURCE_URL}"
export AUTH_DB_USERNAME="${AUTH_DB_USERNAME:-$SPRING_DATASOURCE_USERNAME}"
export AUTH_DB_PASSWORD="${AUTH_DB_PASSWORD:-$SPRING_DATASOURCE_PASSWORD}"
export RAG_DB_URL="${RAG_DB_URL:-$SPRING_DATASOURCE_URL}"
export RAG_DB_USERNAME="${RAG_DB_USERNAME:-$SPRING_DATASOURCE_USERNAME}"
export RAG_DB_PASSWORD="${RAG_DB_PASSWORD:-$SPRING_DATASOURCE_PASSWORD}"
export SPRING_DATA_REDIS_HOST="${SPRING_DATA_REDIS_HOST:-localhost}"
export SPRING_DATA_REDIS_PORT="${SPRING_DATA_REDIS_PORT:-6379}"
export SPRING_KAFKA_LISTENER_AUTO_STARTUP="${SPRING_KAFKA_LISTENER_AUTO_STARTUP:-false}"
export SPRING_KAFKA_BOOTSTRAP_SERVERS="${SPRING_KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
export MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED="${MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED:-false}"
export SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT="${SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT:-false}"
export RAG_RETRIEVAL_ENABLED="${RAG_RETRIEVAL_ENABLED:-true}"
export RAG_ENABLED="${RAG_ENABLED:-true}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2}"
export OLLAMA_CHAT_MODEL="${OLLAMA_CHAT_MODEL:-llama3.2}"
export SPRING_AI_OLLAMA_CHAT_OPTIONS_MODEL="${SPRING_AI_OLLAMA_CHAT_OPTIONS_MODEL:-llama3.2}"
export SPRING_AI_OLLAMA_EMBEDDING_OPTIONS_MODEL="${SPRING_AI_OLLAMA_EMBEDDING_OPTIONS_MODEL:-nomic-embed-text}"
export CLOUD_NACOS_DISCOVERY="${CLOUD_NACOS_DISCOVERY:-false}"
export CLOUD_AUTH_PORT="${CLOUD_AUTH_PORT:-8081}"
export CLOUD_USER_PORT="${CLOUD_USER_PORT:-18082}"
export CLOUD_TRAFFIC_PORT="${CLOUD_TRAFFIC_PORT:-18083}"
export CLOUD_AUDIT_PORT="${CLOUD_AUDIT_PORT:-8084}"
export CLOUD_SYSTEM_PORT="${CLOUD_SYSTEM_PORT:-8085}"
export CLOUD_AI_PORT="${CLOUD_AI_PORT:-8086}"
export CLOUD_SEARCH_PORT="${CLOUD_SEARCH_PORT:-8087}"
export CLOUD_RAG_PORT="${CLOUD_RAG_PORT:-8088}"
export CLOUD_GATEWAY_PORT="$GATEWAY_PORT"
export SPRING_CONFIG_ADDITIONAL_LOCATION="optional:file:$CLOUD_DIR/config/local-dev.yml"

MVN_CMD="${MVN_CMD:-mvn}"
JAVA_CMD="${JAVA_CMD:-java}"
command -v "$MVN_CMD" >/dev/null 2>&1 || { echo "Maven not found" >&2; exit 1; }
command -v "$JAVA_CMD" >/dev/null 2>&1 || { echo "Java not found" >&2; exit 1; }

if [ "${CLOUD_SKIP_BUILD:-$SKIP_BUILD}" != "true" ]; then
  log "Packaging Cloud modules (skip tests)..."
  (cd "$CLOUD_DIR" && "$MVN_CMD" -DskipTests package) >"$LOG_DIR/mvn-package.log" 2>&1
  log "Cloud modules packaged."
fi

http_ok() {
  curl -fsS --max-time 3 "$1" >/dev/null 2>&1 || wget -q -O /dev/null --timeout=3 "$1" >/dev/null 2>&1
}

start_module() {
  name="$1"
  port="$2"
  xmx="$3"
  jar="$(ls -1t "$CLOUD_DIR/$name/target/$name-"*.jar 2>/dev/null | grep -vE 'original|sources|javadoc|tests' | head -n 1 || true)"
  if [ -z "$jar" ]; then
    echo "Missing executable jar for $name" >&2
    return 1
  fi
  log "Starting $name on $port"
  nohup "$JAVA_CMD" -Xms128m -Xmx"$xmx" -jar "$jar" \
    --spring.profiles.active="$PROFILE" --server.port="$port" \
    >"$LOG_DIR/$name.log" 2>"$LOG_DIR/$name.err.log" &
  pid=$!
  PIDS+=("$pid")
  NAMES+=("$name")
  PORTS+=("$port")
  printf '%s=%s\n' "$name" "$pid" >>"$LOG_DIR/cloud-pids.txt"
}

wait_health() {
  name="$1"
  port="$2"
  seconds="$3"
  url="http://127.0.0.1:$port/actuator/health"
  waited=0
  while [ "$waited" -lt "$seconds" ]; do
    if http_ok "$url"; then
      log "$name healthy on $port"
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  echo "$name failed health check at $url" >&2
  return 1
}

: >"$LOG_DIR/cloud-pids.txt"
start_module finalassignmentcloud-user "$CLOUD_USER_PORT" 384m
start_module finalassignmentcloud-auth "$CLOUD_AUTH_PORT" 384m
start_module finalassignmentcloud-traffic "$CLOUD_TRAFFIC_PORT" 384m
start_module finalassignmentcloud-audit "$CLOUD_AUDIT_PORT" 256m || true
start_module finalassignmentcloud-system "$CLOUD_SYSTEM_PORT" 256m || true
start_module finalassignmentcloud-search "$CLOUD_SEARCH_PORT" 256m || true
start_module finalassignmentcloud-rag "$CLOUD_RAG_PORT" 768m

HEALTH_WAIT="${CLOUD_SERVICE_HEALTH_WAIT_SECONDS:-180}"
wait_health finalassignmentcloud-user "$CLOUD_USER_PORT" "$HEALTH_WAIT"
wait_health finalassignmentcloud-auth "$CLOUD_AUTH_PORT" "$HEALTH_WAIT"
wait_health finalassignmentcloud-traffic "$CLOUD_TRAFFIC_PORT" "$HEALTH_WAIT"
wait_health finalassignmentcloud-rag "$CLOUD_RAG_PORT" "$HEALTH_WAIT" || true

start_module finalassignmentcloud-gateway "$CLOUD_GATEWAY_PORT" 256m
wait_health finalassignmentcloud-gateway "$CLOUD_GATEWAY_PORT" "${CLOUD_GATEWAY_HEALTH_WAIT_SECONDS:-180}"

log "Cloud stack is up. Gateway: http://127.0.0.1:$CLOUD_GATEWAY_PORT"
log "Logs: $LOG_DIR"

if [ "$WAIT" = "true" ]; then
  log "Waiting until stopped."
  while true; do
    for pid in "${PIDS[@]}"; do
      if ! kill -0 "$pid" 2>/dev/null; then
        echo "A Cloud process exited (pid $pid)" >&2
        exit 1
      fi
    done
    sleep 2
  done
else
  trap - EXIT
fi
