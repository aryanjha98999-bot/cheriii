import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../models/app_state.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'custom_nav_bar.dart';

/// Hosts the five main tabs with a persistent bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _tabs = [
    HomeScreen(),
    CalendarScreen(),
    ChatScreen(),
    InsightsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: state.tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<AppState>().setTab(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgTop,
        body: IndexedStack(index: state.tabIndex, children: _tabs),
        bottomNavigationBar: keyboardOpen
            ? null
            : CustomNavBar(
                currentIndex: state.tabIndex,
                onTap: context.read<AppState>().setTab,
              ),
      ),
    );
  }
}