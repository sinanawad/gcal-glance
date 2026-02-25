import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/widgets/hero_card.dart';
import 'package:gcal_glance/widgets/compact_event_row.dart';

class DetailArea extends StatelessWidget {
  final List<CalendarEvent> events;
  final List<CalendarEvent> heroEvents;
  final ValueNotifier<DateTime> now;

  const DetailArea({
    super.key,
    required this.events,
    this.heroEvents = const [],
    required this.now,
  });

  bool _isSameEvent(CalendarEvent a, CalendarEvent b) {
    return a.startTime == b.startTime &&
        a.endTime == b.endTime &&
        a.summary == b.summary &&
        a.calendarId == b.calendarId;
  }

  bool _isSameTimeSlot(CalendarEvent a, CalendarEvent b) {
    return a.startTime.hour == b.startTime.hour &&
        a.startTime.minute == b.startTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, currentTime, _) {
        // Exclude hero events from the compact list.
        final filteredEvents = heroEvents.isNotEmpty
            ? events
                .where(
                    (e) => !heroEvents.any((h) => _isSameEvent(e, h)))
                .toList()
            : List<CalendarEvent>.of(events);

        // Compute group indices for alternating colors.
        int currentGroup = 0;
        final groupIndices = <int>[];
        for (var i = 0; i < filteredEvents.length; i++) {
          if (i > 0 &&
              !_isSameTimeSlot(
                  filteredEvents[i - 1], filteredEvents[i])) {
            currentGroup++;
          }
          groupIndices.add(currentGroup);
        }

        // Build list items: separators (tomorrow / group dividers) and events.
        final items = <_DetailItem>[];
        for (var i = 0; i < filteredEvents.length; i++) {
          if (i > 0) {
            final prevDate = filteredEvents[i - 1].startTime;
            final currDate = filteredEvents[i].startTime;

            if (_isSameDay(prevDate, currentTime) &&
                _isSameDay(
                    currDate, currentTime.add(const Duration(days: 1)))) {
              items.add(_DetailItem.tomorrowSeparator());
            } else if (!_isSameTimeSlot(
                filteredEvents[i - 1], filteredEvents[i])) {
              items.add(_DetailItem.groupSeparator());
            }
          } else if (filteredEvents.isNotEmpty &&
              _isSameDay(filteredEvents[0].startTime,
                  currentTime.add(const Duration(days: 1)))) {
            items.add(_DetailItem.tomorrowSeparator());
          }
          items.add(_DetailItem.event(filteredEvents[i], groupIndices[i]));
        }

        final isCompactHero = heroEvents.length > 1;

        return Column(
          children: [
            for (final hero in heroEvents)
              HeroCard(event: hero, now: now, compact: isCompactHero),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isTomorrowSeparator) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: CrtTheme.timelineBg,
                      child: Center(
                        child: Text(
                          '--- Tomorrow ---',
                          style: GoogleFonts.vt323(
                            fontSize: 22,
                            color: CrtTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  if (item.isGroupSeparator) {
                    return Container(
                      height: 1,
                      color: CrtTheme.textSecondary.withValues(alpha: 0.25),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    );
                  }
                  return CompactEventRow(
                    event: item.event!,
                    now: now,
                    isEvenGroup: item.groupIndex! % 2 == 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DetailItem {
  final bool isTomorrowSeparator;
  final bool isGroupSeparator;
  final CalendarEvent? event;
  final int? groupIndex;

  _DetailItem.tomorrowSeparator()
      : isTomorrowSeparator = true,
        isGroupSeparator = false,
        event = null,
        groupIndex = null;

  _DetailItem.groupSeparator()
      : isTomorrowSeparator = false,
        isGroupSeparator = true,
        event = null,
        groupIndex = null;

  _DetailItem.event(CalendarEvent e, int group)
      : isTomorrowSeparator = false,
        isGroupSeparator = false,
        event = e,
        groupIndex = group;
}
