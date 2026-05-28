# Synca — Roadmap Tecnica 0–24 mesi

**Versione:** v1.2  
**Orizzonte:** 0–24 mesi  
**Focus:** iOS + Android + Rails API, matching health-based, Trust & Safety, go-to-market per città

---

## Fase 0–1: Foundation & Setup (0–1 mese)

Obiettivo: creare le fondamenta tecniche e organizzative.

- Monorepo
  - Struttura:
    - `apps/ios/Synca`
    - `apps/android/Synca`
    - `backend/api`
    - `docs`
- CI/CD
  - Pipeline base: build iOS, test/unit Rails (≥90% coverage), lint (Swift, Kotlin, Ruby).
  - Ambienti: `development`, `staging`, `production`.
- Security & Privacy
  - Nessun raw sample condiviso tra utenti, solo aggregati.
  - Data residency: utenti RU → dati in Russia, utenti EU → dati in EU.
- Logging & Monitoring
  - Logging centralizzato per backend.
  - Monitoring uptime API.

---

## Fase 1: MVP Core (1–3 mesi)

Obiettivo: registrazione utenti iOS, raccolta dati HealthKit aggregati, preferenze base,
primi match e prima versione di Synca Spark. Entrambe le origini di match attive.

### Backend API (Rails)

- Modello `User` con auth JWT (`has_secure_password`, no Devise).
- Modello `HealthSummary` (aggregati device-side, no raw samples).
- Modello `PreferenceProfile`.
- Modelli `Match` + `MatchParticipant`:
  - campo `origin` (enum: `spark`, `algorithm`, default: `spark`).
  - campo `algorithm_confidence` (float, nil per match Spark).
  - struttura join-table group-ready senza migrazioni future.
- Modelli `SparkSession` e `SparkReward`.
- Background jobs via **Solid Queue** (no Redis, no Sidekiq):
  - queue `spark` — scoring, rewards, session expiry.
  - queue `algorithm` — `MatchingJob` notturno.
  - queue `mailers`.
- Coverage: **≥90% globale**, 100% su matching, Spark, TrustScore.

### Matching: due origini attive da MVP

```
FLUSSO 1 — Spark (origin: :spark)
  Incontro fisico → SparkSession → score ≥50 → Match

FLUSSO 2 — Algoritmo (origin: :algorithm)
  MatchingJob notturno → health summaries → score ≥65 → Match
```

I match algorithm sono visibili solo agli utenti Premium (premium gating).

### iOS App (Synca)

- Onboarding, HealthKit integration, profilo utente, preferenze.
- **Synca Spark v0**: SparkView con stati Idle → Pending → Active → Result.
- Lista match con badge `origin` ("Synca confermata" vs "Synca suggerita").

---

## Fase 2: Matching Health-Based v1 + Telegram (3–6 mesi)

Obiettivo: compatibilità completa su sleep/activity/preferenze e bot Telegram.

### Matching Engine v1

- `CompatibilityScoreService`:
  - pesi default: Sleep 35%, Activity 30%, Lifestyle 20%, Preferences 15%.
  - output: `score` 0–100 + breakdown per dimensione.
- `MatchingJob` notturno su queue `algorithm`:
  - itera utenti con `HealthSummary` aggiornato negli ultimi 30 giorni.
  - crea match `origin: :algorithm` con `algorithm_confidence`.

### TrustScore v0

- `trust_score` su `profiles` (float, 0–100, default 50).
- Aggiornato da `TrustScoreService` dopo ogni SparkSession completata.

### Telegram Bot v0

- Comandi: `/start`, `/profile`, `/remind`.
- Notifiche: nuovo match, promemoria preferenze.

---

## Fase 3: Android App + Pagamenti + Premium (6–9 mesi)

Obiettivo: parità funzionale iOS/Android e inizio monetizzazione.

### Android App

- Health Connect integration, parità completa con iOS incluso Spark.

### Pagamenti & Premium

