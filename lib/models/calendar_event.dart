import 'package:googleapis/calendar/v3.dart' as calendar;

enum EventStatus { ongoing, upcoming, normal }

enum ResponseStatus { accepted, tentative, needsAction, declined }

class CalendarEvent {
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final String? meetingLink;
  final ResponseStatus responseStatus;
  final String calendarId;
  final bool isPrimary;
  final int? calendarColorValue; // ARGB int from Google hex color

  const CalendarEvent({
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.meetingLink,
    this.responseStatus = ResponseStatus.accepted,
    this.calendarId = 'primary',
    this.isPrimary = true,
    this.calendarColorValue,
  });

  /// Whether the user's response is tentative or needsAction.
  bool get isTentative =>
      responseStatus == ResponseStatus.tentative ||
      responseStatus == ResponseStatus.needsAction;

  /// Whether the user has accepted the event (or is organizer with no attendees).
  bool get isAccepted => responseStatus == ResponseStatus.accepted;

  /// Whether this event belongs to a secondary (non-primary) calendar.
  bool get isSecondary => !isPrimary;

  /// Parses a Google Calendar hex color string (e.g. "#0088aa") to an ARGB int.
  static int? parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    return int.tryParse('FF$cleaned', radix: 16);
  }

  factory CalendarEvent.fromGoogleEvent(
    calendar.Event event, {
    String calendarId = 'primary',
    bool isPrimary = true,
    int? calendarColorValue,
  }) {
    // Find the authenticated user's attendee record via self == true.
    // If no attendees list (personal event), defaults to accepted.
    final selfAttendee = event.attendees
        ?.cast<calendar.EventAttendee?>()
        .firstWhere((a) => a?.self == true, orElse: () => null);

    final ResponseStatus responseStatus;
    switch (selfAttendee?.responseStatus) {
      case 'tentative':
        responseStatus = ResponseStatus.tentative;
      case 'needsAction':
        responseStatus = ResponseStatus.needsAction;
      case 'declined':
        responseStatus = ResponseStatus.declined;
      default:
        responseStatus = ResponseStatus.accepted;
    }

    return CalendarEvent(
      summary: event.summary ?? 'No Title',
      startTime: event.start!.dateTime!.toLocal(),
      endTime: event.end!.dateTime!.toLocal(),
      meetingLink: event.hangoutLink,
      responseStatus: responseStatus,
      calendarId: calendarId,
      isPrimary: isPrimary,
      calendarColorValue: calendarColorValue,
    );
  }

  EventStatus status(DateTime now) {
    if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return EventStatus.ongoing;
    }
    final diff = startTime.difference(now);
    if (diff > Duration.zero && diff <= const Duration(minutes: 10)) {
      return EventStatus.upcoming;
    }
    return EventStatus.normal;
  }

  double progress(DateTime now) {
    if (!now.isAfter(startTime) || !now.isBefore(endTime)) {
      return 0.0;
    }
    final totalDuration = endTime.difference(startTime).inSeconds;
    if (totalDuration <= 0) return 0.0;
    final elapsedDuration = now.difference(startTime).inSeconds;
    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }

  Duration countdown(DateTime now) {
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }
}
