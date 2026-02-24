import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';

class HeroCard extends StatelessWidget {
  final CalendarEvent event;
  final ValueNotifier<DateTime> now;

  const HeroCard({super.key, required this.event, required this.now});

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

        return Card(
          color: CrtTheme.background,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: CrtTheme.ongoing, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.summary,
                        style: GoogleFonts.vt323(
                          fontSize: 38,
                          color: CrtTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$startHour:$startMin\n$endHour:$endMin',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.vt323(
                        fontSize: 19,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                          Icon(Icons.videocam, size: 18, color: CrtTheme.textPrimary),
                          const SizedBox(height: 4),
                          Text(
                            'JOIN',
                            style: GoogleFonts.vt323(
                              fontSize: 14,
                              color: CrtTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: event.progress(currentTime),
                          minHeight: 12,
                          backgroundColor: CrtTheme.clockFlap,
                          color: CrtTheme.ongoing,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(event.progress(currentTime) * 100).toInt()}%',
                      style: GoogleFonts.vt323(
                        fontSize: 16,
                        color: CrtTheme.ongoing,
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
