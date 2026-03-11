# Cogento Self-Hosted

Run [Cogento](https://github.com/stefano-edgible/Cogento) by pulling pre-built images—no build required.

## Prerequisites

- **Docker** and **Docker Compose** (v2)

**Platforms:** The same setup works on **Linux** (e.g. EC2) and **macOS** (Docker Desktop). On Linux, `sudo ./setup-volumes.sh` sets correct ownership for the bind-mounted data dirs; on macOS a postgres entrypoint wrapper fixes permissions inside the container. No platform-specific steps.

**Suggested minimum hardware**

- **RAM:** 2 GB minimum; **4 GB** recommended (Postgres, API, UI; optional pgAdmin).
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
   # Edit .env before first start: POSTGRES_PASSWORD, GHCR_OWNER, SHARED_SUPERUSER_EMAIL (for shared admin), and mail (SMTP or RESEND_API_KEY) so login codes can be sent.
   ```

3. **Create volume dirs and start**
   ```bash
   ./setup-volumes.sh          # run with sudo so postgres/pgAdmin can write (Linux and macOS)
   ./start.sh
   ```

4. **Open the app** at **http://localhost:3000**. The UI uses relative `/api` URLs, so it works on any host (e.g. your server IP or domain) without extra config.

**Optional: pgAdmin**

```bash
./start-with-pgadmin.sh
# Then open http://localhost:5050 (or PGADMIN_PORT from .env)
```

## Secrets and keys

Copy `.env.example` to `.env` and set at least the following.

**Must set before first run**

- **`POSTGRES_PASSWORD`** – Database password (default `changeme` is insecure). Pick a strong value and keep it secret.
- **`GHCR_OWNER`** – Your GitHub user or org name (for pulling images from `ghcr.io`). Not a secret, but required.
- **`SHARED_SUPERUSER_EMAIL`** – Email of the first shared superuser (created by the DB bootstrap). **Set before first `./start.sh`** if you want to log in as shared admin (Tenants/Users); bootstrap runs only on first Postgres init. If you already started without it, run `./scripts/db/add_shared_superuser.sh` (stack must be running) or add the user via SQL against `cogento_shared.users`.
- **Mail (required for login):** Login is by email code (PIN). Without mail configured, no one can sign in (shared superuser or tenant users). Set either **SMTP** (`MAIL_SERVER`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`) or **`RESEND_API_KEY`** (Resend). Plus `MAIL_FROM` / `MAIL_FROM_NAME` if needed.

**Should set for production or if using the feature**

- **`PGADMIN_EMAIL`** / **`PGADMIN_PASSWORD`** – Only if you start pgAdmin (`start-with-pgadmin.sh`). Defaults are weak; change them if pgAdmin is reachable.

**Optional (only if you use that feature)**

- **Multi-tenant Stripe:** **`STRIPE_KEY_ENCRYPTION_KEY`** – Used to encrypt tenant Stripe keys in the DB. It must be a **Fernet** key (not a random typed string). Run `./generate-stripe-encryption-key.sh` to generate one, then add the printed line to `.env`.
- **Cloudflare Turnstile:** **`TURNSTILE_SITE_KEY`** and **`TURNSTILE_SECRET_KEY`** – Only if you enable Turnstile in the app.

**Not secrets (but useful)**

- **`UI_BASE_URL`** – Base URL of the app (e.g. `https://cogento.example.com`) for links in emails. Default `http://localhost:3000`.
- **`COGENTO_DATA_ROOT`** – Where to store volumes; use a dedicated path (e.g. `/data`) on a server.

Keep `.env` out of version control (it is in `.gitignore`).

**Forgot to set SHARED_SUPERUSER_EMAIL before first start?**

If you see "Email does not exist as superuser in shared database" at `/shared/signin`, the bootstrap already ran without that email. Either:

**Option A – Add the superuser to the existing DB:** Set `SHARED_SUPERUSER_EMAIL` in `.env`, then run:

