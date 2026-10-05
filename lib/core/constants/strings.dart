class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String checkIn = '/check-in';
  static const String wellness = '/wellness';
  static const String learn = '/learn';
  static const String reminders = '/reminders';
  static const String appLock = '/app-lock';
  static const String settings = '/settings';
}

class AppAssets {
  AppAssets._();

  static const String onboardingHero = 'assets/images/onboarding_hero.png';
  static const String avatar = 'assets/images/avatar_aarohi.png';
  static const String teaCup = 'assets/images/tea_cup.png';
  static const String lockBlossom = 'assets/images/lock_blossom.png';

  static const String yoga = 'assets/images/wellness_yoga.png';
  static const String breathing = 'assets/images/wellness_breathing.png';
  static const String healthyFoods = 'assets/images/wellness_foods.png';
  static const String selfCare = 'assets/images/wellness_selfcare.png';

  static const String articleCycle = 'assets/images/article_cycle.png';
  static const String articleCramps = 'assets/images/article_cramps.png';
  static const String articleFoods = 'assets/images/article_foods.png';
  static const String articleIrregular = 'assets/images/article_irregular.png';
  static const String articleMyths = 'assets/images/article_myths.png';
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Cheri';
  static const String tagline = 'Your Cycle, Your Strength';
  static const String splashSubtitle =
      'A safe space for your periods, health and happiness';
  static const String getStarted = 'Get Started';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signIn = 'Sign In';

  // Bottom nav
  static const String navHome = 'Home';
  static const String navCalendar = 'Calendar';
  static const String navAskAi = 'Ask AI';
  static const String navInsights = 'Insights';
  static const String navProfile = 'Profile';

  // Home
  static String greeting(String name) => 'Hey, $name! 🌸';
  static const String homeSubtitle = "You're doing great today!";
  static const String periodMayStart = 'Your period may start in';
  static const String currentPhase = 'Current Phase';
  static const String viewDetails = 'View Details';
  static const String todaysCheckIn = "Today's Check-in";
  static const String howFeeling = 'How are you feeling today?';
  static const String forYouToday = 'For You Today';
  static const String forYouBody =
      'You may feel a bit low in energy. Try a warm drink, gentle stretches '
      'and get some extra rest. 💕';

  // Chat
  static const String botName = 'Cherry AI';
  static const String botTagline = 'Your Personal Wellness Companion';
  static const String askHint = 'Ask me anything...';
  static const String botGreeting =
      "Hey Aarohi! 💕\nI'm Cherry, here to help you with your period, "
      'symptoms, self-care and any questions you have.\n'
      'How can I support you today?';
  static const List<String> chatSuggestions = [
    'Why do I get cramps?',
    'Is my cycle regular?',
    'Healthy foods',
    'Mood swings',
    'Skincare tips',
  ];

  // Privacy
  static const String privacyTitle = 'Your privacy matters';
  static const String privacyBody = 'Your data is encrypted and always private.';

  // Buttons
  static const String saveEntry = 'Save Entry';
  static const String saveCheckIn = 'Save Check-in';
  static const String saveSettings = 'Save Settings';
  static const String continueLabel = 'Continue';
  static const String logPeriod = 'Log Period';
}