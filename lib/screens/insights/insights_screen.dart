import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
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

const List<_SymptomStat> _topSymptoms = [
  _SymptomStat('Cramps', Icons.flash_on_rounded, 78, AppColors.tintPink,
      AppColors.rose),
  _SymptomStat('Mood Swings', Icons.sentiment_satisfied_alt_outlined, 62,
      AppColors.tintYellow, Color(0xFFF2A900)),
  _SymptomStat('Headache', Icons.sick_outlined, 48, AppColors.tintOrange,
      Color(0xFFF08A1C)),
  _SymptomStat('Bloating', Icons.bubble_chart_outlined, 42,
      AppColors.tintBlue, Color(0xFF2F7FB0)),
];

const List<_SymptomStat> _moreSymptoms = [
  _SymptomStat('Fatigue', Icons.bedtime_outlined, 36, AppColors.tintGreen,
      Color(0xFF4C9A5B)),
  _SymptomStat('Acne', Icons.blur_on_rounded, 31, AppColors.tintPink,
      AppColors.crimson),
];

const List<(Mood, int)> _moodShare = [
  (Mood.happy, 34),
  (Mood.calm, 28),
  (Mood.okay, 20),
  (Mood.sad, 10),
  (Mood.anxious, 8),
];

const List<double> _cycleLengths = [28, 28, 30, 29, 30, 29];
const List<double> _periodLengths = [5, 5, 6, 5, 5, 5];

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const List<String> _tabs = ['Overview', 'Symptoms', 'Mood', 'Trends'];

  int _tab = 0;

  Widget _content() {
    switch (_tab) {
      case 1:
        return _symptomsTab();
      case 2:
        return _moodTab();
      case 3:
        return _trendsTab();
      default:
        return _overviewTab();
    }
  }

  // ---------------- Overview ----------------
  Widget _overviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your Cycle at a Glance'),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: _StatCard(
                  value: '29',
                  unit: 'days',
                  label: 'Avg. Cycle Length',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '5',
                  unit: 'days',
                  label: 'Avg. Period Length',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '87%',
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
        const AppCard(
          padding: EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: _TrendChart(
            values: _cycleLengths,
            minY: 10,
            maxY: 40,
            interval: 10,
            unit: 'days',
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Most Common Symptoms'),
        const SizedBox(height: 10),
        _symptomCard(_topSymptoms),
        const SizedBox(height: 16),
        const _MessageCard(
          icon: Icons.local_florist_rounded,
          text: 'Your cycles have been quite regular this year! ✨',
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

  // ---------------- Symptoms ----------------
  Widget _symptomsTab() {
    final all = [..._topSymptoms, ..._moreSymptoms];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Symptoms You Log Most'),
        const SizedBox(height: 10),
        _symptomCard(all),
        const SizedBox(height: 16),
        const _MessageCard(
          icon: Icons.favorite_rounded,
          text: 'Cramps and mood changes tend to peak in the 2 days before '
              'your period. Gentle care helps. 💕',
        ),
      ],
    );
  }

  // ---------------- Mood ----------------
  Widget _moodTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('How You Have Been Feeling'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              for (var i = 0; i < _moodShare.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _BarRow(
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _moodShare[i].$1.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _moodShare[i].$1.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  label: _moodShare[i].$1.label,
                  value: _moodShare[i].$2,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _MessageCard(
          icon: Icons.spa_rounded,
          text: 'You felt happy or calm on most days this cycle. Keep it up! 🌸',
        ),
      ],
    );
  }

  // ---------------- Trends ----------------
  Widget _trendsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Cycle Length Trend'),
        const SizedBox(height: 10),
        const AppCard(
          padding: EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: _TrendChart(
            values: _cycleLengths,
            minY: 10,
            maxY: 40,
            interval: 10,
            unit: 'days',
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Period Length Trend'),
        const SizedBox(height: 10),
        const AppCard(
          padding: EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: _TrendChart(
            values: _periodLengths,
            minY: 0,
            maxY: 10,
            interval: 2,
            unit: 'days',
          ),
        ),
        const SizedBox(height: 16),
        const _MessageCard(
          icon: Icons.insights_rounded,
          text: 'Your cycle length varies by only 2 days. That is a very '
              'steady pattern. ✨',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Column(
        children: [
          const AppHeader(title: 'My Insights', showBack: false),
          PillTabs(
            labels: _tabs,
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey<int>(_tab),
                  child: _content(),
                ),
              ),
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
                backgroundColor: AppColors.roseLight.withOpacity(0.3),
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

  static const List<String> _months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];

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
        color: AppColors.crimson.withOpacity(0.07),
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
          showingTooltipIndicators: [
            ShowingTooltipIndicators([
              LineBarSpot(bar, 0, bar.spots.last),
            ]),
          ],
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