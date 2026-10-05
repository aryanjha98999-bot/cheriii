import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/constants/strings.dart';
import '../core/theme/app_theme.dart';
import 'app_card.dart';

/// "Current Phase" card shown on the Home dashboard.
class CycleCard extends StatelessWidget {
  const CycleCard({
    super.key,
    required this.phase,
    required this.day,
    required this.total,
    this.onViewDetails,
  });

  final String phase;
  final int day;
  final int total;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.roseTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: AppColors.crimson,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.currentPhase, style: AppTextStyles.caption),
                Text(
                  phase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: AppColors.crimson),
                ),
                Text('Day $day of $total', style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.roseLight),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onViewDetails,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  AppStrings.viewDetails,
                  style: AppTextStyles.link.copyWith(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}