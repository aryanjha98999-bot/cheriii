import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/primary_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  int _cycleLength = 28;
  int _periodLength = 5;

  DateTime? _lastPeriodStart;

  String _skinSensitivity = 'Normal';
  String _bodyType = 'Regular fit';
  String _dailyRoutine = 'Moderate / Mixed';
  String _flowTendency = 'Medium balanced';

  // ------------------------------------------------------------
  // AVATARS
  // ------------------------------------------------------------

  static const List<_CheriAvatar> _avatars = [
    _CheriAvatar(
      id: 'flower',
      icon: Icons.local_florist_rounded,
      label: 'Flower',
    ),
    _CheriAvatar(
      id: 'favorite',
      icon: Icons.favorite_rounded,
      label: 'Heart',
    ),
    _CheriAvatar(
      id: 'face',
      icon: Icons.face_3_rounded,
      label: 'Smile',
    ),
    _CheriAvatar(
      id: 'pets',
      icon: Icons.pets_rounded,
      label: 'Cute',
    ),
    _CheriAvatar(
      id: 'star',
      icon: Icons.star_rounded,
      label: 'Star',
    ),
    _CheriAvatar(
      id: 'butterfly',
      icon: Icons.flutter_dash_rounded,
      label: 'Butterfly',
    ),
  ];

  String _selectedAvatar = 'flower';

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------

  Future<void> _selectLastPeriodDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.crimson,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _lastPeriodStart = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE PROFILE
  // ------------------------------------------------------------

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lastPeriodStart == null) {
      _showMessage(
        'Please select the date your last period started.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final age = int.parse(
        _ageController.text.trim(),
      );

      final updatedUser = UserModel(
        name: _nameController.text.trim(),
        age: age,
        avatarAsset: _selectedAvatar,
        cycleLength: _cycleLength,
        periodLength: _periodLength,
        lastPeriodStart: _lastPeriodStart!,
        skinSensitivity: _skinSensitivity,
        bodyType: _bodyType,
        dailyRoutine: _dailyRoutine,
        flowTendency: _flowTendency,
      );

      // Save to Supabase
      try {
        await _profileService.createProfile(
          name: updatedUser.name,
          age: updatedUser.age,
          cycleLength: updatedUser.cycleLength,
          periodLength: updatedUser.periodLength,
          lastPeriodStart: updatedUser.lastPeriodStart,
          avatarAsset: updatedUser.avatarAsset,
          skinSensitivity: updatedUser.skinSensitivity,
          bodyType: updatedUser.bodyType,
          dailyRoutine: updatedUser.dailyRoutine,
          flowTendency: updatedUser.flowTendency,
        );
      } catch (e) {
        debugPrint('Remote profile creation error: $e');
      }

      if (!mounted) return;

      final appState = context.read<AppState>();
      appState.updateUser(updatedUser, syncRemote: false);
      appState.completeOnboarding();

      if (!mounted) return;

      // Show Day 1 Pad recommendation modal
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _DayOnePadDialog(
          user: updatedUser,
          onContinue: () {
            Navigator.pop(ctx);
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.main,
              (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not save your profile. Please check the inputs and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ------------------------------------------------------------
  // NUMBER PICKER
  // ------------------------------------------------------------

  Future<void> _showNumberPicker({
    required String title,
    required int min,
    required int max,
    required int currentValue,
    required ValueChanged<int> onSelected,
  }) async {
    int selectedValue = currentValue;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headline,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 180,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        physics:
                            const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setSheetState(() {
                            selectedValue = min + index;
                          });
                        },
                        childDelegate:
                            ListWheelChildBuilderDelegate(
                          childCount: max - min + 1,
                          builder: (context, index) {
                            final value = min + index;

                            return Center(
                              child: Text(
                                '$value days',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      value == selectedValue
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color:
                                      value == selectedValue
                                          ? AppColors.crimson
                                          : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onSelected(selectedValue);
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // HEADER ICON
                  // ------------------------------------------------

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.rose,
                            AppColors.crimsonDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Let’s personalize Cheri',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      'Tell us a little about yourself so Cheri '
                      'can give you more personalized insights.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 14.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // AVATAR
                  // ------------------------------------------------

                  Text(
                    'Choose your Cheri avatar',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Pick the one that feels most like you.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _avatars.map((avatar) {
                      final selected =
                          _selectedAvatar == avatar.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar.id;
                          });
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 180),
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.rose,
                                      AppColors.crimsonDark,
                                    ],
                                  )
                                : null,
                            color: selected
                                ? null
                                : AppColors.roseLight.withValues(
                                    alpha: 0.45,
                                  ),
                            border: Border.all(
                              color: selected
                                  ? AppColors.crimson
                                  : AppColors.roseLight,
                              width: selected ? 3 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.crimson
                                          .withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 12,
                                      offset:
                                          const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            avatar.icon,
                            size: 34,
                            color: selected
                                ? Colors.white
                                : AppColors.crimson,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // NAME
                  // ------------------------------------------------

                  Text(
                    'Your name',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      if (value.trim().length < 2) {
                        return 'Please enter a valid name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // AGE
                  // ------------------------------------------------

                  Text(
                    'Your age',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter your age',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your age';
                      }

                      final age =
                          int.tryParse(value.trim());

                      if (age == null) {
                        return 'Please enter a valid age';
                      }

                      if (age < 13 || age > 100) {
                        return 'Enter an age between 13 and 100';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // CYCLE LENGTH
                  // ------------------------------------------------

                  Text(
                    'Average cycle length',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'How many days does your cycle usually last?',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SelectorCard(
                    icon: Icons.loop_rounded,
                    value: '$_cycleLength days',
                    onTap: () {
                      _showNumberPicker(
                        title: 'Cycle length',
                        min: 21,
                        max: 40,
                        currentValue: _cycleLength,
                        onSelected: (value) {
                          setState(() {
                            _cycleLength = value;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // PERIOD LENGTH
                  // ------------------------------------------------

                  Text(
                    'Average period length',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'How many days does your period usually last?',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SelectorCard(
                    icon: Icons.water_drop_outlined,
                    value: '$_periodLength days',
                    onTap: () {
                      _showNumberPicker(
                        title: 'Period length',
                        min: 2,
                        max: 10,
                        currentValue: _periodLength,
                        onSelected: (value) {
                          setState(() {
                            _periodLength = value;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // LAST PERIOD
                  // ------------------------------------------------

                  Text(
                    'When did your last period start?',
                    style: AppTextStyles.label,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'This helps Cheri calculate your cycle predictions.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SelectorCard(
                    icon: Icons.calendar_month_rounded,
                    value: _formatDate(_lastPeriodStart),
                    onTap: _selectLastPeriodDate,
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // SKIN SENSITIVITY & RASHES
                  // ------------------------------------------------
                  Text(
                    'Skin Sensitivity & Rash History',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Do you get rashes, itching or chafing with regular pads?',
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OptionChip(
                        label: 'Prone to rashes & chafing',
                        icon: Icons.healing_rounded,
                        selected: _skinSensitivity == 'Prone to rashes & chafing',
                        isAlert: true,
                        onTap: () => setState(() => _skinSensitivity = 'Prone to rashes & chafing'),
                      ),
                      _OptionChip(
                        label: 'Sensitive skin',
                        icon: Icons.spa_outlined,
                        selected: _skinSensitivity == 'Sensitive skin',
                        onTap: () => setState(() => _skinSensitivity = 'Sensitive skin'),
                      ),
                      _OptionChip(
                        label: 'Normal',
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        selected: _skinSensitivity == 'Normal',
                        onTap: () => setState(() => _skinSensitivity = 'Normal'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // BODY TYPE & FIT
                  // ------------------------------------------------
                  Text(
                    'Body Type & Fit',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Helps Cheri recommend ideal pad wings and rear coverage.',
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OptionChip(
                        label: 'Curvy / Wide hips',
                        icon: Icons.accessibility_new_rounded,
                        selected: _bodyType == 'Curvy / Wide hips',
                        onTap: () => setState(() => _bodyType = 'Curvy / Wide hips'),
                      ),
                      _OptionChip(
                        label: 'Athletic / Tall',
                        icon: Icons.fitness_center_rounded,
                        selected: _bodyType == 'Athletic / Tall',
                        onTap: () => setState(() => _bodyType = 'Athletic / Tall'),
                      ),
                      _OptionChip(
                        label: 'Petite / Slim',
                        icon: Icons.person_outline_rounded,
                        selected: _bodyType == 'Petite / Slim',
                        onTap: () => setState(() => _bodyType = 'Petite / Slim'),
                      ),
                      _OptionChip(
                        label: 'Regular fit',
                        icon: Icons.person_rounded,
                        selected: _bodyType == 'Regular fit',
                        onTap: () => setState(() => _bodyType = 'Regular fit'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // DAILY ROUTINE & MOVEMENT
                  // ------------------------------------------------
                  Text(
                    'Daily Routine & Movement',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your daily movement helps customize breathable & flexible pads.',
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OptionChip(
                        label: 'Active / Gym / Sports',
                        icon: Icons.directions_run_rounded,
                        selected: _dailyRoutine == 'Active / Gym / Sports',
                        onTap: () => setState(() => _dailyRoutine = 'Active / Gym / Sports'),
                      ),
                      _OptionChip(
                        label: 'Desk job / Long sitting',
                        icon: Icons.chair_rounded,
                        selected: _dailyRoutine == 'Desk job / Long sitting',
                        onTap: () => setState(() => _dailyRoutine = 'Desk job / Long sitting'),
                      ),
                      _OptionChip(
                        label: 'On feet / Travelling',
                        icon: Icons.directions_walk_rounded,
                        selected: _dailyRoutine == 'On feet / Travelling',
                        onTap: () => setState(() => _dailyRoutine = 'On feet / Travelling'),
                      ),
                      _OptionChip(
                        label: 'Moderate / Mixed',
                        icon: Icons.wb_sunny_outlined,
                        selected: _dailyRoutine == 'Moderate / Mixed',
                        onTap: () => setState(() => _dailyRoutine = 'Moderate / Mixed'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // FLOW TENDENCY
                  // ------------------------------------------------
                  Text(
                    'Flow Tendency on Day 1 & 2',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How does your period usually begin?',
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OptionChip(
                        label: 'Heavy initial days',
                        icon: Icons.water_drop_rounded,
                        selected: _flowTendency == 'Heavy initial days',
                        onTap: () => setState(() => _flowTendency = 'Heavy initial days'),
                      ),
                      _OptionChip(
                        label: 'Medium balanced',
                        icon: Icons.water_drop_outlined,
                        selected: _flowTendency == 'Medium balanced',
                        onTap: () => setState(() => _flowTendency = 'Medium balanced'),
                      ),
                      _OptionChip(
                        label: 'Light / Spotting prone',
                        icon: Icons.grain_rounded,
                        selected: _flowTendency == 'Light / Spotting prone',
                        onTap: () => setState(() => _flowTendency = 'Light / Spotting prone'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // CONTINUE
                  // ------------------------------------------------

                  PrimaryButton(
                    label: _isSaving
                        ? 'Saving...'
                        : 'Continue to Cheri',
                    trailingIcon: _isSaving
                        ? null
                        : Icons.arrow_forward_rounded,
                    onPressed:
                        _isSaving ? null : _saveProfile,
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'Your information stays private and secure.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 12.5,
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
}

// ============================================================
// AVATAR MODEL
// ============================================================

class _CheriAvatar {
  const _CheriAvatar({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

// ============================================================
// SELECTOR CARD
// ============================================================

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.roseLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.roseLight.withValues(
                    alpha: 0.45,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.crimson,
                  size: 21,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.crimson,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OPTION CHIP
// ============================================================

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isAlert = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.rose, AppColors.crimsonDark],
                )
              : null,
          color: selected
              ? null
              : (isAlert ? const Color(0xFFFFF0F2) : Colors.white),
          border: Border.all(
            color: selected
                ? AppColors.crimson
                : (isAlert
                    ? AppColors.rose.withValues(alpha: 0.5)
                    : AppColors.roseLight),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : (isAlert ? AppColors.crimson : AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isAlert ? AppColors.crimson : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DAY 1 PAD RECOMMENDATION CELEBRATION DIALOG
// ============================================================

class _DayOnePadDialog extends StatelessWidget {
  const _DayOnePadDialog({
    required this.user,
    required this.onContinue,
  });

  final UserModel user;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.rose, AppColors.crimsonDark],
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user.name}! 🌸',
              style: AppTextStyles.headline.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your Personalized Day 1 Pad is ready',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.crimson,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFF2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.roseLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          color: AppColors.crimson, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.dayOnePadRecommendation,
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 14.5,
                            color: AppColors.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Matched to your profile: ${user.skinSensitivity} • '
                    '${user.bodyType} • ${user.dailyRoutine}. '
                    'This ensures zero irritation, zero chafing, and maximum leakage protection for your start.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'As you log your daily symptoms and routine, Cheri’s Gemini AI '
              'will adjust your pad and wellness advice every day.',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Start Exploring Cheri →',
              height: 48,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}