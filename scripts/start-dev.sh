#!/usr/bin/env sh
set -eu

# Interactive startup for the Final Assignment project (POSIX sh port of
# start-dev.ps1). One menu pick selects the backend implementation and the
# frontend app, then starts local dependencies (optional), the backend, and the
# frontend.
#
# Backends:
#   spring  - finalAssignmentBackend      (main; REST 8080, WS 8081, DB traffic)
#   go      - final_assignment_backend_go (Gin main app; REST 8080, DB cesi)
#   quarkus - final_assignment_backend_quarkus (Gradle/Quarkus; REST 8080, WS 8081, DB cesi)
#   cloud   - finalAssignmentCloud        (Spring Cloud microservices; gateway 8080)
#   none    - skip the backend
#
# Frontends:
#   flutter - final_assignment_front       (web-server, http://127.0.0.1:3000)
#   react   - final_assignment_front_react (Vite,   http://127.0.0.1:5173)
#   none    - skip the frontend

usage() {
  cat <<'EOF'
Usage: sh scripts/start-dev.sh [-b backend] [-f frontend] [-e] [-h]

Starts:
  1. Local Docker/Ollama environment (unless START_LOCAL_SERVICES=false or -e)
  2. The selected backend implementation
  3. The selected frontend app

Backend choices: spring | go | quarkus | cloud | none
Frontend choices: flutter | react | none

Optional flags:
  -b, --backend <name>   Backend implementation to start (skips the menu).
  -f, --frontend <name>  Frontend app to start (skips the menu).
  -e, --no-env           Skip local Docker/Ollama environment startup.
  -h, --help             Show this usage.

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
  GRADLE_CMD                   Gradle executable (or gradlew path).
  GO_CMD                       Go executable. Default: go
  FLUTTER_CMD                  Flutter executable. Default: flutter
  FLUTTER_DEVICE               Flutter device id. Default: web-server
  FLUTTER_ARGS                 Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
  FLUTTER_WAIT_SECONDS         Flutter web readiness timeout. Default: 120
  FLUTTER_WEB_URL              Flutter web readiness URL. Default: http://127.0.0.1:3000
  NPM_CMD                      npm executable. Default: npm
  REACT_DEV_URL                React dev server readiness URL. Default: http://127.0.0.1:5173
  REACT_ARGS                   Extra npm run dev arguments.
EOF
}

# ---- arg parsing -----------------------------------------------------------
MENU_BACKEND=""
MENU_FRONTEND=""
SKIP_ENV="false"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -b|--backend)
      [ $# -ge 2 ] || { echo "[ERROR] Missing value for $1" >&2; usage; exit 1; }
      MENU_BACKEND="$2"; shift 2 ;;
    -f|--frontend)
      [ $# -ge 2 ] || { echo "[ERROR] Missing value for $1" >&2; usage; exit 1; }
      MENU_FRONTEND="$2"; shift 2 ;;
    -e|--no-env) SKIP_ENV="true"; shift ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/dev-compose.yml"

SPRING_DIR="$ROOT_DIR/finalAssignmentBackend"
GO_DIR="$ROOT_DIR/final_assignment_backend_go"
QUARKUS_DIR="$ROOT_DIR/final_assignment_backend_quarkus"
CLOUD_DIR="$ROOT_DIR/finalAssignmentCloud"
FLUTTER_DIR="$ROOT_DIR/final_assignment_front"
REACT_DIR="$ROOT_DIR/final_assignment_front_react"

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
GRADLE_CMD="${GRADLE_CMD:-}"
GO_CMD="${GO_CMD:-go}"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
FLUTTER_ARGS="${FLUTTER_ARGS:---web-hostname 127.0.0.1 --web-port 3000}"
FLUTTER_WAIT_SECONDS="${FLUTTER_WAIT_SECONDS:-120}"
FLUTTER_WEB_URL="${FLUTTER_WEB_URL:-http://127.0.0.1:3000}"
NPM_CMD="${NPM_CMD:-npm}"
REACT_DEV_URL="${REACT_DEV_URL:-http://127.0.0.1:5173}"
REACT_ARGS="${REACT_ARGS:-}"

