#!/bin/sh
# Chown data dir to postgres (70:70) inside the container so bind mounts work on Docker Desktop (macOS).
# The host may not preserve UIDs; chown here fixes it before the real entrypoint runs.
chown -R 70:70 /var/lib/postgresql/data 2>/dev/null || true
exec /usr/local/bin/docker-entrypoint.sh "$@"
