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

class _Article {
  const _Article({
    required this.id,
    required this.title,
    required this.minutes,
    required this.asset,
    required this.icon,
    required this.categories,
    required this.summary,
  });

  final String id;
  final String title;
  final int minutes;
  final String asset;
  final IconData icon;
  final List<String> categories;
  final String summary;
}

const List<_Article> _articles = [
  _Article(
    id: 'cycle',
    title: 'Understanding Your Menstrual Cycle',
    minutes: 5,
    asset: AppAssets.articleCycle,
    icon: Icons.autorenew_rounded,
    categories: ['Period Basics', 'Body'],
    summary:
        'Your cycle is counted from the first day of one period to the day '
        'before the next. It has four phases: menstrual, follicular, '
        'ovulation and luteal. Hormones rise and fall through each phase, '
        'which is why your energy, mood and symptoms change. A typical cycle '
        'lasts between 21 and 35 days.',
  ),
  _Article(
    id: 'cramps',
    title: 'How to Relieve Period Cramps',
    minutes: 7,
    asset: AppAssets.articleCramps,
    icon: Icons.healing_rounded,
    categories: ['Self-Care', 'Period Basics'],
    summary:
        'Cramps come from the uterus contracting to shed its lining. Heat, '
        'gentle movement, water and rest often help, and over-the-counter '
        'pain relief can be used as directed on the label. See a doctor if '
        'the pain is severe, getting worse, or stops you doing everyday '
        'things.',
  ),
  _Article(
    id: 'foods',
    title: 'Foods That Support Your Cycle',
    minutes: 5,
    asset: AppAssets.articleFoods,
    icon: Icons.restaurant_rounded,
    categories: ['Self-Care', 'Body'],
    summary:
        'Iron-rich foods like leafy greens and lentils, magnesium sources '
        'like nuts and seeds, and plenty of water can help you feel steadier '
        'through your cycle. Limiting very salty and sugary snacks may ease '
        'bloating and energy dips.',
  ),
  _Article(
    id: 'irregular',
    title: 'Is It Okay to Have Irregular Periods?',
    minutes: 6,
    asset: AppAssets.articleIrregular,
    icon: Icons.help_outline_rounded,
    categories: ['Body', 'Period Basics'],
    summary:
        'Cycles can vary by a few days, and are often less predictable in '
        'the first years after periods begin. Stress, big changes in weight '
        'and heavy exercise can also shift your timing. Track a few months of '
        'data, and talk to a doctor if periods are missing, very infrequent '
        'or very heavy.',
  ),
  _Article(
    id: 'myths',
    title: 'Period Myths vs Facts',
    minutes: 5,
    asset: AppAssets.articleMyths,
    icon: Icons.fact_check_rounded,
    categories: ['Period Basics'],
    summary:
        'Myth: you cannot exercise on your period. Fact: movement often '
        'eases cramps. Myth: you should avoid washing your hair. Fact: '
        'normal hygiene is safe and healthy. Myth: period blood is dirty. '
        'Fact: it is blood and uterine lining, and completely natural.',
  ),
];

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const List<String> _filters = [
    'All',
    'Period Basics',
    'Self-Care',
    'Body',
  ];

  int _filter = 0;

  void _open(_Article a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
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
                  a.title,
                  style: AppTextStyles.headline
                      .copyWith(fontSize: 20, color: AppColors.crimson),
                ),
                const SizedBox(height: 4),
                Text('${a.minutes} min read', style: AppTextStyles.caption),
                const SizedBox(height: 14),
                Text(a.summary, style: AppTextStyles.body.copyWith(fontSize: 14)),
                const SizedBox(height: 14),
                Text(
                  'This is general information, not medical advice. Talk to '
                  'a doctor if something worries you.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Close',
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
    final state = context.watch<AppState>();
    final label = _filters[_filter];
    final visible = _articles
        .where((a) => label == 'All' || a.categories.contains(label))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Learn & Explore'),
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
                  final a = visible[i];
                  final saved = state.isBookmarked(a.id);
                  return AppCard(
                    padding: const EdgeInsets.all(10),
                    onTap: () => _open(a),
                    child: Row(
                      children: [
                        SafeAssetImage(
                          a.asset,
                          width: 72,
                          height: 72,
                          radius: 14,
                          fallbackIcon: a.icon,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 4),
                              Text('${a.minutes} min read',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: saved ? 'Remove bookmark' : 'Bookmark',
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: AppColors.crimson,
                          ),
                          onPressed: () => context
                              .read<AppState>()
                              .toggleBookmark(a.id),
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