import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';

/// Circular selectable icon with a label underneath. Used for symptoms and
/// the Home quick check-in buttons (pass [tint]/[iconColor] to colour them).
class SymptomChip extends StatelessWidget {
  const SymptomChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.size = 50,
    this.tint,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final Color? tint;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size + 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.crimson
                      : (tint ?? const Color(0xFFFFEEF1)),
                  border: Border.all(
                    color: selected ? AppColors.crimsonDark : AppColors.roseLight,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: size * 0.46,
                  color: selected
                      ? Colors.white
                      : (iconColor ?? AppColors.rose),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  color: selected ? AppColors.crimson : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}