import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/petals.dart';
import '../../widgets/primary_button.dart';

class _OnboardingPage {
  const _OnboardingPage(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      Icons.calendar_month_rounded,
      'Track your cycle with ease',
      'Log periods, flow and symptoms in seconds and get gentle predictions '
          'you can trust.',
    ),
    _OnboardingPage(
      Icons.insights_rounded,
      'Understand your body',
      'See patterns in your mood, energy and symptoms so you know what to '
          'expect in each phase.',
    ),
    _OnboardingPage(
      Icons.lock_rounded,
      'Private, always',
      'Your data stays encrypted and under your control, with an optional '
          'app lock for extra peace of mind.',
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AppState>().completeOnboarding();
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: Text('Skip', style: AppTextStyles.link),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _PageBody(page: _pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.crimson
                            : AppColors.roseLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: PrimaryButton(
                  label: _isLast ? AppStrings.getStarted : 'Next',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CustomPaint(
                    size: Size(260, 260),
                    painter: _IllustrationPainter(),
                  ),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.rose, AppColors.crimsonDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withOpacity(0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(page.icon, size: 84, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 12),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.48,
      Paint()..color = AppColors.roseLight.withOpacity(0.25),
    );
    paintBlossom(canvas, Offset(w * 0.12, h * 0.26), w * 0.08, 0.3, 0.85);
    paintBlossom(canvas, Offset(w * 0.90, h * 0.20), w * 0.06, 1.1, 0.75);
    paintBlossom(canvas, Offset(w * 0.86, h * 0.82), w * 0.09, 0.7, 0.85);
    paintBlossom(canvas, Offset(w * 0.16, h * 0.84), w * 0.05, 2.0, 0.7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}