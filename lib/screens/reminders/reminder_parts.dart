import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_state.dart';

class ReminderItem {
  const ReminderItem({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.background,
  });

  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color background;
}

class StyleOption {
  const StyleOption(this.style, this.title, this.subtitle);

  final NotificationStyle style;
  final String title;
  final String? subtitle;
}

class StyleRow extends StatelessWidget {
  const StyleRow({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StyleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RadioDot(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      style: AppTextStyles.cardTitle
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (option.subtitle != null)
                      Text(option.subtitle!, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? AppColors.crimson : AppColors.textSecondary,
          width: selected ? 2 : 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: selected ? 10 : 0,
        height: selected ? 10 : 0,
        decoration: const BoxDecoration(
          color: AppColors.crimson,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}