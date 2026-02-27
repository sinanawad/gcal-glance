import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';

class CompactEventRow extends StatelessWidget {
  final CalendarEvent event;
  final ValueNotifier<DateTime> now;
  final bool isEvenGroup;

  const CompactEventRow({
    super.key,
    required this.event,
    required this.now,
    this.isEvenGroup = true,
  });

  static String _formatCountdown(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, currentTime, _) {
        final status = event.status(currentTime);

        final Color statusColor;
        final Color bgColor;
        final IconData statusIcon;

        // Secondary events use their Google Calendar faded color.
        final calColor = event.isSecondary && event.calendarColorValue != null
            ? CrtTheme.fadedCalendarColor(event.calendarColorValue!)
            : null;

        if (event.isSecondary) {
          statusColor = calColor ?? CrtTheme.textSecondary;
          bgColor = statusColor.withValues(alpha: 0.08);
          statusIcon = Icons.event;
        } else {
          switch (status) {
            case EventStatus.ongoing:
              statusColor = CrtTheme.ongoing;
              bgColor = CrtTheme.ongoing.withValues(alpha: 0.15);
              statusIcon = Icons.videocam;
            case EventStatus.upcoming:
              statusColor = CrtTheme.upcoming;
              bgColor = CrtTheme.upcoming.withValues(alpha: 0.12);
              statusIcon = Icons.notifications_active;
            case EventStatus.past:
              statusColor = CrtTheme.past;
              bgColor = CrtTheme.past.withValues(alpha: 0.08);
              statusIcon = Icons.event;
            case EventStatus.normal:
              statusColor = CrtTheme.normal;
              bgColor = isEvenGroup
                  ? CrtTheme.clockFlap.withValues(alpha: 0.4)
                  : CrtTheme.background;
              statusIcon = Icons.event;
          }
        }

        final startHour = event.startTime.hour.toString().padLeft(2, '0');
        final startMin = event.startTime.minute.toString().padLeft(2, '0');
        final endHour = event.endTime.hour.toString().padLeft(2, '0');
        final endMin = event.endTime.minute.toString().padLeft(2, '0');

        String countdownText;
        Color countdownColor;
        if (status == EventStatus.ongoing) {
          countdownText =
              'ends ${_formatCountdown(event.countdown(currentTime))}';
          countdownColor = CrtTheme.ongoing;
        } else if ((status == EventStatus.upcoming ||
                status == EventStatus.normal) &&
            event.startTime.isAfter(currentTime)) {
          countdownText =
              'In ${_formatCountdown(event.startTime.difference(currentTime))}';
          countdownColor = status == EventStatus.upcoming
              ? CrtTheme.upcoming
              : CrtTheme.textSecondary;
        } else {
          countdownText = '';
          countdownColor = CrtTheme.textSecondary;
        }

        final hasValidLink = event.meetingLink != null &&
            Uri.tryParse(event.meetingLink!)?.scheme == 'https';
        final hasMeetingLink = event.meetingLink != null;

        // Secondary events always get faded treatment; primary events
        // without meeting links get smaller font.
        final double titleFontSize;
        final double timeFontSize;
        final double countdownFontSize;
        final Color titleColor;
        final Color timeColor;

        if (event.isSecondary) {
          titleFontSize = 18;
          timeFontSize = 18;
          countdownFontSize = 18;
          titleColor = calColor ?? CrtTheme.textSecondary.withValues(alpha: 0.5);
          timeColor = CrtTheme.textSecondary.withValues(alpha: 0.4);
        } else {
          titleFontSize = hasMeetingLink ? 24 : 20;
          timeFontSize = hasMeetingLink ? 24 : 18;
          countdownFontSize = hasMeetingLink ? 22 : 18;
          titleColor = hasMeetingLink
              ? (event.isTentative
                  ? CrtTheme.textPrimary.withValues(alpha: 0.7)
                  : CrtTheme.textPrimary)
              : CrtTheme.textSecondary;
          timeColor = hasMeetingLink
              ? CrtTheme.textSecondary
              : CrtTheme.textSecondary.withValues(alpha: 0.6);
        }

        final rowContent = Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Status icon
              Icon(
                statusIcon,
                size: hasMeetingLink ? 18 : 15,
                color: hasMeetingLink
                    ? statusColor
                    : statusColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              // Contact photo for 1-on-1 meetings
              if (event.otherAttendeeEmail != null && !event.isSecondary)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: event.otherAttendeePhotoUrl != null
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              NetworkImage(event.otherAttendeePhotoUrl!),
                          backgroundColor: CrtTheme.clockFlap,
                        )
                      : CircleAvatar(
                          radius: 14,
                          backgroundColor: CrtTheme.clockFlap,
                          child: Text(
                            event.otherAttendeeEmail!
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.vt323(
                              fontSize: 16,
                              color: CrtTheme.textSecondary,
                            ),
                          ),
                        ),
                ),
              // Event title
              Expanded(
                child: Text(
                  event.summary,
                  style: GoogleFonts.vt323(
                    fontSize: titleFontSize,
                    color: titleColor,
                    fontWeight:
                        hasMeetingLink ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              // Time range — fixed width for alignment
              SizedBox(
                width: 145,
                child: Text(
                  '$startHour:$startMin \u2192 $endHour:$endMin',
                  style: GoogleFonts.vt323(
                    fontSize: timeFontSize,
                    color: timeColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              // Countdown — fixed width for alignment
              SizedBox(
                width: 110,
                child: Text(
                  countdownText,
                  style: GoogleFonts.vt323(
                    fontSize: countdownFontSize,
                    color: hasMeetingLink
                        ? countdownColor
                        : countdownColor.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              // Join button — always reserve the space for alignment
              SizedBox(
                width: 32,
                child: hasValidLink
                    ? IconButton(
                        icon: Icon(
                          Icons.videocam,
                          size: 22,
                          color: CrtTheme.joinActive,
                        ),
                        onPressed: () =>
                            launchUrl(Uri.parse(event.meetingLink!)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );

        if (event.isTentative) {
          return ClipRect(
            child: CustomPaint(
              foregroundPainter: _CrosshatchPainter(color: statusColor),
              child: rowContent,
            ),
          );
        }
        return rowContent;
      },
    );
  }
}

class _CrosshatchPainter extends CustomPainter {
  final Color color;
  _CrosshatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const spacing = 10.0;

    for (double d = -size.height; d < size.width + size.height; d += spacing) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        paint,
      );
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrosshatchPainter old) => color != old.color;
}
