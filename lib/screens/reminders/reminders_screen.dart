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
import 'reminder_parts.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const List<ReminderItem> _items = [
    ReminderItem(
      key: 'period',
      icon: Icons.favorite_rounded,
      title: 'Period Reminder',
      subtitle: 'Get notified before your period',
      iconColor: AppColors.crimson,
      background: AppColors.tintPink,
    ),
    ReminderItem(
      key: 'checkin',
      icon: Icons.assignment_turned_in_rounded,
      title: 'Daily Check-in',
      subtitle: 'A gentle reminder to log your symptoms',
      iconColor: AppColors.rose,
      background: AppColors.tintPink,
    ),
    ReminderItem(
      key: 'water',
      icon: Icons.water_drop_rounded,
      title: 'Water Reminder',
      subtitle: 'Stay hydrated',
      iconColor: Color(0xFF2F7FB0),
      background: AppColors.tintBlue,
    ),
    ReminderItem(
      key: 'tips',
      icon: Icons.auto_awesome_rounded,
      title: 'Wellness Tips',
      subtitle: 'Receive personalised tips',
      iconColor: Color(0xFFF08A1C),
      background: AppColors.tintOrange,
    ),
  ];

  static const List<StyleOption> _styles = [
    StyleOption(
      NotificationStyle.normal,
      'Normal',
      'Shows full notification content',
    ),
    StyleOption(
      NotificationStyle.discreet,
      'Discreet',
      'Shows only "You have a reminder"',
    ),
    StyleOption(NotificationStyle.silent, 'Silent', null),
  ];

  late Map<String, bool> _toggles;
  late TimeOfDay _time;
  late NotificationStyle _style;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _toggles = Map<String, bool>.from(state.reminders);
    _time = state.remindTime;
    _style = state.notificationStyle;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _save() {
    final state = context.read<AppState>();
    _toggles.forEach(state.setReminder);
    state.setRemindTime(_time);
    state.setNotificationStyle(_style);
    Helpers.showSnack(context, 'Reminder settings saved');
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Reminders'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              if (i > 0)
                                const Divider(indent: 70, endIndent: 16),
                              SettingsTile(
                                icon: _items[i].icon,
                                iconColor: _items[i].iconColor,
                                iconBackground: _items[i].background,
                                title: _items[i].title,
                                subtitle: _items[i].subtitle,
                                showChevron: false,
                                onTap: () => setState(() {
                                  final k = _items[i].key;
                                  _toggles[k] = !(_toggles[k] ?? false);
                                }),
                                trailing: Switch(
                                  value: _toggles[_items[i].key] ?? false,
                                  onChanged: (v) => setState(
                                    () => _toggles[_items[i].key] = v,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onTap: _pickTime,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.crimson,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Remind me at',
                              style: AppTextStyles.cardTitle
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            Helpers.timeOfDay(_time),
                            style: AppTextStyles.bodyMuted,
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Notification Style',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            for (var i = 0; i < _styles.length; i++) ...[
                              if (i > 0)
                                const Divider(indent: 16, endIndent: 16),
                              StyleRow(
                                option: _styles[i],
                                selected: _style == _styles[i].style,
                                onTap: () =>
                                    setState(() => _style = _styles[i].style),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(
                  label: AppStrings.saveSettings,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}