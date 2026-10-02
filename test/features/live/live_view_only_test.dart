import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/tournament_detail_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/tournament_card.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUpcomingTournament = TournamentModel(
    id: 't_test_1',
    name: 'Free Fire Championship',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 50000,
    viewersCount: 1250,
    status: TournamentStatus.upcoming,
    startTime: DateTime.now().add(const Duration(hours: 2, minutes: 14)),
    organizer: 'BlastX Esports',
    entryFee: 50,
    isRegistered: true,
    maxSlots: 48,
    filledSlots: 32,
  );

  group('View-Only Live Section Widget Tests', () {
    testWidgets('TournamentCard with viewOnly = true hides registration badge and slots bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentCard(
              tournament: testUpcomingTournament,
              onTap: () {},
              viewOnly: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify tournament title is rendered
      expect(find.text('Free Fire Championship'), findsOneWidget);

      // Verify "Registered ✓" chip and slots count text are hidden in view-only mode
      expect(find.text('Registered ✓'), findsNothing);
      expect(find.text('32/48 slots'), findsNothing);
    });

    testWidgets('TournamentCard with viewOnly = false displays registration badge and slots bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentCard(
              tournament: testUpcomingTournament,
              onTap: () {},
              viewOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify tournament title, registration chip, and slots progress text are displayed
      expect(find.text('Free Fire Championship'), findsOneWidget);
      expect(find.text('Registered ✓'), findsOneWidget);
      expect(find.text('32/48 slots'), findsOneWidget);
    });

    testWidgets('TournamentDetailScreen with viewOnly = true hides JOIN NOW button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveTournamentsProvider.overrideWithValue([testUpcomingTournament]),
          ],
          child: MaterialApp(
            home: TournamentDetailScreen(
              tournamentId: 't_test_1',
              viewOnly: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify JOIN NOW / Register CTA button is hidden
      expect(find.textContaining('JOIN NOW'), findsNothing);

      // Verify countdown info bar is displayed for upcoming tournament in view-only mode
      expect(find.textContaining('Starts in'), findsOneWidget);
    });

    testWidgets('TournamentDetailScreen with viewOnly = false displays JOIN NOW button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveTournamentsProvider.overrideWithValue([testUpcomingTournament]),
          ],
          child: MaterialApp(
            home: TournamentDetailScreen(
              tournamentId: 't_test_1',
              viewOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify JOIN NOW CTA button is displayed
      expect(find.textContaining('JOIN NOW'), findsOneWidget);
    });
  });
}
