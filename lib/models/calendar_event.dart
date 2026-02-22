import 'package:googleapis/calendar/v3.dart' as calendar;

enum EventStatus { ongoing, upcoming, normal }

class CalendarEvent {
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final String? meetingLink;

  const CalendarEvent({
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.meetingLink,
  });

  factory CalendarEvent.fromGoogleEvent(calendar.Event event) {
    return CalendarEvent(
      summary: event.summary ?? 'No Title',
      startTime: event.start!.dateTime!.toLocal(),
      endTime: event.end!.dateTime!.toLocal(),
      meetingLink: event.hangoutLink,
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
