# Quickstart: Code Quality Cleanup

**Branch**: `001-code-quality-cleanup` | **Date**: 2026-02-22

## Prerequisites

- Flutter SDK (Dart ^3.8.1)
- Linux desktop development toolchain (`clang`, `cmake`, `ninja-build`,
  `pkg-config`, `libgtk-3-dev`, `libsecret-1-dev`)
- For developers: Google Cloud project with Calendar API enabled and
  OAuth 2.0 Desktop credentials (to configure the embedded client ID)

## Setup (Developer)

```bash
# 1. Clone and checkout branch
git checkout 001-code-quality-cleanup

# 2. Install dependencies
flutter pub get

# 3. Configure OAuth credentials (one-time developer setup)
#    Copy the example config and fill in your client ID/secret:
cp lib/config/oauth_config.example.dart lib/config/oauth_config.dart
#    Edit lib/config/oauth_config.dart with your Google Cloud OAuth values.
#    This file is gitignored — credentials stay out of version control.
```

## Setup (End User)

No setup required. Launch the app, click "Sign in with Google",
authorize in the browser. Done.

## Run

```bash
# Run on Linux desktop (primary target)
flutter run -d linux

# The app opens a browser for Google OAuth on first launch.
# Tokens are stored securely via libsecret (GNOME Keyring).
```

## Test

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widgets/calendar_home_page_test.dart

# Run analyzer
flutter analyze
```

## Verify Changes

After completing the cleanup, validate:

1. **Fresh install auth**: On a clean machine (or new user account), launch
   the app and click "Sign in with Google". Verify the browser opens, you
   can authorize, and events load — no file setup needed.

2. **Token persistence**: Sign in, wait for a token refresh (or force one
   by restarting), then restart the app. No re-auth prompt.

3. **Secure storage**: Verify no plain-text `token.json` exists anywhere.
   Tokens should be in GNOME Keyring / libsecret (check with
   `secret-tool search service gcal_app`).

4. **Scoped rebuilds**: Open Flutter DevTools, go to the Performance tab,
   and verify that per-second timer updates only trigger rebuilds on clock
   and countdown widgets.

5. **Error handling**: Disconnect the network while the app is running.
   A SnackBar should appear. Reconnect and verify events refresh.

6. **Empty state**: Clear your calendar for today/tomorrow (or use a test
   account). Verify the app shows "No upcoming events" with a refresh
   button, not a spinner.
