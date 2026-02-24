# Feature Specification: Code Quality Cleanup

**Feature Branch**: `001-code-quality-cleanup`
**Created**: 2026-02-22
**Status**: Draft
**Input**: User description: "we want to cleanup the code from security issues, and common optimization issues and Flutter pitfalls."

## Clarifications

### Session 2026-02-22

- Q: What should the app display when authenticated but no events exist for today/tomorrow? → A: Show a text message (e.g., "No upcoming events") with an optional refresh button.
- Q: How should auth work for new users? → A: Embed OAuth client ID in the app. User clicks "Sign in with Google", authenticates in browser, grants calendar read-only permission. No manual credential file setup required.
- Q: How does the user choose which calendars to display? → A: On first login, the app writes a YAML config file to the app's config directory listing all calendars from the account. The primary calendar is marked enabled by default. Users edit the file to enable/disable additional calendars.
- Q: What is the app name? → A: `gcal-glance`. All references to the old name (`gcal_app`) must be updated.
- Q: When should the app refresh the calendar list to discover new/removed calendars? → A: On every app startup (before fetching events).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seamless OAuth Authentication (Priority: P1)

As a new user, I expect to click "Sign in with Google" and authenticate
in my browser. The app handles everything else — I should never need to
create a Google Cloud project, download credential files, or place files
in specific directories.

**Why this priority**: The current flow requires every user to create
their own Google Cloud project and manually provision OAuth credentials.
This is a developer-level task that makes the app unusable for
non-technical users. OAuth client credentials MUST be embedded in the
app so users only need to authorize access.

**Independent Test**: Install the app on a clean machine with no prior
configuration. Click "Sign in with Google". Verify the browser opens,
the user can authorize, and the app loads calendar events — with zero
manual file setup.

**Acceptance Scenarios**:

1. **Given** a fresh install of the app, **When** the user clicks "Sign
   in with Google", **Then** the browser opens to Google's consent screen
   requesting calendar read-only access, with no prior file setup needed.
2. **Given** the user authorizes in the browser, **When** the consent
   flow completes, **Then** the app receives the OAuth token and begins
   loading events immediately.
3. **Given** the user has an existing session with a token that gets
   refreshed during polling, **When** the app is restarted, **Then** the
   refreshed token is loaded from secure storage and no re-authentication
   is required.
4. **Given** HTTP clients are created for authentication, **When** the
   user signs out or the app is closed, **Then** all HTTP clients are
   explicitly closed and no socket leaks occur.
5. **Given** the user wants to revoke access, **When** they click a
   sign-out button, **Then** the local token is deleted and the app
   returns to the sign-in screen.

---

### User Story 2 - Efficient UI Rendering (Priority: P2)

As a user running the app on a desktop (potentially always-on), I expect
the interface to update smoothly without unnecessary CPU or memory usage.

**Why this priority**: The current 1-second full-scaffold `setState`
timer forces a complete widget tree rebuild every second. Event status
(ongoing/upcoming/normal) is computed once at object construction and
becomes stale. These are measurable performance and correctness issues.

**Independent Test**: Run the app and monitor CPU usage over 5 minutes
with a profiler. Verify that per-second updates only rebuild clock and
countdown widgets, not the entire event list.

**Acceptance Scenarios**:

1. **Given** the app is running with events displayed, **When** 1 second
   elapses, **Then** only the clock and countdown text widgets rebuild,
   not the entire event list.
2. **Given** an event's start time is 9 minutes away, **When** the
   countdown crosses the 10-minute threshold, **Then** the event status
   updates to "upcoming" without waiting for the next 60-second data poll.
3. **Given** the event list is displayed, **When** the list is built,
   **Then** group index computation does not perform per-item O(n)
   iteration (precomputed before the build pass).

---

### User Story 3 - User-Visible Error Feedback (Priority: P2)

As a user, when something goes wrong (auth failure, network error, consent
denied), I expect to see a clear message telling me what happened and
what I can do about it.

