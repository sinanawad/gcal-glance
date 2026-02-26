import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/models/calendar_info.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:gcal_glance/widgets/calendar_picker.dart';
import 'package:gcal_glance/widgets/clock_column.dart';
import 'package:gcal_glance/widgets/detail_area.dart';
import 'package:gcal_glance/widgets/timeline_strip.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class CalendarHomePage extends StatefulWidget {
  final GoogleCalendarService calendarService;

  const CalendarHomePage({super.key, required this.calendarService});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  bool _isLoggedIn = false;
  bool _hasCompletedFirstLoad = false;
  List<CalendarEvent> _events = [];
  Timer? _dataFetchTimer;

  final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());
  Timer? _clockTimer;

  /// Time simulation: offset from real time. Zero means real time.
  Duration _timeOffset = Duration.zero;
  bool _showSimControls = false;
  bool _showCalendarPicker = false;
  List<CalendarInfo> _allCalendars = [];
  Set<String> _selectedCalendarIds = {};
  bool _isMuted = false;
  final Set<String> _notifiedEventKeys = {};
  late final FocusNode _focusNode;

  DateTime get _simulatedNow => DateTime.now().add(_timeOffset);

  void _adjustTime(Duration delta) {
    setState(() {
      _timeOffset += delta;
      _now.value = _simulatedNow;
    });
  }

  void _resetTime() {
    setState(() {
      _timeOffset = Duration.zero;
      _now.value = DateTime.now();
    });
  }

  /// Unique key for deduplicating meeting-start notifications.
  String _eventKey(CalendarEvent e) =>
      '${e.calendarId}:${e.summary}:${e.startTime.toIso8601String()}';

  void _checkMeetingStarted() {
    if (_isMuted || _events.isEmpty) return;
    final now = _simulatedNow;
    for (final event in _events) {
      if (!event.isPrimary || event.meetingLink == null) continue;
      if (event.status(now) != EventStatus.ongoing) continue;
      final key = _eventKey(event);
      if (_notifiedEventKeys.contains(key)) continue;
      _notifiedEventKeys.add(key);
      _playChirp();
      break; // one chirp per tick is enough
    }
  }

  void _playChirp() {
    // Fire-and-forget; ignore errors if sound system unavailable.
    Process.run('paplay', [
      '/usr/share/sounds/freedesktop/stereo/camera-shutter.oga',
    ]);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _checkCurrentUser();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = _simulatedNow;
      _checkMeetingStarted();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _dataFetchTimer?.cancel();
    _clockTimer?.cancel();
    _now.dispose();
    widget.calendarService.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() => _showSimControls = !_showSimControls);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyC) {
        setState(() => _showCalendarPicker = !_showCalendarPicker);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        setState(() => _isMuted = !_isMuted);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          _showCalendarPicker) {
        setState(() => _showCalendarPicker = false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _showErrorSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: 400,
        action: actionLabel != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {})
            : null,
      ),
    );
  }

  Future<void> _checkCurrentUser() async {
    final client = await widget.calendarService.getAuthenticatedClient();
    if (client != null && mounted) {
      setState(() {
        _isLoggedIn = true;
      });
      _startPolling();
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final client = await widget.calendarService.signIn(
        (url) {
          Process.start('xdg-open', [url]).then((process) {
            process.exitCode.then((code) {
              if (code != 0) {
                _showErrorSnackBar('Failed to open browser.');
              }
            });
          }).catchError((Object e) {
            _showErrorSnackBar('Failed to open browser.');
          });
        },
      );
      if (client != null) {
        setState(() {
          _isLoggedIn = true;
        });
        _startPolling();
      }
    } catch (_) {
      _showErrorSnackBar('Sign-in was cancelled. Please try again.');
    }
  }

  Future<void> _handleSignOut() async {
    await widget.calendarService.signOut();
    setState(() {
      _isLoggedIn = false;
      _hasCompletedFirstLoad = false;
      _events = [];
      _allCalendars = [];
      _selectedCalendarIds = {};
      _showCalendarPicker = false;
      _dataFetchTimer?.cancel();
    });
  }

  void _startPolling() {
    _loadCalendarList();
    _dataFetchTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateEvents();
    });
  }

  Future<void> _loadCalendarList() async {
    final httpClient = await widget.calendarService.getAuthenticatedClient();
    if (httpClient == null || !mounted) return;

    try {
      final entries =
          await widget.calendarService.fetchCalendarList(httpClient);
      final calendars = entries
          .map((e) => CalendarInfo(
                id: e.id!,
                summary: e.summaryOverride ?? e.summary ?? 'Untitled',
                isPrimary: e.primary == true,
                backgroundColor: e.backgroundColor,
                foregroundColor: e.foregroundColor,
              ))
          .toList();

      final primaryId =
          calendars.where((c) => c.isPrimary).map((c) => c.id).firstOrNull;

      // Load persisted selection, or default to primary only.
      // Intersect against current calendar list to discard stale IDs.
      final validIds = calendars.map((c) => c.id).toSet();
      final saved = await widget.calendarService.loadSelectedCalendars();
      final selectedIds = saved != null
          ? saved.toSet().intersection(validIds)
          : {?primaryId};

      // Ensure primary is always selected.
      if (primaryId != null) {
        selectedIds.add(primaryId);
      }

      // Persist the cleaned-up selection if stale IDs were removed.
      if (saved != null && selectedIds.length != saved.length) {
        widget.calendarService
            .saveSelectedCalendars(selectedIds.toList());
      }

      if (mounted) {
        setState(() {
          _allCalendars = calendars;
          _selectedCalendarIds = selectedIds;
        });
        _updateEvents();
      }
    } catch (_) {
      // Calendar list fetch failed; fall back to primary-only fetch.
      _updateEvents();
    }
  }

  void _handleCalendarToggle(String calendarId) {
    setState(() {
      if (_selectedCalendarIds.contains(calendarId)) {
        _selectedCalendarIds.remove(calendarId);
      } else {
        _selectedCalendarIds.add(calendarId);
      }
    });
    widget.calendarService
        .saveSelectedCalendars(_selectedCalendarIds.toList());
    _updateEvents();
  }

  Future<void> _updateEvents() async {
    final httpClient = await widget.calendarService.getAuthenticatedClient();
    if (httpClient == null || !mounted) return;

    try {
      // Determine which calendars to fetch.
      final calendarIds = _selectedCalendarIds.isNotEmpty
          ? _selectedCalendarIds.toList()
          : ['primary'];

      // Build a lookup of calendar metadata.
      final calendarMap = {for (final c in _allCalendars) c.id: c};

      // Parallel fetch across all selected calendars.
      // Individual failures return empty lists so one bad calendar
      // doesn't break the entire refresh.
      final results = await Future.wait(
        calendarIds.map((id) => widget.calendarService
            .fetchEvents(httpClient, calendarId: id)
            .catchError((_) => <gcal.Event>[])),
      );

      final newEvents = <CalendarEvent>[];
      for (var i = 0; i < calendarIds.length; i++) {
        final calId = calendarIds[i];
        final cal = calendarMap[calId];
        final isPrimary = cal?.isPrimary ?? (calId == 'primary');
        final colorValue = CalendarEvent.parseHexColor(cal?.backgroundColor);

        for (final e in results[i]) {
          if (e.start?.dateTime == null ||
              e.end?.dateTime == null ||
              e.status == 'cancelled') {
            continue;
          }
          final event = CalendarEvent.fromGoogleEvent(
            e,
            calendarId: calId,
            isPrimary: isPrimary,
            calendarColorValue: colorValue,
          );
          if (event.responseStatus != ResponseStatus.declined) {
            newEvents.add(event);
          }
        }
      }

      newEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      if (mounted) {
        // On first load, pre-seed notified set with already-ongoing
        // meetings so we don't chirp for meetings that started before
        // the app launched.
        if (!_hasCompletedFirstLoad) {
          final now = _simulatedNow;
          for (final event in newEvents) {
            if (event.isPrimary &&
                event.meetingLink != null &&
                event.status(now) == EventStatus.ongoing) {
              _notifiedEventKeys.add(_eventKey(event));
            }
          }
        }
        setState(() {
          _events = newEvents;
          _hasCompletedFirstLoad = true;
        });
      }
    } on auth.AccessDeniedException {
      if (mounted) {
        setState(() {
          _hasCompletedFirstLoad = true;
        });
        _showErrorSnackBar('Session expired. Please sign in again.');
        _handleSignOut();
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _hasCompletedFirstLoad = true;
        });
        _showErrorSnackBar(
          'Could not refresh events. Check your connection.',
          actionLabel: 'Retry',
          onAction: _updateEvents,
        );
      }
    } on http.ClientException {
      if (mounted) {
        setState(() {
          _hasCompletedFirstLoad = true;
        });
        _showErrorSnackBar(
          'Could not refresh events. Check your connection.',
          actionLabel: 'Retry',
          onAction: _updateEvents,
        );
      }
    }
  }

  /// Select hero events: ongoing primary events with meeting links.
  /// Accepted events take priority; all accepted are shown (dual hero).
  /// Tentative only promoted if no accepted hero exists (single).
  List<CalendarEvent> _selectHeroEvents(DateTime now) {
    final ongoingWithLink = _events
        .where((e) =>
            e.isPrimary &&
            e.status(now) == EventStatus.ongoing &&
            e.meetingLink != null)
        .toList();
    if (ongoingWithLink.isEmpty) return [];

    final accepted = ongoingWithLink.where((e) => e.isAccepted).toList();
    final tentative = ongoingWithLink.where((e) => e.isTentative).toList();

    if (accepted.isNotEmpty) {
      accepted.sort((a, b) => a.endTime.compareTo(b.endTime));
      return accepted;
    }
    if (tentative.isNotEmpty) {
      tentative.sort((a, b) => a.endTime.compareTo(b.endTime));
      return [tentative.first];
    }
    return [];
  }

  /// Find the next future primary event with a meeting link.
  CalendarEvent? _nextMeetingWithLink(DateTime now) {
    final future = _events
        .where(
            (e) => e.isPrimary && e.startTime.isAfter(now) && e.meetingLink != null)
        .toList();
    if (future.isEmpty) return null;
    future.sort((a, b) => a.startTime.compareTo(b.startTime));
    return future.first;
  }

  Widget _buildMeetingCountdown() {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _now,
      builder: (context, now, _) {
        final next = _nextMeetingWithLink(now);

        final Color borderColor;
        final Widget content;

        if (next == null) {
          borderColor = CrtTheme.textSecondary.withValues(alpha: 0.3);
          content = Center(
            child: Text(
              'NO MEETINGS',
              textAlign: TextAlign.center,
              style: GoogleFonts.vt323(
                fontSize: 18,
                color: CrtTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          );
        } else {
          final countdown = next.startTime.difference(now);
          final hours = countdown.inHours;
          final minutes = countdown.inMinutes.remainder(60);

          final String timeText;
          if (hours > 0) {
            timeText = '${hours}h ${minutes}m';
          } else {
            timeText = '${minutes}m';
          }

          final status = next.status(now);
          switch (status) {
            case EventStatus.ongoing:
              borderColor = CrtTheme.ongoing.withValues(alpha: 0.5);
            case EventStatus.upcoming:
              borderColor = CrtTheme.upcoming.withValues(alpha: 0.5);
            case EventStatus.normal:
              borderColor = CrtTheme.normal.withValues(alpha: 0.5);
          }

          final accentColor = status == EventStatus.ongoing
              ? CrtTheme.ongoing
              : status == EventStatus.upcoming
                  ? CrtTheme.upcoming
                  : CrtTheme.normal;

          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 28, color: accentColor),
              const SizedBox(height: 4),
              Text(
                timeText,
                style: GoogleFonts.vt323(
                  fontSize: 36,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                next.summary,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.vt323(
                  fontSize: 16,
                  color: CrtTheme.textSecondary,
                ),
              ),
            ],
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 200,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'NEXT UP',
                  style: GoogleFonts.vt323(
                    fontSize: 16,
                    color: CrtTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Filter events for today's timeline.
  List<CalendarEvent> _todayEvents(DateTime now) {
    return _events
        .where((e) =>
            e.startTime.year == now.year &&
            e.startTime.month == now.month &&
            e.startTime.day == now.day)
        .toList();
  }

  /// Filter events for detail area: ongoing + future only (no past).
  List<CalendarEvent> _detailEvents(DateTime now) {
    return _events
        .where((e) =>
            e.status(now) == EventStatus.ongoing ||
            e.startTime.isAfter(now))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF5a5a9e),
                  width: 2,
                ),
              ),
              child: _isLoggedIn ? _buildMainLayout() : _buildLoginScreen(),
            ),
            if (_showCalendarPicker && _allCalendars.isNotEmpty)
              CalendarPicker(
                calendars: _allCalendars,
                selectedIds: _selectedCalendarIds,
                onToggle: _handleCalendarToggle,
                onClose: () =>
                    setState(() => _showCalendarPicker = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: _handleSignIn,
        child: Text(
          'Sign in with Google',
          style: GoogleFonts.vt323(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildTimeControls() {
    final isSimulating = _timeOffset != Duration.zero;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSimulating)
          Text(
            'SIM',
            style: GoogleFonts.vt323(
              fontSize: 16,
              color: CrtTheme.upcoming,
            ),
          ),
        const SizedBox(height: 4),
        // +/- hours
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeButton('-1h', () => _adjustTime(const Duration(hours: -1))),
            const SizedBox(width: 4),
            _timeButton('+1h', () => _adjustTime(const Duration(hours: 1))),
          ],
        ),
        const SizedBox(height: 2),
        // +/- 10 minutes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeButton('-10m', () => _adjustTime(const Duration(minutes: -10))),
            const SizedBox(width: 4),
            _timeButton('+10m', () => _adjustTime(const Duration(minutes: 10))),
          ],
        ),
        const SizedBox(height: 4),
        if (isSimulating)
          GestureDetector(
            onTap: _resetTime,
            child: Text(
              'RESET',
              style: GoogleFonts.vt323(
                fontSize: 14,
                color: CrtTheme.joinActive,
              ),
            ),
          ),
      ],
    );
  }

  Widget _timeButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: CrtTheme.textSecondary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.vt323(
            fontSize: 14,
            color: CrtTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMainLayout() {
    if (_events.isEmpty && !_hasCompletedFirstLoad) {
      return Row(
        children: [
          ClockColumn(
              now: _now,
              isMuted: _isMuted,
              onToggleMute: () => setState(() => _isMuted = !_isMuted),
            ),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_events.isEmpty && _hasCompletedFirstLoad) {
      return Row(
        children: [
          ClockColumn(
              now: _now,
              isMuted: _isMuted,
              onToggleMute: () => setState(() => _isMuted = !_isMuted),
            ),
          Expanded(
            child: Center(
              child: Text(
                'No upcoming events',
                style: GoogleFonts.vt323(
                  color: CrtTheme.textSecondary,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: _now,
      builder: (context, now, _) {
        final heroEvents = _selectHeroEvents(now);
        final todayEvents = _todayEvents(now);
        final detailEvents = _detailEvents(now);

        return Row(
          children: [
            // Left: Clock column (180px)
            ClockColumn(
              now: _now,
              bottomContent: _buildMeetingCountdown(),
              isMuted: _isMuted,
              onToggleMute: () => setState(() => _isMuted = !_isMuted),
            ),
            // Right: Timeline strip + detail area
            Expanded(
              child: Column(
                children: [
                  // Top spacer to align with clock column padding
                  Container(height: 12, color: CrtTheme.background),
                  // Timeline strip + time sim controls (press S to toggle)
                  Row(
                    children: [
                      Expanded(
                        child: TimelineStrip(events: todayEvents, now: _now),
                      ),
                      if (_showSimControls) _buildTimeControls(),
                    ],
                  ),
                  // Detail area (Expanded, scrollable)
                  Expanded(
                    child: DetailArea(
                      events: detailEvents,
                      heroEvents: heroEvents,
                      now: _now,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
