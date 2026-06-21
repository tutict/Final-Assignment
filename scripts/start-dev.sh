#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: sh scripts/start-dev.sh

Starts:
  1. Local Docker/Ollama environment, unless START_LOCAL_SERVICES=false
  2. Spring Boot backend from finalAssignmentBackend
  3. Flutter app from final_assignment_front

Ctrl-C cleanup:
  Stops Flutter, Spring Boot, and child processes.
  If START_LOCAL_SERVICES=true, also stops Docker Compose services and Ollama by default.

Optional environment variables:
  START_LOCAL_SERVICES         Start Docker services and Ollama before backend. Default: true
  STOP_LOCAL_SERVICES_ON_EXIT  Stop Docker/Ollama on Ctrl-C or script exit. Default: START_LOCAL_SERVICES
  STOP_DOCKER_ON_EXIT          Stop Docker Compose services on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STOP_OLLAMA_ON_EXIT          Stop Ollama started by this script on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STARTUP_LOG_ROOT             Root log directory. Default: artifacts/startup
  BACKEND_PROFILE              Spring profile. Default: dev
  BACKEND_ARGS                 Extra Maven/Spring Boot plugin arguments.
  BACKEND_WAIT_SECONDS         Initial delay before health polling. Default: 8
  BACKEND_HEALTH_WAIT_SECONDS  Backend health timeout. Default: 120
  BACKEND_HEALTH_URL           Health URL. Default: http://127.0.0.1:8080/actuator/health
  DB_URL, DB_USERNAME, DB_PASSWORD  Short aliases used when SPRING_DATASOURCE_* is unset.
  APP_ENV                      Flutter APP_ENV dart define. Default: dev
  API_BASE_URL                 Flutter API base URL. Default: http://localhost:8080
  WS_BASE_URL                  Flutter WebSocket URL. Default: ws://localhost:8081
  MVN_CMD                      Maven executable. Default: mvn
  FLUTTER_CMD                  Flutter executable. Default: flutter
  FLUTTER_DEVICE               Flutter device id. Default: web-server
  FLUTTER_ARGS                 Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
  FLUTTER_WAIT_SECONDS         Flutter web readiness timeout. Default: 120
  FLUTTER_WEB_URL              Flutter web readiness URL. Default: http://127.0.0.1:3000
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/dev-compose.yml"

BACKEND_DIR="$ROOT_DIR/finalAssignmentBackend"
FLUTTER_DIR="$ROOT_DIR/final_assignment_front"

