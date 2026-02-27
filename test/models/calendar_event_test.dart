import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

void main() {
  group('status', () {
    test('returns ongoing when now is between start and end', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 10, 30);

      expect(event.status(now), EventStatus.ongoing);
    });

    test('returns upcoming when within 10 minutes of start', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 9, 55);

      expect(event.status(now), EventStatus.upcoming);
    });

    test('returns upcoming at exactly 10 minutes before start', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 9, 50);

      expect(event.status(now), EventStatus.upcoming);
    });

    test('returns normal when more than 10 minutes before start', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 9, 0);

      expect(event.status(now), EventStatus.normal);
    });

    test('returns past when now is after end', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 12, 0);

      expect(event.status(now), EventStatus.past);
    });

    test('returns normal at exact start time (boundary)', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      // isAfter is strict: now == startTime → not ongoing.
      // diff is zero: not > Duration.zero → not upcoming.
      expect(event.status(event.startTime), EventStatus.normal);
    });

    test('returns normal at exact end time (boundary)', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      // isBefore(endTime) is false when now == endTime
      expect(event.status(event.endTime), EventStatus.normal);
    });
  });

  group('progress', () {
    test('returns 0.0 before event starts', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 9, 0);

      expect(event.progress(now), 0.0);
    });

    test('returns correct fraction during event', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      // 30 minutes into a 60-minute event = 0.5
      final now = DateTime(2026, 2, 24, 10, 30);

      expect(event.progress(now), closeTo(0.5, 0.01));
    });

    test('returns 0.0 after event ends', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 12, 0);

      expect(event.progress(now), 0.0);
    });
  });

  group('countdown', () {
    test('returns time until start when before event', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 9, 50);

      expect(event.countdown(now), const Duration(minutes: 10));
    });

    test('returns time until end when during event', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 10, 45);

      expect(event.countdown(now), const Duration(minutes: 15));
    });

    test('returns zero after event ends', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 12, 0);

      expect(event.countdown(now), Duration.zero);
    });
  });

  group('edge cases', () {
    test('zero-duration event (startTime == endTime) returns normal status',
        () {
      final event = CalendarEvent(
        summary: 'Instant',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 10, 0),
      );

      expect(event.status(DateTime(2026, 2, 24, 10, 0)), EventStatus.normal);
      expect(event.progress(DateTime(2026, 2, 24, 10, 0)), 0.0);
      expect(event.countdown(DateTime(2026, 2, 24, 10, 0)), Duration.zero);
    });

    test('progress returns 0.0 for zero-duration event', () {
      final event = CalendarEvent(
        summary: 'Instant',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 10, 0),
      );

      expect(event.progress(DateTime(2026, 2, 24, 9, 59)), 0.0);
      expect(event.progress(DateTime(2026, 2, 24, 10, 1)), 0.0);
    });

    test('status transitions correctly at 10-minute boundary', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );

      // 10 min 1 sec before → normal
      final justOutside = DateTime(2026, 2, 24, 9, 49, 59);
      expect(event.status(justOutside), EventStatus.normal);

      // 9 min 59 sec before → upcoming
      final justInside = DateTime(2026, 2, 24, 9, 50, 1);
      expect(event.status(justInside), EventStatus.upcoming);
    });

    test('short event is ongoing at midpoint', () {
      final event = CalendarEvent(
        summary: 'Quick sync',
        startTime: DateTime(2026, 2, 24, 10, 0, 0),
        endTime: DateTime(2026, 2, 24, 10, 0, 10),
      );

      final during = DateTime(2026, 2, 24, 10, 0, 5);
      expect(event.status(during), EventStatus.ongoing);
      expect(event.progress(during), closeTo(0.5, 0.01));
    });
  });

  group('ResponseStatus', () {
    test('defaults to accepted when no responseStatus provided', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
      );

      expect(event.responseStatus, ResponseStatus.accepted);
      expect(event.isAccepted, true);
      expect(event.isTentative, false);
    });

    test('isTentative is true for tentative responseStatus', () {
      final event = CalendarEvent(
        summary: 'Maybe',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
        responseStatus: ResponseStatus.tentative,
      );

      expect(event.isTentative, true);
      expect(event.isAccepted, false);
    });

    test('isTentative is true for needsAction responseStatus', () {
      final event = CalendarEvent(
        summary: 'No response yet',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
        responseStatus: ResponseStatus.needsAction,
      );

      expect(event.isTentative, true);
      expect(event.isAccepted, false);
    });

    test('declined event has correct flags', () {
      final event = CalendarEvent(
        summary: 'Nope',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
        responseStatus: ResponseStatus.declined,
      );

      expect(event.isTentative, false);
      expect(event.isAccepted, false);
      expect(event.responseStatus, ResponseStatus.declined);
    });
  });

  group('multi-calendar fields', () {
    test('defaults to primary calendar', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
      );

      expect(event.calendarId, 'primary');
      expect(event.isPrimary, true);
      expect(event.isSecondary, false);
      expect(event.calendarColorValue, isNull);
    });

    test('isSecondary is true when isPrimary is false', () {
      final event = CalendarEvent(
        summary: 'Team Event',
        startTime: DateTime(2026, 2, 25, 10, 0),
        endTime: DateTime(2026, 2, 25, 11, 0),
        calendarId: 'team@group.calendar.google.com',
        isPrimary: false,
        calendarColorValue: 0xFF0088AA,
      );

      expect(event.isPrimary, false);
      expect(event.isSecondary, true);
      expect(event.calendarId, 'team@group.calendar.google.com');
      expect(event.calendarColorValue, 0xFF0088AA);
    });
  });

  group('parseHexColor', () {
    test('parses standard 6-digit hex with hash', () {
      expect(CalendarEvent.parseHexColor('#0088aa'), 0xFF0088AA);
    });

    test('parses 6-digit hex without hash', () {
      expect(CalendarEvent.parseHexColor('ff5500'), 0xFFFF5500);
    });

    test('returns null for null input', () {
      expect(CalendarEvent.parseHexColor(null), isNull);
    });

    test('returns null for empty string', () {
      expect(CalendarEvent.parseHexColor(''), isNull);
    });

    test('returns null for wrong length', () {
      expect(CalendarEvent.parseHexColor('#fff'), isNull);
      expect(CalendarEvent.parseHexColor('#aabbccdd'), isNull);
    });

    test('returns null for invalid hex characters', () {
      expect(CalendarEvent.parseHexColor('#gggggg'), isNull);
    });
  });

  group('fromGoogleEvent RSVP mapping', () {
    calendar.Event makeGoogleEvent({
      String? selfResponseStatus,
      bool hasSelfAttendee = true,
      bool hasAttendees = true,
    }) {
      final event = calendar.Event()
        ..summary = 'Test Meeting'
        ..start = (calendar.EventDateTime()
          ..dateTime = DateTime.utc(2026, 2, 25, 15, 0))
        ..end = (calendar.EventDateTime()
          ..dateTime = DateTime.utc(2026, 2, 25, 16, 0))
        ..hangoutLink = 'https://meet.google.com/abc-def-ghi';

      if (hasAttendees) {
        final others = calendar.EventAttendee()
          ..email = 'other@example.com'
          ..responseStatus = 'accepted'
          ..self = false;

        if (hasSelfAttendee) {
          final self = calendar.EventAttendee()
            ..email = 'me@example.com'
            ..responseStatus = selfResponseStatus
            ..self = true;
          event.attendees = [others, self];
        } else {
          event.attendees = [others];
        }
      }

      return event;
    }

    test('maps accepted responseStatus', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'accepted'),
      );
      expect(event.responseStatus, ResponseStatus.accepted);
    });

    test('maps tentative responseStatus', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'tentative'),
      );
      expect(event.responseStatus, ResponseStatus.tentative);
    });

    test('maps needsAction responseStatus', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'needsAction'),
      );
      expect(event.responseStatus, ResponseStatus.needsAction);
    });

    test('maps declined responseStatus', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'declined'),
      );
      expect(event.responseStatus, ResponseStatus.declined);
    });

    test('defaults to accepted when no self attendee found', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(hasSelfAttendee: false),
      );
      expect(event.responseStatus, ResponseStatus.accepted);
    });

    test('defaults to accepted when no attendees list (personal event)', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(hasAttendees: false),
      );
      expect(event.responseStatus, ResponseStatus.accepted);
    });

    test('preserves meeting link from hangoutLink', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'accepted'),
      );
      expect(event.meetingLink, 'https://meet.google.com/abc-def-ghi');
    });

    test('passes through calendar metadata', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'accepted'),
        calendarId: 'shared@group.calendar.google.com',
        isPrimary: false,
        calendarColorValue: 0xFF00AA88,
      );

      expect(event.calendarId, 'shared@group.calendar.google.com');
      expect(event.isPrimary, false);
      expect(event.isSecondary, true);
      expect(event.calendarColorValue, 0xFF00AA88);
    });

    test('defaults to primary when no calendar metadata provided', () {
      final event = CalendarEvent.fromGoogleEvent(
        makeGoogleEvent(selfResponseStatus: 'accepted'),
      );

      expect(event.calendarId, 'primary');
      expect(event.isPrimary, true);
      expect(event.isSecondary, false);
      expect(event.calendarColorValue, isNull);
    });
  });
}
