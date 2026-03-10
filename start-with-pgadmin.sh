#!/usr/bin/env bash
# Start Cogento with pgAdmin (profile with-pgadmin)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
docker compose pull
docker compose --profile with-pgadmin up -d
echo "Cogento starting (with pgAdmin). Web: http://localhost:${NGINX_HTTP_PORT:-80}  pgAdmin: http://localhost:${PGADMIN_PORT:-5050}"
