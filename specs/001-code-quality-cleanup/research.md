# Research: Code Quality Cleanup

**Branch**: `001-code-quality-cleanup` | **Date**: 2026-02-22

## 1. Embedded OAuth Credentials & Auth Flow

**Decision**: Embed OAuth client ID/secret as compiled constants in the
app. Use `googleapis_auth`'s `obtainAccessCredentialsViaUserConsent()`
with a loopback redirect to handle the browser-based OAuth flow.

**Rationale**: The current approach requires each user to create a Google
Cloud project and download credential files — a developer-level task.
For desktop apps, Google's OAuth documentation states that client secrets
are "not truly secret" since they ship in distributed binaries. Embedding
them is the standard approach for installed applications.

**Implementation**:
- Store client ID/secret as Dart constants (e.g., `lib/config/oauth_config.dart`)
- Add `oauth_config.dart` to `.gitignore` and provide a
  `oauth_config.example.dart` template for developers
- The existing `obtainAccessCredentialsViaUserConsent()` call already
  opens a browser and handles the loopback redirect — this part works
  correctly today
- Remove all references to `go-gcal-cli-credentials.json`

**Alternatives considered**:
- Keep external credential file — unusable for non-developer users.
- `google_sign_in` package — primarily for mobile/web, limited desktop
  support, adds complexity without benefit since `googleapis_auth` already
  handles desktop OAuth correctly.
- Dart `--dart-define` build flags — viable but less ergonomic than a
  config file for development.

## 2. Secure Token Storage

**Decision**: Use `flutter_secure_storage` for token persistence.
Listen to `AutoRefreshingAuthClient.credentialUpdates` stream to persist
refreshed tokens.

**Rationale**: `flutter_secure_storage` uses platform-native secure
storage (libsecret/GNOME Keyring on Linux, Keychain on macOS, DPAPI on
Windows). This replaces plain-text `token.json` files. The
`credentialUpdates` broadcast stream from `googleapis_auth` emits on
every token refresh, ensuring refreshed tokens are always persisted.

**New dependency**: `flutter_secure_storage: ^9.0.0`

**Implementation**:
- Store serialized `AccessCredentials` JSON in secure storage under a
  known key (e.g., `gcal_oauth_token`)
- Listen to `credentialUpdates` stream wherever `_client` is assigned
- On sign-out, delete the secure storage key
- On corrupted data, clear the key and prompt re-auth

**Alternatives considered**:
- Plain-text `token.json` in app data dir — insecure, readable by any
  process running as the same user.
- `path_provider` + file with restrictive permissions — better than CWD
  but still plain text; libsecret is the Linux-standard approach.
- Periodic save on a timer — races with refresh timing.

## 3. Scoped UI Rebuilds

**Decision**: Use `ValueNotifier<DateTime>` + `ValueListenableBuilder`.

**Rationale**: Built-in Flutter, zero external dependencies, scoped
rebuild. A `ValueNotifier` ticked every second drives only the clock and
countdown widgets via `ValueListenableBuilder`. The event list cards
remain static between 60-second data polls.

**Alternatives considered**:
- `StreamBuilder` + timer stream — heavier abstraction for a simple tick.
- `AnimatedBuilder` + `Ticker` — overkill; rebuilds at 60fps unless
  throttled.
- Provider/Riverpod — adds external dependency for a single notifier.

## 4. Error Notification Widget

**Decision**: Use `SnackBar` with `SnackBarBehavior.floating`.

**Rationale**: Network errors and auth failures are informational and
transient. `SnackBar` is the correct Material 3 pattern: auto-dismissing,
non-blocking, supports an action button (e.g., "Retry"). Constrain width
to ~400px on wide desktop screens.

**Alternatives considered**:
- `MaterialBanner` — designed for persistent messages requiring user
  acknowledgment; too heavy for transient errors.
- Custom overlay — unnecessary when M3 provides a standard widget.

## 5. Widget Testing Strategy

**Decision**: Use `mocktail` with service-level mocking.

**Rationale**: `mocktail` requires no code generation (`build_runner`),
has native null-safety support, and simpler syntax than `mockito`. Mock
`GoogleCalendarService` at the service boundary rather than `http.Client`
directly. Refactor `CalendarHomePage` to accept the service via
constructor parameter.

**New dependency**: `mocktail: ^1.0.0` (dev only).

**Alternatives considered**:
- `mockito` — requires `build_runner` and `@GenerateMocks` annotations;
  heavier setup for a small project.
- Manual fake classes — viable but `mocktail` provides better verification
  APIs with less boilerplate.

## Summary

| Topic | Decision | Key Change |
|-------|----------|------------|
| OAuth credentials | Embedded constants | Remove external `go-gcal-cli-credentials.json` |
| Token storage | `flutter_secure_storage` | Replace plain-text `token.json` with libsecret |
| Token refresh | `credentialUpdates` stream listener | Persist to secure storage on each refresh |
| Scoped rebuilds | `ValueNotifier` + `ValueListenableBuilder` | Replace whole-tree `setState` |
| Error notifications | `SnackBar` (floating, M3) | Add `ScaffoldMessenger.showSnackBar()` |
| Testing | `mocktail` + service injection | Constructor-inject service, add dev dep |
