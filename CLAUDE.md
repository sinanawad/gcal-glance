# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run -d linux         # Run on Linux desktop (primary target)
flutter analyze              # Static analysis (must report zero issues)
flutter test                 # Run all tests
flutter test test/path.dart  # Run a single test file
flutter build linux --release  # Build release binary
```

The release binary is at `build/linux/x64/release/bundle/gcal-glance`.

**Important**: The Flutter SDK is at `/data/dev/sdk/flutter/bin` — prepend to PATH in shell commands.

## Architecture

Flutter desktop app (Linux primary) showing Google Calendar events at a glance. CRT retro aesthetic with dark navy background, VT323 font, split-flap clock.

Package name: `gcal_glance` | Display name: `gcal-glance` | Domain: `coach.incremental`

**Source layout**:

```
lib/
├── main.dart                        # Entry point, MaterialApp shell
├── config/
│   ├── crt_theme.dart               # CRT color palette + ThemeData factory
│   └── oauth_config.example.dart    # OAuth credential template (copy to oauth_config.dart)
├── models/
│   ├── calendar_event.dart          # CalendarEvent + EventStatus + ResponseStatus enums
│   └── time_utils.dart              # Duration formatting helper
├── services/
│   └── google_calendar_service.dart # OAuth, token storage, Calendar + People API client
├── widgets/
│   ├── clock_column.dart            # Left column: flip clock, date, meeting countdown, exit
│   ├── flip_clock.dart              # HH:MM flip clock composition
│   ├── flip_digit.dart              # Single split-flap digit with animation
│   ├── hero_card.dart               # Hero card for ongoing meetings (compact/full, tentative)
│   ├── compact_event_row.dart       # Compact event row with status border + crosshatch + contact photo
│   ├── detail_area.dart             # Hero cards + scrollable compact event list
│   └── timeline_strip.dart          # Fixed-NOW sliding 5-hour timeline
└── screens/
    └── calendar_home_page.dart      # Main screen composition + time simulation + photo cache
```

**Key patterns**:
- Models are plain Dart (no Flutter imports), immutable, with derived status computed at read time via `status(DateTime now)`
- `EventStatus` enum: `ongoing`, `upcoming`, `normal`, `past` — past events shown greyed out
- `ResponseStatus` enum tracks RSVP state (accepted/tentative/needsAction/declined); declined filtered out, tentative gets crosshatch overlay
- `ValueNotifier<DateTime>` drives per-second scoped rebuilds (clock, timeline, countdowns)
- Services accept dependencies via constructor injection for testability
- OAuth credentials embedded as compiled constants (gitignored `oauth_config.dart`)
- Tokens stored securely via `flutter_secure_storage` (libsecret on Linux)
- Errors shown to user via `SnackBar` (floating, Material 3)
- Tests use `mocktail` for service-level mocking

## Google APIs

The app uses two Google APIs — both must be enabled in Google Cloud Console:

1. **Calendar API** (`calendar.readonly` scope) — fetches events
2. **People API** (`contacts.readonly` + `directory.readonly` scopes) — fetches contact photos for 1-on-1 meetings

Contact photo flow:
- `fromGoogleEvent()` detects 1-on-1 meetings (exactly 2 non-resource attendees)
- `fetchContactPhoto()` searches personal contacts first, falls back to Workspace directory
- Photos cached in `_photoCache` map in CalendarHomePage, applied via `copyWithPhotoUrl()`

## Auth Setup (Developer)

1. Create a Google Cloud project, enable **Calendar API** and **People API**
2. Create OAuth 2.0 Desktop credentials
3. Copy `lib/config/oauth_config.example.dart` to `lib/config/oauth_config.dart`
4. Fill in your client ID and secret
5. On first run, browser opens for Google sign-in; token persisted to secure storage

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| S | Toggle time simulation controls |
| M | Toggle mute (meeting start chirp) |
| O | Sign out (clears token, triggers re-auth on next launch) |
| C | Toggle calendar picker |

## Event Display Rules

- Only meetings with Google Meet links (`hangoutLink`) get hero card treatment and large font (24px)
- Events without meeting links: smaller font (20px), dimmer colors (60% alpha)
- Tentative events: crosshatch overlay in compact rows + timeline blocks
- Past events: grey (#616161) in compact rows + timeline
- 1-on-1 meetings: show contact photo (or initial) next to title
- Multi-calendar: secondary calendars shown with faded Google Calendar color
- Timeline: NOW fixed at 25% width, 5-hour sliding window, solid/stripe alternation for accepted events

## KDE Desktop Integration

Files outside this repo (on deployment machine):
- `~/.local/share/applications/gcal-glance.desktop` — app menu entry
- `~/.config/autostart/gcal-glance.desktop` — symlink for autostart
- `~/.local/share/kwin/scripts/gcal-glance-placement/` — KWin script for window placement (top of right monitor, hidden from taskbar)

The KWin script uses `workspace.windowAdded` signal to match `resourceClass === "coach.incremental.gcal-glance"` and sets `skipTaskbar = true` + positions on DP-4.

## Recent Changes

- 002-ui-redesign (latest): CRT retro UI, contact photos, past events, multi-calendar, RSVP filtering, meeting chirp, timeline, hero cards, KDE integration
- 001-code-quality-cleanup: App renamed to gcal-glance, restructured into standard Flutter layout, constructor-injected service, derived model status

## Active Technologies

- Dart 3.11.0 / Flutter 3.41.2
- googleapis 16.x (Calendar + People APIs), googleapis_auth 2.x
- flutter_secure_storage 10.x (libsecret on Linux)
- url_launcher 6.x, google_fonts
- GTK3 runner (linux/runner/my_application.cc)
