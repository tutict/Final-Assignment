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
  BACKEND_PORT                 Go backend port. Default: 8080; auto-falls back when unavailable unless explicitly set
  GO_BACKEND_FALLBACK_PORTS    Go backend fallback ports. Default: 18080 18081 18082
  BACKEND_WAIT_SECONDS         Initial delay before health polling. Default: 8
  BACKEND_HEALTH_WAIT_SECONDS  Backend health timeout. Default: 120
  BACKEND_HEALTH_URL           Health URL. Default: http://127.0.0.1:8080/actuator/health
  DB_URL, DB_USERNAME, DB_PASSWORD  Short aliases used when SPRING_DATASOURCE_* is unset.
  REDPANDA_KAFKA_HOST_PORT     Redpanda Kafka host port. Default: 9092, auto-falls back when unavailable
  REDPANDA_KAFKA_FALLBACK_PORTS Fallback Kafka host ports. Default: 19092 19093 19094
  APP_ENV                      Flutter APP_ENV dart define. Default: dev
  API_BASE_URL                 Flutter API base URL. Default: http://localhost:8080
  WS_BASE_URL                  Flutter WebSocket URL. Default: ws://localhost:8081
  MVN_CMD                      Maven executable. Default: mvn
  GRADLE_CMD                   Gradle executable (or gradlew path).
  GO_CMD                       Go executable. Default: go
  GOCACHE                      Go build cache path. Default: artifacts/go-build-cache
  FLUTTER_CMD                  Flutter executable. Default: flutter
  FLUTTER_DEVICE               Flutter device id. Default: web-server
  FLUTTER_ARGS                 Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
  FRONTEND_WAIT_SECONDS        Frontend readiness timeout. Default: FLUTTER_WAIT_SECONDS or 120
  FLUTTER_WAIT_SECONDS         Legacy frontend readiness timeout. Default: 120
  FLUTTER_WEB_URL              Flutter web readiness URL. Default: http://127.0.0.1:3000
  NPM_CMD                      npm executable. Default: npm
  REACT_DEV_URL                React dev server readiness URL. Default: http://127.0.0.1:5173
  REACT_API_BASE_URL           React API base URL. Default: selected backend target
  REACT_WS_BASE_URL            React WebSocket base URL. Default: selected backend target
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
if [ -n "${SPRING_KAFKA_BOOTSTRAP_SERVERS:-}" ]; then
  SPRING_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="true"
else
  SPRING_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="false"
fi
if [ -n "${KAFKA_BOOTSTRAP_SERVERS:-}" ]; then
  KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="true"
else
  KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="false"
fi
if [ -n "${QUARKUS_KAFKA_BOOTSTRAP_SERVERS:-}" ]; then
  QUARKUS_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="true"
else
  QUARKUS_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT="false"
fi
if [ -n "${REDPANDA_KAFKA_HOST_PORT:-}" ]; then
  REDPANDA_KAFKA_HOST_PORT_EXPLICIT="true"
else
  REDPANDA_KAFKA_HOST_PORT_EXPLICIT="false"
fi
REDPANDA_KAFKA_HOST_PORT="${REDPANDA_KAFKA_HOST_PORT:-9092}"
REDPANDA_KAFKA_FALLBACK_PORTS="${REDPANDA_KAFKA_FALLBACK_PORTS:-19092 19093 19094}"
SPRING_KAFKA_BOOTSTRAP_SERVERS="${SPRING_KAFKA_BOOTSTRAP_SERVERS:-localhost:$REDPANDA_KAFKA_HOST_PORT}"
KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:$REDPANDA_KAFKA_HOST_PORT}"
QUARKUS_KAFKA_BOOTSTRAP_SERVERS="${QUARKUS_KAFKA_BOOTSTRAP_SERVERS:-localhost:$REDPANDA_KAFKA_HOST_PORT}"
APP_ENV="${APP_ENV:-dev}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
WS_BASE_URL="${WS_BASE_URL:-ws://localhost:8081}"
if [ -n "${BACKEND_PORT:-}" ]; then
  BACKEND_PORT_EXPLICIT="true"
else
  BACKEND_PORT_EXPLICIT="false"
