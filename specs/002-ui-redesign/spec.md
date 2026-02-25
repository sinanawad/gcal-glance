# Feature Specification: Retro CRT UI Redesign

**Feature Branch**: `002-ui-redesign`
**Created**: 2026-02-24
**Status**: Implemented (v2 — tentative meetings + dual hero)
**Input**: User description: "Custom desktop app with fixed 1436x462 window, no decorations, on portrait monitor. Explore eye-candy redesign with better readability, better use of space, and a more visually appealing clock and event layout. Retro/pixel art aesthetic."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Glance at Current Time and Today's Schedule (Priority: P1)

The user glances at the app on their secondary portrait monitor to see the current time and get an instant overview of their day's meetings. The flip clock on the left provides the time at a glance with tall split-flap digits, while the horizontal timeline strip shows all events as color-coded blocks (no titles — alternating solid/striped patterns distinguish events), making it immediately clear how the day is structured and where the current moment falls relative to meetings.

**Why this priority**: This is the core use case — the user checks this app dozens of times a day for a quick time-and-schedule overview. Every other feature builds on this layout.

**Independent Test**: Can be fully tested by launching the app with mock events and verifying: flip clock displays correct time with tall digits, timeline shows event blocks with alternating patterns at correct positions, NOW marker is fixed at 25% width and positioned correctly, and the dark CRT color palette is applied.

**Acceptance Scenarios**:

1. **Given** the user is signed in with events loaded, **When** they glance at the app, **Then** the flip clock on the left shows the current time (HH:MM) with tall split-flap digits, the date is displayed immediately below it (day-of-week, day, month, year in larger font), and the timeline strip shows all events as colored blocks with alternating fill patterns
2. **Given** events span the working day, **When** the timeline renders, **Then** event blocks are positioned proportionally by time, with hour markers along the top, a NOW marker (vertical line with triangle) is fixed at 25% of the timeline width, and the 5-hour viewport slides as time passes
3. **Given** the app is running, **When** one minute passes, **Then** the flip clock updates with a split-flap animation and the timeline slides smoothly (1-second update interval)

---

### User Story 2 - Identify Ongoing Meeting with Progress (Priority: P1)

The user needs to instantly see which meeting is currently happening, how far through it they are, and whether they can join. Only ongoing events **with a Google Meet link** get the hero card treatment with a progress bar and JOIN button. Ongoing events without a meeting link appear as regular compact rows. In the timeline, the ongoing event's block is highlighted in phosphor blue.

**Hero priority**: Accepted events take precedence over tentative ones. If multiple accepted meetings with links are ongoing simultaneously, ALL of them get hero cards (stacked vertically in compact mode). Tentative events only get a hero card if no accepted events are ongoing.

**Why this priority**: Knowing the current meeting status is the primary reason the user glances at the app. The hero card provides all critical info without reading small text.

**Independent Test**: Can be fully tested by setting the clock to a time during an event with a meeting link and verifying: hero card appears with event title, time range, progress bar (percentage), and JOIN button. Events without meeting links do NOT get a hero card. Timeline block for ongoing events is phosphor blue.

**Acceptance Scenarios**:

1. **Given** an accepted event with a meeting link is currently ongoing, **When** the detail area renders, **Then** a hero card appears with: event title, time range (start → end), progress bar showing percentage complete, and a JOIN button (red)
2. **Given** an ongoing event has no meeting link, **When** the detail area renders, **Then** it appears as a regular compact row (no hero card, no progress bar)
3. **Given** an ongoing event has a Google Meet link, **When** the user taps the JOIN button, **Then** the meeting URL opens in the system browser
4. **Given** an event is 62% through, **When** the hero card renders, **Then** the progress bar shows approximately 62% filled and the text reads "62%"
5. **Given** two accepted events with meeting links are ongoing simultaneously, **When** the detail area renders, **Then** both events get compact hero cards stacked vertically (smaller title, reduced padding, single-line titles)
6. **Given** one accepted and one tentative event are both ongoing with links, **When** the detail area renders, **Then** only the accepted event gets a hero card; the tentative one appears as a compact row with crosshatch overlay
7. **Given** only a tentative event with a meeting link is ongoing (no accepted), **When** the detail area renders, **Then** the tentative event gets a hero card with an amber border and "TENTATIVE" label

