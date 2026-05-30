# Synca — Field Research Telegram Bot

**Version:** 1.1  
**Last updated:** May 2026  
**Status:** Planned — Phase 0

---

## Purpose

A lightweight Telegram bot used by trusted friends and field researchers who interview
people in real life on behalf of Synca. Instead of filling in a Markdown table after
a date or conversation, the researcher answers a short guided conversation with the bot.
The bot then:

1. Appends a structured row to a shared Google Sheet
2. Sends a structured JSON summary to the founder's private Telegram chat
3. Optionally sends a plain-text recap to the researcher so they can forward it manually

This removes friction from field data collection, supports multilingual researchers,
and ensures consistent formatting across all sessions.

---

## Scope

This is a **research tool only** — not part of the Synca app.
It runs as a standalone Python script (`python-telegram-bot`).
It is operated by researchers, not by end users directly.

---

## Bot flow

```
/start
  → Language choice (buttons: Italiano / English / Русский)
  → Welcome message in selected language
  → Begin guided questionnaire

Section 1: Session info
  → Date of meeting?
  → City?
  → Context? (buttons: dinner / coffee / walk / bar / other)
  → Duration? (buttons: <30min / 30–60min / 1–2h / 2h+)
  → Your codename?

Section 2: Person profile
  → Approximate age? (buttons: 18–24 / 25–30 / 31–36 / 37–45 / 45+)
  → Gender? (buttons: woman / man / non-binary / prefer not to say)
  → Occupation type? (buttons: office / physical / mixed / student / other)

Section 3: Sleep
  → Usual bedtime? (free text, e.g. "23:30")
  → Usual wake time? (free text)
  → Weekend shift? (buttons: earlier / same / later / much later)
  → Sleep quality? (buttons: good / average / poor)
  → Chronotype? (buttons: morning / night / mixed)
  → Sleep issues mentioned? (buttons: yes / no)
  → Confidence on sleep data? (buttons: 1-said clearly / 2-inferred / 3-rough guess)

Section 4: Physical activity
  → Regular exercise? (buttons: yes / no / sometimes)
  → Type? (free text)
  → Frequency? (buttons: daily / 3–4x/week / 1–2x/week / rarely)
  → Preferred time? (buttons: morning / afternoon / evening / no preference)
  → Daily walking level? (buttons: low <3k / medium 3–8k / high 8–15k / very high 15k+)
  → Confidence? (buttons: 1 / 2 / 3)

Section 5: Energy
  → Peak energy time? (buttons: morning / midday / afternoon / evening / night)
  → Post-lunch drop? (buttons: yes / no / sometimes)
  → Evening preference? (buttons: go out / stay in / depends)

Section 6: Temperature
  → Sleep temperature preference? (buttons: cool / warm / no preference)
  → Runs cold or warm? (buttons: always cold / always warm / balanced)

Section 7: Compatibility attitudes
  → Bedtime difference would bother them? (buttons: yes / no / depends)
  → Importance of shared schedule? (buttons: 1 / 2 / 3 / 4 / 5)
  → Importance of shared activity? (buttons: 1 / 2 / 3 / 4 / 5)
  → Past friction about habits mentioned? (buttons: yes / no)

Section 8: Overall impression
  → Lifestyle estimate? (buttons: sedentary / moderately active / very active)
  → Observed chronotype? (buttons: early bird / night owl / intermediate)
  → Any free notes? (free text, optional — can skip)

/done
  → Bot appends one row to Google Sheet
  → Bot sends structured JSON recap to founder's chat
  → Bot sends plain-text recap to researcher
```

---

## Language support

The first interaction is always language selection. The selected language applies to:
- welcome and help messages
- button labels
- question prompts
- completion message

Supported languages in Phase 0:
- Italian
- English
- Russian

All stored values in Google Sheet should use canonical English values to keep analysis
consistent across researchers. The translated UI is only a presentation layer.

Example:
- UI button shown to Italian user: `Mattina`
- Stored value in sheet: `morning`

---

## Output format

### Google Sheet

