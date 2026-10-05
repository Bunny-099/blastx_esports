import 'package:blastix_esports/features/home/presentation/home_screen.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleTournamentLive = TournamentModel(
    id: 'tx_live_01',
    name: 'BlastX Live Showdown',
    game: 'Free Fire',
    gameLogoUrl: 'https://example.com/logo.png',
    status: TournamentStatus.live,
    prizePool: 50000,
    viewersCount: 1250,
    organizer: 'BlastX',
    bannerImageUrl: 'https://example.com/banner.jpg',
    startTime: DateTime.now().subtract(const Duration(hours: 1)),
  );

  final sampleTournamentUpcoming = TournamentModel(
    id: 'tx_up_01',
    name: 'BlastX Upcoming Clash',
    game: 'Free Fire',
    gameLogoUrl: 'https://example.com/logo.png',
    status: TournamentStatus.upcoming,
    prizePool: 25000,
    viewersCount: 0,
    organizer: 'BlastX',
    bannerImageUrl: 'https://example.com/banner2.jpg',
    startTime: DateTime.now().add(const Duration(days: 1)),
  );

  final sampleTournamentFF = TournamentModel(
    id: 'tx_ff_01',
    name: 'Free Fire India Official Championship',
    game: 'Free Fire',
    gameLogoUrl: 'https://example.com/logo.png',
    status: TournamentStatus.upcoming,
    prizePool: 100000,
    viewersCount: 0,
    organizer: 'Garena Official',
    bannerImageUrl: 'https://example.com/banner3.jpg',
    startTime: DateTime.now().add(const Duration(days: 2)),
  );

  group('Home Screen Redesign Tests', () {
    testWidgets('Featured Tournaments section should NOT exist on Home Screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify FEATURED TOURNAMENTS text is NOT found
      expect(find.text('FEATURED TOURNAMENTS'), findsNothing);
      expect(find.text('ESPORTS HUB'), findsOneWidget);
    });

    testWidgets(
        'Section titles render ONLY when their respective tournament lists are not empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLiveTournamentsProvider.overrideWith((ref) => [sampleTournamentLive]),
            appUpcomingTournamentsProvider.overrideWith((ref) => [sampleTournamentUpcoming]),
            officialTournamentsProvider.overrideWith((ref) => [sampleTournamentFF]),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // All 3 titles should be rendered
      expect(find.textContaining('BLASTX LIVE TOURNAMENTS'), findsOneWidget);
      expect(find.textContaining('BLASTX UPCOMING TOURNAMENTS'), findsOneWidget);
      expect(find.textContaining('FREE FIRE OFFICIAL TOURNAMENTS'), findsOneWidget);

      // Verify tournament titles exist
      expect(find.text('BlastX Live Showdown'), findsOneWidget);
      expect(find.text('BlastX Upcoming Clash'), findsOneWidget);
      expect(find.text('Free Fire India Official Championship'), findsOneWidget);
    });

    testWidgets(
        'Sections are dynamically HIDDEN when their tournament lists are empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // BlastX Live has items, but Upcoming and FF Official are empty
            appLiveTournamentsProvider.overrideWith((ref) => [sampleTournamentLive]),
            appUpcomingTournamentsProvider.overrideWith((ref) => []),
            officialTournamentsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // BlastX Live section title should be visible
      expect(find.textContaining('BLASTX LIVE TOURNAMENTS'), findsOneWidget);

      // Upcoming and Free Fire Official section titles MUST NOT be visible when empty
      expect(find.textContaining('BLASTX UPCOMING TOURNAMENTS'), findsNothing);
      expect(find.textContaining('FREE FIRE OFFICIAL TOURNAMENTS'), findsNothing);
    });

    testWidgets('Gamer Profile Card & Daily Quests Teaser Card are displayed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('ProGamer'), findsOneWidget);
      expect(find.text('DAILY ESPORTS QUEST'), findsOneWidget);
    });
  });
}
