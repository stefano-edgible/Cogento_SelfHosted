#!/usr/bin/env bash
# Copy config/migrations from Cogento (source of truth) into this repo.
# Run from Cogento_SelfHosted when you've updated Cogento and want to refresh
# the files here. Guests don't need to run this; the repo already has the files.
#
# Usage: ./sync-from-cogento.sh
# Optional: COGENTO_SOURCE=/path/to/Cogento  (default: ../Cogento)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
SRC="${COGENTO_SOURCE:-../Cogento}"
if [ ! -d "$SRC" ]; then
  echo "Error: Cogento source not found at: $SRC"
  echo "Set COGENTO_SOURCE to the path of your Cogento repo (e.g. COGENTO_SOURCE=../Cogento ./sync-from-cogento.sh)"
  exit 1
fi

mkdir -p api/migrations scripts/db config/nginx config/pgadmin

cp "$SRC/api/migrations/bootstrap_shared_schema.sql" api/migrations/
cp "$SRC/scripts/db/bootstrap_shared_db.sh" scripts/db/
cp "$SRC/config/nginx/default.conf" config/nginx/
cp "$SRC/config/pgadmin/servers.json" config/pgadmin/

echo "Synced from $SRC:"
echo "  api/migrations/bootstrap_shared_schema.sql"
echo "  scripts/db/bootstrap_shared_db.sh"
echo "  config/nginx/default.conf"
echo "  config/pgadmin/servers.json"
