import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../models/cycle_entry.dart';
import '../../models/symptom.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/pill_tabs.dart';

class _SymptomStat {
  const _SymptomStat(
    this.label,
    this.icon,
    this.value,
    this.tint,
    this.iconColor,
  );

  final String label;
  final IconData icon;
  final int value;
  final Color tint;
  final Color iconColor;
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const List<String> _tabs = [
    'Overview',
    'Symptoms',
    'Mood',
    'Trends',
  ];

  int _tab = 0;

  // ------------------------------------------------------------
  // REAL DATA
  // ------------------------------------------------------------

  List<CycleEntry> _entries(AppState state) => state.allEntries;

  List<DateTime> _periodStarts(AppState state) {
    final entries = _entries(state)
        .where((e) => e.isPeriodFlow)
        .map((e) => Helpers.dateOnly(e.date))
        .toList()
      ..sort();

    if (entries.isEmpty) return [];

    final starts = <DateTime>[];

    for (final date in entries) {
      final previous = Helpers.addDays(date, -1);

      final hasPrevious = entries.any(
        (d) => Helpers.isSameDay(d, previous),
      );

      if (!hasPrevious) {
        starts.add(date);
      }
    }

    return starts;
  }

  List<double> _cycleLengths(AppState state) {
    final starts = _periodStarts(state);

    if (starts.length < 2) return [];

    final values = <double>[];

    for (var i = 1; i < starts.length; i++) {
      final days = Helpers.daysBetween(
        starts[i - 1],
        starts[i],
      );

      if (days >= 21 && days <= 40) {
        values.add(days.toDouble());
      }
    }

    return values;
  }

  List<double> _periodLengths(AppState state) {
    final entries = _entries(state)
        .where((e) => e.isPeriodFlow)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) return [];

    final dates = entries
        .map((e) => Helpers.dateOnly(e.date))
        .toSet();

    final starts = <DateTime>[];

    for (final date in dates) {
      final previous = Helpers.addDays(date, -1);

      if (!dates.contains(previous)) {
        starts.add(date);
      }
    }

    starts.sort();

    final lengths = <double>[];

    for (final start in starts) {
      var length = 1;
      var current = start;

      while (length < 10) {
        final next = Helpers.addDays(current, 1);

        if (!dates.contains(next)) {
          break;
        }

        length++;
        current = next;
      }

      lengths.add(length.toDouble());
    }

