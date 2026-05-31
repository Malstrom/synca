# Synca — Development Workflow

**Version 1.0 — May 2026**

---

## Git

- Commit messages: English, Conventional Commits — `type(scope): description`.
- Never commit or push directly to `main`.
- Branch naming:
  - `feat/<name>` — new feature
  - `fix/<name>` — bug fix
  - `docs/<name>` — documentation only
  - `refactor/<name>` — code refactor, no behavior change
  - `test/<name>` — tests only
- Keep branches short-lived. One branch = one logical change.

---

## Pull Requests

- Open a **draft PR** as soon as the branch exists — not when it is ready.
- Title: Conventional Commits format — `type(scope): short description`.
- Body must contain:

```markdown
## What changed
<what was added, removed, or modified>

## Why
<motivation — links to feature doc or phase doc>

## Test plan
<how to verify the change works>
```

- All PRs target `main`. Squash and merge only.
- Branch protection on `main`: PR required, CI must pass before merge.
- Never merge your own PR without a review (unless solo dev with explicit decision).

---

## TDD Flow

All new code follows Test-Driven Development:

1. **Red** — write the test first. It must fail.
2. **Green** — write the minimal code to make it pass.
3. **Refactor** — clean up, keeping tests green.

Rules:
- Never write a model, service, controller, or job without a test first.
- When asked to implement a feature, output the **test file first**, then the implementation file.
- Tests must cover: happy path, edge cases, and error cases.
- If a test requires a fixture that does not exist, create it in the same step.

Ref: `docs/conventions/testing.md` for full test conventions.

---

## CI — Local (`bin/rails ci`)

Run before every push. Mirrors what GitHub Actions runs:

```bash
bundle exec rubocop --autocorrect   # lint + auto-fix
bundle exec bundle-audit check --update  # CVE check
bundle exec brakeman --no-pager     # security scan
bundle exec rails test              # tests + coverage ≥ 90%
git push origin HEAD
```

If on `main`, `bin/rails ci` auto-creates a `dev/ci-YYYYMMDD-HHMMSS` branch,
commits any RuboCop fixes, and opens a PR via the `gh` CLI.

Requires: `brew install gh && gh auth login`

---

## CI — GitHub Actions

Triggered on every push or PR touching `backend/api/**`.

| Job | Tool | Check |
|---|---|---|
| `scan_ruby` | Brakeman | Rails security vulnerabilities |
| `gem_audit` | bundler-audit | CVE check on all gems |
| `lint` | RuboCop | Code style enforcement |
| `test` | Minitest + SimpleCov | Test suite + coverage ≥ 90% |

Workflow file: `.github/workflows/rails-ci.yml`

---

## Continuous Deployment

Triggered automatically after CI passes on `main`.

```
CI passes → Build Docker image → Push ghcr.io → Kamal deploy → db:migrate
```

Workflow file: `.github/workflows/deploy.yml`  
Full guide: `docs/infra/deployment.md`
