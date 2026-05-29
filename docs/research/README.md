# docs/research/

This folder contains the Phase 0 field research protocol for Synca.

Before any algorithm is built or any user is onboarded, this protocol collects
qualitative behavioral data from real people through structured conversations
conducted by field researchers (friends of the founder).

## Files

| File | Purpose |
|---|---|
| [`field-guide.md`](./field-guide.md) | Trilingual guide for field researchers — what to ask, how to ask it |
| [`transcription-form.md`](./transcription-form.md) | Structured form to fill in after each session |
| [`field-research-bot.md`](./field-research-bot.md) | Telegram bot spec that replaces the paper form |

## Data flow

```
Field researcher (friend)
  → goes on a date
  → asks questions naturally during conversation
  → fills in Telegram bot immediately after
  → bot sends JSON to founder's chat
  → founder logs anonymised data for Phase 0 analysis
```

## Privacy

All data collected is:
- **Anonymous** — no names, no surnames, no social profiles
- **Self-reported or observed** — no raw health data is extracted from any device
- **Used only for internal research** — not shared outside the founding team
- **Deletable on request** — if a researcher asks to remove a session, it is removed

See [`../product/user-research.md`](../product/user-research.md) for the qualitative
research context that motivates this protocol.
