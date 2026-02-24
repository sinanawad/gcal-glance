# Implementation Plan: Retro CRT UI Redesign

**Branch**: `002-ui-redesign` | **Date**: 2026-02-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-ui-redesign/spec.md`

## Summary

Replace the current Material 3 default UI with a retro CRT-inspired layout featuring a split-flap flip clock in a left column, a horizontal timeline strip with event blocks and NOW marker, and a detail area with hero card (ongoing event) + compact rows (upcoming events). Dark navy-black palette (#1a1a2e), pixel fonts (Press Start 2P, VT323) via google_fonts, and scoped per-second animations. All existing business logic (models, services, auth, polling) remains unchanged.

## Technical Context

**Language/Version**: Dart 3.11.0 / Flutter 3.41.2
**Primary Dependencies**: googleapis 16.x, googleapis_auth 2.x, flutter_secure_storage 10.x, url_launcher 6.x, google_fonts (NEW)
**Storage**: flutter_secure_storage (libsecret on Linux) — unchanged
**Testing**: flutter_test + mocktail — existing model/service tests unchanged, widget tests updated
**Target Platform**: Linux desktop (1400x450, no decorations)
**Project Type**: Desktop app
**Performance Goals**: 60fps flip clock animations, <16ms per build frame
**Constraints**: Fixed 1400x450 window, single user, ~9-15 events/day
**Scale/Scope**: Single-user personal dashboard, ~15 source files affected

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Widget Composition & Separation | PASS | New widgets each in own file under lib/widgets/, screen in lib/screens/ |
| II. Stateless by Default | PASS | All new widgets StatelessWidget except FlipDigit (owns animation state — permitted per constitution). App-level state stays in CalendarHomePage |
| III. Immutable Models | PASS | CalendarEvent unchanged. No new mutable models |
| IV. Secure Credential Handling | PASS | Auth/token flow unchanged |
| V. Defensive API Integration | PASS | Error handling unchanged, SnackBars preserved |
| VI. Efficient Rendering | PASS | ValueNotifier pattern preserved. Flip animation scoped to individual digit widgets. Timeline uses CustomPainter (single paint pass) |
| VII. Testability | PASS | New widgets accept data via constructor. FlipClock testable with mock ValueNotifier |
| Security: URL validation | PASS | https-only scheme check preserved |
| Security: Minimum scopes | PASS | calendar.readonly unchanged |
| UI: Color semantics | PASS | Blue=ongoing, amber=upcoming, green=normal — consistent with constitution |
| UI: WCAG AA contrast | PASS | All palette colors verified ≥4.5:1 against #1a1a2e |
| UI: DateTime.now() once per frame | PASS | Existing ValueNotifier<DateTime> reused |
| UI: Material 3 | PASS | useMaterial3: true retained with custom dark CRT ColorScheme |
| UI: Distinct loading/empty/error | PASS | Loading spinner, "No upcoming events" text, SnackBar errors — all restyled for dark theme |

No violations. Complexity Tracking not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-ui-redesign/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0: technology research
├── data-model.md        # Phase 1: data model (unchanged + new UI entities)
├── quickstart.md        # Phase 1: developer quickstart for this feature
├── checklists/          # Quality checklists
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── main.dart                          # MODIFY: CRT theme, google_fonts
├── config/
│   ├── oauth_config.dart              # UNCHANGED (gitignored)
│   ├── oauth_config.example.dart      # UNCHANGED
│   └── crt_theme.dart                 # NEW: Color palette + ThemeData factory
├── models/
│   ├── calendar_event.dart            # UNCHANGED
│   └── time_utils.dart                # UNCHANGED
├── services/
│   └── google_calendar_service.dart   # UNCHANGED
├── screens/
│   └── calendar_home_page.dart        # REWRITE: Clock column + timeline + detail layout
└── widgets/
    ├── clock_column.dart              # NEW: Left column (flip clock + date + exit)
    ├── flip_clock.dart                # NEW: HH:MM split-flap display
    ├── flip_digit.dart                # NEW: Single animated flip digit (StatefulWidget)
    ├── timeline_strip.dart            # NEW: Horizontal timeline with CustomPainter
    ├── now_marker.dart                # NEW: NOW marker + countdown text
    ├── hero_card.dart                 # NEW: Ongoing event hero card
    ├── compact_event_row.dart         # NEW: Single compact event row
    ├── detail_area.dart               # NEW: Scrollable hero + compact rows + tomorrow separator
    ├── clock_widget.dart              # DELETE: Replaced by flip_clock
    ├── event_card.dart                # DELETE: Replaced by hero_card + compact_event_row
    └── event_list.dart                # DELETE: Replaced by detail_area

test/
├── models/
│   └── calendar_event_test.dart       # UNCHANGED (17 tests)
├── services/
│   └── google_calendar_service_test.dart  # UNCHANGED (6 tests)
└── widgets/
    └── calendar_home_page_test.dart   # UPDATE: Adapt to new layout structure
```

**Structure Decision**: Single Flutter project, same directory structure. New widgets added to lib/widgets/, old widgets deleted. Config directory gains crt_theme.dart for centralized palette constants.

## Widget Dependency Graph

```text
CalendarHomePage (StatefulWidget — owns timers, auth state, event data)
├── ClockColumn (StatelessWidget)
│   ├── FlipClock (StatelessWidget — composes 4 FlipDigits + colon)
│   │   └── FlipDigit (StatefulWidget — owns AnimationController for flip)
│   ├── Date display (VT323 font)
│   └── Exit button
├── TimelineStrip (StatelessWidget — CustomPainter)
│   └── NowMarker (StatelessWidget — countdown text)
└── DetailArea (StatelessWidget — scrollable)
    ├── HeroCard (StatelessWidget — ongoing event)
    └── CompactEventRow (StatelessWidget — each non-ongoing event)
```

All leaf widgets consume `ValueNotifier<DateTime>` via `ValueListenableBuilder` for per-second updates, consistent with existing architecture.
