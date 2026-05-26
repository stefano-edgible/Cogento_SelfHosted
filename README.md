# Cogento Self-Hosted

Run [Cogento](https://github.com/stefano-edgible/Cogento) by pulling pre-built images—no build required.

## Prerequisites

- **Docker** and **Docker Compose** (v2)

**Platforms:** The same Docker Compose setup works on **Linux** (e.g. EC2) and **macOS** (Docker Desktop). On Linux, `sudo ./setup-volumes.sh` sets correct ownership for the bind-mounted data dirs; on macOS a postgres entrypoint wrapper fixes permissions inside the container. For production hosting, also review the AWS notes below.

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
   sudo ./setup-volumes.sh     # so postgres/pgAdmin can write (Linux and macOS)
   ./start.sh
   ```

4. **Open the app** at **http://localhost:3007**. The UI uses relative `/api` URLs, so it works on any host (e.g. your server IP or domain) without extra config.

**Optional: pgAdmin**

```bash
./start-with-pgadmin.sh
# Then open http://localhost:5057 (or PGADMIN_PORT from .env)
```

**Optional: built-in Caddy reverse proxy**

For local HTTP proxy testing:

```bash
./start-with-proxy.sh
# Then open http://localhost
```

For production HTTPS, set `COGENTO_PROXY_SITE_ADDRESS` and public URLs in `.env` first:

```bash
COGENTO_PROXY_SITE_ADDRESS=cogento.example.com
UI_BASE_URL=https://cogento.example.com
CORS_ORIGINS=https://cogento.example.com
```

Then run:

```bash
sudo ./setup-volumes.sh
./start-with-proxy.sh
```

## AWS EC2 production setup

This repo is intentionally small: it runs Cogento from pre-built images with Docker Compose. On AWS, the main extra work is host preparation, persistent storage, network rules, DNS, and HTTPS.

### 1. Launch an EC2 host

Recommended starting point:

- **Instance:** `t3.small` minimum, `t3.medium` recommended for production use.
- **OS:** Ubuntu LTS or Amazon Linux 2023.
- **Disk:** Use a dedicated EBS volume for data, mounted at `/data` (recommended), with regular EBS snapshots.
- **Architecture:** The default image tag is `latest` for Linux/amd64 EC2 instances. Use ARM images only if you have built/published an ARM tag and set `COGENTO_IMAGE_TAG`.

### 2. Security group

For a normal public deployment, allow inbound:

- **22/tcp** from your admin IP only (SSH).
- **80/tcp** from the internet (HTTP challenge / redirect).
- **443/tcp** from the internet (HTTPS app traffic).

Do **not** expose these publicly:

- **3007** UI direct port
- **8007** API direct port
- **5437** Postgres
- **5057** pgAdmin

Those ports may be useful locally on the host or through an SSH tunnel, but production users should access Cogento through HTTPS on port 443.

### 3. Install Docker

Install Docker Engine and the Compose plugin for your chosen OS, then verify:

```bash
docker --version
docker compose version
```

If the images are private in GitHub Container Registry, log in before `./start.sh`:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
```

The token needs package read access for the image owner set in `GHCR_OWNER`.

### 4. Mount persistent data at `/data`

Attach and mount an EBS volume at `/data`, then ensure it is mounted on boot via `/etc/fstab`. After that, set:

```bash
COGENTO_DATA_ROOT=/data
```

in `.env`. All Postgres, pgAdmin, and tenant files will live under `/data/volumes/`.

### 5. Clone and configure

```bash
git clone https://github.com/stefano-edgible/Cogento_SelfHosted.git
cd Cogento_SelfHosted
cp .env.example .env
```

Edit `.env` before first start. At minimum for production:

- `POSTGRES_PASSWORD`
- `GHCR_OWNER`
- `SHARED_SUPERUSER_EMAIL`
- SMTP settings or `RESEND_API_KEY`
- `SESSION_SECRET_KEY`
- `UNSUBSCRIBE_SECRET_KEY`
- `UI_BASE_URL=https://your.domain.example`
- `CORS_ORIGINS=https://your.domain.example`
- `COGENTO_DATA_ROOT=/data`

Then initialize volumes and start:

```bash
sudo ./setup-volumes.sh
./start.sh
```

### 6. DNS and HTTPS

Point your DNS record (for example `cogento.example.com`) at the EC2 public IP or Elastic IP.

This repo includes an optional **Caddy** reverse proxy profile so you do not need to install a host-level proxy for simple deployments. Set these in `.env`:

```bash
COGENTO_PROXY_SITE_ADDRESS=cogento.example.com
UI_BASE_URL=https://cogento.example.com
CORS_ORIGINS=https://cogento.example.com
COGENTO_DATA_ROOT=/data
```

Then start with:

```bash
sudo ./setup-volumes.sh
./start-with-proxy.sh
```

The proxy service publishes ports **80** and **443**, forwards traffic to the UI container, and stores Caddy TLS data under `$COGENTO_DATA_ROOT/volumes/caddy/`.

The included Caddyfile is:

```caddyfile
{$COGENTO_PROXY_SITE_ADDRESS:http://localhost} {
  encode zstd gzip
  reverse_proxy ui:80
}
```

Because the UI uses relative `/api` URLs and its container proxies `/api` to the API service, the reverse proxy only needs to forward to the UI port.

If you prefer an AWS Application Load Balancer, Nginx, or a host-installed Caddy, keep using `./start.sh` and forward your external proxy to `localhost:3007` instead.

**Recommended when using the built-in proxy:** keep direct service ports bound to localhost in `.env`, and keep only 80/443 open in the security group:

```bash
UI_PORT=127.0.0.1:3007
API_PORT=127.0.0.1:8007
POSTGRES_PORT=127.0.0.1:5437
PGADMIN_PORT=127.0.0.1:5057
```

### 7. Backups

At minimum, snapshot the EBS volume mounted at `/data`. For safer database backups, also run regular `pg_dump` exports from the Postgres container and store them outside the instance.

Suggested backup targets:

- EBS snapshots for fast whole-volume recovery.
- S3 for exported database dumps.
- A tested restore process on a fresh instance.

### 8. Updating

From the repo:

```bash
git pull
docker compose pull
docker compose up -d
```

After pulling a new API image, check `api/migrations/` and apply any new tenant migration SQL to each existing tenant database as described in the migrations section below.

### 9. Recovery on a new EC2 instance

To move or recover:

1. Attach the existing EBS data volume to the new instance and mount it at `/data`.
2. Clone this repo.
3. Restore the same `.env` values, especially `POSTGRES_PASSWORD`, `SESSION_SECRET_KEY`, and `COGENTO_DATA_ROOT=/data`.
4. Run `sudo ./setup-volumes.sh`.
5. Run `./start.sh`.

## Tenant database migrations

SQL for **existing** tenant databases (e.g. adding a column or extending a CHECK constraint) lives in this repo under **`api/migrations/`** alongside the main [Cogento](https://github.com/stefano-edgible/Cogento) tree. After pulling a new API image, apply any new scripts to **each** tenant DB with `psql` (see script headers). Example: **`add_systems_role_to_users.sql`** adds the `systems` integration role to `users.role`.

## Secrets and keys

Copy `.env.example` to `.env` and set at least the following.

**Must set before first run**

- **`POSTGRES_PASSWORD`** – Database password (default `changeme` is insecure). Pick a strong value and keep it secret.
- **`GHCR_OWNER`** – Your GitHub user or org name (for pulling images from `ghcr.io`). Not a secret, but required.
- **`SHARED_SUPERUSER_EMAIL`** – Email of the first shared superuser (created by the DB bootstrap). **Set before first `./start.sh`** if you want to log in as shared admin (Tenants/Users); bootstrap runs only on first Postgres init. If you already started without it, run `./scripts/db/add_shared_superuser.sh` (stack must be running) or add the user via SQL against `cogento_shared.users`.
- **Mail (required for login):** Login is by email code (PIN). Without mail configured, no one can sign in (shared superuser or tenant users). Set either **SMTP** (`MAIL_SERVER`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`) or **`RESEND_API_KEY`** (Resend). Plus `MAIL_FROM` / `MAIL_FROM_NAME` if needed.

**Should set for production or if using the feature**

- **`SESSION_SECRET_KEY`** – Secret for signing session tokens (JWT). **Change the default in production**; use a long random string (e.g. `openssl rand -base64 32`). Set it to a **fixed value in `.env`** so that logins survive container restarts (otherwise you may need to sign in again after `docker compose restart`).
- **`UNSUBSCRIBE_SECRET_KEY`** – Used for secure unsubscribe links in emails. **Change the default in production**.
- **`CORS_ORIGINS`** – Comma-separated allowed origins (e.g. `https://cogento.example.com`). If unset, the API uses `UI_BASE_URL` only. Set when the UI is on a different origin or you have multiple frontends.
- **`PGADMIN_EMAIL`** / **`PGADMIN_PASSWORD`** – Only if you start pgAdmin (`start-with-pgadmin.sh`). Defaults are weak; change them if pgAdmin is reachable.

**Optional (only if you use that feature)**

- **Multi-tenant Stripe:** **`STRIPE_KEY_ENCRYPTION_KEY`** – Used to encrypt tenant Stripe keys in the DB. It must be a **Fernet** key (not a random typed string). Run `./generate-stripe-encryption-key.sh` to generate one, then add the printed line to `.env`.
- **License trial key:** **`LICENSE_TRIAL_PUBLIC_KEY`** and **`LICENSE_TRIAL_PRIVATE_KEY`** – If set, every new tenant gets an auto-generated trial license (100 Stripe customers, 30 days). Generate with: `openssl genrsa -out trial_private.pem 2048` then `openssl rsa -in trial_private.pem -pubout -out trial_public.pem`; put the PEM contents in `.env`. See [Cogento docs](https://github.com/Edgible/Edgible_Public_Docs/blob/main/docs/Cogento/setup/GETTING_STARTED.md) (Step 2) or `Cogento/.env.example` for details.
- **Cloudflare Turnstile:** **`TURNSTILE_SITE_KEY`** and **`TURNSTILE_SECRET_KEY`** – Only if you enable Turnstile in the app.

**Not secrets (but useful)**

- **`UI_BASE_URL`** – Base URL of the app (e.g. `https://cogento.example.com`) for links in emails. Default `http://localhost:3007`.
- **`COGENTO_DATA_ROOT`** – Where to store volumes; use a dedicated path (e.g. `/data`) on a server.

**Using an external mount (e.g. EC2 `/data`):** Set `COGENTO_DATA_ROOT=/data` in `.env`. Run `sudo ./setup-volumes.sh` from the repo (it creates `/data/volumes/postgres`, `pgadmin`, `tenant` and sets ownership). Then `./start.sh` as usual. Compose and the setup script both use the same variable, so everything stays under one path; no extra steps.

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

**Option B – Full reset (re-run bootstrap):** All data lives under `./volumes/` (or `$COGENTO_DATA_ROOT/volumes/`). To start completely fresh: `docker compose -p cogento down`, then `rm -rf volumes` (or `rm -rf $COGENTO_DATA_ROOT/volumes` if using an external path), then `sudo ./setup-volumes.sh`, then `./start.sh`. Set `SHARED_SUPERUSER_EMAIL` in `.env` before `./start.sh`.

**Changing passwords after launch**

- **PostgreSQL:** Yes. In pgAdmin: connect to the "Cogento PostgreSQL" server (use the password from your `.env`), right-click the **postgres** database → **Query Tool**, run `ALTER USER cogento PASSWORD 'your_new_password';`, then update `POSTGRES_PASSWORD` in `.env` to the same value and run `docker compose -p cogento restart api`.
- **pgAdmin:** Yes. Either change your password from inside the pgAdmin web UI (login → right-click your user → Change Password), or set a new default in `.env`, then `rm -rf volumes/pgadmin`, run `sudo ./setup-volumes.sh` again, and `./start-with-pgadmin.sh`.

## Scripts

| Script | Description |
|--------|-------------|
| `setup-volumes.sh` | Create `volumes/postgres`, `volumes/pgadmin`, `volumes/tenant`. Run once or after a full reset. Run with `sudo` so containers can write. |
| `scripts/db/add_shared_superuser.sh` | Add shared superuser to `cogento_shared.users` (e.g. if you started without `SHARED_SUPERUSER_EMAIL`). Run from repo root; stack must be up. |
| `start.sh` | Start stack (Postgres, API, UI) in Docker |
| `start-with-pgadmin.sh` | Start stack plus pgAdmin (profile `with-pgadmin`) |
| `start-with-proxy.sh` | Start stack plus Caddy reverse proxy (profile `with-proxy`, ports 80/443) |
| `stop.sh` | Stop all Cogento containers |
| `generate-stripe-encryption-key.sh` | Generate a Fernet key for `STRIPE_KEY_ENCRYPTION_KEY` (for multi-tenant Stripe). Add the printed line to `.env`. |
| `sync-from-cogento.sh` | **Maintainers:** copy config/migrations from the [Cogento](https://github.com/stefano-edgible/Cogento) repo (source of truth). Run when those files change in Cogento, then commit. Default source: `../Cogento`; override with `COGENTO_SOURCE=/path/to/Cogento`. |

## Ports

Default **host** ports end in **7** to reduce clashes with other stacks; override in `.env` if needed.

- **3007** – UI (web app)
- **8007** – API (direct)
- **5437** – Postgres (host)
- **5057** – pgAdmin (only when started with `start-with-pgadmin.sh`)
- **80 / 443** – Caddy reverse proxy (only when started with `start-with-proxy.sh`)

## Data

**All data lives under one directory:** `./volumes/` (or `COGENTO_DATA_ROOT/volumes/` if you set e.g. `COGENTO_DATA_ROOT=/data`). Subdirs: `postgres`, `pgadmin`, `tenant`, and optionally `caddy` for TLS cert/config state. Run `./setup-volumes.sh` with `sudo` so the postgres (UID 70), pgAdmin (UID 5050), and optional proxy containers can write to their dirs.

**Why use an external mount (e.g. `/data` on EC2)?** Putting data on a dedicated path (set `COGENTO_DATA_ROOT=/data` in `.env`) makes it easy to reinstall the OS or move to a different instance: keep or reattach the same volume, point `.env` at it, and run `sudo ./setup-volumes.sh` and `./start.sh` again. All state stays in one place and is independent of the repo or runtime install.

**Reset everything from scratch:** To wipe all data and get a fresh Postgres (and pgAdmin state): stop the stack (`docker compose -p cogento down`), delete the data dir (`rm -rf volumes` or `rm -rf $COGENTO_DATA_ROOT/volumes` if using an external path), run `sudo ./setup-volumes.sh`, then `./start.sh`. Postgres will run its bootstrap again (including creating the shared superuser if `SHARED_SUPERUSER_EMAIL` is set in `.env`). No Docker volumes to remove—everything is under that one directory.

## Images

Images are pulled from **GitHub Container Registry** (`ghcr.io/<GHCR_OWNER>/cogento-api`, `cogento-ui`). Set `GHCR_OWNER` in `.env` to your GitHub user or org (default: `stefano-edgible`). Default tag is **`latest`** (linux/amd64, e.g. EC2). On **Apple Silicon (M1/M2/M3)** set **`COGENTO_IMAGE_TAG=latest-arm64`** in `.env` and build those images first from the Cogento repo with `DOCKER_PLATFORM=linux/arm64` (see Cogento registry README).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for the full text.