```bash
./scripts/db/add_shared_superuser.sh
```

(Stack must be running.) Alternatively, in pgAdmin connect to **Cogento PostgreSQL** → database **cogento_shared** → Query Tool, run (replace with your email):

```sql
INSERT INTO users (user_id, email, role, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), 'your@email.com', 'superuser', TRUE, NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET role = 'superuser', is_active = TRUE, updated_at = NOW();
```

**Option B – Full reset (re-run bootstrap):** All data lives under `./volumes/`. To start completely fresh: `docker compose -p cogento down`, then `rm -rf volumes`, then `sudo ./setup-volumes.sh`, then `./start.sh`. Set `SHARED_SUPERUSER_EMAIL` in `.env` before `./start.sh`.

**Changing passwords after launch**

- **PostgreSQL:** Yes. In pgAdmin: connect to the "Cogento PostgreSQL" server (use the password from your `.env`), right-click the **postgres** database → **Query Tool**, run `ALTER USER cogento PASSWORD 'your_new_password';`, then update `POSTGRES_PASSWORD` in `.env` to the same value and run `docker compose -p cogento restart api`.
- **pgAdmin:** Yes. Either change your password from inside the pgAdmin web UI (login → right-click your user → Change Password), or set a new default in `.env`, then `rm -rf volumes/pgadmin`, run `sudo ./setup-volumes.sh` again, and `./start-with-pgadmin.sh`.

## Scripts

| Script | Description |
|--------|-------------|
| `setup-volumes.sh` | Create `volumes/postgres`, `volumes/pgadmin`, `volumes/tenant`. Run once or after a full reset. Run with `sudo` so containers can write. |
| `scripts/db/add_shared_superuser.sh` | Add shared superuser to `cogento_shared.users` (e.g. if you started without `SHARED_SUPERUSER_EMAIL`). Run from repo root; stack must be up. |
| `start.sh` | Start stack (Postgres, API, UI, nginx) in Docker |
| `start-with-pgadmin.sh` | Start stack plus pgAdmin (profile `with-pgadmin`) |
| `stop.sh` | Stop all Cogento containers |
| `generate-stripe-encryption-key.sh` | Generate a Fernet key for `STRIPE_KEY_ENCRYPTION_KEY` (for multi-tenant Stripe). Add the printed line to `.env`. |
| `sync-from-cogento.sh` | **Maintainers:** copy config/migrations from the [Cogento](https://github.com/stefano-edgible/Cogento) repo (source of truth). Run when those files change in Cogento, then commit. Default source: `../Cogento`; override with `COGENTO_SOURCE=/path/to/Cogento`. |

## Ports

- **3000** – UI (web app)
- **8000** – API (direct)
- **5432** – Postgres (host)
- **5050** – pgAdmin (only when started with `start-with-pgadmin.sh`)

## Data

**All data lives under one directory:** `./volumes/` (or `COGENTO_DATA_ROOT/volumes/` from `.env`). Subdirs: `postgres`, `pgadmin`, `tenant`. To reset everything: stop the stack, `rm -rf volumes`, run `sudo ./setup-volumes.sh`, then `./start.sh`. Run `./setup-volumes.sh` with `sudo` so the postgres (UID 70) and pgAdmin (UID 5050) containers can write to their dirs.

## Images

Images are pulled from **GitHub Container Registry** (`ghcr.io/<GHCR_OWNER>/cogento-api`, `cogento-ui`). Set `GHCR_OWNER` in `.env` to your GitHub user or org (default: `stefano-edgible`). Default tag is **`latest`** (linux/amd64, e.g. EC2). On **Apple Silicon (M1/M2/M3)** set **`COGENTO_IMAGE_TAG=latest-arm64`** in `.env` and build those images first from the Cogento repo with `DOCKER_PLATFORM=linux/arm64` (see Cogento registry README).