if [ "$SKIP_ENV" = "true" ]; then
  START_LOCAL_SERVICES="false"
fi

STARTUP_LOG_ROOT="${STARTUP_LOG_ROOT:-$ROOT_DIR/artifacts/startup}"
STARTUP_RUN_ID="${STARTUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
STARTUP_LOG_DIR="${STARTUP_LOG_DIR:-$STARTUP_LOG_ROOT/$STARTUP_RUN_ID}"
mkdir -p "$STARTUP_LOG_DIR"
export STARTUP_LOG_DIR STARTUP_RUN_ID

STARTUP_LOG="$STARTUP_LOG_DIR/startup.log"
BACKEND_LOG="$STARTUP_LOG_DIR/backend.log"
BACKEND_ERR_LOG="$STARTUP_LOG_DIR/backend.err.log"
FLUTTER_PUB_LOG="$STARTUP_LOG_DIR/flutter-pub-get.log"
FRONTEND_LOG="$STARTUP_LOG_DIR/frontend.log"
FRONTEND_ERR_LOG="$STARTUP_LOG_DIR/frontend.err.log"
ENV_STOP_LOG="$STARTUP_LOG_DIR/environment-stop.log"
OLLAMA_PID_FILE="$STARTUP_LOG_DIR/ollama.pid"

BACKEND_PID=""
FRONTEND_PID=""
CLEANUP_STARTED="false"

log() {
  printf '%s\n' "$*"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$STARTUP_LOG"
}

# ---- interactive menu ------------------------------------------------------
choose_backend() {
  echo ""
  echo "Choose the backend to start:"
  echo "  [0] Spring Boot (main, finalAssignmentBackend) - REST 8080 / WS 8081 / DB traffic"
  echo "  [1] Go / Gin (final_assignment_backend_go) - REST 8080 / DB cesi"
  echo "  [2] Quarkus (final_assignment_backend_quarkus) - REST 8080 / WS 8081 / DB cesi"
  echo "  [3] Spring Cloud microservices (finalAssignmentCloud) - gateway 8080"
  echo "  [4] None (backend only if frontend selected)"
  while :; do
    printf 'Backend (0-4): '
    read -r choice || { echo; exit 1; }
    case "$choice" in
      0) BACKEND_CHOICE="spring"; return ;;
      1) BACKEND_CHOICE="go"; return ;;
      2) BACKEND_CHOICE="quarkus"; return ;;
      3) BACKEND_CHOICE="cloud"; return ;;
      4) BACKEND_CHOICE="none"; return ;;
      *) echo "  Invalid choice. Enter 0-4." ;;
    esac
  done
}

choose_frontend() {
  echo ""
  echo "Choose the frontend to start:"
  echo "  [0] Flutter Web (final_assignment_front) - http://127.0.0.1:3000"
  echo "  [1] React + Vite (final_assignment_front_react) - http://127.0.0.1:5173"
  echo "  [2] None (frontend only if backend selected)"
  while :; do
    printf 'Frontend (0-2): '
    read -r choice || { echo; exit 1; }
    case "$choice" in
      0) FRONTEND_CHOICE="flutter"; return ;;
      1) FRONTEND_CHOICE="react"; return ;;
      2) FRONTEND_CHOICE="none"; return ;;
      *) echo "  Invalid choice. Enter 0-2." ;;
    esac
  done
}

if [ -z "$MENU_BACKEND" ]; then
  choose_backend
else
  BACKEND_CHOICE="$(printf '%s' "$MENU_BACKEND" | tr '[:upper:]' '[:lower:]')"
  case "$BACKEND_CHOICE" in
    spring|go|quarkus|cloud|none) ;;
    *) echo "[ERROR] Unknown backend: $MENU_BACKEND" >&2; usage; exit 1 ;;
  esac
fi

if [ -z "$MENU_FRONTEND" ]; then
  choose_frontend
