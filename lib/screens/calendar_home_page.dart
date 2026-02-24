import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:gcal_glance/widgets/clock_column.dart';
import 'package:gcal_glance/widgets/detail_area.dart';
import 'package:gcal_glance/widgets/timeline_strip.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _checkCurrentUser();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = _simulatedNow;
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
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyS) {
      setState(() => _showSimControls = !_showSimControls);
      return KeyEventResult.handled;
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
      _dataFetchTimer?.cancel();
    });
  }

  void _startPolling() {
    _updateEvents();
    _dataFetchTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateEvents();
    });
  }

  Future<void> _updateEvents() async {
    final httpClient = await widget.calendarService.getAuthenticatedClient();
    if (httpClient == null || !mounted) return;

    try {
      final apiEvents = await widget.calendarService.fetchEvents(httpClient);

      final newEvents = apiEvents
          .where(
            (e) =>
                e.start?.dateTime != null &&
                e.end?.dateTime != null &&
                e.status != 'cancelled',
          )
          .map((e) => CalendarEvent.fromGoogleEvent(e))
          .toList();

      if (mounted) {
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

  /// Select the hero event: among ongoing events with a meeting link,
  /// the one ending soonest.
  CalendarEvent? _selectHeroEvent(DateTime now) {
    final ongoingEvents = _events
        .where((e) =>
            e.status(now) == EventStatus.ongoing && e.meetingLink != null)
        .toList();
    if (ongoingEvents.isEmpty) return null;
    ongoingEvents.sort((a, b) => a.endTime.compareTo(b.endTime));
    return ongoingEvents.first;
  }

  /// Find the next future event with a meeting link.
  CalendarEvent? _nextMeetingWithLink(DateTime now) {
    final future = _events
        .where((e) => e.startTime.isAfter(now) && e.meetingLink != null)
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
        if (next == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'NO MEETINGS',
              textAlign: TextAlign.center,
              style: GoogleFonts.vt323(
                fontSize: 18,
                color: CrtTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          );
        }

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
        final Color accentColor;
        switch (status) {
          case EventStatus.ongoing:
            accentColor = CrtTheme.ongoing;
          case EventStatus.upcoming:
            accentColor = CrtTheme.upcoming;
          case EventStatus.normal:
            accentColor = CrtTheme.normal;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        body: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF5a5a9e),
              width: 2,
            ),
          ),
          child: _isLoggedIn ? _buildMainLayout() : _buildLoginScreen(),
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
          ClockColumn(now: _now),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_events.isEmpty && _hasCompletedFirstLoad) {
      return Row(
        children: [
          ClockColumn(now: _now),
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
        final heroEvent = _selectHeroEvent(now);
        final todayEvents = _todayEvents(now);
        final detailEvents = _detailEvents(now);

        return Row(
          children: [
            // Left: Clock column (180px)
            ClockColumn(now: _now, bottomContent: _buildMeetingCountdown()),
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
                      heroEvent: heroEvent,
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
