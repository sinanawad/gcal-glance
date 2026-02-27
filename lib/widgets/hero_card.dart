import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';

class HeroCard extends StatelessWidget {
  final CalendarEvent event;
  final ValueNotifier<DateTime> now;
  final bool compact;

  const HeroCard({
    super.key,
    required this.event,
    required this.now,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, currentTime, _) {
        final startHour = event.startTime.hour.toString().padLeft(2, '0');
        final startMin = event.startTime.minute.toString().padLeft(2, '0');
        final endHour = event.endTime.hour.toString().padLeft(2, '0');
        final endMin = event.endTime.minute.toString().padLeft(2, '0');

        final hasValidLink = event.meetingLink != null &&
            Uri.tryParse(event.meetingLink!)?.scheme == 'https';

        final borderColor = event.isTentative
            ? CrtTheme.upcoming.withValues(alpha: 0.7)
            : CrtTheme.ongoing;
        final accentColor = event.isTentative ? CrtTheme.upcoming : CrtTheme.ongoing;

        final double titleSize = compact ? 24 : 38;
        final int titleMaxLines = compact ? 1 : 2;
        final double timeSize = compact ? 16 : 19;
        final double progressHeight = compact ? 8 : 12;
        final EdgeInsets padding = compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.all(16);
        final EdgeInsets margin = compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        final double borderWidth = compact ? 1.5 : 2;

        return Card(
          color: CrtTheme.background,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: margin,
          elevation: 8,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.otherAttendeeEmail != null) ...[
                      Padding(
                        padding: EdgeInsets.only(
                            right: 12, top: compact ? 0 : 4),
                        child: event.otherAttendeePhotoUrl != null
                            ? CircleAvatar(
                                radius: compact ? 16 : 24,
                                backgroundImage: NetworkImage(
                                    event.otherAttendeePhotoUrl!),
                                backgroundColor: CrtTheme.clockFlap,
                              )
                            : CircleAvatar(
                                radius: compact ? 16 : 24,
                                backgroundColor: CrtTheme.clockFlap,
                                child: Text(
                                  event.otherAttendeeEmail!
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.vt323(
                                    fontSize: compact ? 18 : 28,
                                    color: CrtTheme.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                    ],
                    if (event.isTentative) ...[
                      Text(
                        'TENTATIVE',
                        style: GoogleFonts.vt323(
                          fontSize: 12,
                          color: CrtTheme.upcoming,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        event.summary,
                        style: GoogleFonts.vt323(
                          fontSize: titleSize,
                          color: CrtTheme.textPrimary,
                        ),
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      compact
                          ? '$startHour:$startMin\u2192$endHour:$endMin'
                          : '$startHour:$startMin\n$endHour:$endMin',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.vt323(
                        fontSize: timeSize,
                        color: CrtTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasValidLink
                            ? CrtTheme.joinActive
                            : CrtTheme.joinDisabled,
                        disabledBackgroundColor: CrtTheme.joinDisabled,
                        disabledForegroundColor: CrtTheme.textSecondary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: compact ? 6 : 12,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: hasValidLink
                          ? () => launchUrl(Uri.parse(event.meetingLink!))
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam,
                              size: compact ? 16 : 18,
                              color: CrtTheme.textPrimary),
                          const SizedBox(height: 4),
                          Text(
                            'JOIN',
                            style: GoogleFonts.vt323(
                              fontSize: compact ? 12 : 14,
                              color: CrtTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 6 : 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: event.progress(currentTime),
                          minHeight: progressHeight,
                          backgroundColor: CrtTheme.clockFlap,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(event.progress(currentTime) * 100).toInt()}%',
                      style: GoogleFonts.vt323(
                        fontSize: compact ? 14 : 16,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