else
  FRONTEND_CHOICE="$(printf '%s' "$MENU_FRONTEND" | tr '[:upper:]' '[:lower:]')"
  case "$FRONTEND_CHOICE" in
    flutter|react|none) ;;
    *) echo "[ERROR] Unknown frontend: $MENU_FRONTEND" >&2; usage; exit 1 ;;
  esac
fi

if [ "$BACKEND_CHOICE" = "none" ] && [ "$FRONTEND_CHOICE" = "none" ]; then
  echo "[ERROR] You must start at least one of backend or frontend." >&2
  exit 1
fi

# ---- helpers ---------------------------------------------------------------
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
    lsof -nP -iTCP:"$BACKEND_PORT" -iTCP:8081 -iTCP:3000 -iTCP:5173 -sTCP:LISTEN >&2 || true
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
  tail_file "$FRONTEND_LOG" 120
  tail_file "$FRONTEND_ERR_LOG" 120
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
  if [ -n "$FRONTEND_PID" ] && kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
    log "Stopping frontend ($FRONTEND_CHOICE) process tree at PID $FRONTEND_PID..."
    kill_tree "$FRONTEND_PID"
  fi
  if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    log "Stopping backend ($BACKEND_CHOICE) process tree at PID $BACKEND_PID..."
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
Backend choice: $BACKEND_CHOICE
Frontend choice: $FRONTEND_CHOICE
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
REACT_DEV_URL=$REACT_DEV_URL
EOF

# ---- backend launchers -----------------------------------------------------
start_backend() {
  case "$BACKEND_CHOICE" in
    spring)
      [ -f "$SPRING_DIR/pom.xml" ] || fail "Spring Boot project not found: $SPRING_DIR"
      require_command "$MVN_CMD"
      (
        cd "$SPRING_DIR"
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
      ;;
    go)
      [ -f "$GO_DIR/go.mod" ] || fail "Go project not found: $GO_DIR"
      require_command "$GO_CMD"
      (
        cd "$GO_DIR"
        export REDIS_HOST=localhost REDIS_PORT=6379 REDIS_ENABLED=false
        export KAFKA_BOOTSTRAP_SERVERS=localhost:9092 ELASTICSEARCH_URL=http://localhost:9200
        export GO_DOCKER_SERVICES_ENABLED=false
        "$GO_CMD" run ./project/cmd/app
      ) >"$BACKEND_LOG" 2>"$BACKEND_ERR_LOG" &
      BACKEND_PID=$!
      ;;
    quarkus)
      [ -f "$QUARKUS_DIR/build.gradle" ] || fail "Quarkus project not found: $QUARKUS_DIR"
      gradle_cmd="$GRADLE_CMD"
      if [ -z "$gradle_cmd" ]; then
        if [ -x "$QUARKUS_DIR/gradlew" ]; then
          gradle_cmd="$QUARKUS_DIR/gradlew"
        elif command -v gradle >/dev/null 2>&1; then
          gradle_cmd="gradle"
        else
          fail "Gradle not found. Set GRADLE_CMD to the gradlew/gradle path."
        fi
      fi
      db_user="${SPRING_DATASOURCE_USERNAME:-root}"
      db_password="${SPRING_DATASOURCE_PASSWORD:-root}"
      (
        cd "$QUARKUS_DIR"
        export QUARKUS_DEV_SERVICES_ENABLED=false
        export QUARKUS_LANGCHAIN4J_OLLAMA_DEVSERVICES_ENABLED=false
        export QUARKUS_HTTP_PORT=8080
        export NETWORK_SERVER_PORT=8081
        export BACKEND_URL=http://127.0.0.1
        export BACKEND_PORT=8080
        export JWT_SECRET
        export QUARKUS_DATASOURCE_JDBC_URL="jdbc:mysql://localhost:3306/cesi?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
        export QUARKUS_DATASOURCE_USERNAME="$db_user"
        export QUARKUS_DATASOURCE_PASSWORD="$db_password"
        export QUARKUS_REDIS_HOSTS=redis://localhost:6379
        export QUARKUS_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
        export ELASTICSEARCH_HOST=http://localhost:9200
        "$gradle_cmd" quarkusDev
      ) >"$BACKEND_LOG" 2>"$BACKEND_ERR_LOG" &
      BACKEND_PID=$!
      ;;
    cloud)
      [ -f "$CLOUD_DIR/pom.xml" ] || fail "Spring Cloud project not found: $CLOUD_DIR"
      require_command "$MVN_CMD"
      (
        cd "$CLOUD_DIR"
        "$MVN_CMD" -pl finalassignmentcloud-gateway -am spring-boot:run "-Dspring-boot.run.profiles=$BACKEND_PROFILE"
      ) >"$BACKEND_LOG" 2>"$BACKEND_ERR_LOG" &
      BACKEND_PID=$!
      ;;
    none)
      BACKEND_PID=""
      ;;
    *)
      fail "Unsupported backend: $BACKEND_CHOICE"
      ;;
  esac
}

