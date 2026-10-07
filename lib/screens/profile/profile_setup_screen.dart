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
        );
      } catch (e) {
        debugPrint('Remote profile creation error: $e');
      }

      if (!mounted) return;

      final appState = context.read<AppState>();
      appState.updateUser(updatedUser, syncRemote: false);
      appState.completeOnboarding();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
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