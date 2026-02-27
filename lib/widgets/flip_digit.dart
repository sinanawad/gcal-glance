import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';

class FlipDigit extends StatefulWidget {
  final int digit;

  const FlipDigit({super.key, required this.digit});

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentDigit = 0;
  int _previousDigit = 0;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _previousDigit = widget.digit;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = oldWidget.digit;
      _currentDigit = widget.digit;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            children: [
              // Static bottom half — shows new digit, always visible.
              _buildHalf(
                digit: _currentDigit,
                alignment: Alignment.bottomCenter,
              ),
              // Static top half — shows new digit, visible after flip completes.
              if (t >= 1.0)
                _buildHalf(
                  digit: _currentDigit,
                  alignment: Alignment.topCenter,
                ),
              // Animated top flap — old digit flipping down (0 → π/2).
              if (t < 1.0)
                _buildAnimatedFlap(
                  digit: t == 0.0 ? _currentDigit : _previousDigit,
                  alignment: Alignment.topCenter,
                  angle: t * pi / 2,
                  opacity: t <= 0.5 ? 1.0 : 1.0 - (t - 0.5) * 2.0,
                ),
              // Animated bottom flap — new digit revealing (-π/2 → 0).
              if (t > 0.5)
                _buildAnimatedFlap(
                  digit: _currentDigit,
                  alignment: Alignment.bottomCenter,
                  angle: -pi / 2 * (1.0 - (t - 0.5) * 2.0),
                  opacity: 1.0,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHalf({required int digit, required Alignment alignment}) {
    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: alignment,
          heightFactor: 0.5,
          child: _digitContainer(digit),
        ),
      ),
    );
  }

  Widget _buildAnimatedFlap({
    required int digit,
    required Alignment alignment,
    required double angle,
    required double opacity,
  }) {
    final isTop = alignment == Alignment.topCenter;
    return Positioned.fill(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        child: Transform(
          alignment: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.003)
            ..rotateX(angle),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: ClipRect(
              child: Align(
                alignment: alignment,
                heightFactor: 0.5,
                child: _digitContainer(digit),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _digitContainer(int digit) {
    return Container(
      width: 60,
      height: 180,
      decoration: BoxDecoration(
        color: CrtTheme.clockFlap,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$digit',
        style: GoogleFonts.vt323(
          fontSize: 110,
          color: CrtTheme.clockDigit,
        ),
      ),
    );
  }
}
