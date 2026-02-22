import 'package:flutter/material.dart';

class ClockWidget extends StatelessWidget {
  final DateTime now;

  const ClockWidget({super.key, required this.now});

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final weekday = _weekdays[now.weekday - 1];

    return Text(
      '$hour:$minute - $day/$month/$year ($weekday)',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
