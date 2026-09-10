#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: sh scripts/start-env.sh

Starts local Docker services and Ollama.

Optional environment variables:
  START_DOCKER=false       Skip Docker compose services.
  START_OLLAMA=false       Skip Ollama.
  STARTUP_LOG_DIR          Existing run log directory from start-dev.sh.
  REDPANDA_KAFKA_HOST_PORT Redpanda Kafka host port. Default: 9092, auto-falls back when unavailable.
  REDPANDA_KAFKA_FALLBACK_PORTS Fallback Kafka host ports. Default: 19092 19093 19094.
  DOCKER_WAIT_SECONDS      Docker readiness timeout. Default: 180
  OLLAMA_WAIT_SECONDS      Ollama readiness timeout. Default: 60
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/dev-compose.yml"
ROOT_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

START_DOCKER="${START_DOCKER:-true}"
START_OLLAMA="${START_OLLAMA:-true}"
DOCKER_WAIT_SECONDS="${DOCKER_WAIT_SECONDS:-180}"
OLLAMA_WAIT_SECONDS="${OLLAMA_WAIT_SECONDS:-60}"
if [ -n "${REDPANDA_KAFKA_HOST_PORT:-}" ]; then
  REDPANDA_KAFKA_HOST_PORT_EXPLICIT="true"
else
  REDPANDA_KAFKA_HOST_PORT_EXPLICIT="false"
fi
REDPANDA_KAFKA_HOST_PORT="${REDPANDA_KAFKA_HOST_PORT:-9092}"
REDPANDA_KAFKA_FALLBACK_PORTS="${REDPANDA_KAFKA_FALLBACK_PORTS:-19092 19093 19094}"
export REDPANDA_KAFKA_HOST_PORT
STARTUP_RUN_ID="${STARTUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
STARTUP_LOG_DIR="${STARTUP_LOG_DIR:-$ROOT_DIR/artifacts/startup/$STARTUP_RUN_ID}"
mkdir -p "$STARTUP_LOG_DIR"

ENV_LOG="$STARTUP_LOG_DIR/environment.log"
DOCKER_INFO_LOG="$STARTUP_LOG_DIR/docker-info.log"
DOCKER_COMPOSE_LOG="$STARTUP_LOG_DIR/docker-compose.log"
DOCKER_COMPOSE_PS_LOG="$STARTUP_LOG_DIR/docker-compose-ps.log"
OLLAMA_LOG="$STARTUP_LOG_DIR/ollama.log"
OLLAMA_HEALTH_LOG="$STARTUP_LOG_DIR/ollama-health.log"
OLLAMA_PID_FILE="$STARTUP_LOG_DIR/ollama.pid"

cat >"$ENV_LOG" <<EOF
Environment startup
Started at: $(date '+%Y-%m-%d %H:%M:%S')
COMPOSE_FILE=$COMPOSE_FILE
START_DOCKER=$START_DOCKER
START_OLLAMA=$START_OLLAMA
DOCKER_WAIT_SECONDS=$DOCKER_WAIT_SECONDS
OLLAMA_WAIT_SECONDS=$OLLAMA_WAIT_SECONDS
REDPANDA_KAFKA_HOST_PORT=$REDPANDA_KAFKA_HOST_PORT
REDPANDA_KAFKA_HOST_PORT_EXPLICIT=$REDPANDA_KAFKA_HOST_PORT_EXPLICIT
REDPANDA_KAFKA_FALLBACK_PORTS=$REDPANDA_KAFKA_FALLBACK_PORTS
EOF

log() {
  printf '%s\n' "$*"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$ENV_LOG"
}

tail_file() {
  file="$1"
  lines="${2:-80}"
  printf '\n----- %s (last %s lines) -----\n' "$file" "$lines" >&2
  if [ -f "$file" ]; then
    tail -n "$lines" "$file" >&2 || true
  else
    printf '[missing] %s\n' "$file" >&2
  fi
  printf '%s\n' "----- end $file -----" >&2
}

env_fail() {
  printf '\n[ERROR] %s\n' "$*" >&2
  printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$ENV_LOG"
  printf 'Environment log directory: %s\n' "$STARTUP_LOG_DIR" >&2
  tail_file "$ENV_LOG" 80
  tail_file "$DOCKER_INFO_LOG" 80
  tail_file "$DOCKER_COMPOSE_LOG" 160
  tail_file "$DOCKER_COMPOSE_PS_LOG" 120
  tail_file "$OLLAMA_LOG" 120
  tail_file "$OLLAMA_HEALTH_LOG" 80
  exit 1
}

start_docker_engine() {
  if docker info >"$DOCKER_INFO_LOG" 2>&1; then
    return 0
  fi

  os_name="$(uname -s 2>/dev/null || echo unknown)"
  case "$os_name" in
    Darwin)
      log "Docker daemon is not ready. Starting Docker Desktop for macOS..."
      open -a "${DOCKER_APP_NAME:-Docker}" >/dev/null 2>&1 || true
      ;;
    Linux)
      log "Docker daemon is not ready. Attempting to start Docker on Linux..."
      if command -v systemctl >/dev/null 2>&1; then
        systemctl --user start docker-desktop >/dev/null 2>&1 || true
        sudo -n systemctl start docker >/dev/null 2>&1 || true
      fi
      if command -v service >/dev/null 2>&1; then
        sudo -n service docker start >/dev/null 2>&1 || true
      fi
      ;;
    *)
      log "Docker daemon is not ready. Please start Docker manually for $os_name."
      ;;
  esac
}

