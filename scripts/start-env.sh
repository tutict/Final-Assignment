#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: sh scripts/start-env.sh

Starts local Docker services and Ollama.

Optional environment variables:
  START_DOCKER=false       Skip Docker compose services.
  START_OLLAMA=false       Skip Ollama.
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

START_DOCKER="${START_DOCKER:-true}"
START_OLLAMA="${START_OLLAMA:-true}"
DOCKER_WAIT_SECONDS="${DOCKER_WAIT_SECONDS:-180}"
OLLAMA_WAIT_SECONDS="${OLLAMA_WAIT_SECONDS:-60}"

start_docker_engine() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  os_name="$(uname -s 2>/dev/null || echo unknown)"
  case "$os_name" in
    Darwin)
      echo "Docker daemon is not ready. Starting Docker Desktop for macOS..."
      open -a "${DOCKER_APP_NAME:-Docker}" >/dev/null 2>&1 || true
      ;;
    Linux)
      echo "Docker daemon is not ready. Attempting to start Docker on Linux..."
      if command -v systemctl >/dev/null 2>&1; then
        systemctl --user start docker-desktop >/dev/null 2>&1 || true
        sudo -n systemctl start docker >/dev/null 2>&1 || true
      fi
      if command -v service >/dev/null 2>&1; then
        sudo -n service docker start >/dev/null 2>&1 || true
      fi
      ;;
    *)
      echo "Docker daemon is not ready. Please start Docker manually for $os_name."
      ;;
  esac
}

wait_for_docker() {
  waited=0
  until docker info >/dev/null 2>&1; do
    if [ "$waited" -ge "$DOCKER_WAIT_SECONDS" ]; then
      echo "[ERROR] Docker daemon did not become ready in $DOCKER_WAIT_SECONDS seconds." >&2
      exit 1
    fi
    sleep 2
    waited=$((waited + 2))
  done
}

start_docker_services() {
  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "[ERROR] Docker compose file not found: $COMPOSE_FILE" >&2
    exit 1
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker CLI was not found in PATH." >&2
    exit 1
  fi

  start_docker_engine
  wait_for_docker
  echo "Starting Docker services from $COMPOSE_FILE..."
  docker compose -f "$COMPOSE_FILE" up -d --remove-orphans --wait --wait-timeout "$DOCKER_WAIT_SECONDS"
}

ollama_reachable() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1
  else
    ollama list >/dev/null 2>&1
  fi
}

start_ollama_service() {
  if ! command -v ollama >/dev/null 2>&1; then
    echo "[ERROR] Ollama executable was not found in PATH." >&2
    echo "Set START_OLLAMA=false to skip Ollama startup." >&2
    exit 1
  fi

  if ollama_reachable; then
    echo "Ollama is already reachable."
    return 0
  fi

  echo "Starting Ollama service..."
  nohup ollama serve >/tmp/final-assignment-ollama.log 2>&1 &

  waited=0
  until ollama_reachable; do
    if [ "$waited" -ge "$OLLAMA_WAIT_SECONDS" ]; then
      echo "[ERROR] Ollama did not become reachable in $OLLAMA_WAIT_SECONDS seconds." >&2
      exit 1
    fi
    sleep 2
    waited=$((waited + 2))
  done
  echo "Ollama is ready."
}

if [ "$START_DOCKER" != "false" ]; then
  start_docker_services
fi

if [ "$START_OLLAMA" != "false" ]; then
  start_ollama_service
fi

echo "Local environment is ready."
