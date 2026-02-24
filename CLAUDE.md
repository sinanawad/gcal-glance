# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run -d linux         # Run on Linux desktop (primary target)
flutter analyze              # Static analysis (must report zero issues)
flutter test                 # Run all tests
flutter test test/path.dart  # Run a single test file
```

## Architecture

Flutter desktop app (Linux primary) showing Google Calendar events at a glance. Material 3 design.
Package name: `gcal_glance` | Display name: `gcal-glance` | Domain: `coach.incremental`

**Source layout**:

```
lib/
├── main.dart                        # Entry point, MaterialApp shell
├── config/
│   └── oauth_config.example.dart    # OAuth credential template (copy to oauth_config.dart)
├── models/
│   ├── calendar_event.dart          # CalendarEvent + EventStatus enum
│   └── time_utils.dart              # Duration formatting helper
├── services/
│   └── google_calendar_service.dart # OAuth, secure token storage, API client
├── widgets/
│   ├── clock_widget.dart            # Live clock
│   ├── event_card.dart              # Single event card
│   └── event_list.dart              # Grouped event list with precomputed indices
└── screens/
    └── calendar_home_page.dart      # Main screen composition
```

**Key patterns**:
- Models are plain Dart (no Flutter imports), immutable, with derived status computed at read time via `status(DateTime now)`
- Services accept dependencies via constructor injection for testability
- OAuth credentials embedded as compiled constants (gitignored `oauth_config.dart`)
- Tokens stored securely via `flutter_secure_storage` (libsecret on Linux)
- Errors shown to user via `SnackBar` (floating, Material 3)
- Tests use `mocktail` for service-level mocking

## Auth Setup (Developer)

1. Create a Google Cloud project, enable Calendar API
2. Create OAuth 2.0 Desktop credentials
3. Copy `lib/config/oauth_config.example.dart` to `lib/config/oauth_config.dart`
4. Fill in your client ID and secret
5. On first run, browser opens for Google sign-in; token persisted to secure storage

## Recent Changes

- 001-code-quality-cleanup: App renamed to gcal-glance, restructured into standard Flutter layout, constructor-injected service, derived model status, precomputed group indices

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
