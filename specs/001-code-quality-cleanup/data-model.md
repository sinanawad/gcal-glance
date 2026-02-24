# Data Model: Code Quality Cleanup

**Branch**: `001-code-quality-cleanup` | **Date**: 2026-02-22

## Entities

### CalendarEvent

Immutable data model. Status is a derived property, not stored.

| Field | Type | Description |
|-------|------|-------------|
| summary | `String` | Event title (non-null, defaults to "No Title") |
| startTime | `DateTime` | Event start (local time) |
| endTime | `DateTime` | Event end (local time) |
| meetingLink | `String?` | Google Meet URL, nullable |

**Derived properties** (computed from current time at read):
- `status(DateTime now)` → `EventStatus` — ongoing/upcoming/normal
- `progress(DateTime now)` → `double` — 0.0 to 1.0 for ongoing events
- `countdown(DateTime now)` → `Duration` — time until start or end

**Validation rules**:
- `startTime` must be before `endTime`
- Events with null `start.dateTime` or `end.dateTime` (all-day events)
  are filtered out at the API response layer, not at the model layer

### EventStatus (enum)

| Value | Condition |
|-------|-----------|
| `ongoing` | `now` is between `startTime` and `endTime` |
| `upcoming` | `startTime` is within 10 minutes of `now` |
| `normal` | All other future events |

### GoogleCalendarService

Service class with constructor-injected dependencies.

| Dependency | Type | Purpose |
|------------|------|---------|
| httpClientFactory | `http.Client Function()` | Creates HTTP clients (mockable) |
| secureStorage | `FlutterSecureStorage` | Token persistence (mockable) |
| clientId | `ClientId` | Embedded OAuth credentials |

**State**:
- `_client` — `AutoRefreshingAuthClient?`, nullable, closed on sign-out
- `_credentialUpdatesSubscription` — `StreamSubscription?`, cancelled on
  sign-out

**Lifecycle**:
1. `getAuthenticatedClient()` — returns cached client or loads from
   secure storage
2. `signIn()` — opens browser for OAuth consent (calendar.readonly scope),
   receives token via loopback redirect, persists to secure storage,
   starts listening for refresh updates via `credentialUpdates` stream
3. `signOut()` — closes client, cancels subscription, deletes token from
   secure storage

## File Layout (after restructuring)

```
lib/
├── main.dart                        # App entry point, MaterialApp shell
├── config/
│   └── oauth_config.dart            # Embedded OAuth client ID/secret (gitignored)
├── models/
│   ├── calendar_event.dart          # CalendarEvent, EventStatus
│   └── time_utils.dart              # formatDuration helper
├── services/
│   └── google_calendar_service.dart # OAuth flow, secure token storage, API
├── widgets/
│   ├── clock_widget.dart            # AppBar live clock
│   ├── event_card.dart              # Single event card
│   └── event_list.dart              # Event list with grouping
└── screens/
    └── calendar_home_page.dart      # Main screen composition
```
