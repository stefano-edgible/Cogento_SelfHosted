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
   ./setup-volumes.sh          # on Linux, use sudo ./setup-volumes.sh if you use pgAdmin
   ./start.sh
   ```

4. **Open the app** at **http://localhost:8080** (nginx) or **http://localhost:3000** (UI direct). The UI uses relative `/api` URLs, so it works on any host (e.g. your server IP or domain) without extra config.

**Optional: pgAdmin**

On Linux, run `sudo ./setup-volumes.sh` first so the pgAdmin data dir has the correct ownership (UID 5050). Then:

```bash
./start-with-pgadmin.sh
# Then open http://localhost:5050 (or PGADMIN_PORT from .env)
```

## Secrets and keys

Copy `.env.example` to `.env` and set at least the following.

**Must set before first run**

- **`POSTGRES_PASSWORD`** – Database password (default `changeme` is insecure). Pick a strong value and keep it secret.
- **`GHCR_OWNER`** – Your GitHub user or org name (for pulling images from `ghcr.io`). Not a secret, but required.

**Should set for production or if using the feature**

- **`PGADMIN_EMAIL`** / **`PGADMIN_PASSWORD`** – Only if you start pgAdmin (`start-with-pgadmin.sh`). Defaults are weak; change them if pgAdmin is reachable.
- **`SHARED_SUPERUSER_EMAIL`** – Email of the first shared superuser (created by the DB bootstrap script). Optional; set if you want an initial admin.

**Optional (only if you use that feature)**

- **Mail (login emails):** `MAIL_SERVER`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` (SMTP), or **`RESEND_API_KEY`** (Resend). Plus `MAIL_FROM` / `MAIL_FROM_NAME` if needed.
- **Multi-tenant Stripe:** **`STRIPE_KEY_ENCRYPTION_KEY`** – Used to encrypt tenant Stripe keys in the DB. It must be a **Fernet** key (not a random typed string). Run `./generate-stripe-encryption-key.sh` to generate one, then add the printed line to `.env`.
- **Cloudflare Turnstile:** **`TURNSTILE_SITE_KEY`** and **`TURNSTILE_SECRET_KEY`** – Only if you enable Turnstile in the app.

**Not secrets (but useful)**

- **`UI_BASE_URL`** – Base URL of the app (e.g. `https://cogento.example.com`) for links in emails. Default `http://localhost:3000`.
- **`COGENTO_DATA_ROOT`** – Where to store volumes; use a dedicated path (e.g. `/data`) on a server.

Keep `.env` out of version control (it is in `.gitignore`).

**Changing passwords after launch**

- **PostgreSQL:** Yes. In pgAdmin: connect to the "Cogento PostgreSQL" server (use the password from your `.env`), right-click the **postgres** database → **Query Tool**, run `ALTER USER cogento PASSWORD 'your_new_password';`, then update `POSTGRES_PASSWORD` in `.env` to the same value and run `docker compose -p cogento restart api`.
- **pgAdmin:** Yes. Either change your password from inside the pgAdmin web UI (login → right-click your user → Change Password), or set a new default by updating `PGADMIN_EMAIL` / `PGADMIN_PASSWORD` in `.env`, removing the pgAdmin data volume (`rm -rf ./volumes/pgadmin/data`), running `sudo ./setup-volumes.sh` again, and starting with `./start-with-pgadmin.sh` (pgAdmin will re-initialize with the new credentials).

## Scripts

| Script | Description |
|--------|-------------|
| `setup-volumes.sh` | Create volume directories (run once or when changing data root). On Linux, use `sudo ./setup-volumes.sh` if you use pgAdmin. |
| `start.sh` | Start stack (Postgres, API, UI, nginx) in Docker |
| `start-with-pgadmin.sh` | Start stack plus pgAdmin (profile `with-pgadmin`) |
| `stop.sh` | Stop all Cogento containers |
| `generate-stripe-encryption-key.sh` | Generate a Fernet key for `STRIPE_KEY_ENCRYPTION_KEY` (for multi-tenant Stripe). Add the printed line to `.env`. |
| `sync-from-cogento.sh` | **Maintainers:** copy config/migrations from the [Cogento](https://github.com/stefano-edgible/Cogento) repo (source of truth). Run when those files change in Cogento, then commit. Default source: `../Cogento`; override with `COGENTO_SOURCE=/path/to/Cogento`. |

## Ports

- **8080** – nginx (default HTTP)
- **3000** – UI (direct)
- **8000** – API (direct)
- **5432** – Postgres (host)
- **5050** – pgAdmin (only when started with `start-with-pgadmin.sh`)

## Data

Postgres data is stored in a **Docker named volume** (`cogento_postgres_data`), so no host path or permissions setup is needed. Other data (pgAdmin, tenant) is under `./volumes/` (or `COGENTO_DATA_ROOT` from `.env`). To put Postgres on a specific disk, see Docker docs for creating a volume with a custom path.

## Images

Images are pulled from **GitHub Container Registry** (`ghcr.io/<GHCR_OWNER>/cogento-api`, `cogento-ui`). Set `GHCR_OWNER` in `.env` to your GitHub user or org (default: `stefano-edgible`). Default tag is **`latest`** (linux/amd64, e.g. EC2). On **Apple Silicon (M1/M2/M3)** set **`COGENTO_IMAGE_TAG=latest-arm64`** in `.env` and build those images first from the Cogento repo with `DOCKER_PLATFORM=linux/arm64` (see Cogento registry README).
