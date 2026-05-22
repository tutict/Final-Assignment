#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: sh scripts/start-dev.sh

Starts:
  1. Spring Boot backend from finalAssignmentBackend
  2. Flutter app from final_assignment_front

Optional environment variables:
  START_LOCAL_SERVICES  Start Docker services and Ollama before backend. Default: true
  BACKEND_PROFILE       Spring profile. Default: dev
  BACKEND_ARGS          Extra Maven/Spring Boot plugin arguments.
  BACKEND_WAIT_SECONDS  Delay before Flutter starts. Default: 8
  JWT_SECRET            Local JWT secret. Default: development-only secret.
  APP_DEV_SERVICES_ENABLED  Starts Redis, Redpanda, and Elasticsearch Testcontainers in dev. Default: false
  APP_DOCKER_STARTUP_SCRIPT_ENABLED  Let backend run Docker startup scripts. Default: false because scripts/start-env.sh handles it.
  APP_OLLAMA_STARTUP_SCRIPT_ENABLED  Let backend run Ollama startup scripts. Default: false because scripts/start-env.sh handles it.
  APP_DEV_SERVICES_REDPANDA_ENABLED  Starts Redpanda Testcontainer in dev. Default: false
  APP_ELASTICSEARCH_FALLBACK_ENABLED  Fall back to MySQL when ES calls fail. Default: true
  SPRING_DEVTOOLS_RESTART_ENABLED  Disable DevTools restart for stable local startup. Default: false
  SPRING_KAFKA_LISTENER_AUTO_STARTUP  Starts Kafka listeners. Default: false
  SPRING_DATASOURCE_URL Local database JDBC URL. Default: jdbc:mysql://localhost:3306/traffic
  APP_ENV               Flutter APP_ENV dart define. Default: dev
  API_BASE_URL          Flutter API base URL. Default: http://localhost:8080
  WS_BASE_URL           Flutter WebSocket URL. Default: ws://localhost:8081
  MVN_CMD               Maven executable. Default: mvn
  FLUTTER_CMD           Flutter executable. Default: flutter
  FLUTTER_DEVICE        Flutter device id. Default: web-server
  FLUTTER_ARGS          Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
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

BACKEND_DIR="$ROOT_DIR/finalAssignmentBackend"
FLUTTER_DIR="$ROOT_DIR/final_assignment_front"

START_LOCAL_SERVICES="${START_LOCAL_SERVICES:-true}"
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
SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/traffic}"
SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-root}"
SPRING_DATASOURCE_DRIVER_CLASS_NAME="${SPRING_DATASOURCE_DRIVER_CLASS_NAME:-com.mysql.cj.jdbc.Driver}"
APP_ENV="${APP_ENV:-dev}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
WS_BASE_URL="${WS_BASE_URL:-ws://localhost:8081}"
BACKEND_WAIT_SECONDS="${BACKEND_WAIT_SECONDS:-8}"
BACKEND_LOG="${BACKEND_LOG:-$ROOT_DIR/springboot-run.log}"
BACKEND_ERR_LOG="${BACKEND_ERR_LOG:-$ROOT_DIR/springboot-run.err.log}"
MVN_CMD="${MVN_CMD:-mvn}"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
FLUTTER_ARGS="${FLUTTER_ARGS:---web-hostname 127.0.0.1 --web-port 3000}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found in PATH: $1" >&2
    exit 1
  fi
}

if [ ! -f "$BACKEND_DIR/pom.xml" ]; then
  echo "[ERROR] Spring Boot project not found: $BACKEND_DIR" >&2
  exit 1
fi

if [ ! -f "$FLUTTER_DIR/pubspec.yaml" ]; then
  echo "[ERROR] Flutter project not found: $FLUTTER_DIR" >&2
  exit 1
fi

require_command "$MVN_CMD"
require_command "$FLUTTER_CMD"

if [ "$START_LOCAL_SERVICES" = "true" ]; then
  echo "Starting local Docker/Ollama environment..."
  sh "$SCRIPT_DIR/start-env.sh"
fi

BACKEND_PID=""
cleanup() {
  if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    echo
    echo "Stopping Spring Boot backend (PID $BACKEND_PID)..."
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Starting Spring Boot backend with profile \"$BACKEND_PROFILE\"..."
(
  cd "$BACKEND_DIR"
  export JWT_SECRET
  export APP_DEV_SERVICES_ENABLED
  export APP_DOCKER_STARTUP_SCRIPT_ENABLED
  export APP_OLLAMA_STARTUP_SCRIPT_ENABLED
  export APP_DEV_SERVICES_REDPANDA_ENABLED
  export APP_ELASTICSEARCH_FALLBACK_ENABLED
  export APP_ELASTICSEARCH_SYNC_ENABLED
  export SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT
  export SPRING_DEVTOOLS_RESTART_ENABLED
  export SPRING_KAFKA_LISTENER_AUTO_STARTUP
  export MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED
  export SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY
  export SPRING_DATASOURCE_URL
  export SPRING_DATASOURCE_USERNAME
  export SPRING_DATASOURCE_PASSWORD
  export SPRING_DATASOURCE_DRIVER_CLASS_NAME
  # shellcheck disable=SC2086
  "$MVN_CMD" spring-boot:run "-Dspring-boot.run.profiles=$BACKEND_PROFILE" "-Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false" ${BACKEND_ARGS:-}
) >"$BACKEND_LOG" 2>"$BACKEND_ERR_LOG" &
BACKEND_PID=$!

echo "Spring Boot PID: $BACKEND_PID"
echo "Backend logs: $BACKEND_LOG"
echo "Backend errors: $BACKEND_ERR_LOG"
echo "Waiting $BACKEND_WAIT_SECONDS seconds before starting Flutter..."
sleep "$BACKEND_WAIT_SECONDS"

if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
  echo "[ERROR] Spring Boot backend exited during startup." >&2
  echo "Last backend log lines:" >&2
  tail -n 40 "$BACKEND_LOG" >&2 || true
  echo "Last backend error lines:" >&2
  tail -n 40 "$BACKEND_ERR_LOG" >&2 || true
  set +e
  wait "$BACKEND_PID"
  backend_status=$?
  set -e
  exit "$backend_status"
fi

echo "Resolving Flutter dependencies..."
(
  cd "$FLUTTER_DIR"
  "$FLUTTER_CMD" pub get
)

echo "Starting Flutter app..."
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
)
