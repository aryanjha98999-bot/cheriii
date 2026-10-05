import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/strings.dart';
import 'core/theme/app_theme.dart';
import 'models/app_state.dart';
import 'screens/app_lock/app_lock_screen.dart';
import 'screens/checkin/checkin_screen.dart';
import 'screens/learn/learn_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/wellness/wellness_screen.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final appState = AppState();
  await appState.load();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const CheriApp(),
    ),
  );
}

class CheriApp extends StatelessWidget {
  const CheriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.main: (_) => const MainShell(),
        AppRoutes.checkIn: (_) => const CheckInScreen(),
        AppRoutes.wellness: (_) => const WellnessScreen(),
        AppRoutes.learn: (_) => const LearnScreen(),
        AppRoutes.reminders: (_) => const RemindersScreen(),
        AppRoutes.appLock: (_) => const AppLockScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}