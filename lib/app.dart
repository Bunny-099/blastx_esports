import 'package:blastix_esports/core/theme/app_theme.dart';
import 'package:blastix_esports/features/auth/presentation/login_screen.dart';
import 'package:blastix_esports/features/home/presentation/main_screen.dart';
import 'package:blastix_esports/features/live/presentation/tournament_detail_screen.dart';
import 'package:blastix_esports/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BlastIX Esports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/tournament-detail') {
          final tournamentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => TournamentDetailScreen(tournamentId: tournamentId),
          );
        }
        return null;
      },
    );
  }
}
