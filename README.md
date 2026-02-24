# gcal-glance

A retro CRT-themed desktop dashboard that shows your Google Calendar at a glance. Built with Flutter for Linux.

![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux)

## What it does

gcal-glance is an always-on calendar display designed to sit in the corner of your screen. It connects to your Google Calendar and gives you a real-time view of your day without needing to keep a browser tab open.

### Features

- **Animated flip clock** with VT323 monospace font and split-flap digit transitions
- **5-hour scrolling timeline** with event blocks, overlap hatching, and a live NOW marker
- **Color-coded event status** — cyan (ongoing), amber (starts in <10 min), green (later)
- **Next meeting countdown** below the clock with Google Meet detection
- **Hero card** for the current meeting with progress bar and one-click JOIN button
- **Compact event list** with time, title, and status-colored indicators
- **Auto-refresh** every 60 seconds with graceful error handling
- **Secure OAuth** — tokens stored via libsecret, auto-refreshed silently
- **Time simulation mode** (press `S`) for demoing and debugging

### Design

The UI uses a CRT/retro terminal aesthetic — dark navy background (#1a1a2e), phosphor-green and amber accents, and the VT323 pixel font throughout. The layout is a fixed 180px clock column on the left with the timeline and event detail area filling the rest of the window.

## Getting started

### Prerequisites

- Flutter SDK (Dart ^3.11.0)
- Linux with X11 or Wayland
- System dependencies:

```bash
sudo apt install clang ninja-build libgtk-3-dev libsecret-1-dev lld
```

### Google Cloud setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Enable the **Google Calendar API** under APIs & Services
4. Go to **Credentials** and create an **OAuth 2.0 Client ID** (Desktop application type)
5. Note your Client ID and Client Secret

### Build and run

```bash
# Clone the repo
git clone https://github.com/sinanawad/gcal-glance.git
cd gcal-glance

# Install dependencies
flutter pub get

# Configure OAuth credentials
cp lib/config/oauth_config.example.dart lib/config/oauth_config.dart
# Edit oauth_config.dart and fill in your Client ID and Client Secret

# Run
flutter run -d linux
```

On first launch, click **Sign in with Google** — your browser will open for OAuth consent. Once authorized, tokens are stored securely in your system keyring and persist across sessions.

## Project structure

```
lib/
  main.dart                        App entry point
  config/
    crt_theme.dart                 CRT color palette and Material 3 theme
    oauth_config.example.dart      OAuth credential template
  models/
    calendar_event.dart            CalendarEvent model with status/progress/countdown
    time_utils.dart                Duration formatting helpers
  services/
    google_calendar_service.dart   OAuth flow, token storage, Calendar API client
  screens/
    calendar_home_page.dart        Main screen layout and state management
  widgets/
    clock_column.dart              180px left sidebar with flip clock and date
    flip_clock.dart                Animated HH:MM split-flap clock
    flip_digit.dart                Individual digit with 3D flip animation
    timeline_strip.dart            Horizontal scrolling timeline with event blocks
    detail_area.dart               Scrollable event list below the timeline
    hero_card.dart                 Featured card for current meeting
    compact_event_row.dart         Compact row for upcoming events
```

## Development

```bash
flutter analyze    # Static analysis (must report zero issues)
flutter test       # Run all tests
```

### Time simulation

Press `S` while the app is running to toggle the time simulation controls. These let you shift the clock forward/backward in 10-minute or 1-hour increments to test how the UI responds to different times of day.

## License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.
