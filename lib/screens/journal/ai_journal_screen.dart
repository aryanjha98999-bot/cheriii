import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../services/ai_journal_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';

class AiJournalScreen extends StatefulWidget {
  const AiJournalScreen({super.key});

  @override
  State<AiJournalScreen> createState() => _AiJournalScreenState();
}

class _AiJournalScreenState extends State<AiJournalScreen> {
  final AiJournalService _service = AiJournalService();
  JournalEntry? _todayJournal;
  List<JournalEntry> _pastJournals = [];
  bool _loading = true;
  bool _showPadDetail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJournal());
  }

  Future<void> _loadJournal() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    try {
      final today = await _service.getTodayJournal(state);
      final past = await _service.getPastJournals();
      if (mounted) {
        setState(() {
          _todayJournal = today;
          _pastJournals = past.where((j) => !_isSameDay(j.date, today.date)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Column(
        children: [
          const AppHeader(title: 'My Daily Journal', showBack: true),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.rose),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_todayJournal != null) ...[
                          _TodayJournalCard(
                            journal: _todayJournal!,
                            showPadDetail: _showPadDetail,
                            onTogglePad: () =>
                                setState(() => _showPadDetail = !_showPadDetail),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_pastJournals.isNotEmpty) ...[
                          Text('Recent Journals',
                              style: AppTextStyles.sectionTitle
                                  .copyWith(fontSize: 15)),
                          const SizedBox(height: 10),
                          ..._pastJournals.map(
                            (j) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PastJournalCard(journal: j),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Today's Journal Card
// ----------------------------------------------------------------

class _TodayJournalCard extends StatelessWidget {
  const _TodayJournalCard({
    required this.journal,
    required this.showPadDetail,
    required this.onTogglePad,
  });

  final JournalEntry journal;
  final bool showPadDetail;
  final VoidCallback onTogglePad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Text(
          "Today's Journal",
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 8),

        // Main journal card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: AppColors.rose, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      journal.headline,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 16,
                        color: AppColors.crimson,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Body text
              Text(
                journal.body,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 16),
              const _Divider(),
              const SizedBox(height: 14),

              // Tips section
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: AppColors.rose),
                  const SizedBox(width: 6),
                  Text(
                    'Tips For Today',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...journal.tips.map((tip) => _TipRow(tip: tip)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Pad recommendation card
        _PadRecommendationDetailCard(
          recommendation: journal.padRecommendation,
          expanded: showPadDetail,
          onToggle: onTogglePad,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
// Pad Recommendation Detail Card
// ----------------------------------------------------------------

class _PadRecommendationDetailCard extends StatelessWidget {
  const _PadRecommendationDetailCard({
    required this.recommendation,
    required this.expanded,
    required this.onToggle,
  });

  final PadRecommendation recommendation;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.tintPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        color: AppColors.rose, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pad Recommendation',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendation.padType,
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 14,
                            color: AppColors.crimson,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.rose),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Divider(),
                  const SizedBox(height: 12),

                  // Reason
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.roseTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.rose),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation.reason,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Absorbency badge
                  Row(
                    children: [
                      _Badge(
                        label: 'Absorbency: ${recommendation.absorbency}',
                        color: AppColors.tintPink,
                        textColor: AppColors.crimson,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Suggested Products',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...recommendation.products.map(
                    (p) => _ProductTile(product: p),
                  ),

                  const SizedBox(height: 12),

                  // Search button
                  PrimaryButton(
                    label: 'Find These Near You →',
                    height: 44,
                    onPressed: () => _searchOnline(
                      context,
                      recommendation.padType,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _searchOnline(BuildContext context, String padType) async {
    final query = Uri.encodeComponent('buy $padType India');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// ----------------------------------------------------------------
// Past Journal Card
// ----------------------------------------------------------------

class _PastJournalCard extends StatelessWidget {
  const _PastJournalCard({required this.journal});

  final JournalEntry journal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.rose),
              const SizedBox(width: 6),
              Text(
                _formatDate(journal.date),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tintPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  journal.padRecommendation.padType
                      .split(' ')
                      .take(2)
                      .join(' '),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.crimson,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            journal.headline,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 13.5,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            journal.body.split('\n\n').first.replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ----------------------------------------------------------------
// Small Helpers
// ----------------------------------------------------------------

class _TipRow extends StatelessWidget {
  const _TipRow({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 5, color: AppColors.rose),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.body.copyWith(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final PadProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.tintPink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.water_drop_outlined,
                size: 16, color: AppColors.rose),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${product.brand} • ${product.type}',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _searchProduct(context, product),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.rose),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchProduct(BuildContext context, PadProduct product) async {
    final query = Uri.encodeComponent('buy ${product.name} ${product.brand}');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.divider,
    );
  }
}
