# Feature: Auth
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Auth gestisce la registrazione, il login e la sessione utente su iOS, Android e
clientid web futuri. È il prerequisito di ogni altra feature — senza un account
verificato non è possibile accedere a Signals, Spark o Matching.

L'autenticazione usa `has_secure_password` (bcrypt) + JWT. Nessuna dipendenza da
Devise o Warden. Il token JWT viene salvato nel Keychain (iOS) e in
EncryptedSharedPreferences (Android) — mai in storage non cifrato.

---

## Step 1.0 — Email + Password

**Phase:** 1
**Status:** Draft

### User Flow

1. Utente apre l'app per la prima volta.
2. Sceglie "Registrati".
3. Inserisce email + password (min 8 caratteri).
4. Il backend crea `User` + `Profile`, restituisce JWT.
5. JWT salvato in Keychain (iOS) / EncryptedSharedPreferences (Android).
6. Utente reindirizzato all'onboarding di **Profile**.

Login successivo:
1. Inserisce email + password.
2. Backend valida, restituisce nuovo JWT.
3. App aggiorna il token in Keychain.

Scadenza token: 30 giorni. Nessun refresh token in Step 1.0.

### DB Schema

```sql
users
  id              bigint PK
  email           string NOT NULL UNIQUE
  password_digest string NOT NULL        -- bcrypt via has_secure_password
  created_at      datetime
  updated_at      datetime

profiles
  id                    bigint PK
  user_id               bigint FK → users NOT NULL
  display_name          string
  bio                   text
  photos                jsonb DEFAULT '[]'
  trust_score           float NOT NULL DEFAULT 50.0
  spark_verified        boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium               boolean NOT NULL DEFAULT false
  created_at            datetime
  updated_at            datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|--------------|-------------|
| POST | `/api/v1/auth/register` | No | Crea `User` + `Profile`, restituisce JWT |
| POST | `/api/v1/auth/login` | No | Valida credenziali, restituisce JWT |
| GET | `/api/v1/auth/me` | Yes | Restituisce l'utente corrente dal JWT |
| DELETE | `/api/v1/auth/logout` | Yes | Invalida la sessione lato client |

Ref: `docs/api/openapi.yaml`

JWT payload: `{ user_id: integer, exp: unix_timestamp }`
Header richiesto su tutti gli endpoint protetti: `Authorization: Bearer <token>`

### Premium Gating

Nessuno — registrazione e login sono interamente free.

### Open Questions

- Aggiungere refresh token in Step 1.0 o aspettare Step 2.0?
- Scadenza JWT configurabile per città (es. mercati con normative diverse)?
- Email di verifica obbligatoria prima di accedere all'app o opzionale in MVP?

---

## Step 2.0 — Social Login

**Phase:** 2
**Status:** Planned

### User Flow

1. Utente sceglie "Continua con Apple" / "Continua con Google" / "Continua con VK".
2. Il provider restituisce un token OAuth al client.
3. Il client invia il token al backend (`POST /api/v1/auth/social`).
4. Il backend verifica il token con il provider, trova o crea `User` + `Profile`.
5. Restituisce JWT Synca. Flusso identico allo Step 1.0 da qui in poi.

Se l'email del provider coincide con un account email esistente — i due account
vengono collegati automaticamente (`identity_providers`).

### DB Schema

```sql
users
  id              bigint PK
  email           string UNIQUE          -- nullable per account solo-social
  password_digest string                 -- nullable per account solo-social
  created_at      datetime
  updated_at      datetime

profiles
  id                    bigint PK
  user_id               bigint FK → users NOT NULL
  display_name          string
  bio                   text
  photos                jsonb DEFAULT '[]'
  trust_score           float NOT NULL DEFAULT 50.0
  spark_verified        boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium               boolean NOT NULL DEFAULT false
  created_at            datetime
  updated_at            datetime

identity_providers
  id          bigint PK
  user_id     bigint FK → users NOT NULL
  provider    string NOT NULL   -- 'apple' | 'google' | 'vk'
  uid         string NOT NULL   -- ID univoco rilasciato dal provider
  created_at  datetime
  UNIQUE (provider, uid)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|--------------|-------------|
| POST | `/api/v1/auth/register` | No | Invariato da Step 1.0 |
| POST | `/api/v1/auth/login` | No | Invariato da Step 1.0 |
| POST | `/api/v1/auth/social` | No | Verifica token OAuth, restituisce JWT Synca |
| GET | `/api/v1/auth/me` | Yes | Invariato da Step 1.0 |
| DELETE | `/api/v1/auth/logout` | Yes | Invariato da Step 1.0 |

Ref: `docs/api/openapi.yaml`

### Premium Gating

Nessuno — social login è disponibile per tutti i tier.

### Open Questions

- VK è prioritario per il mercato russo — va implementato in Step 2.0 o in un
  Step 2.1 separato dopo Apple e Google?
- Gestione account orfani: se un utente si registra con Apple e poi vuole
  aggiungere una password, come funziona il flusso?
- Token revocation: se un utente revoca l'accesso da Apple/Google, come
  viene gestita la sessione attiva su Synca?
