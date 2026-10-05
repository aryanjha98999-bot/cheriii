import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/petals.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/safe_asset_image.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _getStarted(BuildContext context) {
    final done = context.read<AppState>().onboardingDone;
    Navigator.pushReplacementNamed(
      context,
      done ? AppRoutes.main : AppRoutes.onboarding,
    );
  }

  void _signIn(BuildContext context) {
    context.read<AppState>().completeOnboarding();
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final s = Helpers.scale(context);

    return Scaffold(
      body: AppBackground(
        petals: false,
        child: Stack(
          children: [
            const Positioned.fill(child: FallingPetals(count: 18)),
            SafeArea(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 16),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 10 * s),
                      const _HeartBadge(),
                      Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.script
                            .copyWith(fontSize: 78 * s),
                      ),
                      Text(
                        AppStrings.tagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) => SafeAssetImage(
                            AppAssets.onboardingHero,
                            width: box.maxWidth,
                            height: box.maxHeight,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            radius: 32,
                            fallbackIcon: Icons.spa_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.splashSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: AppStrings.getStarted,
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => _getStarted(context),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 12.5),
                          ),
                          InkWell(
                            onTap: () => _signIn(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                              child: Text(
                                AppStrings.signIn,
                                style: AppTextStyles.link.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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

/// Heart icon with small blossoms either side, shown above the logo.
class _HeartBadge extends StatelessWidget {
  const _HeartBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          CustomPaint(size: Size(84, 64), painter: _HeartPetalsPainter()),
          Icon(Icons.favorite_rounded, size: 42, color: AppColors.crimson),
        ],
      ),
    );
  }
}

class _HeartPetalsPainter extends CustomPainter {
  const _HeartPetalsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    paintBlossom(canvas, Offset(size.width * 0.12, size.height * 0.60), 9, 0.5, 0.75);
    paintBlossom(canvas, Offset(size.width * 0.90, size.height * 0.28), 7, 1.2, 0.65);
    canvas.save();
    canvas.translate(size.width * 0.80, size.height * 0.85);
    canvas.rotate(2.2);
    paintPetal(
      canvas,
      6,
      Paint()..color = AppColors.roseLight.withOpacity(0.7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}