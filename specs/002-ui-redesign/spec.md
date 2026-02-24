# Feature Specification: Retro CRT UI Redesign

**Feature Branch**: `002-ui-redesign`
**Created**: 2026-02-24
**Status**: Draft
**Input**: User description: "Custom desktop app with fixed 1400x450 window, no decorations, on portrait monitor. Explore eye-candy redesign with better readability, better use of space, and a more visually appealing clock and event layout. Retro/pixel art aesthetic."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Glance at Current Time and Today's Schedule (Priority: P1)

The user glances at the app on their secondary portrait monitor to see the current time and get an instant overview of their day's meetings. The flip clock on the left provides the time at a glance, while the horizontal timeline strip shows all events as color-coded blocks with truncated titles, making it immediately clear how the day is structured and where the current moment falls relative to meetings.

**Why this priority**: This is the core use case — the user checks this app dozens of times a day for a quick time-and-schedule overview. Every other feature builds on this layout.

**Independent Test**: Can be fully tested by launching the app with mock events and verifying: flip clock displays correct time, timeline shows event blocks at correct positions with titles, NOW marker is visible and positioned correctly, and the dark CRT color palette is applied.

**Acceptance Scenarios**:

1. **Given** the user is signed in with events loaded, **When** they glance at the app, **Then** the flip clock on the left shows the current time (HH:MM), the date is displayed below it (day-of-week, day, month, year), and the timeline strip shows all events as colored blocks with truncated titles
2. **Given** events span the working day, **When** the timeline renders, **Then** event blocks are positioned proportionally by time, with hour markers along the top, a NOW marker (vertical line) indicates the current position, and the visible range shows one past event plus all future events
3. **Given** an event just ended, **When** the timeline updates, **Then** it smoothly scrolls so the ended event is the single past event visible on the left edge
4. **Given** the app is running, **When** one minute passes, **Then** the flip clock updates with an animation and the NOW marker shifts position

---

### User Story 2 - Identify Ongoing Meeting with Progress (Priority: P1)

The user needs to instantly see which meeting is currently happening, how far through it they are, and whether they can join. The ongoing event appears as a prominent "hero card" in the detail area with a progress bar and JOIN button. In the timeline, the ongoing event's block is highlighted in phosphor blue.

**Why this priority**: Knowing the current meeting status is the primary reason the user glances at the app. The hero card provides all critical info without reading small text.

**Independent Test**: Can be fully tested by setting the clock to a time during an event and verifying: hero card appears with event title, time range, progress bar (percentage), and JOIN button. Timeline block for this event is phosphor blue.

**Acceptance Scenarios**:

1. **Given** an event is currently ongoing, **When** the detail area renders, **Then** a hero card appears with: event title, time range (start → end), progress bar showing percentage complete, and a JOIN button (red if meeting link exists, grey if not)
2. **Given** an ongoing event has a Google Meet link, **When** the user taps the JOIN button, **Then** the meeting URL opens in the system browser
3. **Given** an event is 62% through, **When** the hero card renders, **Then** the progress bar shows approximately 62% filled and the text reads "62%"

---

### User Story 3 - See Upcoming Events and Countdowns (Priority: P2)

Below the hero card (or at the top if no meeting is ongoing), the user sees a scrollable list of upcoming events as compact rows with countdown timers. The next upcoming event (within 10 minutes) is highlighted in warm amber both in the timeline and detail list.

**Why this priority**: After checking the current meeting, the user's next question is "what's next and when?" Countdowns answer this without mental math.

**Independent Test**: Can be fully tested by loading events at various future times and verifying: compact rows show title, time range, and countdown. Events within 10 minutes show amber highlighting. List is scrollable.

**Acceptance Scenarios**:

1. **Given** multiple future events exist, **When** the detail area renders, **Then** each non-ongoing event appears as a compact row with: status indicator, title, time range, and countdown ("In 12m", "In 1h 30m")
2. **Given** an event starts in 5 minutes, **When** the detail area renders, **Then** that event's row and timeline block are highlighted in warm amber (#ffb74d)
3. **Given** 9+ events exist, **When** the detail area is full, **Then** the user can scroll to see additional events