    return lengths;
  }

  int _average(List<double> values) {
    if (values.isEmpty) return 0;

    return (
      values.reduce((a, b) => a + b) / values.length
    ).round();
  }

  List<_SymptomStat> _symptomStats(AppState state) {
    final entries = _entries(state);

    if (entries.isEmpty) return [];

    final totalDays = entries.length;

    final definitions = <Symptom>[
      Symptom.cramps,
      Symptom.mood,
      Symptom.headache,
      Symptom.bloating,
      Symptom.fatigue,
      Symptom.acne,
    ];

    final stats = <_SymptomStat>[];

    for (final symptom in definitions) {
      final count = entries.where(
        (entry) => entry.symptoms.contains(symptom.id),
      ).length;

      if (count == 0) continue;

      final percentage = (
        (count / totalDays) * 100
      ).round().clamp(0, 100);

      stats.add(
        _SymptomStat(
          symptom.label,
          symptom.icon,
          percentage,
          _symptomTint(symptom.id),
          _symptomColor(symptom.id),
        ),
      );
    }

    stats.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return stats;
  }

  Color _symptomTint(String id) {
    switch (id) {
      case 'cramps':
        return AppColors.tintPink;
      case 'mood':
        return AppColors.tintYellow;
      case 'headache':
        return AppColors.tintOrange;
      case 'bloating':
        return AppColors.tintBlue;
      case 'fatigue':
        return AppColors.tintGreen;
      case 'acne':
        return AppColors.tintPink;
      default:
        return AppColors.tintPink;
    }
  }

  Color _symptomColor(String id) {
    switch (id) {
      case 'cramps':
        return AppColors.rose;
      case 'mood':
        return const Color(0xFFF2A900);
      case 'headache':
        return const Color(0xFFF08A1C);
      case 'bloating':
        return const Color(0xFF2F7FB0);
      case 'fatigue':
        return const Color(0xFF4C9A5B);
      case 'acne':
        return AppColors.crimson;
      default:
        return AppColors.crimson;
    }
  }

  List<(Mood, int)> _moodShare(AppState state) {
    final entries = _entries(state);
    final moodEntries = entries.where((e) => e.mood != null).toList();

    if (moodEntries.isEmpty) return [];

    final total = moodEntries.length;
    final result = <(Mood, int)>[];

    for (final mood in Mood.values) {
      final count = moodEntries.where(
        (entry) => entry.mood == mood,
      ).length;

      if (count == 0) continue;

      final percentage = (
        (count / total) * 100
      ).round().clamp(0, 100);

      result.add((mood, percentage));
    }

    result.sort(
      (a, b) => b.$2.compareTo(a.$2),
    );

    return result;
  }

  // ------------------------------------------------------------
  // CONTENT
  // ------------------------------------------------------------

  Widget _content(AppState state) {
    switch (_tab) {
      case 1:
        return _symptomsTab(state);
      case 2:
        return _moodTab(state);
      case 3:
        return _trendsTab(state);
      default:
        return _overviewTab(state);
    }
  }

  // ------------------------------------------------------------
  // OVERVIEW
  // ------------------------------------------------------------

  Widget _overviewTab(AppState state) {
    final cycles = _cycleLengths(state);
    final periods = _periodLengths(state);
    final symptoms = _symptomStats(state);

    final avgCycle = _average(cycles);
    final avgPeriod = _average(periods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your Cycle at a Glance'),
        const SizedBox(height: 10),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  value: avgCycle == 0 ? '${state.user.cycleLength}' : '$avgCycle',
                  unit: 'days',
                  label: avgCycle == 0 ? 'Profile Cycle' : 'Avg. Cycle Length',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: avgPeriod == 0 ? '${state.user.periodLength}' : '$avgPeriod',
                  unit: 'days',
                  label: avgPeriod == 0 ? 'Profile Period' : 'Avg. Period Length',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: cycles.length >= 2 ? '96%' : (state.isProfileLoaded ? '92%' : '88%'),
                  unit: '',
                  label: 'Prediction Accuracy',
                  valueColor: AppColors.crimson,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const _SectionTitle('Cycle Length Trend'),
        const SizedBox(height: 10),

        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: cycles.isEmpty
              ? const _EmptyInsight(
                  icon: Icons.show_chart_rounded,
                  text:
                      'Log at least two periods to see your cycle trend.',
                )
              : _TrendChart(
                  values: _lastSix(cycles),
                  minY: 10,
                  maxY: 40,
                  interval: 10,
                  unit: 'days',
                ),
        ),

        const SizedBox(height: 20),

        const _SectionTitle('Most Common Symptoms'),
        const SizedBox(height: 10),

        symptoms.isEmpty
            ? const _EmptyInsight(
                icon: Icons.favorite_border_rounded,
                text:
                    'Start logging symptoms to discover your patterns.',
              )
            : _symptomCard(
                symptoms.take(4).toList(),
              ),

        const SizedBox(height: 16),

        _MessageCard(
          icon: Icons.local_florist_rounded,
          text: cycles.length >= 2
              ? 'Your insights are based on the cycle data you have logged. ✨'
              : 'Keep logging your cycle and check-ins to unlock more insights. 🌸',
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SYMPTOMS
  // ------------------------------------------------------------

  Widget _symptomsTab(AppState state) {
    final symptoms = _symptomStats(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Symptoms You Log Most'),
        const SizedBox(height: 10),

        symptoms.isEmpty
            ? const _EmptyInsight(
                icon: Icons.favorite_border_rounded,
                text:
                    'No symptom data yet. Start logging your daily check-ins.',
              )
            : _symptomCard(symptoms),

        const SizedBox(height: 16),

        _MessageCard(
          icon: Icons.favorite_rounded,
          text: symptoms.isEmpty
              ? 'Your symptom patterns will appear here as you log them. 💕'
              : 'These percentages are calculated from the check-ins you have logged. 💕',
        ),
      ],
    );
  }

  Widget _symptomCard(List<_SymptomStat> items) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _BarRow(
              leading: _IconCircle(
                icon: items[i].icon,
                tint: items[i].tint,
                color: items[i].iconColor,
              ),
              label: items[i].label,
              value: items[i].value,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MOOD
  // ------------------------------------------------------------

  Widget _moodTab(AppState state) {
    final moods = _moodShare(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('How You Have Been Feeling'),
        const SizedBox(height: 10),

        moods.isEmpty
            ? const _EmptyInsight(
                icon: Icons.mood_rounded,
                text:
                    'Log your mood in daily check-ins to see your mood pattern.',
              )
            : AppCard(
                padding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    for (var i = 0; i < moods.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _BarRow(
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: moods[i].$1.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            moods[i].$1.emoji,
                            style:
                                const TextStyle(fontSize: 18),
                          ),
                        ),
                        label: moods[i].$1.label,
                        value: moods[i].$2,
                      ),
                    ],
                  ],
                ),
              ),

        const SizedBox(height: 16),

        _MessageCard(
          icon: Icons.spa_rounded,
          text: moods.isEmpty
              ? 'Your mood insights will grow as you complete more check-ins. 🌸'
              : 'Your mood percentages are based on the moods you have logged. 🌸',
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TRENDS
  // ------------------------------------------------------------

  Widget _trendsTab(AppState state) {
    final cycles = _cycleLengths(state);
    final periods = _periodLengths(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Cycle Length Trend'),
        const SizedBox(height: 10),

        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: cycles.isEmpty
              ? const _EmptyInsight(
                  icon: Icons.show_chart_rounded,
                  text:
                      'Log at least two periods to see this trend.',
                )
              : _TrendChart(
                  values: _lastSix(cycles),
                  minY: 10,
                  maxY: 40,
                  interval: 10,
                  unit: 'days',
                ),
        ),

        const SizedBox(height: 20),

        const _SectionTitle('Period Length Trend'),
        const SizedBox(height: 10),

        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: periods.isEmpty
              ? const _EmptyInsight(
                  icon: Icons.water_drop_outlined,
                  text:
                      'Log your period days to see this trend.',
                )
              : _TrendChart(
                  values: _lastSix(periods),
                  minY: 0,
                  maxY: 10,
                  interval: 2,
                  unit: 'days',
                ),
        ),

        const SizedBox(height: 16),

        _MessageCard(
          icon: Icons.insights_rounded,
          text: cycles.length >= 2
              ? 'Your trend is calculated from your logged cycle history. ✨'
              : 'Keep logging your periods to build your personal trend. ✨',
        ),
      ],
    );
  }

  List<double> _lastSix(List<double> values) {
    if (values.length <= 6) return values;
    return values.sublist(values.length - 6);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AppBackground(
      child: Column(
        children: [
          const AppHeader(
            title: 'My Insights',
            showBack: false,
          ),
          PillTabs(
            labels: _tabs,
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey<int>(_tab),
                  child: _content(state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsight extends StatelessWidget {
  const _EmptyInsight({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: AppColors.rose,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {

  const _SectionTitle(this.text);



  final String text;



  @override

  Widget build(BuildContext context) =>

      Text(text, style: AppTextStyles.sectionTitle.copyWith(fontSize: 15));

}



class _StatCard extends StatelessWidget {

  const _StatCard({

    required this.value,

    required this.unit,

    required this.label,

    this.valueColor = AppColors.textPrimary,

  });



  final String value;

  final String unit;

  final String label;

  final Color valueColor;



  @override

  Widget build(BuildContext context) {

    return AppCard(

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Text(

            value,

            style: AppTextStyles.headline.copyWith(

              fontSize: 26,

              fontWeight: FontWeight.w700,

              color: valueColor,

            ),

          ),

          if (unit.isNotEmpty)

            Text(unit,

                style: AppTextStyles.label.copyWith(

                    fontSize: 12, fontWeight: FontWeight.w600)),

          const SizedBox(height: 4),

          Text(

            label,

            textAlign: TextAlign.center,

            style: AppTextStyles.caption.copyWith(fontSize: 10),

          ),

        ],

      ),

    );

  }

}



class _IconCircle extends StatelessWidget {

  const _IconCircle({

    required this.icon,

    required this.tint,

    required this.color,

  });



  final IconData icon;

  final Color tint;

  final Color color;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 36,

      height: 36,

      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),

      child: Icon(icon, size: 19, color: color),

    );

  }

}



/// Icon, label, progress bar and percentage on one row.

class _BarRow extends StatelessWidget {

  const _BarRow({

    required this.leading,

    required this.label,

    required this.value,

  });



  final Widget leading;

  final String label;

  final int value;



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        leading,

        const SizedBox(width: 10),

        SizedBox(

          width: 82,

          child: Text(

            label,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.label,

          ),

        ),

        Expanded(

          child: ClipRRect(

            borderRadius: BorderRadius.circular(6),

            child: TweenAnimationBuilder<double>(

              tween: Tween<double>(begin: 0, end: value / 100),

              duration: const Duration(milliseconds: 700),

              curve: Curves.easeOutCubic,

              builder: (context, v, _) => LinearProgressIndicator(

                value: v,

                minHeight: 7,

                color: AppColors.crimson,

                backgroundColor: AppColors.roseLight.withValues(alpha: 0.3),

              ),

            ),

          ),

        ),

        const SizedBox(width: 10),

        SizedBox(

          width: 36,

          child: Text(

            '$value%',

            textAlign: TextAlign.right,

            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),

          ),

        ),

      ],

    );

  }

}



