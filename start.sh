#!/usr/bin/env bash
# Start Cogento – Postgres, API, UI, nginx (no pgAdmin)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
docker compose pull
docker compose up -d
echo "Cogento starting. Web: http://localhost:${NGINX_HTTP_PORT:-80}  (UI direct: http://localhost:${UI_PORT:-3000})"
