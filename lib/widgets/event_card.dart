import 'package:flutter/material.dart';
import 'package:gcal_glance/models/calendar_event.dart';
import 'package:gcal_glance/models/time_utils.dart';

class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final ValueNotifier<DateTime> nowNotifier;
  final Color? Function(EventStatus status) backgroundColorFor;
  final VoidCallback? onJoinMeeting;

  const EventCard({
    super.key,
    required this.event,
    required this.nowNotifier,
    required this.backgroundColorFor,
    this.onJoinMeeting,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: nowNotifier,
      builder: (context, now, _) {
        final eventStatus = event.status(now);
        final bgColor = backgroundColorFor(eventStatus);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          color: bgColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: _borderColor(eventStatus, bgColor),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: _buildIcon(eventStatus),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.summary,
                    style: TextStyle(
                      color: _textColor(eventStatus),
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
                      _formatEventTime(now),
                      style: TextStyle(
                        color: _textColor(eventStatus),
                        fontSize: event.meetingLink == null ? 16 : 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: eventStatus == EventStatus.ongoing
                ? Text(
                    '${(event.progress(now) * 100).clamp(0, 100).toInt()}% of meeting passed',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
            trailing: ElevatedButton(
              onPressed: event.meetingLink != null ? onJoinMeeting : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    eventStatus == EventStatus.ongoing &&
                            event.meetingLink == null
                        ? Colors.grey
                        : event.meetingLink != null
                            ? Colors.red
                            : Colors.grey,
                elevation: 6,
                side: event.meetingLink != null
                    ? const BorderSide(color: Colors.redAccent, width: 2)
                    : BorderSide.none,
              ),
              child: Icon(
                Icons.videocam,
                color: eventStatus == EventStatus.ongoing &&
                        event.meetingLink == null
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _borderColor(EventStatus status, Color? bgColor) {
    switch (status) {
      case EventStatus.ongoing:
        return Colors.blueAccent;
      case EventStatus.upcoming:
        return Colors.orangeAccent;
      case EventStatus.normal:
        return bgColor?.withValues(alpha: 0.8) ?? Colors.grey;
    }
  }

  Icon _buildIcon(EventStatus status) {
    switch (status) {
      case EventStatus.ongoing:
        return const Icon(Icons.videocam, color: Colors.white);
      case EventStatus.upcoming:
        return const Icon(Icons.notifications_active, color: Colors.black);
      case EventStatus.normal:
        return const Icon(Icons.event);
    }
  }

  Color? _textColor(EventStatus status) {
    switch (status) {
      case EventStatus.ongoing:
        return Colors.white;
      case EventStatus.upcoming:
        return Colors.black;
      case EventStatus.normal:
        return null;
    }
  }

  String _formatEventTime(DateTime now) {
    final start = event.startTime;
    final end = event.endTime;
    final countdown = event.countdown(now);
    String countdownStr = '';

    if (countdown > Duration.zero) {
      countdownStr = 'In ${TimeUtils.formatDuration(countdown)}';
    }

    final startTimeStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return '$startTimeStr - $endTimeStr ($countdownStr)';
  }
}
