import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/petals.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/settings_tile.dart';

class AppLockScreen extends StatelessWidget {
  const AppLockScreen({super.key});

  Future<void> _togglePin(BuildContext context, bool enable) async {
    final state = context.read<AppState>();
    if (!enable) {
      state.setPin(null);
      return;
    }
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _PinDialog(),
    );
    if (pin != null) state.setPin(pin);
  }

  void _continue(BuildContext context) {
    final state = context.read<AppState>();
    final anyMethod =
        state.fingerprintEnabled || state.faceIdEnabled || state.pinEnabled;
    state.setAppLock(anyMethod);
    Helpers.showSnack(
      context,
      anyMethod ? 'App lock is on 🔒' : 'App lock is off',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const AppHeader(title: 'App Lock'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: Image.asset(
                        AppAssets.lockBlossom,
                        height: 190,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const _PadlockIllustration(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Keep your data private',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use a PIN or biometric lock to protect your app.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: 22),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          SettingsTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Use Fingerprint',
                            trailing: Switch(
                              value: state.fingerprintEnabled,
                              onChanged: (v) =>
                                  context.read<AppState>().setFingerprint(v),
                            ),
                          ),
                          const Divider(indent: 58, endIndent: 16),
                          SettingsTile(
                            icon: Icons.face_retouching_natural_rounded,
                            title: 'Use Face ID',
                            trailing: Switch(
                              value: state.faceIdEnabled,
                              onChanged: (v) =>
                                  context.read<AppState>().setFaceId(v),
                            ),
                          ),
                          const Divider(indent: 58, endIndent: 16),
                          SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Set 4-digit PIN',
                            trailing: Switch(
                              value: state.pinEnabled,
                              onChanged: (v) => _togglePin(context, v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      color: const Color(0xFFFFE9EC),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppColors.crimson, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can also lock the app automatically after '
                              'a period of inactivity.',
                              style:
                                  AppTextStyles.body.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: AppStrings.continueLabel,
                      onPressed: () => _continue(context),
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

/// Fallback padlock drawn with widgets, with blossoms around it.
class _PadlockIllustration extends StatelessWidget {
  const _PadlockIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _LockBlossomPainter()),
          ),
          SizedBox(
            width: 120,
            height: 150,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 70,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(35),
                      ),
                      border: Border.all(
                        color: AppColors.crimsonDark,
                        width: 12,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.rose, AppColors.crimsonDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 7,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBlossomPainter extends CustomPainter {
  const _LockBlossomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    paintBlossom(canvas, Offset(w * 0.86, h * 0.30), 20, 0.4, 0.9);
    paintBlossom(canvas, Offset(w * 0.96, h * 0.62), 12, 1.2, 0.8);
    paintBlossom(canvas, Offset(w * 0.12, h * 0.70), 11, 0.9, 0.75);
    canvas.save();
    canvas.translate(w * 0.80, h * 0.86);
    canvas.rotate(2.0);
    paintPetal(
      canvas,
      10,
      Paint()..color = AppColors.roseLight.withOpacity(0.8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final TextEditingController _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.text.length != 4) {
      setState(() => _error = 'Enter exactly 4 digits');
      return;
    }
    Navigator.pop(context, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Set a 4-digit PIN', style: AppTextStyles.sectionTitle),
      content: TextField(
        controller: _pin,
        autofocus: true,
        obscureText: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: AppTextStyles.headline.copyWith(letterSpacing: 8),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(counterText: '', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Set PIN')),
      ],
    );
  }
}