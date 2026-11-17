import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/widgets/timeline_strip.dart';

void main() {
  final start = DateTime(2026, 11, 17, 10);
  final end = DateTime(2026, 11, 17, 11);

  group('TimelineStrip.blockAlphaFactor', () {
    test('meetings with a Meet link are drawn at full strength', () {
      final event = CalendarEvent(
        summary: 'Standup',
        startTime: start,
        endTime: end,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
      );
      expect(TimelineStrip.blockAlphaFactor(event), 1.0);
    });

    test('events without a Meet link are heavily faded', () {
      final event = CalendarEvent(
        summary: 'Focus block',
        startTime: start,
        endTime: end,
      );
      expect(
        TimelineStrip.blockAlphaFactor(event),
        TimelineStrip.noMeetingLinkAlphaFactor,
      );
      expect(TimelineStrip.noMeetingLinkAlphaFactor, lessThan(0.5));
    });

    test('tentative events without a link are faded too', () {
      final event = CalendarEvent(
        summary: 'Maybe block',
        startTime: start,
        endTime: end,
        responseStatus: ResponseStatus.tentative,
      );
      expect(
        TimelineStrip.blockAlphaFactor(event),
        TimelineStrip.noMeetingLinkAlphaFactor,
      );
    });
  });
}
