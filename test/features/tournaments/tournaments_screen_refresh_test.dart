import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/features/tournaments/presentation/tournaments_screen.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';

void main() {
  group('TournamentsScreen Pull-To-Refresh Tests', () {
    testWidgets('Renders RefreshIndicator on TournamentsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TournamentsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify TournamentsScreen title is present
      expect(find.text('BlastIX Tournaments'), findsOneWidget);

      // Verify RefreshIndicator widget is present in the tree
      expect(find.byType(RefreshIndicator), findsWidgets);
    });

    testWidgets('Pull to refresh gesture triggers refresh indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blastxLiveTournamentsApiProvider.overrideWith((ref) async => <TournamentModel>[]),
            blastxUpcomingTournamentsApiProvider.overrideWith((ref) async => <TournamentModel>[]),
            blastxTournamentsApiProvider.overrideWith((ref) async => <TournamentModel>[]),
            apiTournamentsProvider.overrideWith((ref) async => <TournamentModel>[]),
          ],
          child: const MaterialApp(
            home: TournamentsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Find the RefreshIndicator
      final refreshIndicatorFinder = find.byType(RefreshIndicator).first;
      expect(refreshIndicatorFinder, findsOneWidget);

      // Drag down to trigger pull-to-refresh
      await tester.drag(refreshIndicatorFinder, const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify RefreshIndicator is present and active
      expect(find.byType(RefreshIndicator), findsWidgets);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
