# Synca — Roadmap Tecnica 0–24 mesi

**Versione:** v1.1  
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
  - Pipeline base:
    - build iOS,
    - test/unit Rails,
    - lint (Swift, Kotlin, Ruby).
  - Ambienti:
    - `development`, `staging`, `production`.
- Security & Privacy
  - Linee guida health data:
    - nessun raw sample condiviso tra utenti,
    - solo aggregati (medie settimanali, cronotipo, activity score).
  - Data residency:
    - utenti RU → dati in Russia,
    - utenti EU → dati in EU.
- Logging & Monitoring
  - Logging centralizzato per backend.
  - Monitoring uptime API.

---

## Fase 1: MVP Core (1–3 mesi)

Obiettivo: registrazione utenti iOS, raccolta dati HealthKit aggregati, preferenze base, primi match semplici e prima versione di Synca Spark.

### Backend API (Rails)

Directory chiave:

- `backend/api/app/models`
- `backend/api/app/controllers/api/v1`
- `backend/api/app/services`

Feature:

- Modello `User`
  - campi: email/phone/telegram_id, nome, età, genere, città, foto.
  - auth base (token JWT o simile).
- Modello `HealthSummary`
  - campi: user_id, chronotype, sleep_start/end_local, avg_sleep_duration_minutes, routine_stability_index, activity_level, peak_energy_start/end_local, recovery_score, source.
- Modello `PreferenceProfile`
  - campi: user_id, visual_embedding (JSONB), travel_style, music_profile (JSONB).
- Modelli `Match` + `MatchParticipant`
  - struttura join-table per supportare match 1-to-1 e group match senza migrazioni future.
- Modelli `SparkSession` e `SparkReward`
  - flusso completo: create → join → submit_answers → result + reward.
- API v1:
  - `POST /auth/signup`, `POST /auth/login`, `POST /auth/refresh`
  - `GET/PUT /profile`
  - `PUT /health_summary`
  - `GET/PUT /preferences`
  - `POST /spark_sessions`, `POST /spark_sessions/:id/join`
  - `POST /spark_sessions/:id/submit_answers`
  - `GET /spark_sessions/:id/result`
  - `GET /spark_rewards`

### iOS App (Synca)

Directory: `apps/ios/Synca`

Feature:

- Onboarding:
  - registrazione,
  - schermo consenso privacy / health data.
- HealthKit integration:
  - richiesta permessi,
  - lettura aggregata (sleep, steps, eventualmente HR),
  - invio dati al backend come `HealthSummary`.
- Profilo utente:
  - editing informazioni base,
  - upload foto (1–3).
- Preferenze:
  - schermata per definire preferenze base (età, distanza, cronotipo, stile).
- **Synca Spark v0**:
  - `SparkView` con stati: Idle → Pending (QR + codice) → Active (micro-test) → Result.
  - modello Swift `MatchParticipant` allineato alla struttura join-table del backend.

### Matching v0 (rule-based)

Directory: `backend/api/app/services/matching/`

- `MatchingService`:
  - filtra per: città, età, genere.
  - ritorna una lista limitata (max 10 profili).
- Compatibilità:
  - placeholder (score fisso o per distanza/età).

---

## Fase 2: Matching Health-Based v1 + Telegram (3–6 mesi)

Obiettivo: introdurre compatibilità su sleep/activity/preferenze e collegare il bot Telegram.

### Matching Engine v1

Directory: `backend/api/app/services/matching/`

- `CompatibilityScoreService`:
  - input: `HealthSummary`, `PreferenceProfile`, info base (età, distanza), `irl_verification_count` da SparkSession.
  - output: `score` 0–100, breakdown (sleep_score, activity_score, lifestyle_score).
  - pesi di default: Sleep 35%, Activity 30%, Lifestyle/Travel 20%, Visual preferences 15%.
- API:
  - `GET /matches`: ritorna pochi profili (3–5) con compatibilità alta, include reason (es. "sleep rhythm aligned").

### TrustScore v0

Directory:

- `backend/api/app/models/trust_score.rb`
- `backend/api/app/services/trust/trust_score_service.rb`

Feature:

- Input:
  - verifica email/telefono,
  - completezza profilo,
  - `irl_verification_count` (numero di Spark completati con utenti distinti),
  - `spark_verified` flag.
- Output:
  - `trust_score` 0–100 usato per ranking interno.

### Telegram Bot v0

- Endpoint backend per bot:
  - comandi base: `/start`, `/profile`, `/remind`.
- Funzioni:
  - invio link per completare profilo su app,
  - notifiche “nuovo match”,
  - promemoria per aggiornare preferenze.

---

## Fase 3: Android App + Pagamenti + Premium (6–9 mesi)

Obiettivo: parità funzionale iOS/Android e inizio monetizzazione.

### Android App (Synca)

Directory: `apps/android/Synca`

Feature:

- Onboarding:
  - registrazione/autenticazione,
  - consensi privacy e health data.
- Health Connect:
  - richiesta permessi,
  - lettura aggregata (sleep, steps, HR se serve),
  - invio `HealthSummary` al backend.
- UI:
  - profilo,
  - preferenze,
  - lista match (come iOS).
- **Synca Spark su Android**: parità completa con iOS (SparkView, micro-test, result + reward).

### Pagamenti & Premium

Backend:

