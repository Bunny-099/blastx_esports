import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/tournaments/presentation/widgets/blastix_tournament_card.dart';
import 'package:blastix_esports/features/tournaments/presentation/widgets/upcoming_tournament_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();

  final liveTournament = TournamentModel(
    id: 't_live',
    name: 'BlastX Live Finals',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 100000,
    viewersCount: 3500,
    status: TournamentStatus.live,
    startTime: now.subtract(const Duration(hours: 1)),
    organizer: 'BlastX Esports',
  );

  final regOpenTournament = TournamentModel(
    id: 't_open',
    name: 'BlastX Open Championship',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 50000,
    viewersCount: 0,
    status: TournamentStatus.upcoming,
    startTime: now.add(const Duration(days: 2)),
    organizer: 'BlastX Esports',
    maxSlots: 48,
    filledSlots: 10,
    registrationOpensAt: now.subtract(const Duration(days: 1)),
    registrationClosesAt: now.add(const Duration(days: 1)),
  );

  final regClosedTournament = TournamentModel(
    id: 't_closed',
    name: 'BlastX Masters Invitational',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 75000,
    viewersCount: 0,
    status: TournamentStatus.upcoming,
    startTime: now.add(const Duration(hours: 3)),
    organizer: 'BlastX Esports',
    maxSlots: 48,
    filledSlots: 48, // Full capacity
  );

  final regOpensSoonTournament = TournamentModel(
    id: 't_soon',
    name: 'BlastX Future Clash',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 25000,
    viewersCount: 0,
    status: TournamentStatus.upcoming,
    startTime: now.add(const Duration(days: 5)),
    organizer: 'BlastX Esports',
    registrationOpensAt: now.add(const Duration(days: 1)),
    registrationClosesAt: now.add(const Duration(days: 4)),
  );

  final registeredTournament = TournamentModel(
    id: 't_registered',
    name: 'BlastX Squad Battle',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 30000,
    viewersCount: 0,
    status: TournamentStatus.upcoming,
    startTime: now.add(const Duration(days: 1)),
    organizer: 'BlastX Esports',
    isRegistered: true,
  );

  final completedTournament = TournamentModel(
    id: 't_completed',
    name: 'BlastX Winter Cup 2025',
    game: 'Free Fire',
    bannerImageUrl: '',
    gameLogoUrl: '',
    prizePool: 50000,
    viewersCount: 0,
    status: TournamentStatus.completed,
    startTime: now.subtract(const Duration(days: 10)),
    organizer: 'BlastX Esports',
  );

  group('TournamentModel Dynamic Status Property Tests', () {
    test('computes status properties correctly for LIVE tournament', () {
      expect(liveTournament.isLive, isTrue);
      expect(liveTournament.actionButtonText, equals('WATCH'));
      expect(liveTournament.statusBadgeText, equals('LIVE'));
    });

    test('computes status properties correctly for REGISTRATION OPEN tournament', () {
      expect(regOpenTournament.isRegistrationOpen, isTrue);
      expect(regOpenTournament.isRegistrationClosed, isFalse);
      expect(regOpenTournament.actionButtonText, equals('REGISTRATION OPEN'));
      expect(regOpenTournament.statusBadgeText, equals('Registration Open'));
    });

    test('computes status properties correctly for REGISTRATION CLOSED (FULL) tournament', () {
      expect(regClosedTournament.isRegistrationClosed, isTrue);
      expect(regClosedTournament.isRegistrationOpen, isFalse);
      expect(regClosedTournament.actionButtonText, equals('REGISTRATION CLOSED'));
      expect(regClosedTournament.statusBadgeText, equals('Registration Closed'));
    });

    test('computes status properties correctly for OPENS SOON tournament', () {
      expect(regOpensSoonTournament.isRegistrationOpensSoon, isTrue);
      expect(regOpensSoonTournament.actionButtonText, equals('OPENS SOON'));
      expect(regOpensSoonTournament.statusBadgeText, equals('Opens Soon'));
    });

    test('computes status properties correctly for REGISTERED tournament', () {
      expect(registeredTournament.effectiveIsRegistered, isTrue);
      expect(registeredTournament.actionButtonText, equals('REGISTERED ✓'));
      expect(registeredTournament.statusBadgeText, equals('Registered ✓'));
    });

    test('computes status properties correctly for COMPLETED tournament', () {
      expect(completedTournament.actionButtonText, equals('COMPLETED'));
      expect(completedTournament.statusBadgeText, equals('Ended'));
    });
  });

  group('BlastIXTournamentCard Dynamic Status Widget Tests', () {
    testWidgets('renders WATCH button for live tournament', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlastIXTournamentCard(
              tournament: liveTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Live Finals'), findsOneWidget);
      expect(find.text('WATCH'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('renders REGISTRATION OPEN button & top badge for open tournament', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlastIXTournamentCard(
              tournament: regOpenTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Open Championship'), findsOneWidget);
      expect(find.text('REGISTRATION OPEN'), findsNWidgets(2)); // Badge and Button
    });

    testWidgets('renders REGISTRATION CLOSED button & top badge when closed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlastIXTournamentCard(
              tournament: regClosedTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Masters Invitational'), findsOneWidget);
      expect(find.text('REGISTRATION CLOSED'), findsNWidgets(2)); // Badge and Button
    });

    testWidgets('renders REGISTERED ✓ button & top badge when user is registered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlastIXTournamentCard(
              tournament: registeredTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Squad Battle'), findsOneWidget);
      expect(find.text('REGISTERED ✓'), findsNWidgets(2)); // Badge and Button
    });
  });

  group('UpcomingTournamentCard Dynamic Status Widget Tests', () {
    testWidgets('renders Registration Open status for open upcoming tournament', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingTournamentCard(
              tournament: regOpenTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Open Championship'), findsOneWidget);
      expect(find.text('Registration Open'), findsOneWidget);
    });

    testWidgets('renders Registration Closed status for closed upcoming tournament', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingTournamentCard(
              tournament: regClosedTournament,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('BlastX Masters Invitational'), findsOneWidget);
      expect(find.text('Registration Closed'), findsOneWidget);
    });
  });
}
