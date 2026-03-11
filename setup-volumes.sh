#!/usr/bin/env bash
# Create volume directories under COGENTO_DATA_ROOT/volumes/ (postgres, pgadmin, tenant).
# Run once, or after a full reset (rm -rf volumes). Run with sudo so postgres (70) and pgadmin (5050) can write.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
ROOT="${COGENTO_DATA_ROOT:-.}"
echo "Creating volumes under ${ROOT}/volumes/..."
mkdir -p "${ROOT}/volumes/postgres" "${ROOT}/volumes/pgadmin" "${ROOT}/volumes/tenant"

# Containers run as postgres (70:70) and pgadmin (5050:5050); they must own these dirs to write
if ! chown 70:70 "${ROOT}/volumes/postgres" 2>/dev/null; then
  echo "Could not chown volumes/postgres. Run: sudo ./setup-volumes.sh"
  exit 1
fi
if ! chown 5050:5050 "${ROOT}/volumes/pgadmin" 2>/dev/null; then
  echo "Could not chown volumes/pgadmin. Run: sudo ./setup-volumes.sh"
  exit 1
fi
echo "Done."
