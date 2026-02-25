# gcal-glance: Complete Feature Specification

This document describes every feature and behavior of the app as of the current implementation. It serves as the baseline for planning new features.

## 1. Platform and Framework

- **Framework**: Flutter with Material 3 (`useMaterial3: true`), seed color `Colors.deepPurple`
- **Primary target**: Linux desktop (launched via `flutter run -d linux`)
- **Package name**: `gcal_glance`
- **Window title**: `gcal-glance`
- **Bundle ID**: `coach.incremental.gcal_glance`

## 2. Authentication

### OAuth Flow
- Uses Google OAuth 2.0 Desktop flow (`obtainAccessCredentialsViaUserConsent`)
- Scope: `calendar.readonly` (read-only access to Google Calendar)
- On sign-in, the system browser opens via `xdg-open` for the user to authorize
- OAuth client ID and secret are embedded as compiled Dart constants in `lib/config/oauth_config.dart` (gitignored)

### Token Storage
- Tokens are stored in Linux secure storage via `flutter_secure_storage` (backed by libsecret/GNOME Keyring)
- Storage key: `gcal_oauth_token`
- Stored as JSON containing: access token (type, data, expiry), refresh token, scopes, id token
- On app launch, the service attempts to restore tokens from secure storage (auto-login)
- An `AutoRefreshingAuthClient` is used — when tokens refresh, the new credentials are automatically persisted back to secure storage via a `credentialUpdates` stream listener
- Corrupted stored data is silently cleared, prompting re-authentication

### Sign-out
- Closes HTTP client, cancels credential update subscription, deletes stored token

## 3. Data Fetching

### Calendar Source
- Fetches from the user's primary calendar by default, with optional multi-calendar support
- Uses Google Calendar API v3 (`googleapis` package)
- `calendarList.list()` fetches all visible calendars; user selects which to display via 'C' key picker
- Selected calendars are persisted to secure storage (key: `gcal_selected_calendars`)
- Events are fetched in parallel across all selected calendars via `Future.wait`

### Time Range
- Fetches events from **now** to **end of tomorrow** (23:59:59 on the next day)
- Times are converted to UTC for the API call, then back to local time for display

### Filtering
- Only events with both `start.dateTime` and `end.dateTime` set are shown (all-day events are excluded since they use `start.date` instead)
- Events with `status == 'cancelled'` are excluded
- Events where the user's response status is `declined` are excluded (determined via `attendees[].self == true`)
- Events are ordered by start time (API-side `orderBy: 'startTime'`, `singleEvents: true` to expand recurring events)

### Polling
- Events are fetched immediately on sign-in, then every **60 seconds** via a periodic timer
- On each poll, the full event list is replaced (not diffed/merged)

## 4. App Layout

### App Bar
- **Center**: Live clock widget showing `HH:MM - DD/MM/YYYY (Weekday)` (e.g., `14:30 - 24/02/2026 (Tuesday)`)
- **Right action** (visible only when logged in): Exit button (`Icons.exit_to_app`) that calls `SystemNavigator.pop()` on Linux or `Navigator.pop()` on other platforms

### Body
- Background color: `Colors.grey[700]` (dark grey)
- When **not logged in**: centered "Sign in with Google" `ElevatedButton`
- When **logged in**: one of three states:
  1. **Loading** (first fetch not complete): centered `CircularProgressIndicator`
  2. **Empty** (first fetch complete, zero events): centered "No upcoming events" text (white, 18px) + refresh `IconButton` (white, 32px). Refresh button is disabled while loading
  3. **Event list**: scrollable `ListView` of event cards

## 5. Event Status Model

Each event has a dynamic status computed at render time based on the current clock (`status(DateTime now)`):

| Status | Condition | Description |
|--------|-----------|-------------|
| `ongoing` | `now.isAfter(startTime) && now.isBefore(endTime)` | Event is currently happening |
| `upcoming` | Start is in the future AND within 10 minutes (`diff > 0 && diff <= 10 min`) | Event is about to start |
| `normal` | Everything else (future beyond 10 min, or past) | Default state |

**Boundary behavior**: At exact `startTime` or exact `endTime`, status is `normal` (strict `isAfter`/`isBefore` checks).

### Progress
- `progress(now)` returns a `double` from 0.0 to 1.0 representing how far through an ongoing event we are
- Calculated as `elapsed seconds / total seconds`, clamped to [0.0, 1.0]
- Returns 0.0 if not currently ongoing
- Returns 0.0 for zero-duration events (division guard: `totalDuration <= 0`)

### Countdown
- `countdown(now)` returns a `Duration`:
  - Before event: time until start
  - During event: time until end
  - After event: `Duration.zero`

## 6. Event List Display

### Grouping
- Events are grouped by identical start time (same hour AND minute)
- A **grey horizontal divider** (2px, with 8px vertical margin) separates each group
- Group indices are precomputed in a single O(n) pass

### Tomorrow Separator
- When the day changes between consecutive events, a full-width `ListTile` with grey background displays `--- Tomorrow ---` (white, bold, 18px, centered)

### Group Background Colors
- Groups with `normal` status alternate between `Colors.grey[300]` (even groups) and `Colors.orange[50]` (odd groups)
- This alternation is overridden by status-specific colors (see Event Card section)

## 7. Event Card

Each event is rendered as a `Card` with `elevation: 6` and `borderRadius: 8`.

### Card Colors by Status

| Status | Background | Border | Text | Leading Icon |
|--------|-----------|--------|------|-------------|
| `ongoing` | `Colors.blue[700]` | `Colors.blueAccent`, 2px | `Colors.white` | `Icons.videocam` (white) |
| `upcoming` | `Colors.orange[400]` | `Colors.orangeAccent`, 2px | `Colors.black` | `Icons.notifications_active` (black) |
| `normal` | Alternating grey/orange (from group) | Background color at 80% opacity, 2px | Default (theme) | `Icons.event` (default) |

