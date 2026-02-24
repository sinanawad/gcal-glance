import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:gcal_glance/widgets/clock_widget.dart';
import 'package:gcal_glance/widgets/event_list.dart';

class CalendarHomePage extends StatefulWidget {
  final GoogleCalendarService calendarService;

  const CalendarHomePage({super.key, required this.calendarService});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  bool _isLoggedIn = false;
  List<CalendarEvent> _events = [];
  Timer? _dataFetchTimer;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _dataFetchTimer?.cancel();
    _uiUpdateTimer?.cancel();
    widget.calendarService.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    final client = await widget.calendarService.getAuthenticatedClient();
    if (client != null) {
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
                debugPrint('xdg-open exited with code $code');
              }
            });
          }).catchError((Object e) {
            debugPrint('Failed to open browser: $e');
          });
        },
      );
      if (client != null) {
        setState(() {
          _isLoggedIn = true;
        });
        _startPolling();
      }
    } catch (e) {
      debugPrint('signIn error: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await widget.calendarService.signOut();
    setState(() {
      _isLoggedIn = false;
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
    if (httpClient == null) return;

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
        });
      }
    } catch (e) {
      // US3 will add proper error handling with SnackBars
      if (mounted) {
        _handleSignOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Center(child: ClockWidget(now: now)),
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
        child: _isLoggedIn ? _buildEventList(now) : _buildLoginScreen(),
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

  Widget _buildEventList(DateTime now) {
    if (_events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return EventList(events: _events, now: now);
  }
}