fi
BACKEND_PORT="${BACKEND_PORT:-8080}"
GO_BACKEND_FALLBACK_PORTS="${GO_BACKEND_FALLBACK_PORTS:-18080 18081 18082}"
BACKEND_WAIT_SECONDS="${BACKEND_WAIT_SECONDS:-8}"
BACKEND_HEALTH_WAIT_SECONDS="${BACKEND_HEALTH_WAIT_SECONDS:-120}"
if [ -n "${BACKEND_HEALTH_URL:-}" ]; then
  BACKEND_HEALTH_URL_EXPLICIT="true"
else
  BACKEND_HEALTH_URL_EXPLICIT="false"
fi
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://127.0.0.1:$BACKEND_PORT/actuator/health}"
MVN_CMD="${MVN_CMD:-mvn}"
GRADLE_CMD="${GRADLE_CMD:-}"
GO_CMD="${GO_CMD:-go}"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
FLUTTER_ARGS="${FLUTTER_ARGS:---web-hostname 127.0.0.1 --web-port 3000}"
FLUTTER_WAIT_SECONDS="${FLUTTER_WAIT_SECONDS:-120}"
FRONTEND_WAIT_SECONDS="${FRONTEND_WAIT_SECONDS:-$FLUTTER_WAIT_SECONDS}"
FLUTTER_WEB_URL="${FLUTTER_WEB_URL:-http://127.0.0.1:3000}"
OPEN_BROWSER="${OPEN_BROWSER:-true}"
if [ -n "${BROWSER_URL:-}" ]; then
  BROWSER_URL_EXPLICIT="true"
else
  BROWSER_URL_EXPLICIT="false"
  BROWSER_URL=""
fi
NPM_CMD="${NPM_CMD:-npm}"
REACT_DEV_URL="${REACT_DEV_URL:-http://127.0.0.1:5173}"
if [ -n "${REACT_API_BASE_URL:-}" ]; then
  REACT_API_BASE_URL_EXPLICIT="true"
elif [ -n "${VITE_API_BASE_URL:-}" ]; then
  REACT_API_BASE_URL_EXPLICIT="true"
  REACT_API_BASE_URL="$VITE_API_BASE_URL"
else
  REACT_API_BASE_URL_EXPLICIT="false"
  REACT_API_BASE_URL=""
fi
if [ -n "${REACT_WS_BASE_URL:-}" ]; then
  REACT_WS_BASE_URL_EXPLICIT="true"
elif [ -n "${VITE_WS_BASE_URL:-}" ]; then
  REACT_WS_BASE_URL_EXPLICIT="true"
  REACT_WS_BASE_URL="$VITE_WS_BASE_URL"
else
  REACT_WS_BASE_URL_EXPLICIT="false"
  REACT_WS_BASE_URL=""
fi
REACT_ARGS="${REACT_ARGS:-}"
REDPANDA_KAFKA_PORT_NOTICE=""
GO_BACKEND_PORT_NOTICE=""

if [ "$SKIP_ENV" = "true" ]; then
  START_LOCAL_SERVICES="false"
fi

STARTUP_LOG_ROOT="${STARTUP_LOG_ROOT:-$ROOT_DIR/artifacts/startup}"
STARTUP_RUN_ID="${STARTUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
STARTUP_LOG_DIR="${STARTUP_LOG_DIR:-$STARTUP_LOG_ROOT/$STARTUP_RUN_ID}"
mkdir -p "$STARTUP_LOG_DIR"
export STARTUP_LOG_DIR STARTUP_RUN_ID
GOCACHE="${GOCACHE:-$ROOT_DIR/artifacts/go-build-cache}"
mkdir -p "$GOCACHE"
export GOCACHE
GO_BACKEND_BINARY="$STARTUP_LOG_DIR/go-backend"
export GO_BACKEND_BINARY

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

# Validate any flag-provided values first (fail fast, before prompting).
if [ -n "$MENU_BACKEND" ]; then
  BACKEND_CHOICE="$(printf '%s' "$MENU_BACKEND" | tr '[:upper:]' '[:lower:]')"
  case "$BACKEND_CHOICE" in
    spring|go|quarkus|cloud|none) ;;
    *) echo "[ERROR] Unknown backend: $MENU_BACKEND" >&2; usage; exit 1 ;;
  esac