### Card Layout (ListTile)

**Leading**: Status icon (see table above)

**Title row** (two `Expanded` children in a `Row`):
- **Left**: Event summary text
  - With meeting link: 20px, bold
  - Without meeting link: 16px, normal weight
  - Overflow: ellipsis
- **Right** (right-aligned): Time string in format `HH:MM - HH:MM (In HH:MM)` or `HH:MM - HH:MM (In XXs)` for <1 minute
  - With meeting link: 24px
  - Without meeting link: 16px
  - Countdown shows "In HH:MM" when time remaining > 0, empty string otherwise

### Subtitle (ongoing only)
- Shows `XX% of meeting passed` (white text)
- Percentage = `progress(now) * 100`, clamped to [0, 100], displayed as integer

### Trailing: Join Meeting Button
- Always present as an `ElevatedButton` with `Icons.videocam`
- **With meeting link (https only)**:
  - Background: `Colors.red`, border: `Colors.redAccent` 2px, icon: white
  - On tap: opens the meeting link via `launchUrl`
  - URL must have `https` scheme (validated via `Uri.tryParse().scheme == 'https'`)
- **Without meeting link**:
  - Background: `Colors.grey`, no border, button disabled (`onPressed: null`)
  - Ongoing + no link: icon is black; otherwise icon is white
- Meeting link is sourced from Google Calendar's `hangoutLink` field (Google Meet links)

## 8. Real-Time Updates

### Clock Timer (1-second)
- A `ValueNotifier<DateTime>` is updated every 1 second via `Timer.periodic`
- Only the `ClockWidget` and each `EventCard` subscribe to this notifier via `ValueListenableBuilder`
- This means per-second rebuilds are scoped — the overall Scaffold and event list structure do NOT rebuild every second

### Data Fetch Timer (60-second)
- A separate `Timer.periodic` fetches fresh events from the API every 60 seconds
- This triggers a full `setState` to replace the event list

### What updates per-second (via ValueNotifier)
- Clock display (HH:MM changes)
- Event status colors (transitions between normal/upcoming/ongoing)
- Countdown text (ticks down)
- Progress percentage (for ongoing events)

### What updates every 60 seconds (via API poll)
- Event list contents (new events appear, past events may disappear)

## 9. Error Handling

All errors are surfaced to the user via floating `SnackBar` messages (max width 400px).

| Error | Message | Action | Side Effect |
|-------|---------|--------|-------------|
| `AccessDeniedException` during event fetch | "Session expired. Please sign in again." | None | Auto sign-out |
| `SocketException` during event fetch | "Could not refresh events. Check your connection." | "Retry" button | Keeps last-known event list |
| `ClientException` during event fetch | "Could not refresh events. Check your connection." | "Retry" button | Keeps last-known event list |
| Sign-in failure/cancellation | "Sign-in was cancelled. Please try again." | None | Stays on sign-in screen |
| Browser open failure | "Failed to open browser." | None | None |

On network errors, the existing event list is preserved (last-known-good data stays visible).

## 10. Architecture

### Source Layout
```
lib/
  main.dart                          # App shell (MaterialApp + service wiring)
  config/
    oauth_config.dart                # Real credentials (gitignored)
    oauth_config.example.dart        # Template for developers
  models/
    calendar_event.dart              # CalendarEvent model + EventStatus enum
    time_utils.dart                  # TimeUtils.formatDuration()
  services/
    google_calendar_service.dart     # OAuth + Calendar API
  screens/
    calendar_home_page.dart          # Main screen (StatefulWidget)
  widgets/
    clock_widget.dart                # Live clock (StatelessWidget + ValueListenableBuilder)
    event_card.dart                  # Single event card (StatelessWidget + ValueListenableBuilder)
    event_list.dart                  # Grouped event list (StatelessWidget)
```

### Dependency Injection
- `GoogleCalendarService` receives `httpClientFactory`, `secureStorage`, and `clientId` via constructor
- `CalendarHomePage` receives `GoogleCalendarService` via constructor
- This enables testing with mocked dependencies via `mocktail`

### Test Coverage
- **Model tests** (17 tests): status(), progress(), countdown() with boundaries and edge cases
- **Service tests** (6 tests): credential storage, restoration, caching, corruption handling, sign-out
- **Widget tests** (7 tests): sign-in UI, sign-in flow, loading state, empty state, error SnackBars (network, session expiry, sign-in failure)

## 11. Known Limitations

- **Multi-calendar supported**: press 'C' to toggle additional calendars; secondary events shown faded with Google Calendar colors
- **No offline mode**: if the initial fetch fails, only a loading spinner is shown (no cached events across app restarts)
- **All-day events excluded**: only timed events (with `dateTime`) are displayed
- **No event details view**: tapping an event does nothing (no expanded view or description)
- **No notification/alarm**: the "upcoming" status is visual only; there is no sound or system notification
- **Desktop only**: while Flutter supports mobile, the sign-in flow uses `xdg-open` (Linux-specific) and the exit button uses `SystemNavigator.pop()`
- **No dark/light theme toggle**: always uses Material 3 with deepPurple seed + grey[700] body background
- **Meeting links only from hangoutLink**: only Google Meet links from the `hangoutLink` field are detected; other conferencing providers' links embedded in event descriptions are not parsed
- **Clock shows HH:MM only**: seconds are not displayed in the app bar clock, even though it updates every second
- **No sign-out button in UI**: the exit button closes the app entirely; sign-out requires clearing secure storage externally or code change
