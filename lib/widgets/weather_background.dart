import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/weather_condition.dart';

/// Renders atmospheric weather visuals behind the date area.
///
/// Uses ambient color washes, soft glows, and subtle gradients rather than
/// literal icon shapes. Keeps everything at low opacity so date text stays
/// legible against the CRT background.
class WeatherBackgroundPainter extends CustomPainter {
  final WeatherCondition condition;
  final double animationValue; // 0.0–1.0 for particle animation

  WeatherBackgroundPainter({
    required this.condition,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    switch (condition.category) {
      case WeatherCategory.clear:
        _drawClear(canvas, size);
      case WeatherCategory.partlyCloudy:
        _drawPartlyCloudy(canvas, size);
      case WeatherCategory.cloudy:
        _drawCloudy(canvas, size);
      case WeatherCategory.fog:
        _drawFog(canvas, size);
      case WeatherCategory.rain:
        _drawRain(canvas, size);
      case WeatherCategory.snow:
        _drawSnow(canvas, size);
      case WeatherCategory.thunderstorm:
        _drawThunderstorm(canvas, size);
    }
  }

  @override
  bool shouldRepaint(WeatherBackgroundPainter oldDelegate) {
    return oldDelegate.condition.category != condition.category ||
        oldDelegate.condition.isDaytime != condition.isDaytime ||
        oldDelegate.animationValue != animationValue;
  }

  // ─── Weather visuals ──────────────────────────────────────

  void _drawClear(Canvas canvas, Size size) {
    if (condition.isDaytime) {
      // Warm golden radial glow from upper-right
      final center = Offset(size.width * 0.8, size.height * 0.1);
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width * 0.7,
          [
            CrtTheme.upcoming.withValues(alpha: 0.18),
            CrtTheme.upcoming.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

      // Soft sun disc
      final sunPaint = Paint()
        ..color = CrtTheme.upcoming.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(center, size.width * 0.09, sunPaint);
    } else {
      // Cool night ambient glow
      final center = Offset(size.width * 0.75, size.height * 0.25);
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width * 0.6,
          [
            const Color(0xFF4466aa).withValues(alpha: 0.10),
            const Color(0xFF334488).withValues(alpha: 0.04),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

      // Crescent moon glow
      final moonPaint = Paint()
        ..color = const Color(0xFFccddff).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        7,
        moonPaint,
      );

      _drawStars(canvas, size, 0.16);
    }
  }

  void _drawPartlyCloudy(Canvas canvas, Size size) {
    if (condition.isDaytime) {
      // Subtle warm glow on upper-left
      final sunCenter = Offset(size.width * 0.2, size.height * 0.15);
      final sunPaint = Paint()
        ..shader = ui.Gradient.radial(
          sunCenter,
          size.width * 0.5,
          [
            CrtTheme.upcoming.withValues(alpha: 0.12),
            CrtTheme.upcoming.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          [0.0, 0.4, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sunPaint);
    } else {
      _drawStars(canvas, size, 0.08);
    }

    // Soft cloud mass on right side
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.68, size.height * 0.55),
      size.width * 0.32,
      0.10,
    );
  }

  void _drawCloudy(Canvas canvas, Size size) {
    // Multiple layered soft cloud masses
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.28, size.height * 0.32),
      size.width * 0.32,
      0.08,
    );
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.72, size.height * 0.52),
      size.width * 0.28,
      0.07,
    );
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.48, size.height * 0.72),
      size.width * 0.36,
      0.05,
    );
  }

  void _drawFog(Canvas canvas, Size size) {
    // Layered horizontal fog bands with soft blur
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    const bands = [0.25, 0.42, 0.58, 0.75];
    const alphas = [0.07, 0.10, 0.09, 0.05];

    for (var i = 0; i < bands.length; i++) {
      paint.color = CrtTheme.textSecondary.withValues(alpha: alphas[i]);
      final y = size.height * bands[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y),
            width: size.width * 0.88,
            height: 5,
          ),
          const Radius.circular(2.5),
        ),
        paint,
      );
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    // Cool blue ambient tint, darker at bottom
    final tintPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          const Color(0xFF3366aa).withValues(alpha: 0.05),
          const Color(0xFF3366aa).withValues(alpha: 0.10),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    // Animated rain streaks
    final paint = Paint()
      ..color = CrtTheme.ongoing.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final rng = Random(42);
    const dropCount = 14;

    for (var i = 0; i < dropCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final len = 5.0 + rng.nextDouble() * 6.0;
      final speed = 0.8 + rng.nextDouble() * 0.4;

      final y = (baseY + animationValue * size.height * speed) %
              (size.height + len) -
          len;
      final x = baseX - animationValue * 3;

      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + len), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    // Cool blue-white ambient tint
    final tintPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          const Color(0xFFaabbdd).withValues(alpha: 0.05),
          const Color(0xFF8899bb).withValues(alpha: 0.08),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    // Gently floating snowflakes with soft blur
    final paint = Paint()
      ..color = CrtTheme.textPrimary.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final rng = Random(37);
    const flakeCount = 10;

    for (var i = 0; i < flakeCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 1.0 + rng.nextDouble() * 1.2;

      final y = (baseY + animationValue * size.height * 0.5) % size.height;
      final sway = sin((animationValue + i * 0.3) * pi * 2) * 5;
      final x = baseX + sway;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawThunderstorm(Canvas canvas, Size size) {
    // Dark stormy ambient tint
    final tintPaint = Paint()
      ..color = const Color(0xFF222244).withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    // Rain underneath
    _drawRain(canvas, size);

    // Brief lightning flash at certain animation phases
    final flashPhase = (animationValue * 5) % 1.0;
    if (flashPhase < 0.06) {
      final flashPaint = Paint()
        ..color = CrtTheme.upcoming.withValues(alpha: 0.15);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        flashPaint,
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────

  void _drawStars(Canvas canvas, Size size, double alpha) {
    final paint = Paint()
      ..color = CrtTheme.textSecondary.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final rng = Random(99);
    for (var i = 0; i < 5; i++) {
      final x = 6.0 + rng.nextDouble() * (size.width - 12);
      final y = 4.0 + rng.nextDouble() * (size.height - 8);
      canvas.drawCircle(Offset(x, y), 0.8 + rng.nextDouble() * 0.4, paint);
    }
  }

  void _drawSoftCloud(
    Canvas canvas,
    Offset center,
    double width,
    double alpha,
  ) {
    final paint = Paint()
      ..color = CrtTheme.textSecondary.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Overlapping soft circles form a natural cloud shape
    canvas.drawCircle(center, width * 0.28, paint);
    canvas.drawCircle(
      Offset(center.dx - width * 0.2, center.dy + 2),
      width * 0.20,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.22, center.dy + 2),
      width * 0.23,
      paint,
    );
  }
}

/// Wraps [WeatherBackgroundPainter] with an [AnimationController] for
/// particle animations. Only runs the controller when the condition
/// is animated (rain, snow, thunderstorm).
class AnimatedWeatherBackground extends StatefulWidget {
  final WeatherCondition? condition;

  const AnimatedWeatherBackground({super.key, this.condition});

  @override
  State<AnimatedWeatherBackground> createState() =>
      _AnimatedWeatherBackgroundState();
}

class _AnimatedWeatherBackgroundState extends State<AnimatedWeatherBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(AnimatedWeatherBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition?.category != widget.condition?.category) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.condition?.isAnimated == true) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final condition = widget.condition;
    if (condition == null) return const SizedBox.shrink();

    if (condition.isAnimated) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: WeatherBackgroundPainter(
              condition: condition,
              animationValue: _controller.value,
            ),
          );
        },
      );
    }

    return CustomPaint(
      painter: WeatherBackgroundPainter(condition: condition),
    );
  }
}