- Modello `Subscription` + `Transaction`.
- Integrazioni: YooKassa (RU), StoreKit/Play Billing/Stripe (altri mercati).
- **Premium gating** (vedi `docs/product/matching.md`):
  - Match algoritmo visibili solo a utenti Premium.
  - Sync Room group (small_group): 1 attiva free, illimitate premium.
  - Event Room: solo premium.
  - Spark Invite Link: solo premium.

---

## Fase 4: Sync Rooms + Date Proposals + Trust & Safety v1 (9–12 mesi)

Obiettivo: attivare le Sync Rooms di gruppo, spingere verso appuntamenti reali,
alzare il livello di sicurezza.

### Sync Rooms (vedi `docs/product/sync-rooms.md`)

Tre tipi di stanza:

| Tipo | Members | Spark rule | Premium |
|------|---------|------------|----------|
| `duo` | 2 | 1 Spark tra i due | Free |
| `small_group` | 3–8 | Grafo completo (ogni coppia) | 1 free, ∞ premium |
| `event_room` | 9–22 | Spark con organizzatore | Solo premium |

Schema DB:

- `sync_rooms` (id, name, created_by, room_type, created_at)
- `sync_room_memberships` (sync_room_id, user_id, spark_session_id, joined_at)
- `sync_room_messages` (sync_room_id, sender_id, body, read_at, created_at)

Action Cable: un canale per stanza, autenticazione su `sync_room_memberships`.
Facilitazione Spark mancante: deep-link invite tra utenti che non si sono ancora incontrati.

### Date Proposal System

- Modello `DateProposal` (match_id, venue_id, suggested_time_slot, status).
- API: `POST/GET /date_proposals`, accept/decline.

### Trust & Safety v1

- Liveness selfie + detection contenuti vietati.
- Contatori reputazione: `no_show_count`, `rude_reports`, `irl_verification_count`.

---

## Fase 5: Matching v2 (Data-Driven) + Analytics (12–18 mesi)

Obiettivo: far “imparare” il matching dagli outcome reali e avere metriche solide.

### Matching v2 (learnt)

- Feedback loop: `chat_started`, `date_proposal_sent/accepted`, rating post-date,
  Spark compatibility score.
- Embedding: preferenze, musica (Spotify), cronotipo.
- Ranking: aggiusta pesi per utente, favorisce profili simili a match con esito positivo.

### Analytics & Dashboard

- MAU per città, conversione free→paid, % date completate, distribuzione TrustScore,
  Spark sessions per città, retention per coorte.

---

## Fase 6: Scalabilità multi-città + Localizzazione (18–24 mesi)

Obiettivo: supportare 5–7 città con regole e pricing differenziati.

### Multi-città

- `CityConfig`: città, valuta, pricing, venue partner.
- Data residency: routing RU → infrastruttura RU, EU → EU.

### Localizzazione

- App: RU, EN, IT, TH, PT, ES.
- Backend: messaggi sistema localizzati (email, push, bot).

---

## Fase 7: Group Compatibility & Event Rooms avanzate (24+ mesi)

Obiettivo: estendere matching a gruppi grandi (sport, eventi sociali) senza re-architettura.

> **Nota architetturale**: `Match` + `MatchParticipant` e `SyncRoom` sono group-ready
> dal Giorno 1. Questa fase attiva engine e UI avanzate, nessuna migrazione di schema.

### Backend

- `GroupCompatibilityService`: score aggregato di gruppo + breakdown (sleep overlap,
  activity alignment, lifestyle blend).
- Event Room avanzate: `suggested_date` obbligatoria, auto-archivio post-evento.
- Group Spark: sessione con più di 2 partecipanti (QR sequenziale o link condiviso).

### Go-to-market

- Targeting: run club, palestre, saune, squadre di calcetto.
- Posizionamento: “Synca non è solo dating, è social wellness”.
- Monetizzazione: Event Room Pack come add-on premium (accesso venue partner).
