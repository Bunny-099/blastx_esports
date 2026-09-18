import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../challenges/presentation/challenges_screen.dart';
import '../../live/presentation/live_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../tournaments/presentation/tournaments_screen.dart';
import '../providers/navigation_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const LiveScreen(),
      const TournamentsScreen(),
      const ChallengesScreen(),
      const ProfileScreen(),
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
              Icons.emoji_events,
              color: selectedIndex == 1 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Tournaments',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.extension,
              color: selectedIndex == 2 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Challenges',
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.person,
              color: selectedIndex == 3 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Profile',
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
