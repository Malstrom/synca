# Synca — Rails API

REST API backend for the Synca dating app. Built with Rails 8 in API-only mode, PostgreSQL, JWT authentication and the Rails Solid Stack (Solid Queue, Solid Cache, Solid Cable).

See also:

- Root overview: [../../README.md](../../README.md)
- API spec: [../../docs/api/openapi.yaml](../../docs/api/openapi.yaml)
- Backend conventions: [../../docs/tech/backend.md](../../docs/tech/backend.md)
- Matching spec: [../../docs/features/matching-v1.md](../../docs/features/matching-v1.md)
- Signals spec: [../../docs/features/signals-v1.md](../../docs/features/signals-v1.md)
- Moments spec: [../../docs/features/moments-v1.md](../../docs/features/moments-v1.md)
- Circles spec: [../../docs/features/circles-v1.md](../../docs/features/circles-v1.md)
- Spark spec: [../../docs/features/spark-v1.md](../../docs/features/spark-v1.md)
- Trust spec: [../../docs/features/trust-v1.md](../../docs/features/trust-v1.md)

## Requirements

| Tool | Version |
|------|---------|
| Ruby | 3.3.1 |
| Rails | 8.0.x |
| PostgreSQL | 16+ |
| ngrok | latest |
| Caddy | latest |

## First-time Setup

```bash
# Install dependencies
bundle install

# Configure environment variables
cp .env.example .env

# Create and migrate the database
bin/rails db:create db:migrate

# (Optional) Seed development data
bin/rails db:seed

# Add local dev domain (once only, requires sudo)
sudo bash -c 'echo "127.0.0.1 api.synca.local" >> /etc/hosts'

# Authenticate ngrok (free account at ngrok.com)
ngrok config add-authtoken <YOUR_TOKEN>

# Make the dev script executable (once only)
chmod +x bin/dev-ngrok
```

## Daily Development

```bash
bin/dev-ngrok
```

This single command starts the full local stack:

| What | Detail |
|------|--------|
| **Rails** | Listening on `127.0.0.1:3000` |
| **Caddy** | Proxies `http://api.synca.local` → `:3000` |
| **ngrok** | Public HTTPS tunnel for device/webhook testing |
| **`.env.ngrok`** | Written at repo root with the tunnel URL — deleted on `Ctrl+C` |

URLs available after startup:

| URL | Use |
|-----|-----|
| `http://api.synca.local` | iOS Simulator, browser (fixed, never changes) |
| `http://api.synca.local/api-docs` | Interactive API documentation (Scalar) |
| `https://xxx.ngrok-free.app` | Physical device, external webhooks (changes each run) |

> **ngrok splash page on first browser visit:** click "Visit Site".
> For API calls from code, add the header `ngrok-skip-browser-warning: true`.

### Running without ngrok (plain Rails)

```bash
bin/rails server
# API available at http://localhost:3000
```

## Background Jobs

Solid Queue is used for background processing. Current job surface includes matching refresh,
Spark session expiry, moment reminders, photo moderation and recurring maintenance flows.

Relevant docs:

- Matching: [../../docs/features/matching-v1.md](../../docs/features/matching-v1.md)
- Spark: [../../docs/features/spark-v1.md](../../docs/features/spark-v1.md)
- Moments: [../../docs/features/moments-v1.md](../../docs/features/moments-v1.md)
- Trust: [../../docs/features/trust-v1.md](../../docs/features/trust-v1.md)

```bash
# Jobs are processed automatically when the server starts in development.
# To run the queue worker manually:
bin/jobs
```

## Code Quality

### RuboCop

```bash
# Check
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Auto-fix all offenses (use with caution)
bundle exec rubocop -A
```

### Security

```bash
# Static analysis for Rails vulnerabilities
bundle exec brakeman --no-pager

# CVE check on all gems
bundle exec bundle-audit check --update
```

## Testing

Minitest is used as the test framework (Rails default). Coverage threshold: **≥ 90%** (enforced by SimpleCov).

```bash
# Run all tests
bin/rails test

# Run a specific file
bin/rails test test/models/user_test.rb

# Run a specific test by line number
bin/rails test test/models/user_test.rb:42
```

## Full CI Flow (local)

`bin/rails ci` runs the complete pipeline in one command — the same steps GitHub Actions runs:

1. If on `main`, auto-creates a `dev/ci-YYYYMMDD-HHMMSS` branch.
2. Runs `rubocop -a` — auto-commits any fixes.
3. Runs `bundle-audit` CVE check.
4. Runs `bin/rails test` with coverage ≥ 90%.
5. Pushes the branch to `origin`.
6. Opens a PR via `gh` CLI.

> Requires: `brew install gh && gh auth login`

## CI/CD

### Continuous Integration

Triggered on every push or PR touching `backend/api/**`.

