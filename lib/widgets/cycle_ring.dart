import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import 'petals.dart';

/// Circular cycle-progress ring with a handle at the arc end, a blossom on
/// the rim, and [child] centred inside. The arc animates in on first build.
class CycleRing extends StatelessWidget {
  const CycleRing({
    super.key,
    required this.progress,
    required this.size,
    required this.child,
  });

  final double progress;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: progress.clamp(0.0, 1.0).toDouble(),
      ),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: CycleRingPainter(value),
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
          ),
        ),
      ),
    );
  }
}

class CycleRingPainter extends CustomPainter {
  CycleRingPainter(this.progress);

  final double progress;
  static const double _stroke = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke - 6;
    final rect = Rect.fromCircle(center: c, radius: radius);

    // Soft inner disc and light track.
    canvas.drawCircle(
      c,
      radius - _stroke / 2,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.roseLight.withOpacity(0.35),
    );

    if (progress > 0.005) {
      final sweep = progress * 2 * math.pi;
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [AppColors.rose, AppColors.crimsonDark],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

      // Handle at the end of the arc.
      final end = -math.pi / 2 + sweep;
      final hp = c + Offset(math.cos(end), math.sin(end)) * radius;
      canvas.drawCircle(
        hp,
        _stroke * 0.95,
        Paint()
          ..color = Colors.black.withOpacity(0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(hp, _stroke * 0.85, Paint()..color = Colors.white);
      canvas.drawCircle(hp, _stroke * 0.5, Paint()..color = AppColors.crimson);
    }

    // Blossom on the lower-right rim.
    const blossomAngle = math.pi * 0.22;
    paintBlossom(
      canvas,
      c + Offset(math.cos(blossomAngle), math.sin(blossomAngle)) * (radius + 2),
      size.width * 0.065,
      0.3,
      0.95,
    );

    // One loose petal on the upper-right.
    const petalAngle = -0.45;
    canvas.save();
    canvas.translate(
      c.dx + math.cos(petalAngle) * (radius + 14),
      c.dy + math.sin(petalAngle) * (radius + 14),
    );
    canvas.rotate(0.8);
    paintPetal(
      canvas,
      size.width * 0.035,
      Paint()..color = AppColors.roseLight.withOpacity(0.8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}