fi
if [ -n "$MENU_FRONTEND" ]; then
  FRONTEND_CHOICE="$(printf '%s' "$MENU_FRONTEND" | tr '[:upper:]' '[:lower:]')"
  case "$FRONTEND_CHOICE" in
    flutter|react|none) ;;
    *) echo "[ERROR] Unknown frontend: $MENU_FRONTEND" >&2; usage; exit 1 ;;
  esac
fi

# Prompt only for whatever was not provided via flags.
if [ -z "$MENU_BACKEND" ]; then
  choose_backend
fi
if [ -z "$MENU_FRONTEND" ]; then
  choose_frontend
fi

if [ "$BACKEND_CHOICE" = "none" ] && [ "$FRONTEND_CHOICE" = "none" ]; then
  echo "[ERROR] You must start at least one of backend or frontend." >&2
  exit 1
fi

update_frontend_routing_defaults() {
  case "$BACKEND_CHOICE" in
    go)
      default_react_api_base_url="http://127.0.0.1:$BACKEND_PORT"
      default_react_ws_base_url="ws://127.0.0.1:$BACKEND_PORT"
      ;;
    cloud)
      default_react_api_base_url="http://127.0.0.1:8080"
      default_react_ws_base_url="ws://127.0.0.1:8080"
      ;;
    *)
      default_react_api_base_url="http://127.0.0.1:8081"
      default_react_ws_base_url="ws://127.0.0.1:8081"
      ;;
  esac
  if [ "$REACT_API_BASE_URL_EXPLICIT" != "true" ]; then
    REACT_API_BASE_URL="$default_react_api_base_url"
  fi
  if [ "$REACT_WS_BASE_URL_EXPLICIT" != "true" ]; then
    REACT_WS_BASE_URL="$default_react_ws_base_url"
  fi
  export FRONTEND_URL FLUTTER_URL BROWSER_URL REACT_API_BASE_URL REACT_WS_BASE_URL REDPANDA_KAFKA_HOST_PORT BACKEND_PORT BACKEND_HEALTH_URL
}

FRONTEND_ORIGIN=""
FRONTEND_URL="${FRONTEND_URL:-}"
FLUTTER_URL="${FLUTTER_URL:-}"
case "$FRONTEND_CHOICE" in
  react)
    FRONTEND_ORIGIN="$REACT_DEV_URL"
    FRONTEND_URL="${FRONTEND_URL:-$FRONTEND_ORIGIN}"
    ;;
  flutter)
    FRONTEND_ORIGIN="$FLUTTER_WEB_URL"
    FRONTEND_URL="${FRONTEND_URL:-$FRONTEND_ORIGIN}"
    FLUTTER_URL="${FLUTTER_URL:-$FLUTTER_WEB_URL}"
    ;;
esac

if [ "$BROWSER_URL_EXPLICIT" != "true" ] && [ -n "$FRONTEND_ORIGIN" ]; then
  BROWSER_URL="$FRONTEND_ORIGIN"
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

backend_listen_ports() {
  case "$BACKEND_CHOICE" in
    go) printf '%s\n' "$BACKEND_PORT" ;;
    spring|quarkus) printf '%s\n%s\n' 8080 8081 ;;
    cloud) printf '%s\n' 8080 ;;
  esac
}

describe_port_listeners() {
  port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
  elif command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | awk -v port=":$port" '$4 ~ port "($|[^0-9])" { print }'
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an 2>/dev/null | awk -v port=":$port" '$0 ~ port "[[:space:]]" && $0 ~ /LISTEN/ { print }'
  fi
}

set_backend_port() {
  BACKEND_PORT="$1"
  export BACKEND_PORT
  if [ "$BACKEND_HEALTH_URL_EXPLICIT" != "true" ]; then
    BACKEND_HEALTH_URL="http://127.0.0.1:$BACKEND_PORT/actuator/health"
    export BACKEND_HEALTH_URL
  fi
}

