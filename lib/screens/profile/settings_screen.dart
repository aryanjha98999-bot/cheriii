
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/settings_tile.dart';

/// Cycle Settings: cycle length, period length and last period date.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _cycle;
  late int _period;
  late DateTime _lastStart;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _cycle = user.cycleLength;
    _period = user.periodLength;
    _lastStart = user.lastPeriodStart;
  }

  Future<void> _pickLastStart() async {
    final max = Helpers.today;
    final initial = _lastStart.isAfter(max) ? max : _lastStart;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: max,
    );
    if (picked != null && mounted) {
      setState(() => _lastStart = Helpers.dateOnly(picked));
    }
  }

  void _save() {
    final state = context.read<AppState>();
    state.updateUser(
      state.user.copyWith(
        cycleLength: _cycle,
        periodLength: _period,
        lastPeriodStart: _lastStart,
      ),
    );
    Helpers.showSnack(context, 'Cycle settings saved 🌸');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Cycle Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _StepperRow(
                            icon: Icons.autorenew_rounded,
                            title: 'Cycle length',
                            subtitle: 'Days from one period to the next',
                            value: _cycle,
                            min: 21,
                            max: 40,
                            onChanged: (v) => setState(() => _cycle = v),
                          ),
                          const Divider(indent: 58, endIndent: 16),
                          _StepperRow(
                            icon: Icons.water_drop_outlined,
                            title: 'Period length',
                            subtitle: 'Days your period usually lasts',
                            value: _period,
                            min: 2,
                            max: 10,
                            onChanged: (v) => setState(() => _period = v),
                          ),
                          const Divider(indent: 58, endIndent: 16),
                          SettingsTile(
                            icon: Icons.event_rounded,
                            title: 'Last period started',
                            subtitle: 'Used to predict your next period',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Helpers.shortDate(_lastStart),
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.crimson),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                            onTap: _pickLastStart,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      color: const Color(0xFFFFE9EC),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.local_florist_rounded,
                              color: AppColors.crimson),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Estimated ovulation: day ${_cycle - 14} of '
                              'your cycle. Predictions get better the more '
                              'you log.',
                              style: AppTextStyles.body.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: AppStrings.saveSettings,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, color: AppColors.crimson, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.roseTint : const Color(0xFFF3EEEF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.crimson : AppColors.toggleOff,
          ),
        ),
      ),
    );
  }
}