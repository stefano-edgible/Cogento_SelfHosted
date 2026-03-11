#!/usr/bin/env bash
# Create volume directories. Run once (or when COGENTO_DATA_ROOT changes).
# Uses COGENTO_DATA_ROOT from .env or current dir.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
ROOT="${COGENTO_DATA_ROOT:-.}"
echo "Creating volumes under ${ROOT}/volumes/..."
# Postgres and pgAdmin use Docker named volumes; no host dirs needed for them
mkdir -p "${ROOT}/volumes/tenant"
echo "Done."