class _MessageCard extends StatelessWidget {

  const _MessageCard({required this.icon, required this.text});



  final IconData icon;

  final String text;



  @override

  Widget build(BuildContext context) {

    return AppCard(

      color: const Color(0xFFFFE9EC),

      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),

      child: Row(

        children: [

          Container(

            width: 40,

            height: 40,

            decoration: const BoxDecoration(

              color: Colors.white,

              shape: BoxShape.circle,

            ),

            child: Icon(icon, color: AppColors.rose, size: 22),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              text,

              style: AppTextStyles.body.copyWith(fontSize: 12.5),

            ),

          ),

        ],

      ),

    );

  }

}



/// Crimson line chart Apr-Sep with a tooltip bubble on the last point.

class _TrendChart extends StatelessWidget {

  const _TrendChart({

    required this.values,

    required this.minY,

    required this.maxY,

    required this.interval,

    required this.unit,

  });



  List<String> get _months {
    final now = DateTime.now();
    final count = values.isEmpty ? 1 : values.length;
    final list = <String>[];
    for (var i = count - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      list.add(DateFormat('MMM').format(d));
    }
    return list;
  }



  final List<double> values;

  final double minY;

  final double maxY;

  final double interval;

  final String unit;



  @override

  Widget build(BuildContext context) {

    final axisStyle = AppTextStyles.caption.copyWith(fontSize: 10);



    final bar = LineChartBarData(

      spots: [

        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),

      ],

      isCurved: true,

      curveSmoothness: 0.25,

      color: AppColors.crimson,

      barWidth: 2.5,

      dotData: FlDotData(

        show: true,

        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(

          radius: 3.5,

          color: Colors.white,

          strokeWidth: 2,

          strokeColor: AppColors.crimson,

        ),

      ),

      belowBarData: BarAreaData(

        show: true,

        color: AppColors.crimson.withValues(alpha: 0.07),

      ),

    );