resolve_go_backend_port() {
  [ "$BACKEND_CHOICE" = "go" ] || return 0
  [ "$BACKEND_PORT_EXPLICIT" != "true" ] || return 0

  initial_port="$BACKEND_PORT"
  if port_bindable "$initial_port"; then
    set_backend_port "$initial_port"
    return 0
  fi

  listeners="$(describe_port_listeners "$initial_port")"
  [ -z "$listeners" ] || return 0

  for candidate in $(printf '%s' "$GO_BACKEND_FALLBACK_PORTS" | tr ',;' '  '); do
    case "$candidate" in
      ''|*[!0-9]*) continue ;;
    esac
    if port_bindable "$candidate"; then
      set_backend_port "$candidate"
      GO_BACKEND_PORT_NOTICE="Go backend port $initial_port is not bindable and has no listening process; using $BACKEND_PORT instead."
      return 0
    fi
  done
}

effective_backend_health_url() {
  case "$BACKEND_CHOICE" in
    go) printf 'http://127.0.0.1:%s/api/actuator/health\n' "$BACKEND_PORT" ;;
    quarkus) printf '%s\n' 'http://127.0.0.1:8080/q/openapi' ;;
    cloud) printf '%s\n' 'http://127.0.0.1:8080/actuator/health' ;;
    *) printf '%s\n' "$BACKEND_HEALTH_URL" ;;
  esac
}

assert_backend_ports_available() {
  backend_listen_ports | while IFS= read -r port; do
    case "$port" in
      ''|*[!0-9]*) continue ;;
    esac
    if port_bindable "$port"; then
      continue
    fi

    listeners=$(describe_port_listeners "$port")
    if [ -n "$listeners" ]; then
      printf '%s\n' "$listeners" | while IFS= read -r line; do
        log "Backend port $port is already in use before starting $BACKEND_CHOICE: $line"
      done
    else
      log "Backend port $port is not bindable, but no listening process was found. It may be reserved by the OS."
    fi
    fail "Backend port $port is unavailable before starting backend ($BACKEND_CHOICE). Stop that process first, or choose -b none if you intentionally want to reuse an existing backend."
  done
}

redpanda_container_running() {
  if ! command -v docker >/dev/null 2>&1; then
    return 1
  fi
  [ "$(docker inspect -f '{{.State.Running}}' final-assignment-redpanda 2>/dev/null || true)" = "true" ]
}

redpanda_kafka_published_port() {
  if ! command -v docker >/dev/null 2>&1; then
    return 0
  fi
  docker port final-assignment-redpanda 9092/tcp 2>/dev/null | awk -F: 'NF > 1 { print $NF; exit }'
}

set_kafka_bootstrap_defaults() {
  port="$1"
  if [ "$SPRING_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT" != "true" ]; then
    SPRING_KAFKA_BOOTSTRAP_SERVERS="localhost:$port"
  fi
  if [ "$KAFKA_BOOTSTRAP_SERVERS_EXPLICIT" != "true" ]; then
    KAFKA_BOOTSTRAP_SERVERS="localhost:$port"
  fi
  if [ "$QUARKUS_KAFKA_BOOTSTRAP_SERVERS_EXPLICIT" != "true" ]; then
    QUARKUS_KAFKA_BOOTSTRAP_SERVERS="localhost:$port"
  fi
  export SPRING_KAFKA_BOOTSTRAP_SERVERS KAFKA_BOOTSTRAP_SERVERS QUARKUS_KAFKA_BOOTSTRAP_SERVERS
}

use_redpanda_kafka_host_port() {
  REDPANDA_KAFKA_HOST_PORT="$1"
  export REDPANDA_KAFKA_HOST_PORT
  set_kafka_bootstrap_defaults "$REDPANDA_KAFKA_HOST_PORT"
}

