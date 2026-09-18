#!/usr/bin/env sh
# Unified Unix entry for local startup. Delegates to start-dev.sh.
# Examples:
#   sh scripts/start-all.sh -b go -f react
#   sh scripts/start-all.sh -b spring -f flutter -e
# Optional env: SMOKE_LOGIN=true OPEN_BROWSER=false
# See scripts/README.md
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
exec sh "$SCRIPT_DIR/start-dev.sh" "$@"
