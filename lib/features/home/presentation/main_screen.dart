import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../challenges/presentation/challenges_screen.dart';
import '../../live/presentation/live_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/widgets/first_time_profile_dialog.dart';
import '../../profile/providers/profile_provider.dart';
import '../../splash/providers/splash_providers.dart';
import '../../tournaments/presentation/tournaments_screen.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialProfileSetup();
    });
  }

  void _checkInitialProfileSetup() {
    if (!mounted || _isDialogShowing) return;

    final profileState = ref.read(profileProvider);
    final user = profileState.user;
    if (profileState.isLoading || user == null) return;

    final storage = ref.read(storageServiceProvider);
    final isAlreadyCompleted = storage.getString('profile_setup_completed_${user.id}') == 'true';

    final isPhoneMissing = user.phone == null || user.phone!.trim().isEmpty;
    final isNameMissing = user.name.trim().isEmpty || user.name.trim() == 'Gamer';

    if ((isPhoneMissing || isNameMissing) && !isAlreadyCompleted) {
      _isDialogShowing = true;
      FirstTimeProfileDialog.show(context, user).then((_) {
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      if (!next.isLoading && next.user != null) {
        _checkInitialProfileSetup();
      }
    });

    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const HomeScreen(),
      const TournamentsScreen(),
      const LiveScreen(),
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
              Icons.home_rounded,
              color: selectedIndex == 0 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Home',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedIndex == 0 ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.emoji_events_rounded,
              color: selectedIndex == 1 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Tournaments',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedIndex == 1 ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.live_tv_rounded,
              color: selectedIndex == 2 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Live',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedIndex == 2 ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.extension_rounded,
              color: selectedIndex == 3 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Challenges',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedIndex == 3 ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.person_rounded,
              color: selectedIndex == 4 ? Colors.white : AppColors.textSecondary,
            ),
            label: 'Profile',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedIndex == 4 ? AppColors.primaryLight : AppColors.textSecondary,
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
