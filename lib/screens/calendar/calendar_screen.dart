import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../models/cycle_entry.dart';
import '../../models/symptom.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/symptom_chip.dart';

class _DayShade {
  const _DayShade(this.bg, this.fg);

  final Color bg;
  final Color fg;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const List<String> _weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<FlowLevel> _flowOptions = [
    FlowLevel.light,
    FlowLevel.medium,
    FlowLevel.heavy,
    FlowLevel.spotting,
  ];

  late DateTime _month;
  late DateTime _selected;
  FlowLevel _flow = FlowLevel.none;
  Set<String> _symptoms = <String>{};

  @override
  void initState() {
    super.initState();
    _selected = Helpers.initialCalendarDate;
    _month = DateTime(_selected.year, _selected.month);
    _loadDraft(context.read<AppState>());
  }

  /// Loads the saved entry (if any) for [_selected] into the local draft.
  void _loadDraft(AppState state) {
    final entry = state.entryFor(_selected);
    _flow = entry?.flow ?? FlowLevel.none;
    _symptoms = Set<String>.of(entry?.symptoms ?? const <String>{});
  }

  void _select(DateTime d) {
    final state = context.read<AppState>();
    setState(() {
      _selected = Helpers.dateOnly(d);
      _month = DateTime(d.year, d.month);
      _loadDraft(state);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) _select(picked);
  }

  void _logPeriod() {
    final state = context.read<AppState>();
    state.logPeriod(_selected);
    setState(() {
      final isFlow = _flow == FlowLevel.light ||
          _flow == FlowLevel.medium ||
          _flow == FlowLevel.heavy;
      if (!isFlow) _flow = FlowLevel.medium;
    });
    Helpers.showSnack(
      context,
      'Period logged for ${Helpers.shortDate(_selected)} 🌸',
    );
  }

  void _save() {
    final state = context.read<AppState>();
    final existing = state.entryFor(_selected) ?? CycleEntry(date: _selected);
    state.saveEntry(
      existing.copyWith(flow: _flow, symptoms: Set<String>.of(_symptoms)),
    );
    Helpers.showSnack(
      context,
      'Entry saved for ${Helpers.shortDate(_selected)} 💕',
    );
  }

  /// Position of [d] within its consecutive run of period days (1-based).
  int _runPosition(AppState state, DateTime d) {
    var pos = 1;
    var prev = Helpers.addDays(d, -1);
    while (pos < 7 && state.isPeriodDay(prev)) {
      pos++;
      prev = Helpers.addDays(prev, -1);
    }
    return pos;
  }

  _DayShade _periodShade(AppState state, DateTime d) {
    final entry = state.entryFor(d);
    if (entry != null && entry.isPeriodFlow) {
      switch (entry.flow) {
        case FlowLevel.heavy:
          return const _DayShade(AppColors.crimsonDark, Colors.white);
        case FlowLevel.medium:
          return const _DayShade(AppColors.crimson, Colors.white);
        default:
          return const _DayShade(AppColors.roseLight, AppColors.crimsonDark);
      }
    }
    switch (_runPosition(state, d)) {
      case 1:
        return const _DayShade(AppColors.crimsonDark, Colors.white);
      case 2:
        return const _DayShade(AppColors.crimson, Colors.white);
      case 3:
        return const _DayShade(AppColors.rose, Colors.white);
      default:
        return const _DayShade(AppColors.roseLight, AppColors.crimsonDark);
    }
  }

  Widget _buildDay(AppState state, DateTime d) {
    final isToday = Helpers.isSameDay(d, Helpers.today);
    final isSelected = Helpers.isSameDay(d, _selected);
    final isPeriod = state.isPeriodDay(d);
    final isPredicted = state.isPredictedDay(d);
    final isFertile = !isPeriod && !isPredicted && state.isFertileDay(d);

    Color? bg;
    Color fg = AppColors.textPrimary;
    Border? border;

    if (isPeriod) {
      final shade = _periodShade(state, d);
      bg = shade.bg;
      fg = shade.fg;
    } else if (isPredicted) {
      bg = AppColors.predictedFill;
      fg = const Color(0xFFB5452E);
      border = Border.all(color: AppColors.predicted, width: 1.2);
    } else if (isFertile) {
      bg = AppColors.fertile;
      fg = AppColors.fertileText;
    }

    if (isToday) {
      border = Border.all(color: AppColors.todayRing, width: 1.4);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: Helpers.shortDate(d),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(d),
        child: SizedBox(
          height: 40,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: border,
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: AppColors.roseLight,
                          blurRadius: 0,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    '${d.day}',
                    style: AppTextStyles.label.copyWith(
                      color: fg,
                      fontWeight:
                          isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isToday)
                    Positioned(
                      bottom: 3,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: bg == null || isPredicted || isFertile
                              ? AppColors.todayRing
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(AppState state) {
    final cells = Helpers.monthGrid(_month);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  Helpers.monthYear(_month),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < cells.length; r += 7)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: cells[r + c] == null
                        ? const SizedBox(height: 40)
                        : _buildDay(state, cells[r + c]!),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AppBackground(
      child: Column(
        children: [
          AppHeader(
            title: 'Cycle Calendar',
            onBack: () => context.read<AppState>().setTab(0),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarCard(state),
                  const SizedBox(height: 12),

                  // ---- Legend ----
                  const Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _LegendItem(color: AppColors.crimson, label: 'Period'),
                      _LegendItem(
                          color: AppColors.predicted, label: 'Predicted'),
                      _LegendItem(
                          color: AppColors.fertileText,
                          label: 'Fertile Window'),
                      _LegendItem(
                        color: AppColors.todayRing,
                        label: 'Today',
                        ring: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- Log period ----
                  Align(
                    alignment: Alignment.centerRight,
                    child: PrimaryButton(
                      label: AppStrings.logPeriod,
                      trailingIcon: Icons.add_rounded,
                      expand: false,
                      height: 40,
                      fontSize: 13,
                      horizontalPadding: 18,
                      onPressed: _logPeriod,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ---- Selected date ----
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Helpers.shortDate(_selected),
                              style: AppTextStyles.sectionTitle
                                  .copyWith(fontSize: 15),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ---- Flow ----
                  Text('Flow', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final level in _flowOptions)
                        Expanded(
                          child: Center(
                            child: _FlowTile(
                              level: level,
                              selected: _flow == level,
                              onTap: () => setState(() {
                                _flow = _flow == level
                                    ? FlowLevel.none
                                    : level;
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ---- Symptoms ----
                  Text('Symptoms', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final s in Symptom.calendarSet)
                        Expanded(
                          child: Center(
                            child: SymptomChip(
                              label: s.label,
                              icon: s.icon,
                              size: 42,
                              selected: _symptoms.contains(s.id),
                              onTap: () => setState(() {
                                if (!_symptoms.remove(s.id)) {
                                  _symptoms.add(s.id);
                                }
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  PrimaryButton(
                    label: AppStrings.saveEntry,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.ring = false,
  });

  final Color color;
  final String label;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring ? null : color,
            border: ring ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
      ],
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final FlowLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = level == FlowLevel.heavy
        ? AppColors.crimsonDark
        : (level == FlowLevel.spotting ? AppColors.rose : AppColors.crimson);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Flow ${level.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: level.tint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.crimson : Colors.transparent,
                  width: 1.6,
                ),
                boxShadow: selected ? AppColors.softShadow : null,
              ),
              child: Icon(level.icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              level.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                color: selected ? AppColors.crimson : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}