import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/squad/data/models/squad_model.dart';
import 'package:blastix_esports/features/squad/presentation/widgets/ask_leader_dialog.dart';
import 'package:blastix_esports/features/squad/presentation/widgets/waitlist_status_dialog.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:blastix_esports/features/tournaments/presentation/widgets/tournament_navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRealTimeSyncManager implements RealTimeSyncManager {
  @override
  void register({
    required String key,
    required Future<dynamic> Function() fetcher,
    required void Function(dynamic data) onChanged,
    bool runImmediately = false,
  }) {}

  @override
  void unregister(String key) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentModel sampleTournament;
  late SquadModel sampleSquad;

  setUp(() {
    RealTimeSyncManager.isTestMode = true;

    sampleTournament = TournamentModel(
      id: 'tourney_999',
      name: 'BlastX Arena Pro Championship',
      game: 'Free Fire',
      bannerImageUrl: '',
      gameLogoUrl: '',
      prizePool: 100000,
      viewersCount: 500,
      status: TournamentStatus.live,
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      organizer: 'BlastX',
      isRegistered: true,
    );

    sampleSquad = SquadModel(
      id: 'squad_001',
      name: 'Apex Legends Squad',
      tag: 'APEX',
      leaderId: 'leader_123',
      members: const [
        SquadMemberModel(
          userId: 'leader_123',
          name: 'Apex Leader',
          ign: 'APEX_LEADER',
          uid: '10001',
          role: SquadRole.leader,
          rosterType: SquadRosterType.main,
        ),
        SquadMemberModel(
          userId: 'member_456',
          name: 'Apex Member 1',
          ign: 'APEX_M1',
          uid: '10002',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
        ),
      ],
    );
  });

  group('Tournament Registration & My Squad Sync Test Suite', () {
    testWidgets('Registered tournament card tap shows dual option modal (View Details & View Waitlist)', (tester) async {
      final fakeSyncManager = FakeRealTimeSyncManager();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () {
                        handleTournamentCardTap(context, ref, sampleTournament);
                      },
                      child: const Text('Tap Tournament Card'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Tap Tournament Card'));
      await tester.pumpAndSettle();

      expect(find.text('JOINED TOURNAMENT'), findsOneWidget);
      expect(find.text('VIEW TOURNAMENT DETAIL'), findsOneWidget);
      expect(find.text('VIEW WAITLIST'), findsOneWidget);
    });

    testWidgets('Non-leader dialog triggers warning for simple member', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAskLeaderDialog(context),
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.text('please ask team leader to register the tournament'), findsOneWidget);
      expect(find.text('Only the Team Leader or Manager can register your squad for tournaments.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('Waitlist status dialog displays member acceptance statuses with ✓ formatting', (tester) async {
      final fakeSyncManager = FakeRealTimeSyncManager();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            appTournamentsProvider.overrideWith((ref) => [sampleTournament]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => showWaitlistModal(context, ref, sampleSquad),
                      child: const Text('Open Waitlist'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open Waitlist'));
      await tester.pumpAndSettle();

      expect(find.text('TOURNAMENT WAITLIST'), findsOneWidget);
      expect(find.text('Apex Leader'), findsOneWidget);
      expect(find.text('✓ Accepted & Confirmed'), findsOneWidget);
      expect(find.text('Waiting from this player to accept the request'), findsOneWidget);
    });

    test('createTeam automatically syncs squad and unlocks squadProvider', () async {
      final fakeSyncManager = FakeRealTimeSyncManager();
      final container = ProviderContainer(
        overrides: [
          realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
          useMockSquadRepositoryProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(squadProvider).hasSquad, isFalse);

      final ok = await container.read(teamProvider('tourney_999').notifier).createTeam(
        teamName: 'Alpha Squad',
        tag: 'ALPHA',
        playerName: 'Alpha Leader',
        uid: '999888777',
      );

      expect(ok, isTrue);
      final squadState = container.read(squadProvider);
      expect(squadState.hasSquad, isTrue);
      expect(squadState.squad?.name, 'Alpha Squad');
      expect(squadState.squad?.tag, 'ALPHA');
    });

    test('joinTeam automatically syncs squad and unlocks squadProvider', () async {
      final fakeSyncManager = FakeRealTimeSyncManager();
      final container = ProviderContainer(
        overrides: [
          realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
          useMockSquadRepositoryProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(squadProvider).hasSquad, isFalse);

      final previewTeam = TournamentTeamModel(
        id: 'team_001',
        tournamentId: 'tourney_999',
        code: 'BLX-ALPHA',
        name: 'Alpha Squad',
        tag: 'ALPHA',
        captainId: 'captain_001',
        members: const [
          TeamMemberModel(
            userId: 'captain_001',
            name: 'Captain Alpha',
            ign: 'CAPTAIN',
            uid: '111222',
            role: TeamRole.captain,
            status: TeamMemberStatus.confirmed,
          ),
        ],
      );

      container.read(teamProvider('tourney_999').notifier).state =
          container.read(teamProvider('tourney_999')).copyWith(previewTeam: previewTeam);

      final ok = await container.read(teamProvider('tourney_999').notifier).joinTeam(
        playerName: 'Joiner Player',
        uid: '333444',
      );

      expect(ok, isTrue);
      final squadState = container.read(squadProvider);
      expect(squadState.hasSquad, isTrue);
      expect(squadState.squad?.name, 'Alpha Squad');
      expect(squadState.squad?.members.any((m) => m.name == 'Joiner Player'), isTrue);
    });
  });
}