---

### User Story 3 - See Upcoming Events and Countdowns (Priority: P2)

Below the hero card (or at the top if no meeting is ongoing), the user sees a scrollable list of upcoming events as compact rows with countdown timers. Events are grouped by start time with alternating row backgrounds and separator lines between groups. Events with meeting links appear in larger font with bold titles; events without links use a smaller, dimmer style. The next upcoming event (within 10 minutes) is highlighted in warm amber both in the timeline and detail list.

**Why this priority**: After checking the current meeting, the user's next question is "what's next and when?" Countdowns answer this without mental math.

**Independent Test**: Can be fully tested by loading events at various future times and verifying: compact rows show status icon, title, time range, and countdown. Events with meeting links are bold/larger; events without are smaller/dimmer. Alternating group backgrounds visible. Events within 10 minutes show amber highlighting. List is scrollable.

**Acceptance Scenarios**:

1. **Given** multiple future events exist, **When** the detail area renders, **Then** each non-hero event appears as a compact row with: status icon (videocam/bell/calendar), title, time range, and countdown ("In 12m", "In 1h 30m")
2. **Given** events with and without meeting links exist, **When** the detail area renders, **Then** linked events show 24px bold text and full-brightness colors, while non-linked events show 20px normal text with dimmer (60% alpha) colors
3. **Given** events are grouped by start time, **When** the detail area renders, **Then** groups alternate between dark slate and base background colors, with subtle separator lines between groups
4. **Given** an event starts in 5 minutes, **When** the detail area renders, **Then** that event's row and timeline block are highlighted in warm amber (#ffb74d)
5. **Given** 9+ events exist, **When** the detail area is full, **Then** the user can scroll to see additional events
6. **Given** all events in a row, **When** they render, **Then** time range, countdown, and join icon columns are fixed-width and right-aligned for consistent visual alignment regardless of meeting link presence

---

### User Story 4 - Timeline Shows Fixed-NOW Sliding Scale (Priority: P2)

The timeline strip displays a 5-hour sliding window with the NOW marker fixed at 25% of the width. Event blocks use alternating visual patterns (solid fill vs horizontal stripes) to distinguish adjacent meetings — no titles are shown. Overlapping events are indicated by diagonal hatching over the overlap region. Near the NOW marker, contextual info appears: "ends Xm" for ongoing events or "next Xm" for the nearest upcoming event (up to 60 minutes out).

**Why this priority**: The timeline is the secondary glance target. The fixed-NOW design keeps temporal context stable and predictable.

**Independent Test**: Can be fully tested by loading events with various statuses and verifying: NOW marker is at 25% width, 5-hour window slides correctly, blocks use alternating patterns, overlaps show hatching, countdown text appears near NOW.

**Acceptance Scenarios**:

1. **Given** events are loaded, **When** the timeline renders, **Then** NOW is fixed at 25% of the timeline width, showing 1h15m of past and 3h45m of future
2. **Given** events are loaded, **When** the timeline renders, **Then** each event appears as a block whose width is proportional to its duration, with alternating solid/striped fills and a colored border (no titles)
3. **Given** two events overlap in time, **When** the timeline renders, **Then** the overlap region is marked with diagonal hatching (white lines at 30% opacity)
4. **Given** a meeting is ongoing, **When** the NOW marker renders, **Then** it shows "ends Xm" next to the marker
5. **Given** no meeting is ongoing but one starts in 20 minutes, **When** the NOW marker renders, **Then** it shows "next 20m"

---

### User Story 5 - Retro CRT Visual Aesthetic (Priority: P3)

The entire app uses a dark CRT-inspired color palette with a deep navy-black background, phosphor-colored accents, and retro pixel-style typography. The flip clock has dark slate flaps with bright white digits and fills the clock column prominently. The date sits immediately below the clock in larger font. Compact event rows have card-like styling with colored left borders and status icons. The overall feel is a retro terminal or departure board aesthetic.

**Why this priority**: The aesthetic is the "eye-candy" goal of this redesign. While functional layout is more critical, the visual polish is what makes the app enjoyable to glance at all day.

