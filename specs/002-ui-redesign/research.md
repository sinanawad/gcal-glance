# Research: Retro CRT UI Redesign

**Branch**: `002-ui-redesign` | **Date**: 2026-02-24

## R1: Split-Flap Flip Animation in Flutter

**Decision**: Use `AnimationController` with `Transform` (3D perspective rotation around X-axis) inside a `StatefulWidget` (FlipDigit). Each digit is an independent animation.

**Rationale**: Flutter's `Transform` widget with `Matrix4.rotationX()` provides hardware-accelerated 3D rotation. Wrapping each digit in its own StatefulWidget with `SingleTickerProviderStateMixin` keeps animation state local (constitution principle II compliance). The animation shows the top half flipping down: old digit on front, new digit revealed behind.

**Implementation approach**:
- FlipDigit holds current and previous digit values
- On value change, trigger a ~300ms flip animation
- Top half: clips to upper 50%, rotates from 0 to π/2 radians (old digit disappears)
- Bottom half: clips to lower 50%, rotates from -π/2 to 0 (new digit appears)
- Dark slate flap background (#2d2d44) with rounded corners and subtle shadow
- Colon separator between hours and minutes is static (no animation)

**Alternatives considered**:
- `flip_panel` package: Abandoned, last updated 2021, not null-safe
- `AnimatedSwitcher` with custom transition: Simpler but lacks the authentic split-flap illusion (no top/bottom half split)
- `CustomPainter`: More control but significantly more code for the same visual result

## R2: Google Fonts Package (Press Start 2P + VT323)

**Decision**: Add `google_fonts: ^6.0.0` to pubspec.yaml. Use `GoogleFonts.pressStart2P()` for timeline block titles and `GoogleFonts.vt323()` for other retro text.

**Rationale**: The google_fonts package automatically downloads and caches fonts at runtime. Both Press Start 2P (chunky pixel font) and VT323 (clean VT terminal font) are free under OFL license. No manual asset bundling needed.

**Implementation approach**:
- Import `package:google_fonts/google_fonts.dart`
- Use `GoogleFonts.pressStart2P(fontSize: 8, color: ...)` for timeline block text
- Use `GoogleFonts.vt323(fontSize: 16, color: ...)` for compact rows, date, general UI
- Flip clock digits use a large monospace font — VT323 at ~48px or larger for readability
- Fonts are cached after first download; subsequent launches use cached versions
- For offline resilience: bundle fonts as assets as a fallback (optional, low priority)

**Alternatives considered**:
- Manual .ttf bundling: More work to set up, but guarantees offline availability. Could add later if network font loading is unreliable.
- System monospace: No retro feel. Rejected.

## R3: Timeline Strip with CustomPainter

**Decision**: Use `CustomPainter` for the timeline strip to render hour markers, event blocks with text, NOW marker, and auto-scroll behavior in a single efficient paint pass.

**Rationale**: The timeline is a dense, custom visualization that doesn't map well to standard Flutter widgets. A CustomPainter gives pixel-level control over positioning, avoids nested widget trees, and paints in a single pass (constitution principle VI: efficient rendering). The painter receives the event list and current time, computing all positions mathematically.

**Implementation approach**:
- `TimelineStrip` is a StatelessWidget wrapping a `CustomPaint`
- The painter computes visible time range: from the most-recently-ended event's start to the last today event's end (with padding)
- Each event block: filled rect with status color, clipped text overlay (Press Start 2P)
- Hour markers: thin vertical lines with hour labels above
- NOW marker: brighter vertical line + triangle pointer + countdown text
- Overlapping events: stack vertically (split the strip height)
- Auto-scroll: when the visible range shifts (meeting ends), animate the range via a parent `AnimatedValue` or `Tween`
- Consumes `ValueNotifier<DateTime>` for per-second NOW marker updates

**Alternatives considered**:
- Row of Widgets: Too many nested widgets for 9+ events with proportional sizing. Layout overhead exceeds CustomPainter.
- `CustomScrollView` with `SliverList`: Overkill for a fixed-height strip with no user scrolling.

## R4: Material 3 Dark CRT Theme

**Decision**: Create a custom `ThemeData` using `ColorScheme.fromSeed()` with dark brightness and override specific colors. Keep `useMaterial3: true`.

**Rationale**: Material 3 supports fully custom dark themes. By using `ColorScheme.dark()` with our CRT palette overrides, we get proper SnackBar, button, and scaffold theming for free while maintaining the retro aesthetic. The constitution requires Material 3 — this approach satisfies it.

**Implementation approach**:
- New file `lib/config/crt_theme.dart` with:
  - Color constants: background, ongoing, upcoming, normal, clockFlap, text, etc.
  - `CrtTheme.themeData()` factory returning a `ThemeData` with:
    - `colorScheme: ColorScheme.dark(...)` with CRT overrides
    - `scaffoldBackgroundColor: Color(0xFF1a1a2e)`
    - `snackBarTheme` for dark-themed error messages
    - `elevatedButtonTheme` for styled buttons
- `main.dart` uses `CrtTheme.themeData()` instead of the current deepPurple seed

**Alternatives considered**:
- Abandon Material 3 entirely: Constitution violation. Rejected.
- ThemeExtension for CRT colors: More idiomatic for custom semantics but adds complexity for a single-user app with a fixed palette. Rejected in favor of simple constants file.

## R5: Timeline Auto-Scroll Behavior

**Decision**: Compute the visible time range dynamically. When the range changes (meeting ends), use `AnimatedContainer` or a `Tween<double>` to smoothly transition the timeline's viewport offset.

**Rationale**: The timeline needs to show one past event + all future events for today. As meetings end, the "viewport start" shifts forward. A smooth animation (500ms ease-in-out) gives visual continuity rather than a jarring jump.

**Implementation approach**:
- Compute `viewportStart`: start time of the most recently ended event (or first event if none ended)
- Compute `viewportEnd`: end time of the last today event (with 30-min padding)
- When `viewportStart` changes (checked on each per-second tick), animate the transition
- The CustomPainter receives the current viewport range and maps all event positions to pixel coordinates
- Edge case: no events → show empty timeline with hour markers for current ±4 hours

**Alternatives considered**:
- No animation (instant jump): Functional but disorienting. Rejected.
- User-scrollable timeline: Adds interaction complexity for a glance-only widget. Rejected.
