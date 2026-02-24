import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_event.dart';

class TimelineStrip extends StatelessWidget {
  final List<CalendarEvent> events;
  final ValueNotifier<DateTime> now;

  const TimelineStrip({
    super.key,
    required this.events,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, currentTime, _) {
        return Container(
          height: 88,
          color: CrtTheme.timelineBg,
          child: ClipRect(
            child: CustomPaint(
              size: const Size(double.infinity, 88),
              painter: _TimelinePainter(
                events: events,
                now: currentTime,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<CalendarEvent> events;
  final DateTime now;

  /// NOW is always at 25% of the width.
  static const double _nowFraction = 0.25;

  /// Total viewport span: 5 hours.
  static const int _viewportMinutes = 5 * 60;

  _TimelinePainter({
    required this.events,
    required this.now,
  });

  late DateTime _viewportStart;
  late DateTime _viewportEnd;

  @override
  void paint(Canvas canvas, Size size) {
    // Viewport: NOW sits at 25% → 1.25h before now, 3.75h after now.
    _viewportStart = now.subtract(
        Duration(minutes: (_nowFraction * _viewportMinutes).round()));
    _viewportEnd = now.add(
        Duration(minutes: ((1 - _nowFraction) * _viewportMinutes).round()));

    _drawHourMarkers(canvas, size);
    _drawEventBlocks(canvas, size);
    _drawNowMarker(canvas, size);
    _drawNowCountdown(canvas, size);
  }

  double _timeToX(DateTime time, Size size) {
    final minutes = time.difference(_viewportStart).inMinutes;
    return (minutes / _viewportMinutes) * size.width;
  }

  void _drawHourMarkers(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = CrtTheme.textSecondary.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    // Start from the first full hour within (or just before) the viewport.
    DateTime hour = DateTime(
      _viewportStart.year,
      _viewportStart.month,
      _viewportStart.day,
      _viewportStart.hour,
    );
    if (hour.isBefore(_viewportStart)) {
      hour = hour.add(const Duration(hours: 1));
    }

    while (hour.isBefore(_viewportEnd)) {
      final x = _timeToX(hour, size);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${hour.hour.toString().padLeft(2, '0')}:00',
          style: GoogleFonts.vt323(
            color: CrtTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 3, 2));

      hour = hour.add(const Duration(hours: 1));
    }
  }

  void _drawEventBlocks(Canvas canvas, Size size) {
    // Assign each event a stable index for alternating visuals.
    // Sort by start time so the pattern is consistent.
    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // First pass: detect overlaps. Build a list of overlap regions.
    final overlapRegions = <Rect>[];

    for (var i = 0; i < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        final a = sorted[i];
        final b = sorted[j];
        // Overlap exists if a.start < b.end && b.start < a.end
        if (a.startTime.isBefore(b.endTime) &&
            b.startTime.isBefore(a.endTime)) {
          final overlapStart =
              a.startTime.isAfter(b.startTime) ? a.startTime : b.startTime;
          final overlapEnd =
              a.endTime.isBefore(b.endTime) ? a.endTime : b.endTime;
          final ox1 = _timeToX(overlapStart, size);
          final ox2 = _timeToX(overlapEnd, size);
          overlapRegions
              .add(Rect.fromLTWH(ox1, 18, max(ox2 - ox1, 2.0), 52));
        }
      }
    }

    // Second pass: draw each event block.
    for (var i = 0; i < sorted.length; i++) {
      final event = sorted[i];
      final x1 = _timeToX(event.startTime, size);
      final x2 = _timeToX(event.endTime, size);
      final blockWidth = max(x2 - x1, 2.0);

      final status = event.status(now);
      final Color statusColor;
      switch (status) {
        case EventStatus.ongoing:
          statusColor = CrtTheme.ongoing;
        case EventStatus.upcoming:
          statusColor = CrtTheme.upcoming;
        case EventStatus.normal:
          statusColor = CrtTheme.normal;
      }

      // Alternating fill: even events are solid, odd events use horizontal lines.
      final blockRect = Rect.fromLTWH(x1, 18, blockWidth, 52);
      final rrect = RRect.fromRectAndRadius(blockRect, const Radius.circular(4));

      if (i.isEven) {
        // Solid fill
        final fillPaint = Paint()..color = statusColor.withValues(alpha: 0.55);
        canvas.drawRRect(rrect, fillPaint);
      } else {
        // Horizontal stripe fill
        final fillPaint = Paint()..color = statusColor.withValues(alpha: 0.25);
        canvas.drawRRect(rrect, fillPaint);

        canvas.save();
        canvas.clipRRect(rrect);
        final stripePaint = Paint()
          ..color = statusColor.withValues(alpha: 0.5)
          ..strokeWidth = 2;
        for (double y = 20; y < 70; y += 8) {
          canvas.drawLine(Offset(x1, y), Offset(x1 + blockWidth, y), stripePaint);
        }
        canvas.restore();
      }

      // Border outline
      final borderPaint = Paint()
        ..color = statusColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Third pass: draw diagonal hatching on overlap regions.
    for (final region in overlapRegions) {
      final rrect =
          RRect.fromRectAndRadius(region, const Radius.circular(4));
      canvas.save();
      canvas.clipRRect(rrect);

      final hatchPaint = Paint()
        ..color = CrtTheme.textPrimary.withValues(alpha: 0.3)
        ..strokeWidth = 1.5;

      // Diagonal lines from bottom-left to top-right.
      const spacing = 8.0;
      final totalDiag = region.width + region.height;
      for (double d = 0; d < totalDiag; d += spacing) {
        final x1h = region.left + d;
        final y1h = region.bottom;
        final x2h = region.left + d - region.height;
        final y2h = region.top;
        canvas.drawLine(Offset(x1h, y1h), Offset(x2h, y2h), hatchPaint);
      }
      canvas.restore();
    }
  }

  void _drawNowMarker(Canvas canvas, Size size) {
    final nowX = _timeToX(now, size);
    final markerPaint = Paint()
      ..color = CrtTheme.textPrimary
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(nowX, 0),
      Offset(nowX, size.height),
      markerPaint,
    );

    // Downward triangle at top
    final trianglePath = Path()
      ..moveTo(nowX - 6, 8)
      ..lineTo(nowX + 6, 8)
      ..lineTo(nowX, 16)
      ..close();
    canvas.drawPath(
      trianglePath,
      Paint()..color = CrtTheme.textPrimary,
    );
  }

  void _drawNowCountdown(Canvas canvas, Size size) {
    final nowX = _timeToX(now, size);
    String? text;

    final ongoingEvents = events
        .where((e) => e.status(now) == EventStatus.ongoing)
        .toList();

    if (ongoingEvents.isNotEmpty) {
      ongoingEvents.sort((a, b) => a.endTime.compareTo(b.endTime));
      final soonest = ongoingEvents.first;
      final countdown = soonest.endTime.difference(now);
      text = '${countdown.inMinutes}m';
    } else {
      final futureEvents =
          events.where((e) => e.startTime.isAfter(now)).toList();
      if (futureEvents.isNotEmpty) {
        futureEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        final nextEvent = futureEvents.first;
        final untilStart = nextEvent.startTime.difference(now);
        if (untilStart.inMinutes <= 60) {
          text = 'next ${untilStart.inMinutes}m';
        }
      }
    }

    if (text != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.vt323(
            fontSize: 22,
            color: CrtTheme.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final textY = (size.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(nowX + 4, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return now != oldDelegate.now ||
        events.length != oldDelegate.events.length;
  }
}
