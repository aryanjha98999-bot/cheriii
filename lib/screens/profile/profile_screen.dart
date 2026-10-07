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
import '../../widgets/settings_tile.dart';
import '../../widgets/user_avatar.dart';

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
                'Your entries are encrypted and securely stored.',
                'You choose what to log. Nothing is shared without your consent.',
                'Turn on App Lock with a PIN or biometrics for extra peace of mind.',
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
                'Cheri uses your last period date and cycle length. '
                'You can adjust them anytime in Cycle Settings.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              Text('Have questions?', style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text('Reach out to us at help@cheriapp.com 💕',
                  style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out of Cheri?'),
        content: const Text(
          'You will be returned to the sign-in screen. Your synced data is safely stored in your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AppState>().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final isLoggedIn = state.isLoggedIn;
    final userEmail = state.userEmail;

    final rows = <Widget>[
      SettingsTile(
        icon: Icons.event_note_rounded,
        title: 'Cycle Settings',
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
      SettingsTile(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications & Reminders',
        onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
      ),
      SettingsTile(
        icon: Icons.auto_awesome_rounded,
        title: 'Cherry AI Settings',
        subtitle: state.geminiApiKey.isEmpty
            ? 'Add free Gemini API key to unlock AI'
            : 'AI connected ✓',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.geminiApiKey.isEmpty
                    ? AppColors.toggleOff
                    : AppColors.crimson,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
        onTap: () => _sheet(context, (_) => const _ApiKeySheet()),
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
                  // ---- Avatar + name + email ----
                  Row(
                    children: [
                      UserAvatar(
                        avatar: user.avatarAsset,
                        size: 84,
                        borderWidth: 2.5,
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
                            if (isLoggedIn && userEmail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.crimson,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                  const SizedBox(height: 16),

                  // ---- Guest Account Callout if not logged in ----
                  if (!isLoggedIn)
                    AppCard(
                      color: const Color(0xFFFFF4F6),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.roseTint,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined,
                                color: AppColors.crimson, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sync your cycle data',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign in to back up your data across devices.',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.crimson,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.login),
                            child: const Text('Sign In',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

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

                  // ---- Sign Out Button (if logged in) ----
                  if (isLoggedIn)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.crimson,
                        title: 'Sign Out',
                        subtitle: 'Logged in as $userEmail',
                        showChevron: true,
                        onTap: () => _confirmSignOut(context),
                      ),
                    ),

                  if (isLoggedIn) const SizedBox(height: 16),

                  // ---- Privacy Card ----
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
  late String _selectedAvatar = widget.user.avatarAsset;
  late String _skinSensitivity = widget.user.skinSensitivity;
  late String _bodyType = widget.user.bodyType;
  late String _dailyRoutine = widget.user.dailyRoutine;
  late String _flowTendency = widget.user.flowTendency;

  String? _nameError;
  String? _ageError;

  static const List<Map<String, dynamic>> _avatarList = [
    {'id': 'flower', 'icon': Icons.local_florist_rounded},
    {'id': 'favorite', 'icon': Icons.favorite_rounded},
    {'id': 'face', 'icon': Icons.face_3_rounded},
    {'id': 'pets', 'icon': Icons.pets_rounded},
    {'id': 'star', 'icon': Icons.star_rounded},
    {'id': 'butterfly', 'icon': Icons.flutter_dash_rounded},
  ];

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

    final updated = widget.user.copyWith(
      name: name,
      age: age,
      avatarAsset: _selectedAvatar,
      skinSensitivity: _skinSensitivity,
      bodyType: _bodyType,
      dailyRoutine: _dailyRoutine,
      flowTendency: _flowTendency,
    );

    context.read<AppState>().updateUser(updated);
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
              Text('Edit Profile', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),

              // Avatar picker
              Text('Choose Avatar', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _avatarList.map((av) {
                  final id = av['id'] as String;
                  final icon = av['icon'] as IconData;
                  final selected = _selectedAvatar == id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = id),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: selected
                            ? const LinearGradient(
                                colors: [AppColors.rose, AppColors.crimsonDark],
                              )
                            : null,
                        color: selected ? null : AppColors.roseTint,
                        border: Border.all(
                          color: selected
                              ? AppColors.crimson
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected ? Colors.white : AppColors.crimson,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
              const SizedBox(height: 16),

              // Skin Sensitivity & Rashes
              Text('Skin Sensitivity & Rashes', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _skinSensitivity,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Prone to rashes & chafing', child: Text('Prone to rashes & chafing')),
                  DropdownMenuItem(value: 'Sensitive skin', child: Text('Sensitive skin')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _skinSensitivity = v);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(height: 12),

              // Body Type
              Text('Body Type & Fit', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _bodyType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Curvy / Wide hips', child: Text('Curvy / Wide hips')),
                  DropdownMenuItem(value: 'Athletic / Tall', child: Text('Athletic / Tall')),
                  DropdownMenuItem(value: 'Petite / Slim', child: Text('Petite / Slim')),
                  DropdownMenuItem(value: 'Regular fit', child: Text('Regular fit')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _bodyType = v);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(height: 12),

              // Daily Routine
              Text('Daily Movement Routine', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _dailyRoutine,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Active / Gym / Sports', child: Text('Active / Gym / Sports')),
                  DropdownMenuItem(value: 'Desk job / Long sitting', child: Text('Desk job / Long sitting')),
                  DropdownMenuItem(value: 'On feet / Travelling', child: Text('On feet / Travelling')),
                  DropdownMenuItem(value: 'Moderate / Mixed', child: Text('Moderate / Mixed')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _dailyRoutine = v);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(height: 12),

              // Flow Tendency
              Text('Initial Flow Tendency', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _flowTendency,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Heavy initial days', child: Text('Heavy initial days')),
                  DropdownMenuItem(value: 'Medium balanced', child: Text('Medium balanced')),
                  DropdownMenuItem(value: 'Light / Spotting prone', child: Text('Light / Spotting prone')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _flowTendency = v);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),

              const SizedBox(height: 20),
              PrimaryButton(label: 'Save Changes', height: 48, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// API Key Sheet — appended to profile_screen.dart
// ----------------------------------------------------------------

class _ApiKeySheet extends StatefulWidget {
  const _ApiKeySheet();

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  late final TextEditingController _ctrl;
  bool _obscure = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<AppState>().geminiApiKey;
    _ctrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setGeminiApiKey(_ctrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
    Helpers.showSnack(context, 'Cherry AI key saved 💕');
  }

  void _clear() {
    _ctrl.clear();
    context.read<AppState>().setGeminiApiKey('');
    setState(() => _saved = false);
    Helpers.showSnack(context, 'API key removed');
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
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.crimson, size: 20),
                  const SizedBox(width: 8),
                  Text('Cherry AI Settings',
                      style: AppTextStyles.sectionTitle),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cherry AI uses Google Gemini to read your full cycle history, '
                'symptoms, mood, sleep and chat — and writes deeply personal '
                'daily journals and pad suggestions just for you.',
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 16),

              // Key card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to get your FREE key:',
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    _Step(
                        n: '1',
                        text:
                            'Go to aistudio.google.com/apikey'),
                    _Step(n: '2', text: 'Sign in with your Google account'),
                    _Step(n: '3', text: 'Click "Create API key" — it\'s free'),
                    _Step(n: '4', text: 'Paste the key below and save'),
                    const SizedBox(height: 4),
                    Text(
                      '✓ Free tier: 1 million tokens/day, 15 requests/minute',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.crimson),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _ctrl,
                obscureText: _obscure,
                style: AppTextStyles.body.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIza...',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.rose,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔒 Stored only on your device. Never sent anywhere except Google\'s API.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  if (context.watch<AppState>().geminiApiKey.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.crimson,
                          side:
                              const BorderSide(color: AppColors.roseLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Remove Key'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _saved ? 'Saved ✓' : 'Save & Enable AI',
                      height: 50,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.crimson,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 12.5))),
        ],
      ),
    );
  }
}