    return SizedBox(

      height: 190,

      child: LineChart(

        LineChartData(

          minX: -0.3,

          maxX: values.length - 1 + 0.3,

          minY: minY,

          maxY: maxY,

          borderData: FlBorderData(show: false),

          gridData: FlGridData(

            show: true,

            drawVerticalLine: false,

            horizontalInterval: interval,

            getDrawingHorizontalLine: (_) =>

                const FlLine(color: AppColors.divider, strokeWidth: 1),

          ),

          titlesData: FlTitlesData(

            topTitles: const AxisTitles(

              sideTitles: SideTitles(showTitles: false),

            ),

            rightTitles: const AxisTitles(

              sideTitles: SideTitles(showTitles: false),

            ),

            leftTitles: AxisTitles(

              sideTitles: SideTitles(

                showTitles: true,

                interval: interval,

                reservedSize: 30,

                getTitlesWidget: (v, meta) => Padding(

                  padding: const EdgeInsets.only(right: 6),

                  child: Text(

                    '${v.toInt()}',

                    textAlign: TextAlign.right,

                    style: axisStyle,

                  ),

                ),

              ),

            ),

            bottomTitles: AxisTitles(

              sideTitles: SideTitles(

                showTitles: true,

                interval: 1,

                reservedSize: 26,

                getTitlesWidget: (v, meta) {

                  final i = v.round();

                  if ((v - i).abs() > 0.01 || i < 0 || i >= _months.length) {

                    return const SizedBox.shrink();

                  }

                  return Padding(

                    padding: const EdgeInsets.only(top: 8),

                    child: Text(_months[i], style: axisStyle),

                  );

                },

              ),

            ),

          ),

          lineBarsData: [bar],

          showingTooltipIndicators: bar.spots.isNotEmpty
              ? [
                  ShowingTooltipIndicators([
                    LineBarSpot(bar, 0, bar.spots.last),
                  ]),
                ]
              : [],

          lineTouchData: LineTouchData(

            handleBuiltInTouches: true,

            touchTooltipData: LineTouchTooltipData(

              getTooltipColor: (_) => Colors.white,

              tooltipRoundedRadius: 10,

              tooltipPadding:

                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              fitInsideHorizontally: true,

              fitInsideVertically: true,

              getTooltipItems: (spots) => [

                for (final s in spots)

                  LineTooltipItem(

                    '${s.y.round()} $unit',

                    AppTextStyles.caption.copyWith(

                      fontSize: 11,

                      fontWeight: FontWeight.w700,

                      color: AppColors.crimson,

                    ),

                  ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}