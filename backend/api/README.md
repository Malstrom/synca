# Synca — Rails API

REST API backend for the Synca dating app. Built with Rails 8 in API-only mode, PostgreSQL, JWT authentication and the Rails Solid Stack (Solid Queue, Solid Cache, Solid Cable).

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

Solid Queue is used for background processing (compatibility scoring, push notifications, Spark session expiry). It runs on PostgreSQL — no Redis required.

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

Workflow: [`/.github/workflows/rails-ci.yml`](../../.github/workflows/rails-ci.yml)

### Continuous Deployment

Triggered automatically after CI passes on `main`.

```
CI passes → Build Docker image → Push ghcr.io → Kamal deploy → db:migrate
```

Workflow: [`/.github/workflows/deploy.yml`](../../.github/workflows/deploy.yml)
Full guide: [`/docs/infra/deployment.md`](../../docs/infra/deployment.md)

## Project Structure

```
backend/api/
├── app/
│   ├── controllers/    # API controllers (versioned under /api/v1)
│   ├── models/         # ActiveRecord models
│   ├── services/       # Service objects (matching, scoring, trust)
│   ├── policies/       # Pundit authorization policies
│   └── jobs/           # Solid Queue background jobs
├── bin/
│   └── dev-ngrok       # One-command local dev environment
├── config/
│   ├── deploy.yml      # Kamal production config
│   ├── routes.rb
│   └── environments/
│       └── development.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/
    ├── models/
    ├── controllers/
    └── factories/      # FactoryBot factories
```

## Environment Variables

Copy `.env.example` to `.env` and fill in the values. Never commit `.env`.

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `JWT_SECRET_KEY` | ✅ | Secret key for JWT signing (`openssl rand -hex 64`) |
| `SECRET_KEY_BASE` | ✅ | Rails secret (`bin/rails secret`) |
| `AWS_ACCESS_KEY_ID` | S3 only | AWS credentials for S3 photo storage |
| `AWS_SECRET_ACCESS_KEY` | S3 only | AWS credentials for S3 photo storage |
| `AWS_BUCKET` | S3 only | S3 bucket name for profile photos |
