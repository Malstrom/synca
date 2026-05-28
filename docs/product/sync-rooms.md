# Sync Rooms — Vision & Architecture

**Version 0.1 — May 2026**

---

## 1. What is a Sync Room?

A Sync Room is a conversational space that exists **only if a verified physical
compatibility exists between all its members**. It is the digital continuation of
a real-world Spark encounter.

> A Sync Room is not a group chat. It is proof that the people inside it have
> actually met and been compatible.

---

## 2. Room Types

| Type | Members | Spark Rule | Use Case |
|------|---------|------------|----------|
| `duo` | 2 | 1 verified Spark between the two | Romantic / friendship match |
| `small_group` | 3–8 | Full graph: every pair must have ≥1 Spark | Friend group, aperitivo crew |
| `event_room` | 9–22 | Every member must have ≥1 Spark with the organiser | Calcetto, beach volley, escape room |

The `duo` type is the default match channel — every accepted Match is a Sync Room
of type `duo` under the hood.

---

## 3. Match as a Special Case of Sync Room

A 1-to-1 Match between Alice and Bob is a Sync Room of type `duo` with 2 members
and a minimum compatibility threshold.

Unifying the two concepts keeps the codebase simple:

```
Match (duo)  →  SyncRoom type: :duo, members: 2
Small Group  →  SyncRoom type: :small_group, members: 3–8
Event Room   →  SyncRoom type: :event_room, members: 9–22
```

The chat, the Action Cable channel, and the expiry logic are shared across all
types. The only thing that varies is the **admission rule** (Spark validation).

### Migration path

- MVP: `Match` model stays as-is.
- Phase 2 (Group Sync): create `SyncRoom`. `Match` becomes
  `SyncRoom.where(room_type: :duo)`.

---

## 4. Admission Rules

### 4.1 Duo

```ruby
# Both users must have a completed SparkSession with score >= threshold
SparkSession.verified_between(user_a, user_b).exists?
```

### 4.2 Small Group

Every pair of members must have at least one verified Spark:

```ruby
# For every combination (u1, u2) in members:
SparkSession.verified_between(u1, u2).exists?
```

If Alice wants to add Bob and Cara but Bob and Cara have never Sparked, the system
surfaces a **facilitation prompt**: Alice can share a deep-link invitation so that
Bob and Cara can open a Spark Session the next time they meet physically.

### 4.3 Event Room

Every new member must have ≥1 Spark with the room **organiser** (creator):

```ruby
SparkSession.verified_between(room.created_by, new_member).exists?
```

This makes the organiser the social guarantor of the group. It is realistic for
sport/event use cases where not everyone knows each other.

---

## 5. Database Schema

```sql
sync_rooms
  id              bigint PK
  name            string
  created_by      bigint FK → users
  room_type       enum: duo | small_group | event_room
  created_at      datetime

sync_room_memberships
  id                  bigint PK
  sync_room_id        bigint FK → sync_rooms
  user_id             bigint FK → users
  spark_session_id    bigint FK → spark_sessions  -- proof of physical encounter
  joined_at           datetime

sync_room_messages
  id              bigint PK
  sync_room_id    bigint FK → sync_rooms
  sender_id       bigint FK → users
  body            text
  read_at         datetime nullable
  created_at      datetime
```

`spark_session_id` in `sync_room_memberships` is the **cryptographic proof** that
a member physically synchronised with the group.

---

## 6. Facilitating a Missing Spark

When a user tries to create a `small_group` room and one pair has not Sparked yet:

1. The API returns a `422` with a structured payload identifying the missing pairs.
2. The client shows a prompt: *"Bob and Cara haven't Synced yet. Share this invite
   so they can meet."*
3. The organiser can share a **Spark Invite Link** — a deep link that pre-configures
   a Spark Session between the two users the next time they are physically together.

This mechanism ensures Sync Rooms always represent real-world trust graphs, not
digital invitation chains.

---

## 7. Premium Gating

| Feature | Free | Premium |
|---------|------|---------|
| Duo Sync Room (Match chat) | ✅ | ✅ |
| Small Group Sync Room | 1 active | Unlimited |
| Event Room | ❌ | ✅ |
| Spark Invite Link (facilitate missing Spark) | ❌ | ✅ |
| Room analytics & compatibility breakdown | ❌ | ✅ |

---

## 8. Action Cable Channels

Each Sync Room maps to a dedicated Action Cable channel:

```ruby
# app/channels/sync_room_channel.rb
class SyncRoomChannel < ApplicationCable::Channel
  def subscribed
    sync_room = SyncRoom.find(params[:room_id])
    reject unless sync_room.member?(current_user)
    stream_for sync_room
  end
end
```

With a few thousand concurrent users at launch, a single Rails server with Action
Cable handles the load comfortably. Redis/Solid Cable adapter can be added later
when horizontal scaling is needed.

---

## 9. Open Questions (Phase 2)

- Maximum lifetime of an Event Room (auto-archive after the event date?).
- Notification strategy when a new message arrives in a room the user has
  backgrounded.
- Whether `event_room` should require a scheduled date/time field.
