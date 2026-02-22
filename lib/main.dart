import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gcal_app/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gcal app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalendarHomePage(),
    );
  }
}

// Represents the status of a calendar event
enum EventStatus { ongoing, upcoming, normal }

// Model for a calendar event
class CalendarEvent {
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final String? meetingLink;
  final EventStatus status;

  CalendarEvent({
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.meetingLink,
  }) : status = _calculateStatus(startTime, endTime);

  factory CalendarEvent.fromGoogleEvent(calendar.Event event) {
    return CalendarEvent(
      summary: event.summary ?? 'No Title',
      startTime: event.start!.dateTime!.toLocal(),
      endTime: event.end!.dateTime!.toLocal(),
      meetingLink: event.hangoutLink,
    );
  }

  static EventStatus _calculateStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isAfter(start) && now.isBefore(end)) {
      return EventStatus.ongoing;
    }
    final diff = start.difference(now);
    if (diff > Duration.zero && diff <= const Duration(minutes: 10)) {
      return EventStatus.upcoming;
    }
    return EventStatus.normal;
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
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
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    final client = await _calendarService.getAuthenticatedClient();
    if (client != null) {
      setState(() {
        _isLoggedIn = true;
      });
      _startPolling();
    }
  }

  Future<void> _handleSignIn() async {
    final client = await _calendarService.signIn();
    if (client != null) {
      setState(() {
        _isLoggedIn = true;
      });
      _startPolling();
    }
  }

  Future<void> _handleSignOut() async {
    await _calendarService.signOut();
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

  void _updateEvents() async {
    final httpClient = await _calendarService.getAuthenticatedClient();
    if (httpClient == null) {
      return;
    }

    final calendarApi = calendar.CalendarApi(httpClient);
    final now = DateTime.now();
    final endOfTomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      23,
      59,
      59,
    );

    try {
      final events = await calendarApi.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: endOfTomorrow.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items != null) {
        final newEvents = events.items!
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
      }
    } catch (e) {
      if (e is auth.AccessDeniedException) {
        _handleSignOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} - ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} (${DateTime.now().weekday == 1
                ? 'Monday'
                : DateTime.now().weekday == 2
                ? 'Tuesday'
                : DateTime.now().weekday == 3
                ? 'Wednesday'
                : DateTime.now().weekday == 4
                ? 'Thursday'
                : DateTime.now().weekday == 5
                ? 'Friday'
                : DateTime.now().weekday == 6
                ? 'Saturday'
                : 'Sunday'})',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
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

  Color? _getEventBackgroundColor(EventStatus status) {
    switch (status) {
      case EventStatus.ongoing:
        return Colors.blue[700];
      case EventStatus.upcoming:
        return Colors.orange[400];
      default:
        return Colors.grey[300];
    }
  }

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final previousEvent = index > 0 ? _events[index - 1] : null;

        final isNewGroup =
            previousEvent == null ||
            event.startTime.hour != previousEvent.startTime.hour ||
            event.startTime.minute != previousEvent.startTime.minute;

        final isTomorrowSeparator =
            previousEvent != null &&
            previousEvent.startTime.day != event.startTime.day;

        final groupIndex =
            _events.sublist(0, index + 1).where((e) {
              final prevIndex = _events.indexOf(e) - 1;
              return prevIndex < 0 ||
                  e.startTime.hour != _events[prevIndex].startTime.hour ||
                  e.startTime.minute != _events[prevIndex].startTime.minute;
            }).length -
            1;

        final groupBackgroundColor = event.status == EventStatus.ongoing
            ? _getEventBackgroundColor(event.status)
            : event.status == EventStatus.upcoming
            ? _getEventBackgroundColor(event.status)
            : groupIndex % 2 == 0
            ? _getEventBackgroundColor(event.status)
            : Colors.orange[50];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTomorrowSeparator)
              ListTile(
                tileColor: Colors.grey,
                title: const Text(
                  '--- Tomorrow ---',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (isNewGroup)
              Container(
                height: 2,
                color: Colors.grey,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
              ),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              color: groupBackgroundColor,
              elevation: 6,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: event.status == EventStatus.ongoing
                      ? Colors.blueAccent
                      : event.status == EventStatus.upcoming
                      ? Colors.orangeAccent
                      : _getEventBackgroundColor(
                              event.status,
                            )?.withOpacity(0.8) ??
                            Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: _getEventIcon(event.status),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.summary,
                        style: TextStyle(
                          color: _getEventTextColor(event.status),
                          fontSize: event.meetingLink == null ? 16 : 20,
                          fontWeight: event.meetingLink == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatEventTime(event),
                          style: TextStyle(
                            color: _getEventTextColor(event.status),
                            fontSize: event.meetingLink == null ? 16 : 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: event.status == EventStatus.ongoing
                    ? Text(
                        '${(_calculateProgress(event.startTime, event.endTime) * 100).clamp(0, 100).toInt()}% of meeting passed',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
                trailing: ElevatedButton(
                  onPressed: event.meetingLink != null
                      ? () => launchUrl(Uri.parse(event.meetingLink!))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        event.status == EventStatus.ongoing &&
                            event.meetingLink == null
                        ? Colors.grey
                        : event.meetingLink != null
                        ? Colors.red
                        : Colors.grey,
                    elevation: 6,
                    side: event.meetingLink != null
                        ? BorderSide(color: Colors.redAccent, width: 2)
                        : BorderSide.none,
                  ),
                  child: Icon(
                    Icons.videocam,
                    color:
                        event.status == EventStatus.ongoing &&
                            event.meetingLink == null
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _calculateProgress(DateTime start, DateTime end) {
    final now = DateTime.now();
    final totalDuration = end.difference(start).inSeconds;
    final elapsedDuration = now.difference(start).inSeconds;
    return elapsedDuration / totalDuration;
  }

  Icon _getEventIcon(EventStatus status) {
    switch (status) {
      case EventStatus.ongoing:
        return const Icon(Icons.videocam, color: Colors.white);
      case EventStatus.upcoming:
        return const Icon(Icons.notifications_active, color: Colors.black);
      default:
        return const Icon(Icons.event);
    }
  }

  Color? _getEventTextColor(EventStatus status) {
    switch (status) {
      case EventStatus.ongoing:
        return Colors.white;
      case EventStatus.upcoming:
        return Colors.black;
      default:
        return null;
    }
  }

  String _formatEventTime(CalendarEvent event) {
    final now = DateTime.now();
    final start = event.startTime;
    final end = event.endTime;
    String countdown = '';

    if (now.isBefore(start)) {
      final diff = start.difference(now);
      countdown = 'In ${_formatDuration(diff)}';
    } else if (now.isAfter(start) && now.isBefore(end)) {
      final diff = end.difference(now);
      countdown = 'In ${_formatDuration(diff)}';
    }

    final startTimeStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return '$startTimeStr - $endTimeStr ($countdown)';
  }
}

String _formatDuration(Duration d) {
  if ((d.inHours > 0) || (d.inMinutes > 0)) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  return '${d.inSeconds}s';
}
