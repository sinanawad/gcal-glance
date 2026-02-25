import 'package:googleapis/calendar/v3.dart' as calendar;

enum EventStatus { ongoing, upcoming, normal }

enum ResponseStatus { accepted, tentative, needsAction, declined }

class CalendarEvent {
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final String? meetingLink;
  final ResponseStatus responseStatus;

  const CalendarEvent({
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.meetingLink,
    this.responseStatus = ResponseStatus.accepted,
  });

  /// Whether the user's response is tentative or needsAction.
  bool get isTentative =>
      responseStatus == ResponseStatus.tentative ||
      responseStatus == ResponseStatus.needsAction;

  /// Whether the user has accepted the event (or is organizer with no attendees).
  bool get isAccepted => responseStatus == ResponseStatus.accepted;

  factory CalendarEvent.fromGoogleEvent(calendar.Event event) {
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
