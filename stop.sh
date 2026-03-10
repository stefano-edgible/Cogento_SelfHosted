#!/usr/bin/env bash
# Stop all Cogento containers
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
docker compose -p cogento down
echo "Cogento stopped."
