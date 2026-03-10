#!/usr/bin/env bash
# Create volume directories. Run once (or when COGENTO_DATA_ROOT changes).
# Uses COGENTO_DATA_ROOT from .env or current dir.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
ROOT="${COGENTO_DATA_ROOT:-.}"
echo "Creating volumes under ${ROOT}/volumes/..."
mkdir -p "${ROOT}/volumes/postgres/data"
mkdir -p "${ROOT}/volumes/pgadmin/data"
mkdir -p "${ROOT}/volumes/tenant"
# pgAdmin writes as UID 5050
if command -v chown &>/dev/null; then
  chown 5050:5050 "${ROOT}/volumes/pgadmin/data" 2>/dev/null || true
fi
echo "Done."