START_LOCAL_SERVICES="${START_LOCAL_SERVICES:-true}"
STOP_LOCAL_SERVICES_ON_EXIT="${STOP_LOCAL_SERVICES_ON_EXIT:-$START_LOCAL_SERVICES}"
STOP_DOCKER_ON_EXIT="${STOP_DOCKER_ON_EXIT:-$STOP_LOCAL_SERVICES_ON_EXIT}"
STOP_OLLAMA_ON_EXIT="${STOP_OLLAMA_ON_EXIT:-$STOP_LOCAL_SERVICES_ON_EXIT}"
BACKEND_PROFILE="${BACKEND_PROFILE:-dev}"
JWT_SECRET="${JWT_SECRET:-dev-jwt-secret-key-for-local-startup-please-change-1234567890}"
APP_DEV_SERVICES_ENABLED="${APP_DEV_SERVICES_ENABLED:-false}"
APP_DOCKER_STARTUP_SCRIPT_ENABLED="${APP_DOCKER_STARTUP_SCRIPT_ENABLED:-false}"
APP_OLLAMA_STARTUP_SCRIPT_ENABLED="${APP_OLLAMA_STARTUP_SCRIPT_ENABLED:-false}"
APP_DEV_SERVICES_REDPANDA_ENABLED="${APP_DEV_SERVICES_REDPANDA_ENABLED:-false}"
APP_ELASTICSEARCH_FALLBACK_ENABLED="${APP_ELASTICSEARCH_FALLBACK_ENABLED:-true}"
APP_ELASTICSEARCH_SYNC_ENABLED="${APP_ELASTICSEARCH_SYNC_ENABLED:-false}"
SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT="${SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT:-true}"
SPRING_DEVTOOLS_RESTART_ENABLED="${SPRING_DEVTOOLS_RESTART_ENABLED:-false}"
SPRING_KAFKA_LISTENER_AUTO_STARTUP="${SPRING_KAFKA_LISTENER_AUTO_STARTUP:-false}"
MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED="${MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED:-false}"
SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY="${SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY:-never}"
SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-${DB_URL:-jdbc:mysql://localhost:3306/traffic}}"
SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-${DB_USERNAME:-root}}"
SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${DB_PASSWORD:-root}}"
SPRING_DATASOURCE_DRIVER_CLASS_NAME="${SPRING_DATASOURCE_DRIVER_CLASS_NAME:-com.mysql.cj.jdbc.Driver}"
SPRING_DATA_REDIS_HOST="${SPRING_DATA_REDIS_HOST:-localhost}"
SPRING_DATA_REDIS_PORT="${SPRING_DATA_REDIS_PORT:-6379}"
SPRING_KAFKA_BOOTSTRAP_SERVERS="${SPRING_KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
APP_ENV="${APP_ENV:-dev}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
WS_BASE_URL="${WS_BASE_URL:-ws://localhost:8081}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
BACKEND_WAIT_SECONDS="${BACKEND_WAIT_SECONDS:-8}"
BACKEND_HEALTH_WAIT_SECONDS="${BACKEND_HEALTH_WAIT_SECONDS:-120}"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://127.0.0.1:$BACKEND_PORT/actuator/health}"
MVN_CMD="${MVN_CMD:-mvn}"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
FLUTTER_ARGS="${FLUTTER_ARGS:---web-hostname 127.0.0.1 --web-port 3000}"
FLUTTER_WAIT_SECONDS="${FLUTTER_WAIT_SECONDS:-120}"
FLUTTER_WEB_URL="${FLUTTER_WEB_URL:-http://127.0.0.1:3000}"

STARTUP_LOG_ROOT="${STARTUP_LOG_ROOT:-$ROOT_DIR/artifacts/startup}"
STARTUP_RUN_ID="${STARTUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
STARTUP_LOG_DIR="${STARTUP_LOG_DIR:-$STARTUP_LOG_ROOT/$STARTUP_RUN_ID}"
mkdir -p "$STARTUP_LOG_DIR"
export STARTUP_LOG_DIR STARTUP_RUN_ID

STARTUP_LOG="$STARTUP_LOG_DIR/startup.log"
BACKEND_LOG="$STARTUP_LOG_DIR/backend.log"
BACKEND_ERR_LOG="$STARTUP_LOG_DIR/backend.err.log"
FLUTTER_PUB_LOG="$STARTUP_LOG_DIR/flutter-pub-get.log"
FLUTTER_LOG="$STARTUP_LOG_DIR/flutter.log"
FLUTTER_ERR_LOG="$STARTUP_LOG_DIR/flutter.err.log"
ENV_STOP_LOG="$STARTUP_LOG_DIR/environment-stop.log"
OLLAMA_PID_FILE="$STARTUP_LOG_DIR/ollama.pid"

BACKEND_PID=""
FLUTTER_PID=""
CLEANUP_STARTED="false"

