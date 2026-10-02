import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/widgets/tournament_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestCard(TournamentModel tournament) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TournamentCard(
            tournament: tournament,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  group('TournamentCard Widget Tests', () {
    testWidgets('renders LIVE tournament card correctly', (WidgetTester tester) async {
      final liveTournament = TournamentModel(
        id: 'tourney_live_1',
        name: 'Free Fire World Cup',
        game: 'Free Fire',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 100000,
        viewersCount: 2500,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'Garena',
        maxSlots: 48,
        filledSlots: 32,
        isRegistered: true,
      );

      await tester.pumpWidget(buildTestCard(liveTournament));

      expect(find.text('Free Fire World Cup'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('• 2.5K watching'), findsOneWidget);
      expect(find.text('Registered ✓'), findsOneWidget);
      expect(find.text('32/48 slots'), findsOneWidget);
    });

    testWidgets('renders UPCOMING tournament card with countdown', (WidgetTester tester) async {
      final futureTime = DateTime.now().add(const Duration(hours: 2, minutes: 14));
      final upcomingTournament = TournamentModel(
        id: 'tourney_upcoming_1',
        name: 'Free Fire Open 2026',
        game: 'Free Fire',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 50000,
        viewersCount: 0,
        status: TournamentStatus.upcoming,
        startTime: futureTime,
        organizer: 'BlastX Esports',
        startsAt: futureTime,
        maxSlots: 48,
        filledSlots: 48,
        isRegistered: false,
      );

      await tester.pumpWidget(buildTestCard(upcomingTournament));

      expect(find.text('Free Fire Open 2026'), findsOneWidget);
      expect(find.textContaining('Starts in 02h'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('48/48 slots'), findsOneWidget);
      expect(find.text('FULL'), findsOneWidget);
    });

    testWidgets('renders COMPLETED tournament card with Ended label', (WidgetTester tester) async {
      final completedTournament = TournamentModel(
        id: 'tourney_completed_1',
        name: 'Free Fire Championship',
        game: 'Free Fire',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 25000,
        viewersCount: 0,
        status: TournamentStatus.completed,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        organizer: 'BlastX Esports',
        maxSlots: 32,
        filledSlots: 32,
        isRegistered: false,
      );

      await tester.pumpWidget(buildTestCard(completedTournament));

      expect(find.text('Free Fire Championship'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });
  });
}
