# Synca — Field Research Telegram Bot

**Version:** 1.0  
**Last updated:** May 2026  
**Status:** Planned — Phase 0

---

## Purpose

A lightweight Telegram bot that replaces the paper transcription form.
Instead of filling in a Markdown table after a date, the researcher answers
a short guided conversation with the bot. The bot then:

1. Sends a structured JSON summary to the founder's private Telegram chat
2. Optionally sends a plain-text recap to the researcher so they can forward it manually

This removes friction from the data collection flow and ensures consistent field formatting.

---

## Scope

This is a **research tool only** — not part of the Synca app.
It runs as a standalone Python script (python-telegram-bot library).
No database, no server — data arrives as Telegram messages.

---

## Bot flow

```
/start
  → Welcome message (EN/IT/RU choice)
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
  → Bot sends structured JSON recap to founder's chat
  → Bot sends plain-text recap to researcher
```

---

## Output format

### To founder's chat (JSON)

```json
{
  "session": {
    "date": "29/05/2026",
    "city": "Moscow",
    "context": "dinner",
    "duration": "2h+",
    "researcher": "alpha"
  },
  "person": {
    "age_range": "25-30",
    "gender": "woman",
    "occupation": "office"
  },
  "sleep": {
    "bedtime": "00:30",
    "wake_time": "08:00",
    "weekend_shift": "later",
    "quality": "average",
    "chronotype": "night",
    "issues": false,
    "confidence": 1
  },
  "activity": {
    "regular_exercise": "sometimes",
    "type": "yoga",
    "frequency": "1-2x/week",
    "preferred_time": "morning",
    "walking_level": "medium 3-8k",
    "confidence": 2
  },
  "energy": {
    "peak_time": "evening",
    "post_lunch_drop": "no",
    "evening_preference": "go out"
  },
  "temperature": {
    "sleep_preference": "warm",
    "general": "always cold"
  },
  "compatibility": {
    "bedtime_diff_bothers": "depends",
    "shared_schedule_importance": 3,
    "shared_activity_importance": 2,
    "past_friction_mentioned": false
  },
  "impression": {
    "lifestyle": "moderately active",
    "chronotype_observed": "night owl",
    "notes": "Said she can't function before 9am. Very clear about it."
  }
}
```

### To researcher (plain text recap)

```
✅ Synca Research — Session saved

📅 29/05/2026 · Moscow · dinner · 2h+
👤 Woman, ~25–30, office worker

😴 Sleep: goes to bed ~00:30, wakes ~08:00 (later on weekends)
   Quality: average · Chronotype: night · Confidence: clear

🏃 Activity: yoga 1–2x/week, mornings · Walking: medium
   Confidence: inferred

⚡ Energy: peaks in the evening · No post-lunch drop · Prefers going out

🌡️ Temperature: warm sleeper · Always cold

❤️ Compatibility: bedtime diff — depends · Schedule importance: 3/5 · Activity together: 2/5

📝 Notes: Said she can't function before 9am. Very clear about it.
```

---

## Technical stack

| Component | Choice | Reason |
|---|---|---|
| Language | Python 3.11 | Fast to build, best Telegram bot library |
| Library | python-telegram-bot 20.x | Async, well maintained, ConversationHandler built-in |
| Storage | None (Telegram messages only) | Zero infra, no server, data arrives as messages |
| Hosting | Local machine or free tier (Railway / Fly.io) | Bot only needs to be running, not always on |
| State | In-memory (ConversationHandler) | Sessions are short, no persistence needed |

---

## File structure

```
research-bot/
  bot.py               # main entry point, ConversationHandler setup
  handlers/
    session.py         # Section 1: session info
    person.py          # Section 2: person profile
    sleep.py           # Section 3: sleep
    activity.py        # Section 4: physical activity
    energy.py          # Section 5: energy rhythms
    temperature.py     # Section 6: temperature
    compatibility.py   # Section 7: compatibility attitudes
    impression.py      # Section 8: overall impression
  formatters/
    json_output.py     # builds JSON payload for founder chat
    text_recap.py      # builds plain-text recap for researcher
  config.py            # BOT_TOKEN, FOUNDER_CHAT_ID from env vars
  requirements.txt
  .env.example
```

---

## Environment variables

```
BOT_TOKEN=<your Telegram bot token from @BotFather>
FOUNDER_CHAT_ID=<your personal Telegram chat ID>
```

---

## Build estimate

| Task | Time |
|---|---|
| Bot scaffold + ConversationHandler | 2h |
| All 8 question sections | 3h |
| JSON formatter | 1h |
| Plain-text recap formatter | 1h |
| Test with 2–3 real sessions | 1h |
| **Total** | **~8h** |

Realistic timeline: **1–2 days** working part-time.

---

## Next steps

1. Create a new bot with @BotFather → get `BOT_TOKEN`
2. Get your `FOUNDER_CHAT_ID` (send `/start` to @userinfobot)
3. Run `bot.py` locally to test
4. Deploy to Railway (free tier, always-on)
5. Share bot link with field researchers

When you are ready to build, say **"build the research bot"** and the full
implementation (TDD, test file first) will be generated.
