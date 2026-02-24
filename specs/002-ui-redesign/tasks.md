# Tasks: Retro CRT UI Redesign

**Input**: Design documents from `/specs/002-ui-redesign/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Existing tests will be updated in the Polish phase. No new test-first tasks — this is a visual redesign with unchanged business logic.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Add new dependency and create shared CRT theme infrastructure

- [ ] T001 Add `google_fonts: ^6.0.0` dependency to `pubspec.yaml` and run `flutter pub get`
- [ ] T002 Create `lib/config/crt_theme.dart` with all color constants (background #1a1a2e, timelineBg #0d0d1a, ongoing #4fc3f7, upcoming #ffb74d, normal #66bb6a, clockFlap #2d2d44, clockDigit #e0e0e0, textPrimary #e0e0e0, textSecondary #b0b0b0, joinActive #ef5350, joinDisabled #757575) and a `CrtTheme.themeData()` factory returning a Material 3 dark `ThemeData` with CRT palette overrides

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Apply CRT theme and create the new layout skeleton that all user stories plug into

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Update `lib/main.dart` to use `CrtTheme.themeData()` from `lib/config/crt_theme.dart` instead of the current deepPurple seed theme
- [ ] T004 Rewrite `lib/screens/calendar_home_page.dart` layout to a `Row` with: left clock column placeholder (Container, 180px wide, CRT background) + right `Column` with timeline strip placeholder (~100px tall, timelineBg color) and detail area placeholder (Expanded, scrollable). Preserve ALL existing state management: `_isLoggedIn`, `_isLoading`, `_hasCompletedFirstLoad`, `_events`, `_now` ValueNotifier, `_dataFetchTimer`, `_clockTimer`, sign-in flow, error SnackBars, `_updateEvents()`, `_handleSignIn()`

**Checkpoint**: App launches with dark CRT background, placeholder layout visible, existing auth/polling/error handling works

---

## Phase 3: User Story 1 — Glance at Current Time and Schedule (Priority: P1) 🎯 MVP

**Goal**: User sees flip clock with time/date on the left, and a timeline strip with event blocks on the right

**Independent Test**: Launch app with events loaded → flip clock shows HH:MM, date shows below, timeline shows colored event blocks at proportional positions with hour markers and NOW marker

### Implementation for User Story 1

- [ ] T005 [P] [US1] Create `lib/widgets/flip_digit.dart` — StatefulWidget with SingleTickerProviderStateMixin. Accepts `int digit` and `ValueNotifier<DateTime>`. On digit change, runs a ~300ms flip animation: top half clips to upper 50% and rotates from 0 to π/2 (old digit disappears), bottom half clips to lower 50% and rotates from -π/2 to 0 (new digit appears). Uses dark slate flap background (#2d2d44) with rounded corners, bright white digits (#e0e0e0), large monospace VT323 font (~48px)
- [ ] T006 [US1] Create `lib/widgets/flip_clock.dart` — StatelessWidget composing 4 FlipDigit widgets (2 for hours, 2 for minutes) with a static colon separator between them. Accepts `ValueNotifier<DateTime> now`. Extracts hours/minutes from the ValueNotifier value and passes individual digits to each FlipDigit
- [ ] T007 [US1] Create `lib/widgets/clock_column.dart` — StatelessWidget. Contains: FlipClock at top (centered), date display below (day-of-week, day, month, year in stacked VT323 text, textPrimary color), exit button at bottom (small `Icons.exit_to_app` icon, calls `SystemNavigator.pop()` on Linux). Accepts `ValueNotifier<DateTime> now`. Full-height Column with MainAxisAlignment.spaceBetween, 180px wide, CRT background color
- [ ] T008 [US1] Create `lib/widgets/timeline_strip.dart` — StatelessWidget wrapping a `CustomPaint` widget. Accepts `List<CalendarEvent> events` (today only), `ValueNotifier<DateTime> now`. The CustomPainter: draws timelineBg background, computes visible time range (first event start to last event end with 30-min padding), draws hour marker lines with labels (VT323, 10px, textSecondary), draws event blocks as filled rounded rects positioned proportionally by time (width = duration proportion), colored by status (ongoing=#4fc3f7, upcoming=#ffb74d, normal=#66bb6a). Draws a vertical NOW marker line at current time position (textPrimary color, 2px wide). ~100px tall
- [ ] T009 [US1] Wire ClockColumn and TimelineStrip into `lib/screens/calendar_home_page.dart`: replace the left placeholder with ClockColumn (passing `_now`), replace timeline placeholder with TimelineStrip (passing today's events filtered from `_events` and `_now`). Filter today's events: keep only events where `startTime.day == DateTime.now().day`

**Checkpoint**: App shows flip clock with animated digit transitions, date, exit button on left. Timeline shows colored event blocks with hour markers and NOW line on top-right. Existing auth/polling still works.

---

## Phase 4: User Story 2 — Identify Ongoing Meeting with Progress (Priority: P1)

**Goal**: The ongoing event (ending soonest) appears as a prominent hero card with progress bar and JOIN button

**Independent Test**: Set clock to mid-meeting time → hero card shows event title, time range, progress bar (correct %), and JOIN button (red if link exists)

### Implementation for User Story 2

- [ ] T010 [P] [US2] Create `lib/widgets/hero_card.dart` — StatelessWidget. Accepts `CalendarEvent event` and `ValueNotifier<DateTime> now`. Uses ValueListenableBuilder to compute live progress and countdown. Renders: bordered Card with phosphor blue (#4fc3f7) glow/border, event title (VT323, ~20px, textPrimary), time range "HH:MM → HH:MM" (VT323, textPrimary), progress bar (LinearProgressIndicator or custom, filled with ongoing color, track with clockFlap color) with percentage text, JOIN ElevatedButton (red #ef5350 background + white Icons.videocam if meetingLink != null and https scheme, grey #757575 + disabled if no link). Opens meeting link via `launchUrl`
- [ ] T011 [US2] Add hero card selection logic in `lib/screens/calendar_home_page.dart`: compute `heroEvent` as the ongoing event with earliest `endTime` from the current event list. Null if no ongoing events. Pass to detail area
- [ ] T012 [US2] Wire HeroCard into the detail area of `lib/screens/calendar_home_page.dart`: if `heroEvent` is not null, show HeroCard at the top of the detail area Expanded section. Other ongoing events appear below as placeholder rows (will be styled in US3)

**Checkpoint**: During an ongoing event, hero card appears with live progress bar and functional JOIN button. When no event is ongoing, detail area shows no hero card.

---

## Phase 5: User Story 3 — See Upcoming Events and Countdowns (Priority: P2)

**Goal**: Below the hero card, a scrollable list shows all upcoming events with countdowns. Upcoming events (within 10 min) highlighted in amber.

**Independent Test**: Load 9+ events → scrollable list shows compact rows with status dots, titles, time ranges, countdowns. Events within 10 min have amber highlighting.

### Implementation for User Story 3

- [ ] T013 [P] [US3] Create `lib/widgets/compact_event_row.dart` — StatelessWidget. Accepts `CalendarEvent event` and `ValueNotifier<DateTime> now`. Uses ValueListenableBuilder. Renders a single Row: status dot (Circle, colored by event status: ongoing=#4fc3f7, upcoming=#ffb74d, normal=#66bb6a), event title (VT323, 14px, textPrimary, ellipsis overflow), time range "HH:MM→HH:MM" (VT323, 12px, textSecondary), countdown "In Xm" or "In Xh Ym" (VT323, 12px, upcoming=#ffb74d for upcoming, textSecondary for normal). Compact single-line height (~40px). Optional JOIN icon button on the right for events with meeting links
- [ ] T014 [US3] Create `lib/widgets/detail_area.dart` — StatelessWidget. Accepts `List<CalendarEvent> events` (ongoing + future only, no past), `CalendarEvent? heroEvent`, `ValueNotifier<DateTime> now`. Renders: HeroCard at top if heroEvent != null, then a scrollable ListView of CompactEventRow for remaining events (excluding heroEvent). Insert a "Tomorrow" separator (full-width row, VT323, textSecondary, centered "--- Tomorrow ---") between today's and tomorrow's events. Other ongoing events (not the hero) show as compact rows with blue accent
- [ ] T015 [US3] Wire DetailArea into `lib/screens/calendar_home_page.dart`: replace the detail area placeholder with DetailArea widget. Filter events to ongoing + future only (exclude past events). Pass `heroEvent` and `_now`. Keep existing empty state ("No upcoming events" in VT323 on CRT background) and loading state (CircularProgressIndicator with CRT-compatible colors)

**Checkpoint**: Full detail area functional. Hero card for ongoing + scrollable compact rows for all other events. Scrolling works with 9+ events. Tomorrow separator visible.

---

## Phase 6: User Story 4 — Timeline Shows Rich Contextual Info (Priority: P2)

**Goal**: Timeline blocks show truncated titles in pixel font. NOW marker shows countdown text. Timeline auto-scrolls when meetings end.

**Independent Test**: Load events → timeline blocks show "1:1", "Sprint" etc. in Press Start 2P font. NOW marker shows "ends in 12m" during meeting or "next in 5m" before meeting. When a meeting ends, timeline smoothly scrolls.

### Implementation for User Story 4

- [ ] T016 [P] [US4] Create `lib/widgets/now_marker.dart` — StatelessWidget overlay for the timeline. Accepts `List<CalendarEvent> todayEvents`, `ValueNotifier<DateTime> now`, and timeline viewport parameters. Uses ValueListenableBuilder. Computes: if any event is ongoing, show "ends in Xm" (time until end of soonest-ending ongoing event); if no ongoing but next event starts within 30 min, show "next in Xm". Renders text in VT323 font, textPrimary color, positioned near the NOW marker line
- [ ] T017 [US4] Add event title text overlay to timeline blocks in `lib/widgets/timeline_strip.dart`: within the CustomPainter, after drawing each event block rect, draw the event summary text (truncated to block width) using Press Start 2P font at ~8px. Use `TextPainter` with maxLines: 1 and ellipsis. Text color: textPrimary for ongoing/upcoming, clockDigit for normal
- [ ] T018 [US4] Implement timeline auto-scroll in `lib/widgets/timeline_strip.dart`: compute dynamic viewport range — startTime is the start of the most recently ended event (or first event if none ended), endTime is end of last today event + 30-min padding. When viewport startTime changes (a meeting just ended), animate the transition smoothly (~500ms). Use an `AnimatedValue` or internal state to interpolate between old and new viewport positions. Wrap the timeline in a StatefulWidget if needed to own the animation controller

**Checkpoint**: Timeline blocks show truncated titles. NOW marker shows contextual countdown. When a meeting ends, timeline smoothly scrolls to show the ended meeting as the single past event.

---

## Phase 7: User Story 5 — Retro CRT Visual Aesthetic (Priority: P3)

**Goal**: Full retro CRT aesthetic applied to all screens — fonts, sign-in, loading, empty, error states

**Independent Test**: Launch app → dark CRT background everywhere. Sign-in button styled retro. Loading spinner themed. Empty state uses VT323. SnackBars match dark theme.

### Implementation for User Story 5

- [ ] T019 [P] [US5] Apply VT323 font to all remaining text in `lib/widgets/compact_event_row.dart`, `lib/widgets/detail_area.dart`, `lib/widgets/clock_column.dart`, and `lib/widgets/hero_card.dart`. Ensure Press Start 2P is used only in timeline block titles. Verify all text uses CrtTheme color constants (no hardcoded Colors.white or Colors.black)
- [ ] T020 [P] [US5] Style sign-in screen in `lib/screens/calendar_home_page.dart`: "Sign in with Google" button uses VT323 font, CRT-themed ElevatedButton (clockFlap background, textPrimary text, subtle border). Center on CRT dark background. Style loading state: CircularProgressIndicator with ongoing color (#4fc3f7). Style empty state: "No upcoming events" in VT323, textSecondary color
- [ ] T021 [US5] Style SnackBars in `lib/screens/calendar_home_page.dart` and/or `lib/config/crt_theme.dart`: update `_showErrorSnackBar` or the theme's `snackBarTheme` so error messages use VT323 font, dark background matching CRT palette, textPrimary content color. Retry action button in upcoming color (#ffb74d)

**Checkpoint**: Entire app has consistent CRT retro aesthetic. No default Material colors visible. All states (sign-in, loading, empty, error, events) match the dark CRT palette.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Clean up, verify, validate

- [ ] T022 Delete old widget files: `lib/widgets/clock_widget.dart`, `lib/widgets/event_card.dart`, `lib/widgets/event_list.dart`. Remove any unused imports referencing these files
- [ ] T023 Update `test/widgets/calendar_home_page_test.dart`: adapt assertions to new layout. Sign-in button test should still find "Sign in with Google". Loading spinner test unchanged (CircularProgressIndicator). Empty state should find "No upcoming events". Error SnackBar tests should still find error message text and Retry button. Update any widget finders that reference deleted widgets
- [ ] T024 Run `flutter analyze` — must report zero issues. Fix any warnings or errors
- [ ] T025 Run `flutter test` — all tests must pass (model: 17, service: 6, widget: 7). Fix any failures from layout changes
- [ ] T026 Visual validation: run `flutter run -d linux` at 1400x450 and verify no overflow, no clipping, all elements visible and correctly positioned. Verify flip clock animation works, timeline shows events, hero card appears during ongoing meetings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2. Must complete before US2 (hero card needs detail area context)
- **US2 (Phase 4)**: Depends on US1 (needs layout wired)
- **US3 (Phase 5)**: Depends on US2 (needs hero card to compose into detail area)
- **US4 (Phase 6)**: Depends on US1 (needs timeline_strip.dart). Can run in parallel with US3
- **US5 (Phase 7)**: Depends on US1-US4 (needs all widgets to exist for font/style application)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

```text
Phase 1 (Setup) → Phase 2 (Foundational)
                     ↓
                  Phase 3 (US1: Clock + Timeline)
                     ↓              ↓
              Phase 4 (US2)    Phase 6 (US4) ← can parallel
                     ↓
              Phase 5 (US3)
                     ↓
              Phase 7 (US5)
                     ↓
              Phase 8 (Polish)
