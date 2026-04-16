#!/usr/bin/env bash
# Start Cogento – Postgres, API, UI (no pgAdmin; UI image serves the app and proxies /api)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
docker compose pull
docker compose up -d
echo "Cogento starting. Web: http://localhost:${UI_PORT:-3007}"
