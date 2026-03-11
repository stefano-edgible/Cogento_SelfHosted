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
mkdir -p "${ROOT}/volumes/pgadmin/data/sessions"
mkdir -p "${ROOT}/volumes/pgadmin/data/storage"
mkdir -p "${ROOT}/volumes/tenant"
# postgres:15-alpine runs as postgres (UID 70) and must create pgdata inside the mount
if command -v chown &>/dev/null; then
  if chown 70:70 "${ROOT}/volumes/postgres/data" 2>/dev/null; then
    echo "Postgres data dir owned by 70:70."
  else
    echo "Warning: could not chown Postgres data to 70:70 (run with sudo on Linux if Postgres fails to start)."
  fi
fi
# pgAdmin (dpage/pgadmin4) runs as user pgadmin (UID 5050)
if command -v chown &>/dev/null; then
  if chown -R 5050:5050 "${ROOT}/volumes/pgadmin/data" 2>/dev/null; then
    echo "pgAdmin data dir owned by 5050:5050."
  else
    echo "Warning: could not chown pgAdmin data to 5050:5050 (run with sudo on Linux if pgAdmin fails to start)."
  fi
fi
echo "Done."