```

### Within Each User Story

- Widgets with [P] can be built in parallel (independent files)
- Wiring/integration tasks depend on their widget tasks
- Each phase checkpoint should be validated before moving on

### Parallel Opportunities

- T005 (FlipDigit) can run in parallel — standalone widget, no deps beyond CrtTheme
- T010 (HeroCard) can run in parallel — standalone widget
- T013 (CompactEventRow) can run in parallel — standalone widget
- T016 (NowMarker) can run in parallel — standalone widget
- T019, T020 (US5 styling) can run in parallel — different files
- US3 and US4 can run in parallel after US2 completes (US4 only needs US1's timeline, US3 needs US2's hero card)

---

## Parallel Example: User Story 1

```bash
# FlipDigit has no deps beyond CrtTheme — can start immediately after Phase 2:
Task: "Create FlipDigit in lib/widgets/flip_digit.dart"

# Then sequentially:
Task: "Create FlipClock in lib/widgets/flip_clock.dart"   # depends on FlipDigit
Task: "Create ClockColumn in lib/widgets/clock_column.dart"  # depends on FlipClock
Task: "Create TimelineStrip in lib/widgets/timeline_strip.dart"  # independent of clock
Task: "Wire into CalendarHomePage"  # depends on ClockColumn + TimelineStrip
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T004)
3. Complete Phase 3: US1 — Clock + Timeline (T005-T009)
4. **STOP and VALIDATE**: Flip clock works, timeline shows events, dark CRT theme applied
5. This alone delivers the core glance experience

### Incremental Delivery

1. Setup + Foundational → Dark CRT skeleton
2. US1 (Clock + Timeline) → Core glance experience (MVP!)
3. US2 (Hero Card) → Ongoing meeting prominence
4. US3 (Detail Area) → Full event list with scrolling
5. US4 (Timeline Rich Info) → Titles, NOW countdown, auto-scroll
6. US5 (Aesthetic Polish) → Fonts and styling consistency
7. Polish → Tests, cleanup, validation

### Single Developer Strategy (Recommended)

Execute phases sequentially: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Each phase builds on the previous. Commit after each checkpoint.

---

## Notes

- [P] tasks = different files, no dependencies on other tasks in the same phase
- [Story] label maps task to specific user story for traceability
- Models and services are UNCHANGED — only widget/screen layer and theme are modified
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- All CrtTheme colors must come from `lib/config/crt_theme.dart` — no hardcoded hex in widgets
