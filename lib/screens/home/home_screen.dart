import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../services/ai_journal_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/cycle_card.dart';
import '../../widgets/cycle_ring.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/safe_asset_image.dart';
import '../../widgets/symptom_chip.dart';
import '../../widgets/user_avatar.dart';

const Map<String, String> _phaseInfo = {
  'Menstrual Phase':
      'Your uterine lining is shedding. Rest, stay warm and be gentle with '
          'yourself.',
  'Follicular Phase':
      'Energy starts to rise as your body prepares to ovulate. A great time '
          'to try something new.',
  'Ovulation Phase':
      'An egg is released. You may feel more social, confident and energetic.',
  'Luteal Phase':
      'Hormones shift and PMS symptoms can appear. You may feel lower in '
          'energy, so prioritise rest and nourishing food.',
};

String _tipFor(String phase) {
  switch (phase) {
    case 'Menstrual Phase':
      return 'Your body is working hard. Keep a heating pad close, sip '
          'something warm and rest when you can. 💕';
    case 'Follicular Phase':
      return 'Your energy is building. A walk or a light workout could feel '
          'great today. 🌿';
    case 'Ovulation Phase':
      return 'You may feel social and energetic. Stay hydrated and enjoy '
          'it! ✨';
    default:
      return AppStrings.forYouBody;
  }
}

String _countdown(int days) {
  if (days <= 0) return 'Today';
  if (days == 1) return '1 day';
  return '$days days';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showPhaseDetails(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.phase,
                style: AppTextStyles.headline
                    .copyWith(fontSize: 20, color: AppColors.crimson),
              ),
              const SizedBox(height: 4),
              Text(
                'Day ${state.cycleDay} of ${state.user.cycleLength}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Text(_phaseInfo[state.phase] ?? '', style: AppTextStyles.body),
              const SizedBox(height: 12),
              Text(
                'Next period expected ${Helpers.shortDate(state.nextPeriodDate)}',
                style: AppTextStyles.label.copyWith(color: AppColors.crimson),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Got it',
                height: 48,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;
    final ringSize = math.min(width * 0.66, 280.0);
    final entry = state.entryFor(Helpers.today);

    final moodDone = entry?.mood != null;
    final crampsDone = entry?.symptoms.contains('cramps') ?? false;
    final flowDone = entry?.isPeriodFlow ?? false;

    void openCheckIn() => Navigator.pushNamed(context, AppRoutes.checkIn);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<AppState>().setTab(4),
                    child: UserAvatar(
                      avatar: state.user.avatarAsset,
                      size: 46,
                      borderWidth: 1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.greeting(state.user.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(AppStrings.homeSubtitle,
                            style: AppTextStyles.bodyMuted),
                      ],
                    ),
                  ),
                  _BellButton(
                    count: 2,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.reminders),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Cycle ring ----
              Center(
                child: CycleRing(
                  progress: state.cycleProgress,
                  size: ringSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.phase == 'Menstrual Phase'
                            ? 'Period Day'
                            : AppStrings.periodMayStart,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.phase == 'Menstrual Phase'
                            ? '${state.cycleDay}'
                            : _countdown(state.daysUntilNextPeriod),
                        style: AppTextStyles.bigNumber.copyWith(fontSize: 38),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.phase == 'Menstrual Phase'
                            ? 'of ${state.user.periodLength} days'
                            : Helpers.shortDate(state.nextPeriodDate),
                        style: AppTextStyles.body.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded,
                          size: 12, color: AppColors.crimson),
                      SizedBox(width: 6),
                      Icon(Icons.favorite_rounded,
                          size: 16, color: AppColors.rose),
                      SizedBox(width: 6),
                      Icon(Icons.favorite_rounded,
                          size: 12, color: AppColors.crimson),
                      SizedBox(width: 6),
                      Icon(Icons.favorite_rounded,
                          size: 15, color: AppColors.rose),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // ---- Current phase ----
              CycleCard(
                phase: state.phase,
                day: state.cycleDay,
                total: state.user.cycleLength,
                onViewDetails: () => _showPhaseDetails(context, state),
              ),
              const SizedBox(height: 14),

              // ---- Today's Pad Recommendation & AI Journal ----
              _PadRecommendationHomeCard(
                recommendation: AiJournalService().recommendPadForState(state),
                onTap: () => Navigator.pushNamed(context, AppRoutes.journal),
              ),
              const SizedBox(height: 20),

              // ---- Today's check-in ----
              Text(AppStrings.todaysCheckIn, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 2),
              Text(AppStrings.howFeeling, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SymptomChip(
                    label: 'Mood',
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    selected: moodDone,
                    tint: AppColors.tintYellow,
                    iconColor: const Color(0xFFF2A900),
                    onTap: openCheckIn,
                  ),
                  SymptomChip(
                    label: 'Cramps',
                    icon: Icons.flash_on_rounded,
                    selected: crampsDone,
                    tint: AppColors.tintPink,
                    iconColor: AppColors.rose,
                    onTap: openCheckIn,
                  ),
                  SymptomChip(
                    label: 'Flow',
                    icon: Icons.water_drop_rounded,
                    selected: flowDone,
                    tint: AppColors.tintPink,
                    iconColor: AppColors.crimson,
                    onTap: openCheckIn,
                  ),
                  SymptomChip(
                    label: 'Energy',
                    icon: Icons.bolt_rounded,
                    selected: false,
                    tint: AppColors.tintOrange,
                    iconColor: const Color(0xFFF08A1C),
                    onTap: openCheckIn,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- For you today ----
              AppCard(
                color: const Color(0xFFFFE9EC),
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                onTap: () => Navigator.pushNamed(context, AppRoutes.wellness),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.forYouToday,
                              style: AppTextStyles.sectionTitle
                                  .copyWith(fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(
                            _tipFor(state.phase),
                            style: AppTextStyles.body.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const SafeAssetImage(
                      AppAssets.teaCup,
                      width: 96,
                      height: 96,
                      radius: 18,
                      fallbackIcon: Icons.emoji_food_beverage_rounded,
                    ),
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

class _BellButton extends StatelessWidget {
  const _BellButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifications',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: AppColors.crimson,
              ),
              if (count > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PadRecommendationHomeCard extends StatelessWidget {
  const _PadRecommendationHomeCard({
    required this.recommendation,
    required this.onTap,
  });

  final PadRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tintPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: AppColors.rose, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S RECOMMENDED PAD',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.rose,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      recommendation.padType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 13.5,
                        color: AppColors.crimson,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.rose, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.roseTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 14, color: AppColors.crimson),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${recommendation.products.length} brands (Carmesi, Nua, Stayfree...) match this type',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  'View →',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}