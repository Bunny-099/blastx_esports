import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../live/presentation/live_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tournaments/presentation/upcoming_tournaments_screen.dart';
import '../providers/navigation_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const LiveScreen(),
      const UpcomingTournamentsScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: AppColors.surface,
        buttonBackgroundColor: AppColors.primary,
        animationDuration: const Duration(milliseconds: 300),
        index: selectedIndex,
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              Icons.live_tv,
              color: selectedIndex == 0 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Live',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.event_available,
              color: selectedIndex == 1 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Upcoming',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.person,
              color: selectedIndex == 2 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Profile',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.settings,
              color: selectedIndex == 3 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Settings',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
