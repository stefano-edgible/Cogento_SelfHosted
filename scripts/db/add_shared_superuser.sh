#!/usr/bin/env bash
# Add the shared superuser to cogento_shared.users (e.g. if you started without SHARED_SUPERUSER_EMAIL).
# Run from Cogento_SelfHosted root. Requires stack to be running (postgres container up).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"
[ -f .env ] && set -a && source .env && set +a

if [ -z "${SHARED_SUPERUSER_EMAIL}" ]; then
  echo "SHARED_SUPERUSER_EMAIL is not set in .env. Add it and run this script again."
  exit 1
fi

# Escape single quotes for SQL: ' -> ''
EMAIL_ESC="${SHARED_SUPERUSER_EMAIL//\'/\'\'}"
CONTAINER="${COGENTO_POSTGRES_CONTAINER:-cogento-postgres}"
export PGPASSWORD="${POSTGRES_PASSWORD:-changeme}"

if ! docker exec "$CONTAINER" pg_isready -U "${POSTGRES_USER:-cogento}" -d cogento_shared >/dev/null 2>&1; then
  echo "Postgres container $CONTAINER is not ready or cogento_shared is missing. Start the stack with ./start.sh first."
  exit 1
fi

EXISTS=$(docker exec -e PGPASSWORD "$CONTAINER" psql -U "${POSTGRES_USER:-cogento}" -d cogento_shared -t -A -c "SELECT 1 FROM users WHERE LOWER(email) = LOWER('$EMAIL_ESC') AND role = 'superuser' LIMIT 1" 2>/dev/null || true)
if [ -n "$EXISTS" ]; then
  echo "Superuser already exists: $SHARED_SUPERUSER_EMAIL"
  exit 0
fi

# Insert or update to superuser if user exists with different role
docker exec -e PGPASSWORD="$PGPASSWORD" "$CONTAINER" psql -U "${POSTGRES_USER:-cogento}" -d cogento_shared -c "
INSERT INTO users (user_id, email, role, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), '$EMAIL_ESC', 'superuser', TRUE, NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET role = 'superuser', is_active = TRUE, updated_at = NOW();
"
echo "Shared superuser added or updated: $SHARED_SUPERUSER_EMAIL. You can sign in at /shared/signin."
