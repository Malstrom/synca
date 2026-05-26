# Synca — Rails API

REST API backend for the Synca dating app. Built with Rails 8 in API-only mode, PostgreSQL, JWT authentication and the Rails Solid Stack (Solid Queue, Solid Cache, Solid Cable).

## Requirements

- Ruby 3.3.1
- Rails 8.0.x
- PostgreSQL 16+

## Local Setup

```bash
# Install dependencies
bundle install

# Configure environment variables
cp .env.example .env

# Create and migrate the database
bin/rails db:create db:migrate

# (Optional) Seed development data
bin/rails db:seed

# Start the server
bin/rails server
```

The API will be available at `http://localhost:3000`.

## Background Jobs

Solid Queue is used for background processing (compatibility score calculation, push notifications). It runs on PostgreSQL — no Redis required.

```bash
# Jobs are processed automatically when the server starts in development.
# To run the queue worker manually:
bin/jobs
```

## Code Style

RuboCop is configured with Rails Omakase rules.

```bash
# Check
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Auto-fix all offenses (use with caution)
bundle exec rubocop -A
```

## Security

```bash
# Static analysis for vulnerabilities
bundle exec brakeman --no-pager
```

## Testing

Minitest is used as the test framework (Rails default).

```bash
# Run all tests
bin/rails test

# Run a specific file
bin/rails test test/models/user_test.rb

# Run a specific test by line number
bin/rails test test/models/user_test.rb:42
```

## CI/CD

GitHub Actions runs automatically on every push or pull request that touches `backend/api/**`.

| Job | Description |
|---|---|
| **Security Scan** | Brakeman static analysis for Rails vulnerabilities |
| **Linting** | RuboCop code style enforcement |
| **Tests** | Minitest suite against a real PostgreSQL 16 instance |

Workflow file: [`/.github/workflows/rails-ci.yml`](../../.github/workflows/rails-ci.yml)

## Project Structure

```
backend/api/
├── app/
│   ├── controllers/    # API controllers (versioned under /api/v1)
│   ├── models/         # ActiveRecord models
│   ├── services/       # Interactor service objects (matching, scoring)
│   ├── policies/       # Pundit authorization policies
│   └── jobs/           # Solid Queue background jobs
├── config/
│   ├── routes.rb
│   └── database.yml
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/
    ├── models/
    ├── controllers/
    └── factories/      # FactoryBot factories
```

## Environment Variables

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET_KEY` | Secret key for JWT signing |
| `AWS_ACCESS_KEY_ID` | AWS credentials for S3 photo storage |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for S3 photo storage |
| `AWS_BUCKET` | S3 bucket name for profile photos |
