# Tasks: Weather Background for Date Display

**Input**: Design documents from `/specs/003-weather-background/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md

**Tests**: Not explicitly requested in spec. Test tasks included for model and service layers only (minimal coverage for data integrity).

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Configuration files and project initialization for the weather feature

- [x] T001 Create API key template file at `lib/config/weather_config.example.dart` with placeholder constant `weatherApiKey`
- [x] T002 Create actual API key config file at `lib/config/weather_config.dart` (gitignored) with compiled constant
- [x] T003 Add `lib/config/weather_config.dart` to `.gitignore`

---

## Phase 2: Foundational (Models & Service)

**Purpose**: Core data models and API service that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create `WeatherCategory` enum and `WeatherCondition` model in `lib/models/weather_condition.dart` — 7 enum values (clear, partlyCloudy, cloudy, rain, snow, thunderstorm, fog) with `isAnimated` derived property; immutable model with fields: category, temperature, isDaytime, description, updatedAt; derived `temperatureDisplay` (rounded int + "°"); factory `fromApiResponse(Map<String, dynamic> json)` that maps WeatherAPI.com condition codes to categories (1000=clear, 1003=partlyCloudy, 1006/1009=cloudy, 1063/1150-1201/1240-1246=rain, 1066/1114/1117/1204-1237/1255-1264=snow, 1087/1273-1282=thunderstorm, 1030/1135/1147=fog, fallback=cloudy)
- [x] T005 [P] Create `WeatherLocation` model in `lib/models/weather_condition.dart` — immutable with fields: cityName (String), latitude (double), longitude (double); `toJson()` and `fromJson()` for secure storage serialization
- [x] T006 Create `WeatherService` in `lib/services/weather_service.dart` — constructor accepts `http.Client`; method `Future<WeatherCondition?> fetchWeather(WeatherLocation location)` that calls `https://api.weatherapi.com/v1/current.json?key={KEY}&q={lat},{lon}`, parses response via `WeatherCondition.fromApiResponse()`, returns null on any error; method `Future<WeatherLocation?> fetchLocationByCity(String cityName)` that calls same endpoint with `q={cityName}`, extracts `location.name`, `location.lat`, `location.lon` from response, returns null on error
- [x] T007 [P] Create model unit tests in `test/models/weather_condition_test.dart` — test WeatherCategory mapping for all 7 categories + fallback, test `temperatureDisplay` formatting, test `isAnimated` for each category, test `WeatherLocation` JSON round-trip
- [x] T008 [P] Create service unit tests in `test/services/weather_service_test.dart` — use mocktail to mock `http.Client`, test successful weather fetch with sample API response, test null return on HTTP error, test null return on malformed JSON, test `fetchLocationByCity` returns WeatherLocation with resolved lat/lon

**Checkpoint**: Models and service ready — user story implementation can begin

---

## Phase 3: User Story 1 — See Current Weather at a Glance (Priority: P1) MVP

**Goal**: Weather visual (static icon or particle animation) appears behind the date area in the clock column, reflecting current conditions. Temperature shown as small text.

**Independent Test**: Configure a location, restart app, verify date area shows a weather-appropriate visual (sun for clear, rain drops for rainy, etc.) and temperature reading (e.g., "14°"). Date text remains fully legible.

### Implementation for User Story 1

- [x] T009 [US1] Create `WeatherBackground` widget in `lib/widgets/weather_background.dart` — StatelessWidget accepting `WeatherCondition?` and `Size`; uses `CustomPainter` to render CRT-styled visuals; static icons for calm conditions: clear day (sun lines), clear night (moon + stars), partlyCloudy (sun/moon + cloud), cloudy (cloud layers), fog (horizontal dashed lines); animated particles for dynamic conditions: rain (falling cyan drops), snow (falling white flakes), thunderstorm (rain + periodic flash); all drawn with CRT color palette at low opacity (0.3–0.5); particle state driven by `AnimationController` or external tick
- [x] T010 [US1] Add `AnimatedWeatherBackground` wrapper in `lib/widgets/weather_background.dart` — StatefulWidget that wraps `WeatherBackground` with an `AnimationController` (duration ~2s, repeating) for particle animations; passes normalized animation value to painter; only runs controller when `WeatherCondition.isAnimated` is true
- [x] T011 [US1] Modify `lib/widgets/clock_column.dart` — Stack `AnimatedWeatherBackground` behind the date text widget; pass `WeatherCondition?` as a new parameter; show temperature as small VT323 text (e.g., "14°") below or beside the date when weather data is available; ensure date text has sufficient contrast (text shadow or semi-opaque backing if needed)
- [x] T012 [US1] Modify `lib/screens/calendar_home_page.dart` — Add state fields: `WeatherCondition? _weather`, `WeatherLocation? _location`, `Timer? _weatherTimer`, `http.Client _weatherHttpClient`; create `WeatherService` instance with the http client; on init: load saved location from secure storage, if location exists fetch weather immediately; start 30-minute periodic timer for weather polling; pass `_weather` to `ClockColumn`; in `dispose()`: cancel timer and close `_weatherHttpClient`
- [x] T013 [US1] Modify `lib/main.dart` — Import weather config; no direct injection needed (CalendarHomePage creates its own WeatherService internally, consistent with existing GoogleCalendarService pattern)

**Checkpoint**: Weather visual displays behind date for a hardcoded or pre-saved location. MVP functional.