---

### User Story 4 - Timeline Shows Rich Contextual Info (Priority: P2)

The timeline strip displays event blocks with truncated titles in a small pixel font, color-coded by status. Near the NOW marker, contextual info appears: "ends in 12m" for ongoing events or "next in 5m" for the nearest upcoming event.

**Why this priority**: The timeline is the secondary glance target. Rich info in the timeline reduces the need to look at the detail area for quick checks.

**Independent Test**: Can be fully tested by loading events with various statuses and verifying: blocks show titles, colors match status, NOW marker has countdown text.

**Acceptance Scenarios**:

1. **Given** events are loaded, **When** the timeline renders, **Then** each event appears as a block whose width is proportional to its duration, containing a truncated title in a small pixel font
2. **Given** a meeting is ongoing, **When** the NOW marker renders, **Then** it shows "ends in Xm" next to the marker
3. **Given** no meeting is ongoing but one starts in 8 minutes, **When** the NOW marker renders, **Then** it shows "next in 8m"

---

### User Story 5 - Retro CRT Visual Aesthetic (Priority: P3)

The entire app uses a dark CRT-inspired color palette with a deep navy-black background, phosphor-colored accents, and retro pixel-style typography. The flip clock has dark slate flaps with bright white digits. The overall feel is a retro terminal or departure board aesthetic.

**Why this priority**: The aesthetic is the "eye-candy" goal of this redesign. While functional layout is more critical, the visual polish is what makes the app enjoyable to glance at all day.

