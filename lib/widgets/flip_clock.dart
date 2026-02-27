import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/widgets/flip_digit.dart';

class FlipClock extends StatelessWidget {
  final ValueNotifier<DateTime> now;

  const FlipClock({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, dateTime, _) {
        final hour = dateTime.hour;
        final minute = dateTime.minute;
        final h1 = hour ~/ 10;
        final h2 = hour % 10;
        final m1 = minute ~/ 10;
        final m2 = minute % 10;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlipDigit(digit: h1),
            const SizedBox(width: 4),
            FlipDigit(digit: h2),
            const SizedBox(width: 8),
            Text(
              ':',
              style: GoogleFonts.vt323(
                fontSize: 110,
                color: CrtTheme.clockDigit,
              ),
            ),
            const SizedBox(width: 8),
            FlipDigit(digit: m1),
            const SizedBox(width: 4),
            FlipDigit(digit: m2),
          ],
        );
      },
    );
  }
}
