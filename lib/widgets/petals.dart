import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/colors.dart';

/// Draws one cherry-blossom petal pointing up from the origin.
void paintPetal(Canvas canvas, double r, Paint paint) {
  final path = Path()
    ..moveTo(0, 0)
    ..cubicTo(-r * 0.95, -r * 0.25, -r * 0.75, -r * 1.05, -r * 0.14, -r)
    ..lineTo(0, -r * 0.86)
    ..lineTo(r * 0.14, -r)
    ..cubicTo(r * 0.75, -r * 1.05, r * 0.95, -r * 0.25, 0, 0)
    ..close();
  canvas.drawPath(path, paint);
}

/// Draws a five-petal blossom centred on [c].
void paintBlossom(
  Canvas canvas,
  Offset c,
  double r,
  double rotation,
  double opacity,
) {
  final fill = Paint()..color = AppColors.roseLight.withOpacity(opacity);
  final edge = Paint()
    ..color = AppColors.rose.withOpacity(opacity * 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(rotation);
  for (var i = 0; i < 5; i++) {
    paintPetal(canvas, r, fill);
    paintPetal(canvas, r, edge);
    canvas.rotate(2 * math.pi / 5);
  }
  canvas.drawCircle(
    Offset.zero,
    r * 0.12,
    Paint()..color = AppColors.crimson.withOpacity(opacity),
  );
  canvas.restore();
}

/// Static blossom cluster used at the top-right of every screen.
class BlossomCornerPainter extends CustomPainter {
  const BlossomCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    paintBlossom(canvas, Offset(w * 0.74, h * 0.30), w * 0.16, 0.4, 0.55);
    paintBlossom(canvas, Offset(w * 0.40, h * 0.12), w * 0.09, 1.1, 0.40);
    paintBlossom(canvas, Offset(w * 0.92, h * 0.74), w * 0.10, 0.2, 0.45);

    final loose = Paint()..color = AppColors.roseLight.withOpacity(0.5);
    for (final p in [
      [0.55, 0.62, 0.9],
      [0.25, 0.40, -0.6],
      [0.82, 0.05, 2.1],
    ]) {
      canvas.save();
      canvas.translate(w * p[0], h * p[1]);
      canvas.rotate(p[2]);
      paintPetal(canvas, w * 0.05, loose);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Petal {
  const _Petal({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
    required this.rotation,
    required this.spin,
  });

  final double x;
  final double phase;
  final int speed;
  final double size;
  final double sway;
  final double rotation;
  final double spin;
}

/// Animated, looping falling-petal overlay (used on the splash screen).
class FallingPetals extends StatefulWidget {
  const FallingPetals({super.key, this.count = 16, this.opacity = 0.6});

  final int count;
  final double opacity;

  @override
  State<FallingPetals> createState() => _FallingPetalsState();
}

class _FallingPetalsState extends State<FallingPetals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final List<_Petal> _petals = List.generate(widget.count, (i) {
    final r = math.Random(i * 7 + 3);
    return _Petal(
      x: r.nextDouble(),
      phase: r.nextDouble(),
      speed: 1 + r.nextInt(2),
      size: 7 + r.nextDouble() * 8,
      sway: 10 + r.nextDouble() * 18,
      rotation: r.nextDouble() * math.pi * 2,
      spin: r.nextDouble() * 2 - 1,
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FallingPainter(_controller, _petals, widget.opacity),
        ),
      ),
    );
  }
}

class _FallingPainter extends CustomPainter {
  _FallingPainter(this.t, this.petals, this.opacity) : super(repaint: t);

  final Animation<double> t;
  final List<_Petal> petals;
  final double opacity;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    _paint.color = AppColors.roseLight.withOpacity(opacity);
    for (final p in petals) {
      final progress = (t.value * p.speed + p.phase) % 1.0;
      final y = -20 + progress * (size.height + 40);
      final x = p.x * size.width +
          math.sin((progress * 2 + p.phase) * math.pi * 2) * p.sway;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.spin * math.pi * 2);
      paintPetal(canvas, p.size, _paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}