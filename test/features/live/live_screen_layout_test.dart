import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/features/live/presentation/live_screen.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTournament = TournamentModel(
    id: 't_live_1',
    name: 'Free Fire Premier Cup',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 100000,
    viewersCount: 5200,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 30)),
    organizer: 'BlastX Esports',
    entryFee: 0,
    isRegistered: false,
    maxSlots: 100,
    filledSlots: 100,
  );

  group('LiveScreen Layout Exception Regression Tests', () {
    testWidgets('LiveScreen in loading state renders without intrinsic dimension assertion errors', (tester) async {
      final completer = Completer<List<TournamentModel>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiTournamentsProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: LiveScreen(),
          ),
        ),
      );

      // Perform layout pass
      await tester.pump();

      // Verify no exceptions thrown and screen title is visible
      expect(find.text('Free Fire Live'), findsOneWidget);
    });

    testWidgets('LiveScreen with tournament list renders cards cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiTournamentsProvider.overrideWith((ref) async => [testTournament]),
          ],
          child: const MaterialApp(
            home: LiveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Free Fire Premier Cup'), findsOneWidget);
    });

    testWidgets('LiveScreen in empty state renders without layout errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiTournamentsProvider.overrideWith((ref) async => <TournamentModel>[]),
          ],
          child: const MaterialApp(
            home: LiveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('No tournaments found'), findsOneWidget);
    });

    testWidgets('LiveScreen in error state renders error widget cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiTournamentsProvider.overrideWith((ref) => Future.error(Exception('Network error'))),
          ],
          child: const MaterialApp(
            home: LiveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Couldn't load tournaments"), findsOneWidget);
    });
  });
}
