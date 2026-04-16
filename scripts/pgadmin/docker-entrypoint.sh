#!/bin/sh
set -e
python3 /pgadmin4/render-servers.py
exec /entrypoint.sh "$@"
