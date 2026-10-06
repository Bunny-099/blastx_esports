import 'package:blastix_esports/features/home/data/models/home_data_models.dart';
import 'package:blastix_esports/features/home/presentation/home_screen.dart';
import 'package:blastix_esports/features/home/providers/home_provider.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/tournaments/presentation/widgets/blastix_tournament_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleTournament = TournamentModel(
    id: 'tourney_test_01',
    name: 'BlastX Grand Showdown',
    game: 'Free Fire',
    mode: 'SQUAD',
    status: TournamentStatus.live,
    bannerImageUrl: 'assets/images/top_banner.jpg',
    gameLogoUrl: 'assets/logos/app_logo.png',
    prizePool: 50000,
    entryFee: 0,
    maxSlots: 48,
    registeredCount: 32,
    viewersCount: 1200,
    startTime: DateTime.now(),
    startsAt: DateTime.now(),
    organizer: 'BlastX Esports',
  );

  const sampleLiveStream = LiveStreamCardItem(
    id: 'stream_01',
    title: 'BlastX Live Showdown',
    subtitle: 'Grand Finals',
    location: 'New Delhi, India',
    viewerCount: '12.4K',
    imageUrl: 'assets/images/top_banner.jpg',
    streamUrl: 'https://youtube.com/live',
  );

  const samplePartner = PartnerItem(
    id: 'partner_01',
    name: 'Red Bull Gaming',
    logoUrl: 'https://example.com/redbull.png',
  );

  group('Home Screen Redesign Tests', () {
    testWidgets('Header branding & Quick Action Grid render correctly',
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

      // Verify header rich text branding
      expect(find.textContaining('BLASTIX', findRichText: true), findsWidgets);
      expect(find.textContaining('ARENA', findRichText: true), findsWidgets);

      // Verify Quick Action Grid options
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.text('Live Matches'), findsOneWidget);
      expect(find.text('Daily Quests'), findsOneWidget);
      expect(find.text('My Squad'), findsOneWidget);
    });

    testWidgets('User Profile Greeting Card uses username or Player fallback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(username: 'Player'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Hey, Player!'), findsOneWidget);
    });

    testWidgets('Live Tournaments Section displays live streams when available',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveStreamsProvider.overrideWith((ref) => [sampleLiveStream]),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('LIVE TOURNAMENTS', findRichText: true), findsOneWidget);
      expect(find.text('BlastX Live Showdown'), findsOneWidget);
    });

    testWidgets('Live Tournaments Section is HIDDEN when no streams or tournaments are active',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveStreamsProvider.overrideWith((ref) => []),
            homeFeaturedTournamentsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('LIVE TOURNAMENTS', findRichText: true), findsNothing);
    });

    testWidgets('Our Partners section displays partners when available',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partnersProvider.overrideWith((ref) => [samplePartner]),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('OUR PARTNERS'), findsOneWidget);
      expect(find.text('Red Bull Gaming'), findsOneWidget);
    });

    testWidgets('Our Partners section is HIDDEN when no partners exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partnersProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('OUR PARTNERS'), findsNothing);
    });

    testWidgets('Featured section renders BlastIXTournamentCard for BlastX tournaments',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeFeaturedTournamentsProvider.overrideWith((ref) => [sampleTournament]),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BlastIXTournamentCard), findsOneWidget);
      expect(find.text('BlastX Grand Showdown'), findsOneWidget);
    });

    testWidgets('Hero banner section is HIDDEN when backend returns empty banners',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeBannersProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('BHADRAK GAMING CHAMPIONSHIP'), findsNothing);
      expect(find.text('BGC 2026'), findsNothing);
    });

    testWidgets('Hero banner renders image cleanly without button when button_text is removed/empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const pureImageBanner = BannerItem(
        id: 'banner_pure_img',
        imageUrl: 'assets/images/top_banner.jpg',
        targetTabIndex: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeBannersProvider.overrideWith((ref) async => [pureImageBanner]),
          ],
          child: const MaterialApp(
            home: HomeScreen(username: 'ProGamer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Button should NOT exist
      expect(find.text('KNOW MORE →'), findsNothing);
      expect(find.text('KNOW MORE'), findsNothing);

      // Verify BannerItem.hasOverlayText helper
      expect(pureImageBanner.hasOverlayText, false);
    });

    test('BannerItem parses optional json fields without forcing dummy defaults', () {
      final json = {
        'id': 'b1',
        'image_url': 'https://cdn.blastx.gg/banner.jpg',
      };
      final item = BannerItem.fromJson(json);

      expect(item.id, 'b1');
      expect(item.imageUrl, 'https://cdn.blastx.gg/banner.jpg');
      expect(item.title, '');
      expect(item.subtitle, '');
      expect(item.tagline, '');
      expect(item.brandBadge, '');
      expect(item.buttonText, '');
      expect(item.hasOverlayText, false);
    });
  });
}
