import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/safe_asset_image.dart';

class _WellnessItem {
  const _WellnessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.asset,
    required this.icon,
    required this.categories,
    required this.steps,
    this.breathing = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String action;
  final String asset;
  final IconData icon;
  final List<String> categories;
  final List<String> steps;
  final bool breathing;
}

const List<_WellnessItem> _items = [
  _WellnessItem(
    id: 'yoga',
    title: 'Gentle Yoga',
    subtitle: '10 min • For Cramps',
    action: 'Play',
    asset: AppAssets.yoga,
    icon: Icons.self_improvement_rounded,
    categories: ['Exercise', 'Relax'],
    steps: [
      "Child's pose: rest for 1 minute and breathe slowly.",
      'Cat-cow: move through 8 slow rounds.',
      'Supine twist: hold 1 minute on each side.',
      'Legs up the wall: stay for 3 minutes.',
      'Finish lying down and rest for 2 minutes.',
      'Stop any move that hurts and go at your own pace.',
    ],
  ),
  _WellnessItem(
    id: 'breathing',
    title: 'Breathing Exercise',
    subtitle: '5 min • Calm your mind',
    action: 'Play',
    asset: AppAssets.breathing,
    icon: Icons.air_rounded,
    categories: ['Relax', 'Mind'],
    breathing: true,
    steps: [
      'Sit comfortably and relax your shoulders.',
      'Breathe in through your nose as the circle grows.',
      'Breathe out slowly as it shrinks.',
      'Keep going for about 5 minutes.',
    ],
  ),
  _WellnessItem(
    id: 'foods',
    title: 'Healthy Foods',
    subtitle: 'For your cycle phase',
    action: 'View',
    asset: AppAssets.healthyFoods,
    icon: Icons.restaurant_rounded,
    categories: ['Nutrition'],
    steps: [],
  ),
  _WellnessItem(
    id: 'selfcare',
    title: 'Self-Care Tips',
    subtitle: 'Feel better naturally',
    action: 'View',
    asset: AppAssets.selfCare,
    icon: Icons.spa_rounded,
    categories: ['Relax', 'Mind'],
    steps: [
      'Use a warm shower or heating pad to ease tension.',
      'Do gentle stretches or a slow walk.',
      'Cut screen time before bed for deeper sleep.',
      'Write down how you feel in a short journal entry.',
      'Say no to extra commitments when you are low on energy.',
    ],
  ),
];

List<String> _foodTips(String phase) {
  switch (phase) {
    case 'Menstrual Phase':
      return [
        'Iron: leafy greens, lentils, beans and dates.',
        'Warm foods: soups, khichdi and herbal tea.',
        'Vitamin C (citrus, amla) helps iron absorption.',
        'Stay hydrated with water and coconut water.',
      ];
    case 'Follicular Phase':
      return [
        'Fresh veggies and fruit for rising energy.',
        'Lean protein: eggs, paneer, tofu or chickpeas.',
        'Fermented foods like curd for gut health.',
        'Whole grains for steady fuel.',
      ];
    case 'Ovulation Phase':
      return [
        'Fibre-rich foods: oats, beans, berries.',
        'Colourful vegetables for antioxidants.',
        'Healthy fats: nuts, seeds, avocado.',
        'Plenty of water as body temperature rises.',
      ];
    default:
      return [
        'Magnesium: nuts, seeds and dark chocolate.',
        'Complex carbs: oats, brown rice, sweet potato.',
        'Calcium and vitamin B6: curd, bananas, chickpeas.',
        'Go easy on very salty and sugary snacks.',
      ];
  }
}

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  static const List<String> _filters = [
    'All',
    'Relax',
    'Exercise',
    'Nutrition',
    'Mind',
  ];

  int _filter = 0;

  void _open(_WellnessItem item) {
    final phase = context.read<AppState>().phase;
    final steps = item.id == 'foods' ? _foodTips(phase) : item.steps;
    final meta = item.id == 'foods' ? 'For your $phase' : item.subtitle;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: AppTextStyles.headline
                      .copyWith(fontSize: 22, color: AppColors.crimson),
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppTextStyles.bodyMuted),
                if (item.breathing) ...[
                  const SizedBox(height: 16),
                  const Center(child: _BreathingCircle()),
                ],
                const SizedBox(height: 16),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.roseTint,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.crimson,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(steps[i], style: AppTextStyles.body),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Done',
                  height: 48,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _filters[_filter];
    final visible = _items
        .where((i) => label == 'All' || i.categories.contains(label))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Wellness Hub'),
            PillTabs(
              labels: _filters,
              selectedIndex: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = visible[i];
                  return AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    onTap: () => _open(item),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTextStyles.cardTitle
                                    .copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(item.subtitle,
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                label: item.action,
                                expand: false,
                                height: 34,
                                fontSize: 12,
                                horizontalPadding: 22,
                                onPressed: () => _open(item),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SafeAssetImage(
                          item.asset,
                          width: 112,
                          height: 96,
                          radius: 16,
                          fallbackIcon: item.icon,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanding / shrinking circle that paces slow breathing.
class _BreathingCircle extends StatefulWidget {
  const _BreathingCircle();

  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final inhale = _c.status == AnimationStatus.forward;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.roseLight, AppColors.rose],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withOpacity(0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                inhale ? 'Breathe in' : 'Breathe out',
                style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}