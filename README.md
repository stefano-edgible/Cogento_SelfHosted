# Cogento Self-Hosted

Run [Cogento](https://github.com/stefano-edgible/Cogento) by pulling pre-built images—no build required.

## Prerequisites

- **Docker** and **Docker Compose** (v2)

**Suggested minimum hardware**

- **RAM:** 2 GB minimum; **4 GB** recommended (Postgres, API, UI, nginx; optional pgAdmin).
- **Disk:** At least **5 GB** for images and **5–10 GB** for `volumes/` (Postgres, tenant data). Use a dedicated path (e.g. `/data`) and set `COGENTO_DATA_ROOT=/data` for production.
- **CPU:** 2 cores.

## Quick start

1. **Clone this repo**
   ```bash
   git clone https://github.com/stefano-edgible/Cogento_SelfHosted.git
   cd Cogento_SelfHosted
   ```

2. **Create `.env`**
   ```bash
   cp .env.example .env
   # Edit .env if needed (e.g. COGENTO_DATA_ROOT=/data, POSTGRES_PASSWORD, GHCR_OWNER)
   ```

3. **Create volume dirs and start**
   ```bash
   chmod +x *.sh
   ./setup-volumes.sh
   ./start.sh
   ```

4. **Open the app** at **http://localhost:80** (nginx) or **http://localhost:3000** (UI direct).

**Optional: pgAdmin**

```bash
./start-with-pgadmin.sh
# Then open http://localhost:5050 (or PGADMIN_PORT from .env)
```

## Scripts

| Script | Description |
|--------|-------------|
| `setup-volumes.sh` | Create volume directories and set pgAdmin data dir ownership (run once or when changing data root) |
| `start.sh` | Start stack (Postgres, API, UI, nginx) in Docker |
| `start-with-pgadmin.sh` | Start stack plus pgAdmin (profile `with-pgadmin`) |
| `stop.sh` | Stop all Cogento containers |

## Ports

- **80** – nginx (default HTTP)
- **3000** – UI (direct)
- **8000** – API (direct)
- **5432** – Postgres (host)
- **5050** – pgAdmin (only when started with `start-with-pgadmin.sh`)

## Data

By default, data is stored under `./volumes/` (or `COGENTO_DATA_ROOT` from `.env`). Use a dedicated path (e.g. `/data`) on a server with a data disk.

## Images

Images are pulled from **GitHub Container Registry** (`ghcr.io/<GHCR_OWNER>/cogento-api`, `cogento-ui`). Set `GHCR_OWNER` in `.env` to your GitHub user or org (default: `stefano-edgible`).
