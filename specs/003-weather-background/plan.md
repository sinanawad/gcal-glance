# Implementation Plan: Weather Background for Date Display

**Branch**: `003-weather-background` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-weather-background/spec.md`

## Summary

Add ambient weather visuals behind the date area in the clock column. Uses WeatherAPI.com free-tier API with an embedded API key. Calm conditions (clear, cloudy, fog) render as static CRT-styled CustomPainter icons; dynamic conditions (rain, snow, thunderstorm) use subtle particle animations. Current temperature shown as small text. Location configured via 'W' keyboard shortcut, persisted in secure storage. Weather polled every 30 minutes, independent of calendar polling.

## Technical Context

**Language/Version**: Dart 3.11.0 / Flutter 3.41.2
**Primary Dependencies**: http (already available), dart:convert, flutter_secure_storage (already available)
**Storage**: flutter_secure_storage for location persistence (libsecret on Linux)
**Testing**: flutter_test + mocktail (existing patterns)
**Target Platform**: Linux desktop (primary)
**Project Type**: Desktop app (Flutter)
**Performance Goals**: Weather fetch async, no UI blocking; particle animations at 60fps within existing ValueNotifier tick
**Constraints**: No new package dependencies; API key embedded as compiled constant
**Scale/Scope**: Single user, single location, 48 API calls/day

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Widget Composition & Separation | PASS | New model in `lib/models/`, new service in `lib/services/`, new widget in `lib/widgets/` |
| II. Stateless by Default | PASS | WeatherBackground is StatelessWidget; weather state lives in CalendarHomePage (existing pattern) |
| III. Immutable Models | PASS | WeatherCondition and WeatherLocation are immutable with final fields |
| IV. Secure Credential Handling | PASS | API key in gitignored config file; location in flutter_secure_storage |
| V. Defensive API Integration | PASS | All API responses validated; null/error handled gracefully; unknown codes fall back to "cloudy" |
| VI. Efficient Rendering | PASS | Weather visual uses ValueListenableBuilder scoped to weather data; particle animation driven by existing per-second clock tick |
| VII. Testability | PASS | WeatherService accepts http.Client via constructor; model tests need no network |
| Security Requirements | PASS | API key gitignored; no new OAuth scopes; http-only external call (HTTPS) |
| UI & UX Standards | PASS | CRT aesthetic maintained; date text legible over weather visual (low opacity background) |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/003-weather-background/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: API research and decisions
├── data-model.md        # Phase 1: Entity definitions
├── quickstart.md        # Phase 1: Setup guide
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
lib/
├── config/
│   ├── weather_config.example.dart    # NEW — API key template
│   └── weather_config.dart            # NEW (gitignored) — actual key
├── models/
│   └── weather_condition.dart         # NEW — WeatherCondition, WeatherCategory, WeatherLocation
├── services/
│   └── weather_service.dart           # NEW — WeatherAPI.com API client
├── widgets/
│   ├── weather_background.dart        # NEW — CustomPainter for icons + particle animations
│   └── clock_column.dart              # MODIFIED — Stack weather behind date, show temp
├── screens/
│   └── calendar_home_page.dart        # MODIFIED — Weather state, polling, 'W' shortcut
└── main.dart                          # MODIFIED — Import weather config

test/
├── models/
│   └── weather_condition_test.dart    # NEW — Model + category mapping tests
└── services/
    └── weather_service_test.dart      # NEW — API response parsing tests
```

**Structure Decision**: Follows existing single-project layout. New files mirror the established pattern: model in `models/`, service in `services/`, widget in `widgets/`. No new directories needed.
