#!/bin/sh
# Stop leftover local backend/frontend processes started by this repo.
# Also stops Docker Compose / Ollama unless STOP_LOCAL_SERVICES_ON_EXIT=false.
cd "$(dirname "$0")/.." || exit 1
sh scripts/start-dev.sh --stop "$@"
