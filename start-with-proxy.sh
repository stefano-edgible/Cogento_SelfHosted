#!/usr/bin/env bash
# Start Cogento with the optional Caddy reverse proxy (ports 80/443).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
docker compose pull
docker compose --profile with-proxy up -d
echo "Cogento starting (with proxy). Web: ${COGENTO_PROXY_SITE_ADDRESS:-http://localhost}"
