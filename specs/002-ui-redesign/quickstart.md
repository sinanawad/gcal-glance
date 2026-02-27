# Quickstart: Retro CRT UI Redesign

**Branch**: `002-ui-redesign` | **Date**: 2026-02-24

## Prerequisites

- Flutter 3.41.2+ / Dart 3.11.0+ (installed at `/data/dev/sdk/flutter`)
- Linux desktop build dependencies: `ninja-build`, `clang`, `lld`, `libsecret-1-dev`
- OAuth credentials in `lib/config/oauth_config.dart` (see `oauth_config.example.dart`)

## Setup

```bash
git checkout 002-ui-redesign
flutter pub get          # Fetches google_fonts and other deps
```

## New Dependency

This feature adds one new package:

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.0.0   # Press Start 2P + VT323 retro fonts
```

## Build & Run

```bash
flutter run -d linux     # Run with hot reload
flutter build linux      # Release build
```

## Test

```bash
flutter test             # All tests (model + service + widget)
flutter analyze          # Zero issues required
```

## New Files

| File | Purpose |
|------|---------|
| `lib/config/crt_theme.dart` | Color palette constants + ThemeData factory |
| `lib/widgets/clock_column.dart` | Left column: flip clock + date + exit button |
| `lib/widgets/flip_clock.dart` | HH:MM split-flap display composing FlipDigits |
| `lib/widgets/flip_digit.dart` | Single animated flip digit (StatefulWidget) |
| `lib/widgets/timeline_strip.dart` | Horizontal timeline with CustomPainter |
| `lib/widgets/now_marker.dart` | NOW marker + countdown text overlay |
| `lib/widgets/hero_card.dart` | Ongoing event hero card |
| `lib/widgets/compact_event_row.dart` | Compact row for non-ongoing events |
| `lib/widgets/detail_area.dart` | Scrollable hero + compact rows container |

## Deleted Files

| File | Replaced By |
|------|-------------|
| `lib/widgets/clock_widget.dart` | `flip_clock.dart` + `clock_column.dart` |
| `lib/widgets/event_card.dart` | `hero_card.dart` + `compact_event_row.dart` |
| `lib/widgets/event_list.dart` | `detail_area.dart` + `timeline_strip.dart` |

## Modified Files

| File | Changes |
|------|---------|
| `lib/main.dart` | CRT theme via `CrtTheme.themeData()` |
| `lib/screens/calendar_home_page.dart` | Complete layout rewrite (clock column + timeline + detail) |
| `test/widgets/calendar_home_page_test.dart` | Adapt assertions to new layout |
| `pubspec.yaml` | Add `google_fonts` dependency |

## Architecture Notes

- **Models and services are untouched** — only the widget/screen layer changes
- **ValueNotifier<DateTime> pattern preserved** — per-second updates scoped to FlipDigit, NowMarker, HeroCard, CompactEventRow
- **FlipDigit is the only new StatefulWidget** — it owns an AnimationController for the flip animation (permitted by constitution principle II)
- **TimelineStrip uses CustomPainter** — single paint pass for all blocks, markers, and text
- **CrtTheme centralizes all colors** — no hardcoded hex values in widget files