resolve_redpanda_kafka_host_port() {
  if [ "$START_LOCAL_SERVICES" != "true" ]; then
    return 0
  fi
  if [ "$REDPANDA_KAFKA_HOST_PORT_EXPLICIT" = "true" ]; then
    set_kafka_bootstrap_defaults "$REDPANDA_KAFKA_HOST_PORT"
    return 0
  fi
  if redpanda_container_running; then
    published_port=$(redpanda_kafka_published_port)
    if [ -n "$published_port" ]; then
      configured_port="$REDPANDA_KAFKA_HOST_PORT"
      use_redpanda_kafka_host_port "$published_port"
      if [ "$published_port" != "$configured_port" ]; then
        REDPANDA_KAFKA_PORT_NOTICE="Using existing Redpanda Kafka host port $published_port from the running final-assignment-redpanda container."
      fi
    else
      set_kafka_bootstrap_defaults "$REDPANDA_KAFKA_HOST_PORT"
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
      REDPANDA_KAFKA_PORT_NOTICE="Redpanda Kafka host port $initial_port is not available; using $REDPANDA_KAFKA_HOST_PORT instead."
      return 0
    fi
  done

  fail "Redpanda Kafka host port $initial_port is not available, and no fallback ports are bindable. Set REDPANDA_KAFKA_HOST_PORT to a free port."
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

backend_started_by_this_run() {
  [ "$BACKEND_CHOICE" = "go" ] || return 0
  marker="Go backend started on http://localhost:$BACKEND_PORT"
  grep -F "$marker" "$BACKEND_LOG" "$BACKEND_ERR_LOG" >/dev/null 2>&1
}

open_frontend_in_browser() {
  if [ "$OPEN_BROWSER" != "true" ]; then
    log "Skipping browser launch because OPEN_BROWSER=$OPEN_BROWSER."
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "$BROWSER_URL" >/dev/null 2>&1 &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$BROWSER_URL" >/dev/null 2>&1 &
  elif command -v wslview >/dev/null 2>&1; then
    wslview "$BROWSER_URL" >/dev/null 2>&1 &
  else
    log "Frontend is ready at $BROWSER_URL. No browser launcher was found."
    return 0
  fi
  log "Opened frontend in the default browser: $BROWSER_URL"
}

# Lightweight port occupancy probe used before starting the Flutter web server.
# The POSIX script deliberately does not auto-kill the holder: identifying a
# stale Flutter process from a command line is unreliable across platforms
# (Git Bash, WSL, macOS) and could take down an unrelated service. On Windows
# the start-dev.ps1 path performs the safe command-line-scoped cleanup.
warn_if_port_in_use() {
  port="$1"
  if command -v lsof >/dev/null 2>&1; then
    holder=$(lsof -t "tcp:$port" 2>/dev/null | head -n 1 || true)
    if [ -n "$holder" ]; then
      log "Port $port is already in use (PID $holder). Flutter web startup may fail. On Windows, start-dev.ps1 will clear stale Flutter hold-backs; otherwise free the port first."
    fi
  elif command -v ss >/dev/null 2>&1; then
    if ss -ltn | grep -q ":$port "; then
      log "Port $port is already in use. Flutter web startup may fail. On Windows, start-dev.ps1 will clear stale Flutter hold-backs; otherwise free the port first."
    fi
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

resolve_redpanda_kafka_host_port
resolve_go_backend_port
update_frontend_routing_defaults
EFFECTIVE_BACKEND_HEALTH_URL="$(effective_backend_health_url)"

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
BACKEND_PORT=$BACKEND_PORT
BACKEND_PORT_EXPLICIT=$BACKEND_PORT_EXPLICIT
GO_BACKEND_FALLBACK_PORTS=$GO_BACKEND_FALLBACK_PORTS
GOCACHE=$GOCACHE
GO_BACKEND_BINARY=$GO_BACKEND_BINARY
BACKEND_HEALTH_URL=$BACKEND_HEALTH_URL
EFFECTIVE_BACKEND_HEALTH_URL=$EFFECTIVE_BACKEND_HEALTH_URL
FRONTEND_WAIT_SECONDS=$FRONTEND_WAIT_SECONDS
SPRING_DATASOURCE_URL=$SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME=$SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD=<redacted>
SPRING_DATA_REDIS_HOST=$SPRING_DATA_REDIS_HOST
SPRING_DATA_REDIS_PORT=$SPRING_DATA_REDIS_PORT
REDPANDA_KAFKA_HOST_PORT=$REDPANDA_KAFKA_HOST_PORT
REDPANDA_KAFKA_HOST_PORT_EXPLICIT=$REDPANDA_KAFKA_HOST_PORT_EXPLICIT
REDPANDA_KAFKA_FALLBACK_PORTS=$REDPANDA_KAFKA_FALLBACK_PORTS
SPRING_KAFKA_BOOTSTRAP_SERVERS=$SPRING_KAFKA_BOOTSTRAP_SERVERS
KAFKA_BOOTSTRAP_SERVERS=$KAFKA_BOOTSTRAP_SERVERS
QUARKUS_KAFKA_BOOTSTRAP_SERVERS=$QUARKUS_KAFKA_BOOTSTRAP_SERVERS
APP_ENV=$APP_ENV
API_BASE_URL=$API_BASE_URL
WS_BASE_URL=$WS_BASE_URL
FRONTEND_URL=$FRONTEND_URL
FLUTTER_URL=$FLUTTER_URL
FLUTTER_DEVICE=$FLUTTER_DEVICE
FLUTTER_ARGS=$FLUTTER_ARGS
FLUTTER_WAIT_SECONDS=$FLUTTER_WAIT_SECONDS
FLUTTER_WEB_URL=$FLUTTER_WEB_URL
REACT_DEV_URL=$REACT_DEV_URL
REACT_API_BASE_URL=$REACT_API_BASE_URL
REACT_API_BASE_URL_EXPLICIT=$REACT_API_BASE_URL_EXPLICIT
REACT_WS_BASE_URL=$REACT_WS_BASE_URL
REACT_WS_BASE_URL_EXPLICIT=$REACT_WS_BASE_URL_EXPLICIT
BROWSER_URL=$BROWSER_URL
BROWSER_URL_EXPLICIT=$BROWSER_URL_EXPLICIT
EOF

if [ -n "$REDPANDA_KAFKA_PORT_NOTICE" ]; then
  log "$REDPANDA_KAFKA_PORT_NOTICE"
fi
if [ -n "$GO_BACKEND_PORT_NOTICE" ]; then
  log "$GO_BACKEND_PORT_NOTICE"
fi

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
        export KAFKA_BOOTSTRAP_SERVERS ELASTICSEARCH_URL=http://localhost:9200
        export GO_DOCKER_SERVICES_ENABLED=false
        export PORT="$BACKEND_PORT"
        export GOCACHE
        "$GO_CMD" build -o "$GO_BACKEND_BINARY" ./project/cmd/app
        exec "$GO_BACKEND_BINARY"
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
        export JWT_SECRET_KEY="${JWT_SECRET_KEY:-$JWT_SECRET}"
        export QUARKUS_DATASOURCE_JDBC_URL="jdbc:mysql://localhost:3306/cesi?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
        export QUARKUS_DATASOURCE_USERNAME="$db_user"
        export QUARKUS_DATASOURCE_PASSWORD="$db_password"
        export QUARKUS_REDIS_HOSTS=redis://localhost:6379
        export KAFKA_BOOTSTRAP_SERVERS
        export QUARKUS_KAFKA_BOOTSTRAP_SERVERS
        export ELASTICSEARCH_HOST=http://localhost:9200
        export JWT_ML_DSA_PRIVATE_KEY="${JWT_ML_DSA_PRIVATE_KEY:- }"
        export JWT_ML_DSA_PUBLIC_KEY="${JWT_ML_DSA_PUBLIC_KEY:- }"
        export JWT_ML_KEM_PRIVATE_KEY="${JWT_ML_KEM_PRIVATE_KEY:- }"
        export JWT_ML_KEM_PUBLIC_KEY="${JWT_ML_KEM_PUBLIC_KEY:- }"
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
      # Warn before `flutter run` binds so a stale holder is surfaced instead of a
      # cryptic bind failure. (Auto-cleanup is handled by the Windows .ps1 path.)
      if [ "$FLUTTER_DEVICE" = "web-server" ]; then
        case "$FLUTTER_ARGS" in
          *--web-port=*) fw_port="${FLUTTER_ARGS##*--web-port=}"; fw_port="${fw_port%%[^0-9]*}" ;;
          *) fw_port="3000" ;;
        esac
        warn_if_port_in_use "$fw_port"
      fi
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
      log "React API base URL: $REACT_API_BASE_URL"
      log "React WebSocket base URL: $REACT_WS_BASE_URL"
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
        export VITE_API_BASE_URL="$REACT_API_BASE_URL"
        export VITE_WS_BASE_URL="$REACT_WS_BASE_URL"
        # shellcheck disable=SC2086
        "$NPM_CMD" run dev -- --host 127.0.0.1 --port 5173 --strictPort ${REACT_ARGS:-}
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

