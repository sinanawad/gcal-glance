---

description: "Task list for code quality cleanup feature"
---

# Tasks: Code Quality Cleanup

**Input**: Design documents from `/specs/001-code-quality-cleanup/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Tests are included as the spec requires replacing the placeholder test and establishing testability (FR-018, Principle VII).

**Organization**: Tasks are grouped by user story. US5 (rename) and US6 (restructure) are foundational because they change the package name and file layout that all other stories depend on.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Add new dependencies and configuration scaffolding

- [x] T001 Add `flutter_secure_storage: ^9.0.0`, `yaml: ^3.1.0`, and `path_provider: ^2.1.0` to dependencies in pubspec.yaml. Add `mocktail: ^1.0.0` to dev_dependencies. Run `flutter pub get`
- [x] T002 [P] Create lib/config/oauth_config.example.dart with placeholder constants (`clientId`, `clientSecret`) and a comment explaining how to obtain values from Google Cloud Console
- [x] T003 [P] Update .gitignore: add `lib/config/oauth_config.dart`, remove `go-gcal-cli-credentials.json` and `token.json` entries (these files are no longer used)

---

## Phase 2: Foundational — Rename + Restructure (US5 + US6)

**Purpose**: Rename the app and establish the target file layout. BLOCKS all user story work.

**Why foundational**: The rename changes the Dart package name in every import. The restructure creates the directory layout all subsequent tasks write into. Doing these after other stories would require moving files twice.

### App Rename (US5)

- [x] T004 [US5] Rename package from `gcal_app` to `gcal_glance` in pubspec.yaml (`name:` field) and update `description` to "A desktop app that shows your upcoming Google Calendar events at a glance."
- [x] T005 [US5] Update all Dart `import 'package:gcal_app/...'` statements to `import 'package:gcal_glance/...'` in lib/main.dart and lib/google_calendar_service.dart
- [x] T006 [US5] Update window title from `'gcal app'` to `'gcal-glance'` in lib/main.dart (MaterialApp `title` property)
- [x] T007 [US5] Update Linux platform config: rename `APPLICATION_ID` and binary name to `gcal-glance` in linux/CMakeLists.txt, update `gtk_application_new()` ID in linux/runner/my_application.cc
- [x] T008 [P] [US5] Update web platform config: update `<title>` in web/index.html, update `name` and `short_name` in web/manifest.json to `gcal-glance`
- [x] T009 [P] [US5] Update Android platform config: rename package in android/app/build.gradle and android/app/src/main/AndroidManifest.xml
- [x] T010 [P] [US5] Update iOS platform config: update `PRODUCT_BUNDLE_IDENTIFIER` and display name in ios/Runner.xcodeproj/project.pbxproj and ios/Runner/Info.plist
- [x] T011 [P] [US5] Update macOS platform config: update bundle identifier and product name in macos/Runner.xcodeproj/project.pbxproj and macos/Runner/Configs/AppInfo.xcconfig
- [x] T012 [P] [US5] Update Windows platform config: update `BINARY_NAME` and `APPLICATION_ID` in windows/CMakeLists.txt, update `APP_TITLE` in windows/runner/main.cpp
- [x] T013 [US5] Run `flutter pub get && flutter analyze` to verify rename produces zero issues

### File Restructure (US6)

- [x] T014 [US6] Create directory structure: lib/config/, lib/models/, lib/services/, lib/widgets/, lib/screens/, test/models/, test/services/, test/widgets/
- [x] T015 [US6] Extract `CalendarEvent` class, `EventStatus` enum, and `_calculateStatus` to lib/models/calendar_event.dart. Change `status` from a stored field to a method `EventStatus status(DateTime now)`. Add `double progress(DateTime now)` and `Duration countdown(DateTime now)` methods. Remove Flutter imports — pure Dart only
- [x] T016 [P] [US6] Extract `_formatDuration` to lib/models/time_utils.dart as `static String formatDuration(Duration d)` (public, no leading underscore)
- [x] T017 [US6] Refactor lib/services/google_calendar_service.dart: add constructor parameters for `http.Client Function() httpClientFactory`, `FlutterSecureStorage secureStorage`, and `ClientId clientId`. Remove file-based credential loading (`_getClientId`, `_credentialsFile`). Keep method signatures (`signIn`, `signOut`, `getAuthenticatedClient`) but stub implementations for now (US1 will complete them)
- [x] T018 [US6] Extract clock display from AppBar to lib/widgets/clock_widget.dart as a StatelessWidget that accepts a `DateTime now` parameter. Replace inline weekday ternary chain with list lookup
- [x] T019 [P] [US6] Extract single event card to lib/widgets/event_card.dart as a StatelessWidget. Accept `CalendarEvent`, `DateTime now`, `Color? backgroundColor`, and `VoidCallback? onJoinMeeting` parameters
- [x] T020 [P] [US6] Extract event list to lib/widgets/event_list.dart as a StatelessWidget. Accept `List<CalendarEvent> events` and `DateTime now`. Precompute group indices before the build pass (fix O(n²) issue from FR-014)
- [x] T021 [US6] Extract CalendarHomePage to lib/screens/calendar_home_page.dart. Accept `GoogleCalendarService` via constructor parameter. Wire up imports from extracted widgets and models
- [x] T022 [US6] Reduce lib/main.dart to minimal app shell: `runApp(MyApp())` with `MaterialApp` pointing to `CalendarHomePage`. All business logic and UI code lives in extracted files
- [x] T023 [US6] Delete test/widget_test.dart (counter-app placeholder). Create test/widgets/calendar_home_page_test.dart with a basic smoke test using `mocktail` to mock `GoogleCalendarService`. Verify the sign-in button renders when not authenticated
- [x] T024 [US6] Run `flutter analyze && flutter test` to verify restructure produces zero issues and test passes

**Checkpoint**: App renamed, restructured into standard layout, builds and passes analyzer + test. All subsequent stories build on this structure.

---

## Phase 3: User Story 1 — Seamless OAuth Authentication (Priority: P1)

**Goal**: User clicks "Sign in with Google" → browser opens → authorize → events load. No credential files needed.

**Independent Test**: On a clean machine with no config, click sign in, authorize in browser, verify events load.

### Implementation for User Story 1

- [x] T025 [US1] Create lib/config/oauth_config.dart with actual embedded `clientId` and `clientSecret` constants from the developer's Google Cloud project (file is gitignored)
- [x] T026 [US1] Implement secure token storage in lib/services/google_calendar_service.dart: `_saveCredentials(AccessCredentials)` writes serialized JSON to `FlutterSecureStorage` under key `gcal_oauth_token`. `_loadSavedCredentials()` reads and deserializes from secure storage. `_clearCredentials()` deletes the key
- [x] T027 [US1] Implement `signIn()` in lib/services/google_calendar_service.dart: use embedded `ClientId` from oauth_config.dart, call `obtainAccessCredentialsViaUserConsent()` with `calendarReadonlyScope` and `launchUrl` callback. Save credentials to secure storage. Create `AutoRefreshingAuthClient` and listen to `credentialUpdates` stream to persist refreshed tokens
- [x] T028 [US1] Implement `signOut()`: close `_client`, cancel `_credentialUpdatesSubscription`, call `_clearCredentials()`, close underlying HTTP clients
- [x] T029 [US1] Implement `getAuthenticatedClient()`: return cached `_client` if available, otherwise attempt to load from secure storage. If loaded, create `AutoRefreshingAuthClient` and subscribe to `credentialUpdates`. Handle corrupted data gracefully (clear and return null)
- [x] T030 [US1] Update lib/screens/calendar_home_page.dart `dispose()` to close HTTP clients via service. Remove all references to `go-gcal-cli-credentials.json` and `token.json` from the codebase
- [x] T031 [US1] Add test in test/services/google_calendar_service_test.dart: mock `FlutterSecureStorage`, verify `_loadSavedCredentials` returns null when storage is empty, verify `_clearCredentials` deletes the key on sign-out

**Checkpoint**: Auth works via embedded credentials + browser flow. Tokens stored in libsecret. Refresh persisted. HTTP clients properly closed.

---

## Phase 4: User Story 2 — Efficient UI Rendering (Priority: P2)

**Goal**: Per-second updates scoped to clock/countdown widgets only. Event status computed at render time.

**Independent Test**: Run app with DevTools profiler. Verify 1-second timer only rebuilds clock and countdowns, not the full event list.

### Implementation for User Story 2

- [x] T032 [US2] Create a `ValueNotifier<DateTime>` in lib/screens/calendar_home_page.dart. Initialize it in `initState()` with a `Timer.periodic(1 second)` that updates the notifier. Remove the existing `_uiUpdateTimer` that calls `setState(() {})`
- [x] T033 [US2] Wrap the clock widget in lib/widgets/clock_widget.dart with `ValueListenableBuilder<DateTime>` so it rebuilds only when the notifier ticks, not on full scaffold rebuild
- [x] T034 [US2] Update lib/widgets/event_list.dart: pass `ValueNotifier<DateTime>` to event list. Wrap each event card's countdown text and status indicator in `ValueListenableBuilder<DateTime>` so countdowns update per-second without rebuilding the entire list
- [x] T035 [US2] Update lib/widgets/event_card.dart: accept `DateTime now` from the `ValueListenableBuilder` parent. Call `event.status(now)` and `event.countdown(now)` at render time instead of reading a cached `event.status` field
- [x] T036 [US2] Implement empty state in lib/screens/calendar_home_page.dart: when `_events.isEmpty` and `_isLoggedIn` and `_hasCompletedFirstLoad`, show a "No upcoming events" text + refresh `IconButton` instead of `CircularProgressIndicator`. Add `_isLoading` flag to distinguish loading from empty
- [x] T037 [US2] Add test in test/models/calendar_event_test.dart: verify `status(now)` returns `ongoing` when `now` is between start and end, `upcoming` when within 10 minutes, `normal` otherwise. Verify `progress(now)` returns correct fraction

**Checkpoint**: Clock and countdowns rebuild per-second via ValueNotifier. Event cards are static between polls. Empty state is distinct from loading.

---

## Phase 5: User Story 3 — User-Visible Error Feedback (Priority: P2)

**Goal**: All errors produce user-visible SnackBar messages instead of silent `dev.log` calls.

**Independent Test**: Disconnect network while running. Verify SnackBar appears. Deny OAuth consent and verify guidance on sign-in screen.

### Implementation for User Story 3

- [ ] T038 [US3] Create a helper method `_showErrorSnackBar(String message, {String? actionLabel, VoidCallback? onAction})` in lib/screens/calendar_home_page.dart using `ScaffoldMessenger.of(context).showSnackBar()` with `SnackBarBehavior.floating` and max width ~400px
- [ ] T039 [US3] Update `_updateEvents()` in lib/screens/calendar_home_page.dart: wrap API call in try-catch. On `AccessDeniedException`, show SnackBar "Session expired. Please sign in again." before calling `_handleSignOut()`. On network error (`SocketException`, `ClientException`), show SnackBar "Could not refresh events. Check your connection." with a "Retry" action. Retain `_events` (last-known list) on error
- [ ] T040 [US3] Update `_handleSignIn()` in lib/screens/calendar_home_page.dart: wrap `signIn()` in try-catch. On failure, show SnackBar "Sign-in was cancelled. Please try again." instead of silently returning null
- [ ] T041 [US3] Remove all `dev.log()` calls from lib/services/google_calendar_service.dart that silently swallow errors. Rethrow or return typed error results so the screen layer can display feedback

**Checkpoint**: All error paths show user-visible SnackBars. No silent failures remain.

---

## Phase 6: User Story 4 — Calendar Selection via Config File (Priority: P2)

**Goal**: YAML config file lists all user calendars. Primary enabled by default. Users edit file to toggle.

**Independent Test**: Sign in with multi-calendar account. Verify YAML file created. Enable a second calendar, restart, verify events from both appear.

### Implementation for User Story 4

- [ ] T042 [US4] Create lib/models/calendar_config.dart: `CalendarConfigEntry` class with `id`, `name`, `enabled` fields. `CalendarConfig` class with `List<CalendarConfigEntry> calendars` and methods: `enabledCalendarIds()`, `toYamlString()`, factory `fromYamlString(String yaml)`, factory `fromApiCalendarList(List<CalendarListEntry> apiCalendars)`
- [ ] T043 [US4] Create lib/services/calendar_config_service.dart: constructor accepts config directory path (from `path_provider`). Methods: `Future<CalendarConfig> load()` reads `calendars.yaml`, `Future<void> save(CalendarConfig config)` writes YAML, `Future<CalendarConfig> mergeWithApi(CalendarConfig existing, List<CalendarListEntry> apiCalendars)` appends new calendars without overwriting user choices
- [ ] T044 [US4] Update lib/services/google_calendar_service.dart: add `Future<List<CalendarListEntry>> fetchCalendarList()` method that calls `CalendarApi.calendarList.list()` using the authenticated client
- [ ] T045 [US4] Update lib/screens/calendar_home_page.dart startup flow: after auth, call `fetchCalendarList()` → load or create `CalendarConfig` → merge API list with config → save merged config. Pass `enabledCalendarIds()` to event polling
- [ ] T046 [US4] Update `_updateEvents()` in lib/screens/calendar_home_page.dart: iterate over enabled calendar IDs and fetch events from each (instead of hardcoded `'primary'`). Merge results into a single sorted list
- [ ] T047 [US4] Handle edge cases in lib/services/calendar_config_service.dart: corrupted YAML (catch `FormatException`, regenerate from API), deleted calendars (skip gracefully during event fetch, log warning), zero calendars (return empty config, UI shows empty state)

**Checkpoint**: Config file created at `~/.config/gcal-glance/calendars.yaml`. Primary calendar enabled. Multi-calendar events merged and displayed.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and documentation

- [ ] T048 Update test/widgets/calendar_home_page_test.dart: add test verifying SnackBar appears when mocked service throws a network error. Add test verifying empty state renders "No upcoming events" when mocked service returns empty list
- [ ] T049 [P] Update test/models/calendar_event_test.dart: add edge case tests — event with `startTime == endTime`, status transitions at exact boundary times
- [ ] T050 [P] Validate URL scheme before `launchUrl` calls: add a check in lib/widgets/event_card.dart that `event.meetingLink` starts with `https://` before launching. Skip or log if scheme is unexpected
- [ ] T051 Run `flutter analyze` and fix any remaining issues across all files
- [ ] T052 Run `flutter test` and verify all tests pass
- [ ] T053 Update README.md: reflect new app name `gcal-glance`, remove manual credential setup instructions, document the YAML config file location and format, update setup instructions for end users (just sign in) vs developers (configure OAuth)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 (needs restructured files + new package name)
- **US2 (Phase 4)**: Depends on Phase 2 (needs extracted widgets to refactor)
- **US3 (Phase 5)**: Depends on Phase 2 (needs extracted screen to add error handling)
- **US4 (Phase 6)**: Depends on Phase 2 + Phase 3 (needs auth service to fetch calendar list)
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **US5 + US6 (Foundational)**: Must complete first — changes package name and file layout
- **US1 (Auth)**: Can start after Foundational
- **US2 (Rendering)**: Can start after Foundational — independent of US1
- **US3 (Errors)**: Can start after Foundational — independent of US1, US2
- **US4 (Calendar Config)**: Depends on US1 (needs authenticated client for CalendarList API)

