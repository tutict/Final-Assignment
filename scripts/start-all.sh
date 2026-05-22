#!/usr/bin/env sh
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
exec sh "$SCRIPT_DIR/start-dev.sh" "$@"
