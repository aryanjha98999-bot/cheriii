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
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/symptom_chip.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  static const List<FlowLevel> _flowOptions = [
    FlowLevel.none,
    FlowLevel.light,
    FlowLevel.medium,
    FlowLevel.heavy,
  ];

  final TextEditingController _notes = TextEditingController();

  Mood? _mood;
  Set<String> _symptoms = <String>{};
  FlowLevel _flow = FlowLevel.medium;
  double _sleep = 7;

  @override
  void initState() {
    super.initState();
    final entry = context.read<AppState>().entryFor(Helpers.today);
    if (entry != null) {
      _mood = entry.mood;
      _symptoms = Set<String>.of(entry.symptoms);
      _flow = _flowOptions.contains(entry.flow) ? entry.flow : FlowLevel.none;
      _sleep = entry.sleepHours.clamp(4.0, 8.0).toDouble();
      _notes.text = entry.notes;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String get _sleepLabel => _sleep % 1 == 0
      ? '${_sleep.toInt()} hrs'
      : '${_sleep.toStringAsFixed(1)} hrs';

  void _save() {
    final state = context.read<AppState>();
    final existing =
        state.entryFor(Helpers.today) ?? CycleEntry(date: Helpers.today);
    state.saveEntry(
      existing.copyWith(
        mood: _mood,
        clearMood: _mood == null,
        symptoms: Set<String>.of(_symptoms),
        flow: _flow,
        sleepHours: _sleep,
        notes: _notes.text.trim(),
      ),
    );
    Helpers.showSnack(context, 'Check-in saved. Great job! 💕');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            AppHeader(
              title: AppStrings.todaysCheckIn,
              subtitle: Helpers.longDate(Helpers.today),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Mood ----
                      Text("How's your mood?",
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final m in Mood.values)
                            Expanded(
                              child: Center(
                                child: _MoodFace(
                                  mood: m,
                                  selected: _mood == m,
                                  onTap: () => setState(
                                    () => _mood = _mood == m ? null : m,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ---- Symptoms ----
                      Text('Any symptoms today?',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final s in Symptom.checkInSet)
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

                      // ---- Flow ----
                      Text('Flow', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            for (final f in _flowOptions)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _flow = f),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _flow == f
                                          ? AppColors.crimson
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      f.label,
                                      style: AppTextStyles.label.copyWith(
                                        color: _flow == f
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: _flow == f
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ---- Sleep ----
                      Row(
                        children: [
                          Expanded(
                            child: Text('Sleep (hours)',
                                style: AppTextStyles.sectionTitle),
                          ),
                          Text(
                            _sleepLabel,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.crimson),
                          ),
                        ],
                      ),
                      Slider(
                        value: _sleep,
                        min: 4,
                        max: 8,
                        divisions: 8,
                        label: _sleepLabel,
                        onChanged: (v) => setState(() => _sleep = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final n in const ['4', '6', '8'])
                              Text(n, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ---- Notes ----
                      Text('Notes (optional)',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notes,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(hintText: 'Add a note...'),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: AppStrings.saveCheckIn,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodFace extends StatelessWidget {
  const _MoodFace({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mood.tint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.crimson : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected ? AppColors.softShadow : null,
              ),
              child: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 6),
            Text(
              mood.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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