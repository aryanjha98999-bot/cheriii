import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';

/// List row with leading icon, title, optional subtitle and trailing widget.
/// Used by Profile, Reminders and App Lock.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.iconColor = AppColors.crimson,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color iconColor;

  /// When set, the icon sits in a rounded tinted square of this colour.
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing ??
        (showChevron
            ? const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              )
            : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (iconBackground != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              )
            else
              SizedBox(
                width: 28,
                child: Icon(icon, color: iconColor, size: 22),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }
}