HEALTH_URL="$(effective_backend_health_url)"

if [ "$BACKEND_CHOICE" != "none" ]; then
  assert_backend_ports_available
fi

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
    if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      wait "$BACKEND_PID" || backend_status=$?
      fail "Backend ($BACKEND_CHOICE) exited before becoming healthy. Exit code: ${backend_status:-1}"
    fi
    if check_http "$HEALTH_URL" && backend_started_by_this_run; then
      sleep 1
      if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
        wait "$BACKEND_PID" || backend_status=$?
        fail "Backend ($BACKEND_CHOICE) exited immediately after health check succeeded. Exit code: ${backend_status:-1}"
      fi
      log "Backend ($BACKEND_CHOICE) is healthy."
      healthy="true"
      break
    fi
    sleep 2
    waited=$((waited + 2))
  done
  if [ "$healthy" != "true" ]; then
    fail "Backend ($BACKEND_CHOICE) did not become healthy within $BACKEND_HEALTH_WAIT_SECONDS seconds at $HEALTH_URL."
  fi
fi

if [ "$FRONTEND_CHOICE" != "none" ]; then
  log "Browser URL: $BROWSER_URL"
  log "Starting frontend ($FRONTEND_CHOICE)..."
  start_frontend
  log "Frontend PID: $FRONTEND_PID"
  log "Frontend stdout: $FRONTEND_LOG"
  log "Frontend stderr: $FRONTEND_ERR_LOG"
  sleep 1
  if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
    wait "$FRONTEND_PID" || frontend_status=$?
    fail "Frontend ($FRONTEND_CHOICE) exited immediately after launch. Exit code: ${frontend_status:-1}"
  fi

  if [ "$FRONTEND_CHOICE" = "flutter" ] && [ "$FLUTTER_DEVICE" = "web-server" ]; then
    log "Waiting up to $FRONTEND_WAIT_SECONDS seconds for $FLUTTER_WEB_URL..."
    waited=0
    reachable="false"
    while [ "$waited" -lt "$FRONTEND_WAIT_SECONDS" ]; do
      if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
        wait "$FRONTEND_PID" || frontend_status=$?
        fail "Frontend exited before the web server became reachable. Exit code: ${frontend_status:-1}"
      fi
      if check_http "$FLUTTER_WEB_URL"; then
        sleep 1
        if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
          wait "$FRONTEND_PID" || frontend_status=$?
          fail "Frontend exited immediately after readiness check succeeded. Exit code: ${frontend_status:-1}"
        fi
        log "Flutter web server is reachable: $FLUTTER_WEB_URL"
        reachable="true"
        break
      fi
      sleep 2
      waited=$((waited + 2))
    done
    if [ "$reachable" != "true" ]; then
      fail "Flutter web server did not become reachable within $FRONTEND_WAIT_SECONDS seconds."
    fi
    open_frontend_in_browser
  elif [ "$FRONTEND_CHOICE" = "react" ]; then
    log "Waiting up to $FRONTEND_WAIT_SECONDS seconds for $REACT_DEV_URL..."
    waited=0
    reachable="false"
    while [ "$waited" -lt "$FRONTEND_WAIT_SECONDS" ]; do
      if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
        wait "$FRONTEND_PID" || frontend_status=$?
        fail "Frontend exited before the dev server became reachable. Exit code: ${frontend_status:-1}"
      fi
      if check_http "$REACT_DEV_URL"; then
        sleep 1
        if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
          wait "$FRONTEND_PID" || frontend_status=$?
          fail "Frontend exited immediately after readiness check succeeded. Exit code: ${frontend_status:-1}"
        fi
        log "React dev server is reachable: $REACT_DEV_URL"
        reachable="true"
        break
      fi
      sleep 2
      waited=$((waited + 2))
    done
    if [ "$reachable" != "true" ]; then
      fail "React dev server did not become reachable within $FRONTEND_WAIT_SECONDS seconds."
    fi
    open_frontend_in_browser
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
