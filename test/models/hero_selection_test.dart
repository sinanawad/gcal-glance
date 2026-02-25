import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/calendar_event.dart';

/// These tests verify the hero selection and declined-filtering logic
/// as implemented in CalendarHomePage._selectHeroEvents and _updateEvents.
/// The logic is replicated here as pure functions for unit testability.

/// Mirrors CalendarHomePage._selectHeroEvents.
List<CalendarEvent> selectHeroEvents(
    List<CalendarEvent> events, DateTime now) {
  final ongoingWithLink = events
      .where(
          (e) => e.status(now) == EventStatus.ongoing && e.meetingLink != null)
      .toList();
  if (ongoingWithLink.isEmpty) return [];

  final accepted = ongoingWithLink.where((e) => e.isAccepted).toList();
  final tentative = ongoingWithLink.where((e) => e.isTentative).toList();

  if (accepted.isNotEmpty) {
    accepted.sort((a, b) => a.endTime.compareTo(b.endTime));
    return accepted;
  }
  if (tentative.isNotEmpty) {
    tentative.sort((a, b) => a.endTime.compareTo(b.endTime));
    return [tentative.first];
  }
  return [];
}

/// Mirrors the declined-filtering in CalendarHomePage._updateEvents.
List<CalendarEvent> filterDeclined(List<CalendarEvent> events) {
  return events
      .where((e) => e.responseStatus != ResponseStatus.declined)
      .toList();
}

void main() {
  final now = DateTime(2026, 2, 25, 10, 30);

  CalendarEvent makeEvent({
    required String summary,
    DateTime? start,
    DateTime? end,
    String? link,
    ResponseStatus status = ResponseStatus.accepted,
  }) {
    return CalendarEvent(
      summary: summary,
      startTime: start ?? DateTime(2026, 2, 25, 10, 0),
      endTime: end ?? DateTime(2026, 2, 25, 11, 0),
      meetingLink: link,
      responseStatus: status,
    );
  }

  group('declined filtering', () {
    test('removes declined events', () {
      final events = [
        makeEvent(summary: 'Accepted', status: ResponseStatus.accepted),
        makeEvent(summary: 'Declined', status: ResponseStatus.declined),
        makeEvent(summary: 'Tentative', status: ResponseStatus.tentative),
      ];

      final filtered = filterDeclined(events);
      expect(filtered.length, 2);
      expect(filtered.map((e) => e.summary), ['Accepted', 'Tentative']);
    });

    test('keeps needsAction events', () {
      final events = [
        makeEvent(summary: 'NeedsAction', status: ResponseStatus.needsAction),
      ];

      final filtered = filterDeclined(events);
      expect(filtered.length, 1);
    });

    test('returns empty list when all declined', () {
      final events = [
        makeEvent(summary: 'A', status: ResponseStatus.declined),
        makeEvent(summary: 'B', status: ResponseStatus.declined),
      ];

      expect(filterDeclined(events), isEmpty);
    });
  });

  group('hero selection', () {
    test('returns empty when no ongoing events', () {
      final events = [
        makeEvent(
          summary: 'Future',
          start: DateTime(2026, 2, 25, 14, 0),
          end: DateTime(2026, 2, 25, 15, 0),
          link: 'https://meet.google.com/abc',
        ),
      ];

      expect(selectHeroEvents(events, now), isEmpty);
    });

    test('returns empty when ongoing has no meeting link', () {
      final events = [
        makeEvent(summary: 'Ongoing no link'),
      ];

      expect(selectHeroEvents(events, now), isEmpty);
    });

    test('single accepted ongoing with link becomes hero', () {
      final events = [
        makeEvent(
          summary: 'Standup',
          link: 'https://meet.google.com/abc',
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 1);
      expect(heroes.first.summary, 'Standup');
    });

    test('accepted takes priority over tentative', () {
      final events = [
        makeEvent(
          summary: 'Tentative Meeting',
          link: 'https://meet.google.com/tent',
          status: ResponseStatus.tentative,
        ),
        makeEvent(
          summary: 'Accepted Meeting',
          link: 'https://meet.google.com/acc',
          status: ResponseStatus.accepted,
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 1);
      expect(heroes.first.summary, 'Accepted Meeting');
    });

    test('all accepted ongoing with links become heroes (dual hero)', () {
      final events = [
        makeEvent(
          summary: 'Meeting A',
          end: DateTime(2026, 2, 25, 11, 0),
          link: 'https://meet.google.com/a',
        ),
        makeEvent(
          summary: 'Meeting B',
          end: DateTime(2026, 2, 25, 11, 30),
          link: 'https://meet.google.com/b',
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 2);
      // Sorted by endTime
      expect(heroes[0].summary, 'Meeting A');
      expect(heroes[1].summary, 'Meeting B');
    });

    test('tentative-only returns single hero (soonest ending)', () {
      final events = [
        makeEvent(
          summary: 'Tentative A',
          end: DateTime(2026, 2, 25, 11, 30),
          link: 'https://meet.google.com/a',
          status: ResponseStatus.tentative,
        ),
        makeEvent(
          summary: 'Tentative B',
          end: DateTime(2026, 2, 25, 11, 0),
          link: 'https://meet.google.com/b',
          status: ResponseStatus.tentative,
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 1);
      expect(heroes.first.summary, 'Tentative B'); // ends sooner
    });

    test('needsAction treated same as tentative for hero selection', () {
      final events = [
        makeEvent(
          summary: 'NeedsAction Meeting',
          link: 'https://meet.google.com/na',
          status: ResponseStatus.needsAction,
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 1);
      expect(heroes.first.summary, 'NeedsAction Meeting');
    });

    test('mix of accepted + tentative: only accepted get hero', () {
      final events = [
        makeEvent(
          summary: 'Accepted 1',
          end: DateTime(2026, 2, 25, 11, 0),
          link: 'https://meet.google.com/a1',
        ),
        makeEvent(
          summary: 'Tentative 1',
          end: DateTime(2026, 2, 25, 10, 45),
          link: 'https://meet.google.com/t1',
          status: ResponseStatus.tentative,
        ),
        makeEvent(
          summary: 'Accepted 2',
          end: DateTime(2026, 2, 25, 11, 30),
          link: 'https://meet.google.com/a2',
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 2);
      expect(heroes.map((e) => e.summary), ['Accepted 1', 'Accepted 2']);
    });

    test('ongoing without link excluded even if accepted', () {
      final events = [
        makeEvent(summary: 'No Link Meeting'), // ongoing, accepted, no link
        makeEvent(
          summary: 'Has Link',
          link: 'https://meet.google.com/abc',
          status: ResponseStatus.tentative,
        ),
      ];

      final heroes = selectHeroEvents(events, now);
      expect(heroes.length, 1);
      expect(heroes.first.summary, 'Has Link');
    });
  });
}