**Independent Test**: Can be fully tested by launching the app and visually verifying: dark background (#1a1a2e), CRT color palette applied throughout, flip clock rendered with tall flap styling filling the column, VT323 font used throughout, event rows have left border + status icons + alternating backgrounds.

**Acceptance Scenarios**:

1. **Given** the app launches, **When** the UI renders, **Then** the background is deep navy-black (#1a1a2e), text is bright (#e0e0e0), and the timeline strip background is darker (#0d0d1a)
2. **Given** the flip clock is displayed, **When** a digit changes, **Then** the top half of the old digit flap rotates down to reveal the new digit (split-flap animation), with dark slate flaps (#2d2d44) and bright white digits (#e0e0e0). Digits are tall (180px internal height) and fill the 180px column via FittedBox scaling
3. **Given** events have different statuses, **When** they render, **Then** ongoing events are phosphor blue (#4fc3f7), upcoming events are warm amber (#ffb74d), and normal events are dim green (#66bb6a)
4. **Given** event rows render, **When** displayed, **Then** each row has a 3px colored left border, a status icon, and alternating group background colors

---

### User Story 6 - Tentative/Unresponded Meeting Distinction (Priority: P2)

The user needs to distinguish at a glance between meetings they've accepted and meetings they haven't responded to (tentative/needsAction). Tentative events get a crosshatch background overlay in both the compact event rows and the timeline blocks. Declined events are completely hidden from the UI.

**Why this priority**: When the calendar has a mix of accepted and tentative meetings, it's important to visually separate "committed" from "maybe" without cluttering the interface.

**Independent Test**: Can be tested by loading events with different response statuses (accepted, tentative, needsAction, declined) and verifying: accepted events render normally, tentative/needsAction events have crosshatch overlay, declined events are filtered out entirely.

**Acceptance Scenarios**:

1. **Given** an event the user has accepted, **When** the compact row renders, **Then** it appears with normal styling (no crosshatch)
2. **Given** an event the user hasn't responded to (tentative or needsAction), **When** the compact row renders, **Then** a crosshatch pattern (bidirectional diagonal lines at 12% alpha) overlays the row, and the title is slightly dimmed (70% alpha)
3. **Given** a tentative event in the timeline, **When** the timeline renders, **Then** the event block uses a crosshatch fill pattern (bidirectional diagonals at 35% alpha, 6px spacing) instead of the normal solid/stripe pattern
4. **Given** a declined event exists in the calendar, **When** events are fetched, **Then** the declined event is completely excluded from all views (timeline, detail area, hero selection)
5. **Given** the user's response status is determined by matching `attendee.self == true` in the Google Calendar API response, **When** no self-attendee is found (personal events), **Then** the event defaults to "accepted" status

---

### Edge Cases

- What happens when no events are loaded? The detail area shows "No upcoming events" text in the retro style, and the timeline strip is empty with only hour markers and the NOW marker visible
- What happens when events overlap (same time slot)? Overlapping events show as separate colored blocks in the timeline with diagonal hatching on the overlap region, and appear as separate rows in the detail area grouped together. When multiple accepted ongoing events have meeting links, ALL get hero cards (compact mode). If only tentative events are ongoing, the one ending soonest gets the hero card. Accepted always take priority over tentative for hero promotion
- What happens with tentative/unresponded meetings? They render with a crosshatch background overlay in both compact rows and timeline blocks. Tentative events only get hero card treatment when no accepted ongoing events with links exist. Events with `needsAction` response status are treated identically to `tentative`
- What happens with declined meetings? Declined events are completely filtered out during data fetching and never appear anywhere in the UI
- What happens when an event title is very long? Titles are truncated with ellipsis in the detail compact rows. The hero card can show more of the title (up to 2 lines) due to its larger size. Timeline blocks show no titles
- How does the layout handle the transition from today to tomorrow? A "Tomorrow" separator with darker background and bold text appears in the detail list between today's and tomorrow's events
- What happens when the user is not signed in? The sign-in screen uses the same dark CRT background with a styled "Sign in with Google" button

## Clarifications

### Session 2026-02-24

- Q: When multiple events are ongoing simultaneously, which gets the hero card? → A: Among ongoing events **with a meeting link**, the one ending soonest gets the hero card. Ongoing events without meeting links never get a hero card.
- Q: What time range should the timeline display? → A: Fixed 5-hour window with NOW at 25% width. Shows 1h15m before now and 3h45m after now. The entire scale slides as time passes (1-second update interval).
- Q: How elaborate should the flip clock animation be? → A: Classic split-flap flip animation — top half of the flap rotates down to reveal the new digit underneath, mimicking a physical departure board. Digits are tall (180px internal) to fill the column prominently.
- Q: How should the retro pixel font be sourced? → A: Use the google_fonts package with "VT323" for all retro text (compact rows, date display, clock digits, general UI text). Timeline blocks show no titles.
- Q: Should the detail area show past events? → A: No. Detail area shows only ongoing + future events. Past events are visible in the timeline strip only.
- Q: Should tomorrow's events appear on the timeline strip? → A: No. The timeline shows today's events only. Tomorrow's events appear exclusively in the detail area's scrollable list (with a "Tomorrow" separator).
- Q: Where should the exit button live in the new layout (no app bar)? → A: Bottom of the clock column, below the date with a spacer. Small exit icon, accessible but unobtrusive.
- Q: How should events without meeting links differ visually? → A: Smaller font (20px vs 24px title, 18px vs 24px time), dimmer colors (textSecondary instead of textPrimary, 60% alpha on icons/countdown), normal weight. Events with links get bold titles.
- Q: How should overlapping events be shown in the timeline? → A: Diagonal hatching (white lines at 30% opacity) drawn over the overlap region, on top of the individual event blocks.

### Session 2026-02-25

- Q: How should tentative/unresponded meetings be visually distinguished? → A: Crosshatch background overlay (bidirectional diagonal lines) in both compact event rows (12% alpha) and timeline blocks (35% alpha, 6px spacing). Title slightly dimmed at 70% alpha in compact rows.
- Q: How should hero card priority work with tentative vs accepted events? → A: Accepted ongoing events with meeting links always take priority. ALL accepted ongoing events get hero cards (dual/multi compact hero). Tentative only gets hero when no accepted are ongoing (single hero, amber border, "TENTATIVE" label).
- Q: Should `needsAction` be treated the same as tentative? → A: Yes, identical treatment. Both are "not yet accepted".
- Q: What about declined events? → A: Filtered out completely during data fetch. Never shown anywhere.
- Q: How is the user's response status determined? → A: From the Google Calendar API `attendees` array, finding the entry with `self == true` and reading its `responseStatus`. Personal events (no attendees) default to "accepted".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App MUST display a split-flap flip clock in a left column (~180px wide) spanning the full window height, showing hours and minutes with tall digits (180px internal height, FittedBox scaled). The current date MUST be displayed immediately below the clock (weekday in 24px textPrimary, date in 22px textSecondary). An exit button MUST appear at the bottom of the column. Digit transitions MUST use a split-flap flip animation (top half rotates down to reveal new digit)
- **FR-002**: App MUST display a horizontal timeline strip (~100px tall) in the top-right area with a fixed 5-hour sliding window. The NOW marker MUST be fixed at 25% of the timeline width (1h15m past, 3h45m future). Hour markers MUST show HH:00 format. The timeline MUST show today's events only (tomorrow's events appear in the detail area only). The timeline MUST update every 1 second, sliding smoothly as time passes
- **FR-003**: Timeline event blocks MUST use alternating visual patterns (solid fill for even-indexed accepted events, horizontal stripe fill for odd-indexed accepted events, crosshatch fill for tentative/needsAction events) with colored borders, color-coded by event status (ongoing=blue, upcoming=amber, normal=green). No titles in timeline blocks. Overlapping events MUST show diagonal hatching over the overlap region. All text MUST use "VT323" font sourced via google_fonts
- **FR-004**: The NOW marker on the timeline MUST display contextual countdown text: "ends Xm" during ongoing events or "next Xm" when the next event is within 60 minutes
- **FR-005**: App MUST display a scrollable detail area below the timeline, showing hero card(s) for ongoing events **only if they have a meeting link**. Hero priority: all accepted ongoing events with links get hero cards (compact mode when multiple). Tentative events only get a hero card when no accepted ones are ongoing (single, amber border). Compact rows for all other events
- **FR-006**: The hero card MUST show: event title, time range, progress bar with percentage, and a JOIN button (red with meeting link). Only events with meeting links get hero card treatment. Tentative hero cards MUST show an amber border and "TENTATIVE" label. When multiple hero cards are shown, they MUST use compact mode (24px title, single-line, reduced padding)
- **FR-007**: Compact event rows MUST show: status icon (videocam for ongoing, notifications_active for upcoming, event for normal), event title, time range, and countdown to start. Rows MUST have a 3px colored left border matching status. Rows MUST use alternating group backgrounds (dark slate / base background) with separator lines between time groups. Events with meeting links MUST display in 24px bold; events without MUST display in 20px normal with dimmer colors (60% alpha). Tentative/needsAction events MUST have a crosshatch overlay (bidirectional diagonal lines at 12% alpha) and slightly dimmed title (70% alpha). Time range, countdown, and join icon columns MUST be fixed-width and right-aligned for consistent alignment. Detail area MUST only display ongoing and future events
- **FR-015**: App MUST track the user's RSVP response status per event via the `attendees[].self == true` entry from the Google Calendar API. Events with `responseStatus == 'declined'` MUST be completely filtered out. Events with `tentative` or `needsAction` MUST be visually distinguished with crosshatch patterns. Personal events (no attendees) default to accepted
- **FR-008**: App MUST use the dark CRT color palette (background #1a1a2e, timelineBg #0d0d1a, ongoing #4fc3f7, upcoming #ffb74d, normal #66bb6a, clock flaps #2d2d44, text #e0e0e0, textSecondary #b0b0b0, joinActive #ef5350)
- **FR-009**: All existing functionality MUST be preserved: OAuth authentication, token storage, event fetching/polling, error handling via SnackBars, meeting link opening
- **FR-010**: The flip clock MUST update every second (consistent with existing clock behavior)
- **FR-011**: Timeline and detail area MUST update per-second for countdowns and progress, and every 60 seconds for event data (consistent with existing polling)
- **FR-012**: The detail area MUST be scrollable when events exceed the visible space
- **FR-013**: App MUST include a time simulation mode with controls (+/-1h, +/-10m, reset) displayed in the clock column's empty space, allowing testing at different simulated times
- **FR-014**: Window default size MUST be 1436x462 pixels with no decorations, matching the user's portrait monitor allocation

### Key Entities

- **Clock Column**: Left-side panel (~180px) containing the tall flip clock digits, date display immediately below, time simulation controls in the middle space, and exit button at the bottom
- **Timeline Strip**: Horizontal bar with 5-hour sliding window, NOW fixed at 25% width, showing proportionally-spaced event blocks with alternating fill patterns (no titles), overlap hatching, hour markers, and NOW marker with countdown
- **Hero Card**: Prominent display card for ongoing events **with a meeting link**, showing full details, progress bar, and JOIN action. Supports compact mode for dual/multi hero display. Tentative hero cards have amber border and "TENTATIVE" label. Accepted events have priority over tentative for hero promotion
- **Compact Event Row**: Card-like event entry with colored left border, status icon, event title, time range, and countdown. Visual weight varies based on meeting link presence (larger/bold vs smaller/dim). Tentative events get crosshatch overlay
- **ResponseStatus**: Enum (`accepted`, `tentative`, `needsAction`, `declined`) derived from the Google Calendar API `attendees[].self == true` entry. Drives hero priority, visual distinction (crosshatch), and filtering (declined hidden)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: User can identify the current time within 1 second of glancing at the app (flip clock is large with tall digits and immediately readable)
- **SC-002**: User can identify their current or next meeting within 2 seconds of glancing (hero card and timeline provide instant context)
- **SC-003**: All 9+ events for a typical workday are accessible via scrolling in the detail area without losing sight of the timeline or clock
- **SC-004**: Event status changes (normal → upcoming → ongoing) are visually distinct through color transitions in both the timeline and detail area, with clear differentiation between meeting-link and no-link events
- **SC-005**: All existing tests continue to pass after the redesign (model tests, service tests, widget tests)
- **SC-006**: The app renders correctly at the fixed 1436x462 window size with no overflow or clipping
- **SC-007**: Timeline maintains temporal context with NOW always visible at 25% width, past events smoothly scrolling off to the left
