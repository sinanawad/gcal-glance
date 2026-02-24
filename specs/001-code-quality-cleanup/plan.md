# Implementation Plan: Code Quality Cleanup

**Branch**: `001-code-quality-cleanup` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-code-quality-cleanup/spec.md`

## Summary

Remediate security issues (fragile credential paths, leaked HTTP clients,
unpersisted token refreshes), performance problems (full-tree rebuilds
every second, stale event status, O(n²) list computation), and Flutter
anti-patterns (monolithic files, silent errors, missing empty/error
states). Restructure into standard Flutter file layout with testable
service injection.

## Technical Context

**Language/Version**: Dart ^3.8.1 (Flutter SDK)
**Primary Dependencies**: flutter, googleapis ^14.0.0, googleapis_auth ^2.0.0, url_launcher ^6.3.1, flutter_secure_storage ^9.0.0 (new)
**Storage**: Secure storage via libsecret (Linux) / Keychain (macOS) / DPAPI (Windows) for OAuth tokens. OAuth client credentials embedded as compiled constants.
**Testing**: flutter_test + mocktail ^1.0.0 (new dev dep)
**Target Platform**: Linux desktop (primary), cross-platform secondary
**Project Type**: Desktop app
**Performance Goals**: <1% CPU idle (always-on dashboard), scoped 1-second rebuilds
**Constraints**: No external state management packages; use built-in ValueNotifier
**Scale/Scope**: ~575 LOC Dart, 2 source files → ~8 source files after restructuring

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Widget Composition & Separation | VIOLATION → WILL FIX | Current: 2 files. Plan: split into models/, services/, widgets/, screens/ |
| II. Stateless by Default | VIOLATION → WILL FIX | App state in StatefulWidget. Plan: ValueNotifier for clock, keep StatefulWidget only for ephemeral state |
| III. Immutable Models | VIOLATION → WILL FIX | Status cached at construction. Plan: compute via method with `now` param |
| IV. Secure Credential Handling | VIOLATION → WILL FIX | External credential file required, plain-text tokens, no refresh persist, leaked clients. Fix: embed OAuth creds, use flutter_secure_storage, listen to credentialUpdates |
| V. Defensive API Integration | VIOLATION → WILL FIX | Silent errors. Plan: SnackBar feedback on all error paths |
| VI. Efficient Rendering | VIOLATION → WILL FIX | Full setState every 1s. Plan: ValueListenableBuilder for clock/countdowns |
| VII. Testability | VIOLATION → WILL FIX | Hardcoded service, placeholder test. Plan: constructor injection + mocktail |
| Security: URL validation | PASS | Only opens hangoutLink (Google Meet URLs) |
| Security: Minimal scopes | PASS | Already uses calendarReadonlyScope |
| UI: Material 3 | PASS | Already enabled |
| UI: Distinct states | VIOLATION → WILL FIX | Spinner for empty state. Plan: "No upcoming events" + refresh button |

All violations are in-scope for this feature and will be resolved.

## Project Structure

### Documentation (this feature)

```text
specs/001-code-quality-cleanup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── main.dart                        # App entry point, MaterialApp shell only
├── config/
│   └── oauth_config.dart            # Embedded OAuth client ID/secret (gitignored)
├── models/
│   ├── calendar_event.dart          # CalendarEvent model + EventStatus enum
│   └── time_utils.dart              # formatDuration static helper
├── services/
│   └── google_calendar_service.dart # OAuth flow, secure token storage, API client
├── widgets/
│   ├── clock_widget.dart            # Live clock (ValueListenableBuilder)
│   ├── event_card.dart              # Single event card widget
│   └── event_list.dart              # Grouped event list with precomputed indices
└── screens/
    └── calendar_home_page.dart      # Main screen: auth state, polling, composition

test/
├── models/
│   └── calendar_event_test.dart     # Unit tests for status computation
├── services/
│   └── google_calendar_service_test.dart  # Service tests with mocked HTTP
└── widgets/
    └── calendar_home_page_test.dart # Widget test with mocked service
```

**Structure Decision**: Standard Flutter feature-based layout. Models have
no Flutter imports. Services accept dependencies via constructor. Widgets
are composed in screens. Tests mirror the lib/ structure.

## Complexity Tracking

No unjustified complexity violations. All changes reduce complexity from
the current monolithic structure.
