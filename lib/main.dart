import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/strings.dart';
import 'core/theme/app_theme.dart';
import 'models/app_state.dart';

import 'screens/app_lock/app_lock_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/checkin/checkin_screen.dart';
import 'screens/learn/learn_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/journal/ai_journal_screen.dart';

import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // SUPABASE
  // ------------------------------------------------------------

  await Supabase.initialize(
    url: 'https://kggfxrkmncotvvcucpxu.supabase.co',
    publishableKey:
        'sb_publishable_e2Px5gFot3Hb6AK0aPmfNg_mpoIlyi9',
  );

  // ------------------------------------------------------------
  // DEVICE ORIENTATION
  // ------------------------------------------------------------

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ------------------------------------------------------------
  // SYSTEM UI
  // ------------------------------------------------------------

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ------------------------------------------------------------
  // CHERI APP STATE
  // ------------------------------------------------------------

  final appState = AppState();

  // Load local cache + Supabase data if a session
  // already exists.
  await appState.load();

  // ------------------------------------------------------------
  // AUTH STATE LISTENER
  // ------------------------------------------------------------
  //
  // This is IMPORTANT.
  //
  // When the user signs up or signs in, Supabase creates/
  // restores a session AFTER the initial AppState.load().
  //
  // We therefore reload AppState whenever authentication
  // changes so the demo Aarohi user is replaced by the
  // actual Supabase profile.
  //

  Supabase.instance.client.auth.onAuthStateChange.listen(
    (authState) async {
      final event = authState.event;

      debugPrint(
        'Supabase auth event: $event',
      );

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.initialSession) {
        await appState.load();

        debugPrint(
          'AppState refreshed after authentication.',
        );
      }

      if (event == AuthChangeEvent.signedOut) {
        // Reset the state so the next user cannot see
        // the previous user's cached information.
        await appState.load();

        debugPrint(
          'AppState refreshed after sign out.',
        );
      }
    },
  );

  // ------------------------------------------------------------
  // START APP
  // ------------------------------------------------------------

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

      // --------------------------------------------------------
      // ROUTES
      // --------------------------------------------------------

      routes: {
        // Splash
        AppRoutes.splash: (_) =>
            const SplashScreen(),

        // Onboarding
        AppRoutes.onboarding: (_) =>
            const OnboardingScreen(),

        // Authentication
        AppRoutes.login: (_) =>
            const LoginScreen(),

        AppRoutes.signUp: (_) =>
            const SignUpScreen(),

        // Main application
        AppRoutes.main: (_) =>
            const MainShell(),

        // Check-in
        AppRoutes.checkIn: (_) =>
            const CheckInScreen(),

        // Wellness
        AppRoutes.wellness: (_) =>
            const WellnessScreen(),

        // Learn
        AppRoutes.learn: (_) =>
            const LearnScreen(),

        // Reminders
        AppRoutes.reminders: (_) =>
            const RemindersScreen(),

        // App lock
        AppRoutes.appLock: (_) =>
            const AppLockScreen(),

        // Settings
        AppRoutes.settings: (_) =>
            const SettingsScreen(),

        // Profile setup
        AppRoutes.profileSetup: (_) =>
            const ProfileSetupScreen(),
      },
    );
  }
}