wait_for_docker() {
  waited=0
  until docker info >"$DOCKER_INFO_LOG" 2>&1; do
    if [ "$waited" -ge "$DOCKER_WAIT_SECONDS" ]; then
      env_fail "Docker daemon did not become ready in $DOCKER_WAIT_SECONDS seconds."
    fi
    sleep 2
    waited=$((waited + 2))
  done
}

port_bindable() {
  port="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import socket, sys
port = int(sys.argv[1])
for host in ("0.0.0.0", "127.0.0.1"):
    sock = socket.socket()
    try:
        sock.bind((host, port))
    finally:
        sock.close()
' "$port" >/dev/null 2>&1
  elif command -v python >/dev/null 2>&1; then
    python -c 'import socket, sys
port = int(sys.argv[1])
for host in ("0.0.0.0", "127.0.0.1"):
    sock = socket.socket()
    try:
        sock.bind((host, port))
    finally:
        sock.close()
' "$port" >/dev/null 2>&1
  elif command -v lsof >/dev/null 2>&1; then
    ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  else
    return 0
  fi
}

redpanda_container_running() {
  [ "$(docker inspect -f '{{.State.Running}}' final-assignment-redpanda 2>/dev/null || true)" = "true" ]
}

redpanda_kafka_published_port() {
  docker port final-assignment-redpanda 9092/tcp 2>/dev/null | awk -F: 'NF > 1 { print $NF; exit }'
}

use_redpanda_kafka_host_port() {
  REDPANDA_KAFKA_HOST_PORT="$1"
  export REDPANDA_KAFKA_HOST_PORT
}

resolve_redpanda_kafka_host_port() {
  if [ "$REDPANDA_KAFKA_HOST_PORT_EXPLICIT" = "true" ]; then
    return 0
  fi
  if redpanda_container_running; then
    published_port=$(redpanda_kafka_published_port)
    if [ -n "$published_port" ]; then
      configured_port="$REDPANDA_KAFKA_HOST_PORT"
      use_redpanda_kafka_host_port "$published_port"
      if [ "$published_port" != "$configured_port" ]; then
        log "Using existing Redpanda Kafka host port $published_port from the running final-assignment-redpanda container."
      fi
    fi
    return 0
  fi
  if port_bindable "$REDPANDA_KAFKA_HOST_PORT"; then
    use_redpanda_kafka_host_port "$REDPANDA_KAFKA_HOST_PORT"
    return 0
  fi

  initial_port="$REDPANDA_KAFKA_HOST_PORT"
  for candidate in $(printf '%s' "$REDPANDA_KAFKA_FALLBACK_PORTS" | tr ',;' '  '); do
    case "$candidate" in
      ''|*[!0-9]*) continue ;;
    esac
    if port_bindable "$candidate"; then
      use_redpanda_kafka_host_port "$candidate"
      log "Redpanda Kafka host port $initial_port is not available; using $REDPANDA_KAFKA_HOST_PORT instead."
      return 0
    fi
  done

  env_fail "Redpanda Kafka host port $initial_port is not available, and no fallback ports are bindable. Set REDPANDA_KAFKA_HOST_PORT to a free port."
}

start_docker_services() {
  if [ ! -f "$COMPOSE_FILE" ]; then
    env_fail "Docker compose file not found: $COMPOSE_FILE"
  fi
  if ! command -v docker >/dev/null 2>&1; then
    env_fail "Docker CLI was not found in PATH."
  fi

  start_docker_engine
  wait_for_docker
  resolve_redpanda_kafka_host_port
  log "Redpanda Kafka host port: $REDPANDA_KAFKA_HOST_PORT"
  log "Starting Docker services from $COMPOSE_FILE..."
  set +e
  docker compose -f "$COMPOSE_FILE" up -d --remove-orphans --wait --wait-timeout "$DOCKER_WAIT_SECONDS" >"$DOCKER_COMPOSE_LOG" 2>&1
  compose_status=$?
  docker compose -f "$COMPOSE_FILE" ps >"$DOCKER_COMPOSE_PS_LOG" 2>&1
  set -e
  if [ "$compose_status" -ne 0 ]; then
    env_fail "Docker compose startup failed with exit code $compose_status."
  fi
  log "Docker services are ready. Log: $DOCKER_COMPOSE_LOG"
}

ollama_reachable() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >"$OLLAMA_HEALTH_LOG" 2>&1
  else
    ollama list >"$OLLAMA_HEALTH_LOG" 2>&1
  fi
}

start_ollama_service() {
  if ! command -v ollama >/dev/null 2>&1; then
    env_fail "Ollama executable was not found in PATH. Set START_OLLAMA=false to skip Ollama startup."
  fi

  if ollama_reachable; then
    log "Ollama is already reachable."
    return 0
  fi

  log "Starting Ollama service..."
  nohup ollama serve >"$OLLAMA_LOG" 2>&1 &
  echo "$!" >"$OLLAMA_PID_FILE"

  waited=0
  until ollama_reachable; do
    if [ "$waited" -ge "$OLLAMA_WAIT_SECONDS" ]; then
      env_fail "Ollama did not become reachable in $OLLAMA_WAIT_SECONDS seconds."
    fi
    sleep 2
    waited=$((waited + 2))
  done
  log "Ollama is ready. Log: $OLLAMA_LOG"
}

log "Environment startup log directory: $STARTUP_LOG_DIR"

if [ "$START_DOCKER" != "false" ]; then
  start_docker_services
fi

if [ "$START_OLLAMA" != "false" ]; then
  start_ollama_service
fi

log "Local environment is ready."
