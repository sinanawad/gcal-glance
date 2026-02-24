import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:gcal_glance/widgets/clock_widget.dart';
import 'package:gcal_glance/widgets/event_list.dart';
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
  bool _isLoading = false;
  bool _hasCompletedFirstLoad = false;
  List<CalendarEvent> _events = [];
  Timer? _dataFetchTimer;

  final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _dataFetchTimer?.cancel();
    _clockTimer?.cancel();
    _now.dispose();
    widget.calendarService.dispose();
    super.dispose();
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
      _isLoading = false;
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

    setState(() {
      _isLoading = true;
    });

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
          _isLoading = false;
          _hasCompletedFirstLoad = true;
        });
      }
    } on auth.AccessDeniedException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasCompletedFirstLoad = true;
        });
        _showErrorSnackBar('Session expired. Please sign in again.');
        _handleSignOut();
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: ClockWidget(nowNotifier: _now)),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                if (Theme.of(context).platform == TargetPlatform.linux) {
                  SystemNavigator.pop();
                } else {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Exit',
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[700],
        child: _isLoggedIn ? _buildEventList() : _buildLoginScreen(),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: _handleSignIn,
        child: const Text('Sign in with Google'),
      ),
    );
  }

  Widget _buildEventList() {
    if (_events.isEmpty && !_hasCompletedFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No upcoming events',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
              onPressed: _isLoading ? null : _updateEvents,
              tooltip: 'Refresh',
            ),
          ],
        ),
      );
    }

    return EventList(events: _events, nowNotifier: _now);
  }
}
