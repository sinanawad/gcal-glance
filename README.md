# gcal-glance

A Flutter desktop app that shows your upcoming Google Calendar events at a glance.

## Features

- Live clock in the app bar
- Color-coded events: blue (ongoing), orange (upcoming in <10 min), grey (later)
- Real-time countdown timers for each event
- One-click join for Google Meet links
- Shows today's and tomorrow's events
- Auto-refreshes every 60 seconds
- Secure token storage via libsecret (Linux)
- User-visible error feedback via SnackBars

## Setup

### For developers (building from source)

1. Create a Google Cloud project and enable the Google Calendar API
2. Create OAuth 2.0 Desktop credentials
3. Copy `lib/config/oauth_config.example.dart` to `lib/config/oauth_config.dart`
4. Fill in your `clientId` and `clientSecret`
5. Run the app:

```bash
flutter run -d linux
```

6. Sign in with your Google account when prompted — tokens are stored securely and persist across sessions

### Requirements

- Flutter SDK (Dart ^3.11.0)
- Linux build dependencies: `clang`, `ninja-build`, `libgtk-3-dev`, `libsecret-1-dev`, `lld`

```bash
sudo apt install clang ninja-build libgtk-3-dev libsecret-1-dev lld
```

## Project structure

```
lib/
  config/       OAuth credentials (gitignored)
  models/       CalendarEvent, TimeUtils (pure Dart)
  services/     GoogleCalendarService (auth + API)
  widgets/      ClockWidget, EventCard, EventList
  screens/      CalendarHomePage
  main.dart     App shell
```

## Testing

```bash
flutter test
flutter analyze
```
