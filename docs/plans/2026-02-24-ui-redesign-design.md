# Design: Retro CRT UI Redesign

**Date**: 2026-02-24
**Feature Branch**: `002-ui-redesign`
**Status**: Approved

## Context

gcal-glance is a personal desktop calendar widget (1400x450, no decorations) that sits on the top of a portrait monitor. The current UI uses Material 3 defaults with a grey background, standard cards, and a text-only clock. The user wants a retro/pixel art aesthetic with better use of space and improved glanceability.

## Design Decisions

### Layout: Left Clock Column + Two-Row Right Area

```
┌────────┬──────────────────────────────────────────────────────────┐
│        │ 09   10    11    12    13   14   15   16   17            │
│ ╔14╗   │ ··┃1:1 ┃Sprint┃·····┃Lnch┃··┃Plan┃···················  │
│ ╔30╗   │   └────┘──────┘     └────┘  └────┘                      │ ~100px
│        │         ▲NOW  ⏱ ends in 12m                              │ TIMELINE
│ MON    ├──────────────────────────────────────────────────────────┤
│ 24     │                                                          │
│ FEB    │  ╔════════════════════════════════════════════════════╗  │
│ 2026   │  ║ ▶ 1:1 with Alex         10:00 → 10:30            ║  │
│        │  ║   ████████████░░░░░░░░  62%            [▶ JOIN]   ║  │ ~350px
│        │  ╚════════════════════════════════════════════════════╝  │ DETAIL
│        │                                                          │
│        │  ○ Sprint Review    10:00→10:30              In 12m     │
│        │  ○ Standup          10:30→10:45              In 42m     │
│        │  ○ Lunch sync       12:00→12:30                         │
│        │                                                          │
└────────┴──────────────────────────────────────────────────────────┘
 ~180px                    ~1220px
```

**Rationale**: Clock on the left creates a natural "glance left for time, right for events" pattern. The timeline strip gives a bird's-eye view of the full day, while the detail area below provides event specifics. The full-height clock column anchors the layout visually.

### Clock: Split-Flap / Flip Clock

- Large flip clock digits (hours and minutes) centered in the left column
- Dark slate flaps (#2d2d44) with bright white digits (#e0e0e0)
- Date displayed below in stacked format: day-of-week, day number, month, year
- Updates every second (same as existing clock behavior)
- Retro split-flap feel — each digit in its own "flap" container with rounded corners and subtle shadow

### Timeline Strip

- Dark background (#0d0d1a) to visually separate from detail area
- Hour markers along the top edge (09, 10, 11, ... 17)
- Event blocks positioned proportionally by start/end time
- Block width proportional to event duration
- Truncated event titles inside blocks in a small pixel-style font
- Color-coded by status: phosphor blue (ongoing), warm amber (upcoming), dim green (normal)
- NOW marker: vertical line at current time position with countdown text
  - During event: "ends in Xm"
  - Before next event: "next in Xm"
- Overlapping events: stack vertically (thin blocks)
- Timeline auto-positions to keep NOW marker visible

### Detail Area: Hero Card + Compact Rows

**Hero card** (ongoing event):
- Prominent bordered card with phosphor blue glow/accent
- Contains: event title, time range (HH:MM → HH:MM), progress bar with percentage, JOIN button
- JOIN button: red (#ef5350) when meeting link available, grey when disabled
- Appears only when an event is ongoing; otherwise detail area starts with compact rows

**Compact rows** (all other events):
- Single-line entries: status dot (colored), event title, time range, countdown
- Upcoming events (within 10 min): amber dot and text
- Normal events: dim green dot
- Scrollable when list exceeds visible space

### Color Palette: Dark CRT

| Element          | Color           | Hex       |
|------------------|-----------------|-----------|
| Background       | Deep navy-black | `#1a1a2e` |
| Timeline bg      | Darker strip    | `#0d0d1a` |
| Ongoing          | Phosphor blue   | `#4fc3f7` |
| Upcoming         | Warm amber      | `#ffb74d` |
| Normal           | Dim green       | `#66bb6a` |
| Clock flaps      | Dark slate      | `#2d2d44` |
| Clock digits     | Bright white    | `#e0e0e0` |
| Primary text     | Bright          | `#e0e0e0` |
| Secondary text   | Dimmed          | `#b0b0b0` |
| JOIN (active)    | Red accent      | `#ef5350` |
| JOIN (disabled)  | Grey            | `#757575` |

### Behavioral Preservation

All existing logic is preserved:
- Event status model (ongoing/upcoming/normal with same thresholds)
- OAuth authentication flow
- Secure token storage
- 60-second API polling
- 1-second clock/countdown updates via ValueNotifier
- Error handling via SnackBars
- Meeting link validation (https scheme only)
- Tomorrow separator between day groups

### Sign-In Screen

Same dark CRT background with a styled sign-in button — retro aesthetic maintained even before authentication.

## Alternatives Considered

1. **Clock on the right**: Rejected because the timeline strip benefits from full width, and left-side clock creates a natural reading flow.
2. **Clock embedded in timeline at NOW position**: Creative but makes the timeline harder to read and the clock position shifts throughout the day.
3. **Uniform event list (no hero card)**: Shows more events but loses the "what's happening NOW" emphasis that makes glancing effective.
4. **Compact header + tall detail**: Sacrifices clock readability for marginal extra detail space — not worth it at 450px height.
5. **Cyberpunk neon palette**: Too vibrant for an all-day glance widget; the CRT palette is easier on the eyes.