# ---- frontend launchers ----------------------------------------------------
start_frontend() {
  case "$FRONTEND_CHOICE" in
    flutter)
      [ -f "$FLUTTER_DIR/pubspec.yaml" ] || fail "Flutter project not found: $FLUTTER_DIR"
      require_command "$FLUTTER_CMD"
      log "Resolving Flutter dependencies..."
      if ! (cd "$FLUTTER_DIR" && "$FLUTTER_CMD" pub get >"$FLUTTER_PUB_LOG" 2>&1); then
        tail_file "$FLUTTER_PUB_LOG" 120
        fail "flutter pub get failed."
      fi
      log "flutter pub get completed. Log: $FLUTTER_PUB_LOG"
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
      ) >"$FRONTEND_LOG" 2>"$FRONTEND_ERR_LOG" &
      FRONTEND_PID=$!
      ;;
    react)
      [ -f "$REACT_DIR/package.json" ] || fail "React project not found: $REACT_DIR"
      require_command "$NPM_CMD"
      if [ ! -d "$REACT_DIR/node_modules" ]; then
        log "React node_modules not found. Running npm install..."
        if ! (cd "$REACT_DIR" && "$NPM_CMD" install) >"$FRONTEND_LOG" 2>"$FRONTEND_ERR_LOG"; then
          tail_file "$FRONTEND_LOG" 120
          tail_file "$FRONTEND_ERR_LOG" 120
          fail "npm install failed."
        fi
        log "npm install completed."
      fi
      (
        cd "$REACT_DIR"
        # shellcheck disable=SC2086
        "$NPM_CMD" run dev -- --host 127.0.0.1 --port 5173 ${REACT_ARGS:-}
      ) >"$FRONTEND_LOG" 2>"$FRONTEND_ERR_LOG" &
      FRONTEND_PID=$!
      ;;
    none)
      FRONTEND_PID=""
      ;;
    *)
      fail "Unsupported frontend: $FRONTEND_CHOICE"
      ;;
  esac
}

# ---- main flow -------------------------------------------------------------

# Backend health mapping per implementation
HEALTH_URL="$BACKEND_HEALTH_URL"
case "$BACKEND_CHOICE" in
  go) HEALTH_URL="http://127.0.0.1:$BACKEND_PORT/api/actuator/health" ;;
  quarkus) HEALTH_URL="http://127.0.0.1:8080/q/openapi" ;;
  cloud) HEALTH_URL="http://127.0.0.1:8080/actuator/health" ;;
esac

if [ "$START_LOCAL_SERVICES" = "true" ] && { [ "$BACKEND_CHOICE" != "none" ] || [ "$FRONTEND_CHOICE" != "none" ]; }; then
  log "Starting local Docker/Ollama environment..."
  if ! sh "$SCRIPT_DIR/start-env.sh"; then
    fail "Local Docker/Ollama environment startup failed."
  fi
else
  log "Skipping local Docker/Ollama environment because START_LOCAL_SERVICES=false."
fi

