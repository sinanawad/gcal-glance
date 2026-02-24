# Data Model: Retro CRT UI Redesign

**Branch**: `002-ui-redesign` | **Date**: 2026-02-24

## Existing Entities (Unchanged)

### CalendarEvent

Immutable plain Dart class representing a single calendar event. No changes needed — all existing fields and computed methods are reused by the new UI.

| Field | Type | Description |
|-------|------|-------------|
| summary | String | Event title |
| startTime | DateTime | Event start |
| endTime | DateTime | Event end |
| meetingLink | String? | Google Meet URL (from hangoutLink) |

| Computed Method | Returns | Description |
|-----------------|---------|-------------|
| status(DateTime now) | EventStatus | ongoing / upcoming / normal |
| progress(DateTime now) | double | 0.0–1.0 fraction elapsed (ongoing only) |
| countdown(DateTime now) | Duration | Time until start or end |

### EventStatus (enum)

`ongoing` | `upcoming` | `normal` — unchanged thresholds (10-minute upcoming window, strict isAfter/isBefore boundaries).

## New UI Entities

These are UI-only constructs (not persisted, not part of the domain model). They live in config or are computed at render time.

### CrtTheme (lib/config/crt_theme.dart)

Centralized color palette and theme factory. All color constants as static `Color` values.

| Constant | Hex | Usage |
|----------|-----|-------|
| background | #1a1a2e | Scaffold, clock column |
| timelineBg | #0d0d1a | Timeline strip background |
| ongoing | #4fc3f7 | Ongoing event blocks, hero card accent |
| upcoming | #ffb74d | Upcoming event blocks, compact row accent |
| normal | #66bb6a | Normal event blocks, compact row accent |
| clockFlap | #2d2d44 | Flip clock flap background |
| clockDigit | #e0e0e0 | Flip clock digit text |
| textPrimary | #e0e0e0 | Primary text color |
| textSecondary | #b0b0b0 | Secondary/dimmed text |
| joinActive | #ef5350 | JOIN button with meeting link |
| joinDisabled | #757575 | JOIN button without link |

### TimelineViewport (computed at render time)

Not a persisted entity — computed each frame by the timeline painter.

| Property | Type | Description |
|----------|------|-------------|
| startTime | DateTime | Left edge of visible timeline (start of most recently ended event, or first event of day) |
| endTime | DateTime | Right edge (end of last today event + padding) |
| nowPosition | double | Pixel X-coordinate of current time within viewport |

### HeroCardData (computed at render time)

Derived from the event list each frame. Not a separate class — just the selection logic.

| Rule | Description |
|------|-------------|
| Selection | Among all ongoing events, pick the one with the earliest endTime |
| Fallback | If no ongoing event, hero card is not displayed; detail area starts with compact rows |

## Entity Relationships

```text
GoogleCalendarService
  └── fetches → List<CalendarEvent>   (unchanged)

CalendarHomePage
  ├── passes events to → TimelineStrip (today's events only)
  ├── passes events to → DetailArea (ongoing + future events)
  │   ├── selects hero → HeroCard (ongoing event ending soonest)
  │   └── lists others → CompactEventRow (remaining events)
  └── passes time to → ClockColumn → FlipClock → FlipDigit

CrtTheme
  └── provides ThemeData to → MaterialApp (consumed by all widgets)
```

## State Transitions

No new state transitions. The existing `EventStatus` state machine is unchanged:

```text
normal ──(within 10 min)──→ upcoming ──(past start time)──→ ongoing ──(past end time)──→ normal
```

The timeline viewport range transitions smoothly when a meeting ends (animated scroll).