---

## Phase 4: User Story 2 — Configure Location (Priority: P2)

**Goal**: User can set their location via 'W' keyboard shortcut. Location persists across sessions via secure storage.

**Independent Test**: Press 'W', enter a city name (e.g., "Sofia"), confirm weather visual appears within seconds. Restart app, verify saved location is used automatically without re-prompting.

### Implementation for User Story 2

- [x] T014 [US2] Add 'W' keyboard shortcut handler in `lib/screens/calendar_home_page.dart` — in existing `KeyboardListener`/`RawKeyboardListener`, detect 'W' key press; show a simple `AlertDialog` with a `TextField` for city name input; on submit: call `WeatherService.fetchLocationByCity(cityName)`; if successful, save `WeatherLocation` to `flutter_secure_storage` (key: `weather_location`, value: JSON string), update `_location` state, trigger immediate weather fetch; if failed, show error `SnackBar`
- [x] T015 [US2] Add location persistence helpers in `lib/screens/calendar_home_page.dart` — `_loadSavedLocation()`: read `weather_location` from secure storage, deserialize via `WeatherLocation.fromJson()`, set `_location`; `_saveLocation(WeatherLocation loc)`: serialize via `toJson()`, write to secure storage; call `_loadSavedLocation()` in `initState`

**Checkpoint**: Full location configuration flow works. Location persists across restarts.

---

## Phase 5: User Story 3 — Graceful Degradation (Priority: P3)

**Goal**: App continues functioning normally when weather data is unavailable — no error dialogs, no blank screens, last known weather retained.

**Independent Test**: Disconnect network, restart app with a saved location. Verify date area shows no weather visual (or last known if previously fetched). No error dialogs appear. Reconnect network — weather appears on next poll cycle.

### Implementation for User Story 3

- [x] T016 [US3] Harden weather fetch error handling in `lib/screens/calendar_home_page.dart` — ensure `_fetchWeather()` catches all exceptions (network, timeout, parse errors); on failure: retain existing `_weather` value (do not set to null); use `debugPrint` for error logging (no user-visible errors); on first-ever failure (no prior data): `_weather` stays null, date area renders without weather visual (existing behavior)
- [x] T017 [US3] Ensure `WeatherBackground` handles null gracefully in `lib/widgets/weather_background.dart` and `lib/widgets/clock_column.dart` — when `WeatherCondition?` is null: ClockColumn renders date area without weather Stack layer (same as current behavior); no visual artifacts or layout shifts

**Checkpoint**: All user stories independently functional. App resilient to weather API failures.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [x] T018 Run `flutter analyze` — zero issues required
- [x] T019 Run `flutter test` — all tests pass
- [ ] T020 Visual verification: test all 7 weather categories (clear day/night, partlyCloudy day/night, cloudy, rain, snow, thunderstorm, fog) — confirm date text legibility across all conditions
- [ ] T021 Run quickstart.md validation — follow setup steps end-to-end on a clean build (requires real API key)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T003 for API key config)
- **User Story 1 (Phase 3)**: Depends on Foundational (T004-T006 for models and service)
- **User Story 2 (Phase 4)**: Depends on US1 (T012 sets up weather state in CalendarHomePage)
- **User Story 3 (Phase 5)**: Depends on US1 (T012 has the fetch logic to harden)
- **Polish (Phase 6)**: Depends on all user stories complete

### Within Each User Story

- Models before services (Phase 2)
- Service before widget integration (T006 before T009-T013)
- Widget creation before widget integration (T009-T010 before T011)
- Core implementation before integration (T011 before T012)

### Parallel Opportunities

**Phase 1**: T001 + T003 can run in parallel (T002 depends on T001 template)

**Phase 2**: T004 + T005 in parallel (different classes, same file but independent sections); T007 + T008 in parallel (different test files); T004/T005 must complete before T006 (service uses models)

**Phase 3 (US1)**: T009 + T010 are sequential (T010 wraps T009); T011 depends on T009/T010; T012 depends on T011; T013 can run in parallel with T012

**Phase 4 (US2)**: T014 + T015 are tightly coupled (same file, related logic) — execute sequentially

**Phase 5 (US3)**: T016 + T017 can run in parallel (different files)

---

## Parallel Example: Foundational Phase

```
# Launch model tasks in parallel:
Task: "Create WeatherCategory enum + WeatherCondition model in lib/models/weather_condition.dart"
Task: "Create WeatherLocation model in lib/models/weather_condition.dart"

# After models complete, launch test tasks in parallel:
Task: "Create model unit tests in test/models/weather_condition_test.dart"
Task: "Create service unit tests in test/services/weather_service_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational models + service (T004-T008)
3. Complete Phase 3: US1 — weather visual + polling (T009-T013)
4. **STOP and VALIDATE**: Weather visual renders behind date for a saved location
5. Demo if ready — core value delivered

### Incremental Delivery

1. Setup + Foundational -> Foundation ready
2. Add US1 (weather visual) -> Test independently -> Demo (MVP!)
3. Add US2 (location config) -> Test independently -> Demo
4. Add US3 (graceful degradation) -> Test independently -> Demo
5. Polish -> Final verification -> Complete

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Commit after each phase or logical group of tasks
- Stop at any checkpoint to validate story independently
- Total: 21 tasks across 6 phases
