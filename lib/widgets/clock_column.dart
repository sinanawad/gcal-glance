import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/weather_condition.dart';
import 'package:gcal_glance/widgets/flip_clock.dart';

class ClockColumn extends StatelessWidget {
  final ValueNotifier<DateTime> now;
  final Widget? bottomContent;
  final bool isMuted;
  final VoidCallback? onToggleMute;
  final WeatherCondition? weather;

  const ClockColumn({
    super.key,
    required this.now,
    this.bottomContent,
    this.isMuted = false,
    this.onToggleMute,
    this.weather,
  });

  static const _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        color: CrtTheme.background,
        child: Column(
          children: [
            // Clock + date packed at the top
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 6, right: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: FlipClock(now: now),
              ),
            ),
            const SizedBox(height: 4),
            ValueListenableBuilder<DateTime>(
              valueListenable: now,
              builder: (context, dateTime, _) {
                final weekday = _weekdays[dateTime.weekday - 1];
                final day = dateTime.day.toString().padLeft(2, '0');
                final month = _months[dateTime.month - 1];
                final year = dateTime.year;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekday,
                      style: GoogleFonts.vt323(
                        fontSize: 28,
                        color: CrtTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Weather icon + temperature row, or plain date
                    if (weather != null && weather!.iconUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              weather!.iconUrl!,
                              width: 48,
                              height: 48,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox(width: 48, height: 48),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              weather!.temperatureDisplay,
                              style: GoogleFonts.vt323(
                                fontSize: 32,
                                color: CrtTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '$day $month $year',
                      style: GoogleFonts.vt323(
                        fontSize: 26,
                        color: CrtTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const Spacer(),
            ?bottomContent,
            const Spacer(),
            // Mute + Exit buttons at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onToggleMute != null)
                    IconButton(
                      icon: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                      ),
                      color: isMuted
                          ? CrtTheme.joinActive.withValues(alpha: 0.7)
                          : CrtTheme.textSecondary,
                      iconSize: 20,
                      onPressed: onToggleMute,
                      tooltip: isMuted ? 'Unmute (M)' : 'Mute (M)',
                    ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    color: CrtTheme.textSecondary,
                    iconSize: 20,
                    onPressed: () => SystemNavigator.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