**Why this priority**: Currently all errors are silently swallowed via
`dev.log`. Auth failures trigger a silent sign-out. The user has no way
to diagnose issues.

**Independent Test**: Disconnect the network while the app is running.
Verify a user-visible error message appears. Deny the OAuth consent and
verify the sign-in screen shows guidance.

**Acceptance Scenarios**:

1. **Given** the Google Calendar API returns an `AccessDeniedException`,
   **When** the error is caught, **Then** a user-visible message is
   displayed before signing out (e.g., "Session expired. Please sign in
   again.").
2. **Given** a network error occurs during event polling, **When** the
   error is caught, **Then** the user sees a non-blocking notification
   with guidance (e.g., "Could not refresh events. Check your
   connection.").
3. **Given** the OAuth consent flow fails (user denies permission, browser
   closed, network error), **When** the error is caught, **Then** the
   sign-in screen displays actionable guidance (e.g., "Sign-in was
   cancelled. Please try again.").

---

### User Story 4 - Calendar Selection via Config File (Priority: P2)

As a user with multiple Google calendars, I want the app to show events
from my primary calendar by default, and I want to be able to enable
additional calendars by editing a configuration file.

**Why this priority**: The app currently hardcodes `'primary'` as the
only calendar source. Users with shared, team, or personal sub-calendars
have no way to view those events. A YAML config file is a low-friction
solution that avoids building a settings UI while still giving users
control.

**Independent Test**: Sign in with an account that has multiple calendars.
Verify a YAML config file is created listing all calendars. Edit the file
to enable a second calendar. Restart the app and verify events from both
calendars appear.

**Acceptance Scenarios**:

1. **Given** a user signs in for the first time, **When** the app
   fetches the calendar list from the Google Calendar API, **Then** a
   YAML config file is written to the app's config directory listing
   every calendar on the account, with the primary calendar marked
   `enabled: true` and all others marked `enabled: false`.
2. **Given** a config file already exists, **When** the app starts,
   **Then** it reads the file and fetches events only from calendars
   marked `enabled: true`.
3. **Given** the user edits the config file to set a second calendar to
   `enabled: true`, **When** the app is restarted (or refreshes),
   **Then** events from both enabled calendars appear in the event list.
4. **Given** the Google account gains a new calendar (e.g., shared by a
   colleague) after the config file was created, **When** the app
   refreshes the calendar list, **Then** the new calendar is appended to
   the config file with `enabled: false` without overwriting existing
   entries or the user's enabled/disabled choices.

---

### User Story 5 - App Rename to gcal-glance (Priority: P1)

As a developer and user, I expect the app to be consistently named
`gcal-glance` (display name) / `gcal_glance` (Dart package name)
everywhere — in the window title, package name, binary output,
platform configurations, and all source references.

**Why this priority**: The current name `gcal_app` is a placeholder. The
rename must happen early because it affects package imports in every Dart
file, platform manifests, and the app data directory path. Doing it after
other restructuring would require a second pass over all files.

**Independent Test**: Build the app. Verify the window title says
"gcal-glance", the Linux binary is named `gcal-glance`, and
`flutter analyze` passes with the new package name.

**Acceptance Scenarios**:

1. **Given** the codebase is renamed, **When** `flutter pub get` is run,
   **Then** the package resolves as `gcal_glance` with no errors.
2. **Given** the app is built for Linux, **When** it launches, **Then**
   the window title displays "gcal-glance" and the binary name is
   `gcal-glance`.
3. **Given** the rename is complete, **When** `flutter analyze` is run,
   **Then** zero issues are reported and no references to the old name
   `gcal_app` remain in Dart source, pubspec.yaml, or platform configs.

---

### User Story 6 - Code Structure Cleanup (Priority: P3)

As a developer, I expect the codebase to follow standard Flutter file
organization so that models, services, and widgets are in separate files
and easy to find.

**Why this priority**: All application code currently lives in two files
(`main.dart` at 464 lines and `google_calendar_service.dart`). Splitting
into a standard structure enables independent testing, easier navigation,
and parallel development.

**Independent Test**: Verify the app builds and runs identically after
restructuring. Verify each extracted file can be imported independently.

**Acceptance Scenarios**:

1. **Given** the restructured codebase, **When** `flutter analyze` is
   run, **Then** zero issues are reported.
2. **Given** models are extracted to `lib/models/`, **When** a developer
   imports `CalendarEvent`, **Then** it is available from
   `package:gcal_glance/models/calendar_event.dart` without pulling in
   Flutter UI dependencies.
3. **Given** the restructured codebase, **When** `flutter test` is run,
   **Then** all tests pass (the placeholder counter-app test is replaced
   with a test that exercises the actual application).

---

### Edge Cases

- What happens when stored token data is corrupted or unreadable?
  The app MUST handle parse failures gracefully, clear the invalid data,
  and prompt the user to re-authenticate.
- What happens when the Google Calendar API returns events with `null`
  start/end times (all-day events)? These MUST be filtered out without
  crashing.
- What happens when `DateTime.now()` rolls over midnight between event
  polls? The "tomorrow" separator MUST still render correctly.
- What happens when the user is authenticated but has no events for
  today or tomorrow? The app MUST show a "No upcoming events" message
  with a refresh button, not a spinner.
- What happens when the YAML config file is missing, corrupted, or has
  invalid syntax? The app MUST regenerate it from the API calendar list,
  preserving the default (primary calendar enabled) behavior.
- What happens when a calendar listed in the config file no longer exists
  on the Google account (deleted or unshared)? The app MUST skip it
  gracefully and not crash. The stale entry MAY remain in the config file.
- What happens when the user has zero calendars? The app MUST show the
  empty state ("No upcoming events") rather than crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: OAuth client credentials (client ID and secret) MUST be
  embedded in the app (compiled constant or bundled asset). Users MUST NOT
  be required to provide or configure credential files.
- **FR-002**: The sign-in flow MUST open the system browser for Google
  OAuth consent, requesting only `calendar.readonly` scope. The app MUST
  receive the authorization code via a local redirect (loopback).
- **FR-003**: OAuth tokens MUST be stored in platform-appropriate secure
  storage (e.g., `flutter_secure_storage` using libsecret on Linux).
  Plain-text token files MUST NOT be used.
- **FR-004**: Refreshed OAuth tokens MUST be written back to secure
  storage after each refresh.
- **FR-005**: All HTTP client instances MUST be explicitly closed when no
  longer needed (sign-out, app disposal, auth failure).
- **FR-006**: On first sign-in, the app MUST fetch the full calendar list
  via the Google Calendar API (`CalendarList.list()`) and write a YAML
  config file to the app's config directory. Each entry MUST include the
  calendar ID, display name, and an `enabled` boolean.
- **FR-007**: The primary calendar MUST be marked `enabled: true` by
  default. All other calendars MUST default to `enabled: false`.
- **FR-008**: The app MUST read the YAML config file on startup and fetch
  events only from calendars marked `enabled: true`.
- **FR-009**: On every app startup, the app MUST refresh the calendar
  list from the Google Calendar API. Calendars not present in the config
  file MUST be appended with `enabled: false` without overwriting
  existing user choices. The 60-second event poll MUST NOT refresh the
  calendar list.
- **FR-010**: The app MUST be renamed from `gcal_app` to `gcal_glance`
  (Dart package) / `gcal-glance` (display name / binary). All references
  in pubspec.yaml, Dart imports, platform configurations (Linux, macOS,
  Windows, Android, iOS, Web), and the window title MUST be updated.
- **FR-011**: `DateTime.now()` MUST be captured once per build frame and
  reused across all widgets to prevent time-of-check inconsistencies.
- **FR-012**: Event status (ongoing/upcoming/normal) MUST be computed at
  render time, not cached at construction time.
- **FR-013**: Per-second UI updates MUST be scoped to only the widgets
  that display time-dependent data (clock, countdowns), not the full
  widget tree.
- **FR-014**: Group index computation in the event list MUST NOT perform
  O(n) work per list item.
- **FR-015**: All API and auth errors MUST produce user-visible feedback
  before any automatic state change (e.g., sign-out).
- **FR-016**: Network errors during event polling MUST display a
  non-blocking notification and retain the last-known event list.
- **FR-017**: The `CalendarEvent` model, `GoogleCalendarService`, and UI
  widgets MUST be separated into distinct files following standard Flutter
  project layout.
- **FR-018**: The default widget test MUST test the actual application,
  not the Flutter counter template.
- **FR-019**: Top-level functions (`_formatDuration`) MUST be relocated to
  an appropriate scope (static method or utility within the relevant
  class/file).
- **FR-020**: When authenticated with zero events for today/tomorrow, the
  app MUST display a "No upcoming events" text message with a manual
  refresh button. A loading spinner MUST NOT be used to represent an
  empty event list.

### Key Entities

- **CalendarEvent**: Represents a single calendar event. Key attributes:
  summary, startTime, endTime, meetingLink. Status is a derived property
  computed from current time, not a stored field.
- **CalendarConfig**: Represents the YAML config file contents. A list of
  calendar entries, each with: id (Google calendar ID), name (display
  name), enabled (boolean). Read from and written to the app config
  directory.
- **GoogleCalendarService**: Manages OAuth lifecycle (embedded client
  credentials, browser-based consent flow, secure token storage),
  calendar list discovery, and authenticated API access. Accepts
  dependencies via constructor for testability.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can go from app launch to viewing their calendar
  events with only a single "Sign in with Google" click and browser
  authorization — no file setup, no developer tools.
- **SC-002**: After a token refresh, restarting the app does not require
  re-authentication.
- **SC-003**: CPU usage from per-second UI updates is reduced by at least
  50% compared to the current full-rebuild approach (measurable via
  Flutter DevTools).
- **SC-004**: Event status transitions (normal to upcoming, upcoming to
  ongoing) are reflected in the UI within 2 seconds of the real-time
  threshold, not delayed up to 60 seconds.
- **SC-005**: When a network error occurs during polling, the user sees
  feedback within 2 seconds and the previously loaded event list remains
  visible.
- **SC-006**: After first sign-in, a YAML config file exists in the app
  config directory listing all calendars, with the primary enabled.
- **SC-007**: Enabling a second calendar in the config file and
  restarting the app causes events from both calendars to appear.
- **SC-008**: No references to the old name `gcal_app` remain in any
  source file, config, or platform manifest. The package resolves as
  `gcal_glance`.
- **SC-009**: `flutter analyze` reports zero issues after all changes.
- **SC-010**: `flutter test` passes with at least one meaningful test
  exercising the actual application widgets.

### Assumptions

- The app continues to target Flutter desktop (Linux primary) with
  Material 3.
- The existing polling pattern is retained; no real-time push is
  introduced. The OAuth scope remains `calendar.readonly`, which already
  grants access to `CalendarList.list()` for calendar discovery.
- OAuth client credentials (client ID and secret) are embedded in the
  compiled app. For desktop apps, Google considers the client secret not
  truly secret since it ships in the distributed binary. This is the
  standard approach for installed/desktop applications per Google's OAuth
  documentation.
- Token storage uses `flutter_secure_storage` (backed by libsecret on
  Linux) rather than plain-text files.
- The `go-gcal-cli-credentials.json` external file is eliminated. The
  developer configures the client ID/secret once at build time.
- The YAML config file is stored in the platform config directory (e.g.,
  `~/.config/gcal-glance/calendars.yaml` on Linux via XDG). This is a
  user-editable preference file, not a secret.
- The `yaml` Dart package is used for reading YAML. Writing uses simple
  string formatting (no heavyweight YAML serialization library needed).