Each completed interview appends one row to a shared spreadsheet.
The first sheet tab should be named `responses`.

Recommended columns:

```text
timestamp_submitted
researcher_codename
language
session_date
city
context
duration
age_range
gender
occupation_type
usual_bedtime
usual_wake_time
weekend_shift
sleep_quality
self_reported_chronotype
sleep_issues_mentioned
sleep_confidence
regular_exercise
exercise_type
exercise_frequency
exercise_time_preference
walking_level
activity_confidence
peak_energy_time
post_lunch_drop
evening_preference
sleep_temperature_preference
general_temperature_tendency
bedtime_difference_bothers
shared_schedule_importance
shared_activity_importance
past_friction_mentioned
lifestyle_estimate
observed_chronotype
free_notes
```

### Founder chat (JSON)

The founder still receives a structured JSON payload via Telegram for fast review.
This is a notification and audit trail, not the source of truth.

### Researcher recap (plain text)

The bot also returns a readable recap to the researcher for confirmation.

---

## Source of truth

The Google Sheet is the canonical storage for collected field interviews.
Telegram messages are notifications only and must not be treated as the primary archive.

---

## Technical stack

| Component | Choice | Reason |
|---|---|---|
| Language | Python 3.11 | Fast to build, best Telegram bot library |
| Library | python-telegram-bot 20.x | Async, well maintained, ConversationHandler built-in |
| Storage | Google Sheets via `gspread` | Shared, persistent, easy to review and export |
| Hosting | Railway / Fly.io / local machine | Bot only needs lightweight hosting |
| State | In-memory (ConversationHandler) | Interview sessions are short |
| Credentials | Google Service Account + env vars | Smallest reliable setup |

---

## Google Sheets setup

1. Create a Google Sheet and name the first tab `responses`
2. Create a Google Cloud project
3. Enable **Google Sheets API** and **Google Drive API**
4. Create a **Service Account**
5. Generate a JSON key for that service account
6. Share the Google Sheet with the service account email as **Editor**
7. Store the JSON credentials as an environment variable
8. Store the spreadsheet ID as an environment variable

The bot opens the spreadsheet by ID and appends a single row per completed interview.

---

## File structure

```text
research-bot/
  bot.py
  handlers/
    language.py
    session.py
    person.py
    sleep.py
    activity.py
    energy.py
    temperature.py
    compatibility.py
    impression.py
  formatters/
    json_output.py
    text_recap.py
    sheet_row.py
  services/
    google_sheets.py
  i18n/
    it.py
    en.py
    ru.py
  config.py
  requirements.txt
  .env.example
```

---

## Environment variables

```text
BOT_TOKEN=<your Telegram bot token from @BotFather>
FOUNDER_CHAT_ID=<your personal Telegram chat ID>
GOOGLE_SHEET_ID=<spreadsheet id from Google Sheets URL>
GOOGLE_CREDENTIALS_JSON=<single-line JSON string for the service account>
```

Notes:
- `GOOGLE_CREDENTIALS_JSON` should contain the raw service account JSON encoded as one line
- Do not commit credentials to the repository
- `.env.example` should show placeholders only

---

## Failure handling

- If Telegram delivery to founder chat fails, the sheet write should still complete
- If Google Sheet write fails, the bot should warn the researcher and not claim success
- Duplicate submission protection should be handled by appending only after `/done`
- A partial abandoned conversation should not write any row

---

## Build estimate

| Task | Time |
|---|---|
| Bot scaffold + ConversationHandler | 2h |
| Multilingual prompt layer | 2h |
| All 8 question sections | 3h |
| Google Sheets integration | 2h |
| JSON + plain-text formatters | 1h |
| Test with 2–3 real sessions | 1h |
| **Total** | **~11h** |

Realistic timeline: **1–2 days** working part-time.

---

## Next steps

1. Create the bot with @BotFather
2. Create the Google Sheet and service account
3. Run the bot locally with one test interview
4. Deploy to Railway
5. Share the bot with trusted friends who conduct interviews

When you are ready to build, say **"build the field research bot"** and the full
implementation (TDD, test file first) will be generated.