if [ "$BACKEND_CHOICE" != "none" ]; then
  log "Starting backend ($BACKEND_CHOICE)..."
  start_backend
  log "Backend PID: $BACKEND_PID"
  log "Backend stdout: $BACKEND_LOG"
  log "Backend stderr: $BACKEND_ERR_LOG"
  log "Waiting $BACKEND_WAIT_SECONDS seconds before backend health polling..."
  sleep "$BACKEND_WAIT_SECONDS"

  log "Waiting up to $BACKEND_HEALTH_WAIT_SECONDS seconds for $HEALTH_URL..."
  waited=0
  healthy="false"
  while [ "$waited" -lt "$BACKEND_HEALTH_WAIT_SECONDS" ]; do
    if check_http "$HEALTH_URL"; then
      log "Backend ($BACKEND_CHOICE) is healthy."
      healthy="true"
      break
    fi
    if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      wait "$BACKEND_PID" || backend_status=$?
      fail "Backend ($BACKEND_CHOICE) exited before becoming healthy. Exit code: ${backend_status:-1}"
    fi
    sleep 2
    waited=$((waited + 2))
  done
  if [ "$healthy" != "true" ]; then
    fail "Backend ($BACKEND_CHOICE) did not become healthy within $BACKEND_HEALTH_WAIT_SECONDS seconds at $HEALTH_URL."
  fi
fi

if [ "$FRONTEND_CHOICE" != "none" ]; then
  log "Starting frontend ($FRONTEND_CHOICE)..."
  start_frontend
  log "Frontend PID: $FRONTEND_PID"
  log "Frontend stdout: $FRONTEND_LOG"
  log "Frontend stderr: $FRONTEND_ERR_LOG"

  if [ "$FRONTEND_CHOICE" = "flutter" ] && [ "$FLUTTER_DEVICE" = "web-server" ]; then
    log "Waiting up to $FLUTTER_WAIT_SECONDS seconds for $FLUTTER_WEB_URL..."
    waited=0
    reachable="false"
    while [ "$waited" -lt "$FLUTTER_WAIT_SECONDS" ]; do
      if check_http "$FLUTTER_WEB_URL"; then
        log "Flutter web server is reachable: $FLUTTER_WEB_URL"
        reachable="true"
        break
      fi
      if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
        wait "$FRONTEND_PID" || frontend_status=$?
        fail "Frontend exited before the web server became reachable. Exit code: ${frontend_status:-1}"
      fi
      sleep 2
      waited=$((waited + 2))
    done
    if [ "$reachable" != "true" ]; then
      fail "Flutter web server did not become reachable within $FLUTTER_WAIT_SECONDS seconds."
    fi
  elif [ "$FRONTEND_CHOICE" = "react" ]; then
    log "Waiting up to $FLUTTER_WAIT_SECONDS seconds for $REACT_DEV_URL..."
    waited=0
    reachable="false"
    while [ "$waited" -lt "$FLUTTER_WAIT_SECONDS" ]; do
      if check_http "$REACT_DEV_URL"; then
        log "React dev server is reachable: $REACT_DEV_URL"
        reachable="true"
        break
      fi
      if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
        wait "$FRONTEND_PID" || frontend_status=$?
        fail "Frontend exited before the dev server became reachable. Exit code: ${frontend_status:-1}"
      fi
      sleep 2
      waited=$((waited + 2))
    done
    if [ "$reachable" != "true" ]; then
      fail "React dev server did not become reachable within $FLUTTER_WAIT_SECONDS seconds."
    fi
  fi
fi

log "Startup flow completed. Press Ctrl-C to stop all started services. Logs are in $STARTUP_LOG_DIR"

if [ -n "$BACKEND_PID" ] && [ -n "$FRONTEND_PID" ]; then
  while kill -0 "$FRONTEND_PID" >/dev/null 2>&1; do
    if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      wait "$BACKEND_PID" || backend_status=$?
      fail "Backend ($BACKEND_CHOICE) exited while frontend was still running. Exit code: ${backend_status:-1}"
    fi
    sleep 1
  done
  wait "$FRONTEND_PID"
elif [ -n "$BACKEND_PID" ]; then
  wait "$BACKEND_PID"
elif [ -n "$FRONTEND_PID" ]; then
  wait "$FRONTEND_PID"
fi
