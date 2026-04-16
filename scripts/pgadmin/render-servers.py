#!/usr/bin/env python3
"""Write PGADMIN_SERVER_JSON_FILE from preset + env (POSTGRES_USER, PGADMIN_SERVER_NAME)."""
import json
import os
import sys

PRESET = "/pgadmin4/servers-preset.json"
# Default matches image; override with PGADMIN_SERVER_JSON_FILE (must be writable by pgadmin user, e.g. under /var/lib/pgadmin).
OUT = os.environ.get("PGADMIN_SERVER_JSON_FILE", "/var/lib/pgadmin/servers.json")


def main() -> None:
    if not os.path.isfile(PRESET):
        return
    with open(PRESET, encoding="utf-8") as f:
        data = json.load(f)
    servers = data.setdefault("Servers", {})
    entry = servers.setdefault("1", {})
    entry["Username"] = os.environ.get("POSTGRES_USER", "cogento")
    entry["Name"] = os.environ.get("PGADMIN_SERVER_NAME", "PostgreSQL")
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


if __name__ == "__main__":
    try:
        main()
    except OSError as e:
        print(f"render-servers: {e}", file=sys.stderr)
        sys.exit(1)
