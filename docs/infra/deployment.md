# Synca — Deployment Architecture & CD Pipeline

> **Status:** MVP / Development phase  
> **Last updated:** May 2026

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Developer machine                                          │
│                                                             │
│  bin/rails s  →  localhost:3000                             │
│       │                                                     │
│       └──► ngrok tunnel ──► https://xyz.ngrok.io            │
│                                    │                        │
│                             iOS Simulator / device          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  git push → main                                            │
│       │                                                     │
│       ▼                                                     │
│  GitHub Actions ── rails-ci.yml                             │
│       ├── scan_ruby   (Brakeman)                            │
│       ├── gem_audit   (bundler-audit)                       │
│       ├── lint        (RuboCop)                             │
│       └── test        (Minitest ≥ 90% coverage)             │
│                                                             │
│  [only if all CI jobs pass]                                 │
│       │                                                     │
│       ▼                                                     │
│  deploy.yml                                                 │
│       ├── Build Docker image                                │
│       ├── Push → ghcr.io/malstrom/synca-api                 │
│       └── Kamal deploy → SSH → VPS                         │
│                              └── pull + zero-downtime swap  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  VPS (Hetzner CX22 — ~€4/mo)                               │
│                                                             │
│  Docker                                                     │
│    ├── synca-api      (Rails + Puma)                        │
│    ├── synca-db       (PostgreSQL 16)                       │
│    └── kamal-proxy    (Traefik — TLS termination)           │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1 — Local Development with ngrok

### Purpose
Expose `localhost:3000` to the iOS app (Simulator or physical device)
without needing a public server.

### Setup

```bash
# Install ngrok
brew install ngrok        # macOS
# or download from https://ngrok.com/download

# Authenticate (free account)
ngrok config add-authtoken <YOUR_TOKEN>

# Start the tunnel (run alongside bin/rails s)
ngrok http 3000
```

ngrok outputs a URL like `https://abc123.ngrok-free.app`.
Set this as `BASE_URL` in the iOS app's debug config.

### Notes
- The URL changes on every ngrok restart (free plan).
  Use a fixed subdomain with ngrok paid plan if it becomes annoying.
- Never hardcode the ngrok URL in committed code — use an `.xcconfig`
  or environment variable in the iOS target.
- ngrok is **dev only**. It is never part of the CD pipeline.

---

## Phase 2 — CI Pipeline (already live)

File: `.github/workflows/rails-ci.yml`

Triggers on every push/PR to `main` that touches `backend/api/**`.

| Job | Tool | Purpose |
|---|---|---|
| `scan_ruby` | Brakeman | Static security analysis |
| `gem_audit` | bundler-audit | CVE check on all gems |
| `lint` | RuboCop `-a` | Style + autocorrect diff check |
| `test` | Minitest + SimpleCov | Tests + coverage ≥ 90% |

All four jobs run **in parallel**. The deploy job (Phase 3) will only
run after all four pass.

---

## Phase 3 — CD Pipeline (to implement)

File to create: `.github/workflows/deploy.yml`

### Flow

```
CI passes on main
      │
      ▼
Build Docker image (multi-platform: linux/amd64)
      │
      ▼
Push to ghcr.io/malstrom/synca-api:latest
      │
      ▼
Kamal deploy
  └── SSH into VPS
  └── docker pull ghcr.io/malstrom/synca-api:latest
  └── Stop old container (graceful)
  └── Start new container
  └── Health check → if fails, auto-rollback
```

### GitHub Secrets required

Add these in: `Settings → Secrets and variables → Actions`

| Secret name | Value |
|---|---|
| `KAMAL_SERVER_IP` | IP address of the VPS |
| `KAMAL_SSH_PRIVATE_KEY` | Private SSH key to access the VPS |
| `KAMAL_REGISTRY_PASSWORD` | GitHub Personal Access Token (write:packages) |
| `RAILS_MASTER_KEY` | Content of `backend/api/config/master.key` |
| `DATABASE_URL` | `postgres://synca:PASSWORD@db:5432/synca_production` |
| `SECRET_KEY_BASE` | Output of `bin/rails secret` |
| `JWT_SECRET_KEY` | Random 64+ char secret for JWT signing |

### Kamal secrets file

`.kamal/secrets` already reads from ENV — no changes needed.
GitHub Actions will export the secrets as env vars before running
`kamal deploy`.

---

## Phase 4 — VPS Setup (one-time, manual)

### Recommended server
**Hetzner CX22** — 2 vCPU, 4GB RAM, 40GB SSD — ~€4/month.
Located in **Helsinki (EU)** or **Falkenstein (EU)** for GDPR compliance.

> For Russian users, a separate RU-region instance will be needed
> in the future (see `docs/product/vision.md` — data residency).

### Bootstrap the server (one-time)

```bash
# On your local machine — Kamal handles the rest
cd backend/api

# 1. Add your SSH public key to the VPS via Hetzner console first

# 2. Bootstrap: installs Docker, creates deploy user
kamal setup

# 3. First deploy
kamal deploy
```

Kamal installs Docker on the VPS automatically via `kamal setup`.
No Ansible, no manual apt-get needed.

### What runs on the VPS

| Container | Image | Notes |
|---|---|---|
| `synca-api` | `ghcr.io/malstrom/synca-api` | Rails + Puma |
| `synca-db` | `postgres:16` | Kamal accessory |
| `kamal-proxy` | Traefik | TLS via Let's Encrypt, port 80/443 |

PostgreSQL data is persisted via a Docker volume (`synca_db_data`).
Backups: `pg_dump` via a daily cron job on the VPS (to implement).

---

## Rollback

```bash
# Instant rollback to previous image
kamal rollback

# Or to a specific version
kamal rollback <git-sha>
```

Kamal keeps the previous image on the VPS for instant rollback.

---

## Domain & TLS

1. Buy a domain (e.g., `synca.app`) — Cloudflare Registrar recommended.
2. Add an `A` record pointing to the VPS IP.
3. Set `KAMAL_SERVER_HOST=api.synca.app` in secrets.
4. Kamal-proxy (Traefik) handles Let's Encrypt TLS automatically.

---

## TODO — Ordered by priority

- [ ] Create `config/deploy.yml` (Kamal configuration)
- [ ] Create `.github/workflows/deploy.yml` (CD pipeline)
- [ ] Add all secrets to GitHub repository settings
- [ ] Provision Hetzner VPS
- [ ] Run `kamal setup` + first manual `kamal deploy`
- [ ] Verify health check endpoint (`GET /up`)
- [ ] Configure domain + TLS
- [ ] Add `pg_dump` daily backup cron
- [ ] Set up ngrok fixed subdomain (optional, paid plan)
- [ ] RU-region infrastructure (future — post-MVP)
