# gcal-glance

A Flutter desktop app that shows your upcoming Google Calendar events at a glance.

## Features

- Live clock in the app bar
- Color-coded events: blue (ongoing), orange (upcoming in <10 min), grey (later)
- Real-time countdown timers for each event
- One-click join for Google Meet links
- Shows today's and tomorrow's events
- Auto-refreshes every 60 seconds

## Setup

1. Create a Google Cloud project and enable the Google Calendar API
2. Create OAuth 2.0 Desktop credentials and download the JSON file
3. Rename it to `go-gcal-cli-credentials.json` and place it in the project root
4. Run the app:

```bash
flutter run -d linux
```

5. Sign in with your Google account when prompted

## Requirements

- Flutter SDK (Dart ^3.8.1)
- Google Cloud project with Calendar API enabled
- OAuth 2.0 Desktop client credentials