### Within Each Phase

- Models before services
- Services before screens/widgets
- Core implementation before edge case handling
- All [P] tasks within a phase can run in parallel

### Parallel Opportunities

- T002 + T003 (setup config + gitignore) in parallel
- T008 + T009 + T010 + T011 + T012 (platform configs) in parallel
- T015 + T016 (model extraction) in parallel
- T019 + T020 (widget extraction) in parallel
- US2 + US3 can run in parallel after Foundational (different files, no dependencies)
- T048 + T049 + T050 (polish tests + validation) in parallel

---

## Implementation Strategy

### MVP First (US5 + US6 + US1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (rename + restructure)
3. Complete Phase 3: US1 (auth)
4. **STOP and VALIDATE**: App renamed, restructured, auth works via embedded creds
5. This alone is a significant improvement over the current state

### Incremental Delivery

1. Setup + Foundational → App renamed and restructured
2. Add US1 → Auth works for end users (MVP!)
3. Add US2 → Rendering optimized for always-on use
4. Add US3 → Error feedback visible to users
5. Add US4 → Multi-calendar support via config file
6. Polish → Tests complete, docs updated

### Parallel Team Strategy

With multiple developers after Foundational completes:

- Developer A: US1 (Auth) — blocking for US4
- Developer B: US2 (Rendering) — independent
- Developer C: US3 (Errors) — independent
- After US1 done: Developer A takes US4 (Calendar Config)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US5 and US6 are in Foundational phase despite being separate user stories because they block all other work
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