- Modello `Subscription` (user_id, plan, start/end, status).
- Modello `Transaction` (user_id, amount, method, status).
- Integrazioni:
  - RU: provider locali (es. YooKassa / equivalenti).
  - EU/altro: StoreKit / Play Billing / Stripe secondo strategia.
- Reward engine Spark: free → `premium_week`, premium → `match_credit`, premium+ → `match_credit` + `boost`.

Client (iOS/Android):

- Schermata “Upgrade to Premium”.
- Gating:
  - limite match attivi,
  - priorità nelle date proposals,
  - opzione rematch/filtri avanzati.

---

## Fase 4: Date Proposals + Trust & Safety v1 (9–12 mesi)

Obiettivo: spingere verso appuntamenti reali e alzare il livello di sicurezza.

### Date Proposal System

Backend:

- Modello `DateProposal`:
  - `match_id` (FK → matches — referenzia il match tra i partecipanti, non user_a/user_b direttamente),
  - `venue_id` (opzionale all’inizio),
  - `suggested_time_slot`,
  - `status` (suggested/accepted/declined/completed).
- API:
  - `POST /date_proposals`
  - `POST /date_proposals/:id/accept`
  - `POST /date_proposals/:id/decline`
  - `GET /date_proposals` (per utente).
- TrustScore: `irl_verification_count` contribuisce al ranking dei profili suggeriti per date proposals.

Client:

- UI:
  - lista date proposals,
  - dettaglio proposta,
  - bottoni accetta/rifiuta.

### Trust & Safety v1

Liveness & Image Checks:

- Integrazione API (es. Yandex Vision / alternativa):
  - liveness selfie (foto/video),
  - detection contenuti vietati.

Reputation:

- Contatori:
  - `no_show_count`,
  - `rude_reports`,
  - `spam_reports`,
  - `irl_verification_count` (incrementato da ogni SparkSession completata con utente distinto).
- Uso:
  - abbassare visibilità/match per TrustScore basso.

---

## Fase 5: Matching v2 (Data-Driven) + Analytics (12–18 mesi)

Obiettivo: far “imparare” il matching dagli outcome reali e avere metriche solide.

### Matching v2 (learnt)

Dati raccolti:

- Per ogni match:
  - chat_started (sì/no),
  - date_proposal_sent (sì/no),
  - date_proposal_accepted (sì/no),
  - feedback post-date (rating o thumbs up/down),
  - Spark compatibility score (segnale IRL diretto).

Algoritmi:

- Embedding:
  - preferenze,
  - musica (integrazione Spotify futura),
  - cronotipo/lifestyle.
- Modello di ranking:
  - aggiusta pesi del compatibility score per utente,
  - favorisce profili simili a match con esito positivo,
  - usa `irl_verification_count` come segnale di qualità aggiuntivo.

### Analytics & Dashboard

- Metriche:
  - MAU per città,
  - conversione free → paid,
  - % utenti che ricevono/accettano date proposals,
  - % date completate,
  - distribuzione TrustScore,
  - Spark sessions completate per città (segnale di engagement IRL),
  - retention per coorte.
- UI:
  - semplice pannello interno (es. Rails + grafici base).

---

## Fase 6: Scalabilità multi-città + Localizzazione (18–24 mesi)

Obiettivo: supportare 5–7 città con regole e pricing differenziati.

### Multi-città & Configurazione

Backend:

- Modello `CityConfig`:
  - città,
  - valuta e pricing (premium, date pack),
  - orari/zone “preferred” per date,
  - liste venue partner (estendibile).
- Data residency:
  - routing utenti RU → infrastruttura RU,
  - utenti EU → EU (compliance).

### Localizzazione

Client:

- Localizzazione app in: RU, EN, IT, TH, PT, ES.

Backend:

- Messaggi di sistema localizzati (email, notifiche push, bot Telegram).

---

## Fase 7: Group Compatibility (24+ mesi)

Obiettivo: estendere il matching a gruppi di persone (amici, run club, eventi sociali) senza re-architettura.

> **Nota architetturale**: il modello `Match` + `MatchParticipant` è già group-ready dal Giorno 1. Questa fase attiva l’engine e le UI, non richiede migrazioni di schema.

### Backend

- `GroupCompatibilityService`:
  - input: N user_id (via `match_participants`),
  - output: score aggregato di gruppo + breakdown per dimensione (sleep overlap, activity alignment, lifestyle blend).
  - usa `SparkSession` completate tra i membri come segnale di qualità IRL.
- API:
  - `POST /matches` con array di `participant_ids` (già supportato dal modello).
  - `GET /matches/:id` restituisce tutti i partecipanti con ruolo e score.
- `DateProposal` esteso per proposte di gruppo:
  - `venue_id` diventa obbligatorio per group date,
  - `suggested_time_slot` con overlap check tra i cronotipi dei partecipanti.

### Client (iOS + Android)

- Schermata “Group Match”: mostra i partecipanti con mini-profilo e score di gruppo.
- Group Spark: sessione Spark con più di 2 partecipanti (scanner QR sequenziale o link condiviso).
- Group Date Pack: proposta appuntamento collettivo con venue suggerita.

### Go-to-market

- Targeting: run club, palestre, saune — canali già attivi nel piano marketing offline.
- Posizionamento: “Synca non è solo dating, è social wellness”.
- Monetizzazione: Group Date Pack come add-on premium (es. accesso a venue partner a prezzo ridotto).
