import 'package:flutter/material.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/widgets/event_card.dart';
import 'package:url_launcher/url_launcher.dart';

class EventList extends StatelessWidget {
  final List<CalendarEvent> events;
  final ValueNotifier<DateTime> nowNotifier;

  const EventList({super.key, required this.events, required this.nowNotifier});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    // Precompute group indices before the build pass (FR-014).
    final groupIndices = _computeGroupIndices();

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final previousEvent = index > 0 ? events[index - 1] : null;

        final isNewGroup = previousEvent == null ||
            event.startTime.hour != previousEvent.startTime.hour ||
            event.startTime.minute != previousEvent.startTime.minute;

        final isTomorrowSeparator = previousEvent != null &&
            previousEvent.startTime.day != event.startTime.day;

        final groupIndex = groupIndices[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTomorrowSeparator)
              const ListTile(
                tileColor: Colors.grey,
                title: Text(
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
            EventCard(
              event: event,
              nowNotifier: nowNotifier,
              backgroundColorFor: (status) =>
                  _getGroupBackgroundColor(status, groupIndex),
              onJoinMeeting: event.meetingLink != null &&
                      Uri.tryParse(event.meetingLink!)?.scheme == 'https'
                  ? () => launchUrl(Uri.parse(event.meetingLink!))
                  : null,
            ),
          ],
        );
      },
    );
  }

  /// Precompute group index for each event. O(n) single pass.
  List<int> _computeGroupIndices() {
    final indices = List<int>.filled(events.length, 0);
    int currentGroup = 0;

    for (int i = 0; i < events.length; i++) {
      if (i > 0) {
        final prev = events[i - 1];
        final curr = events[i];
        if (curr.startTime.hour != prev.startTime.hour ||
            curr.startTime.minute != prev.startTime.minute) {
          currentGroup++;
        }
      }
      indices[i] = currentGroup;
    }

    return indices;
  }

  Color? _getGroupBackgroundColor(EventStatus status, int groupIndex) {
    switch (status) {
      case EventStatus.ongoing:
        return Colors.blue[700];
      case EventStatus.upcoming:
        return Colors.orange[400];
      case EventStatus.normal:
        return groupIndex % 2 == 0 ? Colors.grey[300] : Colors.orange[50];
    }
  }
}
