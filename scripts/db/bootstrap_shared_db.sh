#!/bin/sh
# Bootstrap Shared Database Script – creates cogento_shared and applies schema (self-hosted)
set -e

echo "=========================================="
echo "Bootstrapping cogento_shared database..."
echo "=========================================="

until pg_isready -U "$POSTGRES_USER" -d postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

echo "PostgreSQL is ready."

DB_EXISTS=$(psql -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'cogento_shared'" | grep -q 1 && echo "yes" || echo "no")

if [ "$DB_EXISTS" = "no" ]; then
    echo "Creating cogento_shared database..."
    psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE cogento_shared;"
    echo "Database cogento_shared created."
else
    echo "Database cogento_shared already exists, skipping creation."
fi

echo "Running bootstrap schema..."
BOOTSTRAP_SQL="/docker-entrypoint-initdb.d/bootstrap_shared_schema.sql"

if [ -f "$BOOTSTRAP_SQL" ]; then
    psql -U "$POSTGRES_USER" -d cogento_shared -f "$BOOTSTRAP_SQL"
    echo "Bootstrap schema applied successfully."
else
    echo "WARNING: Bootstrap SQL file not found at $BOOTSTRAP_SQL"
    echo "Schema initialization skipped."
fi

if [ -n "$SHARED_SUPERUSER_EMAIL" ]; then
    echo "Creating initial superuser: $SHARED_SUPERUSER_EMAIL"
    USER_EXISTS=$(psql -U "$POSTGRES_USER" -d cogento_shared -tc "SELECT 1 FROM users WHERE email = '$SHARED_SUPERUSER_EMAIL'" | grep -q 1 && echo "yes" || echo "no")
    if [ "$USER_EXISTS" = "no" ]; then
        psql -U "$POSTGRES_USER" -d cogento_shared <<EOF
INSERT INTO users (user_id, email, role, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), '$SHARED_SUPERUSER_EMAIL', 'superuser', TRUE, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;
EOF
        echo "Initial superuser created: $SHARED_SUPERUSER_EMAIL"
    else
        echo "Superuser already exists: $SHARED_SUPERUSER_EMAIL (skipping)"
    fi
else
    echo "SHARED_SUPERUSER_EMAIL not set, skipping superuser creation."
fi

echo "=========================================="
echo "Bootstrap complete!"
echo "=========================================="
