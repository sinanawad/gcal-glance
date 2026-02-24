import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/calendar_event.dart';

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

    test('returns normal when now is after end', () {
      final event = CalendarEvent(
        summary: 'Meeting',
        startTime: DateTime(2026, 2, 24, 10, 0),
        endTime: DateTime(2026, 2, 24, 11, 0),
      );
      final now = DateTime(2026, 2, 24, 12, 0);

      expect(event.status(now), EventStatus.normal);
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
}
