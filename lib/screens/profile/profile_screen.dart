import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../models/user_model.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/safe_asset_image.dart';
import '../../widgets/settings_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
  ];

  void _sheet(BuildContext context, Widget Function(BuildContext) builder) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }

  void _editProfile(BuildContext context, UserModel user) {
    _sheet(context, (_) => _EditProfileSheet(user: user));
  }

  void _pickLanguage(BuildContext context) {
    _sheet(context, (ctx) {
      final current = ctx.read<AppState>().language;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text('Language', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              for (final lang in _languages)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ctx.read<AppState>().setLanguage(lang);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontWeight: lang == current
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (lang == current)
                          const Icon(Icons.check_rounded,
                              color: AppColors.crimson),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'The interface is currently available in English. More '
                'languages are on the way.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    });
  }

  void _privacy(BuildContext context) {
    _sheet(context, (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text('Privacy & Data', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              for (final line in const [
                'Your entries are stored on this device.',
                'You choose what to log. Nothing is shared without your say.',
                'Turn on App Lock with a PIN or biometrics for extra privacy.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3, right: 10),
                        child: Icon(Icons.favorite_rounded,
                            size: 12, color: AppColors.crimson),
                      ),
                      Expanded(child: Text(line, style: AppTextStyles.body)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Manage App Lock',
                height: 48,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.appLock);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  void _help(BuildContext context) {
    _sheet(context, (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text('Help & Support', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              Text('How do I log my period?', style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text(
                'Open the Calendar tab, pick a day and tap Log Period.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              Text('How are predictions made?',
                  style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text(
                'Cheri uses your last period date and average cycle length. '
                'You can change both in Cycle Settings.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              Text('Still stuck?', style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text('Email us at help@cheri.example',
                  style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    final rows = <Widget>[
      SettingsTile(
        icon: Icons.event_note_rounded,
        title: 'Cycle Settings',
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
      SettingsTile(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
      ),
      SettingsTile(
        icon: Icons.lock_outline_rounded,
        title: 'App Lock',
        trailing: Switch(
          value: state.appLockEnabled,
          onChanged: (v) => context.read<AppState>().setAppLock(v),
        ),
        onTap: () => Navigator.pushNamed(context, AppRoutes.appLock),
      ),
      SettingsTile(
        icon: Icons.language_rounded,
        title: 'Language',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.language, style: AppTextStyles.bodyMuted),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
        onTap: () => _pickLanguage(context),
      ),
      SettingsTile(
        icon: Icons.shield_outlined,
        title: 'Privacy & Data',
        onTap: () => _privacy(context),
      ),
      SettingsTile(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        onTap: () => _help(context),
      ),
      SettingsTile(
        icon: Icons.info_outline_rounded,
        title: 'About Cheri',
        onTap: () => showAboutDialog(
          context: context,
          applicationName: AppStrings.appName,
          applicationVersion: '1.0.0',
          applicationLegalese: AppStrings.tagline,
        ),
      ),
    ];

    return AppBackground(
      child: Column(
        children: [
          AppHeader(
            title: 'My Profile',
            onBack: () => context.read<AppState>().setTab(0),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // ---- Avatar + name ----
                  Row(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border:
                              Border.all(color: AppColors.crimson, width: 2.5),
                        ),
                        child: ClipOval(
                          child: SafeAssetImage(
                            user.avatarAsset,
                            width: 76,
                            height: 76,
                            fallbackIcon: Icons.person_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headline
                                  .copyWith(fontSize: 22),
                            ),
                            Text('${user.age} years old',
                                style: AppTextStyles.bodyMuted),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _editProfile(context, user),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('View & edit profile',
                                        style: AppTextStyles.link),
                                    const Icon(Icons.chevron_right_rounded,
                                        size: 16, color: AppColors.crimson),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- Settings list ----
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i > 0) const Divider(indent: 58, endIndent: 16),
                          rows[i],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Privacy card ----
                  AppCard(
                    color: const Color(0xFFFFE9EC),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 44, color: AppColors.crimson),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.privacyTitle,
                                  style: AppTextStyles.cardTitle),
                              const SizedBox(height: 2),
                              Text(AppStrings.privacyBody,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final UserModel user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _age =
      TextEditingController(text: '${widget.user.age}');
  String? _nameError;
  String? _ageError;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Please enter your name' : null;
      _ageError =
          (age == null || age < 1 || age > 120) ? 'Enter a valid age' : null;
    });
    if (_nameError != null || _ageError != null) return;

    context
        .read<AppState>()
        .updateUser(widget.user.copyWith(name: name, age: age));
    Navigator.pop(context);
    Helpers.showSnack(context, 'Profile updated 💕');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text('Edit profile', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Age',
                  errorText: _ageError,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Save', height: 48, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}