**Independent Test**: Can be fully tested by launching the app and visually verifying: dark background (#1a1a2e), CRT color palette applied throughout, flip clock rendered with flap styling, pixel-style font used in timeline.

**Acceptance Scenarios**:

1. **Given** the app launches, **When** the UI renders, **Then** the background is deep navy-black (#1a1a2e), text is bright (#e0e0e0), and the timeline strip background is darker (#0d0d1a)
2. **Given** the flip clock is displayed, **When** a digit changes, **Then** the top half of the old digit flap rotates down to reveal the new digit (split-flap animation), with dark slate flaps (#2d2d44) and bright white digits (#e0e0e0)
3. **Given** events have different statuses, **When** they render, **Then** ongoing events are phosphor blue (#4fc3f7), upcoming events are warm amber (#ffb74d), and normal events are dim green (#66bb6a)

---

### Edge Cases

- What happens when no events are loaded? The detail area shows "No upcoming events" text in the retro style, and the timeline strip is empty with only hour markers and the NOW marker visible
- What happens when events overlap (same time slot)? Overlapping events stack in the timeline (multiple thin blocks) and appear as separate rows in the detail area, grouped together. When multiple events are ongoing, the one ending soonest gets the hero card; other ongoing events appear as blue-accented compact rows
- What happens when an event title is very long? Titles are truncated with ellipsis in both the timeline blocks and the detail compact rows. The hero card can show more of the title due to its larger size
- How does the layout handle the transition from today to tomorrow? A "Tomorrow" separator appears in the detail list between today's and tomorrow's events, consistent with existing behavior
- What happens when the user is not signed in? The sign-in screen uses the same dark CRT background with a styled "Sign in with Google" button

## Clarifications

### Session 2026-02-24

- Q: When multiple events are ongoing simultaneously, which gets the hero card? → A: The event ending soonest gets the hero card (most time-sensitive); other ongoing events appear as compact rows with blue accent.
- Q: What time range should the timeline display? → A: Dynamic with auto-scroll. The timeline always shows exactly one past event (the most recently ended) plus all future events. When a meeting ends, the timeline smoothly scrolls so the newly-ended event becomes the single past event shown. Before any meeting ends, the timeline starts from the first event of the day.
- Q: How elaborate should the flip clock animation be? → A: Classic split-flap flip animation — top half of the flap rotates down to reveal the new digit underneath, mimicking a physical departure board.
- Q: How should the retro pixel font be sourced? → A: Use the google_fonts package with "Press Start 2P" for timeline block titles and "VT323" for other retro text (compact rows, date display, general UI text).
- Q: Should the detail area show past events? → A: No. Detail area shows only ongoing + future events. The one past event is visible in the timeline strip only, providing context without consuming detail area space.
- Q: Should tomorrow's events appear on the timeline strip? → A: No. The timeline shows today's events only. Tomorrow's events appear exclusively in the detail area's scrollable list (with a "Tomorrow" separator).
- Q: Where should the exit button live in the new layout (no app bar)? → A: Bottom of the clock column, below the date. Small exit icon, accessible but unobtrusive.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App MUST display a split-flap flip clock in a left column (~180px wide) spanning the full window height, showing hours and minutes with the current date stacked below, and an exit button at the bottom of the column. Digit transitions MUST use a split-flap flip animation (top half rotates down to reveal new digit)
- **FR-002**: App MUST display a horizontal timeline strip (~100px tall) in the top-right area with hour markers, proportionally positioned event blocks, and a NOW marker. The timeline MUST show today's events only (tomorrow's events appear in the detail area only). The visible range MUST be dynamic: showing one most-recently-ended event plus all remaining today events. Before any event ends, the range starts from the first event of the day
- **FR-013**: The timeline MUST auto-scroll smoothly when a meeting ends, so that the newly-ended event becomes the single past event visible on the left edge
- **FR-003**: Timeline event blocks MUST show truncated event titles in "Press Start 2P" pixel font (small size), color-coded by event status (ongoing=blue, upcoming=amber, normal=green). Other retro text (compact rows, date, general UI) MUST use "VT323" font. Both sourced via the google_fonts package
- **FR-004**: The NOW marker on the timeline MUST display contextual countdown text: "ends in Xm" during ongoing events or "next in Xm" when the next event is approaching
- **FR-005**: App MUST display a scrollable detail area (~350px tall) below the timeline, showing a hero card for the ongoing event (when multiple ongoing, the one ending soonest) and compact rows for other events
- **FR-006**: The hero card MUST show: event title, time range, progress bar with percentage, and a JOIN button (red with meeting link, grey without)
- **FR-007**: Compact event rows MUST show: status indicator, event title, time range, and countdown to start. Detail area MUST only display ongoing and future events (past events appear in the timeline strip only)
- **FR-008**: App MUST use the dark CRT color palette as defined in the design (background #1a1a2e, ongoing #4fc3f7, upcoming #ffb74d, normal #66bb6a, clock flaps #2d2d44, text #e0e0e0)
- **FR-009**: All existing functionality MUST be preserved: OAuth authentication, token storage, event fetching/polling, error handling via SnackBars, meeting link opening
- **FR-010**: The flip clock MUST update every second (consistent with existing clock behavior)
- **FR-011**: Timeline and detail area MUST update per-second for countdowns and progress, and every 60 seconds for event data (consistent with existing polling)
- **FR-012**: The detail area MUST be scrollable when events exceed the visible space

### Key Entities

- **Clock Column**: Left-side panel (~180px) containing the flip clock digits, date display, and exit button at the bottom, spanning full window height
- **Timeline Strip**: Horizontal bar showing proportionally-spaced event blocks with titles, hour markers, and a NOW marker with countdown
- **Hero Card**: Prominent display card for the currently ongoing event, showing full details, progress bar, and JOIN action
- **Compact Event Row**: Single-line event entry for non-ongoing events in the detail area, showing essential info and countdown

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: User can identify the current time within 1 second of glancing at the app (flip clock is large and immediately readable)
- **SC-002**: User can identify their current or next meeting within 2 seconds of glancing (hero card and timeline provide instant context)
- **SC-003**: All 9+ events for a typical workday are accessible via scrolling in the detail area without losing sight of the timeline or clock
- **SC-004**: Event status changes (normal → upcoming → ongoing) are visually distinct through color transitions in both the timeline and detail area
- **SC-005**: All existing tests continue to pass after the redesign (model tests, service tests, widget tests)
- **SC-006**: The app renders correctly at the fixed 1400x450 window size with no overflow or clipping