| Job | Tool | Check |
|-----|------|-------|
| `scan_ruby` | Brakeman | Rails security vulnerabilities |
| `gem_audit` | bundler-audit | CVE check on all gems |
| `lint` | RuboCop | Code style enforcement |
| `test` | Minitest + SimpleCov | Test suite + coverage ≥ 90% |

Workflow: [../../.github/workflows/rails-ci.yml](../../.github/workflows/rails-ci.yml)

### Continuous Deployment

Triggered automatically after CI passes on `main`.

```text
CI passes → Build Docker image → Push ghcr.io → Kamal deploy → db:migrate
```

Workflow: [../../.github/workflows/deploy.yml](../../.github/workflows/deploy.yml)
Full guide: [../../docs/infra/deployment.md](../../docs/infra/deployment.md)

---

## Production Infrastructure

> ⚠️ **These services are configured but not yet active.**
> They must all be operational before the first production deploy.
> See the [Pre-production Checklist](#pre-production-checklist) at the bottom of this section.

### 1. Database Backup — Yandex Object Storage

**Why:** PostgreSQL data must be recoverable in case of VPS failure or accidental data loss.
Yandex Object Storage is S3-compatible, data stays in Russia (ru-central1), and the free
tier covers the entire MVP phase (first 1 GB storage + first 10k PUT operations free).

**How it works:** `DatabaseBackupJob` runs every night at 03:00 via Solid Queue (see
`config/recurring.yml`). It calls `pg_dump`, uploads the `.dump` file to a private Yandex
bucket, then deletes the local temp file. No extra infrastructure — Solid Queue already
runs inside the Rails container.

```bash
# Trigger a manual backup at any time
kamal backup
# (alias for: kamal app exec "bin/rails runner 'DatabaseBackupJob.perform_now'")
```

**Setup steps (once, before production):**
1. Create a Yandex Cloud account at [console.yandex.cloud](https://console.yandex.cloud)
2. Create a bucket named `synca-backups` in region `ru-central1`, set access to **Private**
3. Create a service account with role `storage.uploader`
4. Generate a static access key for that service account
5. Add to GitHub Secrets: `YC_ACCESS_KEY_ID`, `YC_SECRET_ACCESS_KEY`, `YC_BACKUP_BUCKET`

---

### 2. Log Aggregation — Yandex Cloud Logging + Fluent Bit

**Why:** In production, container logs disappear when the container restarts. Yandex Cloud
Logging collects and retains logs centrally, enabling post-mortem analysis of errors and
slow requests. Data stays in Russia. Cost at MVP scale: effectively €0/month.

**How it works:** Fluent Bit runs as a lightweight sidecar, reads Rails stdout (forwarded
via Docker logging driver), and ships structured log entries to Yandex Cloud Logging using
the official Yandex plugin. Configuration: `config/fluent-bit.conf`.

**Setup steps (once, before production):**
1. In Yandex Cloud Console, note your **Folder ID** (visible on the Overview page)
2. Create a service account with role `logging.writer`
3. Download its IAM key as JSON → save as `/etc/fluent-bit/yc-key.json` on the VPS
4. Add to GitHub Secrets: `YC_FOLDER_ID`
5. Start Fluent Bit on the VPS:
   ```bash
   docker run -d \
     -v /etc/fluent-bit/yc-key.json:/etc/fluent-bit/yc-key.json \
     -v /var/log/synca:/var/log/synca \
     -e YC_FOLDER_ID=$YC_FOLDER_ID \
     cr.yandex/crptd6tl36lh10p1o1ng/fluent-bit-plugin-yandex:latest \
     -c /fluent-bit/etc/fluent-bit.conf
   ```

---

### 3. Error Tracking — GlitchTip (self-hosted)

**Why:** Without error tracking, Rails exceptions in production are invisible. GlitchTip is
a fully open-source, Sentry-compatible alternative. It runs as a Docker container (Kamal
accessory) on the same VPS — no external service, no cost, data never leaves the server.

**How it works:** Rails uses the standard `sentry-ruby` + `sentry-rails` gems, pointing the
DSN at the local GlitchTip instance (`config/initializers/sentry.rb`). The initializer is
a no-op in development (no `SENTRY_DSN` set). In production it captures exceptions,
background job failures, and slow transactions.

**Setup steps (once, before production):**
1. Deploy the GlitchTip accessory:
   ```bash
   kamal accessory boot glitchtip
   ```
2. Open `http://<SERVER_IP>:8000` in your browser (access via SSH tunnel if needed:
   `ssh -L 8000:localhost:8000 user@<SERVER_IP>`)
3. Create an admin account and a project named `synca-api`
4. Copy the DSN from Project Settings → DSN
5. Add to GitHub Secrets: `SENTRY_DSN`, `GLITCHTIP_SECRET_KEY`, `GLITCHTIP_DATABASE_URL`
6. Redeploy: `kamal deploy`

```bash
# Verify GlitchTip is receiving events (triggers a test exception)
kamal app exec "bin/rails runner 'raise \"GlitchTip test error\"'"
```

---

### 4. Uptime Monitoring — UptimeRobot

**Why:** Rails 8 exposes a `/up` health check endpoint out of the box. UptimeRobot pings
it every 5 minutes and sends an alert (email or Telegram) if the server stops responding.
Free tier supports up to 50 monitors.

**How it works:** No code required. UptimeRobot calls `GET https://api.synca.app/up` and
expects HTTP 200. If it receives anything else (or times out), it triggers the alert.

**Setup steps (once, before production):**
1. Register at [uptimerobot.com](https://uptimerobot.com) (free)
2. Add a new monitor: type **HTTP(S)**, URL `https://api.synca.app/up`, interval **5 minutes**
3. Add alert contacts: email and/or Telegram bot
4. Verify the monitor shows **Up** after the first production deploy

---

### Pre-production Checklist

All four services must be active before go-live. Use this as a final gate:

| Service | Status | Verified by |
|---------|--------|-------------|
| ☐ Yandex Object Storage bucket created | not active | `kamal backup` exits 0 |
| ☐ `YC_ACCESS_KEY_ID` / `YC_SECRET_ACCESS_KEY` in GitHub Secrets | not active | CD passes |
| ☐ Backup job runs successfully | not active | Check Solid Queue dashboard |
| ☐ Fluent Bit shipping logs to Yandex Cloud Logging | not active | Log entry visible in YC Console |
| ☐ `YC_FOLDER_ID` in GitHub Secrets | not active | — |
| ☐ GlitchTip accessory deployed and reachable | not active | `kamal accessory details glitchtip` |
| ☐ `SENTRY_DSN` in GitHub Secrets | not active | Test error appears in GlitchTip |
| ☐ UptimeRobot monitor shows **Up** | not active | Email/Telegram alert configured |

---

## Project Structure

```text
backend/api/
├── app/
│   ├── controllers/    # API controllers (versioned under /api/v1)
│   ├── models/         # ActiveRecord models
│   ├── services/       # Service objects (matching, scoring, trust)
│   ├── channels/       # Action Cable channels for circles and realtime flows
│   ├── policies/       # Pundit authorization policies
│   └── jobs/           # Solid Queue background jobs
│       └── database_backup_job.rb
├── bin/
│   └── dev-ngrok       # One-command local dev environment
├── config/
│   ├── deploy.yml      # Kamal production config (incl. GlitchTip accessory)
│   ├── recurring.yml   # Solid Queue scheduled jobs
│   ├── fluent-bit.conf # Log shipping to Yandex Cloud Logging
│   ├── routes.rb
│   └── initializers/
│       └── sentry.rb   # GlitchTip / error tracking init
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/
    ├── models/
    ├── controllers/
    └── jobs/
```

Domain docs:

- Matching: [../../docs/features/matching-v1.md](../../docs/features/matching-v1.md)
- Signals: [../../docs/features/signals-v1.md](../../docs/features/signals-v1.md)
- Moments: [../../docs/features/moments-v1.md](../../docs/features/moments-v1.md)
- Circles: [../../docs/features/circles-v1.md](../../docs/features/circles-v1.md)
- Spark: [../../docs/features/spark-v1.md](../../docs/features/spark-v1.md)
- Trust: [../../docs/features/trust-v1.md](../../docs/features/trust-v1.md)

## Environment Variables

Copy `.env.example` to `.env` and fill in the values. Never commit `.env`.

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `JWT_SECRET_KEY` | ✅ | Secret key for JWT signing (`openssl rand -hex 64`) |
| `SECRET_KEY_BASE` | ✅ | Rails secret (`bin/rails secret`) |
| `YC_ACCESS_KEY_ID` | ✅ before prod | Yandex Object Storage — backup uploads |
| `YC_SECRET_ACCESS_KEY` | ✅ before prod | Yandex Object Storage — backup uploads |
| `YC_BACKUP_BUCKET` | ✅ before prod | Bucket name for DB backups (e.g. `synca-backups`) |
| `YC_FOLDER_ID` | ✅ before prod | Yandex Cloud folder ID for log aggregation |
| `SENTRY_DSN` | ✅ before prod | GlitchTip DSN for error tracking |
| `GLITCHTIP_SECRET_KEY` | ✅ before prod | GlitchTip Django secret key |
| `GLITCHTIP_DATABASE_URL` | ✅ before prod | PostgreSQL URL for GlitchTip's own DB |
| `AWS_ACCESS_KEY_ID` | S3 only | AWS/YC credentials for photo storage |
| `AWS_SECRET_ACCESS_KEY` | S3 only | AWS/YC credentials for photo storage |
| `AWS_BUCKET` | S3 only | Bucket name for profile photos |