log() {
  printf '%s\n' "$*"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$STARTUP_LOG"
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

print_ports() {
  printf '\n----- Port diagnostics -----\n' >&2
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$BACKEND_PORT" -iTCP:8081 -iTCP:3000 -sTCP:LISTEN >&2 || true
  elif command -v ss >/dev/null 2>&1; then
    ss -ltnp >&2 || true
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an >&2 || true
  else
    printf 'No port diagnostic command found.\n' >&2
  fi
  printf '%s\n' '----- end Port diagnostics -----' >&2
}

print_docker_state() {
  if command -v docker >/dev/null 2>&1; then
    printf '\n----- Docker compose services -----\n' >&2
    docker compose -f "$COMPOSE_FILE" ps >&2 2>/dev/null || true
    printf '%s\n' '----- end Docker compose services -----' >&2
  fi
}

print_failure_context() {
  printf '\nStartup log directory: %s\n' "$STARTUP_LOG_DIR" >&2
  tail_file "$STARTUP_LOG" 80
  tail_file "$BACKEND_LOG" 120
  tail_file "$BACKEND_ERR_LOG" 120
  tail_file "$FLUTTER_PUB_LOG" 80
  tail_file "$FLUTTER_LOG" 120
  tail_file "$FLUTTER_ERR_LOG" 120
  print_ports
  print_docker_state
}

fail() {
  printf '\n[ERROR] %s\n' "$*" >&2
  printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$STARTUP_LOG"
  print_failure_context
  exit 1
}

check_http() {
  url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 3 "$url" >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=3 --spider "$url" >/dev/null 2>&1
  else
    return 1
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Required command not found in PATH: $1"
  fi
}

kill_tree() {
  pid="$1"
  if [ -z "$pid" ] || ! kill -0 "$pid" >/dev/null 2>&1; then
    return 0
  fi
  if command -v pgrep >/dev/null 2>&1; then
    for child in $(pgrep -P "$pid" 2>/dev/null || true); do
      kill_tree "$child"
    done
  fi
  kill "$pid" >/dev/null 2>&1 || true
  sleep 1
  kill -9 "$pid" >/dev/null 2>&1 || true
}

cleanup_dependencies() {
  if [ "$STOP_OLLAMA_ON_EXIT" = "true" ] && [ -f "$OLLAMA_PID_FILE" ]; then
    ollama_pid="$(head -n 1 "$OLLAMA_PID_FILE" 2>/dev/null || true)"
    case "$ollama_pid" in
      *[!0-9]*|'') ;;
      *)
        log "Stopping Ollama process tree at PID $ollama_pid..."
        kill_tree "$ollama_pid"
        ;;
    esac
  fi

  if [ "$STOP_DOCKER_ON_EXIT" = "true" ] && command -v docker >/dev/null 2>&1 && [ -f "$COMPOSE_FILE" ]; then
    log "Stopping Docker Compose services from $COMPOSE_FILE..."
    if docker compose -f "$COMPOSE_FILE" down --remove-orphans >"$ENV_STOP_LOG" 2>&1; then
      log "Docker Compose services stopped. Log: $ENV_STOP_LOG"
    else
      log "Docker Compose cleanup failed. See $ENV_STOP_LOG"
    fi
  fi
}

