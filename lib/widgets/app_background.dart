import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import 'petals.dart';

/// Soft pink gradient with faint blossoms at the top-right.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.petals = true});

  final Widget child;
  final bool petals;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          if (petals)
            const Positioned(
              top: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 190,
                  height: 150,
                  child: CustomPaint(painter: BlossomCornerPainter()),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}