import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Image.asset with a gradient + icon fallback so the app runs without assets.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.radius = 0,
    this.fallbackIcon = Icons.local_florist_rounded,
    this.fallbackColors = const [Color(0xFFFFD9DF), Color(0xFFF4A6B5)],
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final double radius;
  final IconData fallbackIcon;
  final List<Color> fallbackColors;

  @override
  Widget build(BuildContext context) {
    final iconSize = math.min(
          (width != null && width!.isFinite) ? width! : 80,
          (height != null && height!.isFinite) ? height! : 80,
        ) *
        0.45;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: fallbackColors,
            ),
          ),
          child: Icon(
            fallbackIcon,
            size: iconSize,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}