import 'package:blastix_esports/features/home/data/models/home_data_models.dart';
import 'package:blastix_esports/features/home/presentation/home_screen.dart';
import 'package:blastix_esports/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    testWidgets('Live Tournaments Section is HIDDEN when no streams are active',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveStreamsProvider.overrideWith((ref) => []),
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
  });
}
