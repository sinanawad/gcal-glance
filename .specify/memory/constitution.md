<!--
  Sync Impact Report
  ===================
  Version change: N/A → 1.0.0 (initial ratification)
  Modified principles: N/A (first version)
  Added sections:
    - Core Principles (7 principles)
    - Security Requirements
    - UI & UX Standards
    - Governance
  Removed sections: N/A
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ no changes needed (Constitution Check section is generic)
    - .specify/templates/spec-template.md ✅ no changes needed (user stories structure compatible)
    - .specify/templates/tasks-template.md ✅ no changes needed (phase structure compatible)
    - .specify/templates/checklist-template.md ✅ no changes needed (generic template)
    - .specify/templates/agent-file-template.md ✅ no changes needed (generic template)
  Follow-up TODOs: None
-->

# gcal-glance Constitution

## Core Principles

### I. Widget Composition & Separation

All Flutter UI MUST follow a clear separation between widgets, state, and
services. Each concern lives in its own file once it exceeds ~100 lines:

- **Models** in `lib/models/` — plain Dart classes, no Flutter imports
- **Services** in `lib/services/` — API calls, auth, persistence
- **Widgets** in `lib/widgets/` — reusable UI components
- **Screens** in `lib/screens/` — full-page compositions

Rationale: Monolithic files become untestable and unreadable. Separation
enables widget testing, service mocking, and parallel development.

### II. Stateless by Default

Widgets MUST be `StatelessWidget` unless they own local ephemeral state
(animations, form fields, scroll position). App-level state (auth status,
event data, polling timers) MUST NOT live inside widget `State` objects.
Use a state management approach (Provider, Riverpod, or similar) when state
is shared across widgets.

Rationale: Pushing state up and out of widgets makes the UI predictable,
testable, and prevents rebuild cascades from `setState(() {})`.

### III. Immutable Models

All data model classes MUST be immutable. Fields MUST be `final`. Status
or derived values that change over time MUST be computed at read time
(getter or method), never cached at construction time.

Rationale: Mutable models cause stale-state bugs. A `CalendarEvent` whose
status is computed once at creation and never updated is a concrete example
of this failure mode.

### IV. Secure Credential Handling

- OAuth tokens and credential files MUST NEVER be committed to version
  control. The `.gitignore` MUST include `token.json` and
  `go-gcal-cli-credentials.json`.
- Credential file paths MUST be resolved relative to a well-known location
  (e.g., app data directory via `path_provider`), NOT relative to
  `Directory.current.path`.
- HTTP clients MUST be explicitly closed when no longer needed to prevent
  resource leaks.
- Refreshed tokens MUST be persisted so that subsequent app launches do not
  require re-authentication.

Rationale: Relying on the working directory for secrets is fragile and
error-prone. Leaked clients exhaust OS socket pools.

### V. Defensive API Integration

- All Google API responses MUST be validated before use. Null fields MUST
  be handled gracefully (skip the record or show a placeholder), never
  force-unwrapped without a preceding null check.
- Auth failures (`AccessDeniedException`) MUST surface user-visible
  feedback before signing out.
- Network errors MUST be caught and presented to the user with actionable
  guidance (retry, check connection).

Rationale: Silent failures leave users staring at a spinner with no
recourse.

### VI. Efficient Rendering

- Periodic UI rebuilds MUST be scoped to the smallest subtree possible.
  Full-scaffold `setState` on a 1-second timer is prohibited.
- Use `ValueListenableBuilder`, `StreamBuilder`, or equivalent to rebuild
  only the widgets that depend on changing data (clock, countdowns).
- List item builders MUST NOT perform O(n) or worse computations per item.
  Precompute grouping data before the build pass.

Rationale: Unnecessary rebuilds drain battery on always-on dashboard
displays — the primary use case for this app.

### VII. Testability

- Every service class MUST accept its dependencies via constructor
  injection (HTTP clients, file system access) so tests can provide mocks.
- Widget tests MUST be able to run without network access or real OAuth
  credentials.
- The default test file MUST test the actual application, not Flutter's
  counter template.

Rationale: Untestable code is unverifiable code. Constructor injection is
the minimum bar for testability in Dart.

## Security Requirements

- All external URLs opened via `url_launcher` MUST be validated against an
  allowlist of schemes (`https`, `mailto`) before launching.
- The app MUST request only the minimum OAuth scopes required
  (`calendar.readonly` for read-only access).
- Token storage MUST use platform-appropriate secure storage
  (`flutter_secure_storage` or OS keychain) for production builds.
  Plain-text `token.json` is acceptable only during local development.

## UI & UX Standards

- Material 3 (`useMaterial3: true`) is the required design system.
- Color semantics MUST be consistent: blue for ongoing events, orange for
  upcoming (within 10 minutes), neutral for future events.
- All interactive elements MUST have accessible labels (`semanticsLabel`
  or `Tooltip`).
- Loading, empty, and error states MUST be visually distinct. A spinner
  MUST NOT be used to represent "no events."
- Text contrast MUST meet WCAG AA (4.5:1 for normal text, 3:1 for large).
- `DateTime.now()` MUST be called once per build frame and reused across
  all widgets in that frame to avoid time-of-check inconsistencies.

## Governance

- This constitution supersedes ad-hoc patterns found in existing code.
  New code MUST comply; existing code SHOULD be migrated incrementally
  when touched.
- Amendments require: (1) a description of the change, (2) rationale,
  (3) version bump per semver, and (4) update to dependent templates if
  principle-driven sections change.
- All pull requests MUST be verified against these principles before merge.
- Use `CLAUDE.md` at the repository root for runtime development guidance
  (build commands, project structure, quick-start).

**Version**: 1.0.0 | **Ratified**: 2026-02-22 | **Last Amended**: 2026-02-22
