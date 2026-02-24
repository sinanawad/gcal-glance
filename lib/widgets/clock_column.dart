import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/widgets/flip_clock.dart';

class ClockColumn extends StatelessWidget {
  final ValueNotifier<DateTime> now;
  final Widget? bottomContent;

  const ClockColumn({super.key, required this.now, this.bottomContent});

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
                  children: [
                    Text(
                      weekday,
                      style: GoogleFonts.vt323(
                        fontSize: 28,
                        color: CrtTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
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
            // Exit button at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: CrtTheme.textSecondary,
                iconSize: 20,
                onPressed: () => SystemNavigator.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