cleanup() {
  status=$?
  trap - EXIT INT TERM
  if [ "$CLEANUP_STARTED" = "true" ]; then
    exit "$status"
  fi
  CLEANUP_STARTED="true"
  log "Cleanup started."
  if [ -n "$FLUTTER_PID" ] && kill -0 "$FLUTTER_PID" >/dev/null 2>&1; then
    log "Stopping Flutter process tree at PID $FLUTTER_PID..."
    kill_tree "$FLUTTER_PID"
  fi
  if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    log "Stopping Spring Boot process tree at PID $BACKEND_PID..."
    kill_tree "$BACKEND_PID"
  fi
  if [ "$START_LOCAL_SERVICES" = "true" ] && [ "$STOP_LOCAL_SERVICES_ON_EXIT" = "true" ]; then
    cleanup_dependencies
  else
    log "Skipping dependency cleanup. START_LOCAL_SERVICES=$START_LOCAL_SERVICES STOP_LOCAL_SERVICES_ON_EXIT=$STOP_LOCAL_SERVICES_ON_EXIT"
  fi
  log "Cleanup completed."
  exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cat >"$STARTUP_LOG" <<EOF
Final Assignment startup run
Run ID: $STARTUP_RUN_ID
Started at: $(date '+%Y-%m-%d %H:%M:%S')
Root: $ROOT_DIR
Log directory: $STARTUP_LOG_DIR
Backend directory: $BACKEND_DIR
Flutter directory: $FLUTTER_DIR
START_LOCAL_SERVICES=$START_LOCAL_SERVICES
STOP_LOCAL_SERVICES_ON_EXIT=$STOP_LOCAL_SERVICES_ON_EXIT
STOP_DOCKER_ON_EXIT=$STOP_DOCKER_ON_EXIT
STOP_OLLAMA_ON_EXIT=$STOP_OLLAMA_ON_EXIT
BACKEND_PROFILE=$BACKEND_PROFILE
BACKEND_HEALTH_URL=$BACKEND_HEALTH_URL
SPRING_DATASOURCE_URL=$SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME=$SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD=<redacted>
SPRING_DATA_REDIS_HOST=$SPRING_DATA_REDIS_HOST
SPRING_DATA_REDIS_PORT=$SPRING_DATA_REDIS_PORT
SPRING_KAFKA_BOOTSTRAP_SERVERS=$SPRING_KAFKA_BOOTSTRAP_SERVERS
APP_ENV=$APP_ENV
API_BASE_URL=$API_BASE_URL
WS_BASE_URL=$WS_BASE_URL
FLUTTER_DEVICE=$FLUTTER_DEVICE
FLUTTER_ARGS=$FLUTTER_ARGS
EOF

if [ ! -f "$BACKEND_DIR/pom.xml" ]; then
  fail "Spring Boot project not found: $BACKEND_DIR"
fi

if [ ! -f "$FLUTTER_DIR/pubspec.yaml" ]; then
  fail "Flutter project not found: $FLUTTER_DIR"
fi

require_command "$MVN_CMD"
require_command "$FLUTTER_CMD"

if [ "$START_LOCAL_SERVICES" = "true" ]; then
  log "Starting local Docker/Ollama environment..."
  if ! sh "$SCRIPT_DIR/start-env.sh"; then
    fail "Local Docker/Ollama environment startup failed."
  fi
else
  log "Skipping local Docker/Ollama environment because START_LOCAL_SERVICES=false."
fi

log "Starting Spring Boot backend with profile $BACKEND_PROFILE..."
(
  cd "$BACKEND_DIR"
  export JWT_SECRET APP_DEV_SERVICES_ENABLED APP_DOCKER_STARTUP_SCRIPT_ENABLED APP_OLLAMA_STARTUP_SCRIPT_ENABLED
  export APP_DEV_SERVICES_REDPANDA_ENABLED APP_ELASTICSEARCH_FALLBACK_ENABLED APP_ELASTICSEARCH_SYNC_ENABLED
  export SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT SPRING_DEVTOOLS_RESTART_ENABLED SPRING_KAFKA_LISTENER_AUTO_STARTUP
  export MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY
  export SPRING_DATASOURCE_URL SPRING_DATASOURCE_USERNAME SPRING_DATASOURCE_PASSWORD SPRING_DATASOURCE_DRIVER_CLASS_NAME
  export SPRING_DATA_REDIS_HOST SPRING_DATA_REDIS_PORT SPRING_KAFKA_BOOTSTRAP_SERVERS
  # shellcheck disable=SC2086
  "$MVN_CMD" spring-boot:run "-Dspring-boot.run.profiles=$BACKEND_PROFILE" "-Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false" ${BACKEND_ARGS:-}
) >"$BACKEND_LOG" 2>"$BACKEND_ERR_LOG" &
BACKEND_PID=$!

log "Spring Boot PID: $BACKEND_PID"
log "Backend stdout: $BACKEND_LOG"
log "Backend stderr: $BACKEND_ERR_LOG"
log "Waiting $BACKEND_WAIT_SECONDS seconds before backend health polling..."
sleep "$BACKEND_WAIT_SECONDS"

log "Waiting up to $BACKEND_HEALTH_WAIT_SECONDS seconds for $BACKEND_HEALTH_URL..."
waited=0
while [ "$waited" -lt "$BACKEND_HEALTH_WAIT_SECONDS" ]; do
  if check_http "$BACKEND_HEALTH_URL"; then
    log "Spring Boot backend is healthy."
    break
  fi
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    wait "$BACKEND_PID" || backend_status=$?
    fail "Spring Boot backend exited before becoming healthy. Exit code: ${backend_status:-1}"
  fi
  sleep 2
  waited=$((waited + 2))
done

if [ "$waited" -ge "$BACKEND_HEALTH_WAIT_SECONDS" ]; then
  fail "Spring Boot backend did not become healthy within $BACKEND_HEALTH_WAIT_SECONDS seconds."
fi

log "Resolving Flutter dependencies..."
if ! (cd "$FLUTTER_DIR" && "$FLUTTER_CMD" pub get >"$FLUTTER_PUB_LOG" 2>&1); then
  tail_file "$FLUTTER_PUB_LOG" 120
  fail "flutter pub get failed."
fi
log "flutter pub get completed. Log: $FLUTTER_PUB_LOG"

log "Starting Flutter app..."
(
  cd "$FLUTTER_DIR"
  if [ -n "${FLUTTER_DEVICE:-}" ]; then
    # shellcheck disable=SC2086
    "$FLUTTER_CMD" run -d "$FLUTTER_DEVICE" \
      "--dart-define=APP_ENV=$APP_ENV" \
      "--dart-define=API_BASE_URL=$API_BASE_URL" \
      "--dart-define=WS_BASE_URL=$WS_BASE_URL" \
      ${FLUTTER_ARGS:-}
  else
    # shellcheck disable=SC2086
    "$FLUTTER_CMD" run \
      "--dart-define=APP_ENV=$APP_ENV" \
      "--dart-define=API_BASE_URL=$API_BASE_URL" \
      "--dart-define=WS_BASE_URL=$WS_BASE_URL" \
      ${FLUTTER_ARGS:-}
  fi
) >"$FLUTTER_LOG" 2>"$FLUTTER_ERR_LOG" &
FLUTTER_PID=$!

log "Flutter PID: $FLUTTER_PID"
log "Flutter stdout: $FLUTTER_LOG"
log "Flutter stderr: $FLUTTER_ERR_LOG"

if [ "$FLUTTER_DEVICE" = "web-server" ]; then
  log "Waiting up to $FLUTTER_WAIT_SECONDS seconds for $FLUTTER_WEB_URL..."
  waited=0
  while [ "$waited" -lt "$FLUTTER_WAIT_SECONDS" ]; do
    if check_http "$FLUTTER_WEB_URL"; then
      log "Flutter web server is reachable: $FLUTTER_WEB_URL"
      break
    fi
    if ! kill -0 "$FLUTTER_PID" >/dev/null 2>&1; then
      wait "$FLUTTER_PID" || flutter_status=$?
      fail "Flutter exited before the web server became reachable. Exit code: ${flutter_status:-1}"
    fi
    sleep 2
    waited=$((waited + 2))
  done
  if [ "$waited" -ge "$FLUTTER_WAIT_SECONDS" ]; then
    fail "Flutter web server did not become reachable within $FLUTTER_WAIT_SECONDS seconds."
  fi
fi

log "Startup flow completed. Press Ctrl-C to stop all started services. Logs are in $STARTUP_LOG_DIR"
while kill -0 "$FLUTTER_PID" >/dev/null 2>&1; do
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    wait "$BACKEND_PID" || backend_status=$?
    fail "Spring Boot backend exited while Flutter was still running. Exit code: ${backend_status:-1}"
  fi
  sleep 1
done
wait "$FLUTTER_PID"
