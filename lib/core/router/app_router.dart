import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/main_screen.dart';
import '../../features/live/presentation/tournament_detail_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// ============================================================
/// APP ROUTER & DEEP LINK HANDLER
/// Supports deep links:
/// - blastix://tournaments/:id/match
/// - blastix://tournaments/:id/teams
/// - blastix://tournaments/:id/standings
/// - blastix://tournaments/:id/wildcard
/// ============================================================

import '../../features/profile/presentation/profile_setup_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');

    // Handle deep links: blastix://tournaments/:id/match, /teams, /standings, /wildcard
    if (uri != null && (uri.scheme == 'blastix' || settings.name?.startsWith('/tournaments') == true)) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'tournaments') {
        final tournamentId = pathSegments[1];
        int initialTab = 0;
        if (pathSegments.length >= 3) {
          final action = pathSegments[2].toLowerCase();
          if (action == 'match') {
            initialTab = 4; // Match Tab
          } else if (action == 'teams') {
            initialTab = 2; // Teams Tab
          } else if (action == 'standings' || action == 'leaderboard') {
            initialTab = 3; // Standings / Brackets Tab
          } else if (action == 'roadmap') {
            initialTab = 1; // Roadmap Tab
          } else if (action == 'wildcard') {
            initialTab = 0; // Overview Tab
          }
        }

        return MaterialPageRoute(
          builder: (context) => TournamentDetailScreen(
            tournamentId: tournamentId,
            initialTabIndex: initialTab,
          ),
          settings: settings,
        );
      }
    }

    if (settings.name == '/tournament-detail') {
      final args = settings.arguments;
      String tournamentId = '';
      int initialTab = 0;

      if (args is String) {
        tournamentId = args;
      } else if (args is Map<String, dynamic>) {
        tournamentId = args['tournamentId']?.toString() ?? args['id']?.toString() ?? '';
        initialTab = (args['initialTab'] as num?)?.toInt() ?? 0;
      }

      return MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(
          tournamentId: tournamentId,
          initialTabIndex: initialTab,
        ),
      );
    }

    return null;
  }

  static Map<String, WidgetBuilder> get routes => {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
      };
}
