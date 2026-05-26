# Synca — Rails API

REST API backend for the Synca dating app. Built with Rails 8 in API-only mode, PostgreSQL and JWT authentication.

## Requirements

- Ruby 3.3.x
- Rails 8.0.x
- PostgreSQL 14+
- Redis 7+

## Local Setup

```bash
# Install dependencies
bundle install

# Configure environment variables
cp config/database.yml.example config/database.yml
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

Sidekiq is used for background processing (compatibility score calculation, push notifications).

```bash
# In a separate terminal
bundle exec sidekiq
```

Sidekiq dashboard available at `/sidekiq` (development only).

## Code Style

RuboCop is configured with Rails Omakase rules.

```bash
# Check
bundle exec rubocop

# Auto-fix
bundle exec rubocop -a
```

## Security

```bash
# Static analysis for vulnerabilities
bundle exec brakeman
```

## Testing

```bash
# Run all tests
bin/rails test

# Run a specific file
bin/rails test test/models/user_test.rb
```

## Project Structure
